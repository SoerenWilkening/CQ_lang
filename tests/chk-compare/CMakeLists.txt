# chk-compare (cq-w0-chk-compare): §6 comparison on synthetic RunResults.
add_test(NAME chk-compare
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_compare.py -v)
