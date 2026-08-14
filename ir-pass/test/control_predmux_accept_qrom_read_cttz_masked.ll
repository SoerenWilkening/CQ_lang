; control_predmux_accept_qrom_read_cttz_masked.ll — ACCEPT (bd s6ao).
; THE REGRESSION PIN FOR THE CLANG-REACHABLE CELL. This is the shape six lines of
; ordinary C produce (`int k = __builtin_ctzll(bits); if (q<0.0) q -= tbl[k];`
; over a 64-entry const table), and it is the reason the s6ao fence is a real
; lowering fix rather than a capability loss.
;
; BEFORE the fence, `llvm.cttz.i64(%bits, i1 true)`'s `is_zero_poison` immarg
; tightened the ValueTracking range from [0,64] to [0,63], the claim reported
; Provable, and the read was emitted UNMASKED — an out-of-bounds load on the
; basis state `%bits == 0` (`q == +0.0`), where the true `cttz` is 64. `opt` exit
; 0, `opt -verify` clean, `free_pairing_check.py` 0 violations.
;
; AFTER the fence the poison-derived bound is refused, the index is no longer
; Provable — and because 64 IS a power of two the sound `NeedsMask` fallback
; takes over and emits `cq_template_and_i64_hl(%h, 63)` before the load. The read
; still lowers; it lowers CORRECTLY. `and idx, 63` maps every basis state into
; [0,63], so the excluded state reads a garbage row that the merge's ∧-with-
; block-predicate discards, which is exactly the fallback's stated contract.
;
; *** THE `CHECK` ORDER IS THE ASSERTION. *** The mask must be emitted BEFORE the
; load and must feed it. A fixture that merely asserted `cq_template_and_i64_hl`
; appears somewhere would pass on a module that masked a different value, or
; masked after the read — so the load's index operand is bound to the mask's
; result by name. This is the whole behavioural difference the fence buys.
;
; *** THERE IS NO DECLINE TWIN, AND THAT IS A STRUCTURAL FACT, NOT AN OMISSION.
; *** `cttz(x, i1 true)` bounds at [0,63] and `i1 false` at [0,64], so the ONLY
; table size whose verdict the immarg can change is exactly 64 — which is a power
; of two, so the outcome is always the masked accept below and never a decline. A
; 48-cell variant was written and DELETED after measuring that it declines
; pre-fence too (63 >= 48), i.e. it pinned nothing. Do not re-add one.
;
; NOR DOES THIS FIXTURE DISCRIMINATE THE ctpop/ctlz/cttz RULE ITSELF: delete that
; rule and `full()` also refuses the bound, so the read still masks and this file
; still passes. What it pins is the OBSERVABLE — that this cone lowers MASKED
; rather than unmasked — which is the property the miscompile violated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@t64 = internal unnamed_addr constant [64 x double] zeroinitializer
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i64 @llvm.cttz.i64(i64, i1 immarg)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = call i64 @llvm.cttz.i64(i64 %bits, i1 true)   ; is_zero_poison — refused
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [64 x double], ptr @t64, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hd = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hd, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 64)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_cttz_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[Z]], i64 63)
; CHECK:     call i32 @cqrt_qram_load_f64(i32 %[[T]], i32 %[[M]])
