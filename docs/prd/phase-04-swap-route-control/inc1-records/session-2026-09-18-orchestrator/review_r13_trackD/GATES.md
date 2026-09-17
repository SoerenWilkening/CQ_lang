# review_r13_trackD — GATES (hash-keyed; `$SES/PROTOCOL.md` non-redundancy protocol)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <time>`

⚠ **Binaries verified on disk at review open, 2026-09-17, by `shasum -a 256`:**

```
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt                              (ORACLE, main checkout)
5ee9d14420c3533a3c8958370a3bf3c05375ff34bfa1b0f2db07a93c0989892c  .claude/worktrees/agent-ad7349188dd3b67bd/…/cq-opt (SUBJECT)
```

Both match the brief. Subject branch `drbq12-hoisted-compare-p4` tip `832ce900` — matches.
**Every `cited:` line in `trackD2/GATES.md` was re-hashed against the binary on disk: 0 stale.**

## Run by this review (reviewer runs NO build and NO suite; per-probe pipeline only)

binary-hash-check | 9bd01598d574b344 + 5ee9d14420c3533a | both match PROTOCOL/brief; `trackD2/GATES.md` cited hashes all current | review | 2026-09-17
per-probe pipeline, 24 constructed probes, BOTH binaries | 9bd01598d574b344 vs 5ee9d14420c3533a | see REVIEW.md attack table; probes in `probes/`, runner `probes/run.sh` | review | 2026-09-17
`lit -v ir-pass/test --filter 'crossblock'` (Rule-11 spot check, ≤1, SUBJECT build, no rebuild) | 5ee9d14420c3533a | `Total Discovered Tests: 2091 / Excluded 2078 / Passed 13` — 13 of 13 PASS, including the late-added `control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll` | review | 2026-09-17
corpus mover re-derivation (READ of the two committed corpus files, not a re-run) | 5ee9d14420c3533a | `corpus_5ee9d144.txt` 2090 rows → 9 movers, ALL D→A, 0 A→D, 0 A→A md5 change; `corpus_probes_5ee9d144.txt` 2464 rows → 5 movers, ALL D→A, 0 A→D, 0 A→A md5 change. **14/14 D→A confirmed independently** | review | 2026-09-17
corpus-vs-tree file-set diff | — | `ls ir-pass/test/*.ll` = **2091**, corpus = 2090; the one file absent from the sweep is `control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll` (trackD2's own, added after the sweep). F-4 | review | 2026-09-17
e2e golden byte-identity (READ, not a ctest run) | — | `diff tests/e2e/slice_control_inplace_ry_inloop_hoisted_cond.expected.log …_twin.expected.log` → empty. BYTE-IDENTICAL, 14 lines | review | 2026-09-17

## Not run — an ABSENCE, never a green

* any build, any `ctest`, `cq-opt-equivalence-full`, the twin matrices, the injection matrix,
  the full corpus sweep. All belong to the implementer / fix agent / merge-and-gate agent.
* `ctest -R ir-pass-lit` — trackD2's 3rd line (`1/1 Passed 110.66 sec, 2090 fixtures`) is cited,
  with F-4's caveat that the tree now discovers **2091**.
