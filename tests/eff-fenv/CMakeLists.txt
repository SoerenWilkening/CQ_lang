# tests/eff-fenv (cq-w1-eff-fenv): rule 23 probes and the owned examples through the real cq-lower plugin.
add_test(NAME eff-fenv
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_eff_fenv.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
