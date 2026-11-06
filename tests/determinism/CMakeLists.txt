# tests/determinism (cq-fm68i): two lowerings of one input are byte-identical, address randomization on.
add_test(NAME determinism
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_determinism.py
          --opt ${CQ_OPT} --plugin $<TARGET_FILE:CQLower> --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(determinism PROPERTIES TIMEOUT 600)
