; lowering_loop_break_qq_phase.ll — POSITIVE emission (Phase 7.4 Inc 2, epic
; y05j; coverage test_C_libtooling-mvrb). The PHASE-CARRYING-COMPARAND sibling of
; lowering_loop_break_qq.ll: a value-arm `break` whose tainted Q==Q condition
; compares the rail against a loop-invariant comparand `p` that carries a RELATIVE
; PHASE (an Rz / cq_phi in p's lineage). Source shape:
;
;     int p0 = cq_theta(pseed, 0.5);
;     int p  = cq_phi(p0, 0.3);       // Rz — p now carries a relative phase
;     int q  = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;                  // in-place value rail self-update
;         if (q == p) break;          // TAINTED Q==Q break flag (rail vs phase-p)
;     }
;     return cq_measure(q);
;
; WHY THE COMPARAND'S RELATIVE PHASE RIDES INERT (the load-bearing rationale, cleared
; by a 5-lens adversarial Rule-13 sign-off 2026-06-30 — permutation-completeness /
; phase-kickback / free-cleanliness / spine-terminal / entanglement-semantics, 0
; concrete holes): the ENTIRE break construct (forward capture + exit consolidation +
; reverse-play) emits ONLY computational-basis PERMUTATION gates — cqrt_xorc/addc,
; cqrt_toffoli/cnot, cqrt_copy_<W>[_controlled], cq_template_icmp_eq_<W>(+_unc),
; cqrt_alloc(|0>)/cqrt_free(|0>), cqrt_measure. There is NO Ry/Rz/Hadamard ANYWHERE
; inside it; the ONLY cqrt_rz is PRE-LOOP (it prepares p's phase, OUTSIDE the
; construct). So the construct acts as a FIXED permutation π on the computational
; basis: any input amplitudes — incl. p's relative phase e^{iθ} — ride inert
; (out = Σ γ_x |π(x)>, γ_x preserved). The comparand `p` is consumed EXCLUSIVELY as
; an operand/control of the QQ eq-compare and its matched `_unc` — never rotated,
; never copied into `out`, never measured, never freed — so `p` is restored EXACTLY
; (phase intact) and LEFT ALLOCATED (the Rule-6 safe leak, identical to the bare-mint
; comparand in lowering_loop_break_qq.ll). This is DISTINCT from the B3 phase fence,
; which permanently declines a phase-class ESCAPING ANSWER (the rail itself carrying
; the phase — there method-B's CNOT copy-out would dephase, Rule 7); a phase on the
; COMPARAND is never copied out, so Rule 7 does not bite.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PLEAK < %t.cqd0.ll
;
; --- p built as cq_theta THEN cq_phi (the Rz is the relative phase) ------------
; CHECK: %[[P:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; CHECK: call void @cqrt_ry_i32(i32 %[[P]], double 5.000000e-01)
; CHECK: call void @cqrt_rz_i32(i32 %[[P]], double 3.000000e-01)
; CHECK: %[[RAIL:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; --- FORWARD body: in-place rail xor, then the bare Q==Q compare (rail vs p) + _unc
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: %[[FCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[RAIL]], i32 %[[P]])
; CHECK: call void @cqrt_toffoli(i32 %[[FCMP]],
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[FCMP]], i32 %[[RAIL]], i32 %[[P]])
; --- BACKWARD reverse-play clone: the SAME compare (rail vs p) reading the same %p --
; CHECK: cq.brk.rev:
; CHECK: %[[BCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[RAIL]], i32 %[[P]])
; CHECK: call void @cqrt_toffoli(i32 %[[BCMP]],
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[BCMP]], i32 %[[RAIL]], i32 %[[P]])
; --- the inverse rail-mut closes the reverse-play; R/idx freed, out measured ----
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; The two CHECK-NOTs mirror LIVE diagnostics (documentary on this -S stdout stream —
; a decline regression is caught by the positive CHECKs failing on empty stdout).
; CHECK-NOT: cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop
;
; --- NEITHER p NOR the phase-source p0 is ever freed — left allocated-clean (Rule 6)
; The compiler must NOT reverse the pre-loop cqrt_rz: that would be a hidden
; measurement collapsing the answer (p is entangled with out on every break branch).
; PLEAK: %[[P2:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; PLEAK-NOT: cqrt_free(i32 %[[P2]])

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_qq_phase(i32 %x, i32 %pseed, i32 %n) {
entry:
  %p0 = call i32 @cq_theta_si32(i32 %pseed, double 5.000000e-01)  ; basis superposition
  %p = call i32 @cq_phi_si32(i32 %p0, double 3.000000e-01)        ; Rz — relative phase comparand
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %brk = icmp eq i32 %qn, %p                         ; TAINTED Q==Q break flag (rail vs phase-p)
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
