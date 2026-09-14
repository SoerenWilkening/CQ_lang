# Track U — ADVERSARIAL REVIEW round 1 (Rule 13), bd `z9t1`

**Subject:** branch `undef-seed-zero`, tip `8865f7d55104c52644080c41ed8ee02b17e1c89f`, in the worktree
`/Users/sorenwilkening/Desktop/CQ_undef`. Its built binary: `cq-opt`
`a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff`, `libCQPass.so`
`957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194`.
**ORACLE** (unchanged main checkout `build/`): `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.

**YOUR FIRST ACT IS `shasum -a 256` ON BOTH BINARIES.** If either differs from the hashes above, STOP and
report — a gate line whose hash does not match the binary on disk is a FINDING, and so is a moved oracle.

## Your role, and its limits (PROTOCOL.md matrix — do not exceed it)

You run **NO build** and **NO suite**. You may re-run **at most ONE** lit fixture as a Rule-11 spot-check.
Your instrument is the **per-probe pipeline, subject vs ORACLE**, using the binaries that already exist:

```
LLVM=/usr/local/opt/llvm@19/bin
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S p.c -o s1.ll
<BUILD>/ir-pass/cq-opt -load-pass-plugin <BUILD>/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll; echo exit=$?
python3 tools/free_pairing_check.py s2.ll                     # accepts only, STRICT
"$LLVM/clang" s2.ll <BUILD>/runtime/libcq_templates.a <BUILD>/runtime/libcq_runtime.a -o a && ./a
CQ_CTRL_DBG=1 <BUILD>/ir-pass/cq-opt … 2>&1 | head            # to name a firing site
```
Write probes into `$SES/trackU/review_r1_probes/` **in the main checkout** (read-only elsewhere). Never
write under `ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a running
measurement; never `pkill` by pattern. ⚠ The box is under heavy concurrent load — if a measurement is slow,
that is contention, not a result; never let load make you skip a probe and report it as clean.

## What is ruled (bd `z9t1`, owner 2026-09-14, five clauses)

1. The rule attaches to **QUBIT ALLOCATION**, not to variables: an `undef`/`poison` SEED reaching a **source**
   `cq_theta`'s arg-0 becomes a concrete zero **at the allocation**. CQ makes no claim about the C variable;
   clang keeps every liberty, including deleting a branch that reads the same uninitialized value.
2. **BOTH spellings compile** — `bool b; b = cq_theta(b,.5);` and `bool b; if (c) b = cq_theta(b,.5);` —
   which forces the placement EARLY, before classification.
3. **SILENT** — no warning, no diagnostic, exit 0.
4. **`cq_measure` of a never-quantum uninitialized value KEEPS DECLINING** (bd `21mg`).
5. **NOT TOTAL** — an undef arriving through a phi with an undef incoming is not caught by
   `valueCarriesUndef` (constant-only) and stays as today.

## What was built, and the attack surface the implementer handed you

`normalizeUndefRotationSeed` in `ir-pass/src/RotationLowering.cpp`, **one call site** in `collectAndSeed`'s
`IsTheta` arm (`TaintPropagation.cpp`) — i.e. inside `propagate`, the funnel both entry points and every
re-propagate round pass through. +200 lines, no new symbol/ABI/`CQ.h` change/diagnostic. Read
`$SES/trackU/IMPL_U.md` (in the subject worktree) in full first.

**Six places to attack, in priority order. These are leads, not a checklist — Rule 10 says all bugs are deep
and interlocked, and CLAUDE.md's measured hit rate says this round finds something.**

1. **The φ-INCOMING WIDENING — the biggest one.** The ruling says *seed*. The implementation also normalizes
   an `undef` **φ incoming**, gated on "that φ carries that theta's own result". That is a widening beyond the
   ruling's letter, justified by a measurement (`-O1` spells the uninitialized object `undef` at BOTH reads,
   so normalizing only the seed leaves F1's pointer-identity sub-clause failing). **Attack the gate.** Can a
   φ carry that theta's result AND have an `undef` incoming that the program did not write as an
   uninitialized read? Try: a φ with three incomings; an `undef` incoming on an edge that is unreachable; a
   φ whose other incoming is a *different* theta on the same rail; a nested/chained φ; a loop header φ whose
   backedge incoming is the theta and whose preheader incoming is `undef`. Does the normalization change which
   region F1/F2 classify, or which value `condProvenance` seeds from?
2. **`isa<UndefValue>` as the ACTION predicate while `valueCarriesUndef` is the GATE.** The implementer
   reports the safety polarity FLIPS relative to every other caller (there it gates a decline; here it gates
   a rewrite) and that `valueCarriesUndef` is true for a `ConstantExpr` merely *containing* an undef leaf,
   which must NOT be rewritten (it denotes an address). Verify the split is exactly right in both directions:
   is there a value that **should** be normalized and is not (`poison` in a vector? an `undef` of an fp
   width? a `zeroinitializer`-adjacent case?), and one that **is** normalized and should not be?
3. **L1, and the `specialize` gap the implementer flagged against themselves.** They report that
   `specialize` runs AFTER the last full `propagate` — the real L1 gap — and that it is safe only because
   `SpecializeReject::scanBody` rejects every body containing a theta ("load-bearing precondition R2"), NOT
   because of a re-propagate. **They also record that their FIRST draft of that argument was wrong and "reads
   just as convincing."** Take that seriously: re-derive the argument yourself from the source, and try to
   construct a theta that reaches `specialize` un-normalized. Also confirm the `collectAndSeed` site really
   is hit in BOTH entry points and on every `repropagateControlMerges` round.
4. **The three fixtures that flipped from DECLINE to ACCEPT, and the u1rp mover.** `stateprep_{undef,poison}_seed`,
   the PredMux `theta_poison_seed`, and the corpus FINDING
   `control_predmux_reject_selectform_rotation_theta_poison_seed.ll` (bd `u1rp`), whose over-decline existed
   for a poison that no longer exists by the time `classifyConeNode` asks. **For each: is the new ACCEPT's
   emitted circuit the right one?** Read the stream, not the exit code. The implementer moved the `u1rp` pin
   to the angle spelling — verify the angle spelling still declines and that the move did not vacate the
   fixture (a decline fixture that goes green because its subject no longer exists pins nothing — Rule 12(c)).
5. **Clause 4 and clause 3.** `cq_measure` of a never-quantum undef must still decline with the `21mg` string
   character-for-character. Nothing may warn. Probe the compositions: undef seed AND undef measure in one
   function; an undef seed whose rail is later measured; an undef seed under a peeled multi-φ merge.
6. **The PARTIAL corpus sweep.** The implementer stopped the sweep by exact PID under load 300–440 and closed
   it with a 98-row tail over every unswept fixture containing an `undef`/`poison` token, plus a parse (not
   grep) showing 0 of the 782 unswept fixtures carries the trigger. **Audit that argument**: is "carries the
   trigger" the right closure — can a fixture with no `undef` token in its text acquire one from the pass's
   own rewriting, or from a `ConstantExpr`, before `collectAndSeed` runs? If the closure is wrong, say which
   rows are unaudited.

Also worth one probe each, cheaply: an undef **ANGLE** (arg-1 — must be untouched, Rule 3); a **CHAINED**
theta (the rule is SOURCE-only); the widths the implementer did not fixture; and `bool b[N]` uninitialized
(Track L flagged the composition with the rail bank).

## Verdict format — `$SES/trackU/REVIEW_U_R1.md`

Per finding: **F-U1-<n>**, a one-line claim, the probe that demonstrates it (path + exact commands + the two
verdicts), the severity (**over-ACCEPT / silent miscompile** — the unforgivable class; **over-DECLINE** — a
defect under the 2026-09-11 ruling; **fixture/record hygiene**; **documentation**), and the minimal fix you
would make. End with one of: **CLEAR**, **CLEAR-WITH-ITEMS** (items listed and each dispositioned), or
**NOT CLEAR** (with the blocking findings named).

Say plainly what you did NOT examine. A green suite does not clear a core change (Rule 13), and
"opt -verify clean" and "runs without crashing" are not evidence (Rule 2). If you find nothing, say what you
attacked and why you believe the surface is covered — a clearance with no attack record is worth nothing.
