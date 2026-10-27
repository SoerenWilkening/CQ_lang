# Unit tests of calls::finalize (cq-by8): constructed modules run through finalize, the surviving
# module compared. With no argument the binary runs every positive case; each case is also its own
# test, and each fatal case must fail with its named error.
cq_add_unit_test(calls_finalize_tests finalize_tests.cpp)

set(CQ_CALLS_CASES
  noop_no_clone noop_clone_namespace_absent drop_retargeted keep_classical_caller keep_address_taken
  keep_used_global drop_mutual_recursion drop_chain keep_live_chain drop_external_original
  drop_dead_references keep_shared_references declared_clone_only twin_only)
foreach(c ${CQ_CALLS_CASES})
  add_test(NAME calls.${c} COMMAND calls_finalize_tests ${c})
endforeach()

set(CQ_CALLS_FATAL
  "fatal_uniquified=cq: unimplemented: calls: calls::finalize: a symbol in the clone namespace that is not a canonical clone name"
  "fatal_ambiguous=cq: unimplemented: calls: calls::finalize: a clone name that reads as a clone of more than one in-module function"
  "fatal_inplace_entry=cq: unimplemented: calls: calls::finalize: an original with no classical caller whose body was rewritten in place"
  "fatal_other_stubs=cq: unimplemented: calls: calls::materialize")
foreach(entry ${CQ_CALLS_FATAL})
  string(FIND "${entry}" "=" eq)
  string(SUBSTRING "${entry}" 0 ${eq} c)
  math(EXPR rs "${eq} + 1")
  string(SUBSTRING "${entry}" ${rs} -1 re)
  add_test(NAME calls.${c} COMMAND calls_finalize_tests ${c})
  set_tests_properties(calls.${c} PROPERTIES PASS_REGULAR_EXPRESSION "${re}")
endforeach()
