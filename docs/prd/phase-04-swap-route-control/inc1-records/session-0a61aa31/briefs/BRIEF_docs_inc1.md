# BRIEF_docs_inc1 — the surface docs that still describe the two-argument `cq_phi` (round-1 lens L6, F-L6-5)
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_impl_inc0.md`, `$SP/progress/inc0.md`, then
`$SP/progress/review_r1_L6.md` §F-L6-5 and §F-L6-6, and `$SP/progress/impl_inc1a.md` §"What shipped".
Agent name: `docs_inc1`. Model: opus. DOCS ONLY — no file under `ir-pass/`, `tests/`, `include/`, `tools/`.

## Where you work
Worktree `$SP/wt/inc0`, branch `3qlq-inc0` (Inc 0 landed there at a08b381: `frontend.md` §3.2/§3.3 are
already rewritten for the register-free branch phase and `cq_ry`). Continue on that branch.

## Job — make every user-facing doc TRUE of the Inc-1 surface, `void cq_phi(double)`
1. `docs/frontend.md` — the residual rows L6 measured: line ~78 (§3.1 table row `cq_phi(x, angle)`),
   ~152 ("cq_phi declared the same way (same 14 widths…)"), ~356 (§5 table "Phase rotation (Rz) |
   `cq_phi(x, φ)`"), and anything else `grep -n 'cq_phi' docs/frontend.md` shows that still names a
   register operand or `cqrt_rz_<W>` for W≠i1. Also drop the "lowering ships in Inc 1, not at HEAD"
   status blockquote's tense to "ships in Inc 1 (bd 3qlq.2, this branch set)" — do not claim it is on
   main.
2. `docs/backend.md` ~:141 and ~:336-337 (`@cq_phi_<sfx>(x, φ)` … lowering to `cqrt_rz_<W>` /
   deletion on classical) → the kickback lowering: recognised by EXACT name `@cq_phi`, prototype
   `void(double)`; under a tainted single-compare condition → flag mint, `cqrt_rz_i1(f, θ)`
   (`cqrt_x`-bracketed for the false arm), compare `_unc` strip, `cqrt_free(f)`; if/else → the exact
   two-gate form on one flag; N calls in one arm → N gates on one flag; uncontrolled/classically-
   controlled → deleted (global phase). The retired 15-width family is a RESERVED NAME that declines
   when declared (round-1 fix, lens L6). The ABI table row for `cqrt_rz_<W>`: emitted at `i1` only.
3. `docs/quantum-classical-handling.md` ~:242-247 ("cq_phi on a classical operand as a deletion
   candidate; on a tainted operand taint-propagating only") → `cq_phi` has no data operand; its ONE
   operand is an angle and is classical (a tainted angle declines `unsupported quantum-derived
   rotation angle`); it propagates nothing. `docs/example.md` ~:39 likewise.
4. `CLAUDE.md` Rule 3: the sentence "`cq_phi` (Rz) propagates taint but never introduces it (deleted
   on classical operands)" and "The **arg-1 angle** operand of a rotation is classical" → rewrite for
   the new surface: `cq_theta` sole source, `cq_measure` sole sink, `cq_phi` is REGISTER-FREE
   (`void cq_phi(double)`) — a branch phase with no data operand, so it neither introduces nor
   propagates taint; its only operand is the angle and is classical (for `cq_theta` the arg-1 angle,
   for `cq_phi` the arg-0 angle). Keep the per-operand-use exclusion sentence for `cq_theta`. Also
   add ONE line to the "Key Prohibitions" bullet "Do NOT make `cq_phi` (Rz) a taint source…" so it
   reads for the new surface (do not allocate a qubit for it; it has no operand to allocate for).
5. F-L6-6 doc note (frontend.md §3.3): `cq_phi(<int expr>)` compiles by implicit int→double
   conversion and IS a phase of that many radians — the type system no longer separates register
   from angle; and the name `cq_phi` with prototype `void(double)` is reserved (a user definition is
   refused — state it as "refused" ONLY if the fix agent's hand-back in `$SP/progress/fix_r1.md`
   says the decline shipped; otherwise say "must not be defined by user code").
6. `grep -rn 'cq_phi(' docs/*.md README.md | grep -v 'cq_phi(double\|cq_phi(θ\|cq_phi(PI\|cq_phi(0\.'`
   as your final sweep — every remaining two-argument spelling is either rewritten or (in a
   historical/design-record section) annotated "(pre-3qlq register form)".
Commit on `3qlq-inc0`; hand back per BRIEF_common with the list of lines changed per file.
