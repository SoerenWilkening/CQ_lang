# cq-w0-rt-mem: QROM/QRAM evaluator family against native clang-19 -O1 code and the CR §2 table.
add_test(NAME rt-mem
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_rt_mem.py
          --clang ${CQ_CLANG} --out ${CMAKE_CURRENT_BINARY_DIR}/rt-mem --seeds 5)
