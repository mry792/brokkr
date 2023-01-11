
# Create an executable target and populate it with all the specified options.
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
