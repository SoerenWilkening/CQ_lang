; control_inplace_ry_reject_stateprep_runtime_seed_round2_quantum_from_c.ll — DECLINE
; (bd test_C_libtooling-z0re, the L1 re-ask): the PLAIN-C spelling of
; `control_inplace_ry_reject_stateprep_runtime_seed_round2_quantum.ll` — its body is the
; llvm-linked `clang -O1` output of `z0re_probes/src/l3C.c` + `l3C.lib.c`, metadata and
; attribute groups stripped.
;
;     __attribute__((const)) int f(int a);            // lib TU: return a + 100;
;     int y = 5; if (q > 3) y = f(n);                 // 6.5: classical call under control
;     if (c > 1000) puts("x");                        // a classical block BETWEEN the regions
;     int r = y; if (q2 + y > 7) r = cq_theta(y, .2); // runtime-seed prep on the 6.5 result
;
; WHY THIS FILE EXISTS BESIDE THE HAND-IR ONE: it proves the hazard the bd z0re widening
; introduces is reachable from plain C, not only from hand IR. MEASURED with the re-ask
; disabled (mutant M6, TRACK_Z0RE.md §5.4): exit 0, STRICT stage 2b `0 violation(s)`,
; and the stream `add(%out, q2) -> h6; icmp_sgt(h6, 7) -> h7;
; cqrt_ry_i32_controlled(h7, %out, .2)` — an Ry on the 6.5 `%out` rail that the flag's
; own derived record `h6` reads, `h6` left DIRTY (Rule 8), with only the M-A WARNING.
; The `puts` block is load-bearing for REACHING the fence: without it the 6.5 merge IS
; the prep's Pred and the pair declines `control flow` at the `hcrg` precedence check
; (bd 35t0) first. On the ORACLE (main 9a230646) it declines at F1's literal-only clause.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: state prep seed became quantum under quantum control

@.str = private unnamed_addr constant [2 x i8] c"x\00", align 1

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.500000e-01)
  %11 = icmp sgt i32 %9, 3
  br i1 %11, label %12, label %14
12:
  %13 = tail call i32 @f(i32 noundef %8) #1
  br label %14
14:
  %15 = phi i32 [ %13, %12 ], [ 5, %2 ]
  %16 = icmp sgt i32 %0, 1000
  br i1 %16, label %17, label %19
17:
  %18 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  br label %19
19:
  %20 = add nsw i32 %15, %10
  %21 = icmp sgt i32 %20, 7
  br i1 %21, label %22, label %24
22:
  %23 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 2.000000e-01)
  br label %24
24:
  %25 = phi i32 [ %23, %22 ], [ %15, %19 ]
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25)
  ret i32 %26
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare noundef i32 @puts(ptr nocapture noundef readonly)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @f(i32 noundef %0) #0 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind memory(none) }
