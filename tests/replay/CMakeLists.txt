# Exact clone replay in the evaluator (cq-kcn5i): replay on and off agree byte for byte, mutants inside a replayed clone
# are still rejected, a tampered record trips the spot check, a clone that writes its argument never records.
add_test(NAME replay
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_replay.py --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(replay PROPERTIES TIMEOUT 1200)
