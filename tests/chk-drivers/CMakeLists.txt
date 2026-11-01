# cq-w0-chk-drivers: unit tests of drivers.py / sampling.py, and the corpus acceptance (every
# example has a DriverSpec and a SampleSet with every class present or empty with a reason).
cq_add_python_unit_classes(chk-drivers-unit ${CMAKE_CURRENT_SOURCE_DIR}/test_drivers.py
  ${CMAKE_SOURCE_DIR}/checker "CQ_SPEC_DIR=${CQ_SPEC_DIR}")
# The corpus acceptance in chunks of 25 examples, each its own entry under heavy.sh's cap (cq-fbii:
# as one run it exceeded both the time and the 2 GB cap).
file(GLOB cq_examples LIST_DIRECTORIES true RELATIVE "${CQ_SPEC_DIR}/examples" "${CQ_SPEC_DIR}/examples/[0-9]*")
list(SORT cq_examples COMPARE NATURAL)
list(LENGTH cq_examples cq_n)
set(cq_i 0)
while(cq_i LESS cq_n)
  list(SUBLIST cq_examples ${cq_i} 25 cq_chunk)
  list(GET cq_chunk 0 cq_first)
  string(REGEX REPLACE "_.*" "" cq_first "${cq_first}")
  add_test(NAME chk-drivers-corpus-${cq_first}
    COMMAND ${Python3_EXECUTABLE} -m cqcheck.sampling ${cq_chunk}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/checker)
  set_tests_properties(chk-drivers-corpus-${cq_first} PROPERTIES ENVIRONMENT "CQ_SPEC_DIR=${CQ_SPEC_DIR}" TIMEOUT 600)
  math(EXPR cq_i "${cq_i} + 25")
endwhile()
