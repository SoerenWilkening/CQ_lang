; control_inplace_rz_dead_chain_reversed.ll — the §6a Rz peephole's TRANSPARENCY
; witness (bd test_C_libtooling-drbq Inc 2a, control-in-place-PRD §12.1).
;
; THIS IS THE FIXTURE FOR THE HALF OF INC 2a THAT IS NOT A SYMBOL SUBSTITUTION.
; Every other `control_inplace_rz_*` file pins the five route lines collapsing to
; one gate. This one pins what happens to the register's OWN dead data chain
; AFTERWARDS — the part the golden multiset audit needs to come out empty, and the
; part a wrong stem split would silently change.
;
; THE SHAPE. `r` carries a two-link dead chain (`y = r*7`, `z = y*2`) computed
; BEFORE the region; the region rotates `r`; `t = z*3` is measured after. So the
; interval [first gate reading r, the discharge point] STRADDLES the region, and
; the whole-DAG spine must reverse `z` then `y` and free both, reading `r` after
; the region fired.
;
; WHY IT IS LEGAL, and why it is the Rz stem specifically. `Uncomputation::
; preservesBorrowedParent` clause (d) needs every register the forward chain read
; to still hold its forward value when the adjoint fires. Under the swap ROUTE
; that held as a GROUP property: `cswap; rz(rail); cswap` restores r's basis label
; only because BOTH cswaps run (clause (d2), `TaintSet::RestoringRoutes`).
; Control-in-place emits no group, so the licence had to move to the gate — and
; there it is STRONGER: `cqrt_rz_i32_controlled(f, r, θ)` is `diag(1,e^{iθ})` on
; the f=1 branch and `I` on f=0, DIAGONAL EITHER WAY, so r's basis label is not
; restored-after-being-moved, it is NEVER MOVED. Clause (1b) states that pointwise.
;
; WHAT BREAKS IF THE STEMS ARE NOT SPLIT. Admit `cqrt_rz_<W>_controlled` to
; `ChainWalk::isInPlaceGateOn` (as Inc 1 did, harmlessly, while the gate had no
; caller) and this file goes red in TWO different ways at once: as a DAG link the
; gate joins `D.Calls`, so `emitDagReversal` emits its adjoint naming a flag the
; region already freed; and `railCarriesControlledRotation` freezes r's DAG, so
; the two `mul_unc`s and their frees below vanish entirely. Either way the four
; lines this file ends with are the ones that disappear.
;
; MEASURED AGAINST THE PRE-2a BINARY: the routed stream for this exact module has
; the identical four-line tail. That equality is the whole claim of §12.1.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The route's ABSENCE, on its own prefix anchored at the function header (a
; trailing CHECK-NOT scans only past the LAST positive of its prefix — bd memory
; filecheck-check-not-window-trap).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @dead_chain_across_region() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %y = mul nsw i32 %r, 7
  %z = mul nsw i32 %y, 2
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r2 = call i32 @cq_phi_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r2, %arm ], [ %r, %entry ]
  %t  = mul nsw i32 %z, 3
  %m1 = call i32 @cq_measure_si32(i32 %t)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %m3 = call i32 @cq_measure_si32(i32 %rm)
  %s1 = add nsw i32 %m1, %m2
  %s2 = add nsw i32 %s1, %m3
  ret i32 %s2
}

; the two forward chain links, BEFORE the region
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 7)
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Y]], i32 2)
; the region, collapsed to ONE controlled gate on %[[R]]
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the live consumer
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Z]], i32 3)
; ⚠ THE FOUR LINES THIS FILE EXISTS FOR: the dead chain is reversed LIFO and both
; rails are freed, and the `%[[Y]]` adjoint READS %[[R]] — the register the region
; just rotated — because a controlled Rz moved no basis label.
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[Z]], i32 %[[Y]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[Y]], i32 %[[R]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[Y]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; the merge phi was RAUW'd to the base, so the third measure reads the register
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; the two source wires carry superposition and are correctly LEFT ALLOCATED
; (Rule 6): no free may follow the chain's two
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @dead_chain_across_region(
; (No `cqrt_alloc_i32(i32 0)` assertion here, deliberately: BOTH source registers
; are minted with seed 0 in this module, so the route's work rail would be
; indistinguishable from them by that pattern. The cswap is the unambiguous one.)
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: phi i32
