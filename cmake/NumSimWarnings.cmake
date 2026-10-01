# numsim_target_warnings(<target> [WERROR]) -- the warning set the NumSim
# libraries build their own code with.
function(numsim_target_warnings TARGET_NAME)
    cmake_parse_arguments(ARG "WERROR" "" "" ${ARGN})
    set(_flags $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic -Wconversion>)
    if(ARG_WERROR)
        list(APPEND _flags $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror>)
    endif()
    target_compile_options(${TARGET_NAME} PRIVATE ${_flags})
endfunction()
