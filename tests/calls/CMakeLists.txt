# Unit tests of calls::finalize (cq-by8) and of the twins it defines (cq-w1-calls): constructed modules run through finalize, the surviving
# module compared. With no argument the binary runs every positive case; each case is also its own
# test, and each fatal case must fail with its named error.
cq_add_unit_test(calls_finalize_tests finalize_tests.cpp)

set(CQ_CALLS_CASES
  noop_no_clone noop_clone_namespace_absent drop_retargeted keep_classical_caller keep_address_taken
  keep_used_global drop_mutual_recursion drop_chain keep_live_chain drop_external_original keep_inplace_entry
  drop_dead_references keep_shared_references declared_clone_only twin_only
  twin_define twin_fieldwise twin_chain twin_pure twin_declared twin_return_phi)
foreach(c ${CQ_CALLS_CASES})
  add_test(NAME calls.${c} COMMAND calls_finalize_tests ${c})
endforeach()

set(CQ_CALLS_FATAL
  "fatal_materialize_no_taint=cq: internal error: calls: materialize of a clone before any call site of the run")
foreach(entry ${CQ_CALLS_FATAL})
  string(FIND "${entry}" "=" eq)
  string(SUBSTRING "${entry}" 0 ${eq} c)
  math(EXPR rs "${eq} + 1")
  string(SUBSTRING "${entry}" ${rs} -1 re)
  add_test(NAME calls.${c} COMMAND calls_finalize_tests ${c})
  set_tests_properties(calls.${c} PROPERTIES PASS_REGULAR_EXPRESSION "${re}")
endforeach()

# Review-fix probes through the real cq-lower plugin (cq-5xde, cq-09xh, cq-h8vd, ...): run_probes.py's CASES.
add_test(NAME calls.probes
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
