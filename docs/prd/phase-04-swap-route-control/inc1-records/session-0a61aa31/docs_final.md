# progress: docs_final (post-merge docs pass, Inc 0 + Inc 1)

## 2026-09-05 step 0 — start
- Main checkout /Users/sorenwilkening/Desktop/CQ_lang, branch `3qlq-inc1`, HEAD `cd2f071`
  (brief said be4e2ea; HEAD has moved one commit forward — cd2f071 "wip(3qlq-inc1):
  lowering_reject_break_phase_answer.ll ... re-pointed to the fence that fires").
  `git log --oneline -5` / `git branch --show-current`.
- Working tree clean at start (`git status --short` empty).
- Read BRIEF_common.md, BRIEF_docs_final.md.
- Next: read BRIEF_docs_inc1.md, progress/docs_inc1.md, OWNER_QUESTIONS.md, INC1 notes,
  hand-backs fix_r1/fix_r2/prep_a2/prep_b2/prep_d2, clearance.md (does not exist yet).

## 2026-09-05 step 1 — reading (DONE for: briefs, docs_inc1, OWNER_QUESTIONS, INC1 notes §1/§2)
- `$SP/progress/clearance.md` DOES NOT EXIST (`ls $SP/progress/clearance*` → empty dir listing).
  The clearance reviewer is still running; I proceed without it and say so in the hand-back.
- OWNER_QUESTIONS.md read in full (358 lines): OQ-1..OQ-29 + Q-R1-1..4 + Q-R2-1..3.
- RETIRE_SWAP_ROUTE_INC1_NOTES.md §1 (round 1, 8 lenses: F-L7-1/F-L1-1/F-L2-1 spine adjoint;
  F-L3-1 P7 ordering; F-L6-1 stale-header retired family; F-L7-2/F-L5-1 in-loop discharge;
  F-L3-4/3/L4-1/L5-6) and §2 (round 2: F-R1-1 once-only collapse, F-R1-2 over-decline,
  the ⭐ once-runs table, Q-R2-1/2/3) read.
- Next: hand-backs fix_r1 / fix_r2 / prep_a2 / prep_b2 / prep_d2, then measure counts.

## 2026-09-05 step 2 — MEASUREMENTS (every number I will write, with its command)
| number | command | result |
|---|---|---|
| lit fixture corpus | `ls ir-pass/test/*.ll \| wc -l` | **1656** |
| XFAIL grep | `grep -l XFAIL ir-pass/test/*.ll \| wc -l` | 9 (prose; lit reports 1) |
| ctest total | `ctest --test-dir build -N \| tail -1` | **339** |
| ctest e2e | `ctest -N -R '^e2e-'` | **329** |
| ctest e2e-slice | `ctest -N -R '^e2e-slice-'` | **302** |
| ORACLE ctest total | `ctest --test-dir $SP/wt/pre-3qlq/build -N` | 327 (e2e 317, slice 293) |
| entry delta | `comm` over the two `ctest -N` name lists | **+15 added / −3 removed** (names in CLAUDE.md) |
| matrix expected rows | `grep -c '^m_' tools/loop_twin_matrix.expected.txt` | **245** |
| quarantine cells | `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` | **29** |
| quarantine classes | `grep -o 'class *[A-C]' … \| sort \| uniq -c` | **6 A / 21 B / 2 C** |
| `--allow-unproven` slices | `grep -B14 'allow-unproven")' tests/e2e/CMakeLists.txt` | **4** (`slice_loop_break{,_qq,_qq_derived,_qq_i64}`) |
| goldens | `ls tests/e2e/*.expected.log \| wc -l` | **304** |
| `cqrt_rz_i1` lines in goldens | `grep -h 'cqrt_rz_i1' tests/e2e/*.expected.log \| wc -l` | **168** |
| non-i1 `cqrt_rz` in goldens | grep | **0** |
| `cqrt_rz_*_controlled` in goldens | grep | **0** |
| kickback emission sites | `grep -rn 'markBranchPhaseGate' ir-pass/src` | **6 calls**, 4 files, 5 emitters |
| `NestedRouteEmit.cpp` | `ls` | **absent** (deleted) |
| `CondTreeEmit.{h,cpp}` | `ls` | present |
PASS PROBES on the MERGED main binary `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
(hand IR under `$SP/docs_final_work/`):
- retired family `@cq_phi_si32` with a TAINTED arg-0 → exit 1
  `cq rotation lowering: retired register-form cq_phi_si32; use the register-free void cq_phi(double)`
- same family CONST-FOLDED arg-0 under `if (q==5)` (F-L6-1's third path) → exit 1, SAME string
- same family with a WRONG prototype but CALLED → exit 1, SAME string
- DECL-ONLY retired family (right or wrong prototype, no call) → **exit 0, silent** (OQ-29)
- a module DEFINING `void @cq_phi(double)` with a `store` body → **exit 0**, the definition is
  discarded and the call lowers as a kickback (2 `cqrt_rz_i1` lines = 1 decl + 1 call); the body
  never executes. Q-R1-3 / OQ-21a still OPEN.
- §6.1a fixture counts re-measured on the merged binary:
  diamond 1/0/1, negated 1/2/1, two_calls 2/0/1, ifelse_tail_phi 3/2/1 (rz_i1 / cqrt_x / free),
  and `!cq.branchphase` == rz_i1 in all four.
⚠ CONTRADICTS MY BRIEF item 3: "the retired family now declines WHEN DECLARED" is FALSE.
  A DECL-ONLY retired symbol is SWEPT (exit 0); only a USE declines. That is OQ-29's own
  disposition, deliberate and argued — I write the measured behaviour.

## 2026-09-05 step 3 — CLAUDE.md edits (a)(b)(c)(d)(e) DONE
- (d) `--allow-unproven`: "five" → **four**, with the deleted fifth named and the reason.
- (c) quarantine: NEW ⚠ blockquote after the drbq-Inc-3 paragraph — 245 expected rows /
  29 quarantined cells / 6 A + 21 B + 2 C / `.register.txt` = frozen history / the
  `phi_surface_of_header()` single spelling / the second boundary control is now an
  INSTANCE of class A / selftest 12 → 27 cases.
- (a) ctest count: `# 327 ctest entries` → `# 339 ctest entries` + a dated 3qlq entry naming
  all 15 additions and all 3 removals with reasons; old paragraph retained as `# was 327 …`.
- (b) `ir-pass-lit`: 1582 → **1656**, with +91 / −17 / 473-modified split, the four new
  fixture families with accept/decline counts, the "emitted Rz set is `cqrt_rz_i1` ONLY"
  sentence (D3), and an explicit statement that I did NOT run lit.
- (e) CORRECTNESS-RISK: Inc-1 record appended after the Inc-0 paragraph — the three confirmed
  classes + their fix mechanisms, the two in-loop leaks, Q-R1-1, and the two standing lessons.
- Next: (f) Rule 7, (g) Where Things Live, (h) audit tool row.

## 2026-09-05 step 4 — CLAUDE.md (f)(g)(h) DONE
- (f) Rule 7 opening ⚠ retensed to SHIPPED + "the kickback is the phase-arm lowering at EVERY
  site (nest and switch USED to keep the route)"; the drbq-2a `cqrt_rz_<W>_controlled` sentence
  marked HISTORY with its date; the "still holds verbatim for the nest and the switch /
  `Rz|0⟩=|0⟩` freed clean" sentence marked FALSE in both halves with the reason.
  Also the Correctness-Risk `SwapRouteEmit` paragraph (all three phase-arm forms, with "all
  three put a TENSORED per-qubit Rz on q" as the reason not to restore either) and the
  "Method matches arm class, not convenience" bullet.
- (g) Where Things Live: RotationLowering row (`emitRz` DELETED, no `phi → cqrt_rz_<W>` row),
  ControlDetect row (kickback emitters; `NestedRouteEmit.cpp` DELETED), NEW `CondTreeEmit`
  row, AngleSelectEmit row (the two stems no longer share a lowering; the Rz stem performs NO
  subtraction so the rounding fence has no subject — "do not migrate a fence between stems"),
  Uncomputation/ChainWalk row (the `!cq.branchphase` record + the `preservesBorrowedParent`
  clause (1) that soundly still admits it by name), `include/CQ.h` row (14 × 2 + one
  `void cq_phi(double)`).
- (h) NEW `tools/golden_multiset_audit.py` row: `--epic 3qlq`, the 33/1/1/10/26 classification,
  the selftest, NOT-a-ctest-entry, and the DELETED-golden status (corrected: it no longer
  crashes — `golden_multiset_audit.py:1311`).
- Key Prohibitions: the `_controlled` reserve bullet gains "the Rz half has no minter at all".
- Docs map: the 3qlq PRD + INC1 notes + inc1-records added.
- CLAUDE.md diff so far: +293 / −45.
- Next: ROADMAP.md.

## 2026-09-05 step 5 — ROADMAP.md DONE (+102 lines)
- Phase 4 heading: `[4.0–4.5 DONE]` → `[4.0–4.5 DONE; **the route is RETIRED FOR PHASE ARMS**,
  2026-09-05]`, followed by a ⚠ STATUS blockquote placed BEFORE the increment list (why the
  tensored Rz is not an oracle; Inc 1 shipped on branch `3qlq-inc1` merge `be4e2ea` with an
  explicit ⚠ to re-point at the `main` commit; VALUE arms still route and are Inc 2, so
  `cqrt_cswap` still has minters — the value path + `AbortParkEmit`; the three phrases that
  must stop being quoted as phase-arm invariants; the three confirmed miscompiles).
- Phase 11 freeze: NEW ⚠ blockquote "THE FREEZE LIST NOW HAS A SUBTRACTION SIDE" —
  `cqrt_rz_<W>` (W>1) declared/unemitted; `cqrt_rz_<W>_controlled[_inv]` declared/unemitted
  with NO minter left; `cqrt_cswap` still minted (value path + AbortParkEmit) until Inc 2;
  `cqrt_ry_<W>_controlled` unaffected; and the owner's freeze-gate question (delete vs freeze
  declared-unemitted, PRD §12 Q1). CQ.h deliverable: "14 × 3 = 42 + 3 macros" → 14 × 2 + the
  single `void cq_phi(double)` + 2 macros + `cq_ry` + `cq_invert_*`.
- drbq Inc-3 paragraph: the "15 cells / 273 cells" quarantine figures marked 2026-09-04
  history and re-measured (245 rows / 29 cells / 6 A + 21 B + 2 C / `.register.txt`).
- Next: frontend.md + backend.md.

## 2026-09-05 step 6 — frontend.md / backend.md / PRD errata DONE
backend.md:
- §3.2 exact-name blockquote + §6.1a status blockquote retensed (SHIPPED, not "this branch
  set"); the §6.1a header block now says what the kickback REPLACED and why.
- §6.1a retired-family TABLE REWRITTEN from 3 rows to 4, all MEASURED on the merged binary:
  any USE declines (tainted / const-folded / wrong-prototype), decl-only is swept. The old
  "row 3 is OPEN, two of three rows are silent" warning is REPLACED by the F-L6-1 story +
  the decl-only narrowing's argument and its open owner question.
- §6.1a NEW paragraph "beyond the single compare" (compound tree, nest, switch) and a NEW
  "the real traces, from committed goldens" block quoting three goldens verbatim
  (`slice_control_seq_grover`, `slice_control_phase_angle_select`, `slice_control_phase_nest`)
  + the byte-identity of the nest and `&&` goldens.
- §11.3 part-A/part-B ⚠ resolved: both parts merged; the measured evidence (1661 fixture
  outputs, 35 Rz, 0 non-i1; 0 non-i1 and 0 `_controlled` in 304 goldens).
frontend.md:
- §3.3 Status blockquote retensed to SHIPPED with the pre-merge state as history.
- §7 phase-arm bullet retensed + "the lowering at every phase site" list.
- The reserved-name paragraph: `void(double)` prototype decline MEASURED both decl-only and
  called; the retired family's reserved-name string added; the DEFINED `@cq_phi` re-measured
  on the merged tree (exit 0, definition discarded, calls read as branch phases) and kept as
  the OPEN owner question Q-R1-3 / F-L6-6.
PRD:
- NEW `## 0. ERRATA` block (E1–E9) before §1, dated, pointing at the notes: E1 §3/§7.1
  "freed clean" false for `t`; E2 §9 per-bit row false→fixed→true with the measured golden
  counts + the two uncovered shapes; E3 §6.3 N-per-arm narrowed (diamond accepts, if/else
  declines); E4 P5 has no plain-C customer (7 spellings measured) and ships hand-IR only;
  E5 P6 does not reach P2 in a loop; E6 three §6.3 rows moved incl. the Q+Q LAYER move;
  E7 the measured migration; E8 the §12 assumptions as exercised; E9 the three confirmed
  miscompiles + "budget a third round".
- Status header: SHIPPED for Inc 0/1, NOT for Inc 2; `NestedRouteEmit` marked deleted.
- Next: sweep + consistency checks, then commit.

## 2026-09-05 step 7 — checks + COMMIT
Checks (all cheap; NO ctest, NO lit — a docs commit touching no pass source, no fixture,
no golden and no harness has nothing for those layers to witness, Rule 19; I state that
rather than implying coverage):
- markdown fence parity + table-column raggedness, 5 files, NOW vs the base commit
  (`/tmp/mdchk.py`): all fence counts EVEN; backend.md 40 → 42 (my one new fenced block);
  **0 new ragged tables** (the PRD's 2 are pre-existing, same count in base).
- `include/CQ.h` after the comment edit: `phi_surface_of_header()` (the instruments'
  surface classifier) still returns `void` for the shipped header and `register` for the
  oracle's; `clang -Iinclude -include CQ.h -O1 -Wall -Wextra -fsyntax-only` clean.
- final sweep `grep -rn 'cq_phi(' docs/*.md README.md CLAUDE.md` minus one-argument
  spellings: every remaining two-argument spelling is an explicit reference to the retired
  form, annotated as such.
- sweep for `this branch set` / `not on main` / `not yet at HEAD` across docs+README+
  CLAUDE.md+ROADMAP.md: **0 hits** (all retensed).

COMMIT **71a780b** on branch `3qlq-inc1`, 6 files, **+708 / −112**:
CLAUDE.md, ROADMAP.md, docs/backend.md, docs/frontend.md,
docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md, include/CQ.h (comment only).
`git show --stat 71a780b` confirms nothing under ir-pass/, tests/, tools/, runtime/ or any
CMakeLists.

# ======================= HAND-BACK (docs_final) =======================

## 1. What shipped
Branch `3qlq-inc1`, ONE commit **`71a780b`** (parent `cd2f071`), 6 files,
**+708 / −112**. DOCS + ONE HEADER COMMENT. `git show --stat` confirms nothing under
`ir-pass/`, `tests/`, `tools/`, `runtime/`, or any `CMakeLists.txt`; no CHECK/RUN line
and no golden was edited.

| file | changed line ranges (post-commit numbering) | what |
|---|---|---|
| `CLAUDE.md` | **194–220** (Rule 7 opening ⚠ + the drbq-2a history marker + the "still holds verbatim for the nest and the switch" retirement), **862–1007** (the Inc-1 CORRECTNESS-RISK record), **1015–1040** (the `SwapRouteEmit` / nest paragraph), **1232–1259** (the quarantine ⚠ blockquote), **1571–1578** ("method matches arm class" bullet), **1673–1706** (the ctest-count entry), **1758–1764** (the loaded full-run data point), **1791** (the `ir-pass-lit` line), **1891–1903** (`--allow-unproven` four + the long-pole correction), **1966–1970** (`_controlled` prohibition), **2053–2081** (Where Things Live rows + the audit-tool row + the docs map) | +346 / −45 |
| `ROADMAP.md` | **345–394** (Phase 4 heading + STATUS blockquote), **781–794** (the quarantine figures), **1479–1514** (Phase 11 freeze subtraction side + the CQ.h deliverable) | +102 |
| `docs/backend.md` | **146** (§3.2 exact-name tense), **370–374** (§6.1a status), **419–472** (the compound/nest/switch paragraph + the real-traces block), **496–537** (the retired-family table + F-L6-1 + the decl-only narrowing), **1186** / **1199–1215** (§11.3 part-A/part-B resolved) | +148 |
| `docs/frontend.md` | **299–308** (§3.3 Status), **411–433** (the reserved-name paragraph), **720–724** (§7 phase-arm bullet) | +59 |
| `docs/prd/…/retire-swap-route-PRD.md` | **3–10** (Status header), **18–150** (the NEW `## 0. ERRATA` block, E1–E9) | +144 |
| `include/CQ.h` | **3–19** (the file's top block COMMENT only) | +21 |

## 2. Every number I wrote, with the command that measured it
| number | command | result |
|---|---|---|
| lit fixture corpus | `ls ir-pass/test/*.ll \| wc -l` | **1656** (oracle 1582) |
| fixture delta | `git diff --name-status 52d7764 HEAD -- ir-pass/test \| awk '{print $1}' \| sort \| uniq -c` | **91 A / 17 D / 473 M** |
| `control_phase_kickback_*` | `ls ir-pass/test/ \| grep -c '^control_phase_kickback'` + `grep -l 'RUN: not'` | 44 (27 accept / 17 decline) |
| `control_phase_switch_*` | same | 10 (3 / 7) |
| `control_phase_nest_*` | same | 12 (5 / 7) |
| `control_angle_select_phase_*` | same | 12 (3 / 9) |
| ctest total | `ctest --test-dir build -N \| tail -1` | **339** (oracle build 327) |
| ctest `^e2e-` | `ctest -N -R '^e2e-'` | **329** (oracle 317) |
| ctest `^e2e-slice-` | `ctest -N -R '^e2e-slice-'` | **302** (oracle 293) |
| entry delta + NAMES | `comm` over the two `ctest -N` name lists | **+15 / −3** |
| matrix expected rows | `grep -c '^m_' tools/loop_twin_matrix.expected.txt` | **245** |
| quarantine cells | `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` | **29** |
| quarantine classes | `grep -o 'class *[A-C]' tools/loop_twin_matrix.quarantine.txt \| sort \| uniq -c` | **6 A / 21 B / 2 C** |
| `--allow-unproven` slices | `grep -B14 'allow-unproven")' tests/e2e/CMakeLists.txt` | **4** |
| goldens | `ls tests/e2e/*.expected.log \| wc -l` | **304** |
| `cqrt_rz_i1` golden lines | `grep -h 'cqrt_rz_i1' tests/e2e/*.expected.log \| wc -l` | **168** |
| non-`i1` `cqrt_rz` in goldens | `grep -h 'cqrt_rz_' … \| grep -v 'cqrt_rz_i1(' \| wc -l` | **0** |
| `cqrt_rz_*_controlled` in goldens | grep | **0** |
| kickback emission sites | `grep -rn 'markBranchPhaseGate' ir-pass/src` | **6 calls**, 4 files, 5 emitters |
| per-bit golden discharge | `grep -c` on `slice_control_phase_perbit_loop{,_k32}.expected.log` | K=4: 4 `and_hl` / 4 `and_unc` / 8 free; K=32: 32 / 32 / 64 |
| §6.1a fixture counts | `build/ir-pass/cq-opt -passes=cq-lowering -S <fixture>` + grep | diamond 1/0/1, negated 1/2/1, two_calls 2/0/1, ifelse_tail_phi 3/2/1; `!cq.branchphase` == `rz_i1` in all four |
| `NestedRouteEmit.cpp` | `ls` | absent |
| `CondTreeEmit.{h,cpp}` | `ls` | present |
| markdown integrity | `/tmp/mdchk.py` (fence parity + table raggedness, now vs base) | all even; **0 new ragged tables** |
| CQ.h surface classifier | `python3 -c "import loop_twin_matrix as m; m.phi_surface_of_header(...)"` | shipped → `void`, oracle → `register` |
| CQ.h syntax | `clang -Iinclude -include CQ.h -O1 -Wall -Wextra -fsyntax-only` | clean |

PASS PROBES on `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (hand IR in
`$SP/docs_final_work/`), each named in the docs that quote them:
- retired `@cq_phi_si32` with a TAINTED arg-0 → exit 1 `cq rotation lowering: retired
  register-form cq_phi_si32; use the register-free void cq_phi(double)`
- same, CONST-FOLDED arg-0 under `if (q==5)` (F-L6-1's third path) → exit 1, SAME string
- same, WRONG prototype but CALLED → exit 1, SAME string
- DECL-ONLY retired family (right or wrong prototype) → **exit 0, silent**
- `@cq_phi` with a WRONG prototype, decl-only AND called → exit 1
  `cq rotation lowering: unsupported declared prototype for cq_phi`
- a module DEFINING `void @cq_phi(double)` with a `store` body → **exit 0**, definition
  discarded, call lowered as a kickback, body never runs

NOT RUN, deliberately: `ir-pass-lit`, `frontend-lit`, e2e, the full `ctest`, the twin
matrices, the golden audit. This commit changes no pass source, no fixture, no golden and
no harness, so no layer can witness it (Rule 19). **I make no claim about their colour.**
For the record and with attribution: the ORCHESTRATOR's full run at `be4e2ea`
(`$SP/progress/orch_full_ctest.log`) was **338 of 339 passed, 399 s wall**, the single red
being `ir-pass-lit` on `lowering_reject_break_phase_answer.ll` — which HEAD's own commit
`cd2f071` re-points. `e2e-loop-twin-matrix` PASSED (399 s).

## 3. Findings that are NOT mine to decide / contradict a brief or a hand-back

**D-1 — MY BRIEF item 3 is FALSE: "the retired family now declines WHEN DECLARED".**
MEASURED on the merged binary: a DECL-ONLY `@cq_phi_<sfx>`, right or wrong prototype, is
**swept at exit 0**; only a USE declines. That is not a defect — it is the deliberate,
argued `!use_empty()` narrowing (the set that can reach a wrong unitary is exactly the set
with a use; a decl-only decline would have reddened ~490 fixtures mid-migration). I wrote
the measured behaviour, and recorded the narrowing's open owner question (OQ-29: the
second reason is spent now that the corpus is migrated; tightening is one clause and ~5
fixtures). Reproducers `$SP/docs_final_work/legacy_declonly.ll`, `legacy_wrongproto.ll`.

**D-2 — MY BRIEF item 1(a) says "the 14 enabled; the 4 removed". MEASURED: +15 / −3.**
The name-level `comm` against the ORACLE build is the ground truth for a doc, and it says
11 slices + 4 `compare_files` gates ADDED and 3 entries REMOVED. prep-b2's "4 removed"
counts `slice_control_phase_nest_deep`, which prep-b ADDED and prep-b2 REMOVED inside the
branch set — it never existed in the shipped suite, so it is not a removal from it. Same
arithmetic, different denominator; I wrote the measured one and named it as measured
against 52d7764.

**D-3 — the brief says the main checkout is at `be4e2ea`; it is at `cd2f071`** (one
commit later, the `lowering_reject_break_phase_answer.ll` re-point). Everything I measured
is at `cd2f071`. The one consequence for a reader: the orchestrator's full-ctest log is a
`be4e2ea` measurement and its single red is what `cd2f071` fixes, so **nobody should quote
that log as the colour of this tree.** I say so wherever I cite it.

**D-4 — `$SP/progress/clearance.md` DOES NOT EXIST**; the clearance reviewer was still
running. My brief told me to read it "if it exists". Anything the clearance finds that
moves a fence, a count, or a disposition **lands after this commit** and is not reflected
in it. Two places are most exposed: PRD §0's E3/E4/E5 (accept-class statements) and
CLAUDE.md's Inc-1 record.

**D-5 — an OPEN owner question I re-measured and did NOT close: a module that DEFINES
`void @cq_phi(double)`** compiles at exit 0 with no diagnostic, the definition discarded
and the body never run. `cq_phi`/`void(double)` is a short, collidable C signature.
`fix_r1.md` files it as Q-R1-3 (= OQ-21a) and it is still open; `frontend.md` §3.3 now
states the measured disposition and names it as undecided, rather than asserting a fence.

**D-6 — a stale count OUTSIDE my file scope, for whoever owns it.**
`tests/e2e/CMakeLists.txt:3998` still phrases the quarantine as "these 15 cells" (it is 29
now). It is a comment inside a CMake file, which my brief excludes; one line.

**D-7 — two figures I quote are NOT mine and are labelled so in the docs**: the round-2
lens's "1661 fixture outputs, 35 emit an Rz, 0 at any other width" and prep-b2's final
`--epic 3qlq` audit tally (29 / 1 / 1 / 11 / 30 over 72 goldens). Both carry an explicit
"not re-measured for this doc pass" note at the point of use.

## 4. What is left
1. **Re-point ROADMAP Phase 4's "branch `3qlq-inc1`, merge `be4e2ea`" at the commit that
   lands the epic on `main`.** The blockquote carries a ⚠ saying so.
2. **`docs/backend.md` §8 "Controlled-form lowering" is still wholesale stale** — §8.3
   describes the DELETED controlled-op design and §8.5 calls Phases 4/5 prototypes. Not
   3qlq-specific, so I did not touch it (docs_inc1 flagged it too). A reader sent to §8 by
   `example.md`'s table lands on the retired design.
3. **OQ-1 (the linear rule is enforced for tainted PURE ops only)** is still open and still
   documented as a gap in `frontend.md` §3.2. Untouched.
4. The PRD's §5–§9 bodies are deliberately LEFT AS WRITTEN, with §0 ERRATA as the
   override. If the owner would rather have them rewritten in place, that is a second pass
   and it destroys the design-vs-built diff.
