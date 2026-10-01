set(_work ${CMAKE_CURRENT_BINARY_DIR}/work)
set(_modules ${PROJECT_SOURCE_DIR}/cmake)
set(_fixtures ${CMAKE_CURRENT_SOURCE_DIR}/fixtures)

add_test(NAME setup COMMAND ${CMAKE_COMMAND} -DWORK=${_work} -DFIXTURES=${_fixtures}
                            -P ${CMAKE_CURRENT_SOURCE_DIR}/setup.cmake)
set_tests_properties(setup PROPERTIES FIXTURES_SETUP layout)

# Each case configures the consumer with different settings and checks how
# numsim_dependency resolved depa.
function(dependency_case name expected)
    add_test(NAME dependency.${name}
             COMMAND ${CMAKE_COMMAND} -S ${_work}/devel/consumer -B ${_work}/build-${name}
                     -DNUMSIM_CMAKE_MODULES=${_modules} -DDEPA_REPOSITORY=${_work}/depa.git
                     -DDEPA_TAG=v1 ${ARGN})
    set_tests_properties(dependency.${name} PROPERTIES FIXTURES_REQUIRED layout
                         PASS_REGULAR_EXPRESSION "RESOLVED=${expected}")
endfunction()

# pinned to a commit hash on a side branch (no shallow clone possible)
add_test(NAME dependency.fetched_by_hash
         COMMAND ${CMAKE_COMMAND} -DWORK=${_work} -DMODULES=${_modules}
                 -P ${CMAKE_CURRENT_SOURCE_DIR}/fetch_by_hash.cmake)
set_tests_properties(dependency.fetched_by_hash PROPERTIES FIXTURES_REQUIRED layout
                     PASS_REGULAR_EXPRESSION "depa side branch")

# 3. sibling checkout next to the top-level project (default)
dependency_case(sibling "sibling")
# 2. explicit FETCHCONTENT_SOURCE_DIR override wins over the sibling
dependency_case(override "override" -DFETCHCONTENT_SOURCE_DIR_DEPA=${_work}/src/depa)
# 5. pinned fetch when siblings are disabled
dependency_case(fetched "fetched v1" -DNUMSIM_PREFER_SIBLINGS=OFF)
# siblings elsewhere: NUMSIM_DEVEL_DIR points to a directory without depa
dependency_case(no_sibling "fetched v1" -DNUMSIM_DEVEL_DIR=${_work})

# OPTIONS reach the subproject (DEPA_TESTS=OFF) without FORCE
add_test(NAME dependency.options
         COMMAND ${CMAKE_COMMAND} -S ${_work}/devel/consumer -B ${_work}/build-options
                 -DNUMSIM_CMAKE_MODULES=${_modules} -DDEPA_REPOSITORY=${_work}/depa.git -DDEPA_TAG=v1)
set_tests_properties(dependency.options PROPERTIES FIXTURES_REQUIRED layout
                     PASS_REGULAR_EXPRESSION "DEPA_TESTS=OFF")
