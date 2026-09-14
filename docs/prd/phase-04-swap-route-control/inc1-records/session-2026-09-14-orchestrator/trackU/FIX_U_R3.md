# Track U — FIX record for review rounds 2 and 3 (bd `z9t1`) — **PROSE ONLY, NO BEHAVIOUR**

Worktree `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero`.
Subject: tip `4044e49e`, `cq-opt` `a5773be142835fb8`. ORACLE `f7b65d8ccd7bc472`
(`/Users/sorenwilkening/Desktop/CQ_lang/build`, read-only).
Rounds: `$SES/trackU/REVIEW_U_R2.md` (CLEAR-WITH-ITEMS, 3 items) and `REVIEW_U_R3.md`
(CLEAR-WITH-ITEMS, 4 items, **no code change recommended**).

**This round changed no pass behaviour and the binary proves it** — see §6. Everything below is a
record correction, a source *comment*, or a fixture *header*.

---

## 0. Disposition

| finding | round | instruction | what I did |
|---|---|---|---|
| **F-U2-2** | 2 | fix the record (3 edits) | **it had NEVER LANDED at this tip** — done now, §1, folded with F-U3-2 |
| **F-U3-2** | 3 | same item, confirmed at scale | folded into ONE corrected paragraph, §1 |
| **F-U3-3** | 3 | write the missing disclosure paragraph | done, §2 — verbatim, normative copy in `IMPL_U.md` §2(b′), same text at the mechanism |
| **F-U3-4** | 3 | the clause is ONE-SHOT; record why that is harmless, with retirement triggers | done, §3 — **three limbs re-verified by me, two extra write-spellings found, and round 3's stated reason CORRECTED** |
| number hazard | 3 | "164 of 972 thetas" ≠ "164 modules" | marked at **every** site either number appears, §4 |
| **F-U3-1** | 3 | *not mine* — owner ruling | **UNTOUCHED.** Recorded as pending in `IMPL_U.md` §8.0 beside F-U1-1, §5 |
| **F-U1-1** | 1 | *not mine* — owner ruling, coordinator hold 2026-09-14 | **UNTOUCHED**, §5 |
| **F-U2-1 / F-U2-3** | 2 | — | not in this brief. F-U2-1 is the F-U1-1 mechanism (§5); F-U2-3's record edit is already carried by `IMPL_U.md` §6's PARTIAL-sweep note and `FIX_U_R1.md` §5 |

---

## 1. F-U2-2 + F-U3-2 — the false "i.e.", folded into one corrected paragraph

**The same finding, three rounds running, and the record edit is the whole fix.** Round 1 (F-U1-2)
corrected `IMPL_U.md`; round 2 (F-U2-2) found the false sentence still in `RotationLowering.cpp` and
spelled the fix; **that fix never landed**; round 3 (F-U3-2) found it again with a measured
population. The sentence, in full, so it is recognisable if it is ever quoted again:

> *"A phi incoming is normalized ONLY when that phi carries THIS theta's result as another incoming —
> i.e. only where the object was undefined on BOTH edges."*

The clause before the dash is what the code asks. **The "i.e." is false**, and it described a rule
with a population of about **four**; the shipped clause's is **164**.

**Landed at four sites** (every place the claim was repeated):

| file | what changed |
|---|---|
| `ir-pass/src/RotationLowering.cpp` | the scope block replaced — heading retitled *"THE MOTIVATION IS 'ONE OBJECT, READ TWICE'; THE SCOPE IS WIDER"*, the three directions with counts, the population, the two-164 warning, the true reasons the shipped declines stay green, **and the P3b interaction** (F-U2-2's second edit) |
| `ir-pass/include/RotationLowering.h` | the declaration comment said *"(the SAME uninitialized object read a second time)"*; now states the superset and points at the definition |
| `ir-pass/src/RotationLowering.cpp` (phi loop body) | a ⚠ at the loop itself: *"READ THE SCOPE PARAGRAPH BEFORE QUOTING THIS LOOP"* |
| `ir-pass/test/control_accept_undef_theta_seed_stateprep.ll` | the header carried its own copy of the false "i.e."; corrected |

**The three directions, re-derived independently by me** from round 3's committed census artefact
(`review_r3_probes/census_main.json`) rather than copied — all six figures reproduced exactly:

```
files/modules                      : 711     phis carrying theta : 895
injectable non-theta incomings     : 698     already-undef files :   4
carried thetas                     : 972
thetas carried by MORE THAN ONE phi: 164     phis with >=2 non-theta incomings: 37
```

1. **several phis per theta** — 164 of 972 (probe `pL_second_unrelated_phi`);
2. **several incomings per phi** — 37 phis with ≥2 non-theta incomings, so one visit can equate
   several **distinct C objects** (probe `pA_three_edges`);
3. **a different object entirely** — probe `pD_two_objects`, `D→A` on that ground alone.

**Population of the phi half** (round 3's isolation sweep, cited not re-run): **164 of 710 measurable
modules** — 124 `D→A`, 39 message changes, 1 IR-only; all 164 byte-identical to the zero twin, 0
divergences, 0 `A→D`.

**The two retirement triggers F-U2-2 specified are now in both peel fixtures**
(`control_peel_reject_{undef,poison}_incoming.ll`), and each states the thing round 3 insisted on:
**the only reason those fixtures are untouched is that their undef/poison-bearing phi `%6` does not
carry a theta** (the theta-carrying phi `%7` has no undef incoming) — verified by reading the modules
myself, not inherited. Each trigger also says what to check *first* if the fixture ever goes red, so
nobody "fixes" it by narrowing `z9t1`.

---

## 2. F-U3-3 — the disclosure paragraph that did not exist

Written in the words CLAUDE.md §4 insists on — *what class of program stops being refused, what the
rival reading was, why it has no lowering to be robbed of* — plus why disclosure and not a predicate,
and three retirement triggers. **Normative copy: `IMPL_U.md` §2(b′)**, which the orchestrator carries
to `CLAUDE.md`; the same text is at the mechanism in `RotationLowering.cpp`.

**The one claim in it I verified in source myself rather than inheriting:** F1's second sub-clause is
a literal `Value*` comparison —

```cpp
// ArmClassify.cpp:3905-3908
if (PredIdx < 0 ||
    MergePhi->getIncomingValue(unsigned(PredIdx)) != RotBase) { … declineArm(…) }
```

— so `Constant::getNullValue`'s uniquing makes the seed operand and the Pred incoming **the same
`Value*`**, and F1's proof is **manufactured, not found**, for 116 of the 136 `D→A` rows.

---

## 3. F-U3-4 — the clause is ONE-SHOT; the three limbs, re-verified BY ME

**The record's claim.** `IMPL_U.md` §1 and the source both argued that sitting inside `propagate`
discharges the L1 round-2 obligation **structurally**. That is true of the **seed** half. The
function early-returns once the seed is concrete, so **the phi loop is unreachable at every propagate
round after the first** — the phi half is one-shot, and its safety is **measured**, not structural.

**The point of this item was to verify it rather than copy it, so here are my own greps** over
`ir-pass/src ir-pass/include ir-pass/tools`:

| limb | what I ran | result |
|---|---|---|
| (a) | `grep -rn "setIncomingValue"` | **1 site** — `RotationLowering.cpp:274`, this clause |
| (a′) | `grep -rn "addIncoming\|setIncomingValueForBlock\|removeIncomingValue"` — ⚠ **round 3 did not run this** | `addIncoming` **3** (`Specialization.cpp:487` a clone `ret` value; `BreakReversePlay.cpp:834`/`:837` two `sub` Instructions), `removeIncomingValue` **2** (`CtlzIdiomPrepass.cpp:433-434`, removes only). **None can put an `undef` on a theta-carrying phi** |
| (b) | `grep -rn "UndefValue::get\|PoisonValue::get"` | **0 call sites**; one comment hit, `LiteralIntegrity.h:136`, which records that this grep is clean |
| (b′) | `grep -rn "getUndef\|getPoison\|UndefValue\|PoisonValue"` | every other hit is an `isa<UndefValue>` **read** or a comment — incl. `QramLowering.cpp:657`, which normalizes undef→zero **for a local predicate** and mutates no phi |
| (c) | `grep -rn "PHINode::Create\|CreatePHI\|createPHI"` | **2 sites**, both read in source: `Specialization.cpp:484` `cqq.ret` and `BreakReversePlay.cpp:831` `cq.brk.ip` |

**Why both phi minters are excluded — read, not inherited.** `cqq.ret` merges **clone return
values**, and `SpecializeReject::scanBody` returns `SpecReject::QuantumPrimitive` for any `CallInst`
in `Sets.Rotations` (`SpecializeReject.cpp:636`), a set seeded from `taint.ThetaCalls` at `:53` — its
own *"load-bearing precondition R2"* — so a rotation cannot be in a clone body and that phi can never
be a theta user. `cq.brk.ip`'s two incomings are `NMinus1` (`BinaryOperator::CreateSub`) and `IDec`
(`RB.CreateSub`), both Instructions.

**(d) What I did NOT enumerate, stated rather than implied:** a RAUW whose replacement value is an
`undef` **already present in the input module** could in principle land on a phi incoming. Limb (b)
bounds it — the pass creates no new undef — but I did not enumerate the RAUW targets. Limb (c) also
inherits F-U1-3's qualifier: `Sets.Rotations` is **exact-pointer**, so a theta clone minted after the
last full `propagate` is invisible to `scanBody`.

**⚠ AND I CORRECTED ROUND 3'S OWN STATED REASON (Rule 11 applies to reviewers too).** F-U3-4's
proposed trigger says *"moving the seed guard is the wrong fix, because it would make the rewrite
non-idempotent."* **That is not the hazard.** The phi loop *is* idempotent (`isa<UndefValue>` is false
after the first rewrite) and the single call site **discards the return value**
(`normalizeUndefRotationSeed(CI);`, `TaintPropagation.cpp:171`), so no fixpoint is driven by it. The
real hazard is the **seed operand**: that same guard is the ACTION guard for `setArgOperand`, and
relaxing it to reach the phi loop would let the rewrite fire on a seed that is not a whole-value
`undef` — the silent value change the `isa<UndefValue>` conjunct exists to prevent. **The fix, if a
limb ever retires, is a SECOND ENTRY POINT, never a relaxed guard**, and that is what the triggers
say.

**Retirement triggers landed**, one per limb, in `RotationLowering.cpp` (PLACEMENT section + the loop
body), in `RotationLowering.h`, and in `IMPL_U.md` §1: (a) a second writer **in the phi-incoming write
family** — not merely a second `setIncomingValue`, which is the L2 lesson applied to my own extra
grep; (b) any `UndefValue::get`/`PoisonValue::get` call site; (c) a third phi-creation site, or either
existing one ceasing to be excluded.

---

## 4. The number hazard — "164" twice, and they are not the same number

*"164 of 972 carried thetas"* is a **count of thetas** (census). *"164 modules"* is the phi half's
**module population** (isolation sweep, denominator 710). Different instruments, different
denominators, **equal by coincidence**. The warning *"do not cite one for the other"* is now at every
site either number appears:

* `ir-pass/src/RotationLowering.cpp` — the scope paragraph **and** the phi-loop body comment;
* `ir-pass/test/control_accept_undef_theta_seed_stateprep.ll` — the header;
* `IMPL_U.md` §2(b) — as its own blockquote;
* this file, here.

---

## 5. What is PENDING A RULING and was not touched

**F-U3-1** (the phi clause disarms ruling clause 4 upstream of the sink; 4 of 710) and **F-U1-1** (the
GUARD 1 count drop; round 2's F-U2-1 adds a SIGABRT outcome to the same mechanism) are **with the
owner**. I changed nothing about either: no predicate, no conjunct, no decline fixture, and no
softening of the source comments that state them as OPEN. They are now recorded together in
`IMPL_U.md` §8.0, because they are one question asked twice — *this rule moves modules through a
diagnostic nobody predicted*.

---

## 6. Gate lines — the whole gate is that the binary did not move

| | sha256 (`cq-opt`) | sha256 (`libCQPass.so`) |
|---|---|---|
| before this round | `a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff` | `957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194` |
| **after `cmake --build build -j8`** | **`a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff`** | **`957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194`** |

**BIT-IDENTICAL** — which is the mechanical proof that nothing behavioural landed, and the brief's own
stated FINDING condition (a comment-only edit that moves the binary) did **not** occur. The
comment-only property is checked the same way `FIX_U_R1.md` §7 checks it:

```
$ git diff -U0 ir-pass/ | grep -E '^[+-]' | grep -v '^[+-][+-]' | grep -vE '^[+-]\s*//' | grep -vE '^[+-]\s*$'
  (no output — for the .cpp/.h edits)
```

The three `.ll` fixtures changed only `;` comment lines (headers), which are not compiled into
anything and are excluded from the duplicate-body scan's hash by construction.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| `cmake --build build -j8` (BOTH targets) after the comment-only edits | a5773be142835fb8 | exit 0, 2 pre-existing `-Wunused-parameter` warnings in untouched functions; **bit-identical to the round's subject** | fix-r3 | 2026-09-14 |
| `lit ir-pass/test --filter 'control_peel_reject_undef_incoming\|control_peel_reject_poison_incoming\|control_accept_undef_theta_seed_stateprep'` | a5773be142835fb8 | `Passed: 3` of 3 (1936 discovered, 1933 excluded), 10.10 s | fix-r3 | 2026-09-14 |
| census re-derivation from `review_r3_probes/census_main.json` | — (text parse, no pass) | 711 modules / 895 phis / 698 injectable / 4 already-undef / **972 carried thetas** / **164** in >1 phi / **37** phis with ≥2 non-theta incomings — all six match round 3 | fix-r3 | 2026-09-14 |
| the three F-U3-4 greps + the two extra spellings | — (source read) | (a) 1 · (a′) 3 `addIncoming` + 2 `removeIncomingValue` · (b) 0 · (c) 2, both excluded — §3 | fix-r3 | 2026-09-14 |

### CITED, not re-run (PROTOCOL: a gate result is a fact about a BINARY)

The rebuild is bit-identical to `a5773be142835fb8`, so every `a5773be1` row in `GATES.md` still
describes the binary on disk:

* `cited: ir-pass-lit Passed 225.31 s, 1/1, lit discovers 1936 @ a5773be1 (impl, row 36)`
* `cited: corpus sweep 2793 rows / 7 movers @ f7b65d8c-vs-a5773be1 (impl, row 32) — ⚠ PARTIAL as recorded`
* `cited: corpus tail 98 rows / 0 movers @ f7b65d8c-vs-a5773be1 (impl, row 33)`
* `cited: injection matrix applied 67 / MISSED 0 / N/A 23 @ a5773be1 (impl, row 31)`
* `cited: vacuity scan 0 VACUOUS @ a5773be1 (impl, row 30)`
* `cited: review round 3's 711-module / 2844-invocation phi sweep @ f7b65d8c-vs-a5773be1 (REVIEW_U_R3 §1)`

### NOT run by this agent (brief: no corpus sweep, no suite, no full ctest)

`ctest -j6 -R '^e2e-'` · the full `ctest -j6` · `cq-opt-equivalence-full` · the twin matrices · any
corpus sweep. The only executed gate this round is the rebuild plus **three** lit fixtures; everything
else is a source read or a parse of a committed artefact. **`cq-opt-equivalence-full` remains owed by
the group gate for the ORIGINAL increment** (three shipped declines became accepts), unchanged by this
round.
