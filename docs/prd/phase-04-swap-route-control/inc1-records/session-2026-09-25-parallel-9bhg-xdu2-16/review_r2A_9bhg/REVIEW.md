# Rule-13 round r2A on bd `test_C_libtooling-9bhg`: the accept surface and the slot order

Reviewer: independent agent, 2026-09-26. Subject: branch `worktree-agent-a50057998e957b90e`, head
`f2148d0a` (9bhg merged with `main` `aee8f4f8` = d88e + xdu2.16 + 8e5r). A concurrent round r2B
covers the specializer and container composition, so this round did not attack those.

Binaries (sha-256 prefixes, frozen copies, never rebuilt here):

| tag | binary | prefix |
|---|---|---|
| sub | subject `cq-opt` (`frozen/cq-opt.final`, identical to the worktree's `build/ir-pass/cq-opt`) | `bfb441d3b9568bd1` |
| dbg | subject `cq-opt-debugalloc` | `7ef9853f0eb3a528` |
| main | `main` `aee8f4f8` | `69250feaf68bbe49` |
| alone | 9bhg alone, `30529716` | `8b837d1f79574156` |
| ora | `983f9361` (3jru + l3oi, pre-9bhg) | `438c77bf45c02e3e` |
| pre | `aad63450` (pre-3jru) | `63e2f0bbd3708c92` |
| ins | private instrumented build of `f2148d0a` (`probes/tools/r2a_instrumentation.patch`, trace-only, env-gated) | — |

The subject worktree was not edited and not rebuilt. The instrumented build lived in a private
`git worktree` in the scratchpad and was removed after the round.

## Verdict: **NOT-CLEAR**

The verdict is NOT-CLEAR for the same reason both r1 rounds were: a PRE-EXISTING P1 whose
population 9bhg grows. 9bhg's own mechanism survived every attack in this round. That covers the
provisional-return predicate, the early and late asks, the ordered scrub, and the slot order. The
problem is what 9bhg now accepts. It re-admits a silent wrong-unitary class that the 3jru and l3oi
fences had been declining as a side effect (F-9C-1).

| id | sev | attribution | one line |
|---|---|---|---|
| **F-9C-1** | **P1** | **PRE-EXISTING defect, population GROWN by 9bhg** (both the non-crossing and the ordered scrub add members) | A classical-verdict clone's phantom read of a pass-invented which-path rail (a 4.4 bool-select `%out` or a 6.5 `%out`) leaves that rail dirty across a later non-diagonal gate on the register it copies. The result is a **silently** dephased circuit: no warning, and stage 2b STRICT is clean. The track's class argument, "the only twin difference is a dead borrowed register, Rule 6's accepted leak", is FALSE for the class. New bd filed. |
| F-9C-2 | P3 | INTRODUCED (a record claim) | The slot-order rationale "each owner is placed where the hand-inlined twin agrees" is false for l3oi (3) before the late 3jru ask (4). In `o1` the subject declines with the l3oi string and its twin declines with the 3jru string. Only the decline string differs; the verdict is the same. |
| F-9C-3 | P3 | record imprecision + a PRE-EXISTING over-decline | TRACK §6 says "f's own control on its spec result still declines at l3oi's fence". That is not the owner when `f` RETURNS the emitter's rail (`e1C` `e2C` `e3C` `e4C` `e9C`): the round-2 `%out` makes the return non-provisional, and the EARLY 3jru re-ask refuses it. The fp provisional returns (`fp_*`) decline at `tainted value returned at non-i32 width` on every binary. Both belong to bd `cepm`'s class. |

## F-9C-1 (P1): silent Rule-8 dephasing through a classical-verdict clone's phantom read

### Mechanism

Take `h(int a, int k) { return k + 1; }`, compiled in a separate TU. For a call `h(p, m)` with `p`
tainted, the clone is `__cq_q_h_01(p_handle, m)`. It ignores `p` and returns classical data. The call
still READS `p` as far as the lowering is concerned, which is bd `hgwx`'s root cause. So a `p` that
the hand-inlined twin never computes (`-O1` deletes it once `h` is `m + 1`) is materialized and then
left allocated.

- **Theta-source `p`** (`p = q = cq_theta(...)`). This is every pair the track measured. The leftover
  register is a product state and is harmless: probe `b3`, where `q` is rotated again after the
  borrow, stays coherent.
- **Derived `p`** (a which-path copy of a register `x`). The leftover rail is ENTANGLED with `x`. A
  later `Ry` on `x` then acts on a register whose branches are tagged, so it dephases (Rule 8, and
  the Q-R1-1 lesson in CLAUDE.md §5).

The dirty rail comes in two kinds, and they differ in what the user sees:
- template rails (`add`, `xor`, `shl`, `zext` of a compare, `and`): the lyyf-(B) warning
  `non-diagonal gate over a live derived record` fires. These are bd `hgwx`'s warned class.
- pass-invented value rails (the 4.4 data-select `%out` on a bare `_Bool`, and the 6.5 classical-call
  arm `%out`): **nothing fires**. The module compiles at exit 0 with 0 bytes of warnings, stage 2b
  STRICT reports `0 violation(s), 0 unproven`, and the trace is self-consistent.

Repro `b10f` (2-TU; lib `int h(int a, int k) { return k + 1; }`):

```c
__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5);
  int p = b + 1; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
int main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }
```

The lowered `f` on the subject:

```llvm
  %h = call i32 @cqrt_alloc_i1(i1 %4)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)                    ; p's rail: 2 or 1 according to b
  ... two cqrt_copy_i32_controlled(%bf, ..., %out), bf restored and freed ...
  %5 = tail call i32 @__cq_q_h_01(i32 noundef %out, i32 noundef %0)   ; phantom read
  call void @cqrt_ry_i1(i32 %h, double 0x3FE6666666666666)   ; Ry(.7) on b; %out still records b
  %m = call i1 @cqrt_measure_i1(i32 %h)
```

The twin (`int t = m + 1;`, so `p` is dead) emits `cqrt_ry_i1(h0, .5)`, then `cqrt_ry_i1(h0, .7)`, then
the measure. That is a coherent `Ry(1.2)`. Analytically, for `m` odd (b starts in |1⟩), with
Ry(θ) = exp(−iθY/2):
- the twin gives P(b = 1) = cos²(0.6) = **0.6812**;
- the subject gives sin²(.25)·sin²(.35) + cos²(.25)·cos²(.35) = **0.8356**.

That is a different measurement distribution, with no diagnostic.

### Attribution (`opt` exit / warning count; identical lowered-IR sha where accepted)

| probe | shape | pre | ora | alone | main | **sub** |
|---|---|---|---|---|---|---|
| `b10` | bool-select rail borrowed in `main`, then Ry, then measure | acc, 0 warn | acc, 0 | acc, 0 | acc, 0 | acc, 0 |
| `b15` | same, `p = b ? 9 : 4` | acc, 0 | acc, 0 | acc, 0 | acc, 0 | acc, 0 |
| `s3d` | 6.5 `%out` (`if (q > 3) r = K(m)`) borrowed by `h(r, m)`, then Ry(q) | — | acc, 0 | — | acc, 0 | acc, 0 |
| `b10f` | `b10` inside a provisional `f` | acc | **DECL 3jru** | acc | **DECL 3jru** | **acc, 0 warn** |
| `b15f` | `b15` inside a provisional `f` | acc | DECL 3jru | acc | DECL 3jru | **acc, 0 warn** |
| `s3c` | `s3d` inside a provisional `F` | — | DECL 3jru | — | DECL 3jru | **acc, 0 warn** |
| `b26` | CALLER side: `main` borrows its own bool-select rail in `h(p, f(m))` | — | DECL 3jru | acc | DECL 3jru | **acc, 0 warn** |
| `b20` | SINGLE function, ordered scrub: `t = h(q,m); u = h(p, t)` with `p` a bool-select rail | — | — | acc | **DECL l3oi** | **acc, 0 warn** |

- The defect is pre-existing: `b10`, `b15` and `s3d` produce byte-identical wrong streams back to
  `aad63450`.
- Its population grows. Four accepted members (`b10f`, `b15f`, `s3c`, `b26`) were declined by 3jru's
  refusal of the provisional return. One more (`b20`) was declined by l3oi's fence, and the ordered
  scrub admits it. On `main` all five decline; on the subject they accept silently.
- Deterministic: `b10f`, `b15f`, `b2` and `b6` gave 5 of 5 identical lowered IR under the system,
  `lifo` and `nofree` allocators.

Newly accepted **warned** siblings, which are bd `hgwx`'s class, grown the same way (declined on
`main` by 3jru, accepted with the warning on the subject): `b2`, `b5`, `b6`, `b7f`, `b8f`, `b12f`,
`b17f`, `b18f`. Each one is a coherent twin against a dephased subject.

### Why nothing caught it

- The track's §10/§11 correctness argument for the D→A population was "DEAD-REG-ONLY, checked
  mechanically (15 of 15)" plus "Rule 6's accepted leak". That argument is true of the measured
  pairs, where every borrowed register is a `cq_theta` source.
- It is not a class argument. Whether a leftover register is harmless depends on whether it is
  ENTANGLED with something a later non-diagonal gate touches. The measured population had no member
  of the quadrant "derived rail borrowed ∧ source later rotated" (§4k's empty-quadrant lesson).
- `free_pairing_check.py` cannot see a dirty `alloc` rail that is never freed. It miscounts the clone
  call as a template rail (hgwx). The warning is blind to value-merge `%out` rails.
- On the direct path the hazard is unreachable. `-O1` deletes a dead `p`, and a live `p` is the
  user's circuit (probe `u1`, correctly dephased because `p` is measured). Only a classical-verdict
  clone's phantom read keeps a DEAD `p` alive.

### Routes (for the owner; none implemented)

1. Settle bd `hgwx`'s owner question the way its r1B note suggests: a call to a `SpecHandleArgMask`
   clone whose `ReturnTainted` is false does not READ its masked slots. Or simply do not pass them.
   Either way the argument becomes dead and uncomputable, as in the twin. This removes the cause.
2. As a fence: decline when a classical-verdict clone's masked argument is a non-source rail AND a
   later non-diagonal gate touches a register that rail copies. This is warned today for template
   rails, and would become a decline for the value-merge rails.
3. At minimum, the lyyf-(B) warning must cover `%out` value rails. The owner ruled the dephasing
   class a WARNING, not a silence.

Filed as bd `test_C_libtooling-vsfp` (P1; related to `hgwx`, discovered from `9bhg`).

## F-9C-2 (P3): the (3)-before-(4) slot rationale does not match the twin

TRACK §10 says: "the first `DS_Error` exits, so the order decides which owner speaks, and each owner
is placed where the hand-inlined twin agrees."

Probe `o1`: `f` branches on the spec-CLASSICAL `t = h(q,m)` (`if (t > 3) cq_phi(.3)`) and returns
the spec-QUANTUM `u = h2(q, m)`.
- The subject declines with `classical call result used as a quantum register`, from l3oi at slot (3).
- The twin `o1T` (`t = m + 1`) declines with `quantum value returned across a function boundary`
  on every binary. The twin has no l3oi offender, because its `t` is classical from the start.
- So for this pair, only (4) before (3) would match the twin.
- Same verdict, different string. §10 carries the "(3) before (4)" row on the ground of "more specific
  owner", not twin parity, so the general sentence needs that qualifier.
- `o4` shows the same shape (subject l3oi, twin ACCEPT with a warning, which is cepm's over-decline).

## F-9C-3 (P3): owner imprecision in §6, and a sibling over-decline (both bd cepm)

When `f`'s return value is ITSELF produced by a round-1 control emitter reading the conservatively
tainted `t`, the owner is not l3oi. The emitter RAUWs the return to an `%out` rail, the round-2 reseed
taints it, and the early slot's predicate re-ask sees a return that is no longer in the scrub cone. So
the EARLY 3jru slot refuses with the 3jru string, although the verdict is classical and the twin
accepts. The members are:
- `e1C`: `(t > 3) ? 5 : 7`;
- `e2C`: a value arm;
- `e3C`: a switch data-mux;
- `e4C`: an IO-sink mux;
- `e9C`: `_Bool b = t & 1; return b ? 4 : 2`.

This is safe-direction and is cepm's class. cepm's candidate route (predict classical before
propagation) would cover it; a fix aimed at l3oi alone would not.

Separately, the provisional fp returns (`fp_{doubl,float,longd}_C`, `fpb_*`) decline at
`declineTaintEscapes`' `tainted value returned at non-i32 width` on every binary. That too is the
conservative taint at a pre-`specialize()` fence. It is PRE-EXISTING.

## What survived (measured; each null control run first)

- **Lit A/B, subject vs `main_aee8`, 2320 fixtures.** The null control was 0 of 2320 for each binary,
  each run twice. Movers: **6 D→A (9bhg's six accept fixtures) and 1 DIAG (the order pin)**. There
  were 0 A→D, 0 stream moves and 0 crashes. This matches TRACK §11 exactly.
- **Probe corpus, 2267 modules**, built from all 11 record dirs (r1A/r1B 9bhg, d88e_probes,
  r1A/r1B d88e, r1A/r1B xdu2_16, track_8e5r, xdu2_16_probes, the track's probes, r2_delta_8e5r).
  - Null control: 0 for sub, main and alone, each run twice.
  - main→sub: **38 D→A, 0 A→D, 32 DIAG, 0 STREAM, 0 crash**.
  - The 38 are the track's own 14 probes, 18 r1A modules, `r07C`, `n3`, `n4` and `s_f{32,64,80}`.
    The last six are not listed in TRACK §10/§11. They are ordered-scrub accepts, and each was
    twin-checked here: `r07C`, `n4` and `s_f*` are trace-IDENTICAL, and `n3` is DEAD-REG-ONLY.
  - **Composed-only accepts** (sub accepts, main and alone both decline): **0 of 2267**. Over my own
    348 modules there was 1, `a_v12`: F-9B-2's accept, recovered by 8e5r and twin DEAD-REG-ONLY.
    That one is expected.
- **Window battery, spec-QUANTUM** (34 caller contexts: a `cq_phi` angle, classical control, a volatile
  dead store, a volatile global, a branch, a `cq_theta` angle and seed, `cq_measure`, `printf`, a
  controlled `printf`, a shadow store, a table index, a loop bound, a data select, an `_hl` literal, a
  switch, a spec-site argument, a kickback angle, an Rz-stem angle select, `ret`, a loop, a bool seed,
  a mixed add, a d88e lift, a value arm, a nest, a condition tree, an in-loop kickback, a controlled
  store, and more):
  - 33 of 34 decline at exit 1, with 0 crashes.
  - `k03Q` (`volatile int s = f(m);`) ACCEPTS on **every** binary, `main` and `ora` included.
    `eraseDeadVolatileScalarStores` runs before propagation and leaves the call result unused, which
    is the P3-a unused-result contract. It is pre-existing and benign: `f`'s state is a separate tensor
    factor that nothing reads.
  - Plus 6 loop, 6 rail-bank/literal and 16 emitter-return contexts, and 21 clone-verdict bodies
    (QRAM, popcount, ctz, urem, select, loops, IO, volatile), both single-function and wrapped. Every
    QUANTUM verdict declines at the late ask.
- **The same contexts with a spec-CLASSICAL callee against the hand-inlined twin.**
  - Verdict parity with the twin is **34 of 34**, including byte-equal decline strings.
  - Every accept is DEAD-REG-ONLY (27 pairs × 2 argument sets), and so are the loop, rail-bank and
    emitter families.
  - Stage 2b reports 0 violations on all accepts.
  - `m3` (`e2e-spec-classical-return`) matches its golden, with STRICT 2b clean.
- **Use-vanish (S1).** With the instrumented build, no function across 2320 + 2267 modules was
  tainted at the late ask with a used call at the early slot and none at the late slot. By reading,
  every window eraser leaves a dead user behind or replaces the use; `k01Q`'s `cq_phi` deletion
  leaves a dead `sitofp`, so the call stays "used" and is refused.
- **Mask recompute (M10/M11).** 413 site resolutions produced 17 mask changes. All 17 are DROPs
  explained by the ordered scrub; there were 0 GROW and 0 UNEXPLAINED. GROW is still not
  constructed; I tried an IO-sink MuxOut reseed (`g3`), a round-1 peel (`gr2`) and a round-2 peel
  (`gr1`), and each already has `det == now`, or declines.
- **S3 / M16.** `s3a` constructs "crossed at drain 1, provisional after round 2" (a 6.5 `%out`
  newly feeding `G(r)` with `G` returning a theta). Round-2 specialization detection pre-empts it:
  `callee contains a quantum primitive` fires before the early slot. This confirms the track's
  argument, and M16 stays unpinnable.
- **Emitter returns.** An `%out` returned from `F` (4.4 select, value arm, switch data-mux, IO mux,
  6.5) is always tainted by the early slot (instrumented `tainted=1 prov=0`). So no late-ask bypass
  through an untainted `%out` was found.
- **Allocator stability.** My 348 modules gave identical results under the system allocator,
  `lifo` and `nofree`, and the corpus of 2267 gave identical results under the system allocator
  and `lifo`.

## What I did NOT attack

- The specializer and container composition: the ordered scrub against `retargetSite` REBUILD
  aliasing, `ScrubbedByReturnTaint` WeakVH semantics, and `+Asserts`/ASan builds. Those are r2B's.
- The r1B alias families with their generators. I spot-checked `v12` and `w12` only, against twins;
  both agree with TRACK §11.
- `invoke`, C++, and multi-module link orders beyond `llvm-link caller lib`.
- A statevector check of F-9C-1. The probabilities above are analytic, per the owner's no-simulator
  rule.
- Whether the WARNED siblings, the template-rail borrows, are "the user's circuit". That is bd
  `hgwx`'s open owner question. F-9C-1's P1 rests on the SILENT members only.
- The full `ctest` and `cq-opt-equivalence-full`. Nothing in this round changed code.

## Files

- `probes/src/`: every probe source. `<n>.c` plus `<n>.lib.c` builds as 2-TU (llvm-linked, the
  `run_slice_multi.sh` recipe); `<n>T.c` is the hand-inlined twin.
- `probes/tools/`: the harness scripts (`h.py`, `sv.py`, `bat.py`, `ab.py`, `cmp.py`,
  `trace_sweep.sh`, `buildcorp.py`), the generators, and `r2a_instrumentation.patch`.
- `probes/results/`:
  - `own_probes_verdicts.tsv`: 348 modules × {sub, main, alone, dbg-lifo, dbg-nofree};
  - `corpus2267_*`: the probe-corpus list and the A/B mover lists;
  - `lit2320_main_vs_sub.txt`;
  - `instrumented_sweep_summary.txt`.
