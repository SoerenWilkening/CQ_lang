# Rule-13 round r6 — bd `test_C_libtooling-vsfp` round 6 (`7ab83256`)

Narrow round on the `nullSafeSlot` / `dropEligibleSlot` split and the one-slot-question change. Independent
reviewer; no edits to the subject, no rebuilds, no sweeps, no mutation matrix (owner efficiency request).

**VERDICT: CLEAR-WITH-ITEMS** — 0 P1, 1 P2, 2 P3. The round-6 fix does what it says for bd `w7nm`
(`mt1` is TRACE-IDENT with `mtT` again), no C-reachable regression was found, and every re-derived probe
from r5 / r4A / r2B / ctz4 is unchanged or better. But the change's central sentence — *"where the two
questions differ the slot is READ everywhere, the conservative direction for each consumer"* — is false for
two of its three named consumers, and one of those two carries an exit-0 wrong unitary (IR-only).

## Binaries (sha-256 prefix, measured)

| tag | path | `cq-opt` |
|---|---|---|
| S (subject, round 6 `7ab83256`) | `<worktree>/build/ir-pass/cq-opt` | `3f6db37f5cf937b4` |
| R5 (round 5 kept copy) | `scratchpad/vsfp/bin/cq-opt.r5keep` | `74df1d02e7b90123` |
| R4 (round 4 kept copy) | `scratchpad/vsfp/bin/cq-opt.r4keep` | `829769d92e05c4e4` |
| M (oracle, `main` `aee8f4f8`) | `scratchpad/frozen/cq-opt.main_aee8` | `69250feaf68bbe49` |

Harness: `probes/tools/run.sh` (lower → stage 2b STRICT → link templates-before-runtime → run; `rc` taken
from `cq-opt` directly, no pipeline) and `probes/tools/build.sh` (the r5 recipe, 2-TU `llvm-link`). Scripts
carry this session's scratchpad paths.

## F-R6-1 (P2) — the w7nm MECHANISM survives for every other recorded-dead, not-null-safe inner slot; the "READ is conservative" claim is false for liveness

**Claim under test** (`DeadValueLiveness.h` at `isRewritableDeadSlot`; TRACK §R6.2): *"A slot this calls
'read' but the record calls dead is treated as READ everywhere — the conservative direction for each
consumer (… liveness: the operand survives)."*

It is false one clone level up, and the subject's own comment two screens away says why
(`DeadValueLiveness.cpp`, the w7nm note): *"A read counted here is NOT local: through `deadParamMask` it
makes the enclosing clone's parameter LIVE one level up."* Round 6 removed `musttail` from the set of
reasons an inner slot is not rewritable; it did not remove the mechanism. Any inner slot that is recorded
dead and NOT null-safe still turns the enclosing clone's parameter live, the outer (null-safe) phantom slot
is never neutralised, and `resolvePhantomCloneArgReads` cannot see it (it only looks at slots the OUTER
record calls dead).

**Repro** (`probes/csrc/sa1.ll`): r5's `mtN` stage-1 IR (the plain-tail twin of `mt1`) with one edit —
`h2`'s parameter 0 carries a string attribute (`i32 noundef "cq.probe.opaque" %0`). Twin: r5's `mtT`.

| | opt | warn | 2b STRICT | lines | vs twin `mtT` |
|---|---|---|---|---|---|
| S | 0 | 1 (`non-diagonal gate over a live derived record`) | `2 verified, 0 violation(s)`; census 2 dirty | 12 | **TRACE-DIFF** |
| R5 | 0 | 1 | same | 12 | TRACE-DIFF |
| R4 | 0 | 0 | `3 verified`; census 1 dirty | 14 | TRACE-IDENT |
| M | 0 | 1 | same as S | 12 | TRACE-DIFF |

`probes/results/sa1_vs_mtT.diff` — the subject omits exactly the twin's discharge of `p = 3q` before the
second Ry:

```
9a10,11
> cq_template_mul_i32_hl_unc(h1, h0, 3)
> cqrt_free(h1)
```

`probes/results/sa1.S.s2.ll`: `@main` passes `%h_op` into `@__cq_q_h_01` in a LIVE slot; inside, the call
to `@__cq_q_h2_01(i32 noundef %0, …)` keeps the operand (not null-safe) and counts as a read. `h1` stays
dirty and entangled with `h0` across `cqrt_ry_i32(h0, 0.7)` — bd `tzfa`'s wrong unitary, the oracle's
stream byte-for-byte, exit 0 (warned, not silent).

**Reachability.** IR-only as far as I could establish: clang-19 `-O1` on x86-64 puts only
`noundef`/`signext`/`zeroext`/`range`/`nofpclass` (all allowlisted) on an int/fp parameter, and a quantum
value cannot reach a pointer, vector or aggregate slot of a clone without `scanBody` declining first. `musttail`
was the one C-reachable policy reason and round 6 moved it. A silent value-merge variant (`sa2.ll`, the
phantom operand a 4.4 `%out`) declines earlier at the 4.4 fence on every binary, so the witness is the warned
template-rail member. Rated P2 (falsified claim + IR-only wrong unitary, pre-existing on the oracle,
introduced vs round 4 by round 5, not closed by round 6); it is a P1 the day a C spelling of a
non-allowlisted int attribute appears.

**Why the round's own instrument missed it.** TRACK §R6.2's IR construction (`vsfp_probes/r6/src/w2probe.ll`)
puts the string attribute on an inner slot whose operand `%p` is ALSO read live in `h` (`%u = add %p, %t`),
so there is no phantom read to expose. It measured W2 against S (byte-identical, true) and never against a
twin. The shape that matters is the one where the non-null-safe inner slot is the outer parameter's ONLY
reader.

**Fix direction (not prescriptive).** Prime Directive: in `buildClone`, a recorded-dead inner slot that is
not null-safe and whose operand is quantum in `cloneTaint` should decline loudly with `kMsgPhantomArgRead` —
the module-level rule of `resolvePhantomCloneArgReads` step 1, one level down. Alternatively, for an
`Argument` operand, liveness need not count the slot as a read: an `Argument` is never deleted, so "the
operand survives" holds without it. Either way, correct the sentence at the source in the same change (L7 —
bd `z9t1`).

Filed: bd `test_C_libtooling-nlfd` (P2).

## F-R6-2 (P3) — "M-A: a hop → more records" names the wrong direction

`cloneArgReachesResult` has exactly ONE caller, `reachesObservingSink` (`RotationLowering.cpp:1890`), which
is M-A's clause-3 EXEMPTION walk. There a hop moves toward an observing sink, which EXEMPTS the record (fewer
lyyf-(B) warnings). The same file's round-2 note calls exactly that an OVER-ACCEPT: *"A clone that IGNORES a
parameter returns a result independent of it, so exempting a record on 'the clone's result is measured' was
an OVER-ACCEPT."* The clause-1 walks, where a clone hop *adds* records, do not call this predicate (the
comment at `RotationLowering.cpp:1393` says so). Round 6 flipped a recorded-dead, not-null-safe slot from
"no hop" (round 5, bare record) to "hop" — the exempting direction — while the comments in
`DeadValueLiveness.h` and at `RotationLowering.cpp:1419` (and TRACK §R6.2) call it conservative.

The two predicates answer DIFFERENT questions, and Rule 14 does not license merging them: liveness asks
"does the operand have to exist?" (yes, while it stays in the slot). M-A asks "does the clone's result
depend on this argument?" (no, whatever null-safety says). The honest answer for M-A is the bare record.

**Not reachable today** (argued; I did not construct a counter-example): M-A gates are rotations, which occur
only in non-clone functions (`scanBody` declines `cq_theta` in a clone), and there a recorded-dead,
not-null-safe slot with a quantum operand is declined by `resolvePhantomCloneArgReads` step 1 before
`lowerRotations` runs. So the verdict is P3: a wrong-direction justification on a currently unreachable
edge (L7's shape). Either revert M-A to `isRecordedDeadSlot` or state the unreachability argument as the
reason. Do not keep "conservative". Filed: bd `test_C_libtooling-x8ut` (P3).

## F-R6-3 (P3) — the split moved `naked` too, not only `musttail`; an unannounced D→A, sound, with an unwritten dependency

`nullSafeSlot` dropped every callee conjunct: `!isDeclaration`, `hasExactDefinition`, `!naked`, `!isVarArg`
and the function-type match. Only a callee with a record (a clone) reaches it through `isRewritableDeadSlot`,
so I enumerated them against clones:

| conjunct | vacuous for a clone? | why |
|---|---|---|
| declaration | yes | a clone is a definition |
| `hasExactDefinition` | yes | clones are `InternalLinkage`; `scanBody` (0-pre) requires the original exact, so the recorded body is the body that runs |
| variadic | yes | `scanBody` (0a) declines varargs; the fp path builds `isVarArg=false` |
| function-type match | yes | LLVM 19 `CallBase::getCalledFunction()` returns null on a type mismatch (`InstrTypes.h:1465`), so neither `isRecordedDeadSlot` nor `nullSafeSlot` sees such a call |
| `returned` | kept in `nullSafeSlot`; also stripped from clones (`stripStaleClassicalAttrs`) | — |
| `musttail` | policy only | a constant changes no signature and no ABI attribute (`range`/`nofpclass` are not ABI attrs); `mt1` runs twin-identical |
| **`naked`** | **NO** | `CloneFunction` copies `naked` onto the clone |

**Measured** (`probes/csrc/nk5.ll`, IR-only — a C naked body must be asm-only): a `naked` callee with a pure
body `ret (k + 1)` in `mt1`'s main. S accepts (the naked clone `@__cq_q_f_01` keeps `naked` and is called
with `i32 noundef 0`), TRACE-IDENT with `mtT`, 2b `3 verified`; `llc -O0` shows the clone reads only
`%esi`. **R5 DECLINES** (`quantum argument to a parameter the lifted callee never reads`); M accepts with the
phantom (12 lines, 1 dirty, warned). A D→A move that TRACK §R6.5's corpus A/B did not contain ("4 movers,
all w7nm's shape").

It is sound, and the argument is two facts nobody wrote down at `nullSafeSlot`: the verifier forbids any use
of a naked function's argument, and `scanBody` declines inline asm. So no clone body can observe the slot.
ctz4's hazard (asm reading the argument REGISTERS) is therefore held off by `scanBody`'s inline-asm decline,
not by anything the slot predicate asks. Write that down at `nullSafeSlot` as a retirement trigger (L8): the
day `scanBody` admits any inline asm, `nullSafeSlot` must refuse a `naked` callee, or ctz4's wrong value
comes back through the rewrite. `naked1`/`naked2` are unchanged (below). Filed: bd
`test_C_libtooling-xmew` (P3).

## Re-derivations (attack 3)

All under S, R5, (R4), M; `probes/results/k_family.txt` holds the r2B table.

- **`mt1` / `mtN` vs `mtT`** — S: `mt1` and `mtN` TRACE-IDENT with `mtT` (14 lines, 2b `3 verified, 0
  violation(s), 0 unproven`); R5 `mt1` TRACE-DIFF (12 lines, warn 1) and the oracle both TRACE-DIFF; R4
  TRACE-IDENT. The census on S `mt1` is `5 template rail mint(s) of which 1 left dirty` against `mtT`'s
  `3 … 0`. I checked the lowered module: the two extra "mints" are the clone CALLS `%7` (main) and `%3`
  (inside `@__cq_q_h_01`), both classical results (the F-XA-5 census artefact the TRACK names). No real
  rail is dirty. The inner `musttail` slot is `i32 noundef 0` (the CLONE prefix's claim).
- **r4A `bv` / `bvn2` / `pn`** — executables RUN on S: exit 5, 8 / 18 / 8 trace lines, 2b clean,
  trace-identical to R5 and to the oracle. No pointer or `byval` argument is `null`: `pn`'s call keeps
  `ptr noundef nonnull %3`, `bv`/`bvn2` keep `byval(%struct.Big)` operands. `bvn` declines identically on
  all three. `cn` is TRACE-IDENT with its DAE twin `cnD` on S (27 lines; the oracle 33, as r4A recorded).
- **r2B `k19` and members** (`k8`, `k14`, `k18`, `k19`, `k24`) — all accept on S, R5 and M, TRACE-IDENT with
  their `…F` twins on S. `k19v` TRACE-IDENT. Non-members `k1`–`k7`, `k10`, `k12`, `k13`, `k15`, `k16`,
  `k20`–`k23` are TRACE-IDENT with their twins. `k9` is TRACE-DIFF with `k9F` on S, but S equals R5 byte for
  byte, and r2B recorded the subject's stream hash as already different from main's, so round 6 did not move
  it. `k11F` does not build standalone (no lib TU), and `k11` on S equals R5. **No k-family row moved between
  R5 and S.**
- **ctz4 `naked1` / `naked2`** — `naked1`: S and M both print `ident=15` (= 5·3), traces identical, exit 0.
  `naked2`: S and M both decline, `callee contains a non-reversibilizable construct under quantum lift
  (inline assembly)`.
- **Module-level `musttail` to a clone** (`mm1.c`, non-void — r5's `mt3` was the void, no-op form): declines
  on every binary at `cq taint escape: quantum value returned across a function boundary`. Before
  `specialize()` the musttail call's result is conservatively tainted and it IS the return value. So round
  6's musttail-slot rewrite has no module-level customer in this shape. The plain-tail twin `mmN` accepts
  TRACE-IDENT with `mmT` on S/R5/R4, and the oracle declines. The musttail form declining where the twin
  accepts is the drop's documented policy (pre-existing on every binary), not round 6.
- Lit: the four round-6-touched fixtures (`--filter 'phantom_arg_read_(musttail_inner|byval|pointer)'`)
  pass 4/4. `ctest -R "musttail-inner|byval-slot"` passes 4/4. Nothing else was run.

## Attack 2 — the reconciliation, consumer by consumer

`isRecordedDeadSlot` has one direct caller left, `resolvePhantomCloneArgReads` (`Specialization.cpp:1374`).
Every other consumer asks `isRewritableDeadSlot`: `FunctionLiveness` (`DeadValueLiveness.cpp:197`),
`rewriteRecordedDeadSlotUse` (`:152`), which also serves `deleteDeadCones` step 3 and `buildClone`'s dead-param
loop, M-C (d0) (`ArithLowering.cpp:654`) and M-A (`RotationLowering.cpp:1411`). Consistency between the
REWRITE and the LIVENESS holds: a not-null-safe slot's operand is live, so it is never in `Del` and never
needs the rewrite. `userProgramReads` counts every clone-call slot as a read, which is the right answer
after neutralisation. The per-consumer "conservative" claim fails in two places:

- **d0** holds — "not settled" falls to (d)/(e), out of place.
- **liveness** fails — F-R6-1.
- **M-A** fails — F-R6-2.

## What I did NOT attack

- No corpus A/B, no mutation matrix, no full lit or ctest (owner request). The claims above rest on the
  named probes only.
- The census artefact itself (clone calls counted as template mints). I read it on `mt1` only.
- `nullSafeSlot`'s attribute allowlist against every LLVM-19 int/fp parameter attribute. I checked the ones
  clang emits on x86-64. I did not audit `inreg`/`alignstack`/`allocalign` codegen with a constant.
- Whether a C spelling of a non-allowlisted int/fp parameter attribute exists on another target (i386
  `regparm` gives `inreg`, which is allowlisted). F-R6-1's C-reachability rests on "none found".
- The `_unc` twin's copy of a clone call whose forward operand was neutralised (the r4A "twin call carries no
  `byval`" note). Not re-derived.
- Clone bodies' own inner LIVE-operand-in-dead-slot case (an operand live for another reason stays in the
  slot while d0/M-A call the slot dead). Pre-existing; unchanged by round 6 for null-safe slots.
- `ad35` (comment-only QRAM change): read, not attacked.

Probes: `probes/csrc/` (`sa1.ll`, `sa2.ll`, `sb.c`, `sbT.c`, `nk3.ll`–`nk5.ll`, `mm1.c`, `mm1.lib.c`, `mmN.c`,
`mmT.c`), `probes/results/` (`sa1.S.s2.ll`, `sa1.S.trace`, `sa1.S.stderr`, `mtT.S.trace`, `sa1_vs_mtT.diff`,
`k_family.txt`), `probes/tools/` (`run.sh`, `build.sh`). The other probes are read from the r5 / r4A / r2B /
r1A review directories.
