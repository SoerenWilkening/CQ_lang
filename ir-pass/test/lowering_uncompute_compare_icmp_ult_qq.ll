; lowering_uncompute_compare_icmp_ult_qq.ll — witness restoration for the bare
; Q+Q (BOTH operands tainted) UNSIGNED-less-than data-position compare and its
; void uncompute twin (bd `gowy`).
;
; WHY THIS FILE EXISTS. Commit dbab515 (`tkju`) DELETED NO FILES. It de-vendored
; 52 e2e slices IN PLACE: it stripped the fictional openlibm SOFTWARE bodies
; those .c files had vendored for Rule-18 HARDWARE keeps, and regenerated their
; goldens. Every slice still exists — verify, do not trust this comment (Rule 11):
;
;   $ git show --name-status --format='' dbab515 | awk 'NF{print $1}' | sort | uniq -c
;         1 A
;        75 M          <-- ZERO 'D'
;   tests/e2e/*.c: 249 at dbab515^, 249 at dbab515.
;
; What disappeared was not slices but TRACE LINES. Those vendored bit-twiddle
; ladders were the only code in the tree that ever emitted a set of
; `cq_template_*` symbols, so once the bodies went, the regenerated
; `.expected.log` files stopped containing them. For the pair pinned here the
; loss is exact and measurable: at dbab515^, `cq_template_icmp_ult_i32` appeared
; in three goldens (slice_libm_real_{coshl,llroundl,lroundl}.expected.log — 7, 2
; and 2 lines) and `cq_template_icmp_ult_i32_unc` in one (coshl, 7 lines); at
; dbab515 both counts drop to ZERO, and are still zero today. Both symbols now
; exist solely as generated bodies in runtime/cq_templates.{h,c} with NO witness
; anywhere — no golden, no lit fixture. (The de-vendoring was CORRECT: a keep has
; no injectable body, so a slice that vendored one proved a program the ship
; floor never compiles. The witness gap is collateral, and this file closes it.)
; The `_unc` half is the whole-DAG uncompute spine, which is exactly where this
; project's verify-clean silent miscompiles live (Rule 13), so an un-witnessed
; adjoint is not a cosmetic gap. This fixture restores the witness cheaply, at
; the ir-pass layer, without resurrecting an e2e slice.
;
; NEAR-MISS — DO NOT DELETE THIS AS REDUNDANT. The repo already witnesses
; `cq_template_icmp_ult_i32_hl` / `..._hl_inv` (ir-pass/test/
; lowering_hybrid_lgammal_words_f80.ll and the `slice_libm_real_{logf,tanhl}`
; goldens). Those are the HANDLE+LITERAL shape used as a control-condition flag
; and stripped by the fresh-minting `_inv`. They are DIFFERENT SYMBOLS with a
; DIFFERENT ARITY from the bare QQ pair pinned here: `_hl` takes (handle, i32
; literal) and its `_inv` returns a fresh handle; the bare QQ form takes
; (handle, handle) and its adjoint is the VOID `_unc` that reverses IN PLACE.
; Neither `cq_template_icmp_ult_i32` nor `cq_template_icmp_ult_i32_unc` appears in
; any other TEXT file in the tree — `git grep -I -w` for either token, excluding
; the generated runtime and this file, returns nothing. (Exact-token matching
; matters: `-w` treats `_` as a word character, so the bare symbol does NOT match
; its `_unc` / `_inv` / `_hl` siblings. The only non-text hits are string-table
; matches inside the committed prebuilt Mach-O binaries under `scratchpad_g387/`,
; which link the whole template archive; those are build detritus, not a witness,
; and they are byte-identical at dbab515^, dbab515 and HEAD.)
;
; THE PHYSICS BEING PINNED. `q1 = x; cq_theta(&q1, ·); q2 = y; cq_theta(&q2, ·); w = (q1 < q2)`
; — a DEAD, source-derived, tainted data-position compare over two independent
; theta rails, reaching the whole-DAG LIFO uncompute spine.
;
;  * DD-3 SLOT ORDER. The void `_unc` emitter is shape-agnostic (EmitInverse.cpp):
;    it PREPENDS the forward result `out`, then copies the forward operands in
;    their ORIGINAL order. So forward `cq_template_icmp_ult_i32(%h_q1, %h_q2)`
;    must adjoint to `cq_template_icmp_ult_i32_unc(%out, %h_q1, %h_q2)` — three
;    i32 handles, `out` first, q1 STILL at slot 1 and q2 STILL at slot 2. `ult`
;    is NOT commutative (`a < b` != `b < a`), so a swapped operand slot here is a
;    verify-clean WRONG UNITARY that no `opt -verify` and no trace-shape check
;    would catch. That is what the capture variables below exist to pin.
;
;  * WHY IT REVERSES AT ALL. The embedded compare is the permutation
;    |a,b,c> -> |a,b, c XOR (a<b)>, which is SELF-INVERSE: recomputing the flag
;    from the still-live roots and XOR-ing it back drives the flag rail to |0>.
;    It is a permutation, never a phase, so nothing dephases (Rule 7/8).
;
;  * LIFO, LEAF-FIRST, SOURCE STILL LIVE. Reversal is reverse program order, so
;    the `zext` leaf adjoint runs FIRST and reads the still-live compare rail;
;    only then does the compare adjoint run, reading the still-live roots %h_q1
;    and %h_q2; only then are those roots un-rotated. Whole-DAG LIFO is what
;    guarantees every adjoint's sources are still allocated — an adjoint reading
;    an already-freed rail is the classic use-after-free miscompile.
;
;  * FREE ONLY A PROVEN-SAFE RAIL, IN LIFO ORDER (Rule 6). Each rail is freed on
;    the step IMMEDIATELY AFTER the adjoint that restored it: the widened flag
;    after `zext_unc` and the compare flag after `icmp_ult_..._unc`; each theta
;    root is un-rotated by its own `cqrt_ry(-theta)` and KEPT (bd 5c5b — see the
;    THETA ROOTS item below). That adjacency is pinned below with
;    CHECK-NEXT and NOT with plain CHECK, deliberately: a stray in-place gate
;    slipped between an adjoint and its `cqrt_free` (e.g. `cqrt_x` on the rail
;    just zeroed) RE-DIRTIES the rail and turns the free into a hidden
;    measurement that collapses `q`. A plain-CHECK version of this file accepts
;    exactly that mutant; the CHECK-NEXT chain rejects it. `free_pairing_check.py`
;    would also catch it, but that is an e2e stage-2b gate and never runs on lit
;    fixtures — here the CHECK-NEXT chain IS the Rule-6 gate. Do not loosen it.
;
;    The two rail classes are NOT in the same state; do not conflate them:
;      - DERIVED rails (the compare flag and the widened flag) genuinely reach
;        |0>. Each was minted fresh by its template, and its void `_unc` XORs the
;        recomputed value back out — |0>-restoration, `free_pairing_check.py`'s
;        T1/T2/T3 clause for MINTED rails.
;      - THETA ROOTS do NOT reach |0>, and writing that they do would be wrong.
;        `cqrt_alloc_i32(%x)` initialises the root to the alloc-time CLASSICAL
;        BASIS STATE |x>, so `cqrt_ry(-theta)` restores |x>, not |0>. So the
;        roots are KEPT, never freed (bd 5c5b, libcqops vmz9). This file used to
;        license their free as "provably DISENTANGLED and in a KNOWN CLASSICAL
;        state" — the checker's A2 clause for ALLOCATED rails ("the write
;        history REDUCES TO IDENTITY, returning the rail to its alloc-time
;        classical v"). That is measurement immunity, not the |0> proof
;        `cqrt_free` requires; the backend's free certificate convicts it, and
;        (A2) still certifies it (the stage-2b half, filed separately).
;    Note the roots un-rotate in reverse allocation order — %h_q2 (allocated
;    second) before %h_q1 — which the CHECK sequence pins.
;
; No accept-predicate is added by this file, so per Rule 12 a POSITIVE fixture is
; sufficient; there is no new decline surface to probe.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %y) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %c  = icmp ult i32 %q1, %q2   ; Q+Q data-position compare -> flag (bare QQ, no literal)
  %w  = zext i1 %c to i32       ; DEAD widened-flag terminal off the compare lineage
  ret void
}

; Forward: two theta rails (alloc + ry each), then the bare QQ compare flag with
; q1 at slot 0 and q2 at slot 1, then the dead zext widen off the flag.
; CHECK:      %[[HQ1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ1]], double 2.500000e-01)
; CHECK-NEXT: %[[HQ2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ2]], double 5.000000e-01)
; CHECK-NEXT: %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32(i32 %[[HQ1]], i32 %[[HQ2]])
; CHECK-NEXT: %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
;
; Reversed adjoint (whole-DAG LIFO, leaf-first). zext_unc(out=%w, src=%c) runs
; BEFORE the compare adjoint and reads the still-live flag rail; its own rail is
; then a proven-|0> free. The compare adjoint is the VOID `_unc` in DD-3 slots —
; out prepended, then q1, q2 in ORIGINAL order — reading both still-live roots;
; the flag rail is then a proven-|0> free. Finally the roots un-rotate in reverse
; allocation order to their alloc-time classical basis states — NOT |0> (see the
; Rule-6 bullet above) — and are kept. Every free is CHECK-NEXT-adjacent to the
; adjoint that restored it. Every handle is i32 (Rule 15); no fresh mint.
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST]], i32 %[[CMP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[CAST]])
; CHECK-NEXT: call void @cq_template_icmp_ult_i32_unc(i32 %[[CMP]], i32 %[[HQ1]], i32 %[[HQ2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ2]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HQ1]], double -2.500000e-01)
; CHECK-NEXT: ret void
;
; The uncompute adjoint is the VOID `_unc`, NEVER the fresh-minting `_inv` (an
; `_inv` here would leak a new rail instead of restoring the old one), and the
; intrinsic must be fully lowered away.
; CHECK-NOT: cq_template_icmp_ult_i32_inv
; CHECK-NOT: cq_template_zext_i1_to_i32_inv
; CHECK-NOT: cq_theta_si32
