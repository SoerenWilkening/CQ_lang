; lowering_uncompute_interior_loop_consumer_and_after.ll — ACCEPT (M-B Increment
; 5, bd test_C_libtooling-4p7j Rule-13 round, finding F4c). THE ONE SHIPPED SHAPE
; WHERE A CONSUMER EXECUTES K TIMES BEFORE A ONCE-ONLY DISCHARGE, and the reason
; the irreducible-cycle fence keys on WRITES and never on reads.
;
;     x = a * a;                       /* minted once, in a dominating block */
;     for (i = 0; i < 3; i++) m += cq_measure(x < i);   /* K reads, in a loop */
;     d = x > 100;                     /* one more read, after the loop */
;     return m + cq_measure(d);
;
; WHY THE DISCHARGE IS SOUND WITH A CONSUMER INSIDE A LOOP. `%h_op` is minted in
; `entry`, which dominates everything and cannot repeat. Its in-loop consumer is
; a `cq_template_icmp_*` — a forward reassigning producer, which READS the rail
; and mints a fresh one; it never writes `%h_op`. So after K trips the rail still
; holds exactly `a*a`, which is the value the single `cq_template_mul_i32_unc`
; recomputes and XORs away. The positional proof is met on the nose:
; `DT.dominates(loop-consumer, At)` (the loop body dominates the exit block) and
; `!isPotentiallyReachable(At, loop-consumer)` (nothing returns to the loop from
; the exit), so `provablyBefore` holds for the K-times reader as well.
;
; THE IN-LOOP RAILS THEMSELVES LEAK, and that is the §1 candidate skip (a rail
; MINTED in a loop is re-minted per trip — lowering_uncompute_interior_leak_loop_rail.ll).
; This fixture is its complement: the producer OUTSIDE, the consumers inside AND
; after.
;
; THIS IS ALSO THE SHAPE THE STAGE-2b CHECKER CANNOT SEE. `tools/free_pairing_check.py`
; models one straight-line stream at a time, so the cross-block discharge below
; reports `UNPROVEN U3-extern-rail` — the rail is written in the exit stream but
; minted in another block. That is a VISIBILITY gap, not a violation: no shipped
; slice has this shape today, and the first one that does will need the checker
; taught the "minted in a dominating block, no intervening write" case (bd filed
; in the Rule-13 round, F2). Pinning it HERE is deliberate — a lit fixture is the
; only gate that can witness this placement at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_loop_consumer(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = mul i32 %q, %q
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %sum, %loop ]
  %c = icmp ult i32 %x, %i                  ; K READS of %x — never a write
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %sum = add i32 %acc, %m
  %i1 = add i32 %i, 1
  %e = icmp ult i32 %i1, 3
  br i1 %e, label %loop, label %out
out:
  %d = icmp ugt i32 %x, 100                 ; the last read, after the loop
  %zd = zext i1 %d to i32
  %m2 = call i32 @cq_measure_si32(i32 %zd)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %sum, %m2
  %r2 = add i32 %r, %m3
  ret i32 %r2
}

; CHECK-LABEL: define i32 @interior_loop_consumer(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[H]], i32 %[[H]])
; the in-loop compare rail is minted per trip and LEAKS (no `_unc`, no free):
; CHECK:      %[[LC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[OP]],
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[LC]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; after the loop, the once-only LIFO discharge of the compare rail AND of the
; rail its K-times reader was reading:
; CHECK:      %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i32_hl(i32 %[[OP]], i32 100)
; CHECK-NEXT: %[[ZD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[D]])
; CHECK-NEXT: call void @cq_template_icmp_ugt_i32_hl_unc(i32 %[[D]], i32 %[[OP]], i32 100)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cq_template_mul_i32_unc(i32 %[[OP]], i32 %[[H]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[ZD]])

; The BORROWED source wire is never adjointed and never freed (one anchor, one
; prefix ⇒ window anchor -> EOF; bd memory [filecheck-check-not-window-trap]):
; NOFREEH:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEH-NOT: call void @cqrt_ry_i32(i32 %[[H2]], double -5.000000e-01)
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])
