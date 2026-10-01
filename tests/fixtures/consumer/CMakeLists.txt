cmake_minimum_required(VERSION 3.25)
project(consumer LANGUAGES NONE)
list(APPEND CMAKE_MODULE_PATH "${NUMSIM_CMAKE_MODULES}")
include(NumSimDependency)
numsim_dependency(depa
    TARGET depa::depa
    GIT_REPOSITORY "${DEPA_REPOSITORY}"
    GIT_TAG        ${DEPA_TAG}
    SIBLING        depa
    NO_FIND_PACKAGE
    OPTIONS DEPA_TESTS=OFF)
if(NOT TARGET depa::depa)
    message(FATAL_ERROR "depa target missing")
endif()
message(STATUS "RESOLVED=${numsim_dependency_depa_SOURCE}")
