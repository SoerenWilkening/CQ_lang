# cq-w0-tmpl-cmp: differential test of checker/rt/tmpl_cmp.c against native x86-64 code, with its
# mutant self-test (tests/tmpl-cmp/difftest.py).
add_test(NAME tmpl-cmp
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/difftest.py
          --clang ${CQ_CLANG} --work ${CMAKE_CURRENT_BINARY_DIR}/work)
set_tests_properties(tmpl-cmp PROPERTIES TIMEOUT 900)
