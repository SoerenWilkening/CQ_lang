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
# cq-quhmu: a loop of a K-loop's exit arm whose tail the K-loop's trips also enter (musl printf_core's inval).
add_test(NAME loops-cutoff-arm-tail
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/arm_tail.O1.ll
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
# cq-v8cn7, cq-1ye9c (CR rules 2, 8, 14): a measurement behind a classical branch, in a K-loop's trips and without a loop;
# run_probes.py MUTANTS: a trip copy measuring another register, measurements hoisted above the classical br, rejected.
add_test(NAME loops-cutoff-measure-cbr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in h=4 --measures-in g=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_cbr.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# rulings Q8, Q9: a body cq_measure of a carried value whose next value is unrelated (trip j measures the carried rail of
# trip j); run_probes.py MUTANTS: a copy measuring another register through a select of its own making is rejected.
add_test(NAME loops-cutoff-measure-carried
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in measure_carried=4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_carried.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# rulings Q3 part 2 (cq-nmzv3, cq-qotkl, review R1 and R2): a classical conjunct decides a skip classically; a quantum
# branch's arms measured in sequence; a site behind a classical branch inside a skipped quantum arm. run_probes.py MUTANTS:
# the classical guards dropped are rejected.
foreach(p q3_conjunct q3_arms q3_phantom)
  add_test(NAME loops-cutoff-${p}
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
            --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
            ${CMAKE_CURRENT_SOURCE_DIR}/probes/${p}.O1.ll
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
endforeach()
# rulings Q3 (2026-11-11): a measurement behind a classical branch on an earlier outcome; run_probes.py MUTANTS: the
# measurement hoisted above that branch is rejected.
add_test(NAME loops-cutoff-measure-outcome
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in meas_behind_outcome=2
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_outcome.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-jws5r (CR rule 8 with rule 14): a purely classical branch inside a K-trip stays a `br` in every trip copy (the arm
# C does not take emits nothing; the taken arm's effects sit under the trip predicate alone), in a clone, a _ctl clone
# and a twin; a sub-loop, a noreturn arm and a measurement behind one. Each entry §6-checked against its C program.
add_test(NAME loops-cutoff-trip-cbr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          --br-in __cq_q_pa_loop_100=4 --calls-in __cq_q_pa_loop_100=cqrt_alloc_i1=4
          --br-in __cq_q_pa_loop2_100=4 --br-in pb_call=8 --calls-in pb_call=__cq_q_pb_note_11_b2147483647_ctl=4
          --br-in __cq_q_pc_inner_1000_ctl=4 --br-in pd_trip=4 --br-in __cq_q_pe_f_100=8 --br-in __cq_q_pe_f_100_unc=8
          --br-in pf_nested=8 --br-in pg_abort=8 --br-in ph_measure=8
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_cbr.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-tntm (CR rule 14: a_K is kept only when B > K or no bound is known): B = 0 (a header-tested loop whose header runs
# at most once) is a known bound: the clone makes no trip and one header test, and keeps no a_K. §6-checked.
add_test(NAME loops-cutoff-b-zero
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --entry pf_b0
          --calls-in __cq_q_cnt_11_b1=cq_template_mul_i32_hl=0 --calls-in __cq_q_cnt_11_b1=cq_template_icmp_ugt_i32_hl=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/b_bound_zero.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-kbygn (CR rule 8 with rule 14): a mixed branch condition `C && Q` inside a K-trip is factored on its Boolean function,
# its classical factor a `br` in every trip copy (no seed), also where -O1 joined it with a sub-loop's guard. Each entry
# §6-checked against its C program.
add_test(NAME loops-cutoff-trip-factor
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          --br-in pa_mixed=4 --br-in pb_nested=8
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_factor.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-kbygn exit-test part (owner ruling Q10; CR rule 14): the classical conjunct of a K-loop's exit test is a `br` at each
# of the K tests (the chain ends where it is false, no later trip), for `while (c && q)`, `do ... while (c && q)` and a c
# that changes in the loop. Each entry §6-checked against its C program; the mutant without test 0's br is rejected.
add_test(NAME loops-cutoff-exit-conjunct
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          --br-in ec_while=8 --br-in ec_do=8 --br-in ec_vary=8
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/exit_conjunct.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-9kcq with owner rulings Q2 and Q3 of 2026-11-14 (CR 1.4 "Received K", rule 27 "Cutoff", rule 6): @__cq_k carries the
# received K to the helpers a table clone calls by name (one level, nested, a helper also called from an ordinary entry,
# the _ctl, forward and twin forms, restored at every return of a table clone); rule 6's per-trip clean in a loop the
# received K cuts (a helper's carried sum, a carried value adding a measured outcome). Each entry §6-checked against
# table_kh_c.O1.ll; the mutants that ignore @__cq_k in a helper or drop its restore are rejected.
add_test(NAME loops-cutoff-table-kh
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900 --c-side table_kh=table_kh_c.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/table_kh.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-wkzu9 (CR rule 19 "Address rail", rule 14, rule 27 "Cutoff"): table functions of one type calling by-name helpers that
# hold a K-loop (one with Q10's classical conjunct), dispatched over a rail pointer: the helpers of the candidates not
# selected run unguarded and keep their a_K, merged by a phi across the cut's and the test's joins; their twins keep none.
add_test(NAME loops-cutoff-ctl-helper
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/ctl_helper.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# Review R1 m1 (CR rule 6 "In a rolled loop", owner ruling Q4, with Q10's tests): rule 6's per-trip clean of a carried
# value across the classical exit tests, cleaned under each test's "went on" flag. Each entry §6-checked.
add_test(NAME loops-cutoff-conjunct-r6
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/conjunct_r6.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# Review R1 n1 (owner ruling Q10, CR rule 14, rule 8): a K-loop nested in a classically bounded loop branches on its
# pre-header guard's classical conjunct before trip 0, and keeps a_K per outer trip through the tests' joins. §6-checked.
add_test(NAME loops-cutoff-conjunct-nest
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/conjunct_nest.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-7jd1z (CR rules 8, 9, 13 with rule 14): a quantum switch's case atom carried to a classical join is a phi in the
# scrutinee's own type (musl wcsrtombs: the exit hub of a K-loop behind a classical bound test); switches in a K-trip on
# a narrowed and a widened scrutinee, a default arm, two cases sharing a successor. Each entry §6-checked.
add_test(NAME loops-cutoff-trip-switch
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_switch.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-9kcq (CR rule 27 "Cutoff", §1.4, rule 19): a K-loop in a table clone runs on the K the clone receives: each callee
# (body form, two exits, nested, do-while, continue, return, a bus-load exit) is called through a pointer from an entry at
# K 2 while its own K is 4. Each entry §6-checked against table_k_c.O1.ll (the callees at the received K, the C oracle's
# per-function resolution); the mutant that compares with the own K is rejected.
add_test(NAME loops-cutoff-table-k
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900 --c-side table_k=table_k_c.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/table_k.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
