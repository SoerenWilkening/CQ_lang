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
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/bounded_two_exits.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/seq_bounded.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_counter.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/while_mixed.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/hoisted_test.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/arm_test.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_arms.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_guard.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/both_dead_merge.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/packed_measure.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/lane_switch.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/guard_cover_ir.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/join_units.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-z6nkx: musl mbsrtowcs' two scan loops into one tail; strlen's tail edge excluding its unit; stpcpy's skip of a loop in a tail; its head's flag seed.
add_test(NAME loops-cutoff-tail-phis
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_phis.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_excl.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_skip.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_guard2_ir.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/seed_arm_ir.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-t30vh: a K-loop's tail inside another loop's trip on the paths that skip the loop.
add_test(NAME loops-cutoff-tail-trip
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tail_trip.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# Nested loop tails (review of eda902b..096db1c): tail bindings and assumptions composed, one entry each.
add_test(NAME loops-cutoff-tail-nest
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_a1.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_f4.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_f2.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_i1.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_j2.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_j1.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_h3.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_g5.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_h5.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_h1.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_a4.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/tl_k1.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_merge.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-oiclq (owner): one cq_measure is one cqrt_measure: a measurement in a K-loop's exit arm runs once after the trips.
add_test(NAME loops-cutoff-measure-one
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures 1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_one.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-two
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures 2
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_two.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-body
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=4 --measures-in __cq_q_f_1_t_ctl=4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_body.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-reread
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=1 --measures-in __cq_q_f_1_t_ctl=4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_reread.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-rail
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=2 --measures-in __cq_q_f_1_t_ctl=5
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_rail.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-outer
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_outer.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-arm
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_arm.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-47f8h (owner 2026-11-07): measurements are identified by call site: the K copies on trips no sample of the C program
# reaches execute the site C does reach; run_probes.py MUTANTS: an extra site, another shape, a wrong value are rejected.
add_test(NAME loops-cutoff-measure-site
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=4 --measures-in g=4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_site.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
