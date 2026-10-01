# numsim_target_warnings(<target> [WERROR]) -- the warning set the NumSim
# libraries build their own code with: -Wall -Wextra -Wpedantic -Wconversion.
# Clang's -Wconversion also enables -Wsign-conversion, GCC's (in C++) does
# not; it is switched off on Clang so both compilers enforce the same set.
function(numsim_target_warnings TARGET_NAME)
    cmake_parse_arguments(ARG "WERROR" "" "" ${ARGN})
    set(_flags $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic -Wconversion>
               $<$<CXX_COMPILER_ID:Clang,AppleClang>:-Wno-sign-conversion>)
    if(ARG_WERROR)
        list(APPEND _flags $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror>)
    endif()
    target_compile_options(${TARGET_NAME} PRIVATE ${_flags})
endfunction()
