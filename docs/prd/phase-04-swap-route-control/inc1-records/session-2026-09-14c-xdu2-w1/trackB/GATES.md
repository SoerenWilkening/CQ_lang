# GATES — Track B (bd `xdu2` / L-1a clause C5, the per-activation promoter)

`PROTOCOL.md` line format:

```
<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
```

**A gate result is a fact about a BINARY, not about a moment.** Before running any gate, read this file:
if the binary hash is unchanged and the gate is recorded, cite the line instead of re-running it. A
cited line whose hash does not match the binary on disk is a FINDING.

**ORACLE (read-only, frozen, never rebuilt by this track):**
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
sha256 `5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`,
`libCQPass.so` `5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`.
Verified with `shasum -a 256` before the first probe and unchanged after the last.

---

```
oracle-hash-verify          | 5c6f7490a81c7505 | matches the brief; libCQPass.so 5276f7ab7416b36b | impl | 2026-09-14 18:10
baseline-build-of-worktree  | 5c6f7490a81c7505 | BIT-IDENTICAL to the ORACLE before any edit (cq-opt AND libCQPass.so) | impl | 2026-09-14 18:14
lit --filter railbank_ (RED) | 5c6f7490a81c7505 | 1 FAIL — the first positive fixture fails on the unmodified pass (red-green) | impl | 2026-09-14 18:22
corpus sweep ir-pass/test (dev) | 522cc8af0a2d59b0 | 1995 rows, 0 movers (exit + full stderr + lowered-IR md5) | impl | 2026-09-14 19:05
injection matrix ROUND 1     | 522cc8af0a2d59b0 | 12 mutants, 0 N/A, MISSED=7 — every miss a SECOND clause refusing the same shape | impl | 2026-09-14 20:10
injection matrix ROUND 2     | 9846bca0bf23a01e | 7 combined mutants, 0 N/A, MISSED=2 | impl | 2026-09-14 21:05
injection matrix ROUND 3     | 9846bca0bf23a01e | 2 mutants on two rewritten probes, 0 N/A, MISSED=0 | impl | 2026-09-14 21:35
injection matrix ROUND 4     | 9846bca0bf23a01e | M13 (re-add the !cq.railbank mint): CAUGHT by all 7 accept fixtures | impl | 2026-09-14 22:05
P10 armWritesMemory measurement | (temporary AUDIT build, reverted) | 6 bank modules, promoter OFF and ON: ZERO audit lines — MergePhiPeel is never reached. Controls fired P1/P10-asked/P10-passed and P10-REFUSED, so the lever was live | impl | 2026-09-14 21:50
lit --filter railbank_       | 9846bca0bf23a01e | 20/20 PASS | impl | 2026-09-14 22:10
ctest -R ir-pass-lit         | 9846bca0bf23a01e | Passed 64.03 sec; `lit ir-pass/test` = 2013 passed, 1 expectedly failed, of 2014 | impl | 2026-09-14 22:15
corpus sweep ORACLE-vs-SUBJECT | 9846bca0bf23a01e | 4725 rows (3680 committed .ll + 1045 stage-1 from .c probes), 0 MOVERS | impl | 2026-09-14 22:20
trackL probe matrix          | 9846bca0bf23a01e | 34 probes, 8 promoted, 0 verdict movers, 0 !dbg movers | impl | 2026-09-14 22:25
```

**NOT RUN, deliberately, per the PROTOCOL matrix's implementation column:** the full `ctest -j6`,
`ctest -R '^e2e-'`, `cq-opt-equivalence-full`, and the twin matrices. Those are the merge-and-gate
agent's, once per GROUP.

⚠ **Track B and Track A are in the SAME GROUP** (PROTOCOL S1): both touch files under `ir-pass/`, and
at merge Track A's `railBankCarveVerdict` REPLACES this branch's `RailBankCarveShim.cpp` — a
duplicate-symbol link error if it is not deleted. One combined gate, not two.

⚠ The baseline line above is worth more than it looks: every oracle-vs-subject row this track reports is
a comparison against a binary this worktree reproduces byte-for-byte, not merely against "a build of the
same commit".

