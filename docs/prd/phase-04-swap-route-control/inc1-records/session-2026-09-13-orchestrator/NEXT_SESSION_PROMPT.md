# Next session — orchestrator prompt (written 2026-09-13 at the close of session `013Hi5y8TF8WpYRVVqZH21Vo`)

You are the ORCHESTRATOR for CQ_lang (`/Users/sorenwilkening/Desktop/CQ_lang`, `main` at the hash `git log
-1` shows, ≥ the 2026-09-13 closing docs commit). **Every agent you spawn is `model: "opus"`**; the
orchestrator runs no build, no ctest, no lit, no pipeline — it spawns an opus agent for every execution
(owner 2026-09-11). **The non-redundancy protocol is binding** (owner 2026-09-13, `PROTOCOL.md` beside this
file): one hash-keyed `GATES.md` per track; a gate result is a fact about a BINARY; the implementer's inner
loop is `lit --filter` + single slices with `ir-pass-lit` ONCE at hand-off; the reviewer runs NO build and
NO suite; the merge-and-gate agent is the ONLY full-`ctest` runner, once per landing on the merged tree;
`cq-opt-equivalence-full` only when a decline string / analysis site moved; the primary `build/` is the
frozen ORACLE until the closing step-5 rebuild. Measured effect this session: **4 full-suite runs for 3
landings** (three merge-and-gate + one closing) against the four-track session's ~9; zero cited-but-stale
gate lines (every hash matched on disk); the `md5-across-sweeps` and the corpus-tag-lossiness (D→D string
changes inside the `cq_measure` family invisible to the shared `corpus.sh` tag regex — `MERGE_R1_1.md` F-R1)
are the two instrument lessons. Read first: `CLAUDE.md` (Prime Directive; Rules 1/6/7/8/12/13/14/17/18/19;
CORRECTNESS RISK §1–§5 incl. the 2026-09-13 paragraph; Build & Test; Session Completion), `bd prime`, this
directory (`ORCHESTRATOR_PROMPT.md` §3 the protocol as first written; `PROTOCOL.md`; `CLOSING_MEASUREMENTS.md`
for the closing numbers; `trackL/SCOPE_loop.md` — THE SPINE of this session), and as style models
`trackM/{SCOPE_M,BRIEF_M,REVIEW_BRIEF_M_r1,FIX_BRIEF_M_R1,MERGE_BRIEF_M}.md`, `MERGE_BRIEF_TEMPLATE.md`,
`CLOSING_BRIEF.md`.

## What the 2026-09-13 session landed (three squash landings on `main`)

1. `23b0cd1` — **bd `21mg`** `cq_measure` of a never-quantum value lowers to the classical value (no gate)
   + **L-0** the H-10 pins (a loop-carried `_Bool` with the in-body theta as condition — the shipped rolled
   accept, now pinned rolled == unrolled 9 = 9, K-independent).
2. `94c085e` — **bd `rb9x`** F2 excludes the peel's compare CLONES via `taint.PeelClones` (a record,
   consulted at the TEST; the PREIMAGE argument). The `int b0` / `bool b1` fused spelling compiles (22).
3. `59ac5b7` — **bd `boi6` D-B / `8xaw`** the region-merge-φ rail leaf for the 4.4 DATA SELECT: **the
   owner's `example/grover/grover_oracle_uncompute.c` of 2026-09-13 (N=2, `if (b1) a -= 3;`) COMPILES AS
   WRITTEN — 29 trace lines, STRICT 2b clean**; the run-time-`a` general cascade 31; a compare-conditioned
   prep + select on its output 21; an in-loop select on an outside prep's φ rolled == unrolled 43 = 43. Two
   Rule-13 rounds (r1 CLEAR-WITH-ITEMS → the `hcrg` precedence EDGE for a select region → r2
   CLEAR-WITH-ITEMS).

Counts at close: see `CLOSING_MEASUREMENTS.md` (re-measure by command before quoting).

## What is OPEN, in the order that compiles the most C (the owner's goal: "a large loop where MANY of those controlled operations are applied")

**Owner questions carried over, answered by this session's measurements where possible:**
* **Q2 (loop spelling)** — Track L MEASURED that the scalar `bool b` re-prepared per trip DENOTES A
  DIFFERENT CIRCUIT (the value arm is conditioned on `b`, not the flag: `a` reaches −1 at N=2, −4 at N=3)
  and its flat twin declines on every binary. Recommendation (i) `bool b[N]`, one qubit per trip = the flat
  file's semantics. **Ask the owner to confirm (i)** — it decides whether L-1a is the next increment.
* **Q1 (boi6 H-1)** — still open; only `boi6.a` (the header-φ) needs it. Recommend (a).
* **R-2 / R-2′ (`vd.c`, N=3)** — bd `om35`: the N=3 cascade declines F2 on the THIRD region's guard pinned
  on the true edge (no peel). The rival audit (`trackR/SCOPE_R2.md`, 14 rows, 0 holes) found the stated 2c
  ground WRONG (the fences are R3/R6/`:3257`) and a stronger spelling R-2′ ("a collider pinned on ONE edge
  is not a collider") that flips ≥11 shipped decline fixtures. **An owner ruling** — with it, N=3 compiles
  (M + R-1 + R-2′); without it, `vd.c` stays declined.
* **Q-1 (21mg)** — a classical measure writes NOTHING to the trace; if the 7.6 output tape wants every
  user-written measurement, `MeasureLowering.cpp`'s classical branch is the site.

| bd | what | why next |
|---|---|---|
| **`xdu2` L-1a** | the bounded VALUE-TAINTED rail ARRAY (`bool b[N]` in a rolled loop): ONE wall, N-independent (`kMsgStore`, before `lowerLoops`); after lowering a rail is an `i32` handle, so `[N x i1]` → `[N x i32]` of handles in classical memory — no new ABI; rails stored to memory are FROZEN | the whole of Q2(i); its unrolled twin is the flat cascade Tracks M/R landed, so the two compose into one witness. ⚠ `free_pairing_check` counts alloc SITES (a rolled per-trip alloc reads as one rail) — the golden trace is the witness. 3 rounds |
| **`x5fp` L-2** | the §3c clobber fence fires THROUGH THE BACK EDGE (`diagonalAliasHit`+`StraightThrough`); ask it PER ACTIVATION via `provablyBeforePerActivation` | the first wall of every `if (cond on a) …; if (b) a -= 3;` loop; a structural guard wearing a semantic label (L4/L6). L2 obligation: `condProvenance`'s φ walk feeds 2c too. ⚠ carried `_Bool` is an `i8` WIRE in every loop form (bd `r903` NOTES) — probe first |
| L-3 (bd filed 2026-09-13, "a CLASSICAL rail ROOT for a loop-carried _Bool") | `bool b = 0` before the loop ⇒ `railPhiRootMint` finds NO MINT ⇒ `declineClassicalMuxes`; materialise `cqrt_alloc(seed)` in the PREHEADER | the ONLY loop wall invisible in the flat file; every owner spelling hits it; ~60–90 lines, 2 rounds |
| **`ej5w` L-4** | the in-loop VALUE arm is declined by the LOOP LAYER's X1 clause (`LoopLowering.cpp:2108` + round-2 twin `:2551`), NOT by `3qlq.6` | the cascade's `a -= 3` in a loop; the C-1 family's first carried-rail subject; 3 rounds |
| `om35` R-2/R-2′ | see above — owner ruling first | N=3 flat |
| `3qps` | the PHASE consumer on a prep merge-φ (`if (b1) cq_phi(θ)`) is a LEAF-GRAMMAR over-decline, not `drbq.7`'s wire fence (the arm theta is a SOURCE; the int compare twin lowers) — same predicate as Track M at `classifyPhaseKickback` step 5b | plain C, one round |
| ROOT-ONLY (bd filed 2026-09-13) | a prep merge-φ as an INTERIOR leaf of a compound select condition | cheap widening of Track M |
| `gy1w` | a CLASSICAL `cq_measure` inside a tainted arm — needs a `MeasureCalls` scrub at the block-erase sites | over-decline |
| `xqgx` A.2 | + the new `m15i` customer (S† after a select: `bool` accepts, `int` declines — the compare/rail DT-prong asymmetry) | |
| `3d8q` (P1) | population WIDENED again: Track M's φ admission adds the sibling-reader shape (`trackM/probes/impl/p3d8q_sibling.c`, `review_M_r1_probes/r15_p3d8q_sibling.c`) and F-M3 (the in-place-ARM φ) is pinned as a DECLINE whose retirement is "land the `3d8q` fence, then re-derive `condProvenance`'s seed" | the oldest open miscompile; build it before narrowing any seed |
| `qta2` | 6 more fixtures carry a bare `-NOT: phi` (green only by windowing) | fixture hygiene |
| `br4a`, the zext-of-peeled-select F2 collider, `35t0`, `wx8g`, `boi6.a`, `54ur`, `fg9k`, `l4x4.a`, `lo7u`, `f8eu`, `6uqc` | as recorded | |

## Method that worked (keep it)

Four scoping agents in one message (read-only, ORACLE only, ≥20 probes each) before any code; one
implementation agent per track in its OWN worktree + build; a written brief per agent with the §3 protocol
row copied in; independent opus Rule-13 rounds (budget 2, the second found the `hcrg` edge gap the first
had graded as a doc defect); fix agents resumed from the implementer's context with a written brief; one
merge-and-gate agent per landing (the ONLY full-`ctest` runner); the orchestrator squashes; step 5 rebuilds
the primary ONCE. Landings are serial and whichever is cleared lands first (C → R-1 → M this session).
Every brief names the customer file, the `file:line` anchors with the predicate verbatim, the ORACLE hash,
and what NOT to do. Scoping agents corrected three recorded claims this session before they cost code
(boi6 §0.3's "wire fence" for the owner's shape; rb9x's own rival string; R-2's 2c ground) — measure
before you build, and write the correction where the next reader looks.

## Session completion (non-negotiable, `CLAUDE.md`)

bd follow-ups; full `ctest -j6` before any core commit (per landing, by the merge-and-gate agent);
`bd remember` per increment and lesson; CLAUDE.md status paragraph with counts by command; ROADMAP; PRD
`retire-swap-route-PRD.md` §0/§NN; lab-report entry 006 (`docs/labreport/TEMPLATE.tex`, ≤5 pages,
`tools/labreport/build.py --seal`, never the PDF); `git pull --rebase && git push && git status`; worktrees
removed; the next `NEXT_SESSION_PROMPT.md` in the session's record dir.
