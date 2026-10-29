# tests/loops-cutoff (cq-w1-loops-cutoff): loops::resolveK precedence and loops::tripBound.
add_executable(loops_cutoff_k k_and_bound.cpp $<TARGET_OBJECTS:cq_pass_objs>)
target_include_directories(loops_cutoff_k PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(loops_cutoff_k PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(loops_cutoff_k PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(loops_cutoff_k cq_pass_objs)
target_link_libraries(loops_cutoff_k PRIVATE LLVM)
add_test(NAME loops_cutoff_k COMMAND loops_cutoff_k)
