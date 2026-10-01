# NumSimTesting.cmake -- GoogleTest executables with sanitizer variants.
#
#   numsim_add_test(<name> SOURCES <src...> LINK <targets...>
#                   [MPI_PROCS <n...>] [NO_MAIN] [NO_SANITIZERS] [TSAN]
#                   [INCLUDE_DIRS <dirs...>])
#
# Builds <name> (linked to GTest::gtest, and GTest::gtest_main unless NO_MAIN)
# and registers it with ctest (gtest_discover_tests, or one mpiexec run per
# MPI_PROCS count). With NUMSIM_SANITIZER_TESTS the same sources are built
# again with AddressSanitizer + UndefinedBehaviorSanitizer (<name>_asan) and,
# if TSAN is given, with ThreadSanitizer (<name>_tsan). NO_SANITIZERS skips
# the variants (e.g. HPX, which needs its own sanitizer build). TSan is
# opt-in: it reports false positives through uninstrumented runtimes such as
# libgomp and Open MPI.
#
# Requires: include(GoogleTest), a GTest target, and for MPI tests the
# variables of find_package(MPI).

include(GoogleTest)

option(NUMSIM_SANITIZER_TESTS
       "Also build and run the tests under ASan+UBSan (and TSan where threads are involved)" ON)
if(NUMSIM_SANITIZER_TESTS AND NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    message(WARNING "NumSim: sanitizer tests need GCC or Clang; disabled")
    set(NUMSIM_SANITIZER_TESTS OFF)
endif()

set(NUMSIM_ASAN_FLAGS -fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=undefined)
set(NUMSIM_TSAN_FLAGS -fsanitize=thread -fno-omit-frame-pointer)

# libtsan (GCC 13) aborts with "unexpected memory mapping" under the ASLR
# entropy of recent kernels: TSan binaries run without ASLR.
find_program(NUMSIM_SETARCH setarch)
mark_as_advanced(NUMSIM_SETARCH)

# Open MPI needs --oversubscribe to run more ranks than cores; other MPIs
# reject the flag.
set(NUMSIM_MPIEXEC_PREFLAGS)
if(MPIEXEC_EXECUTABLE)
    execute_process(COMMAND ${MPIEXEC_EXECUTABLE} --version OUTPUT_VARIABLE _numsim_mpiexec_version
                    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_numsim_mpiexec_version MATCHES "Open MPI|OpenRTE|open-mpi|PRTE")
        set(NUMSIM_MPIEXEC_PREFLAGS --oversubscribe)
    endif()
endif()

function(_numsim_test_executable TARGET_NAME)
    cmake_parse_arguments(ARG "NO_MAIN" "" "SOURCES;FLAGS;LINK;INCLUDE_DIRS" ${ARGN})
    add_executable(${TARGET_NAME} ${ARG_SOURCES})
    target_include_directories(${TARGET_NAME} PRIVATE ${ARG_INCLUDE_DIRS})
    target_link_libraries(${TARGET_NAME} PRIVATE ${ARG_LINK} GTest::gtest)
    if(NOT ARG_NO_MAIN)
        target_link_libraries(${TARGET_NAME} PRIVATE GTest::gtest_main)
    endif()
    numsim_target_warnings(${TARGET_NAME} WERROR)
    target_compile_options(${TARGET_NAME} PRIVATE ${ARG_FLAGS})
    target_link_options(${TARGET_NAME} PRIVATE ${ARG_FLAGS})
endfunction()

function(_numsim_register_test TARGET_NAME SUFFIX)
    cmake_parse_arguments(ARG "" "" "MPI_PROCS;ENVIRONMENT" ${ARGN})
    if(ARG_MPI_PROCS)
        foreach(np IN LISTS ARG_MPI_PROCS)
            add_test(NAME ${TARGET_NAME}_np${np}${SUFFIX}
                     COMMAND ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${np}
                             ${NUMSIM_MPIEXEC_PREFLAGS} ${MPIEXEC_PREFLAGS}
                             $<TARGET_FILE:${TARGET_NAME}> ${MPIEXEC_POSTFLAGS})
            set_tests_properties(${TARGET_NAME}_np${np}${SUFFIX} PROPERTIES
                                 PROCESSORS ${np} ENVIRONMENT "${ARG_ENVIRONMENT}")
        endforeach()
    else()
        gtest_discover_tests(${TARGET_NAME} DISCOVERY_TIMEOUT 120 TEST_SUFFIX "${SUFFIX}"
                             PROPERTIES ENVIRONMENT "${ARG_ENVIRONMENT}")
    endif()
endfunction()

function(numsim_add_test TARGET_NAME)
    cmake_parse_arguments(ARG "NO_MAIN;NO_SANITIZERS;TSAN" "" "SOURCES;MPI_PROCS;LINK;INCLUDE_DIRS" ${ARGN})
    set(_main_arg)
    if(ARG_NO_MAIN)
        set(_main_arg NO_MAIN)
    endif()
    set(_common ${_main_arg} SOURCES ${ARG_SOURCES} LINK ${ARG_LINK} INCLUDE_DIRS ${ARG_INCLUDE_DIRS})

    _numsim_test_executable(${TARGET_NAME} ${_common})
    _numsim_register_test(${TARGET_NAME} "" MPI_PROCS ${ARG_MPI_PROCS})

    if(NUMSIM_SANITIZER_TESTS AND NOT ARG_NO_SANITIZERS)
        set(_asan_env "UBSAN_OPTIONS=print_stacktrace=1")
        if(ARG_MPI_PROCS)
            list(APPEND _asan_env "ASAN_OPTIONS=detect_leaks=0") # Open MPI leaks at shutdown
        endif()
        _numsim_test_executable(${TARGET_NAME}_asan ${_common} FLAGS ${NUMSIM_ASAN_FLAGS})
        _numsim_register_test(${TARGET_NAME}_asan "_asan" MPI_PROCS ${ARG_MPI_PROCS} ENVIRONMENT ${_asan_env})
        if(ARG_TSAN)
            _numsim_test_executable(${TARGET_NAME}_tsan ${_common} FLAGS ${NUMSIM_TSAN_FLAGS})
            if(NUMSIM_SETARCH)
                set_target_properties(${TARGET_NAME}_tsan PROPERTIES
                    CROSSCOMPILING_EMULATOR "${NUMSIM_SETARCH};${CMAKE_HOST_SYSTEM_PROCESSOR};-R")
            endif()
            _numsim_register_test(${TARGET_NAME}_tsan "_tsan" MPI_PROCS ${ARG_MPI_PROCS}
                                  ENVIRONMENT "TSAN_OPTIONS=halt_on_error=1")
        endif()
    endif()
endfunction()
