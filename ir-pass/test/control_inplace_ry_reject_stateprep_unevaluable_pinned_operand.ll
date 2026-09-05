; control_inplace_ry_reject_stateprep_unevaluable_pinned_operand.ll — DECLINE by
; F2's CONSERVATIVE half: "a function of a pinned register that we cannot
; evaluate".
;
; The seed is 7 and NOTHING in this module is provably 7 on either edge — the
; decline is deliberate and it is an OVER-decline. It exists because the round-3
; fix has exactly ONE place where it stops looking, and that place needs a
; fixture on both sides.
;
; THE RULE. F2's forward evaluation models what LLVM's own constant machinery
; models (`ConstantRange::binaryOp` / `castOp` / `intrinsic`, exact
; `ConstantFold*` once every operand is pinned, `KnownBits` refinement). A
; tainted user it cannot bound is SKIPPED when none of its operands is pinned —
; sound, because `clang`'s lattice is overdefined there too, so no fold of the
; seed could have come from it. But when an operand IS EXACTLY PINNED and the
; result is still unevaluable, F2 DECLINES: that is a function of a pinned
; register whose value we cannot compute, and guessing it is the whole
; miscompile family this fence exists to stop.
;
; HERE: `%q` is pinned to `{5}` on the arm edge; `llvm.fshl(%q, %p, 8)` has a
; SECOND, unpinned tainted operand, so `ConstantFoldCall` cannot fire; and
; `fshl` is not one of the intrinsics `ConstantRange::isIntrinsicSupported`
; models (that set is `uadd_sat`/`usub_sat`/`sadd_sat`/`ssub_sat`/`umin`/`umax`/
; `smin`/`smax`/`abs`/`ctlz`/`cttz`/`ctpop` — the same set IPSCCP's
; `visitIntrinsicCall` uses). No abstract value; a pinned operand; decline.
;
; THE ONE-TOKEN CONTROL is `..._intrinsic_fshl.ll`, where BOTH data operands are
; the same pinned `%q`: there `ConstantFoldCall` evaluates the rotate EXACTLY,
; and the decline is a real pin rather than a refusal to guess. And
; `control_inplace_ry_stateprep_cond_derived.ll` is the control for the OTHER
; direction — a tainted user with NO pinned operand is skipped and the file
; accepts.
;
; MUTATION (recorded, not automated): make the conservative half return `true`
; instead of `false` and this file is the only one in the family that flips to
; ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 4.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %entry ]
  %t  = call i32 @llvm.fshl.i32(i32 %q, i32 %p, i32 8)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
