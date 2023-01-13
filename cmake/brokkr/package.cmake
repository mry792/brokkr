
function(_bkr_generate_extra_config OUTPUT_FILENAMES OUTPUT_TO_INSTALL)
    set(filenames)
    set(files_to_install)

    foreach(extra IN LISTS ARGN)
        string(REGEX MATCH "\\.cmake(\\.in)?$" extension ${extra})

        if("${extension}" STREQUAL ".cmake.in")
            cmake_path(GET extra FILENAME template_filename)
            string(REGEX REPLACE "\\.cmake\\.in$" ".brokkr-gen.cmake" extra_filename ${template_filename})
            set(extra_generated "${CMAKE_CURRENT_BINARY_DIR}/brokkr/${extra_filename}")
            configure_file(${extra} ${extra_generated} @ONLY)

            list(APPEND filenames ${extra_filename})
            list(APPEND files_to_install ${extra_generated})

        elseif("${extension}" STREQUAL ".cmake")
            cmake_path(GET extra FILENAME extra_filename)

            list(APPEND filenames ${extra_filename})
            list(APPEND files_to_install ${extra})

        else()
            message(
                SEND_ERROR
                "Extra config must either be directly included (ends in "
                "\".cmake\") or be templated (ends in \".cmake.in\"). The "
                "specified extra config file \"${extra}\" is neither."
            )
        endif()
    endforeach()

    set(${OUTPUT_FILENAMES} ${filenames} PARENT_SCOPE)
    set(${OUTPUT_TO_INSTALL} ${files_to_install} PARENT_SCOPE)
endfunction()


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
# :param EXTRA_CONFIG: Extra files to be installed and loaded when the package
#     is imported. Files with a ".cmake.in" extension will be run through
#     `confgure_file(@ONLY)` before being installed.
# :type EXTRA_CONFIG: List of file paths, relative to the current lists file
#     or absolute.
function(brokkr_package)
    cmake_parse_arguments(
        PARSE_ARGV 0
        BKR_PKG
        ""
        "CONFIG_TEMPLATE"
        "EXTRA_CONFIG"
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

    # Generate extra files.
    _bkr_generate_extra_config(
        BROKKR_EXTRA_CONFIG
        extra_config_to_install
        ${BKR_PKG_EXTRA_CONFIG}
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
            ${extra_config_to_install}
        DESTINATION lib/cmake/${PROJECT_NAME}
    )
endfunction()
