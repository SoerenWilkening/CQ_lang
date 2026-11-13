# tests/chk-core (cq-w0-chk-core): evaluator core, trace contract, violations, stubgen over the corpus.
cq_add_python_unit_classes(chk-core ${CMAKE_CURRENT_SOURCE_DIR}/test_chk_core.py
  ${CMAKE_SOURCE_DIR} "CQ_SPEC_DIR=${CQ_SPEC_DIR}")
# cq-p9pty task B: checker cache pruning (temporary cache dirs only)
add_test(NAME chk-cachegc
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_cachegc.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
