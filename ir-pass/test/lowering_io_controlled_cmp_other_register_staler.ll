; lowering_io_controlled_cmp_other_register_staler.ll — ACCEPT, and it is the
; DISCRIMINATING control for `lowering_reject_io_controlled_cmp_blind_staler.ll`
; (Track A.1, Rule-13 ROUND-2 finding F-A1R2-1; probe
; `review_a1_r2_probes/io6.c`, plain `clang -O1` C).
;
;     void emit(int seed) {
;       int q  = seed; cq_theta(&q, 0.5);
;       int r  = seed; cq_theta(&r, 0.25);
;       int q2 = q; cq_theta(&q2, 0.9);  /* staler on q's WIRE — NOT on r's */
;       if (r > 5) printf("%d", r);      /* ctrl = flag minted from r */
;       (void) cq_measure(q2);
;       (void) cq_measure(r);
;     }
;
; WHY IT MUST KEEP LOWERING. Unexempting rung (iii) for the 7.6 sink is a
; question about the CONDITION's wire, not a blanket refusal of any in-place Ry
; in the function: `r`'s rail carries no gate between its Ry and the mint, so the
; flag encodes exactly the predicate the source compares. If this file ever goes
; red, the narrowing has become "decline whenever the module contains a sibling
; theta", which is a different and much wider fence than the one that was asked
; for. GREEN on the ORACLE (`main` 0c7380c), on the pre-round-2 checkpoint
; b439944 and here — MEASURED on all three.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @emit(i32 %seed) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %c  = icmp sgt i32 %r, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %p = call i32 (ptr, ...) @printf(ptr @.str, i32 %r)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m1 = call i32 @cq_measure_si32(i32 %q2)
  %m2 = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; The flag is minted from the CONDITION's own rail (%h1, `r`) and the staler
; rides the OTHER rail (%h, `q`); the controlled tape write, the strip and the
; free are the ordinary 7.6 stream:
; CHECK:      %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_ry_i32(i32 %[[HQ]], double 5.000000e-01)
; CHECK:      %[[HR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_ry_i32(i32 %[[HR]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[HQ]], double 9.000000e-01)
; CHECK:      %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[HR]], i32 5)
; CHECK:      call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[HR]])
; CHECK:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[HR]], i32 5)
; CHECK:      call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  br i1

; Whole-file exact counts (a trailing CHECK-NOT after the positives is windowed
; and asserts nothing — the F-L6-1 / Inc-4 lesson):
; RYCNT-COUNT-3: call void @cqrt_ry_i32
; RYCNT-NOT:     call void @cqrt_ry_i32
; MCNT-COUNT-2:  = call i32 @cqrt_measure_i32(
; MCNT-NOT:      call i32 @cqrt_measure
; FCNT-COUNT-1:  call void @cqrt_free
; FCNT-NOT:      call void @cqrt_free
; XCNT-NOT:      call void @cqrt_x

; The pass must stay silent on stderr — no diagnostic, no M-A warning:
; SILENT-NOT: cq controlled lowering
; SILENT-NOT: cq I/O output sink
