file(READ "${WORK}/side.sha" _sha)
execute_process(COMMAND ${CMAKE_COMMAND} -S ${WORK}/devel/consumer -B ${WORK}/build-hash
                        -DNUMSIM_CMAKE_MODULES=${MODULES} -DDEPA_REPOSITORY=${WORK}/depa.git
                        -DDEPA_TAG=${_sha} -DNUMSIM_PREFER_SIBLINGS=OFF
                COMMAND_ERROR_IS_FATAL ANY)
# the generated clone step must not be shallow for a hash pin
file(READ "${WORK}/build-hash/_deps/depa-subbuild/CMakeLists.txt" _sub)
if(_sub MATCHES "GIT_SHALLOW")
  message(FATAL_ERROR "hash pin was cloned shallow")
endif()
