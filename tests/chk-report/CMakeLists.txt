# Unit tests of module chk-report (bead cq-w0-chk-report).
add_test(NAME chk-report
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_report.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(chk-report PROPERTIES ENVIRONMENT "CQ_PLUGIN=$<TARGET_FILE:CQLower>")
