# REVIEW r2B — bd `test_C_libtooling-rhk5`, ROUND 2 (surface B: declared-name / linkage vocabulary, the cache, `isCopyGate` reuse, the checker, fixture hygiene)

Rule-13 reviewer **r2B**, session 2026-09-28 (parallel). Independent of the implementer and of r2A.

| | |
|---|---|
| Subject | branch `worktree-agent-a7712272d6ca568e9`, round-2 commit `c7dad811` on round-1 `c89afa59`; diff range `c89afa59..c7dad811` |
| Subject `cq-opt` | `aa0dff29ea088cde195e222c…` (verified by `shasum -a 256` before first use) |
| Oracle (main `9a230646`) | `…/scratchpad/frozen/cq-opt.main_9a230646`, `3f6db37f5cf937b4d70f5736…` (verified) |
| Time | ~75 min; box load ~2–4 (quiet) |
| Probes | `probes/` — `checker/width_battery.py` (Q5), `ir/q2_*.ll` + `ir/q4_*.ll` (Q2/Q4), reused r1A `a3_d12.s1.ll` (Q3), reused `build.sh`/`run.sh` |

**What I ran, LITERALLY.** (1) Read the whole diff `c89afa59..c7dad811` for `ChainWalk.{h,cpp}`, `Uncomputation.cpp`, `RotationLowering.{h,cpp}`, `DagTraversal.*`, `tools/trace_twin_equiv.py`, and the 10 fixtures. (2) `python3 tools/trace_twin_equiv.py --selftest` (42/42) and re-ran r1B's `checker_mutants.py` against the NEW checker (spot-check of the implementer's claim). (3) Wrote and ran `probes/checker/width_battery.py`: 6 mixed-width non-equiv pairs + a U12 pair + a U13 pair, plus positive-EQUIV boundary controls. (4) Verified LLVM-19 `hasExactDefinition()` semantics from `GlobalValue.h`. (5) Ran the SUBJECT and ORACLE on `q2_{linkonce_odr,weak_odr,available_externally,internal,alias}.ll` and `q4_ccopy_src.ll`; stage 2b (`free_pairing_check.py`) on the admits and leaks. (6) Ran the 8 new lit fixtures through their own RUN lines on the subject; proved the LEAK-NOT/WARN prefixes LIVE by feeding the discharge stream through them. (7) `/usr/bin/time` on `a3_d12` (the cache).
**What I did NOT run.** No private build and therefore **no source mutants of my own** — I re-ran r1B's mutant script and applied the U-mutations to the *checker* (pure Python, no build). No full `lit`/`ctest`, no corpus A/B, no `e2e-loop-twin-matrix`. I did NOT reproduce RED-on-round-1 with the round-1 binary (`fa71e37a` is not in the scratchpad); instead I proved the fb5y leak fixtures LIVE by construction (below), which establishes the same thing.

## Verdict: **CLEAR-WITH-ITEMS**

**No P1.** The change's core predicate `cloneCallPreservesArg` is sound in every direction I could reach: a defined hostile callee, an interposable/derefinable twin, an alias/ifunc, a write through a controlled-copy destination, and a wrong-width copy all REFUSE (leak, matching the oracle byte-for-byte); only an exact-definition read-only body ADMITS (chain discharged, 2b `0 left dirty`). The checker's width logic reports DIFF on all 6 mixed-width non-equivalent pairs I built — **no false EQUIV found**. Four **P3** items, all coverage/hygiene, most already disclosed by the implementer.

---

## The argument, restated — and where it rests

Round 2 makes `cloneCallPreservesArg` trust a callee's NAME only when the module merely DECLARES it (the runtime ABI); a DEFINED callee must be recorded in `SpecHandleArgMask` **and walked** through (B4), or refuse; and (C1) demands `hasExactDefinition()`. The kyy1 fix wraps the interior planner in a two-layer "never worse than pre-rhk5" guard. **The entire soundness of both — including ATTACK-FIRST #1 (the ON/OFF comparison is on rail sets, not placement) and #2 (a clause-(3) piece plan) — reduces to one question: is `cloneCallPreservesArg` sound?** ON-mode placement is validated by clause (d) using that predicate; the ON/OFF superset check is only a leak-safety-net on top. So I spent the round attacking that predicate directly (Q1–Q4) and the instrument that is supposed to catch a wrong circuit if it isn't (Q5).

---

## Answers to the six questions

### Q1 — declared names / the pipeline. **No reachable path; the assumption matches the reserved-name model.**
`tests/e2e/run_slice_multi.sh` compiles every user TU to IR and `llvm-link`s them into `combined.ll` **before** the one `cq-lowering` pass (stages 1–2), so any user *definition* is visible to the pass (→ (B4) walk, or refuse — the fb5y fix). Stage 4 links **only** `libcq_templates.a` + `libcq_runtime.a` (read from the harness: `"$CQ_LD" -o slice s2.o "$TPL" "$RT"`) — **no user object**. So the ONLY residual trust the header admits — a module that *declares* a novel `cq_template_evil_i32` and supplies its body in a **separate link-time object** — is **not reachable through either shipped harness** (`run_slice.sh` links the same two archives). And a program that declares/defines a `cq_template_*`/`cqrt_*`/`__cq_*` symbol is using the reserved namespace, off CQ's model. The pass's assumption is the same boundary every emitter stands on (a user `cq_template_add_i32_hl` definition hijacks every lowering, oracle included). **Not a finding.**

### Q2 — definition kinds. **All refuse safely; verified analytically and empirically.**
`hasExactDefinition()` = `!isDeclaration() && !mayBeDerefined()` (LLVM-19 `GlobalValue.h`), and `mayBeDerefined()` is TRUE for `weak_odr`, `linkonce_odr`, `available_externally` (plus interposable `weak`/`linkonce`/`common`/`extern_weak` and `nobuiltin` defs). So the ONLY linkages it accepts are the non-derefinable ones (external/internal/private) where the walked body IS the body that runs. Measured on the subject vs the oracle (`probes/ir/q2_*.ll`, built by re-linkage-tagging the shipped `spec_leak_clone_read_weak_twin.ll` twin):

| twin linkage | subject | oracle | correct? |
|---|---|---|---|
| `linkonce_odr` | LEAK (xor_unc 0, warns) | LEAK | ✔ (conservative) |
| `weak_odr` | LEAK | LEAK | ✔ |
| `available_externally` | LEAK | LEAK | ✔ |
| `alias`→internal | LEAK (no crash) | — | ✔ (called-operand is a `GlobalAlias`, not a `Function` → refuse) |
| `internal` | **ADMIT** (xor_unc 2, no warn, 2b `0 dirty`) | LEAK | ✔ (the intended rhk5 win) |

`ifunc` and a call through a `ptrtoint`/`bitcast`/`select`/`phi` of function pointers behave like the alias: `dyn_cast<Function>(C->getCalledOperand())` is null → refuse. All refusals are the safe (leak) direction. The TRACK §R2.7 claim that weak_odr/linkonce_odr are refused is **correct** (I verified the LLVM semantics rather than trusting it). Repro: `build/ir-pass/cq-opt -passes=cq-lowering -S probes/ir/q2_linkonce_odr.ll` (leak) vs `…q2_internal.ll` (admit).

### Q3 — the cache. **Sound.** Key = `(Function*, ArgNo)`; lifetime = ONE query (`ProofCtx Ctx` is local to `cloneCallPreservesArg`). (a) *Different argument slot* → different key (`ArgNo` is in the key), and label-preservation of a formal is a property of the body alone, independent of the caller's argument, so a `(F,slot)→Yes` is valid at every call site within the query. (b) *Verdict produced while a cycle is open* → `NoProvisional`, and the write is guarded by `if (Res != Proof::NoProvisional)` — cycle/cap refusals are never memoized. (c) *Body modified between two queries* → impossible to reuse: the memo does not survive a query, and clone bodies are final before `uncompute`. (d) *Stops at first refusal*: `clonePassPreserves` returns `P` on the first non-`Yes` per-slot; `formalLabelPreserved` `break`s on the first refusal; the refusal propagates upward through the conjunction (a `Yes` can never sit above a refusal). Cost: `a3_d12` (r1A's exponential probe) is **0.23 s user** on the round-2 subject (was 17.84 s on round 1). tcpq fixed.

### Q4 — `isCopyGate` reuse. **Answers the right question for every copy family.** `isCopyGate` = `void ∧ name.starts_with("cqrt_copy_") ∧ (arity 2 ∨ 3)`, width-agnostic; the B3 clause then reads "the LAST operand is written": `Slot != Last ∧ arg[Last] != A → admit`. Plain (`cqrt_copy_i32`, arity 2, dst=slot 1), controlled (`…_controlled`, arity 3, dst=slot 2), `_Bool` (`cqrt_copy_i1[_controlled]`) and fp (`cqrt_copy_f{16,32,64,80}[_controlled]`) all match by prefix+arity and are handled uniformly. Pinned in both directions: `spec_leak_clone_read_twin_copy_dst.ll` (formal as a controlled-copy **destination** → refuse, verified) and my `probes/ir/q4_ccopy_src.ll` (formal as a controlled-copy **source**, slot 1 → **ADMIT**, subject 2b `0 dirty`). The `src==dst` case is subsumed: if `src==dst==A` then `A` is the destination → caught. Sound.

### Q5 — the checker. **Width logic sound; U12 and U13 are UNPINNED-but-sound, not "equivalent".**
Re-ran r1B's `checker_mutants.py` against the new checker: **U1, U5, U12, U13 survive** (selftest GREEN, no gate flip) — matches §R2.2. U3/U6–U11/U14 RED (killed by the adopted controls), as claimed.

My 6 new mixed-width non-equivalent pairs (`probes/checker/width_battery.py`) ALL report **DIFF** on the shipped checker (positive-EQUIV boundary controls in the same run return EQUIV, so the harness can distinguish): `W1` zext i8→i32 with an i8 copy; `W2` trunc i64→i32 with an i64 copy; `W3` compare (i1) with an i32 copy; `W4` rule-2 recompute with a wide copy; `W5` fp `fptrunc` f32-result with an f64 copy; `W6` sext-vs-zext same widths. **No false EQUIV.** `result_width()` reads the cast `_to_<W>` first, then `i1` for compares, then the first `_<W>` — correct for the whole template grammar.

For U1/U5/U12/U13 (the implementer's §R2.6 says "argued equivalent by r1B; no controls added"):
- **U12** (measure classified as READ instead of WRITE) — **a real, pinnable blind spot, NOT equivalent.** My `U12_measure_past_copysrc` pair (a `cqrt_measure_i32(h0)` reordered past a `cqrt_copy_i32(h0,·)` that reads `h0`) is **DIFF** on the shipped checker (measure is a barrier) and **EQUIV** under U12. A collapse is not a read; the shipped classification is correct but no control defends it.
- **U13** (renaming injectivity, `elif y in bwd`) — **also a real, pinnable blind spot.** My `cqrt_cnot(h0,h1); cqrt_cnot(h0,h2)` (two distinct targets) vs `…(h0,h1); …(h0,h1)` (one target twice) is **DIFF** shipped, **EQUIV** under U13. (My first alloc-first attempt was defeated by the mint's forward-consistency binding — injectivity is only load-bearing when handles are not bound before the colliding gate; the cnot pair reaches it.)
- **U1/U5** (the `len(ua)!=4`/`uc[1]!=j` narrowness conjuncts of `contract()`) — unpinned, but **sound on real compiler traces**: the scratch rail is used by exactly its 4 Bennett lines, and downstream checks reject the relaxed cases, so no real subject/twin pair exploits them.

So U12/U13 are **not "equivalent"** — they are correct conjuncts with **no control**, and the checker is an e2e GATE. See F-r2B-1.

### Q6 — fixture hygiene. **Pure negatives, LIVE; one caveat.** No `CHECK-COUNT` in any `spec_leak_clone_*` fixture (Rule-12a clean). The LEAK-NOT lines are LIVE, proved by mutation: feeding the ADMIT stream (`q2_internal.sub.ll`, which contains `xor_i32_unc`) through `spec_leak_clone_read_defined_template_name.ll --check-prefix=LEAK` makes FileCheck **fail** (`error: LEAK-NOT: excluded string found`). The WARN prefix fails against empty stderr. These are warn+exit-0 cases (stdout carries the IR), so the checks are not the vacuous-decline trap (Rule-12b). **This also establishes RED-on-round-1 for the fb5y fixtures without the round-1 binary**: round 1 produced exactly that admit stream. **Caveat (F-r2B-3):** `spec_leak_clone_read_twin_cycle.ll` and `spec_leak_clone_read_depth_cap.ll` PASS on the oracle, round 1 AND round 2 (the leak is on all three) — they do not distinguish the fix and are pinned only by out-of-tree mutants R3/R4.

---

## Findings

### F-r2B-1 — **P3, INTRODUCED** — the checker's `measure`-as-write (U12) and renaming-injectivity (U13) conjuncts are load-bearing but pinned by NO control; the record calls them "equivalent", which is imprecise
`tools/trace_twin_equiv.py` is the `*-twin-equivalent` e2e GATE — the only instrument that can catch a wrong *circuit* the 2b census and trace-diff miss. Two of its soundness conjuncts have no boundary control: measure-as-collapse (U12) and the reverse-injectivity of the handle renaming (U13). I constructed non-equivalent trace pairs that the shipped checker correctly calls DIFF but each mutant calls EQUIV (`probes/checker/width_battery.py` rows `U12_measure_past_copysrc`, `U13_injectivity`; and the alloc-free/cnot U13 pair in the round log). A future edit to `effects()` or `bind()` could silently break either and let a real divergence pass the gate. This is the `e1gr` shape. **Fix:** adopt my two pairs (and the U1/U5 narrowness pairs) as CONTROLS, exactly as r1B's A9/A12/A22–A28 were adopted. **Grade P3** because the shipped checker is correct on all of them today (no current false EQUIV). Repro: `python3 tools/trace_twin_equiv.py … ` via `probes/checker/width_battery.py` (all DIFF); apply the U12/U13 one-line mutations from r1B's `checker_mutants.py` and the same pairs flip to EQUIV.

### F-r2B-2 — **P3, PRE-EXISTING** — U1/U5 (the contraction narrowness conjuncts) are also unpinned
`if len(ua) != 4 …` / `if len(uc) != 4 or uc[1] != j` in `contract()`. Relaxing either leaves the selftest green. Sound on real compiler output (the scratch rail's use-set is exactly the 4 Bennett lines), so lower concern than F-r2B-1. Adopt a crafted trace with an extra scratch read as a control if these are ever load-bearing.

### F-r2B-3 — **P3, INTRODUCED** — two leak fixtures do not distinguish the fix and rest on an out-of-tree mutant matrix
`spec_leak_clone_read_twin_cycle.ll`, `spec_leak_clone_read_depth_cap.ll` are GREEN on oracle, round 1 and round 2 (`§R2.3` agrees). Their protection is entirely `tools/mutants_r2.py` R3/R4, which is **not a ctest gate**. If the cycle/depth-cap conjuncts regress, the shipped suite stays green. Test debt; acknowledged by the implementer. (The subjects exist and are not vacuous — Rule-12c clean.)

### F-r2B-4 — **P3, INTRODUCED (disclosed)** — the layer-(2) function-level backstop is unpinned (mutant R9 survives)
`collectInteriorPlans`' ON/OFF superset comparison changes no module in the tree (R9 removes it, 0 movers over 3,384 modules — §R2.5). Its distinguishing input (a clause-(3) piece plan dropping an outer plan via the cross-plan ordering check) is argued, not constructed. It is the SAFE direction (falls back to the pre-rhk5 planner), so P3, and the implementer disclosed it. I could not construct the distinguishing input either in the time budget; noting it so the orchestrator counts it as attacked-not-broken rather than covered.

---

## What I attacked and did NOT break
- **The fb5y core**: defined hostile callee (fixture), interposable/derefinable twin (weak_odr/linkonce_odr/available_externally — all leak), alias-resolved twin (leak, no crash). Only exact-definition read-only bodies admit.
- **Controlled/fp/i1 copy handling** via `isCopyGate`: source/control admit, destination refuses.
- **The memo**: no cross-slot, cross-query, or cycle-poisoning reuse; short-circuits at first refusal; `a3_d12` 0.23 s.
- **The checker's width logic**: 6 mixed-width non-equiv pairs, all DIFF — no false EQUIV.
- **The ON/OFF kyy1 guard**: reduces to `cloneCallPreservesArg` soundness (validated) plus a conservative superset check; ATTACK-FIRST #1/#2 not exhibited.
- **L1** (round-2 taint delta): `cloneCallPreservesArg` records nothing and reads bodies + `SpecHandleArgMask` at ask time, after both control rounds; the round-2 diff adds no inter-round computation. Clean (matches r1A).
- **L7**: the TRACK §R2.7 weak_odr/linkonce_odr claim and the `hasExactDefinition` header wording are both correct (verified against LLVM source), and the "Nothing is read off the NAME" sentence was already corrected at the source.

## Beads
None filed (all four items are P3 coverage/hygiene, three already disclosed by the implementer). If the orchestrator wants F-r2B-1 tracked, it is the `e1gr`-family checker-control gap; my controls are in `probes/checker/width_battery.py`.
