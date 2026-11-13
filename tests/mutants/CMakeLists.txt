# Static tests of module chk-selftest (bead cq-w0-chk-selftest): the mutants apply, parse and cover
# every class; the judging rules. The evaluation itself is `python3 -m cqcheck selftest`.
add_test(NAME mutants
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_mutants.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-p9pty: a restricted self-test (one mutant, its control, one empty output) prints its final line and exits
# promptly after its last check; each outcome line carries its timing.
add_test(NAME selftest_exit
  COMMAND ${CMAKE_COMMAND} -E env CQ_PLUGIN=$<TARGET_FILE:CQLower> ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_selftest_exit.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(selftest_exit PROPERTIES TIMEOUT 300)
