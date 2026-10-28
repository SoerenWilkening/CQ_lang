# tests/mem-qrom (cq-w1-mem-qrom): rule 20 QROM probes and the owned examples through the real cq-lower plugin.
add_test(NAME mem-qrom
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_mem_qrom.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
