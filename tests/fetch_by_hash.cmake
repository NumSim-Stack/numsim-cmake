file(READ "${WORK}/side.sha" _sha)
execute_process(COMMAND ${CMAKE_COMMAND} -S ${WORK}/devel/consumer -B ${WORK}/build-hash
                        -DNUMSIM_CMAKE_MODULES=${MODULES} -DDEPA_REPOSITORY=${WORK}/depa.git
                        -DDEPA_TAG=${_sha} -DNUMSIM_PREFER_SIBLINGS=OFF
                COMMAND_ERROR_IS_FATAL ANY)
