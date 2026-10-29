# tests/loops-classical (cq-w1-loops-classical): rule 14 cases 1 and 3 through the real cq-lower plugin.
add_test(NAME loops-classical
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_loops_classical.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
