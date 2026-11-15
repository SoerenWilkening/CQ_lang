# tests/eff-fenv (cq-w1-eff-fenv): rule 23 probes and the owned examples through the real cq-lower plugin.
add_test(NAME eff-fenv
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_eff_fenv.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-9kcq S12 (CR rules 14, 23; ROLLED_DESIGN.md §4): the quantum floating-point environment changed in a K-loop's trips
# and read after it (a raising op, feraiseexcept, fesetround with a quantum argument, a clone carrying the environment),
# and a K-loop that only reads it. Each entry §6-checked against its C program under the rolled driver: CQ_K_ROLLED=1 is
# set here until S14 makes the rolled form the default and deletes the switch (remove the ENVIRONMENT entry then).
add_test(NAME eff-fenv-kloop-state
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tests/loops-cutoff/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 600
          ${CMAKE_CURRENT_SOURCE_DIR}/kloop/kloop_state.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(eff-fenv-kloop-state PROPERTIES ENVIRONMENT "CQ_K_ROLLED=1")
