# Rule-13 review r2B — bd `test_C_libtooling-vsfp` round 2 (`0a485382`)

Reviewer B of round 2. Scope: the EMITTED CIRCUITS, the phantom-read backstop
`declinePhantomCloneArgReads`, `taint.SpecDeadArgMask`, M-C arm (d0), and the composition with
bd 9bhg `f2148d0a`. (Reviewer A has the liveness predicate and everything it deletes.)

## Verdict: **NOT-CLEAR**

One P1 (a wrong unitary reachable from C, re-admitted by a round-2 relaxation), one P2 (a falsified
headline claim, with its root cause), three P3.

## Binaries (sha-256 prefixes, measured)

| tag | what | `cq-opt` |
|---|---|---|
| main | ORACLE `aee8f4f8` (frozen) | `69250feaf68bbe49` |
| v5 | round 1 `5e56060b` | `73fd07592c4960dd` |
| subj | SUBJECT `0a485382` (`build/ir-pass/cq-opt`) | `d17c95e8353711b1` |
| comp | my private merge of `0a485382` + `f2148d0a` (worktree under scratchpad, removed after) | `5e5a47214a22180c` |
| 9bhg | `f2148d0a` alone | `bfb441d3b9568bd1` |
| B3 | the implementer's mutant "no keeper check" | (from `vsfp/bin/`) |

**Build null control:** my composed build came out BIT-IDENTICAL to the implementer's COMPOSED binary
(`5e5a47214a22180c`, TRACK §R2.8), so the composition claims were checked on the same binary. Source
conflicts on the merge: none. Fixture conflicts (`CODE_MAP.md`, two
`taint_reject_scrubbed_handle_clone_arg*.ll`) resolved to 9bhg's version; they do not enter the binary.

Harness: `probes/tools/h.py` (a copy of the implementer's `h.py` pointed at my scratch; stage 1
`clang -O1`, multi-TU via `llvm-link`, stage 2, stage 2b `free_pairing_check.py` STRICT + its CENSUS
line, link with `libcq_templates.a` BEFORE `libcq_runtime.a`, run with args `5 7`). Every twin below
is a hand-inlined or fenv-intended program; every probe source is under `probes/src/`.

---

## F-WB-1 (P1, filed bd `test_C_libtooling-tzfa`) — the backstop's "kept alive elsewhere" exemption re-admits a Rule-8 wrong unitary

**Class:** over-accept, wrong unitary, reachable from C. **PRE-EXISTING against the oracle** (main emits
the byte-identical stream), **INTRODUCED against round 1** (v5 declined every exhibit). The round-2
change that re-admits it is the keeper conjunct `keptAliveElsewhere` (mutant B3 declines all of them
again).

**Repro** (`probes/src/k19.c` + `k19.lib.c`, two TUs):

```c
// k19.lib.c
static volatile int K = 7;
int h(int a, int k) { if (a > 3) (void)K; return k + 1; }
// k19.c
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5);
  int p = q * 3; int r = h(p, m); int u = p ^ q;
  if (u == 10) cq_phi(3.14159);           // phase oracle on q
  q = cq_theta(q, .7); return r + cq_measure(q); }
```

Twin `k19F.c`: the same with `int r = m + 1;` (h inlined; `-O1` then deletes its dead diamond).

| binary | verdict | stage 2b | CENSUS |
|---|---|---|---|
| main | ACC, 1 warning | `0 violation(s), 0 unproven` | 4 template rail mints, **2 left dirty** |
| v5 | DECL `quantum argument to a parameter the lifted callee never reads` | — | — |
| **subj** | **ACC, 1 warning** | `0 violation(s), 0 unproven` | 4 template rail mints, **2 left dirty** |
| comp | ACC, same stream as subj | clean | 2 left dirty |
| twin on subj | ACC, 0 warnings | clean | 3 template rail mints, **0 left dirty** |

The subject's trace next to the twin's (`probes/results/headline_traces.txt`):

```
subject                                       twin (k19F)
cqrt_alloc_i32(5) -> h0                       cqrt_alloc_i32(5) -> h0
cqrt_ry_i32(h0, 0x1p-1)                       cqrt_ry_i32(h0, 0x1p-1)
cq_template_mul_i32_hl(h0, 3) -> h1           cq_template_mul_i32_hl(h0, 3) -> h1
cq_template_xor_i32(h0, h1) -> h2             cq_template_xor_i32(h0, h1) -> h2
cq_template_icmp_eq_i32_hl(h2, 10) -> h3      cq_template_icmp_eq_i32_hl(h2, 10) -> h3
cqrt_rz_i1(h3, pi)                            cqrt_rz_i1(h3, pi)
cq_template_icmp_eq_i32_hl_unc(h3, h2, 10)    cq_template_icmp_eq_i32_hl_unc(h3, h2, 10)
cq_template_xor_i32_unc(h2, h0, h1)           cq_template_xor_i32_unc(h2, h0, h1)
cqrt_free(h2)                                 cqrt_free(h2)
                                              cq_template_mul_i32_hl_unc(h1, h0, 3)   <-- missing
                                              cqrt_free(h1)                           <-- missing
cqrt_free(h3)                                 cqrt_free(h3)
cqrt_ry_i32(h0, 0x1.666p-1)                   cqrt_ry_i32(h0, 0x1.666p-1)
cqrt_measure_i32(h0)                          cqrt_measure_i32(h0)
```

**Why the unitary is wrong (analytic, Rule 2):** after the oracle, the subject's state is
`Σ_x α_x φ(x) |x⟩_h0 |3x⟩_h1`. `x ↦ 3x mod 2^32` is a bijection, so `h1` is a COMPLETE which-path record
of `q`, and the reduced state of `h0` is `diag(|α_x|²)`. Every oracle phase `φ(x)` and every
off-diagonal term is gone before the `Ry(0.7)`, so the measured distribution of `q` is the one of the
program with the oracle DELETED and `q` fully dephased. This is the §0 failure class ("the oracle is
the identity"). The twin uncomputes `h1` first and keeps `Σ α_x φ(x)|x⟩` pure, so its distribution
depends on `φ`. The only signal is the generic lyyf-(B) warning (`non-diagonal gate over a live derived
record`), which the twin does NOT emit. Stage 2b STRICT is clean on both.

**Mechanism:** `h`'s only read of `a` is branch-only, so the drop (slots A and B) keeps the argument.
The clone's flatten then removes the read and `buildClone` records slot 0 dead (see F-WB-2 for why the
drop did not predict it). At the backstop, `p` is a quantum template rail, not a `cq_theta` result, but
`keptAliveElsewhere(p)` is TRUE because the live `xor` reads it, and the backstop concludes "the phantom
adds nothing". **That is false.** The phantom clone call is itself an extra CONSUMER of `h1` for the
uncompute spine. The spine discharges `h1` after the `xor` only when the `xor` is its sole consumer; with
the clone call in the use-list it leaves `h1` allocated and dirty. The phantom does not keep the rail
ALIVE. It keeps it from being DISCHARGED.

**Why the round-2 evidence missed it:** the only pin of the keeper rule,
`spec_accept_phantom_arg_read_kept_alive.ll`, uses a MEASURED keeper on a 4.4 `%out` rail. A rail like
that is discharged by neither the subject nor the twin, so the exemption is correct THERE. The argument
does not reach a keeper that is a non-terminal, out-of-place consumer whose rail the twin discharges.
It is L3's mirror: the exemption answers "is the value live?" when the spine asks "does the value have
exactly this consumer set?".

**Members (all on subj = comp, stream hash equal to main, v5 DECL, B3 DECL):** `k8` (`u = p ^ q`,
measured), `k14` (the keeper is before the phantom call), `k18` (`u = p * q`), `k19` (above), `k24` (the
phantom operand is the rail `u = q*3` itself, with a phase oracle on `u ^ q`). Non-members: `k2` (the
keeper is a clone READ slot), `k5`/`k10` (the keeper is a measure or a theta: the rail is never
discharged in either program), `k6`/`k7`/`k9` (M-C puts the keeper op in place), and `k20`. All of
those are TRACE-IDENT with their twins. Control `k19v`: the same caller with a callee whose slot the drop
CAN predict (`volatile int z = a > 3;`) is TRACE-IDENT on subj, so the leak needs a clone-only dead slot
plus a keeper.

**Direction of a fix (not prescriptive):** when the keeper conjunct holds, either decline (round 1's
behaviour, which costs `spec_accept_phantom_arg_read_kept_alive.ll`'s accept) or neutralise the phantom
operand before `uncompute`, so that the spine sees the twin's consumer set. Fixing F-WB-2's root closes
today's C route but not the argument.

## F-WB-2 (P2, filed bd `test_C_libtooling-stl3`) — "C-reachable customer count ZERO / a pure backstop" is false; the root is an L2 omission

**Falsified claims:** TRACK §R2.5 ("Its C-reachable customer count is zero as far as measured … the
fenv stages now fold what they empty"), the commit message's "pure backstop" framing, and the same
sentence at `ArithLowering.cpp` (d0) (`the only customer is a slot the CLONE's own pipeline made dead …
with a cq_theta result as the operand`) and `RotationLowering.cpp:1351-1361`.

**Root:** `foldVolatileConstGlobalLoads` (`QramLowering.cpp:2597`) is the one member of the volatile-fold
family inside the slot-A..slot-B window that round 2 did NOT give the empty-arm fold. Its three siblings
(`foldVolatileConstAllocaLoads`, `eraseDeadVolatileScalarStores`, `promoteVolatileScalarLocals`) now call
`deleteDeadCones(…, Emptied)`. When it RAUWs the only instruction of an arm (a volatile load of a
never-stored internal global) it leaves an empty diamond, or a two-entry φ with EQUAL incomings. The
original callee's `a` stays branch-live, so slot B does not drop it. The clone's flatten removes the
branch, the record calls the slot dead, and every C program of this shape reaches the backstop. Measured
directly: `k1`'s lowered module keeps `@h`'s empty diamond while the clone `__cq_q_h_01` has lost the
`icmp`.

**Exhibits (subj DECL at the backstop, fenv-intended twin ACC, main ACC with a leaked rail):** `k1`
(`if (a > 3) (void)K;`; main leaves 4.4 which-path rail `h2` across `Ry(b)`), `g9A/B`
(`__builtin_expect(a > 3, 1)`), `g13A/B` (`(a > 3) ? K : 0` with `K = 0`: a φ of equal incomings, no
empty arm), `k12`, `k13`, and `k3`/`k4`. `k3`/`k4` also CONSTRUCT the over-decline §R2.5 names but did
not build: the operand's only other reader is a control-emitted `cq_template_icmp`, which
`keptAliveElsewhere` does not count. Every one is a safe-direction over-decline against its twin. The
same root is what makes F-WB-1 reachable from C.

## F-WB-3 (P3) — two source comments claim a population the keeper rule enlarged; a third "slot unread" spelling

- `ArithLowering.cpp` (d0): *"any other quantum operand in such a slot has already been declined"*.
  False: the keeper exemption lets a non-`cq_theta` operand through. In `k7`
  (`p = q*3; h(p, m); p += 5; measure(p)`) a derived record reaches (d0), which settles it, and the
  stream is TRACE-IDENT with the twin. The outcome is right and the stated population is wrong (L7).
- `RotationLowering.cpp:1351-1361`: *"this branch is reached only by such a register (never a derived
  record)"*. False for the same reason: `k5`'s derived record `p = q*3` (kept by a measure) reaches
  `cloneArgReachesResult`. That function still asks `Argument::use_empty()` of the clone parameter, a
  THIRD spelling of "slot unread" beside `isRecordedDeadSlot` (Rule 14). The stream is identical to the
  twin's. The subject emits a lyyf-(B) warning the twin does not (`k5`, and also `d1`/`d4`/`e1`–`e8`,
  where the operand is a `cq_theta` result). Warning parity only.

## F-WB-4 (P3, owner) — the fenv sentence: confirmed, and a correction

Confirmed on main vs subj (`probes/src/f*.c`, plus the implementer's `qjoc`/`qjoc_tpl`):

- `qjoc` (a dead 4.4 select): main TRACE-DIFF and leaves the which-path rail allocated, with NO warning.
  subj TRACE-IDENT.
- `qjoc_tpl` (a dead template product, later `Ry` on its source): main leaves `mul_i32_hl` dirty with a
  lyyf warning. subj TRACE-IDENT.
- **Beyond §R2.6:** the first half ("with no enclosing tainted control flow the dead product IS lowered,
  uncomputed and freed") was false on main even WITHOUT a later non-diagonal gate. In `f1`
  (`int p = q*3; volatile int z = p; … return cq_measure(q)`) main emits `cq_template_mul_i32_hl(h0,3)`
  and no `_unc`: a dirty rail, 2b CENSUS `1 left dirty`. Only the ruling fixture's own `fmul r*r`
  happened to be uncomputed. `f3` (fp, later `Ry`) leaves the `fmul` product dirty with a warning.
- The second half ("inside a PredMux region it is deleted outright") was also not what main did: `f5`
  (`if (b) { volatile int z = q*3; }` with `b` tainted) DECLINES on main (`operand predates a
  non-diagonal gate`) and is TRACE-IDENT on subj.

**What the sentence should say (report only; not edited):** *"The erasure deletes the stored value's
DEAD CONE by liveness (`deleteDeadCones`), so the product is deleted whether or not it sits in a PredMux
region; there is no asymmetry. What survives is only what is live for another reason, or a liveness
root (a front-end `cq_*` site, a reserved-namespace or specializer-built call, or a call whose callee
body is not provably side-effect-free and terminating). Before bd vsfp round 2 neither half held: the
no-control-flow product was lowered and in general NOT uncomputed (a Rule-8 wrong unitary once its
source takes a non-diagonal gate, silently for a dead 4.4 select), and the PredMux case could decline."*
The ruling itself is not in question.

## F-WB-5 (P3, note) — bd 9bhg ALONE accepts a vsfp-class leak the composition declines

`k11` (`r = h(p, m); s = h(p, r);`, K-trick callee): 9bhg alone ACC, 1 warning, 3 template rails dirty.
main, subj and comp DECLINE (subj at the taint-escape guard, comp at the backstop: a string move only).
It is recorded for bd 9bhg's owner. The composition does not inherit it.

---

## What was checked and came back clean

- **Composition (item 5).** The implementer's 84-pair battery on my composed binary
  (`probes/results/r2bat_comp.txt`): **79 TRACE-IDENT + 5 ORACLE-SAME, 0 other**, line-for-line the same
  verdicts as `r2bat_comp3.txt`. That covers every F-9C-1 member in it, v01–v30 (`v30`/`v30i` TRACE-IDENT
  with `v30F`, so the hgwx "(d0)-blind" spelling does lower in place), and the j/e hgwx members. The r1B
  probes the battery omits (`v08`, `v08b`, `v26vsel`) are TRACE-IDENT on subj and comp. All 67 of my own
  probes on main/subj/comp/9bhg (`probes/results/tri_out.txt`): **comp's trace hash equals subj's on
  every accept, and there is NO composed-only accept** (no probe accepts on comp while declining on both
  subj and 9bhg).
- **Movers (item 1).** 17 of 17 sourced movers from a seeded random sample of the implementer's twin
  table (12 D→A, 6 STREAM, 3 A→D; 4 had no source) re-paired on subj: every one TRACE-IDENT or DECL-SAME,
  and every twin is fair (the call replaced by its inlined value, `probes/results/mover_sample_seed7.txt`).
  Two hand-classified D→A rows re-checked against MY hand twins: `n4` and `s_f64`, both TRACE-IDENT
  (the implementer's auto twin for `n4` was broken). The ORACLE-SAME `v16b` against my hand twin is
  TRACE-DIFF but equivalent: both keep an injective basis copy of `q` across the `Ry` on `q+6`, so only
  the order differs and the statistics do not.
- **New spellings of the dead-use class (item 1, `probes/results/adversarial_g1-g13.txt`), each ×2
  callers (a 4.4 which-path rail, a template rail):** a cross-TU pure helper returning its argument,
  `volatile` select on a classical condition, a `volatile` struct field, a loop-carried dead accumulator
  (`-O1` closed form), `switch`, fp conversions (`double`/`float`), and a `memcpy` into a local then a
  `volatile` load are all TRACE-IDENT with the fenv-intended twin. The vector lane (`volatile v4`) and
  `__builtin_expect`+`__builtin_assume` decline identically on main and subj. The
  `__builtin_expect`/`switch`/φ-of-a-`volatile`-global spellings are F-WB-2 members. No silent dephasing
  among the drop-predicted spellings.
- **(d0) identity (item 4).** `d1`, `d4` (and `e6`, `e8`) TRACE-IDENT: the clone is a no-op on the dead
  slot, and the caller's `q += 3` / `q ^= 5` lowers IN PLACE like the twin. `d2`, `e1`–`e4` and `e7`
  have a DEAD computation on the slot inside the clone (`mul`/`add`, `xor`, `trunc`, `sext`+`mul`).
  Each is lowered as a forward template followed by its `_unc` and `cqrt_free`, all before the caller's
  in-place `cqrt_addc_i32`. That is an identity on the operand, as (d0)'s argument says. A dead `select`
  in the clone declines (`e5`, `d3`: tainted control flow under lift), the same on main.
- **`SpecDeadArgMask` (item 3).** By reading: every clone-body mutation after the record
  (`lowerCloneSelect`, `lowerQramReads`, `lowerOps`, the Bennett wrap, `ensureTwin`) either lowers an
  existing read or lowers a DEAD instruction into a forward/adjoint pair the wrap captures. I found no
  stage that adds a READ of a slot recorded dead. Under 9bhg's ordered scrub a changed mask builds a
  DIFFERENT clone (the cache key includes the mask), so no record goes stale. The clone is single-block
  at record time (`lowerCloneControl`'s size backstop), so the predicate's missing control dependence
  cannot bite there. **The record is sound for what it states. The unsound step is a CONSUMER of it
  (F-WB-1).**
- **Backstop totality (item 2).** No path found where a clone slot keeps a caller-side rail alive with
  NO keeper and NO decline. Nested clones are covered by the outer Bennett wrap. The `cq_theta`-result
  exemption does not block discharge of the theta's children (`k22`, `k23` TRACE-IDENT). Clone calls in
  a loop (`k15`, `k21`) decline earlier at `loop-carried tainted value crosses iterations`, identically
  on every binary.

## What I did NOT attack

- The liveness predicate and `deleteDeadCones` themselves (reviewer A), including the body-purity rule,
  the φ folds, the pre-pass order and the passthrough.
- Hand-written-IR-only routes to a clone-only dead slot. All my exhibits are C through the
  `volatile`-global fold.
- xdu2 rail banks (`rewriteRailBankCellTypes` runs AFTER the backstop, and a bank-cell phantom operand
  is untested); fp-ABI clones with a dead slot; multi-exit clones; a top-level `_unc`-twin emission after
  a (d0) in-place op.
- A clone call inside a loop that reaches the backstop (both loop probes stopped at an earlier wall).
- Any statevector computation. F-WB-1's argument is analytic (bijective `3x` copy ⇒ fully dephased).
- The corpus A/B, the allocator sweeps and the mutation matrix (not re-run, per the brief). The 651
  movers were sampled (19 plus the battery), not exhausted.
- No suite was run, and nothing was built in the subject or the 9bhg worktree.

## Files

`probes/src/` (C sources and twins: `k*` backstop/keeper, `d*`/`e*` (d0), `f*` fenv, `g*` new
spellings, `m_*` hand twins for movers, `r1b_*` omitted r1B probes); `probes/tools/` (`h.py`,
`tri.py` four-binary runner, `samp.py` mover sampler, `r2bat.sh`); `probes/results/` (all outputs
quoted above). No executables.
