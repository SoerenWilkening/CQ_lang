; loop_condtree_select_accept_hoisted_data_rotated.ll — ACCEPT (bd
; test_C_libtooling-xdu2.16). It is ROLLED-ONLY against its C-level hand-unrolled
; twin and it IS WITNESSED by an IR-level twin (see "THE TWIN" below): read this
; header before reading the verdict.
; ⚠ An earlier version of this line called it "the ONE measured ROLLED-ONLY cell
; of the increment". That understated it: xdu2.16's Rule-13 rounds found at least
; four flat-decline causes and ~50 rolled-only cell-forms (r1B F-B1-2, bd
; `test_C_libtooling-xdu2.23`; r1A F-A1-2, bd `test_C_libtooling-xdu2.22`), all
; flat OVER-declines in the safe direction; see TRACK_XDU2_16.md §7.
;
; `for (i < n) { int t = ((q > 1) & (r < 5)) ? i : 55; t = cq_theta(t, 0.7);
;  s += cq_measure(t); }` — the select's OUTPUT is rotated by a NON-DIAGONAL gate
; and measured, every trip. The tree is LICM-hoisted, so on the pre-change ORACLE
; `438c77bf45c02e3e` this declined at the xdu2.16 wall (`round-1 iteration-local
; marking falsified by round-2 taint`); after the change it ACCEPTS.
;
; ⚠ ITS HAND-UNROLLED TWIN DECLINES, ON BOTH BINARIES, AND THAT IS A PRE-EXISTING
; FLAT OVER-DECLINE, NOT A HAZARD THE ROLLED FORM ESCAPES. Measured with CQ_CTRL_DBG:
; the flat form's second select declines `condition predates a non-diagonal gate`
; at `SelectClassify`'s POSITIONAL prong (c) — `-O1` CSEs the three trees into ONE
; `and` in the entry block, so the first copy's `cq_theta(t, 0.7)` sits between the
; shared compare leaves and the second select IN THE SAME BLOCK, and prong (c)
; refuses any tainted-operand `cq_theta` in that window "even on another wire (over-
; decline is safe)" — its own words. In the rolled form the leaves are in the
; preheader, a different block from the select, so prong (c) does not apply, and
; the POSITION-FREE walk (prong (a), `findNonDiagonalWireGate` over the leaves'
; provenance) — the question prong (c) is a conservative same-block shortcut for —
; finds NO non-diagonal gate on `q`'s or `r`'s wire, correctly: the rotated
; register is the select's fresh `%out`, disjoint from both.
;
; WHY THE ROLLED CIRCUIT IS RIGHT, gate by gate (per trip): both leaf flags are
; minted from `h`/`h2` and the toffoli node on a fresh ancilla; the two X-bracketed
; controlled copies write a FRESH `%out` from two CLASSICAL source rails (`i`,
; `55` — basis states, unchanged by being copy sources, so never entangled); the
; toffoli is undone, the ancilla freed, both compares `_unc`'d and freed. ONLY THEN
; `cqrt_ry_i32(%out, 0.7)` and the measure. At the rotation the only live rails
; entangled with `%out` are `h`/`h2` themselves — exactly the dependence the source
; program denotes — and no which-path record of the condition survives the trip
; (the G-13 hazard is a LEFTOVER rail entangled with the rotated register; there is
; none). Stage 2b STRICT `3 verified, 0 violation(s), 0 unproven`.
; ⚠ It emits ONE `cq rotation lowering: non-diagonal gate over a live derived
; record` WARNING (the bd `lyyf` warning class — a SIGNAL, not coverage), and so
; does the loop-free single-select spelling of the same statements on the ORACLE
; (measured, 2 warnings: `slice` and its inlined copy in `main`), so the warning
; is not new to this increment. Which record it counts was NOT traced here; the
; physics argument above does not rest on it.
;
; THE TWIN (xdu2.16 Rule-13 r1B F-B1-1). The C-level twin is not the only flat
; form. r1B's recipe (`review_r1B_xdu2_16/probes/unrl/twin_ir.sh`): make the trip
; constant (3), rewrite `llvm.loop.unroll.disable` to `llvm.loop.unroll.full` in
; the ROLLED stage-1 IR, and run ONLY `opt -passes='loop-unroll<O3>'` — no other
; `-O1` re-canonicalisation, so no cross-copy CSE and prong (c) never fires. Rolled
; vs that IR twin: BYTE-IDENTICAL on 15/15 `rot` cells (r1B), and the pre-change
; ORACLE lowers the IR twin to the SAME stream on 15/15. Re-measured by the
; implementer on `i32_and_rot_for` (this fixture's shape at K=3): 63 = 63 trace
; lines, identical, and ORACLE-on-twin == SUBJECT-rolled byte for byte (the ORACLE
; still declines the rolled form at the xdu2.16 wall). ⚠ The diagnostics are not
; symmetric: the flat twin prints the `lyyf` warning once PER TRIP (3), the rolled
; form once — a warning count, not a stream difference.
; So the old retirement trigger ("when the flat twin accepts") is MET by the IR
; twin. What stays open is the C-level twin: bd `test_C_libtooling-xdu2.19` (prong
; (c)'s cross-wire refusal); bd `test_C_libtooling-xdu2.20` carries the recipe as
; a mechanism for the twin matrix. RETIREMENT TRIGGER (re-armed): when the C-level
; flat twin accepts, add this pair to a `*-twin-identical` gate; do not delete this
; file.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
;
; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[H2:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK:      body:
; CHECK:      %[[F1:h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[F2:h_cmp[0-9]*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H2]], i32 5)
; CHECK-NEXT: %[[G:g[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: %[[OUT:out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[T:selop[0-9]*]] = call i32 @cqrt_alloc_i32(i32 %i)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: %[[E:selop[0-9]*]] = call i32 @cqrt_alloc_i32(i32 55)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[H2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[OUT]], double 0x3FE6666666666666)
; CHECK-NEXT: %{{[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[OUT]])
;
; NEG-NOT: and i1
; NEG-NOT: select i1
; NEG-NOT: cqrt_free(i32 %h{{[0-9]*}})
; NEG-NOT: cqrt_free(i32 %out
; ERR-NOT: cq loop lowering
; ERR-NOT: error

define i32 @slice(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit

ph:
  %c1 = icmp sgt i32 %q, 1
  %c2 = icmp slt i32 %r, 5
  %c = and i1 %c1, %c2
  br label %body

exit:
  %s.lcssa = phi i32 [ 0, %entry ], [ %s.next, %body ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s0 = add i32 %mq, %s.lcssa
  %s1 = add i32 %s0, %mr
  ret i32 %s1

body:
  %s = phi i32 [ 0, %ph ], [ %s.next, %body ]
  %i = phi i32 [ 0, %ph ], [ %i.next, %body ]
  %t = select i1 %c, i32 %i, i32 55
  %t2 = call i32 @cq_theta_si32(i32 %t, double 0x3FE6666666666666)
  %mt = call i32 @cq_measure_si32(i32 %t2)
  %s.next = add nsw i32 %mt, %s
  %i.next = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %body
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
