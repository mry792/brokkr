
function(_bkr_package_names_from_targets OUTPUT_PACKAGES OUTPUT_LOOSE)
    set(package_names)
    set(loose_names)

    foreach(target_name IN LISTS ARGN)
        string(FIND "${target_name}" "::" ns_position)
        if("${ns_position}" EQUAL "-1")
            list(APPEND loose_names ${target_name})
        else()
            string(SUBSTRING "${target_name}" 0 ${ns_position} package_name)
            list(APPEND package_names "${package_name}")
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
            "Dependency \"${target_name}\" is neither an existing target nor "
            "a package-qualified name. Cannot auto-import it."
        )
    endforeach()

    list(APPEND packages ${BKR_ENSF_PACKAGES})
    list(SORT packages)
    list(REMOVE_DUPLICATES packages)
    list(REMOVE_ITEM packages ${PACKAGE_NAME})

    foreach(package_name IN LISTS packages)
        # Do we need "GLOBAL"? (https://cmake.org/cmake/help/latest/command/find_package.html)
        find_package("${package_name}" REQUIRED)
    endforeach()

    if(BKR_ENSF_OUTPUT_PACKAGES)
        set(${BKR_ENSF_OUTPUT_PACKAGES} ${packages} PARENT_SCOPE)
    endif()
endfunction()
