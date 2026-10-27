# C oracle (cq-w0-chk-oracle): unit tests of the instrumentation and runtime on small C programs.
# The corpus run (tests/chk-oracle/corpus.py) is a whole-suite run and is not registered here.
add_test(NAME chk-oracle
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_oracle.py
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_tests_properties(chk-oracle PROPERTIES ENVIRONMENT "CQ_BUILD_DIR=${CMAKE_BINARY_DIR};CQ_SPEC_DIR=${CQ_SPEC_DIR}")
