# tests/usercheck (cq-w1-usercheck): cqcheck user on small programs, corpus references and mutants.
add_test(NAME usercheck
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_usercheck.py --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(usercheck PROPERTIES ENVIRONMENT "CQ_PLUGIN=$<TARGET_FILE:CQLower>")
