# loopgate/probes — provenance, so nothing here is read as this agent's measurement when it is not

**Written by the merge-and-gate agent (this directory's owner):**

* `sweep_gate.sh` + `sweep_row.sh` — the group corpus sweep. Reused from
  `loopfix/probes/sweep.sh` (Rule 14) with **two deliberate changes**: (1) the **full stderr** is
  sha-256'd instead of being reduced by the shared `corpus.sh` tag regex — PROTOCOL S3 records that
  the regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, so a decline→decline STRING
  move inside it is invisible; (2) the lowered IR is sha-256'd for accepts (with `ModuleID` /
  `source_filename` stripped, so it IS comparable across sweeps) — an accept whose STREAM moved is a
  mover too. Boundary controls inherited **because the fix agent's first spelling reported "0 movers"
  while all 2050 rows were exit 127** (`CLAUDE.md` L10): it refuses to emit a file unless the binary
  AND the plugin exist at the path given, no row is exit 127, both verdict classes occur, and it skips
  0-byte modules by name (bd memory `empty-module-accepts-vacuity-trap` — a 0-byte `.ll` ACCEPTS
  through the passthrough early-out). Self-attacked: a bad build dir exits 2.
* `attribute.py` — buckets movers per track BY STRING and prints an **`⚠ UNATTRIBUTED — FINDING`**
  bucket; exits non-zero if that bucket is non-empty. It is a first cut, not an oracle: every mover in
  `ATTRIBUTION.md` was adjudicated by reading the row, not by trusting the bucket.
* `dupscan.py` — the L8 duplicate-body scan: sha-256 over each fixture's NON-COMMENT lines, and for
  every group of >1 it reads each member's **claimed verdict off its own RUN lines** and flags groups
  that MIX them (the 2026-09-14 erratum: that half is what catches a `git mv`'d fixture resurrected by
  a merge under two names with contradictory verdicts).
* `rederive.sh` — re-derives a rolled-vs-hand-unrolled pair on a given build, reporting **BOTH** the
  trace LINE COUNT and the gate-symbol MULTISET. ⚠ It reports both because the fix agent's depth-3
  probe read `72 == 72` and was a real divergence: **12 mints / 8 discharges vs 10 / 10**, and
  `12+12+8+8 = 10+10+10+10 = 40`. **A line-count equality is not a multiset equality.**
* `fence_hosts.sh` — which fixtures still DECLINE at `declineDephasingUnmarkedLoopRails`. The cheap
  way to re-home the bd `bbu0` `DEFER` instrument pin the next time its L8 trigger fires (it fired in
  this merge; see `MERGE.md` §4).

**Sweep results** — `sweep_<LABEL>_<hash16>.txt`, one per binary, all over the SAME corpus paths in
this worktree so the rows are comparable.

**Not written here, cited only:** every `loopfix/probes/*.c` program (the fix agent's and, before it,
the Rule-13 reviewer's) is re-measured on the MERGED binary rather than re-copied.

## The gate's own adversarial probe

* `g1_twofn_kb_rotated.c` — `trackT/probes/adv/r2_two_functions.c` with **one line added**,
  `y = cq_theta(y, 0.9);` in `kb()`. It tests whether the leak `r2` accepts in `kb()` (the hoisted
  TEMPLATE rail half Track T did not build, bd `1m5p`) stops being benign once the register those
  rails copy meets a post-loop non-diagonal gate — `CLAUDE.md` §5's divergent half. **It DECLINES on
  all five binaries** (ORACLE, S′, T, FIX, MERGED), and on MERGED the `!dbg` names `kb` at `:23:39`,
  the leaking read. Worth promoting to a fixture.
* `g1_twofn_kb_rotated_un.c` — its hand-unrolled twin. **It is NOT evidence for anything in this
  gate** and is committed only so the pair is complete for whoever widens the pairing to the
  template-rail half: the rolled form declines, so there is nothing to compare it against today. Its
  own measured verdict on the merged binary is recorded in `GATE.md`'s filing, not asserted here.
