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
# cq-r7-91: CR rules 14, 20, 21 trip objects (a malloc in a K-loop read after it through the last trip's pointer).
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
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/latches_ir.O1.ll 
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/exits.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/entries_ir.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/noexit.O1.ll 
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/b_bound_pos.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/arm_loop.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/bus_kloop.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_arms.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_guard.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/both_dead_merge.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/packed_measure.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/lane_switch.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/guard_cover_ir.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/join_units.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-z6nkx: musl mbsrtowcs' two scan loops into one tail. Lowers; the §6 check FAILS until the bead closes.
add_test(NAME loops-cutoff-tail-phis
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_phis.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
