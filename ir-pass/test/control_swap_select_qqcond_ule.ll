; control_swap_select_qqcond_ule.ll — ACCEPT (bd `gowy`): the NON-STRICT unsigned
; sibling of control_swap_select_qqcond.ll (`sgt`) and control_swap_select_qqcond_ugt.ll
; (`ugt`). Same Phase-4.4 shape — a tainted-condition integer-data `select` whose
; condition is a Q+Q compare (BOTH operands are theta handles) — lowered by the
; controlled-XOR copy merge. The delta is the PREDICATE: `ule`.
;
; WHY THIS FIXTURE EXISTS. Commit dbab515 (tkju) DE-VENDORED 52 e2e slices IN
; PLACE: it stripped the fictional SOFTWARE bodies they had vendored for Rule-18
; HARDWARE keeps and REGENERATED their goldens. It DELETED NOTHING — `git show
; --name-status --format='' dbab515` is 1 `A` + 75 `M` and ZERO `D`, and
; tests/e2e/*.c is 249 files both before and after. Every slice is still on disk.
; What vanished were the TRACE LINES: with the software bodies gone, the
; regenerated .expected.log files no longer exercise the `cq_template_*` symbols
; those bodies used to reach, leaving several alive in the generated
; runtime/cq_templates.c with no witness anywhere in the tree.
; `cq_template_icmp_ule_i32_inv` is one of them. Its two witnesses were
; tests/e2e/slice_libm_real_lroundl.expected.log and
; tests/e2e/slice_libm_real_llroundl.expected.log — both listed `M` in dbab515,
; both still present at HEAD, and both went 16 occurrences -> 0 across it (verify
; with `git show dbab515^:<f> | grep -c`). After that, `git grep -I
; cq_template_icmp_ule_i32_inv HEAD` outside runtime/cq_templates.{c,h} returned
; nothing. Do NOT go looking for removed files: the loss was regeneration, not
; deletion.
;
; The loss is easy to overlook because the QQ `ule` pair looks covered: the forward
; mint `cq_template_icmp_ule_i32` and the void adjoint `..._unc` are both pinned by
; lowering_uncompute_compare_icmp_ule_qq.ll. But that fixture names the `_inv` twin
; only in a CHECK-NOT — it witnesses the symbol as an ABSENCE (the whole-DAG spine
; must NOT fresh-mint), never as an EMISSION. Nothing in the repo asserted that the
; `_inv` is emitted where it genuinely belongs. This fixture supplies that half. No
; accept-predicate is added here, so per Rule 12 a positive fixture suffices; the
; `ule` decline surface rides the shared select reject family.
;
; NOTE the adjoint at this site IS the fresh-minting `_inv`, NOT the void `_unc`.
; This is the 4.4 control-flag STRIP — a region-local, immediate undo of one compare
; the merge emitter itself minted — not whole-DAG LIFO uncomputation, which is the
; spine that owns the void `_unc` ABI. So, unlike the lowering_uncompute_* fixtures,
; this file deliberately carries NO CHECK-NOT against `_inv`: here `_inv` is the
; correct adjoint, and `_unc` would be the bug.
;
; PHYSICS FACT 1 — NON-STRICTNESS IS PART OF THE UNITARY, AND IT HIDES ON THE
; DIAGONAL. The flag rail is returned to |0> by RECOMPUTING the compare and
; XOR-cancelling it, so mint and strip must agree on the predicate exactly. If
; either side normalized the non-strict `ule` to the strict `ult`, the residue left
; on the flag rail is
;       (q <=u y) XOR (q <u y)  =  (q == y)
; — non-zero on precisely the equal-operand subspace and nowhere else. Both operands
; are Ry-rotated theta rails, so that subspace carries real amplitude, but it is a
; single diagonal: a spot-check, a hand-traced example, or a random-probe test walks
; past it almost every time. The following `cqrt_free` then stops being a lifetime op
; and becomes a HIDDEN MEASUREMENT that collapses `q` (Rule 6). This is the
; verify-clean silent-miscompile class in its purest form — `opt -verify` is clean,
; the trace is plausible, and the wrongness is confined to a measure-thin slice of
; the input space. Slot order is load-bearing for the same reason: `ule` is not
; commutative, and swapping the two rails turns `q <=u y` into `uge`, leaving the
; complementary residue `(q != y)` — wrong nearly EVERYWHERE.
;
; PHYSICS FACT 2 — `ule` IS THE COMPLEMENT OF `ugt`, AND THE EMITTER ALREADY OWNS A
; NEGATION. Steps 4 and 6 below bracket the false-arm copy with a self-inverse
; `cqrt_x` on the flag rail, so between those two calls the rail literally holds
; `ugt`. That makes an off-by-one-negation — minting the complement predicate, or
; dropping/adding a bracket — a defect that SWAPS THE TWO ARMS of the select while
; leaving every structural invariant intact: the bracket is still self-inverse, the
; strip still cancels, the flag rail is still provably |0>, and tools/free_pairing_
; check.py is still perfectly happy. Nothing but the DATA is wrong. That is why the
; CHECK lines below are CHECK-NEXT and bind %[[HQ]]/%[[HY]]/%[[F]]/%[[OUT]] once and
; re-use those SAME capture vars downstream: this fixture pins handle IDENTITY and
; emission ORDER, not symbol presence, because presence is exactly what survives the
; bug.
;
; THE SIX-STEP MERGE, in emission order. This numbering is FIXTURE-LOCAL (it splits
; the emitted lines one per step) and does NOT line up with the numbered steps in
; ir-pass/src/SelectMergeEmit.cpp, which groups differently: emitter step 4 (:236)
; is the whole X-bracketed false-arm copy — BOTH cqrt_x calls plus the copy — so it
; covers fixture steps 4-5; emitter step 5 (:245) is the STRIP alone; emitter step 6
; (:272) is the REWIRE (RAUW %sel -> %out), which emits nothing and so appears in no
; CHECK line here. When cross-referencing, translate; do not match step numbers.
;   1. QQ flag mint   cq_template_icmp_ule_i32(h_q, h_y) — the 7.1 Q+Q data-compare
;      template (frozen; `_inv`/`_unc` twins exist; NO new symbol). Both slots are
;      handles, so no `_hl` degradation.
;   2. out rail       cqrt_alloc_i32(0) — the literal 0 is what makes the destination
;      provably |0>, so the two XOR-copies compose into a clean mux.
;   3. true-arm copy  cqrt_copy_i32_controlled(flag, h_q, out) — the TRUE arm goes
;      first, under the un-negated flag.
;   4. cqrt_x(flag)   polarity bracket OPEN — the next copy is controlled on ¬flag.
;   5. false-arm copy the classical operand %x is materialized on its own rail
;      (copy_controlled takes handles, never literals) and copied under ¬flag; the
;      second cqrt_x CLOSES the bracket, so the net effect on the flag rail is
;      identity and it again holds (q <=u y) at step 6. Net:
;      out = flag·q XOR ¬flag·x — the select, with zero inserted measurement (Rule 5).
;   6. `_inv` strip over the SAME predicate, SAME rails, SAME slot order as the mint,
;      then cqrt_free(flag) — the proven-|0> free.
;
; RAILS. %h/%h2/%selop — and %h_cmp1, the `_inv`'s own fresh result handle (below) —
; are NOT freed. Note what `cqrt_alloc_<W>(d)` actually does: it initialises the rail
; to the CLASSICAL BASIS STATE |d>, not unconditionally to |0>. That is why step 2's
; literal 0 matters (|0> is what makes the two XOR-copies compose into a clean mux)
; and why %h/%h2 are not |0> even before their Ry: they start at |u0>/|v0> and the Ry
; then superposes them. An additive controlled-XOR copy PRESERVES its source, so none
; of these rails is provably |0> at the end; per Rule 6 they are left allocated (an
; accepted leak in the qubits-not-scarce regime) rather than freed dirty, which on
; %h/%h2 would be a hidden measurement of a superposed rail (Rule 8). Only the flag
; rail is freed, and only after the strip. The strip reads %h and %h2 while BOTH are
; still LIVE — no adjoint in this region touches a freed rail.
;
; THE `_inv` IMPLICIT-RAIL WART — why adjacency is the only thing that pins the
; pairing. The emitted strip is `%h_cmp1 = call i32 @cq_template_icmp_ule_i32_inv(i32
; %h, i32 %h2)`: it NEVER NAMES %h_cmp, the rail it restores. The `_inv` ABI takes
; only the forward operands and returns a FRESH handle (runtime/cq_templates.c:8369
; calls cqrt_alloc_handle()), unlike the Phase-5 void `_unc` ABI, which does take the
; rail explicitly. That wart is documented at tools/free_pairing_check.py:25-31, where
; fixing it is called FROZEN-ABI adjacent and deferred; it is why that checker has to
; INFER the strip/free pairing. So do NOT read the strip as unpaired. What pins it
; here is (a) CHECK-NEXT adjacency — the strip is immediately followed by the free,
; with nothing in between that could re-dirty the rail — and (b) the free's TARGET
; being the bound capture %[[F]], i.e. the very rail the mint produced.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp ule i32 %q, %y                ; Q+Q condition, UNSIGNED NON-STRICT
  %sel = select i1 %c, i32 %q, i32 %x       ; tainted true arm, classical false arm
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; Both theta roots become allocated+rotated rails. CHECK-NEXT throughout: a stray
; gate slipped between the mint, the bracket and the strip is itself a miscompile
; this fixture exists to catch (a non-diagonal gate on %h between mint and strip
; would make the strip recompute a DIFFERENT value than the one on the flag rail).
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ]], double 5.000000e-01)
; CHECK-NEXT: %[[HY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HY]], double 2.500000e-01)
; Step 1 — QQ mint: predicate `ule`, %h_q in slot 0 and %h_y in slot 1, matching the
; source `icmp ule i32 %q, %y`. A swap here silently means `uge`.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ule_i32(i32 %[[HQ]], i32 %[[HY]])
; Steps 2-5 — the |0> out rail, then the true-arm copy FIRST, then the ¬flag-bracketed
; false-arm copy. Arm order is the data, and only this ordering pins it.
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[HQ]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[XS:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[XS]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; Step 6 — THE WITNESS. The strip recomputes the SAME non-strict unsigned predicate
; over the SAME still-live rails in the SAME slot order as the mint; only then is the
; flag rail provably |0> and eligible for cqrt_free.
; CHECK-NEXT: call void @cq_template_icmp_ule_i32_unc(i32 %[[F]], i32 %[[HQ]], i32 %[[HY]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; The measurement reads the merged out rail — the only measurement in the module, and
; the user wrote it (Rule 5).
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT]])
; Pinning the terminator closes the RAILS paragraph's Rule-6/Rule-8 claim, which was
; PROSE-ONLY until this line existed: without it the CHECK-NEXT chain ends at the
; measure, so `cqrt_free(%h)` / `cqrt_free(%h2)` injected between the measure and the
; `ret` — two dirty frees of Ry-superposed rails, i.e. exactly the hidden-measurement
; collapse the header warns about — PASSED this fixture (empirically confirmed). With
; the `ret` pinned, the function body is CHECK-NEXT-contiguous end to end and nothing
; can be inserted anywhere in it. tools/free_pairing_check.py DOES catch that mutant,
; but it is an e2e stage-2b gate and never runs on ir-pass lit fixtures.
; CHECK-NEXT: ret i32
;
; The intrinsic is gone; the Q+Q compare did NOT degrade to the handle+literal shape;
; the unsigned predicate was NOT normalized to signed; and the NON-STRICT predicate
; was NOT tightened to the strict one. Each of these would surface in the trailing
; declare block, which this CHECK-NOT region covers.
; CHECK-NOT: cq_template_icmp_ule_i32_hl
; CHECK-NOT: cq_template_icmp_sle
; CHECK-NOT: cq_template_icmp_ult
; CHECK-NOT: cq_theta_
; And no free anywhere past the pinned body — e.g. cleanup relocated into a new block
; after the `ret`, which the CHECK-NEXT chain above would not see. The `call void @`
; prefix is REQUIRED: a bare `cqrt_free` would false-fail on `declare void
; @cqrt_free(i32)`, which legitimately appears in the trailing declare block.
; CHECK-NOT: call void @cqrt_free
