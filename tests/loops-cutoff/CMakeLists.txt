# tests/loops-cutoff (cq-w1-loops-cutoff): loops::resolveK precedence and loops::tripBound.
add_executable(loops_cutoff_k k_and_bound.cpp $<TARGET_OBJECTS:cq_pass_objs>)
target_include_directories(loops_cutoff_k PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(loops_cutoff_k PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(loops_cutoff_k PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(loops_cutoff_k cq_pass_objs)
target_link_libraries(loops_cutoff_k PRIVATE LLVM)
add_test(NAME loops_cutoff_k COMMAND loops_cutoff_k)
# cq-41v2: CR rule 6 on carried values of a K-cutoff loop, through the real cq-lower plugin.
add_test(NAME loops-cutoff-rule6
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_rule6.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# A-loops (wave 2a round 7): CR rule 14 multi-exit loops, dead-end exits, walked pointers, a clone's _b bound.
add_test(NAME loops-cutoff-multi-exit
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_multi_exit.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-r7-91: CR rules 14, 20, 21 trip objects (a malloc in a K-loop read after it through the last trip's pointer).
add_test(NAME loops-cutoff-trip-objects
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_trip_objects.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-zge7: a clone's _b bound below SCEV's constant maximum (an unsigned i32 trip count) still bounds the cutoff.
add_test(NAME loops-cutoff-b-bound
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_b_bound.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-s7c4: CR rule 14 mixed exits `c || q`: c is a classical bound only when it bounds the trip count.
add_test(NAME loops-cutoff-mixed-exit
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_mixed_exit.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-b58q (owner 2026-11-02, no stops): the widened rule-14 constructions, each probe entry §6-checked against its C program.
add_test(NAME loops-cutoff-widened
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_cfg.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/latches.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/latches_ir.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/recursion.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/exits.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/entries_ir.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/noexit.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/cgoto.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/b_bound_pos.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/arm_loop.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
