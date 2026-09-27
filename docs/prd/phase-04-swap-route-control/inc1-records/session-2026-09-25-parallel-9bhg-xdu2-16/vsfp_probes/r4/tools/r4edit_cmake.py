p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/tests/e2e/CMakeLists.txt'
s = open(p).read()
anchor = '''add_test(NAME e2e-volatile-arm-fold-repropagate-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_repropagate_twin.expected.log")
'''
assert s.count(anchor) == 1
add = '''
# bd vsfp ROUND 4 (Rule-13 r3B F-XB-1 — bd 1xp9, probe `u5`). Two cascaded diamonds on
# CLASSICAL conditions whose arms the fenv store erasure empties; the second condition is an
# `i1` phi the first fold's block merge erases. Rounds 2-3 read it freed: SIGSEGV (exit 139) on
# a program the ORACLE compiles. RED (a crash) on rounds 2 and 3, GREEN here, pinned to the
# fenv-intended twin.
add_test(NAME e2e-slice-volatile-arm-fold-cascade
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade.expected.log")
add_test(NAME e2e-slice-volatile-arm-fold-cascade-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade_twin.expected.log")
add_test(NAME e2e-volatile-arm-fold-cascade-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_volatile_arm_fold_cascade_twin.expected.log")
'''
s = s.replace(anchor, anchor + add)
open(p, 'w').write(s)
print('ok')
