# Track L — SCOPING brief (READ-ONLY): the bounded rail ARRAY, L-1a (bd `xdu2`)

**You build NOTHING and you edit NOTHING.** Main checkout `/Users/sorenwilkening/Desktop/CQ_lang`, ORACLE
read-only, writes **only** into `$SES/trackL/` (`$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`). `$PREV` =
`…/session-2026-09-13-orchestrator/`. Never write under `ir-pass/ include/ runtime/ tests/ tools/ example/`.

**ORACLE, hash before first use, STOP if it differs:** `build/ir-pass/cq-opt`
`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`; `build/ir-pass/libCQPass.so`
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`. Never rebuild, never relink under a
measurement, never `pkill` by pattern.

**READ FIRST:** `$SES/PROTOCOL.md`, `CLAUDE.md` (Prime Directive; Rules 3, 5, 6, 8, 12, 13, 14, 17;
CORRECTNESS RISK §1 the in-loop rows, §2 "Loop scope", §3 L1/L2/L10), `bd show xdu2`, `bd show x5fp`,
`bd show ej5w`, `$PREV/trackL/SCOPE_loop.md` (the 37 probes — §1.1, §2.1 especially), and
`ir-pass/include/QramLowering.h` (7.5 is the OPPOSITE axis and owns `matchQramAccess`).

---

## 1. Why this track exists

The owner's standing goal, verbatim (2026-09-13): *"the grover script might be implemented with a large
loop, where MANY of those controlled operations are applied"*. Last session measured the two spellings:

* **(i) `bool b[N]`** — exactly ONE wall, **N-independent**: `cq taint escape: tainted value stored to
  memory` (`TaintPropagation.cpp:526`, `kMsgStore`), BEFORE `lowerLoops`. Rolled, `-O1` stamps
  `llvm.loop.unroll.disable` so no constant N scalarises the array; hand-unrolled, SROA removes it completely
  and the program IS the flat cascade Tracks M/R already lower. **This is L-1a and this is your subject.**
* **(ii) scalar `bool b`** re-prepared per trip — four walls AND it denotes a **DIFFERENT circuit**
  (`a` goes negative: −1 at N=2, −4 at N=3). Not your subject; the owner's recommendation is (i).

Customer state vector at N=3 (from `xdu2`): branches `000/001/010/100` with `a = 5/2/2/2`, amplitudes
`c³, c²s, cs, s` (`c = cos .25`, `s = sin .25`) — a first-success cascade with a kept history, one qubit per
trip.

## 2. Deliverable — `$SES/trackL/SCOPE_L1a.md`, an IMPLEMENTABLE design, not a survey

The next agent must be able to build from it without re-deriving anything. It needs:

### 2a. The accept predicate, five clauses, each as a code site

`xdu2` states them; your job is to turn each into *"this predicate, at this file:line, answers this
question"*, and to MEASURE that each is a decline today:
1. a non-escaping `alloca` of a **bounded static element count**;
2. every access a **classical-index in-bounds GEP** (a TAINTED index keeps 7.5's decline — say which
   predicate enforces that and cite it);
3. the stored value **tainted with an ABI width**;
4. no aliasing fan-out and no mixed classical/quantum use of a cell — **CALL 7.5's `matchQramAccess`
   provenance walk, do not re-spell it** (Rule 14; the drbq Inc-3 (b′) defect is a second spelling of a
   predicate the tree already owned);
5. element type rewritten to the handle type, store/load carry handles, and **the carve and the emitter share
   ONE predicate** (the `isRecognizedIOSink` / `qramCarveVerdict` discipline).

### 2b. The FENCE, spelled

**A rail whose handle is stored to memory is FROZEN** — never reverse-played, never freed (Rule 5/6: a rail
not provably `|0⟩` is left allocated, never freed dirty). Enumerate **every** in-place / stale-record /
free-point fence that is keyed on SSA wires and say, per fence, how it learns that a stored rail is frozen
and that it must refuse loudly. **L2 applies**: when you widen the set of things that can be a rail, ask what
OTHER set was computed over the same closure — name every one.

### 2c. The ROUND-2 question (L1), in writing

Control detect+lower runs TWICE. Does the array carve run before round 1, between the rounds, or after the
fixpoint? What does it compute that a later stage consumes over a premise round 2 can falsify? Does it GROW
the taint set — and if so, where is `adjudicateTaintDelta` owed? Answer all three or say which you cannot.

### 2d. The INSTRUMENT blind spot, stated in the words a reviewer needs

`free_pairing_check.py` counts `cqrt_alloc` **SITES**, so a rolled per-trip alloc reads as ONE rail — stage 2b
is **not** the witness here; the golden trace is. Say which instrument witnesses what, and whether
`e2e-loop-twin-matrix` (the only thing in the tree that can see a leaked TEMPLATE-minted rail) applies.

### 2e. The TEST PLAN and the COST

The fixture list (positives, and a **decline fixture + adversarial probe per accept-predicate clause** —
Rule 12), the slices + goldens, the twin-matrix cells, the rolled-vs-unrolled equality claim and what proves
it (K-independence of the lowered IR + byte identity with the hand-unrolled twin, per §1's shipped
witnesses), the Rule-13 round budget (`CLAUDE.md` says budget the rounds up front: the measured hit rate
says the next round finds something), and the line/fixture/ctest cost. `xdu2` estimates ~150–220 lines,
~20 fixtures, +4 goldens / +6 ctest, ~8 matrix cells, 3 adversarial rounds — **confirm or correct it by
measurement**.

### 2f. The DEPENDENCY statement

`xdu2` says L-1a depends on Track M (landed `59ac5b7`) + Track R (`rb9x`, landed `94c085e`) for the unrolled
twin's stream. Re-measure whether that is still true at `main` 607b6fe4, and state whether this session's
Track P (bd `3qps`/`4aiu`) or Track F (R-2′) changes the unrolled twin. **If a dependency is unmet, say so
plainly — that is the finding.**

---

## 3. Gates

No build, no suite. Per-probe pipeline on the ORACLE only:
```
LLVM=/usr/local/opt/llvm@19/bin
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S p.c -o s1.ll
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll; echo "exit=$?"
CQ_CTRL_DBG=1 build/ir-pass/cq-opt ... 2>&1 | head
```
Probes in `$SES/trackL/probes/`; `GATES.md` line for anything you run. Report to the orchestrator: the five
clauses as sites, the fence enumeration, the L1 answer, the cost, the dependency verdict, and any clause you
could NOT turn into a site.
