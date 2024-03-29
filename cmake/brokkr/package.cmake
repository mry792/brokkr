
function(_bkr_generate_extra_config OUTPUT_FILENAMES OUTPUT_TO_INSTALL)
    set(filenames)
    set(files_to_install)

    foreach(extra IN LISTS ARGN)
        string(REGEX MATCH "\\.cmake(\\.in)?$" extension ${extra})

        if("${extension}" STREQUAL ".cmake.in")
            cmake_path(GET extra FILENAME template_filename)
            string(REGEX REPLACE "\\.cmake\\.in$" ".brokkr-gen.cmake" extra_filename ${template_filename})
            set(extra_generated "${CMAKE_CURRENT_BINARY_DIR}/brokkr/${extra_filename}")

            message(STATUS "[brokkr] generating file: ${extra} => ${extra_filename}")
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
                "[brokkr] Extra config must either be directly included (ends "
                "in \".cmake\") or be templated (ends in \".cmake.in\"). The "
                "specified extra config file \"${extra}\" is neither."
            )
        endif()
    endforeach()

    set(${OUTPUT_FILENAMES} ${filenames} PARENT_SCOPE)
    set(${OUTPUT_TO_INSTALL} ${files_to_install} PARENT_SCOPE)
endfunction()


function(_bkr_generate_targets_file OUTPUT_FILENAME)
    _bkr_get_proj_prop(targets "targets")
    if(targets)
        message(STATUS "[brokkr] Generating targets file for targets \"${targets}\".")
        install(
            TARGETS ${targets}
            EXPORT ${PROJECT_NAME}-targets
            FILE_SET HEADERS
        )
        install(
            EXPORT ${PROJECT_NAME}-targets
            FILE "${PROJECT_NAME}-targets.cmake"
            NAMESPACE "${PROJECT_NAME}::"
            DESTINATION lib/cmake/${PROJECT_NAME}
        )
        set(${OUTPUT_FILENAME} "${PROJECT_NAME}-targets.cmake" PARENT_SCOPE)
    else()
        message(STATUS "[brokkr] No targets found. Skipping generation of targets file.")
    endif()
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
#     or absolute. (optional)
# :param COMPATIBILITY: The compatibility mode to forward to the
#     `write_basic_package_version_file` function. (default: "SameMajorVersion")
# :type COMPATIBILITY: One of "AnyNewerVersion", "SameMajorVersion",
#     "SameMinorVersion", or "ExactVersion".
# :param EXTRA_CONFIG: Extra files to be installed and loaded when the package
#     is imported. Files with a ".cmake.in" extension will be run through
#     `confgure_file(@ONLY)` before being installed.
# :type EXTRA_CONFIG: List of file paths, relative to the current lists file
#     or absolute. Files must have unique names as they will be installed into
#     the same directory.
function(brokkr_package)
    cmake_parse_arguments(
        PARSE_ARGV 0
        BKR_PKG
        ""
        "CONFIG_TEMPLATE;COMPATIBILITY"
        "EXTRA_CONFIG"
    )
    if(BKR_PKG_UNPARSED_ARGUMENTS)
        message(
            FATAL_ERROR
            "[brokkr] Unrecognized arguments to function `brokkr_package`:\n"
            "${BKR_PKG_UNPARSED_ARGUMENTS}"
        )
    endif()

    # Set defaults.
    _bkr_set_with_default(
        config_template
        "${BKR_PKG_CONFIG_TEMPLATE}"
        "${brokkr_CMAKE_DIR}/brokkr/templates/config.cmake.in"
    )
    _bkr_set_with_default(
        compatibility
        "${BKR_PKG_COMPATIBILITY}"
        SameMajorVersion
    )

    include(CMakePackageConfigHelpers)

    # Generate version file.
    set(version_file "brokkr/${PROJECT_NAME}-config-version.cmake")
    write_basic_package_version_file(
        ${version_file}
        COMPATIBILITY ${compatibility}
    )

    # Generate extra files.
    _bkr_generate_extra_config(
        BROKKR_CONFIG_FILES
        extra_config_to_install
        ${BKR_PKG_EXTRA_CONFIG}
    )

    # Generate targets file.
    _bkr_generate_targets_file(targets_file)
    list(PREPEND BROKKR_CONFIG_FILES "${targets_file}")

    # Generate main config file.
    _bkr_get_proj_prop(BROKKR_PROJECT_DEPENDENCIES "dependencies")
    set(main_config_file "brokkr/${PROJECT_NAME}-config.cmake")
    configure_package_config_file(
        ${config_template}
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
