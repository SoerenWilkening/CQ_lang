# tests/bus-alloc: rules 16 Allocation, 20 Allocation, 22 and §0 K2 through the real cq-lower plugin.
add_test(NAME bus-alloc
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_bus_alloc.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(bus-alloc PROPERTIES TIMEOUT 1500)
