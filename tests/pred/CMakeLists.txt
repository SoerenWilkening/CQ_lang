# Module pred (cq-w0-pred) unit tests. The example IR is read from the pinned CQ_spec (read-only).
cq_add_unit_test(pred_unit PredTest.cpp)
target_include_directories(pred_unit PRIVATE "${CMAKE_SOURCE_DIR}/pass/lib/pred")
target_compile_definitions(pred_unit PRIVATE CQ_SPEC_DIR="${CQ_SPEC_DIR}")
