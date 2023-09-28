
# Populate the version variables normally populated by the CMake `project
# ()` command.
#
# :param VERSION: Full version string. Must be of the form "X[.Y[.Z[.T]]]]".
# :param MAJOR: first version component (X)
# :param MINOR: second version component (Y)
# :param PATCH: third version component (Z)
# :param TWEAK: fourth version component (T)
macro(_bkr_set_version_vars VERSION MAJOR MINOR PATCH TWEAK)
    if(PROJECT_NAME EQUAL CMAKE_PROJECT_NAME)
        set(CMAKE_PROJECT_VERSION "${VERSION}" PARENT_SCOPE)
    endif()

    set(PROJECT_VERSION "${VERSION}" PARENT_SCOPE)
    set(PROJECT_VERSION_MAJOR "${MAJOR}" PARENT_SCOPE)
    set(PROJECT_VERSION_MINOR "${MINOR}" PARENT_SCOPE)
    set(PROJECT_VERSION_PATCH "${PATCH}" PARENT_SCOPE)
    set(PROJECT_VERSION_TWEAK "${TWEAK}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION "${VERSION}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_MAJOR "${MAJOR}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_MINOR "${MINOR}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_PATCH "${PATCH}" PARENT_SCOPE)
    set(${PROJECT_NAME}_VERSION_TWEAK "${TWEAK}" PARENT_SCOPE)
endmacro()


# Set the current project version.
#
# :param VERSION: Full version string. Must be of the form "X[.Y[.Z[.T]]]]".
macro(_bkr_project_version VERSION)
    set(comp_regex "([0-9]+)")
    set(version_regex "^${comp_regex}(\\.${comp_regex}(\\.${comp_regex}(\\.${comp_regex})?)?)?$")
    string(REGEX MATCH ${version_regex} full_match "${VERSION}")

    if(full_match STREQUAL "")
        message(
            FATAL_ERROR
            "[brokkr] Specified version string \"${VERSION}\" is not valid. Must match \"X[.Y[.Z[.T]]]]\"."
        )
    endif()

    _bkr_set_version_vars(
        ${VERSION}
        "${CMAKE_MATCH_1}"
        "${CMAKE_MATCH_3}"
        "${CMAKE_MATCH_5}"
        "${CMAKE_MATCH_7}"
    )
endmacro()


# Derive a version suitable for CMake from a recent git tag.
#
# This expects the recent git tag to be of the form "vX[.Y[.Z]]". If the most
# recent commit is not the one identified by the tag, then the resultant
# version number will include a "tweak" component representing the number of
# commits since the tag in question. In this case, any missing version
# components from the tag will be auto-filled with "0".
#
# This will populate the version variables normally populated by the CMake
# `project()` command.
macro(_bkr_project_version_from_git)
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

    # Set vars.
    _bkr_set_version_vars(${version} "${major}" "${minor}" "${patch}" "${tweak}")
endmacro()


# Derive a version suitable for CMake from the environment.
#
# This tries the following mechanisms in order:
#
#  1) If this is the top-level project, the version will be pulled from the
#     @c BROKKR_THIS_PROJECT_VERSION cache variable. It must be in the form
#     "X[.Y[.Z[.T]]]]".
#
#  2) If there is a git repo rooted in the same directory this function is
#     called from, it will try and pull the version from a recent git tag. The
#     tag must be of the form "vX[.Y[.Z]]". If the most recent commit is not
#     the one identified by the tag, then the resultant version number will
#     include a "tweak" component representing the number of commits since the
#     tag in question. In this case, any missing version components from the
#     tag will be auto-filled with "0".
#
# This will populate the version variables normally populated by the CMake
# `project()` command.
function(brokkr_deduce_project_version)
    if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
        if(DEFINED BROKKR_THIS_PROJECT_VERSION)
            _bkr_project_version("${BROKKR_THIS_PROJECT_VERSION}")
            return()
        endif()
    endif()

    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.git)
        _bkr_project_version_from_git()
        return()
    endif()

    message(WARNING "[brokkr] Filed to deduce \"${PROJECT_NAME}\" project version.")
endfunction()
