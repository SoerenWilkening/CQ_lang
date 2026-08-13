; lowering_uncompute_bitcast_roundtrip_or_i64.ll — WITNESS RESTORE (bd `gowy`).
;
; The three symbols this file pins — `cq_template_bitcast_f64_to_i64_unc`,
; `cq_template_or_i64_hl_unc`, `cq_template_bitcast_i64_to_f64_unc` — had exactly
; ONE witness in the repo outside the generated runtime: the trace lines in
; `tests/e2e/slice_libm_real_coshl.expected.log` (25 of them at dbab515^).
;
; PROVENANCE, STATED PRECISELY (it will be read by an archaeologist, Rule 0):
; commit dbab515 (`tkju`) DELETED NO FILES. It DE-VENDORED 52 e2e slices IN PLACE
; — stripping the FICTIONAL SOFTWARE bodies those `.c` files had vendored for
; Rule-18 HARDWARE keeps — and REGENERATED 21 goldens. Verify: `git show
; --name-status --format='' dbab515 | awk 'NF{print $1}' | sort | uniq -c` is
; `1 A` + `75 M` and ZERO `D`; `tests/e2e/*.c` is 249 files before and 249 after;
; `tests/e2e/slice_libm_real_coshl.{c,expected.log}` are BOTH still in the tree
; today (both merely `M` in that commit). What vanished was the witness LINES, not
; the slices: with the fictional body gone the slice no longer emits these
; templates, so the regenerated golden went 25 matching lines -> 0.
;
; The de-vendoring was right; the collateral was that these `_unc` twins fell back
; to existing only in the generated runtime (`runtime/cq_templates.c`) with NO gate
; anywhere — not an e2e golden, not a lit fixture. 14 of the 20 symbols orphaned
; that way are ADJOINT twins, i.e. the whole-DAG uncompute spine, which is exactly
; where this project's verify-clean silent miscompiles live (Rule 13). This is the
; cheap replacement: an ir-pass lit pin, not an e2e slice. No accept-predicate is
; added here, so a POSITIVE fixture discharges Rule 12 — no decline probe is owed.
;
; THE SHAPE: `q = cq_theta_f64; b = bits(q); o = b | 7; d = bits(o)` — the canonical
; libm bit-twiddling round trip (reach the float through its integer view, set low
; bits, read the float back), DEAD at the terminal so the whole THREE-LINK DAG
; reaches the Phase-5 uncompute spine and reverses in one LIFO sweep.
;
; PHYSICS PINNED
; ==============
; (1) A `bitcast` is a pure REPRESENTATION change, NEVER a measurement — a standing
;     hallucination-risk callout in CLAUDE.md. The only path to a measurement gate
;     is a user-written `cq_measure`; there is none here, and the compiler never
;     inserts one (Rule 5). The f64<->i64 same-width pair is a first-class row of
;     the cast grid (`tools/opcode_table.yaml`), fwd/inv/unc.
; (2) The forward cast MINTS A FRESH RAIL off the still-live root; it does not
;     reinterpret the root's handle in place. Handles are ALWAYS i32 (Rule 15) — the
;     f64/i64 widths live in the SYMBOL NAME, never in the handle type, so both
;     `_unc` twins here are `(i32 out, i32 src)` despite naming two different widths.
; (3) THE ADJOINT OF A BITCAST IS ITS OWN SAME-DIRECTION VOID `_unc`, NOT the
;     opposite-direction forward. `bitcast_f64_to_i64_unc(out, src)` recomputes
;     bits(src) from the still-live source and XORs it out, returning `out` to |0>.
;     Re-interpreting the same handle with `cq_template_bitcast_i64_to_f64(%b)`
;     instead would MINT A SECOND RAIL and leave `%b` dirty — a rail that then can
;     never be freed (Rule 6). Both directions appear here as FORWARD links, so this
;     is the one fixture where both `_unc` twins of the bitcast pair are witnessed
;     inside a single reversal.
; (4) DD-3 SLOT ORDER (EmitInverse.cpp): `out` — the forward RESULT rail being
;     returned to |0> — is PREPENDED, then the forward operands in their ORIGINAL
;     order. So `or_i64_hl(%b, i64 7)` adjoints to `or_i64_hl_unc(%o, %b, i64 7)`:
;     the i64 classical literal stays at its real VALUE width in its forward slot,
;     the handle stays in its forward slot. A swapped slot here is verify-clean and
;     a WRONG UNITARY, which is the whole reason the CHECKs below capture handle
;     IDENTITY rather than grepping for the symbol name.
; (5) LIFO, LEAF-FIRST, SOURCE STILL LIVE: the last-computed link is undone first.
;     `bitcast_i64_to_f64_unc` reads the still-live `%o`; only then does `%o`'s own
;     adjoint read the still-live `%b`; only then does `%b`'s adjoint read the
;     still-live root `%h`. Nothing on this chain is written in place between a
;     forward link and its adjoint, so every `_unc` recomputes from the SAME source
;     state the forward saw — the (T2) precondition of the Rule-6 free-pairing gate.
; (6) FREE ONLY A PROVEN-CLEAN RAIL (Rule 6) — AND THE TWO KINDS OF "CLEAN" HERE
;     ARE NOT THE SAME STATE. Each DERIVED rail (`%b`, `%o`, `%d`) genuinely
;     reaches |0>: its own void `_unc` recomputes the forward value from the
;     still-live source and XORs it back out. The ROOT `%h` does NOT reach |0> and
;     this fixture does not claim it does — `cqrt_alloc_f64(%x)` initialises the
;     root to its alloc-time CLASSICAL BASIS STATE |x> (from the data operand), and
;     `cqrt_ry_f64(-θ)` reduces the write history to identity by restoring THAT
;     state, not |0>. What licenses the root's `cqrt_free` is that it is provably
;     DISENTANGLED and in a known classical state — not copy+uncompute of a
;     superposed source, which would need a `cqrt_cswap` (Rule 8).
;     Either way the free is IMMEDIATE: never before the rail's own adjoint, and
;     with nothing in between that could re-dirty it. Both halves are pinned below
;     by `CHECK-NEXT` — see the note above the reversal block for why a plain
;     ordered check is not enough.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; WHY THIS WHOLE BLOCK IS `CHECK-NEXT` (verified contiguous in the real lowered
; output — the emitted `@slice` body is one straight run from `cqrt_alloc_f64` to
; the root `cqrt_free`, no intervening instruction): here ADJACENCY IS THE PHYSICS,
; and a plain `CHECK` — which only ORDERS matches, never ABUTS them — lets the
; Rule-6 killer through. Demonstrated mutant: splice a stray
; `call void @cqrt_x(i32 %d_rail)` BETWEEN `bitcast_i64_to_f64_unc(%d, %o)` and
; `cqrt_free(%d)`. The adjoint had just driven that rail to |0>; the stray gate
; re-dirties it, so the `cqrt_free` stops being a lifetime op and becomes a HIDDEN
; MEASUREMENT that collapses `q` (Rule 6, and CLAUDE.md's standing callout that
; `cqrt_free` is not benign). Under a plain ordered check that mutant PASSES;
; under `CHECK-NEXT` it FAILS. Nothing else covers it at this layer:
; `tools/free_pairing_check.py` is an e2e stage-2b gate over linked slices and
; NEVER runs on lit fixtures. The same contiguity on the FORWARD run pins the (T2)
; precondition of claim (5): a gate spliced between two forward links would write a
; source IN PLACE, so that link's `_unc` would recompute from a DIFFERENT state
; than the forward saw — verify-clean, wrong unitary, rail never freeable.
;
; Forward stream: theta -> alloc + ry on the root, then the three-link chain
; (f64->i64 view, the `_hl` OR against the classical mask, i64->f64 view back).
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %x)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f64_to_i64(i32 %[[H]])
; CHECK-NEXT: %[[O:[a-zA-Z0-9_.]+]] = call i32 @cq_template_or_i64_hl(i32 %[[B]], i64 7)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_i64_to_f64(i32 %[[O]])
;
; Reversed adjoint, LIFO leaf-first, each `_unc` reading the STILL-LIVE source it
; was computed from, each rail freed the INSTANT its own `_unc` zeroed it — the
; reversal begins on the very next instruction after the last forward link, so no
; gate can slip in anywhere along the undo:
; CHECK-NEXT: call void @cq_template_bitcast_i64_to_f64_unc(i32 %[[D]], i32 %[[O]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cq_template_or_i64_hl_unc(i32 %[[O]], i32 %[[B]], i64 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[O]])
; CHECK-NEXT: call void @cq_template_bitcast_f64_to_i64_unc(i32 %[[B]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])
;
; The adjoints are the VOID `_unc`, never the fresh-minting `_inv` (a minted `_inv`
; would leave a module-level `declare` in this trailing region — the lowered
; module's declare block mirrors EXACTLY the emitted symbol set), and the
; `cq_theta` intrinsic is fully lowered away: the pass ERASES the now-unused
; `declare double @cq_theta_f64`, so the last guard witnesses real ERASURE of the
; intrinsic, not merely the absence of a call.
; CHECK-NOT: cq_template_bitcast_i64_to_f64_inv
; CHECK-NOT: cq_template_or_i64_hl_inv
; CHECK-NOT: cq_template_bitcast_f64_to_i64_inv
; CHECK-NOT: cq_theta_
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)

define void @slice(double %x) {
entry:
  %q = call double @cq_theta_f64(double %x, double 2.500000e-01)
  %b = bitcast double %q to i64                  ; float -> integer view (rep change)
  %o = or i64 %b, 7                              ; _hl mask against a classical literal
  %d = bitcast i64 %o to double                  ; integer -> float view, DEAD terminal
  ret void
}
