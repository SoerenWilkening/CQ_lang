; lowering_accept_measure_undef_zero.ll — ACCEPT: `cq_measure` of a WHOLE-VALUE
; `undef`/`poison` operand measures THE TYPE'S CONCRETE ZERO.
; bd test_C_libtooling-fve8, owner ruling 2026-09-15 (`DECISIONS.md` E2), which
; RETIRES part of the owner's own 2026-09-14 ruling (bd `z9t1` clause 4).
;
; The inverted twin of the shape this ruling retires is
; `lowering_reject_measure_undef_operand.ll` (historical name, now an ACCEPT).
; The surviving DECLINE is `lowering_reject_measure_undef_global_init.ll`.
;
; ── WHAT EACH FUNCTION PINS, AND WHY IT IS NOT DECORATION ────────────────────
;
;   @f_poison_i32      ONE predicate covers `poison`: `PoisonValue` derives from
;                      `UndefValue`, so `isa<UndefValue>` answers both and no
;                      second conjunct is owed.
;   @f_undef_i64       a width other than the i1/i32 the other files carry.
;   @f_undef_double    the f64 width. ⚠ A classical fp measure must NOT mint
;                      `cqrt_alloc_f64` — that is the f64/angle miscompile
;                      family (Rule 3 / Key Prohibitions), and the `NOALLOC`
;                      prefix below is exact for it.
;   @f_undef_f80       the two widths where "the type's zero" is not the digit
;   @f_undef_f16       0: `Constant::getNullValue` is type-generic and consults
;                      no width table, and these two pin that — `0xK00...0` and
;                      `0xH0000`. A per-width zero table would be the place a
;                      width family rots (Rule 15's lesson at a different site).
;   @f_constexpr_undef ⚠ MEASURED, NOT ASSUMED, and it CORRECTS the scoping
;                      record: `ptrtoint (ptr undef to i32)` is CONSTANT-FOLDED
;                      BY THE LLVM-19 PARSER to plain `i32 undef` (verified:
;                      `opt -passes=verify -S` reprints it as
;                      `call i32 @cq_measure_si32(i32 undef)`), so this is NOT a
;                      `ConstantExpr` residual — it is the whole-value clause
;                      under a different source spelling, and it ACCEPTS.
;                      RETIREMENT TRIGGER: if a later LLVM stops folding it,
;                      this function moves to a DECLINE and belongs in
;                      `lowering_reject_measure_undef_global_init.ll` instead.
;                      Do not delete it then — re-derive it.
;   @f_beside_quantum  ⚠ THE RAUW-TARGET DISCRIMINATOR, and the reason this file
;                      exists at all. The measured outcome is CONSUMED by an
;                      `add`, so the two candidate RAUW targets print
;                      differently: `Constant::getNullValue(Measure->getType())`
;                      gives `add nsw i32 %m, 0` — byte-identical to the
;                      written-zero twin — while RAUW-to-OPERAND would give
;                      `add nsw i32 %m, undef`, which is NOT the twin's stream
;                      and would make the refinement claim FALSE. It also pins
;                      that the retired decline used to PREEMPT an otherwise
;                      accepting module: `LLVMContext::diagnose` EXITS on the
;                      first `DS_Error` (bd `br4a`), so on the ORACLE this whole
;                      function's quantum content was never lowered.
;
; RED-GREEN: every function here DECLINES on the session ORACLE (`main`
; 74eabd2c, `cq-opt` 0e280fc6) with `cq_measure_<sfx> operand is an undef/poison
; literal; a classical measurement needs a defined value` — one diagnostic for
; the whole file, since the first `DS_Error` exits — so this file is RED there
; on the EXIT CODE.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MOD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOALLOC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOINTR < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sll(i64)
declare double @cq_measure_f64(double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare half @cq_measure_f16(half)
declare i32 @cq_theta_si32(i32, double)

define i32 @f_poison_i32() {
entry:
  %m = call i32 @cq_measure_si32(i32 poison)
  ret i32 %m
}
; CHECK-LABEL: define i32 @f_poison_i32()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i32 0

define i64 @f_undef_i64() {
entry:
  %m = call i64 @cq_measure_sll(i64 undef)
  ret i64 %m
}
; CHECK-LABEL: define i64 @f_undef_i64()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i64 0

define double @f_undef_double() {
entry:
  %m = call double @cq_measure_f64(double undef)
  ret double %m
}
; CHECK-LABEL: define double @f_undef_double()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret double 0.000000e+00

define x86_fp80 @f_undef_f80() {
entry:
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 undef)
  ret x86_fp80 %m
}
; CHECK-LABEL: define x86_fp80 @f_undef_f80()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret x86_fp80 0xK00000000000000000000

define half @f_undef_f16() {
entry:
  %m = call half @cq_measure_f16(half undef)
  ret half %m
}
; CHECK-LABEL: define half @f_undef_f16()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret half 0xH0000

define i32 @f_constexpr_undef() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr undef to i32))
  ret i32 %m
}
; CHECK-LABEL: define i32 @f_constexpr_undef()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i32 0

define i32 @f_beside_quantum() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %mu = call i32 @cq_measure_si32(i32 undef)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s = add nsw i32 %mq, %mu
  ret i32 %s
}
; CHECK-LABEL: define i32 @f_beside_quantum()
; CHECK:         %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:         call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
; CHECK:         %m = call i32 @cqrt_measure_i32(i32 %h)
; CHECK:         add nsw i32 %m, 0

; ── WHOLE-FILE PREFIXES (Rule 12 (a): counts and negatives get their OWN
; prefix, never a window inside another one) ──────────────────────────────────
;
; all seven bodies survive — this is a lowering, not a deletion:
; MOD: define i32 @f_poison_i32()
; MOD: define i64 @f_undef_i64()
; MOD: define double @f_undef_double()
; MOD: define x86_fp80 @f_undef_f80()
; MOD: define half @f_undef_f16()
; MOD: define i32 @f_constexpr_undef()
; MOD: define i32 @f_beside_quantum()
;
; EXACTLY ONE of each i32 gate in the whole module — the one `@f_beside_quantum`
; owes its `cq_theta` — so a SECOND rail, a SECOND rotation or a SECOND
; measurement gate minted for one of the seven CLASSICAL measures is caught. The
; `-NOT` after each count is the "exactly N" idiom (it only sees the region
; AFTER the match), not a negative sharing a positive prefix — Rule 12 (a)'s
; hazard is the reverse, a positive count WINDOWING negatives that follow it.
; ⚠ each pattern names the CALL, never the bare symbol: the lowered module also
; carries a `declare` for every one of them, and a bare `-NOT: cqrt_alloc_i32`
; would match that declare and fail on a correct module.
; COUNT-COUNT-1: call i32 @cqrt_alloc_i32(i32 0)
; COUNT-NOT: call i32 @cqrt_alloc_i32(i32 0)
; COUNT-COUNT-1: cqrt_ry_i32(i32 %h
; COUNT-NOT: cqrt_ry_i32(i32 %h
; COUNT-COUNT-1: cqrt_measure_i32(i32 %h
; COUNT-NOT: cqrt_measure_i32(i32 %h
;
; the SEVEN classical undef/poison measures mint nothing at all. The ONE
; `cqrt_alloc_i32` in
; the module belongs to `@f_beside_quantum`'s `cq_theta`, so the negative is
; spelled per WIDTH rather than as a bare `cqrt_alloc` — an f64 or i64 rail here
; would be the f64/angle miscompile family:
; NOALLOC-NOT: cqrt_alloc_f64
; NOALLOC-NOT: cqrt_alloc_i64
; NOALLOC-NOT: cqrt_measure_f64
; NOALLOC-NOT: cqrt_measure_i64
;
; ⚠ THE RAUW TARGET WAS THE TYPE'S ZERO, NOT THE OPERAND. These four lines are
; what separates the two spellings; without them this file would pass under a
; RAUW-to-operand implementation and the refinement claim would be unpinned.
; ⚠ NOT a bare `-NOT: undef`: this module's own `; ModuleID`/`source_filename`
; lines carry the word in the FILE PATH (bd `qta2`'s vacuity trap).
; NOUNDEF-NOT: ret i32 undef
; NOUNDEF-NOT: ret i64 undef
; NOUNDEF-NOT: ret double undef
; NOUNDEF-NOT: ret x86_fp80 undef
; NOUNDEF-NOT: ret half undef
; NOUNDEF-NOT: add nsw i32 %m, undef
;
; every front-end intrinsic call is GONE (Rule 1's checked postcondition,
; `declineSurvivingIntrinsicCalls`, would otherwise be loud):
; NOINTR-NOT: call{{.*}}@cq_measure_
; NOINTR-NOT: call{{.*}}@cq_theta_
;
; and the whole module accepts SILENTLY — the owner ruled twice against a
; warning on this family ("both codes are supposed to compie!! also no
; warnings"):
; ACC-NOT: undef/poison literal
; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: warning
