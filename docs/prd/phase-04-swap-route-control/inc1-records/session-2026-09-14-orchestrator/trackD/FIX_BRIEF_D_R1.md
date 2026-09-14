# Track D — FIX brief for review round 1 (bd `3d8q`) — verdict was **NOT CLEAR**

Worktree `/Users/sorenwilkening/Desktop/CQ_3d8q`, branch `stale-reader-fence`, tip `e7d6efe2`.
**READ FIRST:** `$SES/trackD/REVIEW_D_R1.md` in full (29 probes in `trackD/review_r1_probes/`), then your
own `IMPL_D.md` §9.

**Your deviation was adjudicated IN YOUR FAVOUR, and the wrong record was mine.** `g2_measure_parent` must
DECLINE: `q` denotes `Ry(.3)|0⟩` while the register holds `Ry(.8)|0⟩` — different distributions, silently —
and the pure-op twin (`q+1` in place of `cq_measure(q)`, the identical wire question) declines **on the
ORACLE**, i.e. since Phase 5. bd `3d8q`'s *"stays ACCEPT (ancestry exempt)"* is about the chain **TIP**
(`f1w2`), which still accepts. `BRIEF_D.md` §3 is corrected in place with a dated erratum, and so is the
bead. **Keep the decline. Do not revert it.**

The reviewer also verified a lot of your work rather than restating it: both one-operand fixture edits are
byte-identical streams with sha-256 matched and the old text genuinely declines on the subject (so both were
**forced**, not chosen); `p07_chained_after` is A/A; **8 hand-built well-formed programs unchanged — no
over-decline found**; a 40-slice targeted e2e sample, 0 movers and 0 stream diffs; all 9 new fixtures pin
what they claim. It also **closed** the Delta scope's direct sub-case by exhaustive trace, which you could
not.

---

## F-D1-1 — THE DISQUALIFYING FINDING. The fence does not yet close the bug it was built for.

```c
int q = cq_theta(0, 0.3);
for (int i = 0; i < 3; i++) { int b = cq_theta(q, 0.1); s += cq_measure(b); }
```

One `cq_theta` in the body, reading a loop-**INVARIANT** quantum name. It **still compiles**, and its trace
is **byte-identical** to the self-assigned twin `q = cq_theta(q, 0.1)` — a **different, well-formed
program**. That sentence is bd `3d8q`'s own definition of the defect.

**ROOT CAUSE:** `Self`/`Covered` is granted to the reader **unconditionally** and is tested **before**
`gateIsHarmless`, so the reader's own **PREVIOUS DYNAMIC INSTANCE** — the only staling gate in this shape —
is never adjudicated. `Covered`'s contract came from Track A.1, where the caller really had ruled on the
gate; here *"already ruled on"* is **false against itself across a back edge**. This is **L2**: you widened
a swept set and did not re-derive the exemption set computed over the same closure. ⚠ It sits exactly where
your own `IMPL_D.md` §9 item 3 pointed.

**Population, isolated by measurement:** `r5`, `r5a` (runtime trip), `r5b` (template seed), `r5d` (post-loop
measure) all **MISS**; `r5c`/`r5e` (two siblings) correctly decline. **No fixture pins either disposition** —
the shipped post-loop accept fixture uses the φ-carried form, which the fix keeps — and
`staleRailRecordRead` cannot see it (no rail φ to collapse), so **your** fence is the right owner.

**MINIMAL FIX, hand-traced by the reviewer through all five pinned families:** grant the self-exemption only
when `gateIsHarmless(I, I, Rec, …, RequireEmitDominance=false)` holds — **the existing relation, no second
spelling** (Rule 14). Then **pin BOTH dispositions with new fixtures**, since neither is pinned today, and
**re-measure the 26 in-loop / exclusive-arm fixtures** and the whole `r5` family.

## The remainder, in the reviewer's ranking

* **F-D1-2 — Rule 1 "no third path".** `WeakTrackingVH` **tracks across RAUW** in LLVM 19 (check the header
  yourself), so the drain has **three** outcomes where your code and all three comment blocks enumerate
  **two**: a RAUW to a **non-`Instruction`** drops a decline **silently**. Not demonstrated on a reaching
  program — so fix the enumeration and make the third outcome loud, and say whether you could reach it.
* **F-D1-3 — the record contradicts the code.** `StaleQuantumReaders`' header documents a residual the code
  **closes**, and **forbids the delta re-ask the code ships**. Fix the header, not the code.
* **F-D1-4 — vacuity.** `diagnosePreLoopCommitStale`: measured **8 `-NOT`s, 0 positive pins**, and your
  compensating enumeration does **not** cover G2's taint-growth failure mode. Either restore a positive pin
  or state precisely what is now unpinned and why that is acceptable — Rule 12(c).
* **F-D1-5 — strengthening, carry it.** The reviewer closed the Delta scope's **direct** sub-case by
  exhaustive trace. The residual **routing** sub-case leans on `declineClassicalMuxes` and is **unrecorded**.
  Record it with the argument.
* **Minor:** the folded-angle-select path's `!dbg` reports **column 0**. Fix or record.

## Gates you own (PROTOCOL matrix — FIX-agent row)

`cmake --build build -j8` (**never `--target CQPass` alone**); record the new `shasum -a 256` in `GATES.md`.
Re-run: the `r5` family in full, the 26 in-loop/exclusive-arm fixtures, all 14 reproducers, the whole
must-not-move table, every fixture you touch, and **`ctest -R ir-pass-lit` ONCE**. **NO corpus sweep** — one
per session, owned by the merge gate; your existing sweep result stands **for the pre-fix binary only** and
must be labelled so. **NO** full suite, `^e2e-`, equivalence sweep, or twin matrix.

⚠ Every gate line recorded against `7fe2bcbf` is **void for the new binary**. Re-record; say which lines are
cited-for-the-old-binary and which you re-ran.

## Rounds

The reviewer budgets **round 2 AND round 3**, on the measured hit rate and on the fact that F-D1-1 was
exactly where your own attack surface pointed. Round 2 will start at your fix. Your `FIX_D_R1.md` must hand
it a fresh attack surface, not a repeat of the last one.

## Deliverable

Update `IMPL_D.md` and `GATES.md`, add `FIX_D_R1.md` with each finding's disposition, commit on the same
branch with the two `CLAUDE.md` trailers. Report: new tip, new binary hash, the `r5` family before/after on
both binaries, the re-measured 26 + 14 + must-not-move tables, the two new fixtures pinning both
dispositions, the F-D1-2 enumeration fix, and every gate line as `ran:`/`cited:`.
