# tests/driver (cq-w1-driver): the cqcc driver end to end with the real plugin.
add_test(NAME driver
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_driver.py
          --plugin $<TARGET_FILE:CQLower> --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
