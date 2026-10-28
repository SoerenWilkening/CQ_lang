# tests/spine (cq-w0-construct): owned examples and probes through the real cq-lower plugin.
add_test(NAME spine
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_spine.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

# Rule 18 copy-out at a clone's return (cq-b0w). Linked with every pass module except
# calls/Calls.cpp, whose functions the test supplies (materialize is a test double: cq-w1-calls owns
# the real one); include directories and definitions are cq_pass_objs' usage requirements.
add_executable(spine_clone_return clone_return.cpp
  $<FILTER:$<TARGET_OBJECTS:cq_pass_objs>,EXCLUDE,/calls/Calls\.cpp\.o$>)
target_include_directories(spine_clone_return PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(spine_clone_return PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(spine_clone_return PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(spine_clone_return cq_pass_objs)
target_link_libraries(spine_clone_return PRIVATE LLVM)
add_test(NAME spine_clone_return COMMAND spine_clone_return)
