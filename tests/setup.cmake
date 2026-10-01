# Prepares a scratch layout for the dependency tests:
#   <work>/devel/consumer   copy of the fixture consumer (top-level project)
#   <work>/devel/depa       sibling checkout of depa
#   <work>/depa.git         bare git repository of depa with tag v1
file(REMOVE_RECURSE "${WORK}")
file(MAKE_DIRECTORY "${WORK}/devel")
file(COPY "${FIXTURES}/consumer" DESTINATION "${WORK}/devel")
file(COPY "${FIXTURES}/depa" DESTINATION "${WORK}/devel")
file(COPY "${FIXTURES}/depa" DESTINATION "${WORK}/src")
find_package(Git REQUIRED)
set(_d "${WORK}/src/depa")
execute_process(COMMAND ${GIT_EXECUTABLE} init -q -b main WORKING_DIRECTORY ${_d} COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${GIT_EXECUTABLE} -c user.name=t -c user.email=t@t add . WORKING_DIRECTORY ${_d} COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${GIT_EXECUTABLE} -c user.name=t -c user.email=t@t commit -q -m init WORKING_DIRECTORY ${_d} COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${GIT_EXECUTABLE} tag v1 WORKING_DIRECTORY ${_d} COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${GIT_EXECUTABLE} clone -q --bare ${_d} ${WORK}/depa.git COMMAND_ERROR_IS_FATAL ANY)
