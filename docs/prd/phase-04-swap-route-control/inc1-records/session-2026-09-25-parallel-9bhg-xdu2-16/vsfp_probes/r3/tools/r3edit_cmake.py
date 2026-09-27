p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/tests/e2e/CMakeLists.txt'
s = open(p).read()
anchor = '''add_test(NAME e2e-spec-dropped-arg-dead-smax-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_dead_smax.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_boolsel_twin.expected.log")
'''
assert s.count(anchor) == 1
add = '''
# bd vsfp ROUND 3 (Rule-13 r2B F-WB-1/F-WB-2 — bd tzfa / bd stl3, probe `k19`). A callee
# whose only read of the dead parameter is the condition of an arm reading a never-stored
# internal `volatile` global. Round 2 left the emptied diamond (the global fold had no arm
# fold), the backstop accepted the phantom read because the operand `p = q * 3` had
# another reader, and the phantom clone call kept the spine from uncomputing `p`'s rail:
# `q` fully dephased across its phase oracle (a Rule-8 wrong unitary; the ORACLE emits the
# same stream). The 2-TU entry is RED on round 2 and on the oracle (12 trace lines, no
# `mul_i32_hl_unc`), DECLINES on round 1, and is GREEN here; the gate pins its golden to
# the hand-inlined twin's (it compares two files and cannot be red on any binary).
add_test(NAME e2e-slice-spec-dropped-arg-volatile-global
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_volatile_global.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_dropped_arg_volatile_global_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_volatile_global.expected.log")
add_test(NAME e2e-slice-spec-dropped-arg-volatile-global-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_volatile_global_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_volatile_global_twin.expected.log")
add_test(NAME e2e-spec-dropped-arg-volatile-global-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_volatile_global.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_dropped_arg_volatile_global_twin.expected.log")

# bd vsfp ROUND 3 (Rule-13 r2A F-WA-1 — bd otam, probe `stale3c`). The fenv store erasure
# empties a quantum-conditioned arm and its cone deletion folds the two-entry φ into a NEW
# tainted `select`; round 2 never re-propagated, so `f(r)` was treated as classical, `f`
# received the `%out` rail handle as data and the user's `cq_measure` VANISHED (exit 0,
# 0 bytes of stderr, 2b clean). RED on round 2 (12 lines, no clone) and a decline on the
# oracle and round 1; GREEN here, pinned to the fenv-intended twin.
add_test(NAME e2e-slice-volatile-arm-fold-repropagate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate.expected.log")
add_test(NAME e2e-slice-volatile-arm-fold-repropagate-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate_twin.expected.log")
add_test(NAME e2e-volatile-arm-fold-repropagate-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate_twin.expected.log")
'''
s = s.replace(anchor, anchor + add)
open(p, 'w').write(s)
print('ok')
