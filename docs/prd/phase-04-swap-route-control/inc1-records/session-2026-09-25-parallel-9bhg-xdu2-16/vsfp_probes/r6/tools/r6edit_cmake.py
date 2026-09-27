p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/tests/e2e/CMakeLists.txt'
s = open(p).read()
anchor = '''    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_byval_slot.expected.log")
'''
assert s.count(anchor) == 1
add = '''
# bd vsfp ROUND 6 (Rule-13 r5 F-Z-1 — bd w7nm, probe `mt1`). r2B's `k19` main with the callee
# forwarding its dead argument through `musttail`. Round 5's liveness rule asked the drop's
# `musttail` POLICY, the outer phantom slot was never neutralised and `p = 3q` stayed DIRTY across
# the Ry — bd tzfa's wrong unitary, exit 0. RED on round 5 and the ORACLE (their stream lacks the
# `mul_i32_hl_unc` + free), GREEN here; pinned to the hand-inlined twin.
add_test(NAME e2e-slice-spec-dropped-arg-musttail-inner
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_musttail_inner.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_dropped_arg_musttail_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_musttail_inner.expected.log")
add_test(NAME e2e-slice-spec-dropped-arg-musttail-inner-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_musttail_inner_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_musttail_inner_twin.expected.log")
add_test(NAME e2e-spec-dropped-arg-musttail-inner-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_musttail_inner.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_musttail_inner_twin.expected.log")
'''
s = s.replace(anchor, anchor + add)
open(p, 'w').write(s)
print('ok')
