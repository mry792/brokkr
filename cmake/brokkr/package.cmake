
# Generate and install the files necessary for other CMake projects to consume
# this one from its install location through `find_package`.
#
# This must be called once per project after all other things to be installed
# have been specified, typically at the end of the main `CMakeLists.txt`
# file.
#
# :param CONFIG_TEMPLATE: File to use as the the CMake configure template for
#     the package config file.
# :type CONFIG_TEMPLATE: Path to a file, relative to the current lists file
#     or absolute.
function(brokkr_package)
    cmake_parse_arguments(
        PARSE_ARGV 0
        BKR_PKG
        ""
        "CONFIG_TEMPLATE"
        ""
    )
    if(BKR_PKG_UNPARSED_ARGUMENTS)
        message(
            FATAL_ERROR
            "Unrecognized arguments to function `brokkr_package`:\n"
            "${BKR_PKG_UNPARSED_ARGUMENTS}"
        )
    endif()

    include(CMakePackageConfigHelpers)

    # Generate version file.
    set(version_file "brokkr/${PROJECT_NAME}-config-version.cmake")
    write_basic_package_version_file(
        ${version_file}
        COMPATIBILITY SameMajorVersion
    )

    # Generate main config file.
    set(main_config_file "brokkr/${PROJECT_NAME}-config.cmake")
    configure_package_config_file(
        ${BKR_PKG_CONFIG_TEMPLATE}
        ${main_config_file}
        INSTALL_DESTINATION lib/cmake/${PROJECT_NAME}
    )

    # Install everything.
    install(
        FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${version_file}
            ${CMAKE_CURRENT_BINARY_DIR}/${main_config_file}
        DESTINATION lib/cmake/${PROJECT_NAME}
    )
endfunction()
