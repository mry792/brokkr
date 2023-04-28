
macro(_bkr_set_with_default OUTPUT_VAR VALUE DEFAULT)
    if("${VALUE}" STREQUAL "")
        set(${OUTPUT_VAR} "${DEFAULT}")
    else()
        set(${OUTPUT_VAR} "${VALUE}")
    endif()
endmacro()


function(_bkr_package_names_from_targets OUTPUT_PACKAGES OUTPUT_LOOSE)
    set(package_names)
    set(loose_names)

    foreach(target_name IN LISTS ARGN)
        string(REPLACE "::" ";" tokens ${target_name})
        list(LENGTH tokens num_tokens)
        if(num_tokens EQUAL 1)
            list(APPEND loose_names ${target_name})
        elseif(num_tokens EQUAL 2)
            list(GET tokens 0 pkg_name)
            list(APPEND package_names ${pkg_name})
        else()
            message(
                FATAL_ERROR
                "[brokkr] Cannot parse qualified target \"${target_name}\". "
                "Too many namespace tokens."
            )
        endif()
    endforeach()

    list(SORT package_names)
    list(REMOVE_DUPLICATES package_names)
    set(${OUTPUT_PACKAGES} ${package_names} PARENT_SCOPE)

    list(SORT loose_names)
    list(REMOVE_DUPLICATES loose_names)
    set(${OUTPUT_LOOSE} ${loose_names} PARENT_SCOPE)
endfunction()


# Make sure that every package and target has been found.
#
# Specified targets must either already exist or be a package-qualified target
# name, e.g. "package_name::target_name". It is an error if any targets don't
# yet exist and do not have a package name component. For each
# package-qualified target which does not already exist, this function will
# call `find_package(package_name REQUIRED)`.
#
# :param OUTPUT_PACKAGES: If specified, store in this variable the packages
#     found by this function.
# :type OUTPUT_PACKAGES: Name of a variable in the parent scope. (optional)
# :param PACKAGES: Explicitly specified packages to find.
# :type PACKAGES: List of names.
# :param TARGETS: Targets to find.
# :type TARGETS: List of names.
function(brokkr_ensure_found)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_ENSF
        ""
        "OUTPUT_PACKAGES"
        "PACKAGES;TARGETS"
    )

    set(input_targets)
    foreach(target_name IN LISTS BKR_ENSF_TARGETS)
        if(NOT TARGET ${target_name})
            list(APPEND input_targets ${target_name})
        endif()
    endforeach()

    _bkr_package_names_from_targets(packages loose_names ${input_targets})

    foreach(target_name IN LISTS loose_names)
        message(
            SEND_ERROR
            "[brokkr] Dependency \"${target_name}\" is neither an existing "
            "target nor a package-qualified name. Cannot auto-import it."
        )
    endforeach()

    list(APPEND packages ${BKR_ENSF_PACKAGES})
    list(SORT packages)
    list(REMOVE_DUPLICATES packages)
    list(REMOVE_ITEM packages ${PACKAGE_NAME})

    foreach(package_name IN LISTS packages)
        message(STATUS "[brokkr] Importing package \"${package_name}\".")
        # Do we need "GLOBAL"? (https://cmake.org/cmake/help/latest/command/find_package.html)
        find_package("${package_name}" REQUIRED)
    endforeach()

    if(BKR_ENSF_OUTPUT_PACKAGES)
        set(${BKR_ENSF_OUTPUT_PACKAGES} ${packages} PARENT_SCOPE)
    endif()
endfunction()


function(_bkr_get_proj_prop OUTPUT_VARIABLE PROPERTY_NAME)
    get_property(
        property_value
        GLOBAL
        PROPERTY "brokkr_${PROJECT_NAME}_${PROPERTY_NAME}"
    )
    set(
        ${OUTPUT_VARIABLE}
        ${property_value}
        PARENT_SCOPE
    )
endfunction()


function(_bkr_append_proj_prop PROPERTY_NAME)
    _bkr_get_proj_prop(property_value ${PROPERTY_NAME})

    list(APPEND property_value ${ARGN})
    list(SORT property_value)
    list(REMOVE_DUPLICATES property_value)

    set_property(
        GLOBAL
        PROPERTY "brokkr_${PROJECT_NAME}_${PROPERTY_NAME}"
        ${property_value}
    )
endfunction()


# Log the target as "ready to install." It will not actually be installed
# until a later call to `brokkr_package()`.
#
# :param TARGET_NAME: Name of the target to install.
# :type TARGET_NAME: String.
# :param REQUIRED_PACKAGES: Package dependencies of the target to install.
# :type REQUIRED_PACKAGES: List of strings.
function(brokkr_install_target TARGET_NAME)
    cmake_parse_arguments(
        PARSE_ARGV 1
        BKR_ITGT
        ""
        ""
        "REQUIRED_PACKAGES"
    )

    if(NOT TARGET "${TARGET_NAME}")
        message(
            FATAL_ERROR
            "\"${TARGET_NAME}\" does not name a target. Cannot add it to the "
            "export set."
        )
    endif()

    _bkr_append_proj_prop("targets" "${TARGET_NAME}")
    if(BKR_ITGT_REQUIRED_PACKAGES)
        _bkr_append_proj_prop("dependencies" ${BKR_ITGT_REQUIRED_PACKAGES})
    endif()
endfunction()
