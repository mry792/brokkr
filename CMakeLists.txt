cmake_minimum_required(VERSION 3.23 FATAL_ERROR)

include(./cmake/brokkr/package.cmake)
include(./cmake/brokkr/versioning.cmake)

project(brokkr VERSION 1.2)
brokkr_project_version_from_git()

brokkr_package(
    CONFIG_TEMPLATE cmake/templates/config.cmake.in
    EXTRA_CONFIG
        cmake/brokkr/package.cmake
        cmake/brokkr/versioning.cmake
)
