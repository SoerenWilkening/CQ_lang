; control_swap_select_qqcond_ugt.ll — ACCEPT (bd `gowy`): the direct UNSIGNED
; sibling of control_swap_select_qqcond.ll. Same Phase-4.4 shape — a
; tainted-condition integer-data `select` whose condition is a Q+Q compare (BOTH
; operands theta handles) — lowered by the controlled-XOR copy merge. The delta
; is the PREDICATE: `ugt`, not `sgt`.
;
; WHY THIS FIXTURE EXISTS. Commit dbab515 (tkju) DELETED NO FILES — its
; name-status histogram is 75 `M` + 1 `A` + 0 `D`, and tests/e2e/*.c stands at
; 249 both at dbab515^ and at HEAD. What it did was DE-VENDOR 52 e2e slices IN
; PLACE (stripping the fictional SOFTWARE bodies they had vendored for Rule-18
; HARDWARE keeps) and REGENERATE their goldens. The slices all still exist; it
; is the `cq_template_*` trace LINES that vanished from the regenerated
; `.expected.log` files, and for the QQ `ugt` compare pair those lines were the
; only witness anywhere. Concretely, at dbab515^ the bare
; `cq_template_icmp_ugt_i32` and its `_inv` twin appeared in exactly three
; goldens — slice_libm_real_coshl.expected.log (28 bare, 0 `_inv`),
; slice_libm_real_llroundl.expected.log and slice_libm_real_lroundl.expected.log
; (10 bare + 10 `_inv` each) — all three merely MODIFIED by dbab515, all three
; still present at HEAD, all three now carrying zero QQ `ugt` lines. So the pair
; survives in the generated runtime/cq_templates.c with NO witness: not an e2e
; golden, not a lit fixture. (The `_hl` twins are untouched — 58 goldens at
; HEAD, incl. slice_libm_real_nextafter/lgamma; the QQ pair had no such luck.)
; The pre-dbab515 trace is still readable if a future archaeologist wants it:
; `git show dbab515^:tests/e2e/slice_libm_real_lroundl.expected.log`. This
; fixture restores the witness cheaply, at the ir-pass layer.
; No accept-predicate is added here, so per Rule 12 a positive fixture suffices —
; the `ugt` decline surface is already covered by the shared select reject family.
;
; THE PHYSICS FACT BEING PINNED — signedness is carried by the SYMBOL, and the
; mint and the strip must agree on it. Rule 15 strips signedness from the handle
; WIDTH (a handle is always i32) but never from the OPCODE: `ugt` and `sgt` are
; different comparator circuits (no sign-bit handling vs. sign-bit handling), so
; they disagree on exactly the operand pairs that straddle the sign boundary. The
; flag rail is returned to |0> by RECOMPUTING the compare and XOR-cancelling it —
; therefore the strip must recompute the SAME predicate over the SAME two rails
; in the SAME slot order. A predicate that normalized `ugt`→`sgt` on either side,
; or a strip whose operands drifted, leaves the flag rail holding
; `(q >u y) XOR (q >s y)` — non-zero on the straddling inputs, entangled with the
; data rails — and the following `cqrt_free` then stops being a lifetime op and
; becomes a HIDDEN MEASUREMENT that collapses `q` (Rule 6). That failure is
; invisible to `opt -verify` and invisible to a golden that only greps symbol
; names, which is why the CHECK lines below bind %[[HQ]]/%[[HY]] at the alloc and
; re-use those SAME capture vars in the `_inv` line: identity, not presence.
;
; THE SIX-STEP MERGE, in emission order:
;   1. QQ flag mint      cq_template_icmp_ugt_i32(h_q, h_y)  — the 7.1 Q+Q data
;      compare template (frozen; `_inv`/`_unc` twins exist; NO new symbol).
;   2. out rail          cqrt_alloc_i32(0) — the literal 0 is what makes the
;      destination provably |0>, so the two XOR-copies compose to a clean mux.
;   3. true-arm copy     cqrt_copy_i32_controlled(flag, h_q, out).
;   4. cqrt_x(flag)      self-inverse polarity bracket OPEN — control on ¬flag.
;   5. false-arm copy    the CLASSICAL operand %x is materialized on its own rail
;      (copy_controlled takes handles) and copied under ¬flag; then cqrt_x CLOSES
;      the bracket, so the net effect on the flag rail is identity and it again
;      holds the compare value at step 6. out = flag·q XOR ¬flag·x, which is the
;      select, computed with zero measurement (Rule 5).
;   6. `_inv` strip + cqrt_free(flag) — the proven-|0> free.
;
; NOTE the adjoint here IS the fresh-minting `_inv`, NOT the void `_unc`. This is
; the 4.4 control-flag STRIP — a region-local, immediate undo of one compare the
; emitter itself minted — not whole-DAG LIFO uncomputation, which is the spine
; that owns the void `_unc` ABI. So, unlike the lowering_uncompute_* fixtures,
; this file deliberately carries NO CHECK-NOT against `_inv`: `_inv` is the
; correct adjoint at this site. It does guard the two ways the symbol could go
; wrong — a predicate normalized to `sgt`, or the Q+Q shape degrading to `_hl`.
;
; Rails: this emitter emits exactly ONE `cqrt_free` — the flag rail, after the
; strip. FIVE rails are therefore never freed, and this enumeration is meant to
; be exhaustive. One of the five, %out, is not a leak at all: it is MEASURED, and
; Rule 6 forbids freeing a Measured handle — the measurement owns it. The other
; four are %h, %h2, %selop, and the fresh handle the strip itself mints (%h_cmp1
; in the emitted IR — the `_inv` ABI RETURNS a new handle;
; runtime/cq_templates.c:8141 does `cqrt_alloc_handle()` and returns it). Those
; four are accepted leaks in the qubits-not-scarce regime (Rule 6), never freed
; dirty; the identical five appear in the tracked sibling
; control_swap_select_qqcond.ll, so this is the 4.4 strip ABI's standing
; behaviour, not a defect of this shape. Why none of the four is freed:
; an additive XOR-copy PRESERVES its source, so %h/%h2/%selop are still holding
; live values, and %h/%h2 are moreover entangled with %out (out = f·q XOR ¬f·x
; depends on both q and y) — freeing either would be exactly the hidden
; measurement of Rule 6. Note also that un-rotating a theta ROOT would not reach
; |0> in the first place: `cqrt_alloc_i32(v)` seeds the alloc-time CLASSICAL
; BASIS STATE |v>, so `Ry(-theta)` on %h restores |u0>, not |0>; a root free is
; licensed by "provably disentangled and in a known classical state", which is a
; DIFFERENT proof from the flag rail's. The flag rail is the only one here that
; genuinely reaches |0>, and it does so by XOR-cancellation, which is why it is
; the only free. The strip reads %h/%h2 while both are still LIVE — no adjoint
; here touches a freed rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp ugt i32 %q, %y                ; Q+Q condition, UNSIGNED predicate
  %sel = select i1 %c, i32 %q, i32 %x       ; tainted true arm, classical false arm
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; The CHECK chain is CHECK-NEXT from the opening brace to the `ret` — the WHOLE
; body, with no unpinned gap at either end — because a stray gate slipped in
; anywhere is itself the miscompile this fixture exists to catch. Two ends were
; empirically open before this discipline was closed, and both mutants are now
; rejected: (i) a compiler-inserted `cqrt_measure_i32` emitted AHEAD of the first
; alloc (Rule 5 — the compiler never emits a measurement the user did not write)
; slipped past a plain leading positive directive, which simply scanned forward
; over it; (ii) a `cqrt_x(%out)` emitted AFTER the measurement (a post-measure
; gate on the measured rail) slipped past the trailing region, which the negative
; directives do not reach because they only name specific symbols. Anchoring on
; CHECK-LABEL closes (i); pinning `ret` to the measured value closes (ii).
; (Prose here deliberately never writes a directive keyword followed by a colon —
; FileCheck would parse it out of the comment as a real directive.)
; Both theta roots become allocated+rotated rails.
; CHECK-LABEL: define i32 @example(
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ]], double 5.000000e-01)
; CHECK-NEXT: %[[HY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HY]], double 2.500000e-01)
; Step 1 — QQ mint: both slots are handles (no `_hl`), predicate `ugt`.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i32(i32 %[[HQ]], i32 %[[HY]])
; Steps 2-5 — |0> out rail, then the ¬flag-bracketed two-copy XOR merge.
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[HQ]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[XS:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[XS]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; Step 6 — the strip recomputes the SAME predicate over the SAME still-live rails
; in the SAME slot order as the mint, then the flag rail is a proven-|0> free.
; CHECK-NEXT: call void @cq_template_icmp_ugt_i32_unc(i32 %[[F]], i32 %[[HQ]], i32 %[[HY]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; The measurement reads the merged out rail — the only measurement in the module,
; and the user wrote it (Rule 5). `ret` is pinned to that measurement's result so
; nothing can be emitted between the measure and the return: a gate on %out after
; it has been measured would be operating on a collapsed rail.
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: ret i32 %[[M]]
;
; The intrinsic is gone; the Q+Q compare did NOT degrade to the handle+literal
; shape, and the unsigned predicate was NOT normalized to signed. These reach the
; trailing declare block, which is where a wrongly-minted symbol would surface.
; CHECK-NOT: cq_template_icmp_ugt_i32_hl
; CHECK-NOT: cq_template_icmp_sgt
; CHECK-NOT: cq_theta_si32
