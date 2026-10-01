# NumSimDependency.cmake -- one convention for third-party and in-house
# dependencies across the NumSim libraries.
#
#   numsim_dependency(<name>
#       TARGET <target>                 # target that proves the dependency is present
#       GIT_REPOSITORY <url> GIT_TAG <tag-or-sha>
#       [SIBLING <dirname>]             # checkout next to the top-level project
#       [FIND_PACKAGE_ARGS <args...>]   # e.g. CONFIG, NAMES GTest, 1.2 ...
#       [NO_FIND_PACKAGE]               # never use an installed copy
#       [OPTIONS <VAR=value>...]        # cache variables for the subproject
#       [SOURCE_SUBDIR <dir>])
#
# Resolution order (first hit wins):
#   1. the TARGET already exists (another dependency brought it in);
#   2. FETCHCONTENT_SOURCE_DIR_<NAME> is set by the user: that checkout;
#   3. NUMSIM_PREFER_SIBLINGS and <NUMSIM_DEVEL_DIR>/<SIBLING> exists: that
#      checkout (the NumSim-Stack development layout);
#   4. find_package(<name> <FIND_PACKAGE_ARGS> QUIET), unless NO_FIND_PACKAGE;
#   5. FetchContent from GIT_REPOSITORY at the pinned GIT_TAG.
#
# Sources added as subdirectories are SYSTEM (their headers do not trigger
# the including project's -Werror warnings). OPTIONS are set as cache
# variables *without* FORCE, which is enough for subprojects whose option()
# calls run under CMP0077 NEW (CMake >= 3.13 minimum), and they are never
# touched when the dependency comes from find_package.
#
# This is a macro so that the variables FetchContent defines
# (<lowercaseName>_SOURCE_DIR, ...) land in the caller's scope.

include(FetchContent)

option(NUMSIM_PREFER_SIBLINGS
       "Use sibling checkouts (<NUMSIM_DEVEL_DIR>/<name>) of NumSim dependencies when present" ON)
set(NUMSIM_DEVEL_DIR "${CMAKE_SOURCE_DIR}/.." CACHE PATH
    "Directory holding sibling checkouts of the NumSim libraries")

macro(numsim_dependency _nd_name)
    cmake_parse_arguments(_nd "NO_FIND_PACKAGE" "TARGET;GIT_REPOSITORY;GIT_TAG;SIBLING;SOURCE_SUBDIR"
                          "FIND_PACKAGE_ARGS;OPTIONS" ${ARGN})
    if(NOT _nd_TARGET OR NOT _nd_GIT_REPOSITORY OR NOT _nd_GIT_TAG)
        message(FATAL_ERROR "numsim_dependency(${_nd_name}): TARGET, GIT_REPOSITORY and GIT_TAG are required")
    endif()
    string(TOUPPER "${_nd_name}" _nd_upper)

    if(TARGET ${_nd_TARGET})
        set(numsim_dependency_${_nd_name}_SOURCE "target")
    else()
        set(_nd_source_dir "")
        if(DEFINED FETCHCONTENT_SOURCE_DIR_${_nd_upper} AND NOT "${FETCHCONTENT_SOURCE_DIR_${_nd_upper}}" STREQUAL "")
            set(_nd_source_dir "${FETCHCONTENT_SOURCE_DIR_${_nd_upper}}")
            set(numsim_dependency_${_nd_name}_SOURCE "override")
        elseif(NUMSIM_PREFER_SIBLINGS AND _nd_SIBLING AND EXISTS "${NUMSIM_DEVEL_DIR}/${_nd_SIBLING}/CMakeLists.txt")
            get_filename_component(_nd_source_dir "${NUMSIM_DEVEL_DIR}/${_nd_SIBLING}" ABSOLUTE)
            set(numsim_dependency_${_nd_name}_SOURCE "sibling")
        endif()

        set(_nd_found FALSE)
        if(NOT _nd_source_dir AND NOT _nd_NO_FIND_PACKAGE)
            find_package(${_nd_name} ${_nd_FIND_PACKAGE_ARGS} QUIET)
            if(TARGET ${_nd_TARGET})
                set(_nd_found TRUE)
                set(numsim_dependency_${_nd_name}_SOURCE "installed")
            endif()
        endif()

        if(NOT _nd_found)
            foreach(_nd_opt IN LISTS _nd_OPTIONS)
                string(REGEX MATCH "^([^=]+)=(.*)$" _nd_m "${_nd_opt}")
                set(${CMAKE_MATCH_1} "${CMAKE_MATCH_2}" CACHE STRING "${_nd_name}: set by numsim_dependency")
            endforeach()
            set(_nd_subdir_args)
            if(_nd_SOURCE_SUBDIR)
                set(_nd_subdir_args SOURCE_SUBDIR ${_nd_SOURCE_SUBDIR})
            endif()
            if(_nd_source_dir)
                # FetchContent honours FETCHCONTENT_SOURCE_DIR_<NAME> and skips the download.
                set(FETCHCONTENT_SOURCE_DIR_${_nd_upper} "${_nd_source_dir}")
            else()
                set(numsim_dependency_${_nd_name}_SOURCE "fetched ${_nd_GIT_TAG}")
            endif()
            FetchContent_Declare(${_nd_name}
                GIT_REPOSITORY ${_nd_GIT_REPOSITORY}
                GIT_TAG        ${_nd_GIT_TAG}
                GIT_SHALLOW    TRUE
                SYSTEM
                ${_nd_subdir_args})
            FetchContent_MakeAvailable(${_nd_name})
            if(NOT TARGET ${_nd_TARGET})
                message(FATAL_ERROR "numsim_dependency(${_nd_name}): ${numsim_dependency_${_nd_name}_SOURCE} did not provide target ${_nd_TARGET}")
            endif()
        endif()
    endif()
    message(STATUS "${PROJECT_NAME}: ${_nd_name} (${numsim_dependency_${_nd_name}_SOURCE})")
    unset(_nd_source_dir)
    unset(_nd_found)
endmacro()
