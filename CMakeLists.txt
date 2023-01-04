cmake_minimum_required(VERSION 3.23 FATAL_ERROR)
project(brokkr VERSION 0.0.1)

###
# Install Package
###

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    brokkr/${PROJECT_NAME}-config-version.cmake
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY SameMajorVersion
)
configure_package_config_file(
    cmake/templates/config.cmake.in
    brokkr/${PROJECT_NAME}-config.cmake
    INSTALL_DESTINATION lib/cmake/${PROJECT_NAME}
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/brokkr/${PROJECT_NAME}-config-version.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/brokkr/${PROJECT_NAME}-config.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)
