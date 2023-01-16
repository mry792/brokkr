cmake_minimum_required(VERSION 3.23 FATAL_ERROR)
project(brokkr)

include(./cmake/brokkr/helpers.cmake)
include(./cmake/brokkr/package.cmake)
include(./cmake/brokkr/versioning.cmake)
brokkr_project_version_from_git()

brokkr_package(
    CONFIG_TEMPLATE cmake/templates/config.cmake.in
    EXTRA_CONFIG
        cmake/brokkr/executable.cmake
        cmake/brokkr/helpers.cmake
        cmake/brokkr/package.cmake
        cmake/brokkr/versioning.cmake
)
