; control_angle_select_reject_constexpr_arm.ll — DECLINE (S1, the ARM-VALUE
; fence, clause (1b)): a select arm that is a `Constant` but NOT a `ConstantFP`.
;
; ROUND-2 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens R1 item 5). The round-1
; arm-value fence split the world with `dyn_cast<ConstantFP>` and treated
; everything else as a RUNTIME arm:
;
;     if (!CA || !CB) return true;   // "at least one runtime arm: no
;                                    //  compile-time difference exists"
;
; That comment is FALSE for a `double`-typed `ConstantExpr`. The arm below is
; `bitcast (i64 ptrtoint (ptr @g to i64) to double)` — a LINK-TIME constant, not
; a run-time value. There IS a compile-time difference; it is simply not one this
; compiler can evaluate (the address is chosen by the linker), so the finiteness
; clause (2a), the difference-finiteness clause (2b) AND the rounding clause (3)
; all silently did not run, and the shape ACCEPTED with
;
;     %cqang = fsub double bitcast (i64 ptrtoint (ptr @g to i64) to double), 3.0e-01
;     call void @cqrt_ry_i32_controlled(i32 %f, i32 %h, double %cqang)
;
; i.e. a controlled rotation whose angle is a reinterpreted ADDRESS. Nothing in
; the shipped fence could bound it: the bit pattern is not known until link, so it
; may be a NaN, an infinity, or an angle 10^300 rad away from anything the source
; named. Over-declining is safe (Prime Directive) and this class is reachable only
; from hand-written IR — every C punning idiom measured by the reviewer goes
; through a `load`, and a literal `bitcast (i64 K to double)` is folded to a
; `ConstantFP` by the LLVM-19 parser before the pass ever sees it.
;
; CLAUSE ORDER, and it is deliberate — see the block comment above
; `angleSelectArmsAdmissible` in `ir-pass/src/ArmClassify.cpp`. Clause (1)
; (`valueCarriesUndef`) is asked BEFORE this one, so an arm that is BOTH a
; `ConstantExpr` AND carries `undef` is refused as an undef arm, which is the more
; specific fact and the one with the miscompile derivation attached
; (`control_angle_select_reject_undef_constexpr_arm.ll` is that cell). The arm
; here carries no `undef`: `@g` is `i32 7` and `valueCarriesUndef` does not
; descend into a `GlobalValue`'s ADDRESS being well defined — so this fixture is
; owned by clause (1b) alone and goes GREEN-ON-ACCEPT the moment (1b) is deleted.
;
; Reproducer from the round-2 review, lens R1 (`review2b_r2/R1/probes/ce2/ce_addr_A.ll`).
; ORACLE DISPOSITION: the pre-2b binary declines it `rotation angle under quantum
; control` (it declines every angle select), so this is a decline both sides —
; the red-green is against the ROUND-1 binary, which ACCEPTED it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

@g = global i32 7

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double bitcast (i64 ptrtoint (ptr @g to i64) to double), double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
