# MERGE_C_1 — `classical-measure` × `main` 10fe8b4, landing 1 (Track C bd `21mg` + Track L's L-0 H-10 pins)

Merge-and-gate record, 2026-09-13. Worktree `/Users/sorenwilkening/Desktop/CQ_21mg`,
branch `classical-measure` from `main` **01c89b5**, merged with **`main` 10fe8b4**
(= 01c89b5 + the four 2026-09-13 orchestrator docs commits: the R/L/M scoping records,
the R-2 rival audit, the review brief and this merge brief). Review verdict
**CLEAR-WITH-ITEMS** (`review_C_r1.md`, 6 items, none a miscompile). Not committed
(nothing to commit: the merge was a FAST-FORWARD), not pushed; the squash is the
orchestrator's. Instance of `../MERGE_BRIEF_TEMPLATE.md` + `MERGE_BRIEF_C.md`.

**Worktree tip after the merge: `10fe8b4`.** The branch's own work is still UNCOMMITTED —
`git status --porcelain | wc -l` = **27** (3 modified: `ir-pass/{include,src}/MeasureLowering.{h,cpp}`
+ `tests/e2e/CMakeLists.txt`; 24 untracked: the 8 new `ir-pass/test/*.ll`, the 10 new
`tests/e2e/` files, and 6 record entries — `GATES.md`, `IMPL_C.md`, `MERGE_C_1.md`,
`review_C_r1.md`, `probes/`, `review_C_r1_probes/`).

Three binaries:

| label | `cq-opt` sha256 (16) | `libCQPass.so` (16) | what it is |
|---|---|---|---|
| ORACLE | `fbbe0820ef4b176a` | `40e9c7a51e8120bb` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, e96f89c, **re-hashed before first use, matches PROTOCOL.md**, never rebuilt |
| SUBJECT (pre-merge) | `c662bd0ca0e7d8a4` | `52d1136c3c7d9049` | the implementer's build, `GATES.md` |
| **MERGED** | **`c662bd0ca0e7d8a4`** | **`52d1136c3c7d9049`** | this tree, after the merge + the four comment edits + reconfigure + `cmake --build build -j8` (BOTH targets) |

---

## §0 FINDINGS

**ONE, and it is a finding about MY OWN instrument, not about the compiler.**

**F-M1 — the first run of the L-0 injection matrix reported `n/a` for 4 of the 6
mutants the brief names, and `n/a` is indistinguishable from "cannot apply".** The
mutators anchored on `^header:\n`, but LLVM prints a block label with its
`; preds = …` comment, so `_body_insert` returned `None` and `extra_x_on_register`,
`extra_free`, `extra_uncontrolled_ry` and `extra_cswap` were silently skipped —
`MISSED=0` while four of the mutants the pins exist for had never been tried. Fixed
(`^header:[^\n]*\n`), the comment written into the script at the site, and re-run:
**18 mutations, 0 MISSED, 0 DIRTY, 0 n/a** (§4b). This is CLAUDE.md Rule 12(c)
one level up — *a checker that reports a clean matrix because its subject never ran
pins nothing* — and it is exactly why the matrix is validated by MUTATION and not by
re-reading the prefixes.

Stated as the four questions that could have produced a compiler finding, each
answered by measurement:

1. **Did the merge move anything?** It could not: `git merge main` was a
   **FAST-FORWARD** over 168 docs-only files (§1), and the MERGED binary hashes
   **byte-identically to the pre-merge SUBJECT** — the mechanical proof that the four
   review edits were comment-only.
2. **Did anything the ORACLE accepts stop compiling?** No: **0** ACCEPT→DECLINE over
   the delta corpus, and **0** over the 3021 cited rows (§3).
3. **Did any program both binaries accept get a DIFFERENT circuit?** No: **20**
   both-accept rows in the delta, **0** md5 differences; the cited sweep records the
   same over its 3021 (§3).
4. **Do the two new pins pin a stream this landing changed?** No — and that is their
   point: all four Track-L rows are `A:<md5>|A:<md5>` with the **same** md5 on ORACLE
   and MERGED (§3), so they pin a SHIPPED accept, as bd `boi6` H-10 intends.

---

## §1 CONFLICTS — none, and the merge produced no commit

```
$ git -C /Users/sorenwilkening/Desktop/CQ_21mg status --porcelain | wc -l     # before
      23
$ git merge main
Fast-forward … 168 files changed, 5470 insertions(+)
$ git log --oneline -1
10fe8b4 docs(orchestrator): Track C merge-and-gate brief (landing 1, with the L-0 H-10 pins)
```

`main`'s four commits since the branch base add **only** files under
`docs/prd/…/session-2026-09-13-orchestrator/` (`git diff --name-status 01c89b5..main`:
168 × `A`, zero under `ir-pass/`, `tests/`, `include/`, `runtime/`, `tools/`). HEAD was
the merge base, so the merge is a fast-forward: **0 conflicts, no merge commit, nothing
for me to commit.** The branch's uncommitted work survives untouched (`git status` before
and after differ only by the three files below).

**One pre-merge action was required and it is recorded because it is the kind of step
that silently loses content.** Three of `main`'s new files already existed in the
worktree as UNTRACKED copies (`MERGE_BRIEF_TEMPLATE.md`, `trackC/MERGE_BRIEF_C.md`,
`trackC/REVIEW_BRIEF_C_r1.md` — the orchestrator handed them over by file, then committed
them), and git refuses a checkout that would overwrite an untracked file. Each was
verified **byte-identical to `main`'s version** (`git show main:<path> | diff -q - <path>`
→ identical, 3/3) and only then removed, so the merge restored the same bytes under
version control. No other path was touched.

---

## §2 RESURRECTIONS — none; the duplicate-body scan is clean

No fixture was `git mv`'d on either side, so the template's step-6 trigger did not fire;
the scan was run anyway (8 fixtures land here) and is reported because a clean scan is
only worth what its baseline is:

```
$ python3 <sha-256 over each ir-pass/test/*.ll's non-comment lines>
files=1901 same-body groups=9
```

**8 of the 9 groups exist on `main` already** and are the deliberate
same-module/different-prefix pairs `MERGE_l4x4_2.md` §2 enumerated
(`control_swap_{diamond,ifelse}{,_derived}`, the two `angle_select` pairs, the
`inplace_ry` stale-alias pair, the `predmux` pair, the nested-swap reject pair,
`spec_reject_callbr` / `spec_overaccept_probe_callbr_visible`).

**The 9th is NEW and it is DECLARED, not an artefact**: this landing's
`lowering_measure_round2_sixfive_handle.ll` has the same IR body as the pre-existing
`control_classical_call_arm_accept.ll`. Its own header says so in as many words
(`:28` *"The shape is `control_classical_call_arm_accept.ll`'s (which pins the 6.5
stream…)"*, `:94` *"…owns the 6.5 stream"*) — the same module under two prefix sets,
one pinning the 6.5 lowering and one pinning that a round-2 `%out` measure takes the
QUANTUM branch. Nothing to dispose of.

---

## §3 CORPORA — 3021 rows CITED + 46 rows RUN, 15 movers, all on this landing's own strings

**Why a delta and not a re-run.** `MERGE_BRIEF_C.md` §"Corpus" instructed a full re-sweep
on the ground that *"the merged binary has a new hash (item A)"*. **That premise is false
as measured**: the four review edits are comment-only, and the rebuilt `cq-opt` is
`c662bd0ca0e7d8a4…` — the very binary the implementer swept. PROTOCOL.md's
non-redundancy rule is explicit that a gate result is a fact about a BINARY, so the
3021-row sweep is **CITED** (`GATES.md`, impl, 12:33: *1 MOVER, 0 ACCEPT→DECLINE, 0
decline-string changes, 0 both-accept md5 differences, 1 pre-existing CLANGERR on both*)
and what that sweep could not have covered was **RUN** here
(`probes/corpusC_delta.sh` → `probes/corpus_delta_c662bd0ca0e7d8a4.txt`):

| delta corpus | why it was not in the cited sweep | rows |
|---|---|---:|
| `trackC/review_C_r1_probes/*.c` | written by the REVIEWER at 12:50, after the 12:33 sweep, and living in the worktree (`corpusC.sh` reads probe dirs out of the ORACLE checkout) | 36 |
| `trackL/ready/*.c` | the two slices the H-10 pins register | 2 |
| the 8 fixtures this landing ADDS to `ir-pass/test` | `corpusC.sh` deliberately takes `ir-pass/test` from the ORACLE checkout so added fixtures are not miscounted as movers — they still owe a verdict pair | 8 |
| | | **46** |

```
rows=46 movers=15 | D->A=14  A->D=0  D->D(string move)=1 | both-accept=20 of which md5-differ=0
D->A oracle strings: ['D:cq_measure_<sfx> operand not recognized; expected a tainted i32 handle']   <-- one string, and it is this landing's
```

* **14 DECLINE→ACCEPT**, every one with the ORACLE verdict `cq_measure_<sfx> operand not
  recognized; expected a tainted i32 handle` — the retained string bd `21mg` exists to
  narrow. By name: `r09_measure_of_measure`, `r10_measure_theta_seed`,
  `r11_measure_angle_double`, `r12_measure_undef_phi`, `r18_measure_classical_noinline`,
  `r20_measure_in_loop_body`, `r22_measure_classical_float`,
  `r26_measure_classical_array_elt`, `r27_measure_external_arg`,
  `r28_measure_volatile_local`, `r29_measure_global`, and the three accept fixtures
  `control_measure_classical_bool_owner.ll`, `lowering_measure_classical_accept.ll`,
  `lowering_measure_classical_mixed_accept.ll`.
* **1 DECLINE→DECLINE string move**, and it is the intended one:
  `lowering_reject_measure_undef_operand.ll`, old blanket string →
  `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a
  defined value`. That fixture IS the new string's Rule-12 mirror.
* **0 ACCEPT→DECLINE. 0 both-accept md5 differences. 0 CLANGERR.**
* **All 14 accepting movers re-lowered through STRICT stage 2b: 14/14
  `0 violation(s), 0 unproven`** (11 probes at `1 rail mint … 1 left allocated, 0 free`,
  `r27` and `lowering_measure_classical_accept.ll` at `0 rail mint(s)` — the classical
  path minting nothing at all, which is the Rule-3 property that matters —
  `lowering_measure_classical_mixed_accept.ll` at 2/2 left allocated, and
  `control_measure_classical_bool_owner.ll` at `5 rail mint(s) of which 4 left allocated,
  1 cqrt_free site(s): 1 verified`).

**The four Track-L rows are non-movers by design** — `A:e226dd02|A:e226dd02`,
`A:b7e082a9|A:b7e082a9` (the two fixtures) and `A:ded536f1|A:ded536f1`,
`A:590f946a|A:590f946a` (the two slices): ORACLE and MERGED emit the *same* module, which
is the whole claim of a pin on a SHIPPED accept.

---

## §4 THE LANDING-SPECIFIC ITEMS

### 4a. Item A — the four comment-only edits from `review_C_r1.md`

All four were applied as comments and **nothing else**; the unchanged binary hash is the
proof, not the intention.

| review item | site | what the comment now says |
|---|---|---|
| 1 (DOC) | `ir-pass/src/MeasureLowering.cpp`, the classical type-mismatch guard | that it **REUSES `kMsgOperand`**, a string naming neither of this case's facts (the operand is CLASSICAL by construction; the mismatch is against the CALL's own return type, not against `i32`); why reuse is nevertheless right (mirrored character-for-character by the negative fixtures, and the case is unreachable at HEAD); and that if it ever fires it MISDIRECTS, so the fix is a NEW string with its own fixture. The retirement trigger is kept and now hangs off that sentence. |
| 2 (DOC) | the `kMsgUndefOperand` comment | that `valueCarriesUndef` is **CONSTANT-ONLY** (`LiteralIntegrity.cpp:113-119` — a non-`Constant` returns false immediately), so the fence catches `cq_measure(undef/poison)` and `undef` nested in a constant and **nothing else**; that ground 3 ("the source read an uninitialized object") is therefore **broader than the predicate**, with the counter-example named and cited (`review_C_r1_probes/r12_measure_undef_phi.c` — that exact UB COMPILES); and that grounds 1 and 2 are the ones that cover what the predicate does. (L5.) |
| 3 (DOC) | `ir-pass/include/MeasureLowering.h` contract | that an externally-linked `int api_measure(int x){return cq_measure(x);}` now compiles to `ret i32 %x` with **zero `cqrt_*`**, why that is sound (a rail handle cannot cross a TU; an in-module quantum caller declines earlier at `cq specialization: callee measures under quantum lift`), with both probes cited. |
| 5 (DOC) | same contract block | that `cq_measure(cq_measure(q))` emits **ONE** measurement and both reads return its outcome, and **why one is the right number** (a projective measurement is idempotent, so re-measuring a collapsed register changes neither state nor value) — an unstated semantic ruling before this. |

Both new claims were **re-measured on the merged binary rather than copied from the
review**: `r27_measure_external_arg.c` lowers to `define i32 @api_measure(i32 noundef %0)
… ret i32 %0` with `grep -c 'call .*@cqrt_'` = **0**; `r09_measure_of_measure.c` — three
source `cq_measure` reads — emits exactly **one** `call i32 @cqrt_measure_i32(i32 %h)`;
`r17_measure_in_noinline.c` still declines `cq specialization: callee measures under
quantum lift`.

**Review items 4 and 6 were NOT acted on, deliberately** (`MERGE_BRIEF_C.md` A: *"if an
item needs more than a comment, do NOT do it; list it"*): item 4 is an OVER-DECLINE whose
admission owes a scrub of the arm block's dangling `taint.MeasureCalls` entry — a
predicate change and a bd issue, not a comment — and item 6 is a PRE-EXISTING leak
(byte-identical on the ORACLE). Both are the orchestrator's to file.

### 4b. Item B — Track L's L-0 H-10 pins, installed and validated

Six files copied verbatim from `trackL/ready/` (verified `diff -r` identical to the MAIN
checkout's copy, so "which checkout" is not a question): 2 `.ll` → `ir-pass/test/`
(glob-picked), 2 `.c` + 2 `.expected.log` → `tests/e2e/`, and
`CMakeLists.lines.txt` appended **immediately after the
`e2e-phase-bool-loop-twin-identical` block** (file line 5181, exactly where
`ready/README.md` says), then `cmake -S . -B build …` re-run because new `add_test`
entries need a reconfigure.

1. **`lit --filter 'carried_theta_first'` → PASS 2/2** (of 1901 discovered), 1.45 s.
   These fixtures had **never been lit-validated** (the scoping row forbids it) and the
   brief allowed fixing a FileCheck syntax slip: **none was needed — not one character of
   either fixture was changed.**
2. **`ctest -R 'carried-theta-first'` → 3/3 passed**, 2.27 s (1.15 / 1.07 / 0.02), and all
   three ran again inside the full suite.
3. **Injection matrix** (`probes/inject_L0.py`, written here from `inject_C.py` — Rule 14,
   one runner, two mutation sets): **fixtures=2 mutations=18 MISSED=0 DIRTY=0 n/a=0**,
   after the F-M1 fix. Every mutant `ready/README.md` §3 names, with the prefix that
   actually reddens: `extra_x_on_register` → CHECK+**XCNT**, `extra_free` →
   CHECK+**FCNT**, `extra_uncontrolled_ry` → CHECK+**RYCNT**, `extra_cswap` →
   CHECK+**NOROUTE**, `handle_in_angle_slot` (the rail handle in the classical immediate
   slot) → CHECK, `gate_moved_out_of_body` → CHECK (the `header:`/`CHECK-NEXT` chain —
   note MDCNT canNOT see this one, a moved gate keeps the count at 1, which is why the
   extra mutant below was added), `drop_ry` → CHECK+RYCNT, `extra_alloc` → CHECK+**ACNT**,
   and `extra_rz_untagged` → CHECK+**MDCNT** (added here so the MDCNT/MDTAG count
   prefixes are exercised by an EXTRA gate, which is what `ready/README.md` says they are
   for).
4. **K-independence, re-measured once, no `-g`** (the README's own caution — debug
   metadata inflates the count):

   | source | lowered IR lines | trace lines |
   |---|---:|---:|
   | `trackL/probes/p2.c` (K=3) | **50** | 9 |
   | `trackL/probes/p2k1000.c` (K=1000) | **50** | 2003 |
   | `trackL/probes/p2u.c` (hand-unrolled K=3) | 42 | 9 |

   `diff` of the two lowered modules: the module-identity lines and **one** instruction,
   `icmp eq i32 %5, 3` vs `icmp eq i32 %5, 1000`. Reproduces `ready/README.md` exactly.

---

## §5 CUSTOMERS — four, on the MERGED binary

```
== C1a  trackC/probes/owner_2026-09-11_2218.c   (THE Track-C customer)
   opt exit=0, stderr 0 bytes
   free_pairing_check: 5 rail mint(s) of which 4 left allocated, 1 cqrt_free site(s):
                       1 verified, 0 violation(s), 0 unproven          [STRICT]
   trace lines: 15
   diff vs tests/e2e/slice_measure_classical_bool_twin.expected.log:  IDENTICAL
== C1b  probes/va.c
   opt exit=0, stderr 0 bytes, STRICT 2b 6 mints / 5 left allocated / 1 free verified
   trace lines: 19
   diff vs probes/va.trace:                                           IDENTICAL
== C2a  probes/owner_file_2026-09-13.c
   opt exit=1  owner_file_2026-09-13.c:99:9: in function main i32 ():
               cq controlled lowering: control flow under quantum control     [EXPECTED — Track M not landed]
== C2b  probes/vd.c
   opt exit=1  vd.c:10:14: in function main i32 ():
               cq controlled lowering: state prep seed is proven equal to the
               condition register under quantum control                       [EXPECTED — F2's string]
```

C1a is the finding this landing exists for: the owner's 2026-09-11 22:18 file, which
`main` e96f89c refused outright, compiles — and its 15 lines are byte-identical to the
golden of the same program with `cq_measure(b1)` DELETED, a stream the ORACLE reproduces
(`IMPL_C.md` §0). The two declines are recorded, not repaired: they are other tracks'.

---

## §6 GATES (verbatim; Rule 19 — the full suite is this row's, and it ran ONCE)

```
$ cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
-- cq e2e: stage-3 link via derived …/build/tests/e2e/cq_link.sh
-- Configuring done (7.1s) / Generating done (0.8s)

$ cmake --build build -j8                      # BOTH targets — never `--target CQPass` alone
[ 56%] Built target CQPass
[100%] Built target cq-opt

$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
c662bd0ca0e7d8a4db70bc8b410521e1ea946098ccce702d0c2c0ed2b2a1761b  build/ir-pass/cq-opt
52d1136c3c7d9049bf0d6de95b84cfe2c3f353a54457b9c30b5c655feb60a510  build/ir-pass/libCQPass.so
                                               # UNCHANGED from the SUBJECT ⇒ the edits were comment-only

$ cd build && lit -v ir-pass/test --filter 'carried_theta_first'
PASS: control_phase_kickback_rail_inloop_carried_theta_first_negated.ll (1 of 2)
PASS: control_phase_kickback_rail_inloop_carried_theta_first.ll (2 of 2)
Testing Time: 1.45s     Total Discovered Tests: 1901

$ ctest --test-dir build -R 'carried-theta-first' --output-on-failure
100% tests passed, 0 tests failed out of 3        Total Test time (real) = 2.27 sec

$ ctest --test-dir build -j6 --output-on-failure                      # ONCE, this row's only full run
 51/410 Test   #8: ir-pass-lit .......................   Passed   64.33 sec
 36/410 Test   #9: cq-opt-equivalence ................   Passed   38.87 sec
 17/410 Test  #10: frontend-lit ......................   Passed    9.95 sec
410/410 Test #318: e2e-loop-twin-matrix ..............   Passed  220.61 sec
100% tests passed, 0 tests failed out of 410
Total Test time (real) = 407.77 sec

$ cmake --build build --target cq-opt-equivalence-full
cq_opt_equivalence: compared 1901 fixtures, 0 mismatch(es)            # 92 s wall
```

No `-j` failure occurred, so nothing needed a serial re-run. No binary was relinked under
any measurement (the equivalence target's own "Built target" lines are no-ops — the build
was already current), and nothing was killed by pattern. The 7 new ctest entries all ran
inside the full suite (`e2e-slice-measure-classical-{bool,bool-twin,only}`,
`e2e-measure-classical-bool-twin-identical`,
`e2e-slice-control-phase-bool-carried-theta-first{,-unrolled}`,
`e2e-phase-bool-carried-theta-first-twin-identical` — all Passed).

---

## §7 COUNTS (by command, on the merged tree)

```
$ ls ir-pass/test/*.ll | wc -l                       1901      (1893 + 6 Track C + 2 Track L)
$ ls tests/e2e/*.expected.log | wc -l                 360      (355 + 3 + 2)
$ ctest --test-dir build -N | tail -1           Total Tests: 410      (403 + 4 + 3)
$ ctest --test-dir build -N -R '^e2e-'                400      (393 + 4 + 3)
$ ctest --test-dir build -N -R '^e2e-slice-'          358      (353 + 3 + 2)
$ ctest --test-dir build -N -R 'twin-identical'        32      (30 + 1 + 1)
$ grep -c '^add_test' tests/e2e/CMakeLists.txt        400
$ grep -c '^m_'   tools/loop_twin_matrix.expected.txt    259   ]  288 cells,
$ grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt  29   ]  UNCHANGED
```

Every count is the exact sum — there is no off-by-one here, because no fixture was
renamed on either side (§2). `runtime/`, `tools/opcode_table.yaml` and `include/` are
**UNTOUCHED**: no new frozen symbol, no ABI movement, so Rule 15's drift check is not in
play (and `ctest -R runtime` ran green inside the full suite regardless).

---

## §8 WHAT THIS ROW DELIBERATELY DID NOT DO

* **No commit, no squash, no push.** The merge was a fast-forward, so there was no merge
  commit to make; the branch's work stays uncommitted for the orchestrator's squash.
* **No re-run of the 3021-row corpus sweep** — CITED at the same binary hash (§3), which
  is PROTOCOL.md's rule, not a shortcut. What the sweep could not have covered was run.
* **No action on review items 4 and 6** (§4a) — a predicate change and a pre-existing
  leak; both are bd issues for the orchestrator, not comment edits.
* **No twin-matrix instrument runs** (`tools/loop_twin_matrix.py`,
  `angle_select_twin_matrix.py`, `inplace_twin_matrix.py`) — instruments, not gates;
  `e2e-loop-twin-matrix` IS a gate and ran green inside the full suite (220.61 s).
* **No edit to `CLAUDE.md`, `ROADMAP.md` or any PRD**, and no bd writes — the status
  merge and the issue filing are the orchestrator's, and this file is not a place where
  a rule may harden (L7).
* **Nothing written outside the worktree.** The ORACLE checkout was read (its `build/`
  only through `cq-opt`/`libCQPass.so`, never rebuilt) and never written; scratch lived
  in the session scratchpad.
