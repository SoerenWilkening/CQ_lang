# Track F′ — GATES (hash-keyed; PROTOCOL.md "a gate result is a fact about a BINARY")

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

## Binaries

| role | `cq-opt` sha256 | `libCQPass.so` sha256 | note |
|---|---|---|---|
| ORACLE (read-only, `/Users/sorenwilkening/Desktop/CQ_lang/build`) | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | verified by `shasum -a 256` at track open; matches the brief |
| SUBJECT (`/Users/sorenwilkening/Desktop/CQ_F/build`) | `8cda04ca3f32bd735f9be2fd8dd468c4d8916e739c4dcbcfe303641cef44dd16` | `10c2ae8d8f2a12c8b3b4426c56d56aee2ab2b5327add7182421d24c2db5ee2c4` | one build; every row below is against it |

⚠ Source-identity check at track open, so "ORACLE" is a statement about `main` `74eabd2c` and not an
assumption: `for d in ir-pass include runtime tools; do diff -rq --exclude=... $d
/Users/sorenwilkening/Desktop/CQ_lang/$d; done` → only `__pycache__`/build artefacts differ, **no
source file differs**.

⚠ The SUBJECT binary was built BEFORE the comment-only edits to `ArmClassify.cpp`'s header and before
the fixture batch. Comments do not change the binary and the binary was NOT relinked afterwards
(CLAUDE.md: never relink under a running measurement). A rebuild at hand-off is owed and recorded
below if taken.

## Gate lines

```
build (cmake --build build -j8, BOTH targets)        | 8cda04ca3f32bd73 | 0 errors; 4 pre-existing -Wunused warnings in RegionTreeDetect/TaintPropagation, unrelated | impl | 2026-09-15 11:22
per-probe: 3 tripwire fixtures ORACLE vs SUBJECT      | 8cda04ca3f32bd73 | acyclic_nondominated_phi: F2 -> taint-escape (MOVER, intended); backedge_phidesc: F2 -> F2 (HELD); backedge_nonphidesc: F2 -> F2 (HELD) | impl | 2026-09-15 11:26
per-probe: 14 X5/r20 isolation probes ORACLE vs SUBJ  | 8cda04ca3f32bd73 | 3 MOVERS (r20, c2, c2_live), all F2 -> a later decline; 11 SAME incl. w1/w3 back-edge colliders, w1c/w3c non-M-descendant controls, w1b/w3b non-phi-only, c2c/c2c_live/c2d, and both minimal in-loop preps still ACCEPT | impl | 2026-09-15 11:34
per-probe: acc1 (dead non-dominated phi)              | 8cda04ca3f32bd73 | ORACLE exit=1 F2 / SUBJECT exit=0 -- the ACCEPT-vs-DECLINE pair bd hrts' trigger said did not exist | impl | 2026-09-15 11:52
stage 2b STRICT on acc1's lowered IR                  | 8cda04ca3f32bd73 | free_pairing_check: 1 file(s), 2 rail mint(s) of which 2 left allocated, 4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven | impl | 2026-09-15 11:53
per-probe: acc1c isolating control                    | 8cda04ca3f32bd73 | DECLINE at F2 on BOTH binaries (one operand changed; phi no longer carries an M-descendant) | impl | 2026-09-15 11:53
per-probe: acc2 (same module, phi LIVE)               | 8cda04ca3f32bd73 | ORACLE F2 / SUBJECT taint-escape -- still masked by declineClassicalMuxes, i.e. the mask is liveness | impl | 2026-09-15 11:55
per-probe: C spelling of acc1 (clang -O1 -g)          | 8cda04ca3f32bd73 | exit=0 on BOTH binaries -- -O1 DCEs the dead chain, so the recovered ACCEPT is IR-level and NOT demonstrated from C | impl | 2026-09-15 11:56
lit --filter 'acyclic_nondominated'                   | 8cda04ca3f32bd73 | Passed 4 (the converted decline, its control, the new accept, the accept's control) | impl | 2026-09-15 12:14
lit --filter 'backedge'                               | 8cda04ca3f32bd73 | Passed 4 | impl | 2026-09-15 12:05
injection matrix over the new ACCEPT fixture          | 8cda04ca3f32bd73 | 14 mutations, MISSED 0, N/A 1 (n/a-shape, the construct is absent from this module) | impl | 2026-09-15 12:15
injection matrix, empty-argv control                  | 8cda04ca3f32bd73 | exits 1 with a refusal; does NOT print a green-looking line (the 2026-09-14 hole, re-checked) | impl | 2026-09-15 12:15
```

(Rows appended below as they are run.)
collider + Truncated fixture families (17 files) ORACLE vs SUBJ | 8cda04ca3f32bd73 | ALL 17 IDENTICAL, zero movers -- the >=11 shipped merge-block colliders (range_forward_*, sideways_*, merge_edge_sideways, offwire_sideways_min, step_cap_over) AND the four |\| Truncated fixtures (step_cap_over, unfoldable_curated_call, unevaluable_pinned_operand, control_peel_reject_fp_stateprep). Rows: probes/collider_family_{oracle,subject}.txt | impl | 2026-09-15 13:05
whole stateprep fixture family (148 files) ORACLE vs SUBJ | 8cda04ca3f32bd73 | exactly 2 MOVERS, both this track's own files and both ACCEPT-direction: ..._reject_stateprep_acyclic_nondominated_phi.ll (F2 -> taint escape) and ..._stateprep_acyclic_nondominated_phi_accept.ll (F2 -> ACCEPT). The other 146 identical, including all 73 ACCEPTs and all 7 if/else stateprep fixtures. Rows: probes/stateprep_family_{oracle,subject}.txt | impl | 2026-09-15 13:12
shared vacuity.py (PROTOCOL S3)                       | 8cda04ca3f32bd73 | NOT CITED -- hardcoded to the dead worktree /Users/sorenwilkening/Desktop/CQ_mphi (FileNotFoundError), and matches only (NOX|NOFREE)-NOT with an (i32 %handle) operand, which none of this track's fixtures use; even repaired it would print `checked 0`, which S3 calls a HOLE not a pass (bd jdec). The injection matrix covers the same property with teeth (M4-M8 all caught). | impl | 2026-09-15 13:20
rebuild after the prose-only edits (cmake --build build -j8, BOTH targets) | 8cda04ca3f32bd73 | recompiled (ArmClassify.cpp.o 00:07:56, source 00:00:02, binary relinked 00:07:57) and the sha256 is BIT-IDENTICAL to the pre-edit build -- so every `8cda04ca...` citation in the fixture headers and in the rows above is a fact about the SHIPPED source, measured rather than assumed | impl | 2026-09-15 00:08
ctest -R ir-pass-lit                                  | 8cda04ca3f32bd73 | 1/1 Passed, 156.37 s (2042 fixtures, 1 XFAIL as shipped). Run under host load average ~242 (cross-track contention); contention causes false FAILURES and never false passes, so a green here is trustworthy. THIS IS THE SECOND, INDEPENDENT FLIP MEASUREMENT: every shipped fixture still matches its own CHECKs, so the only shipped expectations that moved are the ones this track converted deliberately | impl | 2026-09-15 00:14
corpus sweep ORACLE-vs-SUBJECT, FULL                  | 8cda04ca3f32bd73 | **COMPLETE: 3933/3933 rows -- 2042/2042 shipped ir-pass/test fixtures + 1891 probe modules, both binaries on the same input, decline rows compared by FULL STDERR (not a tag regex -- PROTOCOL S3). 7 MOVERS, every one named and expected (r20 x2, X5's c2 + c2_live, this track's acc1, and the 2 ir-pass/test files moved deliberately); ZERO unattributed. 1 row scored EMPTY (h0_empty.ll, 0 bytes -- the passthrough vacuity trap, deliberately not scored as an accept).** Rows: probes/corpus_8cda04ca.txt. Run under host load average 183->410 on 6 physical cores; took three attempts (serial+buffered, parallel, then parallel+resumable+fixtures-first) -- see IMPL_F2.md section 4b. | impl | 2026-09-15 01:05
