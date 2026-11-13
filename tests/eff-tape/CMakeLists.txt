# tests/eff-tape (cq-w1-eff-tape): rule 16 probes and the owned examples through the real cq-lower plugin.
add_test(NAME eff-tape
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_eff_tape.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# rulings Q2 (owner 2026-11-11, cq-auqs3): an input is excluded only on the C program's object holding a rail
add_test(NAME eff-tape-q2
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/q2/run_q2.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(eff-tape-q2 PROPERTIES ENVIRONMENT "CQ_BUILD_DIR=${CMAKE_BINARY_DIR};CQ_SPEC_DIR=${CQ_SPEC_DIR}")
# cq-025xt (owner 2026-11-13): an ordinary host call's and an unchanged module's results are the host's; an entry's musl's
add_test(NAME eff-tape-host-results
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/host_results/run_host_results.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(eff-tape-host-results PROPERTIES ENVIRONMENT "CQ_BUILD_DIR=${CMAKE_BINARY_DIR};CQ_SPEC_DIR=${CQ_SPEC_DIR}")
