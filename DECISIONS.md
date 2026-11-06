# Decisions

One line per decision on what CQ_spec leaves open. OWNER-FLAG: we proceed on it, the owner should rule.

## Flat memory move (2026-11-05, CQ_spec bff98cb)

- Layout: `pass/lib/bus/` + `pass/include/cq/Bus.h` (namespace `cq::bus`) replace mem/, fatptr/, Memory.h, FatPtr.h; Taint keeps only the host-resident fixpoint; `checker/rt/rt_bus.c` replaces rt_mem.c; `bundle/host/cq_host.c` holds the `__cq_*` host symbols.
- Removal: big-bang cut with loud `cq: unimplemented: bus:` stubs so the tree builds and non-bus examples keep lowering; no old code behind a flag.
- Order: evaluator validated on the references first (`tools/ref_as_ours.py`), then bus core, then in-place / alloc / calls / loops in parallel, then clone table and effects, then musl.
- Q1: all example directories are binding witnesses; §7's "owed" table is stale (SPEC_ISSUES); a reference that disagrees with its C program or with CR text is a SPEC_ISSUES entry, never skipped, never copied.
- Q2: OWNER RULED 2026-11-05, reading accepted, CQ_spec §0 gets it — module identity iff no CQ.h primitive call, no root list, no declared-clone reference (contradicts §0 "every body is lowered" for the CQ-free module only); inside a lowered module every function is rewritten unless it has no non-host-resident memory access, no cq_* call and no call (rule 19; 195 bump, 197 tab_set rewritten, 211 inc kept).
- Q3: DECIDED — "measures" in rule 18 means a tainted measurement (under a quantum predicate or in a _ctl clone); a classical-path measurement returns a seed and the clone keeps its twin (rule 2); SPEC_ISSUES asks rule 18 to say so.
- Q4: DECIDED — rule 5 sentence 3 as written (212): the caller uncomputes/frees what it minted after the twin; 102's extra kept rails are a SPEC_ISSUES entry, not copied.
- Q5: DECIDED — 175 needs musl libm in the v1 bundle (rule 18 "injected source"); a bodiless callee on no root list is rule 16, never an implicit declared clone (rule 27, §0); rule 18's "declared clone otherwise" and CLAUDE.md's bundle text are stale.
- Q6: DECIDED — roots are a cqcc input (`--cq-roots`); corpus table: `roots=` in drivers.txt, 161 ext_fn, 190 ext_sink; the stand-in is the checker's.
- Q7: DECIDED — `__cq_mem/__cq_alloc/__cq_clone_*/__cq_sig` are a runtime object linked after the pass, never lowered; the pre-pass bundle holds only bodies to lift.
- Q8: DECIDED — compare the event sequence (name, fields, predicate, order) per input on both oracles with the §6 stand-in; result rails of deferred outputs are a stated deviation, excluded only against C.
- Q9: DECIDED — rule 16 as written; host-made blocks are a recorded deviation, no provenance check.
- Q10: DECIDED — the aliasing call is out of the C-oracle domain (UB), compared against the reference only.
- Q11: OWNER RULED 2026-11-05, reading accepted, CQ_spec rule 16 gets it — `llvm.va_copy` is a rule-22 24-byte copy when a side is bus-resident (109), against rule 16's "as it stands".
- Q12: DECIDED — recursion is cut at K (rule 14, 98); min(K, B) is for loops; rule 27's wording is a SPEC_ISSUES nit.
- Q13: DECIDED — the controlled copy is under the _ctl clone's formal predicate; an arm inside the clone adds no conjunction (rules 2, 9).
- Q14: DECIDED — "memory(none) or memory(read)" means LLVM onlyReadsMemory/doesNotAccessMemory; any possibly-writing effect is a version change.
- Q15: DECIDED — exit-test loads under the reaching predicate in every quantum-exit case (117); two exit tests per trip: a_K after the K-th latch, no extra header test (189).
- Q16: DECIDED — the C oracle rewrites allocations and allocas to a zeroing never-reusing allocator and drops lifetime markers; drivers pre-zero the stack so host-resident uninitialized reads agree by construction.
- Q17: DECIDED — Ry breaks classical-valuedness (ABI §0 definition); extra handles are trailing outs (verify on 162/193); rule 16's full ordinary-call test governs.
- A (109): DECIDED — `s` is a rule-6 image, kept with role `rule6_image`; the evaluator marks images on every observed rule-6 clean; no frozen carry across the bus; SPEC_ISSUES: rule 6 to name the uncleaned second operand.
- B (203): DECIDED — an unreached trip target without proof stays MISSING/`error`, never FAIL, dead or UNCOVERED without a budget stop; a bound is proved by trip facts on the O1.ll linked with the driver's bodies at -O1.
- C (cq-kzfv): DECIDED — CR wins: excess printf arguments are the format entry's fields and ignored; the evaluator splits by the callee's known arity; an unknown callee after a surplus is a SPEC_ISSUES entry.
- D (cq-ytux): DECIDED — INPUT bytes are classical bus stores (ABI 1.10), so fgets overwrites QUANTUM cells as C does; rt_tape.c's host_write was a bug.
- Stops: OWNER RULED 2026-11-05: no-fence stands. Old `unimplemented()` sites stay no-ops, new code does not stop either; no fatal error, guard or decline for an unbuilt shape; `noteUnbuilt` writes one non-fatal log line naming the site; the checker decides correctness.
- cq-fti6: DECIDED — quantum-length copy under c: per-byte `t = and_i1(p_j, c)` kept, `p_j` undone in-trip; overflow is `(n > K2) & c` kept, raw `icmp_ugt_i64_hl(n, K2)` undone at once (raw would read 1 on an untaken arm).
- cq-ssyq: DECIDED — `load i8 !range [0,2)`: trunc user → access at the truncated width; icmp eq/ne against another `[0,2)` load → i1 (xor_i1); otherwise the load's own i8. Current code stays; 114 `%71` (i1, "SPEC GAP 2") goes to SPEC_ISSUES and runs `--oracle c`.
- cq-5aus: DECIDED — a kept flag holds the IR SSA value: the X bracket always closes (rule 8), the closing `not_i1` placed after the flag's last reader; 55 keeps `m < 0`, no SPEC_ISSUES entry.
- pthread_join: DECIDED — keep Conc.cpp's result store: a join with a non-null result writes `*t` then `*r`; a null join stays nothing (106). Owner note: CR wording should add "unless a join reads the result".
- table-twin: DECIDED — a table clone's twins do nothing only for a tainted measurement (any measurement for `_t_ctl`, a quantum-predicated one for `_t`); a classical-path measure in `_t` gets the rule-18 twin (recompute via `_pure`, re-read with `measure_<W>`, zero and free non-seed results, seed left allocated); 211 unchanged.
- cq-eoru: DECIDED — a function that mints a register in a loop, or calls a rotating callee in a loop or on a call cycle, joins rule 18's no-twin list (propagated to callers); results kept; `_t` pushes per mint, `_t_unc` pops only.
- cq-9kcq: DECIDED — received K is run-time: `_t`, `_t_ctl` and twins use the K parameter, save/set/restore `@__cq_k`; functions reachable by name from a table body use `select(k != 0, k, static)`; elsewhere static first-match. Staged after the loop work; §6 at K=4 cannot witness it.
- cq-orua: DECIDED — per-function fact per CR's fixpoint wording: a by-name callee of a table clone is called after an event unconditionally, direct path included; `propagateEvents` runs the table-caller propagation before its early return.
- cq-9kcq stage: rolling the K-loops (Cutoff::lowerLoop, about 1400 lines) deferred until the sweep shows how many rows the module-size cap costs; §6 at K=4 cannot witness run-time K, so no verdict depends on it. Orchestrator call, 2026-11-06.
- cq-6b2i1: DECIDED (Fable, option b) — observable `volatile` goes on the bus through the `_hl` / rail-column access; the overlay makes it a host access for a HOST cell and a correct one for a QUANTUM cell; no `volatile_store`/`volatile_load` entries; a load under a quantum predicate is executed unguarded and merged; deviation from rule 24 "never on the bus" logged in SPEC_ISSUES.
- cq-t2jj2: DECIDED (Fable, reading a) — a `_t` clone measures a fresh copy of its formal (`alloc`, `copy`, `measure`), as `_t_ctl` with the predicate true; the copy is the measured rail, the caller uncomputes and frees its actual as today; §1.4 and 211's `_t` text logged in SPEC_ISSUES.
- Owner rulings at CQ_spec 4d08ffa: cq-6ucw option (i) (effect entries carry field count n); cq-6b2i1 accepted (observable volatile is rule 20's bus access through the overlay, entries gone from rule 24); cq-bj01 (a classical address that is a getelementptr/cast chain over values live at the first change is computable there; d is the AND of the run-time tests).
- cq-t2jj2 after 4d08ffa: rule 18's text settles the outcome, not the copy: `_t` still measures a kept copy of its formal (§6, meas_table_t; SPEC_ISSUES), but the outcome is classical (a seed) and `_t` keeps its rule-18 twin, replacing "as `_t_ctl` with the predicate true" above; `_t` pushes the copy, `_t_unc` pops and re-reads it; a copy per trip leaves no twin (cq-eoru's reasoning).
