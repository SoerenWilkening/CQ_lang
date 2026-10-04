; control_inplace_ry_reject_stateprep_nomerge_noregion_offoperand.ll — DECLINE
; (bd test_C_libtooling-fmt3, owner ruling 2026-09-28, option B).
;
; THE C SOURCE (`fmt3_probes/src/n17f.c`) — the second route with NO region:
;
;     int W = q + 1; int r;
;     if (q == 5) { r = W; cq_theta(&r, .9); } else { r = 6; cq_theta(&r, .9); }
;     return cq_measure(r) + cq_measure(W) + cq_measure(q);
;
; BEFORE fmt3: sink → φ `[W, 6]` → `select (q == 5), W, 6` → InstSimplify
; `simplifyWithOpReplaced(W, q := 5)` = `add 5, 1` = 6 → an UNCONDITIONAL
; `@cq_theta_si32(6, .9)`, `W` live and measured, never rotated; the oracle ACCEPTED
; (8 trace lines, exit 0) with no fence ever asked. The rotated register `W` is
; not the compare's operand.
;
; SINCE fmt3 (`nomerge` on every `cq_theta_*`) this is what `clang -O1` produces
; (transcribed from `fmt3_probes/out/n17f.nomerge.s1.ll`) and it declines at R4:
; `W = add nsw q, 1` puts the rotated register on the condition's wire.
;
; ⚠ RETIREMENT TRIGGER (L8): if R4 narrows (the F2 header's α theorem names R4 and
; 2c as its two doors), this module must still decline — the if/else is a CHAINED
; arm beside a literal prep (`if/else state prep beside a chained or phase arm`).
; Re-derive the string then; never let it become an ACCEPT that prepares |6>.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout; the property is pinned by the
; `not` on the RUN line, not by any IR-text check.
; CHECK: error: {{.*}}cq controlled lowering: rotation arm on a condition wire under quantum control

declare i32 @cq_theta_si32(i32, double) #0
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01) #1
  %w  = add nsw i32 %q, 1
  %c  = icmp eq i32 %q, 5
  br i1 %c, label %armT, label %armF
armT:
  %rt = call i32 @cq_theta_si32(i32 %w, double 9.000000e-01) #1
  br label %merge
armF:
  %rf = call i32 @cq_theta_si32(i32 6, double 9.000000e-01) #1
  br label %merge
merge:
  %r  = phi i32 [ %rt, %armT ], [ %rf, %armF ]
  %m0 = call i32 @cq_measure_si32(i32 %r)
  %m1 = call i32 @cq_measure_si32(i32 %w)
  %s0 = add nsw i32 %m1, %m0
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s1 = add nsw i32 %s0, %m2
  ret i32 %s1
}

attributes #0 = { nomerge }
attributes #1 = { nomerge nounwind }
