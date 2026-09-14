# Track T — IMPLEMENTATION brief: give the loop twin matrix an `i1` axis (owner-ruled 2026-09-14)

Worktree `/Users/sorenwilkening/Desktop/CQ_twinbool`, branch `twin-matrix-bool` (created off `main`
607b6fe4). Records: `$SES/trackT/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`;
`$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md`, `CLAUDE.md` (Rules 2, 11, **12**, 19; CORRECTNESS RISK §3 **L10** —
*instruments earn their keep by being attacked*; the Build & Test and Where Things Live rows for
`tools/loop_twin_matrix.py`, `…expected.txt`, `…quarantine.txt`), `$SES/trackL/SCOPE_L1a.md` §5, and the
header of `tools/loop_twin_matrix.py` itself.

## 1. The finding, and the ruling

Measured by the Track L scoping agent: `e2e-loop-twin-matrix` — which `CLAUDE.md` calls **the only
instrument in the tree that can see a leaked TEMPLATE-minted rail** (stage 2b is structurally blind to
those, having no `cqrt_alloc` to count) and which is therefore the witness of record for all in-loop work —
generates **259 expected + 29 quarantined = 288 cells** from a script that emits **2 `bool` tokens in
total**. The `i1` width is effectively uncovered. That is the width of every shipped bool-controlled prep
and Ry arm since `e96f89c`, and the width of the owner's entire Grover cascade.

**Owner ruling 2026-09-14: widen it BEFORE the loop work**, so the loop increment's primary instrument can
actually witness its subject instead of reporting green over cells that never exercise `i1`.

## 2. What to build

Add `_Bool`/`i1` to the generator's width axis so the existing shape axes are crossed with it, regenerate
the baselines **deliberately**, and record the new cell count. Keep every existing cell's identity stable if
you can; if a cell's id must change, say which and why.

**The quarantine is the delicate part.** `tools/loop_twin_matrix.quarantine.txt` pins each blessed
divergence by `(verdict, SHA-256 of the exact unified diff)` and **fails if the signature moves, if the cell
stops diverging, or if it appears in both files**, with two boundary controls that run on every invocation
including `--regenerate` (a review once found both write modes returning *before* the controls ran, and
`--regenerate` writing a forbidden row under a message that called itself a refusal). Its own mutant
validation is `e2e-loop-twin-quarantine-selftest` (27 cases). **Do not weaken any of that to make room for
new cells.**

## 3. The part that matters more than the widening — READ TWICE

New `i1` cells **may diverge**. A rolled ≠ unrolled divergence at `i1` is **exactly what this instrument
exists to find**, and it is the reason the owner ruled to widen before the loop work rather than after.

**Every divergent new cell gets an individual written verdict, in `IMPL_T.md`:**
* **a real defect** → file a bd issue with the measured diff and the two streams, and say plainly that the
  instrument found a bug the moment it was pointed at `i1`. **Do not quarantine it.**
* **a blessed divergence** → quarantine it with the reason written in the same terms the existing 29 rows
  use, and say why it is benign in terms of the unitary, not in terms of the diff.

⚠ **Never run `--regenerate` to turn a red green.** Regenerating a baseline is a deliberate act with a
written reason (Rule 12), and a gate expected to be red is a gate people stop reading (L10).

## 4. Gates you own

Configure + build once (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release`; `cmake --build build -j8`; never `--target CQPass` alone) — you need a binary
to generate cells, but you are changing **no pass source**, so your binary must be **bit-identical** to the
ORACLE. **Check that with `shasum -a 256` and report it**: if it differs, STOP — something else moved.

You own exactly two suite gates, because no smaller layer can witness a matrix change:
`ctest --test-dir build -R '^e2e-loop-twin-matrix$'` and
`ctest --test-dir build -R '^e2e-loop-twin-quarantine-selftest$'`. Run each as many times as you need, record
every line in `$SES/trackT/GATES.md`. **NEVER** the full suite, **NEVER** `^e2e-`, **NEVER** the equivalence
sweep, **NEVER** `ir-pass-lit` (you touch no fixture).

## 5. Deliverables

`$SES/trackT/{IMPL_T.md, GATES.md, probes/}`: the generator diff, the OLD and NEW cell counts (expected +
quarantined = total, all three numbers), the per-divergent-cell verdict table of §3, the binary-identity
check, and every gate line as `ran:`/`cited:`.

Commit on your branch (no push, never touch `main`), message `test(instrument): bd uq96
— …` with the two `CLAUDE.md` trailers. Report back: cell counts before/after, the divergence verdicts,
any bd issues you filed, and anything you could not do.
