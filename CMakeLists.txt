cmake_minimum_required(VERSION 3.25)
project(numsim-cmake VERSION 0.1.0 LANGUAGES NONE
        DESCRIPTION "Shared CMake modules of the NumSim libraries")

# Nothing to build. Consumers add cmake/ to CMAKE_MODULE_PATH (see
# bootstrap.cmake). `cmake -S . -B build && ctest --test-dir build` runs the
# module tests.
include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
