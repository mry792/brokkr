
# Derive a version suitable for CMake from a recent git tag.
#
# This expects the recent git tag to be of the form "vX[.Y[.Z]]". If the most
# recent commit is not the one identified by the tag, then the resultant
# version number will include a "tweak" component representing the number of
# commits since the tag in question. In this case, any missing version
# components from the will be auto-filled with "0".
#
# This will populate the version variables normally populated by the CMake
# `project()` command.
function(brokkr_project_version_from_git)
    # Get recent tag description from git.
    find_package(Git REQUIRED)
    execute_process(
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND ${GIT_EXECUTABLE} describe --tags --dirty
        OUTPUT_VARIABLE raw_git_description
    )
    string(STRIP "${raw_git_description}" git_description)
    message(DEBUG "[brokkr] Tag description from git: \"${git_description}\"")

    # Extract the version numbers from the git tag description.
    set(tag_regex "v([0-9]+)(\\.([0-9]+))?(\\.([0-9]+))?")
    set(annotation_regex "(-([0-9]+)-g[0-9a-f]+)?")
    set(description_regex "${tag_regex}${annotation_regex}")
    string(REGEX MATCH ${description_regex} _unused_ "${git_description}")

    # Check for a "commits since tag" count first. If this prompts a tweak
    # version component, any missing components should be "0" instead of
    # empty.
    set(default "")
    set(tweak "${CMAKE_MATCH_7}")
    if(tweak)
        set(default "0")
    endif()

    # Derive remaining version components using the default specified above.
    set(major "${CMAKE_MATCH_1}")
    _bkr_set_with_default(minor "${CMAKE_MATCH_3}" "${default}")
    _bkr_set_with_default(patch "${CMAKE_MATCH_5}" "${default}")

    # Assemble the full version string.
    string(JOIN "." version ${major} ${minor} ${patch} ${tweak})
    message(STATUS "[brokkr] Deduced project version from git: ${version}")

    # Set output variables.
    set(CMAKE_PROJECT_VERSION "${version}" PARENT_SCOPE)
    set(PROJECT_VERSION "${version}" PARENT_SCOPE)
    set(PROJECT_VERSION_MAJOR "${major}" PARENT_SCOPE)
    set(PROJECT_VERSION_MINOR "${minor}" PARENT_SCOPE)
    set(PROJECT_VERSION_PATCH "${patch}" PARENT_SCOPE)
    set(PROJECT_VERSION_TWEAK "${tweak}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION "${version}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_MAJOR "${major}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_MINOR "${minor}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_PATCH "${patch}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_TWEAK "${tweak}" PARENT_SCOPE)
endfunction()
