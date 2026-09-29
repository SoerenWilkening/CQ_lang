; control_inplace_ry_reject_stateprep_nomerge_nested_offoperand.ll — DECLINE
; (bd test_C_libtooling-fmt3, owner ruling 2026-09-28, option B).
;
; THE C SOURCE (`fmt3_probes/src/n13.c`) — the SECOND route, and the evidence
; the owner withdrew the 2026-09-28 α-extension on:
;
;     int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
;     if (q2 > 3) { if (q == 20) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
;     return cq_measure(r) + cq_measure(t) + cq_measure(q2);
;
; Here the rotated register `t` is NOT the inner compare's operand (`q`). IPSCCP
; cannot pin `t`, so the two arms differed in ONE operand; BEFORE fmt3 SimplifyCFG
; sank them with ONE φ `[t, 5]`, FoldTwoEntryPHINode made
; `select (q == 20), t, 5`, and InstSimplify's `simplifyWithOpReplaced(t, q := 20)`
; = `sdiv 20, 4` = 5 folded it to the literal. The module was then IDENTICAL to
; `a6`'s and to the legitimate `if (q2 > 3) r = cq_theta(5, .9);`, and ACCEPTED.
;
; SINCE fmt3 (`nomerge` on every `cq_theta_*`) this is what `clang -O1` produces
; (transcribed from `fmt3_probes/out/n13.nomerge.s1.ll`): nothing is sunk, the
; inner arm keeps `cq_theta(%t, .9)`, and the nest declines.
;
; ⚠ RETIREMENT TRIGGER (L8): the day a nested region lowers, the inner if/else is
; a CHAINED arm on `%t` beside a literal prep and must decline
; `if/else state prep beside a chained or phase arm` (its no-region sibling
; `..._nomerge_noregion_offoperand.ll` declines earlier, at R4, because there the
; compare's register feeds the rotated one IN PLACE). Re-derive; never let it
; become an ACCEPT that prepares a fresh |5>.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout; the property is pinned by the
; `not` on the RUN line, not by any IR-text check.
; CHECK: error: {{.*}}cq controlled lowering: nested control flow under quantum control

declare i32 @cq_theta_si32(i32, double) #0
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01) #1
  %t  = sdiv i32 %q, 4
  %q2 = call i32 @cq_theta_si32(i32 7, double 4.000000e-01) #1
  %c  = icmp sgt i32 %q2, 3
  br i1 %c, label %inner, label %merge
inner:
  %ci = icmp eq i32 %q, 20
  br i1 %ci, label %armT, label %armF
armT:
  %rt = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01) #1
  br label %merge
armF:
  %rf = call i32 @cq_theta_si32(i32 5, double 9.000000e-01) #1
  br label %merge
merge:
  %r  = phi i32 [ %rt, %armT ], [ %rf, %armF ], [ 5, %entry ]
  %m0 = call i32 @cq_measure_si32(i32 %r)
  %m1 = call i32 @cq_measure_si32(i32 %t)
  %s0 = add nsw i32 %m1, %m0
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %s1 = add nsw i32 %s0, %m2
  ret i32 %s1
}

attributes #0 = { nomerge }
attributes #1 = { nomerge nounwind }
