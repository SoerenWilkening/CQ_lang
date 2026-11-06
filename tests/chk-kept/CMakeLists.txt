# Kept rails CR names against the leak rule (CR §6 item 1, cq-71g9): each green, and each's leak of the same shape rejected.
add_test(NAME chk-kept
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_kept.py --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
