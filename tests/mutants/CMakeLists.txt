# Static tests of module chk-selftest (bead cq-w0-chk-selftest): the mutants apply, parse and cover
# every class; the judging rules. The evaluation itself is `python3 -m cqcheck selftest`.
add_test(NAME mutants
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_mutants.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
