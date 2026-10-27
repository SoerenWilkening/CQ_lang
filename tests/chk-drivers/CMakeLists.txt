# cq-w0-chk-drivers: unit tests of drivers.py / sampling.py, and the corpus acceptance (every
# example has a DriverSpec and a SampleSet with every class present or empty with a reason).
add_test(NAME chk-drivers-unit
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_drivers.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/checker)
set_tests_properties(chk-drivers-unit PROPERTIES ENVIRONMENT "CQ_SPEC_DIR=${CQ_SPEC_DIR}")
add_test(NAME chk-drivers-corpus
  COMMAND ${Python3_EXECUTABLE} -m cqcheck.sampling
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/checker)
set_tests_properties(chk-drivers-corpus PROPERTIES ENVIRONMENT "CQ_SPEC_DIR=${CQ_SPEC_DIR}" TIMEOUT 7200)
