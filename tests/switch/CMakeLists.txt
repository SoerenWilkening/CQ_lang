# Module switch (cq-w1-switch) unit tests. The example IR is read from the pinned CQ_spec (read-only).
cq_add_unit_test(switch_unit SwitchTest.cpp)
target_include_directories(switch_unit PRIVATE "${CMAKE_SOURCE_DIR}/pass/lib/pred")
target_compile_definitions(switch_unit PRIVATE CQ_SPEC_DIR="${CQ_SPEC_DIR}")
