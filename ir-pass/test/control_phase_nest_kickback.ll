; control_phase_nest_kickback.ll — ACCEPT. P4, THE GENUINE DEPTH-2 NEST (bd
; test_C_libtooling-3qlq Inc 1 part B, PRD `retire-swap-route-PRD.md` §6.2 row P4).
;
;     if (q > 5) { cq_phi(0.25); if (q < 9) { cq_phi(0.75); } }
;
; The nest is GENUINE because the outer arm holds an opaque `call void @cq_phi`,
; which SimplifyCFG cannot speculate — so the two levels survive `clang -O1`
; instead of folding into one compound branch (which is P3, and which the
; measured `if(a){if(b)X;}` with an EMPTY outer arm does fold to). MEASURED at
; part A's HEAD this exact module declined `control flow` at the OUTER branch:
; the merge carries NO φ, so `recoverRegion` labels it `OffPattern`.
;
; THE LOWERING IS BOOLEAN ALGEBRA, NOT A ROUTE, and that is the increment. The
; outer arm's phases ride `f1`; the inner arm's ride `g = f1 ∧ f2`, ONE
; `cqrt_toffoli` onto a fresh |0> ancilla — the SAME conjunction node the 4.4
; select network and P3 use (`CondTreeEmit`, Rule 14). Compare the 4.3 swap route
; this REPLACES, and which is deleted with this increment: two `cqrt_alloc_i32`
; work rails, FOUR `cqrt_cswap`, an inner flag minted FROM rail1, and a TENSORED
; `cqrt_rz_i32` that could never mark |0..0> (PRD §1).
;
; WHY THE INNER FLAG CAN BE MINTED AT THE OUTER BRANCH — the fact the whole
; region rests on: under D1/D2 NO gate here touches a register (`cq_phi` is
; `void(double)`), so the inner compare reads exactly the registers it reads in
; the source, and `Mid` defines nothing but void calls and the condition tree, so
; every inner leaf operand dominates the outer branch. The 4.3 route had to mint
; from rail1 precisely because its arm gate DID carry a register.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cqrt_x(i32

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(


declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE EMITTED STREAM, DERIVED FROM THE PASS OUTPUT (never typed: the Inc-4
; round-1 review found 9 of 20 fixtures naming an SSA value the pass never
; produced). Ordered CHECK-NEXT, so a gate inserted anywhere in the run fails.
; CHECK:      %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V2]], double 2.500000e-01)
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[V0]], i32 9)
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V4]], double 7.500000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V2]], i32 %[[V3]], i32 %[[V4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[V3]], i32 %[[V0]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[V2]], i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so counts live in their own prefixes and NOROUTE carries no positives). The
; four things a register-free kickback must NEVER emit: a route of any kind, a
; `_controlled` gate, a `cqrt_rz_<W>` for W != i1 (the TENSORED per-register Rz
; PRD §1 records as the defect), and a surviving `@cq_phi` call.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_

; ---------------------------------------------------------------------------
; THE BRANCH-PHASE RECORD, COUNTED — bd 3qlq Inc 1 part A, Rule-13 round-1
; finding F-L7-1, re-asked at THIS increment's OWN emission site (P4).
;
; EVERY `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`. Without the
; record, `ChainWalk::isInPlaceGateOn` reads the gate as an ordinary in-place
; rotation on a reclaimable rail, it joins `D.Calls`, and the whole-DAG
; uncompute spine emits `cqrt_rz_i1(f, -theta)` — which cancels the user's phase
; EXACTLY, because both gates are diagonal in the same basis label. That is a
; CONFIRMED miscompile three round-1 lenses found independently, at `opt`
; exit 0, verify-clean and STRICT-stage-2b-clean.
;
; Here the gates ride the OUTER root flag AND the conjunction ancilla, which part A's
; emitter never mints — so this is a NEW emission site and the record had to be
; added to it at the merge rather than inherited. The two counts below are
; asserted SEPARATELY and must AGREE: 2 gates, 2 carrying the metadata. A
; future emitter that mints a gate and forgets the call moves the first count
; and not the second, and this file goes red.
; MDCNT-COUNT-2: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-2: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
