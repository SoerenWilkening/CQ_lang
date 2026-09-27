p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/tests/e2e/CMakeLists.txt'
s = open(p).read()
anchor = '''add_test(NAME e2e-volatile-arm-fold-cascade-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade_twin.expected.log")
'''
assert s.count(anchor) == 1
add = '''
# bd vsfp ROUND 5 (Rule-13 r4A F-YA-1 — bd 91k9, probe `bv`). A clone's recorded-dead `byval`
# struct slot was neutralised to `null` on rounds 3-4: opt, the verifier and stage 2b were clean
# and the linked executable SIGSEGVed. Only a slice RUNS the program. RED (crash) on rounds 3 and
# 4, GREEN here; the golden is byte-identical to the ORACLE's trace (measured).
add_test(NAME e2e-slice-spec-dropped-arg-byval-slot
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_byval_slot.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_dropped_arg_byval_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_byval_slot.expected.log")
'''
s = s.replace(anchor, anchor + add)
open(p, 'w').write(s)
print('ok')
