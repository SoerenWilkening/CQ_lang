# Unit tests of the uncompute spine (cq-w0-uncompute): synthetic record sets driven through
# Uncompute.h, the emitted IR compared line by line. With no argument the binary runs every positive
# case; each case is also its own test, and each fatal case must fail with its named internal error.
cq_add_unit_test(uncompute_tests uncompute_tests.cpp)

set(CQ_UNC_CASES
  reverse_dependency_order independent_most_recent_first last_use_ir last_use_noted
  nondiagonal_before nondiagonal_kept nondiagonal_transitive rule10_flag_kept
  measure_is_not_a_barrier rule6_sequence scope_mirror_order scope_nested seed_direct
  seed_xorc_direct seed_written_undone qram_lifo qram_rmw qram_realloc qram_kept_bus qram_pop_kept multi_exit arm_flush ex14_fmuladd
  ex42_measure_one_of_two ex162_consumer ex144_rule6
  merge_measured merge_all_arms_kept merge_template_then_garbage merge_noted_use merge_phi merge_nested
  merge_kept_arm_local merge_kept_unchosen_edge merge_kept_rotated merge_kept_nested_phi_edge alias_distinct_cell
  alias_copy_distinct_array cell_load_garbage cell_load_kept
  deferred_kept_through_memory
  call_two_results call_all_kept call_slotout_unused)
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
  "fatal_qram_kept_bus_barrier=cq: unimplemented: uncompute: an in-place write on an operand rail"
  "fatal_qram_realloc_kept=cq: unimplemented: uncompute: an item on a QRAM bus whose qram_realloc result is kept"
  "fatal_unknown_handle=cq: internal error: uncompute: recordTemplate: .* is not a recorded rail"
  "fatal_merge_kept_role=cq: unimplemented: uncompute: a kept role on a classical select over handles"
  "fatal_cell_load_empty=cq: internal error: uncompute: recordCellLoad: a cell load that may name no rail"
  "fatal_call_mixed=cq: unimplemented: uncompute: a call whose results are partly kept"
  "fatal_merge_nondiagonal=cq: unimplemented: uncompute: a non-diagonal gate on a merged handle"
  "fatal_merge_arm_local=cq: unimplemented: uncompute: an arm of a merged handle, .* cq-ut4k"
  "fatal_merge_unchosen_reader=cq: unimplemented: uncompute: an arm of a kept merged handle, .* is read by a pending rail"
  "fatal_merge_unchosen_used_after=cq: unimplemented: uncompute: an arm of a kept merged handle, .* is still used after"
  "fatal_merge_unchosen_read_later=cq: unimplemented: uncompute: recordTemplate: an arm of a kept merged handle, .* is read after the edge"
  "fatal_merge_nested_select_edge=cq: unimplemented: uncompute: a kept role on a classical select over handles whose arm %t"
  "fatal_merge_nested_select_edge_rev=cq: unimplemented: uncompute: a kept role on a classical select over handles whose arm %t"
  "fatal_alias_slot_reload=cq: unimplemented: uncompute: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_slot_direct=cq: unimplemented: uncompute: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_second_array=cq: unimplemented: uncompute: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_second_array_rev=cq: unimplemented: uncompute: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_memcpy=cq: unimplemented: uncompute: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_merge_unchosen_loop=cq: unimplemented: uncompute: an arm of a kept merged handle, %a, freed at the end of an edge where the merge does not choose it, is reached again")
foreach(entry ${CQ_UNC_FATAL})
  string(FIND "${entry}" "=" eq)
  string(SUBSTRING "${entry}" 0 ${eq} c)
  math(EXPR rs "${eq} + 1")
  string(SUBSTRING "${entry}" ${rs} -1 re)
  add_test(NAME uncompute.${c} COMMAND uncompute_tests ${c})
  set_tests_properties(uncompute.${c} PROPERTIES PASS_REGULAR_EXPRESSION "${re}")
endforeach()
