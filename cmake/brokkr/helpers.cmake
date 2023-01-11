
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
