# Rule-13 round r1B on bd `test_C_libtooling-vsfp` (+ `hgwx`): the backstop, M-C arm (d0), the emitted circuits, and composition with bd 9bhg

Reviewer: independent agent, 2026-09-26. Subject: branch `worktree-agent-abf65d7dcfbff38c8`, commit
`5e56060b`. A concurrent round (r1A) attacks the early dead-argument rewrite (`dropDeadCallArguments`)
and the re-spelled fixtures; this round took the backstop `declinePhantomCloneArgReads`, M-C arm (d0),
the circuits, and the composition with bd 9bhg.

Nothing in the subject or 9bhg worktrees was edited or rebuilt. Every build below was made in a
private `git worktree` under the session scratchpad and removed after the round.

| tag | binary | `cq-opt` sha-256 prefix |
|---|---|---|
| sub | subject `5e56060b` (the worktree's `build/`; a private rebuild of the same commit hashed **bit-identical**, so the build null control fired) | `73fd07592c4960dd` |
| main | oracle `aee8f4f8` (`frozen/cq-opt.main_aee8`) | `69250feaf68bbe49` |
| 9bhg | bd 9bhg `f2148d0a` (that worktree's `build/`) | `bfb441d3b9568bd1` |
| comp | private merge of `f2148d0a` onto `5e56060b`, with the implementer's two composition patches applied (`vsfp_probes/results/compose_9bhg_*.patch`) | `e29f68ce5298dedc`. This is **bit-identical to TRACK_VSFP §7's recorded composed hash**, so the composition was reproduced and not approximated. |
| proto | evidence-only prototype of a fix route (§ "Prototype"); never to be committed | `2b1f0c401e472198` |
| B1–B4, D1, D2, M0 | re-built mutants (§ "Re-measurements") | see `probes/results/mutation_rerun.txt` |

Harness: `probes/tools/h.sh` (bash) runs stage 1 (2-TU = the `run_slice_multi.sh` recipe), stage 2,
stage 2b `free_pairing_check.py` STRICT plus the CENSUS line, and a link with templates BEFORE
runtime; `pairs.sh` compares the result against a twin. Every input is argv-derived (`atoi`), which
avoids the bd 46oo trap. An s1 module under 200 bytes is refused (empty-module trap). Positive
controls fired in both directions: the oracle's `b10` is `TRACE-DIFF` from its twin while the
subject's is `TRACE-IDENT`, and the census grep reads `1 left dirty` on the oracle's `b10`.

## Verdict: **NOT-CLEAR**

The change does not make anything worse than `main`. On every probe in this round the subject either
matches the oracle or improves on it. What it does not do is the job it claims to do.

The claimed job is "a TOTAL backstop". The backstop's observable question is `use_empty()` of the
built clone's parameter. The fenv-ruled erasure deletes only the volatile STORE, so any `volatile`
store of a CONVERTED or DERIVED parameter leaves a dead cone. Examples are `volatile char z = a;`,
`volatile long z = a;`, `volatile double z = a;` and `volatile int z = a * 3;`. The clone
Bennett-reverses that dead cone, so the parameter still counts as used. The result is bd vsfp's own
silent Rule-8 dephasing, reachable from C at exit 0 with 0 warnings and stage 2b STRICT clean
(F-VB-1).

Composed with bd 9bhg, the same spellings of every F-9C-1 member that `main` declines are accepted
silently (F-VB-2). The r2A F-9C-1 finding ("population GROWN by 9bhg") is therefore **not
discharged** by vsfp, and it must not be cited as the 9bhg landing gate.

| id | sev | attribution | one line |
|---|---|---|---|
| **F-VB-1** | **P1** | **PRE-EXISTING** (byte-identical on `main`). NOT closed by vsfp; the "TOTAL" claim is falsified. | A callee that volatile-stores a converted or derived parameter keeps the caller's which-path rail (4.4 `%out`, 6.5 `%out`) alive across a later non-diagonal gate. The dephasing is silent, and the backstop is blind to it. The hgwx half is the same: arm (d0) is blind to the same spelling. |
| **F-VB-2** | **P1** | PRE-EXISTING class, population **GROWN by 9bhg, and NOT discharged by vsfp** | Composed vsfp+9bhg silently accepts the `volatile char` spelling of `b15f`, `b10f`, `s3c`, `b26` and `b20` (5 of 5). `main` and the subject decline all five. |
| F-VB-3 | P2 | INTRODUCED (record and source claims) | The backstop's only C-reachable customer is attributed to "the CLONE pipeline". It is actually the MODULE pre-pass `eraseDeadVolatileScalarStores`, which runs on the ORIGINAL callee before `detectSpecializations`. The customer was therefore predictable before emission, and it declines a program whose fenv meaning is the coherent twin. |
| F-VB-4 | P3 | INTRODUCED (unnamed A→D class) | The backstop declines a derived operand even when no later non-diagonal gate touches its source. An example is C's integer promotion of a `_Bool` register at the call (`v12`), where `main` compiled a correct distribution. |
| F-VB-5 | P3 | record claim; verdict-neutral | The slot rationale "any OTHER owner that fires here fires on the twin too" is false. `v27` declines at l3oi's string on every binary, while its twin ACCEPTS. |
| F-VB-6 | P3 | record and source wording | "`e2e-spec-dropped-arg-*-twin-identical` is RED on the oracle" is wrong: that gate is a `compare_files` of two COMMITTED goldens and cannot be red on any binary. What is red on the oracle is `e2e-slice-spec-dropped-arg-{boolsel,inplace}` (measured). |
| F-VB-7 | P3 (qjoc input) | PRE-EXISTING | bd qjoc is confirmed on `main`, sub, comp and 9bhg, all byte-identical. Its falsification of CLAUDE.md's fenv "Both are sound" sentence is broader than the bead states. A dead TEMPLATE product whose source takes a later non-diagonal gate is not "uncomputed and freed" either: it is left dirty, with a warning. |

## F-VB-1 (P1): the backstop is not total. Converted or derived volatile stores reach bd vsfp's silent class

### Mechanism, measured

`eraseDeadVolatileScalarStores` (QramLowering.cpp; its own comment says "THIS STAGE does not touch
the stored VALUE") erases the store and leaves the stored value's cone dead in the callee. For
`h(a,k) { volatile char z = a; return k + 1; }` that cone is `trunc i32 %a to i8`. Nothing deletes it.

The clone of `h` lowers it as `cq_template_trunc_i32_to_i8` plus its `_unc`, inside the Bennett wrap.
So the built clone's parameter 0 **has a use**, and `declinePhantomCloneArgReads` (`use_empty()`) stays
silent. `dropDeadCallArguments` is silent too (its `use_empty()` test also sees the trunc).

The caller's operand is kept alive exactly as in the bead. The clone's forward-and-reverse pair is a
net identity on `%out`, and the `%out` rail stays entangled with `b` across `Ry(.7)`.

Repro `v15vc` (2-TU, `probes/src/v15vc{,.lib}.c`):

```c
// lib:    int h(int a, int k) { volatile char z = a; return k + 1; }
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5);
  int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
```

The subject's trace (identical on `main`):

```
cqrt_alloc_i1(1) -> h0 ; cqrt_ry_i1(h0, .5) ; cqrt_alloc_i1(0) -> h1 ; cqrt_cnot(h0, h1)
cqrt_alloc_i32(0) -> h2 ; ... two cqrt_copy_i32_controlled(h1, 9|4, h2) ... ; cqrt_free(h1)
cq_template_trunc_i32_to_i8(h2) -> h5 ; cq_template_trunc_i32_to_i8_unc(h5, h2) ; cqrt_free(h5)
cqrt_ry_i1(h0, .7)        ; h2 still records b
cqrt_measure_i1(h0)
```

`opt` exits 0 with **0 bytes of warnings**. Stage 2b STRICT reports `0 violation(s), 0 unproven` and
`0 left dirty`, because h2 is an `alloc` rail that is never freed: the bead's "WHY UNSEEN". The
circuit has the same structure as r2A's `b15`. For odd m, P(b=1) = sin²(.25)·sin²(.35) +
cos²(.25)·cos²(.35) = **0.8356**. Under the fenv ruling the program means the one without the
volatile line, whose circuit is `Ry(.5)Ry(.7)` on one handle: cos²(.6) = **0.6812**. That fenv-intended
twin is `b15T`, and the subject's trace differs from it.

### Population (all silent: exit 0, 0 warnings, 2b STRICT clean; byte-identical on `main`)

Results are in `probes/results/fvb1_silent_members.txt`. Each callee body is `h(a,k){ <X> return k+1; }`.

| probe | `<X>` | operand |
|---|---|---|
| `v15vc` `v15vs` `v15vl` `v15vd` `v26vf` `v26vb` | `volatile {char,short,long,double,float,_Bool} z = a;` | 4.4 bool-select `%out` |
| `v02`, `v01` | `volatile int z = a * 3;` | `%out` (`b ? 9 : 4` / `b + 1`) |
| `v15vx`, `v15vn` | `volatile int z = a ^ k;` / `= -a;` | `%out` |
| `v26v2s` | `volatile int z = a; z = a + 1;` | `%out` |
| `v29c` | `volatile char z = a; char w = z; … (w - w)` (a load, promoted by `promoteVolatileScalarLocals`) | `%out` |
| **`v20`** | `volatile char z = a;` | the **round-2 6.5 `%out`**: this is r2A's `s3d` in this spelling, `if (q > 3) r = K(m); u = h(r, m); q = cq_theta(q, .7)` |

The controls went the other way. `volatile int z = a;` (the shipped fixture), `volatile int z = a;
volatile int w = a;` and the int-load spelling `v29` all DECLINE at the backstop. So the fence
catches the one width-preserving spelling and none of its neighbours. Every member was deterministic
under the system, `lifo` and `nofree` allocators (lowered-IR sha identical).

### The hgwx half: arm (d0) is blind to the same spelling

`v30` is TRACK_VSFP's own `hv` probe with `volatile char z = a;`. The clone now reads `q` (the dead
trunc), so (d0) does not apply and G7 falls to (d). The result is `cq_template_add_i32_hl(h0, 6) ->
h2`, then `Ry(.2)` on h2 while h0 keeps the which-value record: dephased, with only the lyyf-(B)
warning. The twin (`v30F`) lowers in place, coherent. The trace is byte-identical on `main`, so this
is PRE-EXISTING. TRACK_VSFP §5 says (d0) "fixes the C-reachable volatile-callee spelling of hgwx". It
fixes ONE spelling.

### Why nothing caught it

- Every probe and fixture in the record uses the one same-width spelling. The bead's own
  "empty-quadrant" lesson (§4k) applies again: the census had no member of "a volatile store of a
  converted parameter".
- The backstop's question is a proxy. The real property is "the built clone's parameter reaches
  nothing but a Bennett-reversed dead cone", and `use_empty()` is only its most degenerate case.

### Attribution and consequence

The defect is PRE-EXISTING: every member is byte-identical on `main`, so the subject introduces none.
But bd vsfp should **stay open** (or a successor should carry it). The record's and bead's closure
language is false: "A TOTAL backstop", "Every F-9C-1 member … twin-identical or declines" (true of the
members and false of the class), and the (d0) "fixes the C-reachable volatile-callee spelling". Filed
as bd `test_C_libtooling-a8q5`.

## F-VB-2 (P1): composed with 9bhg, F-9C-1's grown population survives vsfp

Each member below is the corresponding r2A member with the library changed to `volatile char z = a;`
(`probes/src/v2{1..5}{,.lib}.c`).

| probe | = r2A member | main | 9bhg | **sub** | **comp** |
|---|---|---|---|---|---|
| `v21` | `b15f` (inside provisional `f`) | DECL 3jru | acc, 0 warn | DECL 3jru | **acc, 0 warn, 2b clean** |
| `v22` | `b10f` | DECL 3jru | acc | DECL 3jru | **acc, 0 warn** |
| `v23` | `s3c` (6.5 `%out`) | DECL 3jru | acc | DECL 3jru | **acc, 0 warn** |
| `v24` | `b26` (caller side) | DECL 3jru | acc | DECL 3jru | **acc, 0 warn** |
| `v25` | `b20` (ordered scrub) | DECL l3oi | acc | DECL l3oi | **acc, 0 warn** |

Each composed trace carries the `%out` copy block across the later `Ry` on the copied register (for
`v21` the stream is exactly F-VB-1's `v15vc`). Stderr is 0 bytes. The lowered IR was identical
under the system, `lifo` and `nofree` allocators.

So TRACK_VSFP §7's "every F-9C-1 member … is twin-identical or DECL-SAME composed" is true of the
16 member PROGRAMS and false of the CLASS. The composed tree still accepts, silently, a wrong-unitary
population that `main` declines. That was exactly r2A's reason for NOT-CLEAR on 9bhg, and vsfp does
not discharge it.

## F-VB-3 (P2): the backstop's C customer is a MODULE pre-pass, not "the clone pipeline" (L7 shape)

These are the claims:

- `Specialization.h` says "a use the clone pipeline removed after the drop ran … is caught too".
- The header of `spec_reject_phantom_arg_read_volatile_callee.ll` says "But the CLONE's pipeline
  erases that store … the phantom read the drop could not predict".
- The (d0) comment in `ArithLowering.cpp` says "`volatile int z = a;` in the callee, which the
  clone's lowering erases".
- TRACK_VSFP §1, §2 ("A use the CLONE pipeline later removes is the backstop's") and §4 say the
  same, and so does the text of bd jr8q.

This is what was measured. With `CQ_SPEC_DBG=1` on that fixture, the "module before
`detectSpecializations`" dump already shows `@h` as `%3 = add nsw i32 %1, 1; ret i32 %3`, with
parameter 0 unused. The store was erased by `eraseDeadVolatileScalarStores(M, taint)` in `run()`'s
pre-pass block. That call iterates every defined function, the original library callee included. It
runs about 180 lines after `dropDeadCallArguments` and before PredMux, `detectSpecializations` and
any emission. No clone exists yet.

Why it matters:

1. The customer is predictable before emission, which contradicts the "observer-only" rationale. The
   timing argument that forced the drop to be FIRST does not stop a second drop after the fenv
   pre-passes: they run before `detectSpecializations` and before round-1 emission. That argument is
   carried by the Prototype below.
2. The shipped outcome for that customer is a DECLINE of a program whose fenv meaning is the coherent
   twin, and the owner has ruled over-declines to be defects. The record frames it as "the safe
   direction, costs no correct accept". It costs one: the fenv-intended program.
3. The genuine clone-pipeline removal (PredMux's scoped sweep inside the clone) is exercised only by
   the HAND-WRITTEN IR fixture `…clone_sweep.ll`. It has no C-reachable member in the record.

Correct the source comments in the same change. L7 with a twist: a record correction that does not
reach the source is not a correction.

## F-VB-4 (P3): an unnamed A→D class (a derived operand with no later non-diagonal gate)

`v12`: `_Bool b = cq_theta(...); int t = h(b, m); return t + cq_measure(b);` with the volatile-int
callee. C promotes `b` to `int` at the call, so the operand is `zext` (a template copy of `b`, not a
`cq_theta` result), and the backstop declines. On `main` the circuit left one CNOT-type copy of `b`
allocated and then measured `b`. That gives the correct distribution (a Rule-6 accepted leak), and
the twin accepts.

The same holds for a `short`/`char` register passed to an `int` parameter (`sext`/`zext`). When
`b` IS later rotated, declining is right (that is vsfp's class). The fence cannot tell the two cases
apart, which is its declared design ("declines loudly, never warns"). The A→D census in TRACK §8
(14 = z0re + `s3d`) is corpus-bound and does not name this class. Record it. The narrower route (2) in
the bead text would not decline it.

## F-VB-5 (P3): the "last owner" rationale is false in one direction

The claim at `CQLoweringPass.cpp`'s backstop slot is: "the hand-inlined twin never computes the
phantom operand, so any OTHER owner that fires here fires on the twin too". `v27` is a counterexample:
`t = h1(q, m)` is classical-verdict, `p = b ? t : 7`, and `u = h(p, m)` is the phantom read. The
phantom operand's own cone (a 4.4 select reading the scrubbed `t` as a handle) is what l3oi refuses.
`main`, 9bhg, sub and comp all decline `classical call result used as a quantum register`, while the
twin (`v27T`) ACCEPTS. The verdict is unaffected (the backstop would decline too). The justification
is wrong: "fires on the twin too" should be "fires on the phantom operand's cone, which the twin does
not have".

## F-VB-6 (P3): e2e wording

The `*-twin-identical` gates are `cmake -E compare_files` over two committed goldens and are
binary-independent. What is measured is this:

- On the oracle, the 2-TU `boolsel` stage-2 module runs to a **15-line** trace with the `%out` copy
  block, and the `inplace` one to the out-of-place stream. Both DIFFER from the committed goldens,
  so `e2e-slice-spec-dropped-arg-{boolsel,inplace}` are red on the oracle.
- On the subject, both match the goldens byte for byte. `ctest -R 'spec-dropped-arg|spec-lift-scrubbed-elsewhere'`:
  9/9 passed on the private bit-identical rebuild.

Fix the sentence in `CMakeLists.txt`, the two slice headers and TRACK §3.

## F-VB-7 (P3, input to bd qjoc)

- `qjoc` is confirmed: `main`, sub, comp and 9bhg all give `trace_sha 3b3f53f7803f`, 15 lines, 0
  warnings, 2b clean. The fenv-intended twin is `b15T`, 4 lines.
- **vsfp does not change qjoc's single-TU population.** In 2-TU it moves exactly one spelling
  (`volatile int z = a;`) from silent to DECLINE. Every other spelling (F-VB-1) is qjoc's mechanism
  inside a clone and is unchanged.
- **The fenv sentence is falsified on both halves, not only for the select.** `qjoc_tpl` is
  `p = q * 3; volatile int z = p; … q = cq_theta(q, .7)`. It lowers `cq_template_mul_i32_hl(h0, 3) ->
  h1` and **never uncomputes it**: h1 is left dirty across `Ry(.7)` on h0, with the lyyf-(B) warning.
  So "the dead product IS lowered, uncomputed and freed … Both are sound" (CLAUDE.md) and "harmless"
  (`QramLowering.cpp`, at the erasure) are false for a template product whose source later takes a
  non-diagonal gate. The template case is warned and the select case is silent.
- This is an owner-ruled section, so I report and do not edit it.

## What held: the attack list, answered

1. **The `cq_theta` exemption.** Nine exempt shapes were probed, and all are twin-identical or
   identical to `main`:
   - `v04`: a source, rotated and measured after the read;
   - `v06`: a STALE name read after a relabel;
   - `v11`: a classical one-register lift (the φ is RAUW'd to its theta base before the backstop);
   - `v13`: the in-place Ry arm (M-β RAUW to the hoisted theta);
   - `v14`: state prep;
   - `v03` and `v03b`: a theta CHAINED on a derived 4.4 `%out` or template rail;
   - `v16` and `v16b`: a spec-quantum clone with the theta in an unread slot, alone or also in a read
     slot.

   The chained case is harmless for a structural reason: `cq_theta` is never deleted (no attributes
   in `CQ.h`), so the twin computes and rotates the same derived rail. Each of these was run on the
   rebuilt mutant **B2** (exemption removed), and all nine then DECLINE, so the exemption is broadly
   load-bearing. Consumers other than M-C:
   - FreePoint never frees a theta register.
   - The stale-reader fence asks only about `cq_theta` arg-0 and `cq_measure` (`v06` accepts,
     twin-identical).
   - M-A over-warns (bd jr8q; `v04` warn=1).
   - The census counts the clone call as a template rail (jr8q).

   None changes a stream. The loop spellings (`v10`, `v17`, `v18`) decline on every binary at the
   loop fence, `loop-carried tainted value crosses iterations`, while their twins accept. That is a
   pre-existing over-decline, not vsfp's.
2. **Totality.** It is falsified (F-VB-1). What does hold:
   - The backstop scans every non-clone function and every slot.
   - The round-2 6.5 `%out` IS in `taint.Tainted`, because `ClassicalCallArmEmit`/`SelectMergeEmit`/
     the switch emitters insert `Out` (`v07`, the int spelling of `s3d`, declines at the backstop).
   - Clone membership is the specializer's record: every `buildClone` writes `SpecHandleArgMask`.
   - The clone-body skip is sound for what I could reach. Nested phantom `v08c` (a template rail
     inside `h`'s clone passed to an inner clone with an unread slot) is Bennett-uncomputed inside the
     clone. A select-rail nested phantom (`v08d`) declines at `callee contains tainted control flow
     under quantum lift`.
   - Pointer and escaping-volatile spellings (`v28`, `sink(&z)`) decline at spec (`non-reversibilizable
     construct`).
3. **(d0).** Sound as far as I could attack it.
   - A settled call EXECUTES before the in-place gate, and reading `P` then is correct. G6 still
     refuses any use after the site.
   - M-C does not run inside Bennett clones (`!inBennettClone` gates (1b)), and the top-level spine
     emits no clone `_unc`. `v16`'s dead spec-quantum `out` rail is left allocated, not reverse-played,
     so (d0)'s adjoint argument is moot in today's tree. Its `_unc`-twin claim is also true by
     construction (`synthUncomputeTwin` copies the built clone).
   - `v16` is a second C-reachable (d0) customer: a spec-QUANTUM clone with an unread volatile slot.
     It moves `main`'s out-of-place, warned stream to a coherent in-place one. On D1 it reverts to
     `main`'s stream.
   - Passing `P` in both a read and an unread slot (`v16b`) falls through to (d): identical on `main`.
   - The `!isDeclaration()` vs the drop's `hasExactDefinition()` mismatch is unreachable: a weak
     callee declines at spec, `non-link-exact definition` (`v09`).
   - (d0) is blind to the converted-store spelling (F-VB-1, `v30`).
4. **Circuits.**
   - All 16 r2A F-9C-1 members (`b10 b15 s3d b10f b15f s3c b26 b20 b2 b5 b6 b7f b8f b12f b17f
     b18f`) and hgwx's `j02C e02C j01C` were run on sub AND comp. Each is TRACE-IDENT to its
     hand-inlined twin, or DECL-SAME with it (`s3d`/`s3c`: `control flow under quantum control`,
     like `s3dT`/`s3cT`).
   - All have 0 warnings. Stage 2b STRICT and the CENSUS show `0 violation(s), 0 unproven` and
     `0 left dirty` on all 49 sub/comp stage-2 modules. The census grep was checked against a
     positive control: the oracle's `b10` and 9bhg's `b20` read 1 and 2 dirty.
   - `b10f` on sub and comp: `alloc_i1(1); Ry(.5); Ry(.7); measure` = `Ry(1.2)|1⟩`, so P(b=1) =
     cos²(0.6) = **0.6812**, the twin's.
5. **qjoc.** See F-VB-7.
6. **Re-measurements.**
   - **lit** on a private rebuild bit-identical to the subject: **2328 discovered, 2327 passed, 1
     XFAIL**.
   - **e2e**: see F-VB-6. Both 2-TU slices are red on the oracle and green on the subject.
   - **Mutation matrix** (rebuilt here, full lit per mutant, denominator 2328 each; the null M0
     rebuilt to the subject's exact hash with 0 failures): B1 3, B2 2, B3 10, B4 2, D1 1, D2 1. All
     are **identical to TRACK_VSFP §9**, down to fixture names.

     ⚠ My first run reported `failed=0` for every mutant with an EMPTY denominator. `lit.cfg.py`
     refused to run because `cq-opt-debugalloc` was older than the mutant `cq-opt` (a good fence). The
     harness now refuses a run without a denominator and builds `cq-opt-debugalloc` too. This is L10's
     family, caught by printing the denominator.
   - **Crash sweep**: 521 programs (every r2A_9bhg and d88e probe program), each run on sub and comp.
     **0** rc ∉ {0,1}. Accepts: sub 275, comp 276 (`probes/results/sweep.txt`).

## Prototype of a fix route (evidence only, not a clearance)

`probes/tools/proto.py` makes two changes:

- (a) It applies bd qjoc's candidate fix: `eraseDeadVolatileScalarStores` deletes the erased
  store's now-dead NON-CALL value cone.
- (b) It calls that erasure once more immediately BEFORE `dropDeadCallArguments`, so the drop sees
  the post-fenv callee.

Results:

- 11 of the 13 F-VB-1 members become **coherent accepts byte-identical to the fenv-intended twin**,
  and so do `qjoc` and `qjoc_tpl`. So does `v26vtwo`, and so do the three shipped `volatile int z = a`
  fixtures, which now accept their twin's stream instead of declining.
- `v04` loses its spurious warning, `v12` (F-VB-4) and `v27` (F-VB-5) accept like their twins, and
  `v20` and `v07` decline with the twin's string.
- **Two do not move.** `v29c` (a volatile `char` local that is also LOADED, promoted later by
  `promoteVolatileScalarLocals`) is still silent. `v29` still declines at the backstop. So a second
  pre-pass leaves the same dead cone, and a truly total backstop has to ask whether the parameter's
  forward cone reaches anything but a Bennett-reversed dead computation, not whether it is `use_empty()`.
- Full lit on the prototype moves 5 fixtures: the 3 volatile-callee vsfp fixtures, the fenv accept
  `lowering_volatile_scalar_deadstore.ll` (whose dead product is now deleted), and
  `lowering_reject_volatile_scalar_deadstore_measured.ll`. That last one is a "DECLINE PIN" whose
  module becomes the coherent `alloc; Ry; measure`.
- This is an owner-level move, because it changes what the fenv stage deletes. It is recorded as
  evidence that the route exists, not as a recommendation to ship it unreviewed.

## Beads filed

- **bd `test_C_libtooling-a8q5`** (P1, discovered-from vsfp). It carries F-VB-1, F-VB-2 and the
  route evidence, with bd vsfp, bd 9bhg and bd qjoc cross-referenced. bd vsfp should stay OPEN, or
  close with a8q5 named as its residual. It must not close as "total".

## What I did NOT attack

- `dropDeadCallArguments` itself (the cone deletion, attributes, termination, taint-agnosticism) and
  the 29 re-spelled fixtures. Those belong to the concurrent round r1A.
- A statevector check. The probabilities above are analytic, per the owner's rule.
- `runOnFunction` (a dead shim, AXIS-F): its two slots were read, not exercised.
- `invoke`, C++, and multi-module link orders beyond `llvm-link caller lib`.
- Loop-resident phantom reads beyond `v10`/`v17`/`v18`, all of which decline earlier at the loop
  fence on every binary. A rolled form whose loop fence admits the shape was not constructed.
- The spec-QUANTUM hand-inlined twin's known "detector, not oracle" gap (hgwx notes). For example,
  `h(a, 0) = a*0` is folded away by the twin and computed by the clone. That class is older than vsfp
  and outside its scope.
- `+Asserts` and ASan builds.
- An independent full ctest. I ran lit, the 9 affected e2e entries, the mutation matrix, and the
  sweep.

## Artifacts

- `probes/src/`: every probe of this round (`v01`–`v30`, `qjoc`, `qjoc_tpl`, `w01`).
- The F-9C-1 and hgwx members were run from their original homes: 9bhg worktree
  `…/review_r2A_9bhg/probes/src/` and `…/d88e_probes/src/`, plus this worktree's
  `vsfp_probes/src/own/s3cT*`.
- `probes/tools/`: `h.sh`, `pairs.sh`, `mutrun.sh`, `proto.py`, `sweep.sh`. They carry this session's
  scratchpad paths.
- `probes/results/`: `fvb1_silent_members.txt`, `mutation_rerun.txt`, `proto_probes.txt`,
  `proto_lit.txt`, `circuits.txt`, `sweep.txt`.
