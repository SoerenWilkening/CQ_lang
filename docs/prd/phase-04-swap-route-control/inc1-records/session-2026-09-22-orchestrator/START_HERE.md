# Session 2026-09-22 — start here

**Owner ruling 2026-09-21: pay down P1 correctness debt, starting with bd `s82e`.**

Read `CLAUDE.md` (§4g is new; §4d moved to `docs/CLAUDE-HISTORY.md`; the §5 Q-R1-1
paragraph has a correction block), then
`$PREV/{CLOSING_REPORT,GATES,PROTOCOL,NEXT_SESSION_PROMPT}.md` where
`PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-21-orchestrator/`.
Then `bd prime`, `bd show test_C_libtooling-s82e`, and
`inc1-records/session-2026-09-14c-xdu2-w1/trackS/IMPL_S.md`.

```
main e107a177 · cq-opt 3368af1262695d7e4c… · libCQPass.so 48b8b4db61777082e9…
ctest 472/472 · lit 2112 · fixtures 2112 · goldens 406
LLVM = /usr/local/opt/llvm@19/bin   (NOT on PATH)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.

## ⚠ DO NOT START BY WRITING A FIX. RE-MEASURE FIRST — THE BUG MAY HAVE LANDED ALREADY.

bd `s82e` is a P1 over-accept: an in-loop leak of entangled which-path rails that
needs **no tainted control flow at all**. Track S (2026-09-14) determined the class
is **(R-diverge)** — different unitaries, not merely more rails left allocated —
which **falsifies the premise of the owner's own "PROVE IT" ruling**, and Track S
stopped there without writing a fix, as instructed.

**Measured 2026-09-21 on the binary above, AFTER bd `tu9q` P0+P3 landed:**

```
s1_live_shift      (rolled)  ACCEPT, 14 trace lines     <- Track S recorded 10
s1_live_shift_un   (flat)    ACCEPT, 14 trace lines     <- Track S recorded 14
diff                         BYTE-IDENTICAL
```

That is the **malign** half — the cell Track S said *"must NOT be blessed; it is a
wrong unitary"*. The per-trip `lshr` rails are now `_unc`'d and freed in the body,
so nothing entangled with `h0` survives to the trailing `cqrt_ry_i32(h0, 0.9)`.
**bd `tu9q`'s own bead says it is "the CAPABILITY half of the bd `s82e` re-ruling
… the end state that retires that decline", and on this one pair it did.**
Nobody connected the two because s82e's exhibits live in a track record from
2026-09-14, not in the corpus.

## The job, in order

1. **Re-measure the WHOLE s82e exhibit set on this binary** — the three benign
   (R-leak) programs named in the bead (`w2k_noregion_invread`,
   `w2h_phase_inloop_invread`, `w2h3_select_iterlocal_invread`) and every
   (R-diverge) program Track S's `IMPL_S.md` §0 tabulates, each against its
   hand-unrolled twin. ⚠ **Capture `$?` immediately, never after a pipe** — that
   trap cost time again on 2026-09-21.
2. **Decide what is left.** Three outcomes and they are different sessions:
   (a) the whole class is fixed → close bd `s82e`, close bd `tu9q`, and convert
   Track S's exhibits into the fixtures and twin-matrix cells the class never had
   (`IMPL_S.md` §402-403 already names the two cells and their expected verdicts);
   (b) a residue survives → that residue is the new statement of the bug, and it
   needs its own adversarial round before a fix;
   (c) something got **worse** → stop and report.
3. **Only then** consider a fix, and note the bead's own dispositions were
   PROOF / DISCHARGE / DECLINE with DISCHARGE and DECLINE explicitly rejected by
   the owner — but on a premise that is now falsified twice over, so **it returns
   to the owner as a fresh decision** rather than being read off the old ruling.

⚠ **12 shipped fixtures pin the `s82e` decline string.** Whatever you conclude,
they move together or not at all, and two of them changed owner on 2026-09-21.

## Carried lessons that will bite here

* **An instrument's blind spot is shaped like its author's model.** Use
  `$PREV/probes/entangle.py` (edge-complete, 18 boundary controls), **not**
  `$PREV/probes/dephase.py`, which is committed marked SUPERSEDED with its two
  misses in its header.
* **Stage 2b is structurally blind to this class** — it counts `cqrt_alloc` sites
  and a rolled per-trip alloc reads as one rail. The rolled-vs-hand-unrolled trace
  pair is the only instrument in the tree that sees it. Say so when you cite a gate.
* **A probe for a control-flow shape must be checked at stage 1 for the shape it
  claims** (bd `46oo`): `main(){ return slice(4); }` lets `-O1` delete the control
  flow the probe was built to exercise.
* **An e2e slice whose `main` returns nonzero fails with zero output and no diff**
  (bd memory `e2e-slice-main-return-value-trap`).

## Also open, if s82e closes early
bd `a945` (a retirement trigger now due — L7's shape, third instance in three
sessions), then bd `a3z7` / bd `0njv` (the dtzb in-place family), bd `yiid` (an
UNRULED boundary — `cq_measure` is not modelled as a wire event at all; owner
decision), bd `lo7u`.
