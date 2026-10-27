# tests/chk-core (cq-w0-chk-core): evaluator core, trace contract, violations, stubgen over the corpus.
add_test(NAME chk-core
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_chk_core.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(chk-core PROPERTIES ENVIRONMENT "CQ_SPEC_DIR=${CQ_SPEC_DIR}")
