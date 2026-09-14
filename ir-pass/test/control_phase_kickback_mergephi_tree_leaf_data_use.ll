; control_phase_kickback_mergephi_tree_leaf_data_use.ll — ACCEPT (bd `4aiu`,
; Track P; ADDED BY Rule-13 ROUND-1 FINDING F-P1-3(c)).
;
; THE SHAPE: `control_phase_kickback_mergephi_tree_leaf.ll` PLUS an out-of-branch
; DATA use of the φ leaf — the C is
;
;   int  q  = cq_theta(0, 0.7);
;   bool b0 = cq_theta((bool)0, 0.5);
;   bool b1 = 0;  if (b0) { b1 = cq_theta(b1, 0.5); }
;   if (b1 && q > 3) cq_phi(0.3);
;   int  z  = (int)b1 + q;                     /* <-- the out-of-branch use */
;   return cq_measure(b0) + cq_measure(b1) + cq_measure(z);
;
; (review probe `review_r1_probes/r08_phi_data_use.c`; this fixture is its
; hand-IR twin and its stream is BYTE-FOR-BYTE that probe's 21-line trace.)
;
; ⚠ WHY THIS FILE EXISTS AT ALL — IT PINS AN ACCEPT ASYMMETRY NOBODY HAD
; ARGUED. Step 6's tree-wide "condition used outside the branch" fence builds
; `TreeSet` from `Tree.Leaves` + `Tree.Nodes` ONLY, so neither a RAIL leaf nor a
; region-merge φ leaf is asked about its other users. The COMPARE-leaf twin of
; this program DECLINES `condition used outside the branch` (probe `r25`); this
; one ACCEPTS. That asymmetry was measured, not designed, and an accept shape
; nobody wrote down is how the next widening loses it.
;
; WHY IT IS SOUND — the rail-leaf sanction, one construct over (`ArmClassify`
; step 5b's header carries the argument). The fence protects a MINTED flag that
; this emitter also STRIPS and FREES inside the region: an out-of-tree reader
; would read a freed rail. A φ leaf mints NOTHING — `CondTreeEmit` maps it to
; ITSELF (`FlagOf[V] = V`) and the AND node reads it in a `cqrt_toffoli` CONTROL
; slot, diagonal and basis-label-preserving — so the register is exactly the
; value it was and the data use lowers through the ordinary opcode net:
; `cq_template_zext_i1_to_i32(h2)` → `cq_template_add_i32(h1,h_cast)` → the
; `_unc` → `cqrt_free(h_cast)`.
;
; UNITARY + Rule 6/7: `g = |0⟩`; `cqrt_toffoli(b1, cmp, g)` sets `g = b1 ∧ (q>3)`;
; `cqrt_rz_i1(g, φ)` phases exactly that branch; the SAME self-inverse toffoli
; returns `g` to `|0⟩` on EVERY branch, which is what makes `cqrt_free(g)` a
; proven-`|0⟩` free. The user's register `%h2` is read ONLY as a control and as
; template DATA — never `cqrt_x`-bracketed, never freed. STRICT stage 2b on this
; module: `4 rail mint(s) of which 3 left allocated, 3 cqrt_free site(s): 3
; verified, 0 violation(s), 0 unproven`.
;
; ⚠ RETIREMENT TRIGGER: if a φ leaf is ever given a MINT of its own (a copy
; ancilla, an inverted flag — anything `stripCondNetwork` tears down), the
; premise dies and step 6 must add `RailPhiLeaves` to `TreeSet`. This file then
; becomes a DECLINE; re-derive it, do not delete it. The RAIL leaf owes the
; identical re-derivation at the identical moment.
;
; ⚠ RED ON THE ORACLE: `control flow` (the grammar refused the φ leaf).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TOFCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  %c = icmp sgt i32 %q, 3
  %and = and i1 %b1, %c
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %z = zext i1 %b1 to i32
  %s = add nsw i32 %q, %z
  %m0 = call i1 @cq_measure_i1(i1 %b0)
  %m1 = call i1 @cq_measure_i1(i1 %b1)
  %m2 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m2
}

; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[HQ]], i32 3)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[F]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[F]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[HQ]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H1]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[HQ]], i32 %[[C]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[C]], i32 %[[H1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[S]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; TOFCNT-COUNT-2: call void @cqrt_toffoli(
; TOFCNT-NOT: call void @cqrt_toffoli(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT: call i32 @cqrt_alloc_
