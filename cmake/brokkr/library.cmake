
cmake_minimum_required(VERSION 3.23 FATAL_ERROR)


# Create a binary library target and populate it with all the specified
# options.
#
# This is a lower-level implementation helper function. Prefer the function
# `brokkr_library()` below for creating a library target and configuring
# installation and associated tests.
#
# This will also create an alias target prefixed with "<PACKAGE_NAME>::". This
# matches the name the target will take on when referenced in other
# packages.
#
# :param LIB_NAME: Name of the target.
# :type LIB_NAME: A string which is a valid file name.
# :param INCLUDE_DIR: Base directory for header files.
# :type INCLUDE_DIR: Local path. Relative or absolute.
# :param HEADERS: Header files for the library.
# :type HEADERS: List of paths to files.
# :param SOURCES: Source files to compile into the library.
# :type SOURCES: List of paths to files.
# :param DEPENDENCIES: Targets to link the library to.
# :type DEPENDENCIES: List of target names.
# :param COMPILE_FEATURES: Compile features to configure the target.
# :type COMPILE_FEATURES: List of string values.
function(brokkr_add_library LIB_NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_ADD_LIB
        ""
        "INCLUDE_DIR"
        "HEADERS;SOURCES;DEPENDENCIES;COMPILE_FEATURES"
    )

    if(${BKR_ADD_LIB_SOURCES})
        add_library(${LIB_NAME})
        set(scope PUBLIC)
    else()
        add_library(${LIB_NAME} INTERFACE)
        set(scope INTERFACE)
    endif()

    target_sources(
        ${LIB_NAME}
        PRIVATE
            ${BKR_ADD_LIB_SOURCES}
        ${scope}
            FILE_SET HEADERS
            BASE_DIRS ${BKR_ADD_LIB_INCLUDE_DIR}
            FILES ${BKR_ADD_LIB_HEADERS}
    )

    target_include_directories(
        ${LIB_NAME}
        ${scope}
            $<BUILD_INTERFACE:${BKR_ADD_LIB_INCLUDE_DIR}>
            $<INSTALL_INTERFACE:include>
    )
    target_link_libraries(
        ${LIB_NAME}
        ${scope} ${BKR_ADD_LIB_DEPENDENCIES}
    )
    target_compile_features(
        ${LIB_NAME}
        ${scope} ${BKR_ADD_LIB_COMPILE_FEATURES}
    )
    set_target_properties(
        ${LIB_NAME}
        PROPERTIES
            OUTPUT_NAME "${PROJECT_NAME}_${LIB_NAME}"
    )

    add_library(${PROJECT_NAME}::${LIB_NAME} ALIAS ${LIB_NAME})
endfunction()


# Create an executable target for a library's unit tests.
#
# This is a lower-level implementation helper function. The function
# `brokkr_library()` below will call this function to generate the unit test
# target and register it. Prefer to not call `brokkr_add_library_unit_tests()`
# directly.
#
# :param LIB_NAME: Name of the library under test.
# :type LIB_NAME: Target name.
# :param DISCOVER_INCLUDE: Script which provides the DISCOVER_COMMAND.
# :type DISCOVER_INCLUDE: Name of or path to a CMake script. (optional)
# :param DISCOVER_COMMAND: CMake command used to register the tests with CTest.
# :type DISCOVER_COMMAND: Command name. (optional)
# :param SOURCES: Source files to compile into the test executable.
# :type SOURCES: List of paths to files.
# :param DEPENDENCIES: Targets to link the test executable to.
# :type DEPENDENCIES: List of target names.
# :param DISCOVER_EXTRA_ARGS: Extra arguments to the discover command.
# :type DISCOVER_EXTRA_ARGS: List of strings.
#
# All unparsed arguments will be forwarded to the `brokkr_add_executable`
# command that creates the unit test executable target.
function(brokkr_add_library_unit_tests LIB_NAME)
    if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
        include(CTest)

        if(BUILD_TESTING)
            cmake_parse_arguments(
                PARSE_ARGV 1
                BKR_ADD_LIB_UT
                ""
                "DISCOVER_INCLUDE;DISCOVER_COMMAND"
                "SOURCES;DEPENDENCIES;DISCOVER_EXTRA_ARGS"
            )

            set(ut_exec_name "${LIB_NAME}_unit-tests")

            if(BKR_ADD_LIB_UT_SOURCES OR BKR_ADD_LIB_UT_DEPENDENCIES)
                # Generate empty source file if needed.
                if(NOT BKR_ADD_LIB_UT_SOURCES)
                    message(
                        WARNING
                        "No unit test sources found for unit test executable "
                        "\"${ut_exec_name}\" of library \"${LIB_NAME}\". "
                        "Generating unit test executable only from linked "
                        "dependencies."
                    )
                    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/brokkr_empty.cpp "")
                    list(
                        APPEND
                        BKR_ADD_LIB_UT_SOURCES
                        ${CMAKE_CURRENT_BINARY_DIR}/brokkr_empty.cpp
                    )
                endif()

                brokkr_ensure_found(TARGETS ${BKR_ADD_LIB_UT_DEPENDENCIES})
                brokkr_add_executable(
                    "${ut_exec_name}"
                    SOURCES ${BKR_ADD_LIB_UT_SOURCES}
                    DEPENDENCIES
                        ${LIB_NAME}
                        ${BKR_ADD_LIB_UT_DEPENDENCIES}
                    ${BKR_ADD_LIB_UT_UNPARSED_ARGUMENTS}
                )

                if(BKR_ADD_LIB_UT_DISCOVER_COMMAND)
                    include(${BKR_ADD_LIB_UT_DISCOVER_INCLUDE})
                    cmake_language(
                        CALL
                        ${BKR_ADD_LIB_UT_DISCOVER_COMMAND}
                        ${ut_exec_name}
                        ${BKR_ADD_LIB_UT_DISCOVER_EXTRA_ARGS}
                    )
                endif()
            endif()
        endif()
    endif()
endfunction()


# Create a library and flag it for installation.
#
# The library is assumed to be contained in a single directory in the current
# source directory and named "lib-{LIB_NAME}". The source code should follow
# the "unified source layout" with a single folder under the library root
# called "src" containing the mixed source, header, and unit test files. The
# root should also contain a directory called "tests" containing integration
# test source files. Overall, the directory structure should look like this:
#
#   lib-my-library
#   ├── src
#   │   └── my-library
#   │       ├── component_a.hpp
#   │       ├── component_a.cpp
#   │       ├── component_a.test.cpp
#   │       ├── component_b.hpp
#   │       ├── component_b.test.cpp
#   │       └── subdir
#   │           ├── component_c.hpp
#   │           ├── component_c.cpp
#   │           └── component_c.test.cpp
#   └── tests
#       ├── integration_test_1.cpp
#       └── integration_test_2.cpp
#
# Dependencies do not have to be `find_package`d separately if they conform to
# the following:
#  1) The target name is either local to the project or is qualified by the
#     package name.
#  2) The target can be imported with a simple `find_package(package_name
#     REQUIRED)` call. It is assumed that versions are managed by an external
#     package manager. (Components are not yet supported.)
#
# The parameters `LIBRARY` and `UNIT_TESTS` forward their arguments to other
# functions for specifying the details for the library target and unit test
# executable respectively. As such, they support sub-parameters in their
# arguments. The sub-parameters are documented below separately but they can
# be grouped together in one top-level parameter like so.
#
#   brokkr_library(
#       my-library
#       LIBRARY
#           COMPILE_FEATURES cxx_std_17
#           DEPENDENCIES third-party::library internal-library
#       UNIT_TESTS
#           DEPENDENCIES Catch2::Catch2
#           DISCOVER_COMMAND catch_discover_tests
#   )
#
# :param LIB_NAME: Name of the library target.
# :type LIB_NAME: String. (required)
# :param NO_INSTALL: Suppress installation of the library target.
# :type NO_INSTALL: Flag.
# :param ROOT_DIRECTORY: Path of the root directory of the library.
# :type ROOT_DIRECTORY: Absolute directory path. (optional)
# :param LIBRARY DEPENDENCIES: Targets to link the library to.
# :type LIBRARY DEPENDENCIES: List of target names.
# :param LIBRARY COMPILE_FEATURES: Compile features to configure the library.
# :type LIBRARY COMPILE_FEATURES: List of strings.
# :param UNIT_TESTS DISCOVER_INCLUDE: Script which provides the
#     DISCOVER_COMMAND.
# :type UNIT_TESTS DISCOVER_INCLUDE: Name of or path to a CMake script.
#     (optional)
# :param UNIT_TESTS DEPENDENCIES: Targets to link the test executable to.
# :type UNIT_TESTS DEPENDENCIES: List of target names.
# :param UNIT_TESTS DISCOVER_COMMAND: CMake command used to register the tests
#     with CTest.
# :type UNIT_TESTS DISCOVER_COMMAND: Command name. (optional)
# :param UNIT_TESTS DISCOVER_EXTRA_ARGS: Extra arguments to the discover
#     command.
# :type UNIT_TESTS DISCOVER_EXTRA_ARGS: List of strings.
function(brokkr_library LIB_NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_LIB
        "NO_INSTALL"
        "ROOT_DIRECTORY"
        "LIBRARY;UNIT_TESTS"
    )

    # We need to separately handle dependencies. Parse those now from the
    # extra LIBRARY arguments.
    cmake_parse_arguments(
        BKR_LIB_DETAILS
        ""
        "INCLUDE_DIR"
        "HEADERS;SOURCES;DEPENDENCIES;COMPILE_FEATURES"
        ${BKR_LIB_LIBRARY}
    )

    # Set defaults.
    _bkr_set_with_default(
        lib_root
        "${BKR_LIB_ROOT_DIRECTORY}"
        "lib-${LIB_NAME}"
    )
    get_filename_component(lib_root "${lib_root}" ABSOLUTE)
    set(src_dir "${lib_root}/src")
    set(inc_dir "${src_dir}")
    set(source_glob "*.cpp")
    set(header_glob "*.hpp")
    set(utest_dir "${src_dir}")
    set(utest_regex "\\.test\\.cpp$")

    # Import dependencies as needed.
    brokkr_ensure_found(
        OUTPUT_PACKAGES pkg_dependencies
        TARGETS ${BKR_LIB_DETAILS_DEPENDENCIES}
    )

    # Find files.
    file(GLOB_RECURSE header_files CONFIGURE_DEPENDS "${inc_dir}/${header_glob}")
    file(GLOB_RECURSE source_files CONFIGURE_DEPENDS "${src_dir}/${source_glob}")
    set(utest_files ${source_files})
    list(FILTER source_files EXCLUDE REGEX ${utest_regex})
    list(FILTER utest_files INCLUDE REGEX ${utest_regex})

    # Create library target
    brokkr_add_library(
        "${LIB_NAME}"
        INCLUDE_DIR ${inc_dir}
        HEADERS ${header_files}
        SOURCES ${source_files}
        ${BKR_LIB_LIBRARY}
    )

    # Static analysis????
    # TODO

    # Add unit tests.
    brokkr_add_library_unit_tests(
        "${LIB_NAME}"
        SOURCES ${utest_files}
        ${BKR_LIB_UNIT_TESTS}
    )

    # Add integration tests.
    # TODO

    # Flag for installation.
    if(NOT BKR_LIB_NO_INSTALL)
        brokkr_install_target(
            "${LIB_NAME}"
            REQUIRED_PACKAGES ${pkg_dependencies}
        )
    endif()
endfunction()
