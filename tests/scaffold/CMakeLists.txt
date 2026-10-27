# Scaffold acceptance (cq-w0-scaffold): headers equal cq-arch, every example .O1.ll is an internal
# error with no output, a module with no CQ.h call passes through byte-identical.
add_test(NAME scaffold
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_scaffold.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --clang ${CQ_CLANG} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
