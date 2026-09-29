# Rule-13 review r1B — bd `test_C_libtooling-cepm` + bd `test_C_libtooling-3zr4` (surface B)

**Surface B**: the emitted circuits of the newly accepted programs, the movers, the 6.5
classifier change, and composition. The prediction's soundness and `LaterTaintOracle` belong to
r1A; where this round met them from the program side it says so and does not duplicate them.

## Header

| item | value |
|---|---|
| subject | branch `worktree-agent-a3c46257bc3bd028d`, commits `3a2d690e` + `7f0be42f`, diff `9a230646..7f0be42f` |
| subject `cq-opt` | `02522b6a4fdb8911eafe965ec6e3586370bee0f0a5df54f170738edd24af13d1` (verified) |
| subject `libCQPass.so` | `49e7c01f5c0ba2417e287ddc…` (verified) |
| oracle | `scratchpad/frozen/cq-opt.main_9a230646`, `3f6db37f5cf937b4d70f5736…` (verified) |
| round-1 subject (for one comparison) | `scratchpad/cepm/cq-opt.subj1`, `cb4ed3c2f6251bc7e85bf8dc` |
| COMPOSED binary (my one private build) | `scratchpad/rev_r1B_cepm` = `7f0be42f` merged with rhk5 `c89afa59` (the only conflict was in `CODE_MAP.md`, resolved to ours; the source merge was clean), `cq-opt` target only, `-j4` → `1c0a4e172a9b1f60f3b09ec3`. The worktree has been removed; the binary is kept at `scratchpad/r1B_cepm/cq-opt.comp` |
| rhk5 snapshot | copy of `agent-a7712272d6ca568e9/build/ir-pass/cq-opt`, `aa0dff29ea088cde195e222c` (that worktree has uncommitted round-1b edits, so this is NOT necessarily `c89afa59`'s build; I used it only for one twin check) |
| z0re binary | `scratchpad/z0re_bins/cq-opt.subj_r2`, `8441d60db8fd77b74bd7e660` (= the z0re worktree's current build) |
| time | about 95 minutes, with box load between 75 and 130 |

**What I ran, literally.**
- My own C probe pairs, each with a C side (the reading callee `h` over 4 TUs) and a T side
  (the hand-inlined twin `g(a); … k + 1`): 26 pairs on the subject **and** the oracle, both
  sides. Harness `probes/tw.sh`: `-O1`, `llvm-link`, stage 2 on both binaries, stage 2b, link,
  and a trace diff for argv `5 7`, `2 9` and `9 1`. Results are in
  `probes/results/my_probes_subject_vs_oracle.txt`.
- The implementer's 66-pair battery on the **composed** binary (`probes/twc.sh`):
  `probes/results/battery66_composed_cepm_rhk5_1c0a4e17.txt`, 43 of 66 twin-identical. I also ran
  16 battery pairs on the subject in my own harness; they agree with the implementer's
  `battery_subject_02522b6a.txt`.
- Streams read by hand (lowered `main` plus clones, or the trace gate by gate): `br`, `sw`, `lp`,
  `a04`, `a03`, `z3`, `yb`, `rt9`, `bri`, `tp`, `tpx`, `tps`, `tpk`, `vcone`, `pcm`, `dselq`,
  `measarg`, `lpq`, and the oracle's `sp`.
- One IR probe: `probes/ir/va_speculatable.ll`.
- Spot-check of one implementer claim: the 20 `spec_*_predicted_*.ll` verdicts on the subject,
  the oracle and the composed binary. The 12 ACCEPT fixtures give subject 0, oracle 1 and
  composed 0; the 8 DECLINE fixtures give 1 on all three. That confirms the 12 D→A.
- rhk5's 10 new fixtures on the composed binary vs the rhk5 snapshot: same exit code and
  byte-identical output, 10 of 10.
- The subject's 12 new ACCEPT fixtures, subject vs composed: byte-identical, 12 of 12.
- `spC`, `zl12`, `za01` on the z0re binary.

**NOT run.** lit, ctest, the corpus A/B and allocator sweeps (per the efficiency rule), and
**no mutants**. My one private build went to the cepm × rhk5 composition, which is what found
F-r1B-1. The 6.5 conjunct's pin rests on the implementer's M8 (KILLED 1). There is no
cepm × z0re composed build (F-r1B-3 is argued). No `+Asserts`.

⚠ **Disclosure.** I invoked the implementer's `cepm_probes/mkprobes.py` to list the battery.
That script **rewrites** `cepm_probes/src/*`. `git status` afterwards shows no modification (the
rewrite was byte-identical) and only r1A's untracked review directory. Nothing else in the
subject worktree was touched apart from this directory.

## Verdict

**CLEAR-WITH-ITEMS, conditional on MERGE ORDER: bd `rhk5` must land before or with bd
`cepm`.** If cepm has to land alone, F-r1B-1 makes three measured C programs new accepts of a
wrong unitary (warned, not silent). Read the verdict as NOT-CLEAR for a solo cepm landing.

No P1 on the subject's own stream: every new accept whose stream I read is correct, apart from
the tp family (F-r1B-1), where the twin is wrong in exactly the same way.

## Findings

### F-r1B-1 — P2 (conditional; see the verdict). The population is INTRODUCED; the defect (bd `rhk5`) is PRE-EXISTING. Twin identity was blind to it because BOTH halves are wrong.

**Programs** (`probes/src/tp{C,T}.c`, `tps*`, `tpx*`, and `tpk*` as the oracle control). C side:

```c
int q = cq_theta(m, .5); int p = q * 3;   /* tpx: p = q ^ 5 ;  tps: switch (t) */
int t = h(p, m);                          /* h READS a via g → f2 → f3; returns k + 1 */
if (t > 3) q = cq_theta(q, .2);
return cq_measure(q);
```

- **Oracle:** C declines (`condition predates a non-diagonal gate` for tp and tpx, `control
  flow` for tps). T (`g(p); int t = m + 1;`) **accepts**.
- **Subject:** C **accepts** (D→A), and it is ACC-SAME with T on all three argv values. Both
  sides print the lyyf-(B) `non-diagonal gate over a live derived record` warning.
- **What the stream does** (read by hand, `probes/results/tpC.subject.s2.ll`):
  `%h_op = cq_template_mul_i32_hl(%h, 3)` is passed to `@__cq_q_h_01` and then **never
  uncomputed or freed**. `cqrt_ry_i32(%h, 0.2)` follows, and then `cqrt_measure_i32(%h)`.
  The rail `3q`, or `q ^ 5` for tpx, is a which-path record of `q` that stays allocated and
  entangled across a non-diagonal gate on `q`. That dephases `q` (Rule 8): it is a **wrong
  unitary**. The user does NOT keep `p` live. In the fully inlined program the spine discharges
  it, so this is the bd `rhk5` defect ("a clone call inside a derived chain's discharge
  window"), not the user's circuit under the lyyf-(B) ruling.
- Stage 2b: `0 violation(s)`, `9 template rail mint(s) of which 2 left dirty`. The census sees
  the rail and the gate cannot.
- **Composed** (`1c0a4e17`, `probes/results/tpC.composed.s2.ll`): both sides emit
  `cq_template_mul_i32_hl_unc(%h_op, %h, 3); cqrt_free(%h_op)` **before** the Ry, and they
  stay ACC-SAME. T's warning disappears. C keeps only the bd `9k30` over-warn. The same holds
  for tps and tpx. **rhk5 covers the cepm variant**, where the clone call has a non-void
  classical result.
- **Pre-existing, measured:** tpk (the same leak with no branch on `t`) is accepted on the
  **oracle** with the same stream. So the defect already exists in C form, and cepm adds the
  branch, switch and xor spellings.
- **Twin-criterion blind spot (L10):** tp is one of the implementer's "43 twin-identical" pairs
  and was a wrong circuit on the subject. The TRACK (§8) lists `tp` as a 9k30 over-WARN
  customer ("traces twin-identical; tp's twin warns too"). **That classification is wrong.**
  tp's warning is a TRUE positive on both sides. Every other warned new accept (`br`, `sw`,
  `lp`, `ch`, `fp`, `yc`, `cph`, `ang`, `un`, `lk`) passes `q` itself to `h`. No derived record
  exists there, the streams free every rail at `|0⟩`, and those warnings are genuine over-warns.
- **Rule 12 gap:** no lit fixture and no e2e slice pins this composition. All 12 new ACCEPT
  fixtures produce byte-identical output on the subject and the composed binary, so neither
  landing can see the other.
- **Action:** land rhk5 before or with cepm, and add `tpC`/`tpT` as a composition pin at the
  merge: an accept whose `mul_unc` and `free` of `%h_op` precede the Ry. Correct TRACK §8's
  `tp` row.
- **Repro:**

  ```
  cd <scratch>; bash probes/gen.sh probes/src tpC tpT && bash probes/tw.sh tp
  ```

  Then read `tpC.s2.ll`, and for the composed binary run `probes/twc.sh <comp cq-opt> comp tp`.

### F-r1B-2 — P2 over-decline. INTRODUCED relative to round 1 (`cb4ed3c2`); PRE-EXISTING relative to the oracle. (The mechanism is r1A's `LaterTaintOracle`; I reached it from the program side.)

`probes/src/lpp{C,T}.c`:

```c
for (i < 3) { int t = h(q, i + m); if (q > t) cq_phi(0.2); }
```

- Oracle C: declines `quantum-quantum compare condition`.
- **Round-1 subject `cb4ed3c2` C: ACCEPTS, trace-identical to T for all 3 argv**, 2b
  `8 verified, 0 violation(s)` (`probes/results/lppC.round1_cb4ed3c2.s2.ll`).
- **Round-1b subject: declines again** with the oracle's string. T accepts.
- **Mechanism:** the settle step's `mayGain(i + m)` walks to the loop-header φ `i`. The
  "deciders" of that φ are taken as every conditional terminator between `idom(header)` and the
  header, which is the **whole loop body**. The body contains the tainted `br (q > t)`, so `i`
  "may gain taint", the site is tainted at round 1, and the compare becomes Q+Q.
- That branch does not decide which incoming of `i` arrives: its arms reconverge before the
  latch. No later round replaces a header φ with a merge `%out`, so this is a precision loss
  and not a soundness need.
- **Control:** `lpq`, the same program with the argument `m` (loop-invariant), accepts
  twin-identically (rolled kickback `q > m + 1 + i`, read by hand).
- **Record:** TRACK §12.5 says "Round 1 vs round 1b directly: 2 movers … no other probe's
  verdict … changed". That is true over its 377 probes. lpp is a third round-1 → round-1b A→D
  mover outside that corpus, and TRACK §0's "a loop body" population claim should name the
  residual.
- **Suggested direction (for r1A and the implementer):** decide a φ's incoming by control
  dependence (post-dominance), not by "any conditional terminator between the idom and the
  block".

### F-r1B-3 — P2 over-decline. INTRODUCED, DISCLOSED in TRACK §9, pending bd `z0re`; the oracle's accept it removes was a CORRECT circuit.

- The 4 A→D movers (`zl12`, `zl17`, `za02`, `za01`) plus my `sp` (a fifth instance, a
  reading-callee state-prep seed):

  ```c
  int s = h(q, m); int r = s; if (q2 > 5) r = cq_theta(s, .3);
  ```

- On the oracle, `spC` accepts through the side door:
  `%h2 = cqrt_alloc_i32(%9 /* = m + 1 */); cqrt_ry_i32_controlled(%h_cmp, %h2, 0.3)`. That is
  the correct controlled state prep on the classical seed. **The A→D is therefore a real loss,
  not a fix.**
- On the **z0re binary alone**, `spC`, `zl12C` and `za01C` accept ACC-SAME with their twins,
  because the twin now takes z0re's runtime-seed path.
- **cepm + z0re was not built. Argued:** z0re's `isRuntimeStatePrepSeed` admits an untainted
  `Instruction` and is asked at round-1 taint. Under cepm round 1b, a predicted-classical seed
  is untainted at detection and is **STICKY** afterwards: no later drain taints it, and
  `specialize()` declines loudly if the clone returns a register. So z0re's premise is not
  falsified, and after both land these five should accept on the direct path with the twin's
  stream.
- **Action:** land z0re before or with cepm, or accept a temporary over-decline of a correct
  accept. Re-measure the five pairs on the composed tree.
- **Repro:**

  ```
  probes/tw.sh sp
  probes/twc.sh scratchpad/z0re_bins/cq-opt.subj_r2 z0re sp zl12 za01
  ```

### F-r1B-4 — P3 L7. A stale justification at `(K1)`/`(K5)`, `ArmClassify.cpp:2358-2415` (`valueArmIsPureChain`). PRE-EXISTING text, falsified by this change.

- `(K1)` says "a classical op consuming a chain link would itself be tainted by forward
  propagation, so (K1) already implies 'no cone member reads a chain link'". Since cepm that is
  false for a predicted-classical Phase-6 call: it reads a tainted value and is untainted.
- `(K5)`'s "(K5) is the SOLE fence only for `cq_phi`, `cq_measure` and the invert BRACKETS" is
  now incomplete. For an IR-level `speculatable memory(none)` callee, `(K5)` (any non-intrinsic
  call) is the only thing that refuses an untainted Phase-6 call reading a quantum
  **non-chain** value (the condition register, say) in a value arm. `(K2)` catches every C
  spelling.
- The code is safe because `(K5)` is structural. This is the same proxy the change fixed in
  6.5, left in prose one function over (L3's mirror).
- TRACK §13's proposed CLAUDE.md text ("6.5 was the one predicate caught relying on the proxy")
  should mention it.

### F-r1B-5 — P3 L7. An incomplete correction at `TaintPropagation.h:1862`.

- The header still says "`propagateWorklist` taints every user of a tainted value bar a measure
  sink and an angle-only edge". That is the same sentence the change corrected at
  `MergePhiPeel.cpp:573`, a copy one file over.
- The conclusion it supports (about a `select`) is unaffected.

### F-r1B-6 — P3, fixture strength. `spec_accept_predicted_classical_bank.ll` does not pin the property that matters.

- The CHECKs are `__cq_q_h_01` → `store` → `CHECK-NOT: railbank` → `ret`.
- The a03 property that separates right from wrong is that `cq_measure(b[i])` over a loaded
  classical integer lowers to the **value**: no `cqrt_measure_i32` on a load. The subject has
  exactly one `cqrt_measure_i32`, on `%h`.
- A regression that measured each loaded integer as a handle (the Rule-3 wire crossing) would
  stay green. Stage 2b cannot adjudicate this module (bd `jzwo`), so the fixture is the only pin.
- Suggest a separate whole-file prefix that counts exactly one `cqrt_measure_i32`, or a
  `CHECK-NOT` in the second loop.

(F-r1B-1's TRACK §8 misclassification is counted within F-r1B-1, not separately.)

## What I tested and did not break

1. **A handle reaching opaque classical code (attack 1).**
   - Every accepted stream passes the handle only to clones (`__cq_q_h_01` → `__cq_q_g_1` →
     `__cq_q_f2_1` → `__cq_q_f3_1`, with the `_unc` twins).
   - I read the `br` trace gate by gate. The `f3`/`f2` results are copied out and uncomputed
     (`mul_unc`, `add_unc`, `f2_1_unc` with a recompute), every free is on a rail XOR-returned
     to 0, `q` is untouched, and the classical `m + 1` drives a classical `br`.
   - Three callee spellings that WOULD hand `a` to classical code all decline loudly at
     `scanBody` on both binaries: an undefined external (`xe`), a `printf` (`xp`) and a global
     store (`xs`). No accept passes a rail handle to non-clone code.
   - Clone construction does not use `propagateWorklist` (it uses `seedClone` /
     `reseedCloneTaintFromParams`), so the new predicate never runs inside a clone. That is why
     `in2` stays at l3oi's fence.
2. **At least 6 new accepts of distinct shapes, streams read and correct** (not only
   twin-equal):
   - `sw` (switch on classical `t`), `lp` (loop sum), `a04` (break on a classical exit), `z3`
     (a round-2 site: `__cq_q_h_01(%out, m)` feeding `__cq_q_g2_10(t, %h)`, with `t` in the
     literal slot, so `u = q·(m+1)+1`), `yb` (a clone result in another clone's literal slot),
     `rt9` (`f` returns classical `t + measure(q)`).
   - `a03`: plain `alloca` stores of classical `i+1`, no bank, classical measures. Traces and
     exit codes match T by hand for argv `5 7` and `2 9`.
   - My own: `vcone` and `dselq` (a 4.4 select of classical `t` under `q > 5`), `pcm` and `lpq`
     (Q+C kickback, flat and rolled), `measarg` (a clone read after `cq_measure`, the bd `yiid`
     class; the twin is identical), and `ms`.
3. **The 23 non-identical battery pairs, classified.**
   - 11 `…i` ACC-DIFF. Read on `bri`: h's clone emits `__cq_q_g_1_unc` and frees g's result,
     while T's top-level `g(q)` leaves it allocated across the Ry. **C is the correct side.**
   - r2g and nq: ACC-DIFF on the oracle too.
   - a03 and a03i: 2b-refused (bd jzwo), traces identical by hand.
   - in2, in2i, np, nr2: VERDICT-DIFF, pre-existing, the same on the oracle.
   - r2b and r2d: the oracle's verdict, per the orchestrator ruling.
   - selvg and nm: DECL-DIFF, pre-existing.
   - **None is "twin declines, subject accepts".**
4. **The 6.5 `readsTaintedValue` conjunct (attack 3).**
   - `va` (the call reads the condition register) and `va2` (it reads a different register
     `q2`): both decline `value-arm swap-route` on the subject, the oracle and the composed
     binary, the same as the twin.
   - IR probe `va_speculatable.ll` (`h` marked `speculatable memory(none) nounwind willreturn`,
     call site `memory(none) willreturn`) declines identically on all three binaries.
   - The 6.5 population is unchanged. The conjunct is an all-operand SET test (L4 n/a) and is
     the one exported spelling (Rule 14).
5. **The d88e `isLoweredRailHandle` refusal (attack 4)** still fences a QUANTUM-returning clone
   parked in a bank: probe `bq` declines `a cell parks a value that is not a rail handle` on both
   binaries. A classical-verdict result never enters a bank at all.
6. **Movers.** 12 D→A lit confirmed. The 4 STRING movers (`l04`, `l04i`, `ld`, `gs`) are
   decline → twin-string decline. The 4 A→D are F-r1B-3. The e2e round-2 slice's source is `z3`,
   read and correct.
7. **Composition.**
   - cepm × rhk5 was measured (F-r1B-1). The composed 66-pair battery gives 43 twin-identical,
     the same as the subject's pair set, with tp now correct.
   - rhk5's 10 fixtures are unchanged under the composition. `cloneCallPreservesArg` keys on
     `SpecHandleArgMask` and the clone body, which cepm does not change, so it still sees and
     proves a classical-result clone call (measured: tpC composed).
   - cepm × z0re: argued (F-r1B-3).
   - nlfd/ev3m: no exhibit, and argued why none exists. ev3m's musttail forwarding makes the
     forwarded call the return value, so `predictReturnTainted` says QUANTUM and cepm does not
     reach it. nlfd lives in clone parameter liveness, which cepm does not touch.

## Standing-lesson answers (surface B)

- **L1.** The 6.5 conjunct is asked at each control round on that round's taint. A site recorded
  in round 2 reads a round-2-tainted argument, so it is NotApplicable, as on the oracle. For the
  z0re composition, "untainted at detection" is stable because of the sticky rule plus the
  `specialize()` check (F-r1B-3).
- **L2/L3.** The 6.5 NotApplicable set was widened consistently: the population equals the
  oracle's, measured on `va`, `va2` and the IR probe. Other predicates that name "classical
  result ⇒ classical inputs":
  - `(K1)`: the asymmetry is SOUND because `(K5)` is structural; the prose is F-r1B-4.
  - PredMux E4 asks the arguments directly (`TaintedArg`), so it is unaffected.
  - `declineTaintEscapes` asks `readsTaintedValue`.
  - M-A clause 1 over-warns (bd 9k30). The one warned case that is NOT an over-warn is
    F-r1B-1.
- **L4 / L5.** No new wire walker on this surface. `readsTaintedValue` is a set membership test
  over all operands.
- **L7.** F-r1B-4, F-r1B-5, and the TRACK §8 `tp` row (F-r1B-1).
- **Rule 14.** `readsTaintedValue` was exported rather than re-spelled. PredMux's `TaintedArg`
  loop and `taintArgMask` are narrower, arguments-only spellings of a related question; they are
  pre-existing and conservative.
- **Rule 12.** The 6.5 conjunct is pinned by `spec_reject_predicted_classical_value_arm.ll`. Its
  subject exists (it declines on the subject, measured) and its negative is pure (one CHECK).
  The composition is unpinned (F-r1B-1), and the bank fixture is weak (F-r1B-6).

## Beads

- Notes appended (`--append-notes`) to bd `test_C_libtooling-cepm` and bd
  `test_C_libtooling-rhk5`: the F-r1B-1 merge-order condition, the tp probe, and the composed
  measurement.
- No new bead. F-r1B-2 belongs with r1A's `LaterTaintOracle` items or a cepm note (left to the
  orchestrator), and F-r1B-3 is the disclosed z0re dependency.
