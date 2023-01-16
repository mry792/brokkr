
# Create an executable target and populate it with all the specified options.
#
# This is a lower-level implementation helper function. Prefer the function
# `brokkr_executable()` below for creating an executable target and
# configuring installation and associated tests.
#
# This will also create an alias target prefixed with "PACKAGE_NAME::". This
# matches the name the target will take on when referenced in other
# packages.
#
# :param EXEC_NAME: Name of the target. This will also be the name of the
#     executable file produced by the build.
# :type EXEC_NAME: A string which is a valid file name.
# :param SOURCES: Source files to compile into the executable.
# :type SOURCES: List of paths to files.
# :param DEPENDENCIES: Targets to link the executable to.
# :type DEPENDENCIES: List of target names.
# :param COMPILE_FEATURES: Compile features to configure the target.
# :type COMPILE_FEATURES: List of string values.
# :param COMPILE_OPTIONS: Extra flags to pass to the compilation step.
# :type COMPILE_OPTIONS: List of string values.
function(brokkr_add_executable EXEC_NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_ADD_EXEC
        ""
        ""
        "SOURCES;DEPENDENCIES;COMPILE_FEATURES;COMPILE_OPTIONS"
    )

    add_executable(${EXEC_NAME} ${BKR_ADD_EXEC_SOURCES})
    target_link_libraries(${EXEC_NAME} PUBLIC ${BKR_ADD_EXEC_DEPENDENCIES})
    target_compile_features(${EXEC_NAME} PUBLIC ${BKR_ADD_EXEC_COMPILE_FEATURES})
    target_compile_options(${EXEC_NAME} PRIVATE ${BKR_ADD_EXEC_COMPILE_OPTIONS})

    add_executable(${PROJECT_NAME}::${EXEC_NAME} ALIAS ${EXEC_NAME})
endfunction()


# Create an executable and flag it for installation.
#
# The executable source is assumed to be a single source file. The expectation
# is that almost all of the work will be handled by library code which is
# covered by tests. The single source file for the executable should thus be
# very small and delegate almost everything to libraries.
#
# Dependencies do not have to be `find_package`d separately if they conform to
# the following:
#  1) The target name is either local to the project or is qualified by the
#     package name.
#  2) The target can be imported with a simple `find_package(package_name
#     REQUIRED)` call. It is assumed that versions are managed by an external
#     package manager. (Components are not yet supported.)
#
# :param EXEC_NAME: Name of the executable target.
# :type EXEC_NAME: String. (required)
# :param NO_INSTALL: Suppress installation of the executable target.
# :type NO_INSTALL: Flag.
# :param MAIN_SOURCE: Path to the main source file. Defaults to
#     "${EXEC_NAME}.cpp".
# :type MAIN_SOURCE: Path to a file, relative or absolute. (optional)
# :param DEPENDENCIES: Targets to link the new executable to.
# :type DEPENDENCIES: List of target names.
function(brokkr_executable EXEC_NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_EXEC
        "NO_INSTALL"
        "MAIN_SOURCE"
        "DEPENDENCIES"
    )

    # Set defaults.
    if(NOT BKR_EXEC_MAIN_SOURCE)
        set(BKR_EXEC_MAIN_SOURCE "${EXEC_NAME}.cpp")
    endif()

    # Import dependencies as needed.
    _bkr_ensure_found(
        OUTPUT_PACKAGES pkg_dependencies
        TARGETS ${BKR_EXEC_DEPENDENCIES}
    )

    # Create executable target.
    brokkr_add_executable(
        ${EXEC_NAME}
        SOURCES "${BKR_EXEC_MAIN_SOURCE}"
        DEPENDENCIES ${BKR_EXEC_DEPENDENCIES}
        COMPILE_OPTIONS
            -Werror
            -Wall
            -Wextra
            -Wpedantic
    )

    # Static analysis????
    # TODO

    # Flag for installation.
    if(NOT BKR_EXEC_NO_INSTALL)
        brokkr_install_target(
            ${EXEC_NAME}
            REQUIRED_PACKAGES ${pkg_dependencies}
        )
    endif()
endfunction()
