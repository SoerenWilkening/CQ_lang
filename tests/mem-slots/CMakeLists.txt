# tests/mem-slots (cq-w1-mem-slots): rule 20 probes and the owned examples through the real cq-lower plugin.
add_test(NAME mem-slots
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_mem_slots.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
