# cq-w0-rt-tape: differential test of the tape family against native printf (clang-19 -O1) and the
# tape/abort semantic and violation scenarios. Built against a test double of cqe.h (fake_core.c).
add_test(NAME rt-tape
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_tests.py --clang ${CQ_CLANG}
          --work ${CMAKE_CURRENT_BINARY_DIR}/work)
