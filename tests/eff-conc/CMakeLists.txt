# tests/eff-conc (cq-w1-eff-conc): rule 24 probes through the real cq-lower plugin.
add_test(NAME eff-conc
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_eff_conc.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
