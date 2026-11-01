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

# A loop dispatched as a unit whose exit block is also a zero-trip guard's skip target (cq-gio4).
# Linked with every pass module except loops/classical/Classical.cpp, whose lowerClassical the test
# supplies (a test double: cq-w1-loops-classical owns the real one).
add_executable(spine_loop_exit_join loop_exit_join.cpp
  $<FILTER:$<TARGET_OBJECTS:cq_pass_objs>,EXCLUDE,/loops/classical/Classical\.cpp\.o$>)
target_include_directories(spine_loop_exit_join PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(spine_loop_exit_join PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(spine_loop_exit_join PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(spine_loop_exit_join cq_pass_objs)
target_link_libraries(spine_loop_exit_join PRIVATE LLVM)
add_test(NAME spine_loop_exit_join COMMAND spine_loop_exit_join)

# The loop-module entry points lowerInstruction and LoweringContext::rebind (cq-ofn6). Linked like
# spine_loop_exit_join, with a one-trip lowerClassical test double.
add_executable(spine_loop_body loop_body.cpp
  $<FILTER:$<TARGET_OBJECTS:cq_pass_objs>,EXCLUDE,/loops/classical/Classical\.cpp\.o$>)
target_include_directories(spine_loop_body PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(spine_loop_body PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(spine_loop_body PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(spine_loop_body cq_pass_objs)
target_link_libraries(spine_loop_body PRIVATE LLVM)
add_test(NAME spine_loop_body COMMAND spine_loop_body)

# LoweringContext::K(const Function &) (cq-x2lh): flag, CQ_K, global, default 4 on a declaration and
# a definition. Linked with every pass module.
add_executable(spine_k_function k_function.cpp $<TARGET_OBJECTS:cq_pass_objs>)
target_include_directories(spine_k_function PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(spine_k_function PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(spine_k_function PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(spine_k_function cq_pass_objs)
target_link_libraries(spine_k_function PRIVATE LLVM)
add_test(NAME spine_k_function COMMAND spine_k_function)

# cq-my17 (99): a known library call (Darwin asm label "\01_fwrite") handed a pointer to a slot object
# is HostEffect (rule 16). Linked with every pass module.
add_executable(spine_classify_hosteffect classify_hosteffect.cpp $<TARGET_OBJECTS:cq_pass_objs>)
target_include_directories(spine_classify_hosteffect PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(spine_classify_hosteffect PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(spine_classify_hosteffect PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(spine_classify_hosteffect cq_pass_objs)
target_link_libraries(spine_classify_hosteffect PRIVATE LLVM)
add_test(NAME spine_classify_hosteffect COMMAND spine_classify_hosteffect)
