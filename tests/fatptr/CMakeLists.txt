# tests/fatptr (cq-w1-fatptr): rule 21 pointer compares through the real cq-lower plugin.
add_test(NAME fatptr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_fatptr.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-z6q1: CR rules 14, 20, 21 heap records, a K-loop carrying a quantum pointer, next pointers decoded at run time (189).
add_test(NAME fatptr-heap-list
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_heap_list.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
