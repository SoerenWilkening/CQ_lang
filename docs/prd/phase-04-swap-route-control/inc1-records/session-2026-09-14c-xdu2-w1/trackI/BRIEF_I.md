# Track I — the INSTRUMENTS: bd `21re` (the falsified stage-2b premise) + the L-1a WITNESS design

Worktree `/Users/sorenwilkening/Desktop/CQ_inst`, branch `railbank-instruments` (off `main` `6db48142`).
Records: `$SES/trackI/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/`;
`$SESP` = `…/session-2026-09-14-orchestrator/`; `$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (**binding**), `$SES/DECISIONS.md`, `CLAUDE.md` (Prime Directive;
Rules 2, **11**, 12, 13, 14, **19**; CORRECTNESS RISK §3 **L10** and the six-instances paragraph that
follows it — that paragraph is your job description), `bd show 21re` (**it BLOCKS `xdu2`: "land this
with xdu2, not separately"**), `$SESP/trackL/SCOPE_L1a.md` **§5 in full** (the instrument table and the
two blind spots), `tools/free_pairing_check.py` (**read the file header for exactly what it does and
does not witness**) and `tools/free_pairing_check_test.py`.

**You touch only `tools/` and `tests/`.** You are in **no group** with Tracks A, B, S or X under
PROTOCOL §S1 — do not edit anything under `ir-pass/`, `include/` or `runtime/`.

---

## Job (a) — bd `21re`: `provably_not_a_rail`'s premise, falsified before the code that falsifies it lands

`tools/free_pairing_check.py:1259 provably_not_a_rail` is justified by the docstring at **`:1292`**:

> *"A handle cannot reach a global and come back — a tainted `store` is a loud decline at
> `declineTaintEscapes` long before lowering — so a load result is not a rail."*

bd `xdu2` exists **precisely to remove that decline**. After L-1a a bank `load i32` **is** a rail
handle, `provably_not_a_rail` returns `True` (`:1308`) for it, and any rule that reads it as a classical
immediate — e.g. a bank load passed as a **control** to `cqrt_copy_i32_controlled` — could **discharge a
free it should not**. Stage 2b is the **Rule-6 free-pairing gate**; this is a Rule-13-class instrument
finding, not a nicety.

**What to build.** Either (i) teach `classify()` / `provably_not_a_rail` about `!cq.railbank` loads, or
(ii) make the checker **fail loudly** on a construct whose rail-ness it cannot decide — the discipline
the file already applies to symbols (*"a new `cqrt_*` symbol must be classified in `classify()` or the
checker fails loudly rather than guessing its read/write effects"*). **A load does not get that
treatment today; that asymmetry is the bug.**

⚠ **Sequencing.** Tracks A and B land the classifier and the promoter this session; the **taint rule and
the type rewrite are deliberately deferred**, so **no `!cq.railbank` load exists in any lowered module
you can produce today**. That means:
* your fix must be **pinned by construction, not by a natural subject** — write the lowered-IR fixture
  by hand and feed it to the checker directly;
* and it must carry an **L8 RETIREMENT TRIGGER** in its header naming what will fire: *"when L-1a's type
  rewrite lands, a real slice produces this shape; re-derive this fixture against it then; do NOT delete
  it."*
* ⚠ **A checker fix with no subject is the vacuity trap in its purest form.** `free_pairing_check_test.py`
  is the mutant validator — **extend it**, and report the MISSED count. bd `21re` is only closed when
  the new behaviour is **shown to fail on a mutant**.

⚠ **Do not "fix" this by relaxing the checker.** Over-declining here is safe; a checker that guesses is
the thing `CLAUDE.md` calls *"a number measuring the wrong program"*, alongside the three pure-python
record gates that each shipped **after** the defect they catch had already gone undetected through a
fully green suite.

---

## Job (b) — the L-1a WITNESS, because byte identity is NOT available for this program

⚠ **`$SESP/trackL/SCOPE_L1a.md` §0 H2 / §5 measured that the usual witness does not exist here.** With
`a = 5` compile-time constant, `-O1` **folds trip 0's `a >= 3` away in the UNROLLED spelling and cannot
in the rolled one**, so the shipped N=2 accept is *"one folded region + one genuine prep"* while the
rolled form is *"one genuine prep, K times"* — **they are not the same circuit and cannot be
byte-compared** (50 vs 44 lines). And with an **opaque** `a` the unrolled twin **declines**
(`L13_flat_n2_opaque_noinline.c`, at `%8 = select i1 %6, i32 %7, i32 %0`), so the comparison has no
accepting twin at all.

**Design the replacement, and label it honestly.** The components SCOPE_L1a names:

1. **K-independence of the lowered IR**, measured **without `-g`** (debug metadata inflates the count and
   a `-g` number is not comparable — `$PREV/trackL/SCOPE_loop.md` §3). The shipped precedent is 87 lines
   at K=3 and at K=1000 for the phase path, and 81/66/85/83/105 at K=3 **and** K=1000 for bd `wx8g`'s
   five shapes.
2. **A per-trip MULTISET argument** — the emitted stream's per-activation blocks are identical up to
   handle renaming. `tools/golden_multiset_audit.py` exists; read it and say whether it is the right
   tool or the wrong one.
3. **The label.** It is an **INTERNAL-CONSISTENCY gate**, not an oracle-backed one, and it must say so
   in the style of `tests/e2e/slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.c:11-15`.
   ⚠ **A gate that is cited as clearance when it is only self-consistency is exactly how every shipped
   Grover golden was the identity** — the traces were self-consistent records of the identity and
   nothing could see it.
4. **If a byte-identity twin CAN be constructed** — a program whose every trip is identical and whose
   flat twin lowers — say so and build it; it is strictly better than (1)+(2). SCOPE_L1a §5 says the
   gate *"must therefore be built on"* such a program **or** replaced. Determine which, by measurement.

**State plainly, in the witness's own header and in `IMPL_I.md`, what each instrument CANNOT see:**
* the **golden e2e trace** is the **primary** witness for this increment — the reverse of the usual
  division of labour — because it sees every one of the K per-trip `cqrt_alloc`/`cqrt_ry` lines, the
  angles and the control/target order. Say so in **every** slice header L-1a adds.
* **stage 2b counts `cqrt_alloc` SITES**, so a rolled per-trip alloc reads as **one** rail when the
  circuit mints K. **Do not cite 2b as clearance here** — put that sentence in the slice header, not in
  the review.
* **K-independence says nothing about the unitary.**
* bd `1yeu`: every corpus and gate in the tree is effectively **ONE FUNCTION PER MODULE**, so a
  cross-function defect is invisible to all of them.

---

## The rule that governs both jobs

⚠ **`CLAUDE.md` L10 and the paragraph after it: an instrument's failure mode is to report a PASS, so
the only instrument worth citing is one that has been MADE TO FAIL ON PURPOSE.** Six measured instances
landed in one session (2026-09-14), each found by the agent that owned the instrument and **none** by a
green suite: a vacuity checker that printed `checked 0` on 29 real negatives; an injection matrix that
printed `0 mutations, MISSED 0, N/A 0` when invoked with **no fixture argument**; an injection harness
that **lied twice in the MISSED direction** before telling the truth; a matrix that reported **45
MISSED against fixtures that catch everything** because it ran `FileCheck --check-prefix` and dropped
the RUN line's `--implicit-check-not` flags (*a harness that runs a weaker command than lit measures
itself, not the fixtures*); `--regenerate` silently eating **54 lines of Rule-13 ruling prose** (bd
`gfsk`); and a **0-byte `.ll` module ACCEPTING** through the passthrough early-out, scoring six probes
as ACCEPT on nothing.

**Every instrument you ship or touch must come with a demonstration that it fails on a mutant, and the
MISSED count must be reported. A harness that reports `n/a` is a HOLE, not a pass.**

⚠ Also in scope if you find it cheap: **bd `21re`'s sibling risk** — `free_pairing_check.py`'s handling
of a rolled per-trip alloc. You are not asked to fix the site-counting blindness (that is a bigger
question), but **document it precisely** in `IMPL_I.md` so the next increment does not rediscover it.

---

## Gates you own — PROTOCOL §matrix

You need **no build** for job (a)'s core (the checker is pure python over lowered IR you supply), and a
build only if job (b) needs real lowered modules. If you build: `cmake --build build -j8`, **NEVER
`--target CQPass` alone**, and record `shasum -a 256 build/ir-pass/cq-opt` in `$SES/trackI/GATES.md`.

Run: `ctest --test-dir build -R 'e2e-free-pairing-selftest'` and any single slice you touch. **NEVER**
the full suite, `^e2e-`, `ir-pass-lit` (you touch no pass source), the equivalence sweep, or the twin
matrix. ⚠ The three pure-python record gates (`keepset_vendor_check.py`, `slice_census_sync_check.py`,
`free_pairing_check_test.py`) run in seconds and need no plugin — run the ones you touch.

⚠ **ORACLE** (frozen, read-only): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`. The primary `build/` is READ-ONLY;
never relink under a running measurement; never `pkill` by pattern.

## Deliverables

`$SES/trackI/{IMPL_I.md, GATES.md, probes/}`: the `21re` fix with its hand-built subject and its
retirement trigger; the extended `free_pairing_check_test.py` with the **MISSED count** and the
made-to-fail-on-purpose demonstration; the witness design with each component's label and each
instrument's stated blind spot; the exact sentences L-1a's slice headers must carry; and anything you
could not do.

Commit on your branch (**no push, never touch `main`, never write outside your worktree**), message
`fix(instrument): bd 21re — …` with the two `CLAUDE.md` trailers. Report back: branch tip, gate lines in
the PROTOCOL format, the MISSED counts, and **anything you could not do**. **Rule 19: report only what
you ran.**
