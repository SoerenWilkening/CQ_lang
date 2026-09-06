; control_phase_kickback_and2.ll — ACCEPT. P3, THE FLAGSHIP COMPOUND SHAPE (bd
; test_C_libtooling-3qlq Inc 1 part B, PRD `retire-swap-route-PRD.md` §6.2 row P3).
;
;     if (q == 5 && r == 3) cq_phi(0.3);
;
; The condition is a LOGICAL `select i1 %ca, i1 %cb, i1 false` and not an
; `and i1`, and that is MEASURED rather than stylistic: it is what `clang -O1`
; emits for C's short-circuit `&&` at LLVM 19, because InstCombine deliberately
; does NOT fold the logical form to `and` (the un-taken side's poison must not
; propagate). Before part B this exact program declined
; `branch phase on a bare i1 condition` — the condition is not a `CmpInst`.
;
; THE LOWERING IS THE 4.4 SELECT'S CONDITION NETWORK, SHARED (Rule 14): one flag
; rail per compare LEAF, one |0> ancilla per tree NODE, `cqrt_rz_i1` on the ROOT
; ancilla, then an EXACT-LIFO strip — the node's own self-inverse toffoli and its
; free FIRST (while both children's rails are still allocated), then each leaf's
; `_unc` and free in reverse mint order. The kickback argument of PRD §3 does not
; care how the flag was computed, only that the ancilla is returned to |0> on
; every branch, which the LIFO strip does.
;
; ⚠ THIS FIXTURE ALSO COVERS THE FOLDED NEST, AND DELIBERATELY WITHOUT A SECOND
; FILE. `if (q == 5) { if (r == 3) cq_phi(0.3); }` compiles to a `@slice` body
; that is BYTE-IDENTICAL to `&&`'s at `clang -O1` — measured, `diff` empty, both
; the source `.c` files and the two lowered IRs are in the increment's probe
; directory. A separate `.ll` here would be the SAME BYTES under a second name,
; i.e. a false coverage claim (the Inc-4 "DER lesson"), so the row is recorded in
; this header instead. The e2e layer is where the two SOURCES are distinguished
; (`slice_control_phase_andcond.c` vs `slice_control_phase_nest.c`, whose goldens
; must match byte for byte).
; ⚠ NOT IN THIS TREE YET: the e2e slices for the register-free surface live on branch
; `3qlq-inc1-slices` (prep-b) and are merged before this epic's commit. MEASURED at this
; HEAD, 63 of the 66 `tests/e2e/*.c` that call `cq_phi` FAIL STAGE 1 against the
; register-free `CQ.h`, so `ir-pass-lit` is this branch's ONLY gate and every e2e claim
; below is a statement about that other branch (Rule-13 round-2 finding F-R2-4).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C3 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C4 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C5 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll


; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

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

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ca = icmp eq i32 %q, 5
  %cb = icmp eq i32 %r, 3
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}

; THE NETWORK, IN ORDER. Two leaf mints, ONE |0> conjunction ancilla, the phase
; on the ancilla, then the LIFO undo — the node's toffoli + free BEFORE either
; leaf strip, which is the load-bearing order (the undo READS both leaf rails).
; CHECK:      %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: %[[FB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[R:[a-zA-Z0-9_.]+]], i32 3)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FB]], i32 %[[R]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FB]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FA]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FA]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so every count lives in its own prefix and NOROUTE carries no positives).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; The condition tree itself must be GONE — a dead tainted compare left standing
; becomes a spurious template plus a leaked flag rail in `lowerOps`.
; NOROUTE-NOT: select i1
; NOROUTE-NOT: icmp eq i32

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above). An AND node
; is ONE toffoli and NO cnot; getting that wrong (emitting OR's network) computes
; a different predicate and still verifies, still pairs every free and still
; prints a plausible trace — bd 3c6m.67's verify-clean silent miscompile.
; C1-COUNT-1: call void @cqrt_rz_i1(
; C1-NOT:     call void @cqrt_rz_i1(
; C2-COUNT-2: call void @cqrt_toffoli(
; C2-NOT:     call void @cqrt_toffoli(
; C3-COUNT-3: call void @cqrt_free(
; C3-NOT:     call void @cqrt_free(
; C4-COUNT-1: call i32 @cqrt_alloc_i1(
; C4-NOT:     call i32 @cqrt_alloc_i1(
; C5-NOT: cqrt_cnot

; ---------------------------------------------------------------------------
; THE BRANCH-PHASE RECORD, COUNTED — bd 3qlq Inc 1 part A, Rule-13 round-1
; finding F-L7-1, re-asked at THIS increment's OWN emission site (P3).
;
; EVERY `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`. Without the
; record, `ChainWalk::isInPlaceGateOn` reads the gate as an ordinary in-place
; rotation on a reclaimable rail, it joins `D.Calls`, and the whole-DAG
; uncompute spine emits `cqrt_rz_i1(f, -theta)` — which cancels the user's phase
; EXACTLY, because both gates are diagonal in the same basis label. That is a
; CONFIRMED miscompile three round-1 lenses found independently, at `opt`
; exit 0, verify-clean and STRICT-stage-2b-clean.
;
; Here the gates ride the COMPOUND-condition root ancilla, which part A's
; emitter never mints — so this is a NEW emission site and the record had to be
; added to it at the merge rather than inherited. The two counts below are
; asserted SEPARATELY and must AGREE: 1 gates, 1 carrying the metadata. A
; future emitter that mints a gate and forgets the call moves the first count
; and not the second, and this file goes red.
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(
