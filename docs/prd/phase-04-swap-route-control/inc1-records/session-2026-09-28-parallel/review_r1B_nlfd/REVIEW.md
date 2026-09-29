# Rule-13 review r1B — bd `test_C_libtooling-ev3m` (commit B) and bd `test_C_libtooling-m5pn` (commit C)

Reviewer r1B, session 2026-09-28-parallel. Independent adversarial round (CLAUDE.md Rule 13) of
commits B and C of branch `worktree-agent-a333a1777db2f2295`. Reviewer r1A covers commit A (bd nlfd).
UNCOMMITTED record.

| item | value |
|---|---|
| diff range | `a6a76840..3626a38d` (B `1008dbe3` = the drop no longer refuses a `musttail` site; C `3626a38d` = `stripStaleClassicalAttrs` demotes a `musttail` call in a clone body to no tail kind) |
| SUBJECT `cq-opt` | worktree `build/ir-pass/cq-opt`, sha-256 `93c65d0da41df3fc52ddc45eafb7b26d5ed2e92e5242a473ad53b5ea13fb1ea8` (A+B+C) |
| ORACLE | `<scratchpad>/frozen/cq-opt.main_9a230646` (`3f6db37f5cf937b4…`) |
| COMPOSED (mine) | private worktree `<scratchpad>/rev_r1B_ev3m` = `3626a38d` + merge of rhk5 round 2 `c7dad811` (merge commit `ce40ec1e`; two textual conflicts, `tests/e2e/CMakeLists.txt` and `CODE_MAP.md`, both "each side appended entries", resolved as the union; no source conflict). `cq-opt` `31adc6af595c72df8e44ab2b…`, copied to `<scratchpad>/r1B_bin/cq-opt.composed` before any measurement |
| rhk5 r2 alone | `agent-a7712272d6ca568e9/build/ir-pass/cq-opt` `aa0dff29ea088cde…`, copied to `<scratchpad>/r1B_bin/cq-opt.rhk5r2` (read-only use) |
| time | ~85 min, box load average 57–107 throughout (other agents); `-j4` max |

**What I ran, literally.** `probes/run_r1B.sh` reproduces every row below (`rv.sh` = lower with rc taken
from `cq-opt` itself → `tools/free_pairing_check.py` STRICT + CENSUS → link templates-before-runtime →
run; `eq.sh` = `cmp` + rhk5's `tools/trace_twin_equiv.py`, read from the rhk5 worktree). Every `.c`
probe takes its runtime value from `atoi(argv[1])`; 2-TU probes use the `run_slice_multi.sh` recipe.
- ~95 lowered modules on O / S (and C / R where stated): the implementer's `mtl`/`ev7`/`ev9`/`mm1`
  families re-run from their sources, plus my own Q1 IR battery (21 modules), Q2 C/IR battery
  (c4, d1/d2/d2m/d3, b1, f1, f2, i1, n1, r1, r2, c1, c3, pa, pa2), Q4 battery (s1, s2, j1).
- Spot-check of one implementer sweep: `lit -j4 ir-pass/test --filter musttail` on the SUBJECT build:
  **2418 discovered, 6 passed, 2412 excluded** (matches §9/§10).
- Composition: full `lit -j4 -q ir-pass/test` on the COMPOSED build: **2437 discovered, rc 0**.
- One mutant (M2) with boundary controls, full `lit` on the composed tree (§Mutants).

**NOT run:** the implementer's corpus A/B, census, allocator sweeps, mutation matrix (read, not
re-run); full `ctest`; the new e2e slices through `ctest` (their programs were not re-run as slices;
the implementer's golden claims are unverified by me); `cq-opt-equivalence`; `+Asserts`; Guard Malloc.
Commit A (r1A's surface) was not reviewed beyond what B/C touch.

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1, 1 P2, 4 P3

B and C are sound in everything I could construct: every `musttail` spelling I built is byte-identical
to its plain-`tail` spelling on the ORACLE (or declines identically), and B's constant operand keeps
every LLVM-19 `musttail` verifier rule. The P2 is about the **stop-and-ask record, not the code**: B
and C also route `musttail` spellings into a **second** pre-existing warned class (bd `ffir`) that §5
does not name, and **landing rhk5 first does NOT clean those** (measured on the composed binary).

## Soundness argument, restated — and the step that was asserted

- **(B)** The drop replaces a dead-slot OPERAND by a constant. LLVM 19's `verifyMustTailCall` compares
  the caller's and the call's function types, calling conventions, and ABI-impacting parameter
  attributes, and requires `call; [bitcast;] ret <call>` adjacency. None of those reads an operand
  value, the drop's strip touches only `range`/`nofpclass`, and it inserts nothing. The operand's
  dead cone is necessarily defined BEFORE the call (SSA dominance), so the question "does the clean-up
  of an operand computed between the call and `ret` break adjacency" has no subject: only a bitcast OF
  THE CALL may sit there. Asserted-not-measured in the record: the `inreg`/`tailcc`/`swifttailcc`/
  `byval` cases and the `deleteDeadCones` fold near a `musttail` block. **Measured here (Q1): all
  hold.**
- **(C)** "`musttail` guarantees only the tail-call LOWERING; the call, its operands and its result are
  unchanged by dropping it." Asserted. **Measured here: true on every reachable spelling, FALSE for a
  `preallocated` argument** (F-r1B-2, IR-only). The comment's second reason ("the fp→i32 rewrite
  changes prototypes") is **unmeasured and not what aborts** (F-r1B-4).

## Findings

### F-r1B-1 — P2 — INTRODUCED population growth of a PRE-EXISTING warned class (bd `ffir`) that §5 does not name and that landing rhk5 first does NOT discharge

§5 says B and C add `musttail` customers to bd `rhk5`, and the proposed landing order is rhk5 first.
For §5's three probes that is right (Q3 below: `ev9`/`ev7`/`mtl` become clean on the composed
binary). But B and C also make `musttail` spellings compile into bd **`ffir`**'s class — a
QUANTUM-returning clone's copy-out rail consumed by a phase and **never uncomputed** before a later
`Ry` on its argument (`warning: … non-diagonal gate over a live derived record`, a Rule-8 dephasing
relative to the twin, which uncomputes its record; bd `ffir` is an OPEN owner question on whether the
lyyf-(B) ruling covers a compiler-kept record). rhk5 round 2 does not touch it.

| probe | commit | ORACLE | SUBJECT | SUBJECT vs plain-`tail` on ORACLE | COMPOSED (with rhk5 r2) | twin (all binaries) |
|---|---|---|---|---|---|---|
| `q2/b1` — `f` ends `musttail return h2(t, z)`, `h2` ignores `t` (volatile-fold arm), `t = g(q,k)` a quantum clone result read only by `if (t == 9) cq_phi(π)`, then `Ry(q)` | B | DECLINE (3jru) | exit 0, **warn 1, 1 dirty**, 13 lines | byte-IDENT to `b1N` | **same: warn 1, 1 dirty, DIFF vs twin** | `b1T`: warn 0, 0 dirty, 11 lines |
| `q2/d2m` — `h(a,k){ musttail return h2(a,k); }`, `h2 = a + k`; `main`: `r = h(q,m); if (r == 9) cq_phi(π); q = Ry(q)` | C | **ABORT 134** | exit 0, **warn 1, 1 dirty**, 20 lines | byte-IDENT to `d2` | **same** | `c4T`: warn 0, 0 dirty, 11 lines |
| `q2/c4` — same `main`, 3-deep `musttail` chain `h → h1 → h2` | C | **ABORT 134** | exit 0, **warn 1, 1 dirty**, 34 lines | byte-IDENT to `c4N` | **same** | `c4T` |

The class is pre-existing for the plain spelling at every depth, no `musttail` needed (`q2/d1`,
`d2`, `d3`: warn 1, 1 dirty on O, S and C alike). `b1`'s stream against its twin, side by side: the
subject mints `alloc h2; copy(h1,h2); add_unc(h1); free(h1)` and then leaves `h2` (= a copy of
`q + k`) allocated across `cqrt_ry_i32(h0, 0.7)`; the twin runs `add_unc(h1, h0, k); free(h1)` before
the Ry.

*"Pre-existing" is true of the defect and FALSE of its population* — the same shape as §5, for a
different bead. **Consequence for the landing decision (Q2 in §15):** the rhk5-first order discharges
§5's rhk5 customers but not these; B+C still grow bd `ffir`'s population (from DECLINE/ABORT to a
warned exit-0 stream), which is the owner's call exactly as §5 frames rhk5's. Record it on bd `ffir`
and in §5; no code change is implied (the fix, if any, is ffir's).

Repro: `cd probes/q2 && ../build.sh b1 && for t in O S C; do ../rv.sh $t b1.s1.ll 5; done` (likewise
`b1N`, `b1T`, `d2m`, `d2`, `c4`, `c4N`, `c4T`); `../eq.sh S b1 b1N O; ../eq.sh C b1 b1T`.

### F-r1B-2 — P3 — PRE-EXISTING residual, IR-only: the demotion cannot legalise a `musttail` that forwards a `preallocated` argument, and the comment's universal claim is false for it

LLVM 19's verifier requires a call with a `preallocated` argument to carry the `"preallocated"`
operand bundle **XOR** be `musttail`. `probes/q2/pa2.ll` (`h(ptr preallocated(i32) %s, i32 %a) {
musttail return h2(%s, %a) }`, `h2` reads `a`): ORACLE aborts (`musttail call must precede a ret` AND
`preallocated operand either requires a preallocated bundle or the call to be musttail`); SUBJECT and
COMPOSED abort with the second message only (exit 134). So m5pn is fixed for every argument kind
except `preallocated` (and, by the same token, an `inalloca` perfect-forward is legal IR after
demotion only because the verifier checks `inalloca` provenance only when the operand is an
`alloca`). Not C-reachable on this target (clang emits `preallocated`/`inalloca` only for the 32-bit
Windows C++ ABI), which is why this is P3. The text in `SpecializeClone.cpp` — "`musttail` guarantees
only the tail-call LOWERING; the call, its operands and its result are unchanged by dropping it" —
should say "for every argument kind the pass can see from C; a `preallocated`/`inalloca` forward is
the exception", or the clone path should decline such a body loudly. Repro: `cd probes/q2 && for t in
O S C; do ../rv.sh $t pa2.ll 5; done; grep preallocated <scratchpad>/r1B_out/pa2.S.s2.ll.err`.

### F-r1B-3 — P3 — INTRODUCED (by C): three records say the in-clone `musttail` slot is still the subject of `spec_accept_phantom_arg_read_musttail_inner_slot.ll`; after C it cannot be

`cloneFor` calls `stripStaleClassicalAttrs` at clone creation, the first statement of `buildClone`
(`Specialization.cpp:845`), before `seedClone`, `lowerCloneControl`, the inner-call worklist and every
liveness/record question. So from commit C on, **no slot question is ever asked of a `musttail` call
inside a clone** — the w7nm mechanism (a `musttail` slot counted as a read) is structurally retired
twice (B removed the refusal, C removed the marker). The re-spelled fixture still pins the generic
inner-slot neutralisation for a PLAIN call, which is worth keeping, but three places claim more:
the fixture header ("so the in-clone `musttail` slot is still the subject"), the `tests/e2e/
CMakeLists.txt` comment and the `slice_spec_dropped_arg_musttail_inner.c` header ("the in-clone
`musttail` slot it was written for is pinned only at IR level, by …"). The fixture's own "the CLONE
line matches either spelling" shows the implementer saw half of this. L7-with-a-twist: fix the three
sentences at the source.

### F-r1B-4 — P3 — INTRODUCED comment: the "fp→i32 rewrite changes prototypes" reason for the demotion is unmeasured, and on the reachable surface it is not what aborts

`SpecializeClone.h`/`.cpp` give two reasons a kept `musttail` aborts: code after the call, and
`cloneFor`'s fp→i32 prototype rewrite. The second never bites a reachable program: when a clone's
inner call is retargeted to a clone whose return type differs, `retargetSite` REPLACES the call with
a fresh `CreateCall` (no tail kind), and when the prototypes are unchanged `setCalledFunction` keeps
matching types. Measured: `probes/q2/f1` (`double h(double a,double k){ musttail return h2(a,k); }`,
`h2 = a + k`, a quantum `double`) compiles on the **ORACLE** at exit 0, byte-identical to its
plain-`tail` spelling `f1N`, with no `musttail` in either clone. The abort is only "code after the
call". Correct the sentence (L7).

### F-r1B-5 — P3 — no e2e layer links a demoted clone; the demotion fixture lacks its L8 trigger, and one of its lines goes stale when rhk5 lands

After B the `musttail-inner` e2e pair witnesses the DROP, so commit C's accept is pinned only by the
CLONE lines of `spec_accept_musttail_in_clone_demoted.ll` (mutant D1 kills it by ABORT). That was the
right call while `main`'s stream is rhk5's wrong one (bd jlf8). But on the COMPOSED binary `mtl`
(= that fixture's program) is **clean and twin-equivalent** (warn 0, 0 dirty, 2b STRICT `6 verified,
0 violation(s), 0 unproven`, `trace_twin_equiv` EQUIV vs `mtlT`), so once rhk5 lands the reason for
not pinning `main` is gone. The header should carry the trigger ("when bd rhk5 lands, pin `main`'s
stream and add a linked slice with a twin-equivalence gate"); and its trailing comment "(stderr also
carries 1 warning line(s) — the ORACLE's …)" is false on the composed binary (0 warnings — harmless
to the RUN lines, which do not check stderr, but it will mislead).

## Questions from the brief, answered with programs

### Q1 — LLVM-19 `musttail` rules under the drop (B)

`probes/q1/gen.py` builds `mm1`'s shape (a quantum `w` ending `musttail return h2(p, k)`, `h2` reading
`p` only in a volatile-fold arm) in seven variants × {`musttail`, plain `tail` (N), hand-inlined twin
(T)}: `plain`, `inreg` (param 0 `inreg` on caller, call and callee), `tailcc`, `swifttailcc`, `byval`
(a `ptr byval(i32)` in a LIVE slot beside the dead one), `diamond` (the dead operand is a phi of a
classical diamond immediately before the `musttail` block, so `deleteDeadCones` empties the arms and
folds), `qdiamond` (the same with a TAINTED condition).

| variant | ORACLE | SUBJECT | SUBJECT vs N vs T |
|---|---|---|---|
| all 7 | DECLINE (3jru) | exit 0, warn 0, 0 dirty, 2b STRICT `3 verified, 0 violation(s), 0 unproven`, 12 lines | **byte-IDENT** to N (both binaries) and to T |

The lowered `w` keeps `musttail call [tailcc|swifttailcc] i32 @h2(i32 [inreg] 0, …)` immediately
followed by `ret` in every variant (in-process verifier clean); `qdiamond`'s emptied tainted diamond is
gone. Varargs: the drop refuses a variadic callee (`dropEligibleCallee`), and a `musttail` needs both
sides variadic, so a varargs `musttail` site is never rewritten. `byval` in the DEAD slot: a pointer,
never drop-eligible. Self-recursive `musttail` forwarders (`q2/r1`, `r2`): `clang -O1` eliminates the
tail recursion, no `musttail` survives stage 1 — not a customer.

### Q2 — does anything after the demotion (C) rely on `musttail`?

`grep isMustTailCall|isTailCall|TailCallKind` over `ir-pass/src` at the SUBJECT: only the demotion.
`synthUncomputeTwin` clones the already-demoted clone, so the twin's demotion is redundant (harmless).
Every accepted `musttail` spelling is byte-identical to its plain-`tail` spelling on the ORACLE:
`mtl`≡`mtlN`, `ev7`≡`ev7N` (implementer's, reproduced), `c4`≡`c4N`, `d2m`≡`d2`, `f1`≡`f1N`, `i1`≡`i1N`.
Declines agree (`c1`: a callee with a quantum primitive; `c3`: a callee that measures — both spellings
decline identically). A NON-clone function ending in a CLASSICAL `musttail` after quantum regions and a
loop (`q2/n1`) compiles identically to its plain spelling on both binaries (nothing is emitted after
the call); a non-clone `musttail` returning a clone's quantum result is a 3jru decline before any
emission, so I found no reachable non-clone sibling of m5pn (L2).

### Q3 — the three rhk5-routed programs, alone and composed

| program | ORACLE | SUBJECT | rhk5 r2 alone | COMPOSED | COMPOSED vs twin (`trace_twin_equiv`) |
|---|---|---|---|---|---|
| `ev9` (B) | DECLINE 3jru | warn 1, 2 dirty, ≡ `ev9N`@O | DECLINE 3jru | **warn 0, 0 dirty, `4 verified, 0 violation(s)`** | **EQUIV** (args 5 and 2) |
| `ev7` (C) | ABORT 134 | warn 1, 2 dirty, ≡ `ev7N`@O | ABORT 134 | **warn 0, 0 dirty, `6 verified`** | **EQUIV** |
| `mtl` (C) | ABORT 134 | warn 1, 1 dirty, ≡ `mtlN`@O | ABORT 134 | **warn 0, 0 dirty, `6 verified`** | **EQUIV** |

On the SUBJECT alone all three are DIFF vs their twins (rhk5's wrong circuit, warned), confirming §5.
With rhk5 round 2 composed they become clean and twin-equivalent (an instrument that is itself under
review this session — rhk5's own round found one false-EQUIV in it; its boundary controls ran green on
every invocation here). rhk5 alone does not compile them (it needs B/C). **So "rhk5 first" is the
right order for these three — but see F-r1B-1 for the customers it does not clean.** Composed `lit`:
2437 discovered, rc 0.

### Q4 — other known-defect spellings

- bd `s82e` shape with a `musttail` forward at the end (`q4/s1`, runtime trip; `q4/s2`, the bead's
  constant-trip shape): ORACLE DECLINE (3jru) → SUBJECT exit 0, byte-IDENT to the plain-tail spelling
  on the ORACLE and trace-EQUIV to the hand-unrolled twin. I could not reproduce s82e's leak at this
  HEAD with either spelling (0 dirty, 0 warnings), so no new wrong circuit here.
- bd `qjoc` shape (a 4.4 `_Bool` data select whose only reader is a DROPPED `musttail` slot, `q4/j1`):
  ORACLE DECLINE → SUBJECT exit 0, byte-IDENT to the plain spelling and to the twin (the dead select is
  deleted by the drop's dead-cone pass; no `%out` rail minted).
- bd `ffir`: see F-r1B-1.

### Q5 — lost subjects

After B the `musttail-inner` e2e pair and the re-spelled IR fixture no longer exercise a `musttail`
inside a clone (F-r1B-3: after C nothing can). Commit C itself is pinned by exactly one lit fixture,
`spec_accept_musttail_in_clone_demoted.ll` (CLONE-NOT `musttail` around the inner call; CHECK-NEXT
that the non-clone `h` keeps it) — mutant D1 (implementer's) kills it by abort. No e2e layer links a
demoted clone (F-r1B-5). I did not find another fixture that lost its subject to B (I did not re-run
the implementer's census).

## Standing-lesson questions

- **L1.** B changes only an eligibility filter of the pre-detection drop (slots A and B, both entry
  points); the drop writes constants (a taint SHRINK); no round-2 premise. C runs in `cloneFor`,
  reached only via `resolveSite → buildClone`, which both the round-1 `specialize()` and the round-2
  re-plan use (`Specialization.cpp:936`, `:1507`); it changes a tail-call kind, no taint. No L1 item.
- **L2.** C widens "what a clone stops promising". Same-closure sets: the `_unc` twin (inherits the
  demoted body — consistent); a `musttail` in a NON-clone caller retargeted to a clone
  (`retargetSite` keeps the marker via `setCalledFunction` when return types match) — unreachable with
  code after it (Q2). B widens drop-eligible sites; `dropEligibleSlot` has exactly one caller (the drop
  loop — grep), and `nullSafeSlot`/`isRewritableDeadSlot` are unchanged, so no other consumer moved.
- **L3.** Nothing narrowed.
- **L4.** No wire question.
- **L5.** B replaced a syntactic refusal by a semantic argument; Q1 attacked it with every ABI axis the
  verifier checks. C's semantic claim has the `preallocated` counterexample (F-r1B-2).
- **L7.** F-r1B-2, F-r1B-3, F-r1B-4 are comment/record claims that are false or unmeasured.
- **Rule 14.** The drop loop still asks `dropEligibleCallee` + function-type equality and then
  `dropEligibleSlot` asks them again (PRE-EXISTING duplication); B removed the `musttail` conjunct from
  BOTH spellings, so they did not diverge.
- **Rule 12.** B is an accept-direction widening with three accept fixtures (E1 kills all three); the
  refusal it retires had no decline fixture of its own to keep (it was an accept-side conservatism). C's
  accept has one fixture (D1 kills it). No positive `CHECK-COUNT` inside a negative prefix in the four
  B/C fixtures (read).

## Mutants (private composed tree; boundary controls: base hash checked before, mutant ≠ base, restore → base)

| mutant | change | lit (composed, 2437) | verdict |
|---|---|---|---|
| M2 | delete the demotion's `isMustTailCall()` conjunct (demote EVERY call in a clone to no tail kind, incl. plain `tail`) | rc 0, 0 failures | **EQUIVALENT** — removing a `tail` hint (a promise of no caller-alloca access) is always sound and cannot change a trace; not filed |

Base `31adc6af595c72df…`, M2 `290204d8255c585e…`, restored `31adc6af595c72df…` = base
(`BOUNDARY-OK`; `probes/mutant_M2.{sh,log}`). The null control is the composed build itself (its full
`lit` ran green before the mutant, and the restored rebuild is bit-identical to it).
B deletes a conjunct and adds none (the implementer's E1 restores it: 3 killed). C adds exactly one
conjunct (M2). I did not re-run E1/D1.

## What I tested and did not break

B's operand rewrite against `inreg`, `tailcc`, `swifttailcc`, a live `byval` beside the dead slot, the
dead-cone fold of a classical and of a tainted diamond right before the `musttail` block, fp dead slots (`q2/f2`: ORACLE decline → SUBJECT ≡ plain ≡ twin), a qjoc-shaped
dead select, an s82e-shaped loop; C's demotion against a 3-deep chain with `_unc` twins, the fp
rewrite path, a keep-set intrinsic (`fabs`, folded out by `-O1`), a non-clone `musttail` after quantum
regions, self-recursion (folded out by `-O1`), and `preallocated` (F-r1B-2). Every `musttail` spelling
that accepts is byte-identical to its plain-`tail` spelling on the ORACLE; every one that declines
declines with the plain spelling's string. No new wrong circuit beyond what the plain spelling
already has — the population growth is the whole story (§5 + F-r1B-1).

## Beads

None created. F-r1B-1 appended to bd `test_C_libtooling-ffir`'s notes (`--append-notes`, the three
exhibits and the composed-binary measurement); it also belongs in §5 of the track. F-r1B-2..5 are
record/comment items for the implementer's fix round.

## Housekeeping

The private worktree `<scratchpad>/rev_r1B_ev3m` was removed after the mutant run; the composed and
rhk5-only binaries `run_r1B.sh` needs stay at `<scratchpad>/r1B_bin/` (a scratchpad path — re-build
the composition from `3626a38d` + `c7dad811` if it is gone).
