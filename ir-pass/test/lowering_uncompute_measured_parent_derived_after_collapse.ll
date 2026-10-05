; lowering_uncompute_measured_parent_derived_after_collapse.ll — ACCEPT (bd
; test_C_libtooling-ptue, Rule-11 round-1 finding F2; stated explicitly rather
; than left implicit). The `clang -O1` IR of
;     int q = x; cq_theta(&q, .25); int mq = cq_measure(q);
;     int q2 = q + 1; int t = q2 ^ 9; cq_theta(&t, .5);
;     return mq + cq_measure(q2);
; Declined before ptue ("dead chain would free a measured register").
;
; WHAT THE RETRY BORROWS, AND WHAT IT DOES NOT LOOK AT. The dead terminal is `t`;
; the walk reaches `q2` (measured) and the retry borrows it, so it never walks on
; to `q`. `q2`'s own producer `q + 1` reads `q` AFTER `q`'s collapse — a
; post-measurement use of a name, bd yiid. `measuredParentsReadBeforeCollapse`
; deliberately checks only reads the REVERSAL REPLAYS (gates of the reduced DAG),
; and the reversal never replays `q + 1`: it reads `q2`, and only before `q2`'s
; own collapse. The forward `q + 1` is emitted by `lowerOps` whether or not `t`
; exists — `int mq = cq_measure(q); return mq + cq_measure(q + 1);` lowers the
; same `add_hl` after the measure on its own (measured, rc 0) — and bd yiid is a
; RULED capability (owner 2026-09-14: "a
; capability, not a decline", the measured name is re-usable by re-preparation;
; 2026-09-15 E3 (b) BROAD: every use positioned after the measurement is
; fresh/classical; E3 is not built yet).
;
; HAND TRACE — one reading, and it is E3's too. measure(q) collapses q to |m>, a
; product state, so:
;   add_hl(q, 1)              q2 = |m+1>            (= E3's fresh(m) + 1)
;   xor_hl(q2, 9)             t  = |(m+1)^9>
;   ry(t, .5); ry(t, -.5)     cancel exactly
;   xor_hl_unc(t, q2, 9)      t = 0                 (q2 unmoved since the xor)
;   cqrt_free(t)              |0> in a product state — nothing learned
;   measure(q2)               m+1 with certainty: mq + measure(q2) = 2m+1, the
;                             program's value
; Nothing here depends on whether `q + 1` chains on the collapsed rail (today) or
; on a re-prepared one (E3): `q2`'s label is m+1 either way, and the reversal reads
; only `q2`. Contrast lowering_reject_uncompute_measured_parent_read_after_measure.ll,
; where the REVERSAL itself would replay the post-collapse read of `q`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = tail call i32 @cq_measure_si32(i32 %2)
  %4 = add nsw i32 %2, 1
  %5 = xor i32 %4, 9
  %6 = tail call i32 @cq_theta_si32(i32 %5, double 5.000000e-01)
  %7 = tail call i32 @cq_measure_si32(i32 %4)
  %8 = add nsw i32 %7, %3
  ret i32 %8
}

; CHECK-LABEL: define i32 @slice(i32 %0)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[MQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[Q2]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[Q2]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q2]])
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M2]], %[[MQ]]
; CHECK-NEXT:  ret i32 %[[S]]
