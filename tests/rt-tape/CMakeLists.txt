# cq-w0-rt-tape: differential test of the tape family against native printf (clang-19 -O1) and the
# tape/abort semantic and violation scenarios. Built against a test double of cqe.h (fake_core.c).
add_test(NAME rt-tape
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_tests.py --clang ${CQ_CLANG}
          --work ${CMAKE_CURRENT_BINARY_DIR}/work)
# cq-d4n0n: fx_standin.h's effect table against pass/lib/Common.cpp streamName and musl's _unlocked aliases
add_test(NAME rt-tape-fx-table COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_fx_table.py)
