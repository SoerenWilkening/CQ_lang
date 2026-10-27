# The checker's cross-module Python API frozen by cq-zew (Z1 in cq-arch): every frozen name, once its
# owner defines it, is defined once with the frozen signature; report.SIBLING_API agrees; Z1 agrees.
# The wave-0 coordinator's gate adds --require-all.
add_test(NAME checker-api
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_api.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
