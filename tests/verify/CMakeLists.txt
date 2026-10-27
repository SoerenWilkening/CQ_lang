# Acceptance of cq-w0-verify and cq-7p6: every pinned reference .lowered.ll is accepted by
# cq-verify<reference>; plain cq-verify requires the !cq.measure marker (cq-arch V1); every module in
# mutants/ gets its expected verdict in both modes, one rejected mutant per named check at least.
add_test(NAME verify
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_verify.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
