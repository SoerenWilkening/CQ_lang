# tests/bus-alloc: rules 16 Allocation, 20 Allocation, 22 and §0 K2 through the real cq-lower plugin.
add_test(NAME bus-alloc
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_bus_alloc.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
set_tests_properties(bus-alloc PROPERTIES TIMEOUT 1500)

# cq-wbboy, cq-23ovm: __cq_unbound after a phi of a block not yet ended carries no !dbg (the input has none); a crash or a
# verifier failure fails the test by its exit code.
add_test(NAME bus-alloc.unbound_phi
  COMMAND ${CQ_OPT} -load-pass-plugin=$<TARGET_FILE:CQLower> -passes=cq-lower
          -cq-roots=${CMAKE_CURRENT_SOURCE_DIR}/probes/unbound_phi.roots -S -o -
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/unbound_phi.ll)
set_tests_properties(bus-alloc.unbound_phi PROPERTIES FAIL_REGULAR_EXPRESSION "!dbg")
