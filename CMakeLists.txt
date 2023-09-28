cmake_minimum_required(VERSION 3.23 FATAL_ERROR)
project(brokkr LANGUAGES)

include(./cmake/brokkr/helpers.cmake)
include(./cmake/brokkr/package.cmake)
include(./cmake/brokkr/versioning.cmake)
brokkr_deduce_project_version()

brokkr_package(
    CONFIG_TEMPLATE cmake/templates/config.cmake.in
    EXTRA_CONFIG
        cmake/brokkr/dirs.cmake
        cmake/brokkr/executable.cmake
        cmake/brokkr/helpers.cmake
        cmake/brokkr/library.cmake
        cmake/brokkr/package.cmake
        cmake/brokkr/versioning.cmake
)

install(
    FILES cmake/templates/config.cmake.in
    DESTINATION lib/cmake/brokkr/templates
)
