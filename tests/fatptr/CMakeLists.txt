# tests/fatptr (cq-w1-fatptr): rule 21 pointer compares through the real cq-lower plugin.
add_test(NAME fatptr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_fatptr.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
