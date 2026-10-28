# tests/rot-cry (cq-w1-rot-cry): rule 10 probes through the real cq-lower plugin.
add_test(NAME rot-cry
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_rot_cry.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
