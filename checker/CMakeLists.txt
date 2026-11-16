# The checker's tool cache (cq-8m6v): the evaluator runtime objects, the probe runtime and the C
# oracle's plugin, prebuilt so that no example run pays for them (checker/cqcheck/prebuild.py). Every
# entry is keyed by its sources' content; the stamp only spares a rerun of the (cheap) check.
file(GLOB CQCHECK_TOOL_INPUTS LIST_DIRECTORIES false CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/rt/*" "${CMAKE_CURRENT_SOURCE_DIR}/oracle/*"
     "${CMAKE_CURRENT_SOURCE_DIR}/cqcheck/*.py" "${CMAKE_CURRENT_SOURCE_DIR}/native/*"
     "${CMAKE_SOURCE_DIR}/pass/lib/taint/*" "${CMAKE_SOURCE_DIR}/pass/lib/spine/*"
     "${CMAKE_SOURCE_DIR}/pass/lib/abi/*" "${CMAKE_SOURCE_DIR}/pass/lib/Common.cpp"
     "${CMAKE_SOURCE_DIR}/pass/lib/calls/LibCalls.cpp" "${CMAKE_SOURCE_DIR}/pass/lib/calls/LibCalls.h"
     "${CMAKE_SOURCE_DIR}/pass/include/*")
add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/cqcheck-tools/prebuild.stamp"
  COMMAND ${CMAKE_COMMAND} -E env "CQ_BUILD_DIR=${CMAKE_BINARY_DIR}"
          ${Python3_EXECUTABLE} -m cqcheck.prebuild
  COMMAND ${CMAKE_COMMAND} -E touch "${CMAKE_BINARY_DIR}/cqcheck-tools/prebuild.stamp"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS ${CQCHECK_TOOL_INPUTS}
  COMMENT "cqcheck: prebuilding the checker's tool cache")
add_custom_target(cqcheck_tools ALL DEPENDS "${CMAKE_BINARY_DIR}/cqcheck-tools/prebuild.stamp")
