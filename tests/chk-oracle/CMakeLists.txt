# C oracle (cq-w0-chk-oracle): unit tests of the instrumentation and runtime on small C programs.
# The corpus run (tests/chk-oracle/corpus.py) is a whole-suite run and is not registered here.
cq_add_python_unit_classes(chk-oracle ${CMAKE_CURRENT_SOURCE_DIR}/test_oracle.py
  ${CMAKE_CURRENT_SOURCE_DIR} "CQ_BUILD_DIR=${CMAKE_BINARY_DIR};CQ_SPEC_DIR=${CQ_SPEC_DIR}")
