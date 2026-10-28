# tests/mem-qram (cq-alez): rule 22 memory-intrinsic probes through the real cq-lower plugin.
add_test(NAME mem-qram
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_mem_qram.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
