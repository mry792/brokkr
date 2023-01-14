
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
# :param COMPILE_OPTIONS: Extra flags to pass to the compilation step.
# :type COMPILE_OPTIONS: List of string values.
function(brokkr_add_library LIB_NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_ADD_LIB
        ""
        "INCLUDE_DIR"
        "HEADERS;SOURCES;DEPENDENCIES;COMPILE_FEATURES;COMPILE_OPTIONS"
    )

    cmake_path(
        ABSOLUTE_PATH BKR_ADD_LIB_INCLUDE_DIR
        NORMALIZE
        OUTPUT_VARIABLE inc_dir
    )

    if(${BKR_ADD_LIB_SOURCES})
        add_library(${LIB_NAME})
        set(scope PUBLIC)

        # NOTE: Only add compile options to source compiled for the library.
        target_compile_options(
            ${LIB_NAME}
            PRIVATE ${BKR_ADD_LIB_COMPILE_OPTIONS}
        )
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
            $<BUILD_INTERFACE:${inc_dir}>
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
                "DISCOVER_COMMAND"
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

                _bkr_ensure_found(TARGETS ${BKR_ADD_LIB_UT_DEPENDENCIES})
                brokkr_add_executable(
                    "${ut_exec_name}"
                    SOURCES ${BKR_ADD_LIB_UT_SOURCES}
                    DEPENDENCIES
                        ${LIB_NAME}
                        ${BKR_ADD_LIB_UT_DEPENDENCIES}
                    ${BKR_ADD_LIB_UT_UNPARSED_ARGUMENTS}
                )

                if(BKR_ADD_LIB_UT_DISCOVER_COMMAND)
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
