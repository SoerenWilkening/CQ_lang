# tests/spine (cq-w0-construct).
#
# libCQLowerSpineTest.so: the cq-lower plugin with the TAINT and PRED modules replaced by the test
# doubles in doubles/ (straight-line only), so the spine can be run end to end while those modules
# are stubs. It is a test artefact: libCQLower.so never links a double.
file(GLOB_RECURSE CQ_SPINE_TEST_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/pass/lib/*.cpp")
list(FILTER CQ_SPINE_TEST_SOURCES EXCLUDE REGEX "/pass/lib/(taint|pred|calls)/")
add_library(CQLowerSpineTest MODULE ${CQ_SPINE_TEST_SOURCES}
            ${CMAKE_CURRENT_SOURCE_DIR}/doubles/TaintDouble.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/doubles/PredDouble.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/doubles/CallsDouble.cpp)
target_include_directories(CQLowerSpineTest PRIVATE "${CMAKE_SOURCE_DIR}/pass/include")
target_include_directories(CQLowerSpineTest SYSTEM PRIVATE ${LLVM_INCLUDE_DIRS})
separate_arguments(CQ_SPINE_LLVM_DEFS NATIVE_COMMAND "${LLVM_DEFINITIONS}")
target_compile_definitions(CQLowerSpineTest PRIVATE ${CQ_SPINE_LLVM_DEFS})
target_compile_options(CQLowerSpineTest PRIVATE -Wall -Wextra -Wno-unused-parameter -fvisibility-inlines-hidden)
if(NOT LLVM_ENABLE_RTTI)
  target_compile_options(CQLowerSpineTest PRIVATE -fno-rtti)
endif()
set_target_properties(CQLowerSpineTest PROPERTIES PREFIX "lib" SUFFIX ".so"
                      LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests/spine")
if(APPLE)
  target_link_options(CQLowerSpineTest PRIVATE -undefined dynamic_lookup)
endif()

add_test(NAME spine-doubles
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_doubles.py
          --test-plugin $<TARGET_FILE:CQLowerSpineTest> --plugin $<TARGET_FILE:CQLower>
          --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
