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
# cq-9kcq: run_probes.py's and run_b_bound.py's execution counts (ktrips.py) on a rolled K-loop, with the counterexamples
# each count rejects (a measurement per trip of a carried rail, a classical br per trip, a cycle with no trip counter).
add_test(NAME loops-cutoff-ktrips
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ktrips.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-b58q (owner 2026-11-02, no stops): the widened rule-14 constructions, each probe entry §6-checked against its C program.
add_test(NAME loops-cutoff-widened
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_cfg.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/latches.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/latches_ir.O1.ll 
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/exits.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/entries_ir.O1.ll
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/noexit.O1.ll ${CMAKE_CURRENT_SOURCE_DIR}/probes/noexit_loop.O1.ll
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
# cq-9kcq S21 (CR rules 14, 26): a vector of a quantum-exit K-loop's header test region read by its body, carried by the
# rolled trip one field per header phi; with a mutant (field 1 carried as field 0).
add_test(NAME loops-cutoff-aggregate
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/agg_region.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-n1hy7 (CR rules 6, 14): a value made in a rolled K-trip and read after the loop by a reader that may consume it by rule
# 6 (a template, a store, a return, a rotation, a measurement of a template), one entry per reader shape; with a mutant
# (the exit value read from the trip before the last).
add_test(NAME loops-cutoff-trip-exit
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_exit.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-shndm (CR rules 5, 9, 14, 20 to 22): multi-exit quantum-exit K-loops whose trips access memory (a load through a quantum
# index, a stored quantum value, *p++ and the walked *ws of musl wcsrtombs, an exit inside a classical branch, the region
# form, a callee clone under a quantum predicate), one entry per shape; with a mutant (the exit hub value's copy left live).
add_test(NAME loops-cutoff-exit-mem
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/exit_mem.O1.ll
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
# --table-k 4 (cq-9kcq): the rolled _ctl table clone's trips run to the K its dispatch passes, 4 where none is received.
# Owner 2026-11-15, cq-amtcn (CR rule 14): the exit test (v & 2 on the carried v after the trip's cq_measure of it) reads
# the outcome and is classical, so f's loop is a classical loop: one cqrt_measure site in it, run once per executed trip
# (counted once); the _ctl clone measures a controlled copy (rule 19, no collapse), so its exit stays quantum (K = 4 trips).
add_test(NAME loops-cutoff-measure-body
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=1 --measures-in __cq_q_f_1_t_ctl=4 --table-k 4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_body.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-reread
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=1 --measures-in __cq_q_f_1_t_ctl=4 --table-k 4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_reread.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-rail
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=2 --measures-in __cq_q_f_1_t_ctl=5 --table-k 4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_rail.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-measure-outer
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_outer.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-amtcn: the same classical loop inside the quantum arm b3: its measurement and branch run unconditionally (rule 2),
# one cqrt_measure site run once per executed trip.
add_test(NAME loops-cutoff-measure-arm
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_arm.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-amtcn (owner 2026-11-15, CR rule 14), the other cases: ex_pre's header test reads the carried rail before the trip's
# measurement and stays quantum (a K-loop, K = 4 trips, its latch test on the outcome a classical br per trip); ex_conj's
# outcome test beside the quantum !b2 is a classical conjunct of the K-loop (K = 4 trips); ex_arm is a classical loop in
# a quantum arm (one site, once per executed trip). Each entry §6-checked against its C program.
add_test(NAME loops-cutoff-measure-exit
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          --measures-in ex_pre=4 --measures-in ex_conj=4 --measures-in ex_arm=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_exit.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-pntr (CR rule 14): `p = x; x = f(x)` read after a K-loop; each exit value is read before any rebind.
add_test(NAME loops-cutoff-prev-value
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in prev_value=3
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/prev_value.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-q7u9y: two measurements in sequence in a K-loop's exit arm, the loop also returning past them, each once after the trips.
add_test(NAME loops-cutoff-measure-seq
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in e=2 --measures-in e0=2
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_seq.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-47f8h (owner 2026-11-07): measurements are identified by call site: the trips no sample of the C program reaches
# execute the site C does reach; run_probes.py MUTANTS: an extra site, another shape, a wrong value are rejected.
add_test(NAME loops-cutoff-measure-site
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in f=4 --measures-in g=4
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_site.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-v8cn7, cq-1ye9c (CR rules 2, 8, 14): a measurement behind a classical branch, in a K-loop's trips and without a loop;
# run_probes.py MUTANTS: a trip measuring another register, measurements hoisted above the classical br, rejected.
add_test(NAME loops-cutoff-measure-cbr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in h=4 --measures-in g=1
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_cbr.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# rulings Q8, Q9: a body cq_measure of a carried value whose next value is unrelated (trip j measures the carried rail of
# trip j); run_probes.py MUTANTS: a trip measuring another register through a select of its own making is rejected.
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
# measurement hoisted above that branch is rejected. Ruling of 2026-11-15 (cq-2n7j4): 3 cqrt_measure calls, as (m & 1)
# is a classical branch (rule 8) and each arm's cq_measure is its own measure at its program point.
add_test(NAME loops-cutoff-measure-outcome
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --measures-in meas_behind_outcome=3
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/me_outcome.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-jws5r (CR rule 8 with rule 14): a purely classical branch inside a K-trip stays a `br` in the trip (the arm
# C does not take emits nothing; the taken arm's effects sit under the trip predicate alone), in a clone, a _ctl clone
# and a twin; a sub-loop, a noreturn arm and a measurement behind one. Each entry §6-checked against its C program.
# pa_loop's cqrt_alloc_i1 runs (no rail for the arm's predicate: the store runs under a_j alone), the rolled trip counted
# K = 4 times (cq-9kcq S14): per trip the chain's a_j (and_i1 into a fresh rail) and the kept store's control, a copy of
# the trip's predicate (alloc_i1 + copy_i1 in the store's arm, counted though behind the classical br on p != NULL), 8;
# and a_K's copy after the loop (alloc_i1 + copy_i1 at the exit block), 9. pa_loop is reached by name from pa_store's
# table clone, so its trip count is the received K at run time (@__cq_k, all ones: its own 4).
add_test(NAME loops-cutoff-trip-cbr
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          --br-in __cq_q_pa_loop_100=4 --calls-in __cq_q_pa_loop_100=cqrt_alloc_i1=9
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
# its classical factor a `br` in the trip (no seed), also where -O1 joined it with a sub-loop's guard. Each entry
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
# --test-br-in: the conjunct's br runs once per test, exactly: K + 1 = 5 tests for the
# loops tested at the top (a_0 to a_K: before trip 0 and after each trip), K = 4 for the do-while (a_0 is the seed).
add_test(NAME loops-cutoff-exit-conjunct
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          --test-br-in ec_while=5 --test-br-in ec_do=4 --test-br-in ec_vary=5
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/exit_conjunct.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-9kcq with owner rulings Q2 and Q3 of 2026-11-14 (CR 1.4 "Received K", rule 27 "Cutoff", rule 6): @__cq_k carries the
# received K to the helpers a table clone calls by name (one level, nested, a helper also called from an ordinary entry,
# the _ctl, forward and twin forms, restored at every return of a table clone); rule 6's per-trip clean in a loop the
# received K cuts (a helper's carried sum, a carried value adding a measured outcome). Each entry §6-checked against its
# C program (the C oracle runs each loop at the K the circuit uses, the received K included, cqo_rt.c k_recv); the
# mutants that ignore @__cq_k in a helper or drop its restore are rejected.
add_test(NAME loops-cutoff-table-kh
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
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
# cq-bxikv (CR rules 8, 14): a register rotated in place behind a classical branch of every trip is carried in place (one
# rail on both paths of the branch), no fresh rail per trip.
add_test(NAME loops-cutoff-trip-register
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/trip_register.O1.ll
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
# K 2 while its own K is 4. cq-fy1k5 (CR §6 "the same cutoff as the circuit"; owner 2026-11-15): the C oracle runs a
# K-loop of a function reached through a pointer, and of what that calls by name, at the K the caller passes (cqo_rt.c
# k_recv), so each entry is §6-checked against table_k.O1.ll itself; the own_k mutant is rejected.
add_test(NAME loops-cutoff-table-k
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/table_k.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-9kcq S6 (CR §1.4 "Received K": the K of that activation in place of its own, smaller or larger; owner 2026-11-15):
# the reproducer tk_f with a received K 6 above the callee's own 4 (tk6_f, tk6_d) and 2 below it (tk2_f), each §6-checked
# against the one C module (the C oracle runs the callee at the K its caller passes); the own_k mutant (a cut too late) and
# recv_k_cut1 (a cut too early: 1 trip at a received K 2) are rejected.
add_test(NAME loops-cutoff-table-k6
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 900
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/table_k6.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# Owner ruling of 2026-11-15, the activation-counter cut (CR §1.4, rule 14, rule 19): a function reached only through a
# pointer recursing through it under a quantum predicate; its _t_ctl table clone's depth counter cuts at d < K with the
# received K 2, and the C oracle makes the same cut (cqo_rt.c __cqo_act_enter). §6-checked; the cut_d3 mutant is rejected.
add_test(NAME loops-cutoff-k-chain
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 600
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/k_chain.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-lv2ba (CR rules 14, 16): a classically bounded sub-loop with an abort arm behind a classical condition of a K-trip,
# its counter read after it: a rail on the run path (the sub-loop's only way on is its quantum exit), a |0> seed on the
# skip path. §6-checked against its C program.
add_test(NAME loops-cutoff-sub-abort-skip
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 600
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/sub_abort_skip.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-9kcq S11, S11e (CR rules 14, 16): a trip-local classically bounded loop in a rolled K-trip (ksub: ks_phase) and nested
# abort/exit arms (nstop: a nested K-loop's noreturn arm, its stop rail carried across the inner trips; an exit arm of a
# do-while nested in a K-trip). §6-checked against their C programs.
add_test(NAME loops-cutoff-ksub
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 600
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/ksub.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-nstop
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --timeout 600
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/nstop.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# nr-S25 (cq-9kcq after S14; CR rule 14 case 2): differential families of small quantum-exit K-loops crossing exit tests (f1),
# carried-state updates (f2), readers after the loop (f3), placements (f4), trip effects (f5), K edges (f6), exit arms,
# nesting and widths (f7), calls and flags (f8), measured arms, received K and latches (f9), floating point and fenv (fb),
# each entry §6-checked against its C program; all passed with the K-static-copies lowering (4afda23b) as well.
# diff_fc (cq_invert regions, cq-037u2) and diff_fa (abort behind a measured outcome, cq-njnmt) fail until their beads are fixed.
add_test(NAME loops-cutoff-diff-f1
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f1.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f2
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f2.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f3
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f3.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f4
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f4.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f5
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f5.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f6
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f6.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f7
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f7.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f8
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f8.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-f9
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_f9.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-fb
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_fb.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-fc
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_fc.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_test(NAME loops-cutoff-diff-fa
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/diff_fa.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-mysin (CR rules 14, 23): a nested quantum-exit K-loop whose trips change the quantum floating-point environment, in a
# clone called under a quantum predicate (zero-trip guards): the inner loop's carried environment piece takes its latch value
# at the end of the trip, not at the inner exit block (musl printf_core, sscanf, ctime).
add_test(NAME loops-cutoff-nest-fenv
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_probes.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT}
          ${CMAKE_CURRENT_SOURCE_DIR}/probes/nest_fenv.O1.ll
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
