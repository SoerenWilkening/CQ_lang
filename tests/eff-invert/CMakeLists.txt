# tests/eff-invert (cq-w1-eff-invert): rule 17 cq_invert regions through the real cq-lower plugin.
add_test(NAME eff-invert
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_eff_invert.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
