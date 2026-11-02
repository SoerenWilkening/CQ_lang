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
  merge_arm_local merge_kept_arm_local merge_kept_unchosen_edge merge_kept_rotated carried_phi_rotated carried_phi_unchosen_arm merge_kept_nested_phi_edge alias_distinct_cell
  alias_copy_distinct_array cell_load_garbage cell_load_kept
  deferred_kept_through_memory
  call_two_results call_all_kept call_slotout_unused call_reads resolve_at pointee_before_store cells_distinct deferred_qram_store
  deferred_join_placement alias_formal_local
  merge_kept_select merge_nondiagonal_garbage merge_unchosen_reader merge_unchosen_used_after
  merge_unchosen_read_later merge_nested_select_edge merge_nested_select_edge_rev carried_phi_some_paths
  write_barrier_sandwich pointee_write_swap qram_kept_bus_sandwich merge_unchosen_loop merge_cycle_arm qram_realloc_kept qram_realloc_merged)
foreach(c ${CQ_UNC_CASES})
  add_test(NAME uncompute.${c} COMMAND uncompute_tests ${c})
endforeach()

# Fatal cases: the scheduler refuses, with report_fatal_error, instead of emitting a wrong circuit.
set(CQ_UNC_FATAL
  "fatal_use_after_free=cq: internal error: uncompute: use of"
  "fatal_call_bus_read_unrecorded=cq: internal error: uncompute: noteCallBusRead before recordCall"
  "fatal_operand_mismatch=cq: internal error: uncompute: recordTemplate: operand 1 differs"
  "fatal_unflushed_arm=cq: internal error: uncompute: .* is still pending at a return"
  "fatal_scope_order=cq: internal error: uncompute: scopes close last-in-first-out"
  "fatal_mirror_outside_reader=cq: internal error: uncompute: mirror would free"
  "fatal_unknown_handle=cq: internal error: uncompute: recordTemplate: .* is not a recorded rail"
  "fatal_cell_load_empty=cq: internal error: uncompute: recordCellLoad: a cell load that may name no rail"
  "fatal_resolve_at_used=cq: internal error: uncompute: resolveAt: %t is still used after the point"
  "fatal_resolve_at_bypass=cq: internal error: uncompute: resolveAt: a path from the definition of %s reaches a return without passing the point"
  "fatal_call_mixed=cq: unimplemented: uncompute: a call whose results are partly kept"
  "fatal_alias_slot_reload=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_slot_direct=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_second_array=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_alias_second_array_rev=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_cells_distinct_unnoted=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_cells_distinct_direct_read=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell"
  "fatal_deferred_no_anchor=cq: internal error: uncompute: recordDeferred without exit rails and without a QRAM bus"
  "fatal_deferred_join_bypass=cq: unimplemented: uncompute: a non-diagonal gate or an in-place write on a rail the deferred rule-14 reverse loop reads"
  "fatal_alias_memcpy=cq: unimplemented: awaiting owner ruling: SPEC_ISSUES a gate through a slot cell .*: a non-diagonal gate on a handle that may name an operand rail of %g through a slot cell")
foreach(entry ${CQ_UNC_FATAL})
  string(FIND "${entry}" "=" eq)
  string(SUBSTRING "${entry}" 0 ${eq} c)
  math(EXPR rs "${eq} + 1")
  string(SUBSTRING "${entry}" ${rs} -1 re)
  add_test(NAME uncompute.${c} COMMAND uncompute_tests ${c})
  set_tests_properties(uncompute.${c} PROPERTIES PASS_REGULAR_EXPRESSION "${re}")
endforeach()

# Probes through the real cq-lower plugin (cq-lshe): run_probes.py's CASES.
add_test(NAME uncompute.probes
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
