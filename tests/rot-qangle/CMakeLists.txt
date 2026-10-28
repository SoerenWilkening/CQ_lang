# tests/rot-qangle (cq-w1-rot-qangle): rules 11 and 15 probes and the owned examples through the real cq-lower plugin.
add_test(NAME rot-qangle
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_rot_qangle.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
