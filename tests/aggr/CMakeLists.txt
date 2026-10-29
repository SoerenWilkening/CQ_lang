# tests/aggr (cq-w1-aggr): rules 25 and 26 lane and field constructions through the real cq-lower plugin.
add_test(NAME aggr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_aggr.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
