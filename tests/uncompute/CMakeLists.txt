# Unit tests of the uncompute spine (cq-w0-uncompute): synthetic record sets driven through
# Uncompute.h, the emitted IR compared line by line. With no argument the binary runs every positive
# case; each case is also its own test, and each fatal case must fail with its named internal error.
cq_add_unit_test(uncompute_tests uncompute_tests.cpp)

set(CQ_UNC_CASES
  reverse_dependency_order independent_most_recent_first last_use_ir last_use_noted
  nondiagonal_before nondiagonal_kept nondiagonal_transitive rule10_flag_kept
  measure_is_not_a_barrier rule6_sequence scope_mirror_order scope_nested seed_direct
  seed_xorc_direct seed_written_undone qram_lifo multi_exit arm_flush ex14_fmuladd
  ex42_measure_one_of_two ex162_consumer ex144_rule6)
foreach(c ${CQ_UNC_CASES})
  add_test(NAME uncompute.${c} COMMAND uncompute_tests ${c})
endforeach()

# Fatal cases: the scheduler refuses, with report_fatal_error, instead of emitting a wrong circuit.
set(CQ_UNC_FATAL
  "fatal_use_after_free=cq: internal error: uncompute: use of"
  "fatal_operand_mismatch=cq: internal error: uncompute: recordTemplate: operand 1 differs"
  "fatal_unflushed_arm=cq: internal error: uncompute: .* is still pending at a return"
  "fatal_scope_order=cq: internal error: uncompute: scopes close last-in-first-out"
  "fatal_mirror_outside_reader=cq: internal error: uncompute: mirror would free"
  "fatal_write_barrier=cq: unimplemented: uncompute: an in-place write on an operand rail"
  "fatal_unknown_handle=cq: internal error: uncompute: recordTemplate: .* is not a recorded rail")
foreach(entry ${CQ_UNC_FATAL})
  string(FIND "${entry}" "=" eq)
  string(SUBSTRING "${entry}" 0 ${eq} c)
  math(EXPR rs "${eq} + 1")
  string(SUBSTRING "${entry}" ${rs} -1 re)
  add_test(NAME uncompute.${c} COMMAND uncompute_tests ${c})
  set_tests_properties(uncompute.${c} PROPERTIES PASS_REGULAR_EXPRESSION "${re}")
endforeach()
