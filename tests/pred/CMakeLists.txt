# Module pred (cq-w0-pred) unit tests. The example IR is read from the pinned CQ_spec (read-only).
cq_add_unit_test(pred_unit PredTest.cpp)
target_include_directories(pred_unit PRIVATE "${CMAKE_SOURCE_DIR}/pass/lib/pred")
target_compile_definitions(pred_unit PRIVATE CQ_SPEC_DIR="${CQ_SPEC_DIR}")

# cq-1b92: C probes through the real plugin, §6 against their C programs (cqcheck user).
add_test(NAME pred_probes
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_pred_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

# cq-tdqrq: the leak rule on a real host exit, the exit status, their mutants.
add_test(NAME pred_host_end
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_host_end.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
