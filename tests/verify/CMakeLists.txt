# Acceptance of cq-w0-verify: every pinned reference .lowered.ll is accepted by cq-verify (both modes),
# and every module in mutants/ gets its expected verdict, one rejected mutant per named check at least.
add_test(NAME verify
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_verify.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
