# tests/rt-bus: the evaluator's memory bus (checker/rt/rt_bus.c) and the injection-bundle host file
# (bundle/host/cq_host.c): every op on HOST and QUANTUM cells, and the flat-memory references in the evaluator
# through a hand driver.
cq_add_python_unit_classes(rt-bus ${CMAKE_CURRENT_SOURCE_DIR}/test_rt_bus.py
  ${CMAKE_SOURCE_DIR} "CQ_SPEC_DIR=${CQ_SPEC_DIR}")
