cmake_minimum_required(VERSION 3.23 FATAL_ERROR)
project(brokkr VERSION 0.0.1)

include(./cmake/brokkr/package.cmake)
brokkr_package(CONFIG_TEMPLATE cmake/templates/config.cmake.in)
