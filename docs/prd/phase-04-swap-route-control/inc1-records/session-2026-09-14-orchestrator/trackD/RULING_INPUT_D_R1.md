# Track D — measurements for the owner's F-D1-1 ruling (bd `3d8q`)

**Status: the F-D1-1 self-exemption narrowing is HELD, not landed** (coordinator, 2026-09-14). It is
implemented and measured — the patch is `trackD/HELD_F-D1-1.patch`, the binary that carries it is
`33af613009b823e8…` — and it is **not** in the branch tip. Everything below is a measurement or an
analytic statement labelled as one; no opinion is offered as a result.

Binaries, all verified by `shasum -a 256` before use:

| tag | `cq-opt` sha256 (16) | what it is |
|---|---|---|
| **O** | `f7b65d8ccd7bc472` | the frozen session ORACLE (`/Users/sorenwilkening/Desktop/CQ_lang/build`), pre-increment |
| **P** | `7fe2bcbfb6c97126` | the reviewed branch tip `e7d6efe2` — the increment WITHOUT the F-D1-1 fix |
| **S** | `33af613009b823e8` | P + the held F-D1-1 narrowing (this is the binary being ruled on) |

Harness: `trackD/fix_r1_probes/m3.sh` — stage 1 generated ONCE per probe and fed to all three
binaries, every `.ll` checked non-zero before it is measured (a 0-byte module ACCEPTS via the
passthrough early-out).

---

## (a) Is the emitted circuit for the r5 shape valid, and is it UNIQUE?

### The program

```c
int q = cq_theta(0, 0.3);
int s = 0;
for (int i = 0; i < 3; i++) { int b = cq_theta(q, 0.1); s += cq_measure(b); }
```

### What the pass emits — MEASURED (`P/r5_inloop_invariant_seed.trace`, 8 lines)

```
cqrt_alloc_i32(0) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)     ; 0.3 — the seed
cqrt_ry_i32(h0, 0x1.999999999999ap-4)     ; 0.1 — trip 1
cqrt_measure_i32(h0) -> 0
cqrt_ry_i32(h0, 0x1.999999999999ap-4)     ; 0.1 — trip 2, on the COLLAPSED rail
cqrt_measure_i32(h0) -> 0
cqrt_ry_i32(h0, 0x1.999999999999ap-4)     ; 0.1 — trip 3
cqrt_measure_i32(h0) -> 0
```

**Physically** (analytic, `Ry(θ)|0> = cos(θ/2)|0> + sin(θ/2)|1>`; no simulator, Rule 2): ONE qubit.
Trip 1 measures `Ry(.4)|0>` and COLLAPSES it. Trip 2 applies `Ry(.1)` to the collapsed BASIS state and
measures. Trip 3 likewise. **This is a valid, realizable circuit.** The answer to *"can it lead to a
valid quantum circuit"* is **yes**.

### It is NOT unique — and the second reading is MEASURED, not hypothesised

The same source with the mint moved into the body — `for (…) { int q = cq_theta(0,0.3); int b =
cq_theta(q,0.1); s += cq_measure(b); }` (`r5f_inbody_fresh_mint.c`) — **compiles today on all three
binaries** and emits (`S/r5f_inbody_fresh_mint.trace`, 12 lines):

```
cqrt_alloc_i32(0) -> h0 ; cqrt_ry_i32(h0, 0.3) ; cqrt_ry_i32(h0, 0.1) ; cqrt_measure_i32(h0) -> 0
cqrt_alloc_i32(0) -> h1 ; cqrt_ry_i32(h1, 0.3) ; cqrt_ry_i32(h1, 0.1) ; cqrt_measure_i32(h1) -> 0
cqrt_alloc_i32(0) -> h2 ; cqrt_ry_i32(h2, 0.3) ; cqrt_ry_i32(h2, 0.1) ; cqrt_measure_i32(h2) -> 0
```

Three independent rails; three i.i.d. samples of `Ry(.4)|0>`. **Also valid, also realizable, and a
DIFFERENT distribution.**

### ⚠ The "fresh from `q` each trip" reading does NOT require cloning

This is the argument that looks decisive and is not. `q`'s state is `Ry(.3)|0>` — a **known
preparation from `|0>`**, not an unknown state — so producing it again is **re-preparation**, which
no-cloning does not forbid (Rule 8 forbids duplicating an *unknown* state). Every rail in this
compiler has a fully known provenance (`cqrt_alloc_<W>(seed)` plus a recorded gate list), so the
re-preparation reading is *always* realizable here. `r5f` is the measured proof that this compiler
already emits it when the source asks unambiguously.

**Conclusion for (a): the emitted circuit is valid; it is one of TWO realizable circuits the source
text admits; nothing in the source picks between them; the compiler picks the aliasing one silently.**

### The third measured fact: the stream is byte-identical to a different program

```
diff P/r5_inloop_invariant_seed.trace P/r5t_selfassign_twin.trace   →  no output
```
where `r5t` is `for (…) { q = cq_theta(q,0.1); s += cq_measure(q); }` — the self-assigned chain, a
DIFFERENT, well-formed program that also compiles. Two source programs, one circuit, `opt` exit 0.

---

## (b) Does the same argument apply to bd `3d8q`'s ORIGINAL non-loop case?

### The program and its stream (measured; `probes/src/f1_two_siblings_nocontrol.c`, 6 lines on O)

```c
int q = cq_theta(0,.3); int b = cq_theta(q,.5); int c = cq_theta(q,.9);
return cq_measure(b) + cq_measure(c);
```
```
alloc h0 ; ry(h0,.3) ; ry(h0,.5) ; ry(h0,.9) ; measure h0 ; measure h0
```

**This is also a valid circuit**, and it also admits a second realizable reading: prepare `Ry(.3)|0>`
on TWO rails (re-preparation, again not cloning), `Ry(.5)` on one and `Ry(.9)` on the other, measure
both. So **yes — the argument in (a) applies verbatim to the original.** The "valid circuit" test does
not separate them.

### The distinction the coordinator proposes IS real, but it is about VISIBILITY, not validity

State it precisely, in the two readings that exist:

| reading | what a name means | original (`f1`) | r5 |
|---|---|---|---|
| **ALIAS** (what the pass implements: `lowerRotations` RAUWs every chain member onto ONE handle) | a name is a handle to the register; `cq_theta` rotates in place and returns the same register | the emitted stream is exactly right | the emitted stream is exactly right |
| **RE-PREPARATION** (what a C reader may assume: a new name is a new value computed from `q`) | a read of a consumed name re-prepares that state on a fresh rail | wants 2 rails | wants 3 rails (= `r5f`'s stream) |

Both readings are realizable in BOTH programs, and the compiler emits the ALIAS one in both. So the
ambiguity is the SAME ambiguity — *"is a second read of a consumed name an alias or a
re-preparation?"* — and it is not resolved by the source in either case.

**What the immediacy of the measurement does change** is whether the discrepancy is visible in the
trace:

* **`f1` (within-region):** the trace shows `measure` firing AFTER `ry(.9)`, while the source attaches
  that measurement to `b`. The mismatch is on one line of the trace and an author can see it.
* **`r5` (across-trip):** within each trip the read is immediate and every line of the trace is
  locally consistent. The discrepancy exists only in what the loop-INVARIANT name `q` denotes on trip
  ≥ 2, and **no single line of the trace exhibits it**.

⚠ If that distinction is used to draw the accept/decline line, note which way it points: the r5 shape
is the one whose alternative reading is **invisible in the only artifact this project can inspect**
(the golden trace — Rule 2; there is no simulator). An ambiguity that a trace review cannot catch is
the one that most needs a diagnostic, not the least.

---

## (c) What does the user lose either way? — both answers are MEASURED

### If r5 DECLINES — the cost is a two-token edit, and BOTH intents already compile

| intent | source | verdict | stream |
|---|---|---|---|
| alias / in-place ("keep rotating the register") | `for(…){ q = cq_theta(q,0.1); s += cq_measure(q); }` (`r5t`) | **A on O/P/S**, 8 lines | one rail, chained |
| re-preparation ("sample a fresh `Ry(.4)\|0>` each trip") | `for(…){ int q = cq_theta(0,0.3); int b = cq_theta(q,0.1); s += cq_measure(b); }` (`r5f`) | **A on O/P/S**, 12 lines | three rails |

Neither spelling declines on any binary, on either side of this ruling. The decline's cost is
therefore: the author must say which of the two circuits they meant, and the diagnostic is
source-located on the reader (`!dbg`, IMPL_D §7b — measured `file:line:col`, no `<unknown>:0:0`).

### If r5 COMPILES — name the program someone writes believing something else

The i.i.d.-sampling idiom, which is what a loop around a prepared state normally means:

```c
int q = cq_theta(0, 0.3);                    /* prepare once                  */
for (int i = 0; i < N; i++) {                /* sample Ry(.1)·q, N times      */
    int b = cq_theta(q, 0.1);
    s += cq_measure(b);
}
```

Intended (the `r5f` circuit): N independent samples of `Ry(.4)|0>`, each `P(1) = sin²(0.2) ≈ 0.0395`.
Emitted (measured, the `r5t` circuit): trip 1 samples `Ry(.4)|0>`; **trips 2…N sample `Ry(.1)` applied
to the previous trip's COLLAPSED outcome** — analytically `P(1 | prev=0) = sin²(0.05) ≈ 0.0025` and
`P(1 | prev=1) = cos²(0.05) ≈ 0.9975`. The samples are not i.i.d.; they are a near-perfectly
correlated chain locked onto the first outcome. **No diagnostic, and — per (b) — no line of the trace
shows it.**

---

## (d) The partition of the population — MEASURED, and it is 14–0

Classification of the 14 members bd `3d8q`'s brief names, by whether the staling gate lies within ONE
dynamic activation of the read (the `f1`/3d8q kind) or only across trips with each read immediate (the
r5 kind):

| kind | members | count |
|---|---|---|
| **3d8q kind** — stale within a straight-line region (sibling `cq_theta`, or a mid-chain read) | `f1`, `f1w`, `g1`, `g2`, `f2`, `e6`, `S03`, `S04`, `G8`, `p3d8q_sibling`, `r15_p3d8q_sibling`, `p3d8q_sibling_rail`, the round-2 window shape, and **`l1_inloop_sibling_invariant`** — which is *in* a loop but carries TWO siblings in the body, so it is stale WITHIN the trip | **14** |
| **r5 kind** — one reader, loop-invariant seed, read immediate | none | **0** |

The r5 kind is exactly `{r5, r5a, r5b, r5d, r5h}` — five probes, built by the round-1 reviewer and by
this agent. **It appears in no fixture, in no shipped `e2e` slice, and in no member of the
population.**

### The measured consequence for the ruling

| | all 14 reproducers | the r5 family | shipped in-loop / exclusive-arm fixtures |
|---|---|---|---|
| **P** (no F-D1-1 fix) | **all 14 DECLINE** | `r5`,`r5a`,`r5b`,`r5d`,`r5h` ACCEPT; `r5c`,`r5e` DECLINE | unchanged from O |
| **S** (with the fix) | all 14 DECLINE (identical strings) | `r5`,`r5a`,`r5b`,`r5d`,`r5h` DECLINE; `r5c`,`r5e` DECLINE | see `GATES.md` for the lit figure on `33af6130` |

**Ruling r5 ACCEPT costs this increment nothing**: the branch tip as reviewed already moves all 14 and
already declines `l1`. The two rulings differ by the r5 family **and by nothing else in the measured
population.**

### ⚠ Two facts the ACCEPT side should be told before it is chosen

1. **The `1 → 2` discontinuity already exists and is not introduced by the fix.** `r5c` — the same
   loop with a SECOND `cq_theta` on the same invariant seed — **declines on P today**, as does `r5e`
   (the same seed read by two successive loops). So an ACCEPT ruling for r5 leaves this line: *one*
   reader of a loop-invariant quantum name compiles, *two* readers of the same name decline. That is
   defensible (two readers is the within-region ambiguity of (b)) but it is a line a user crosses by
   adding one statement, and it should be a ruling rather than an artifact.
2. **"Valid circuit" does not distinguish r5 from the 14.** Per (b), every one of the 14 also emits a
   valid, realizable circuit; the defect claim in all 14 is *"a different, well-formed program emits
   the same stream"*, never *"the stream is unrealizable"*. So a ruling that r5 must compile **because
   its circuit is valid** applies unchanged to the other 14 and retires bd `3d8q` in full. A ruling
   that r5 must compile for a **different** reason needs that reason stated — the only structural
   differences this agent can measure are (i) read immediacy and (ii) across-trip vs within-region,
   and per (b) the first of those points toward declining, not accepting.

---

## What is held, and how to land either ruling

* **DECLINE ruling:** apply `trackD/HELD_F-D1-1.patch` (3 files: the `gateIsHarmless` export in
  `WireWalk.{h,cpp}`, the conditional `Self.insert` in `OpcodeLowering.cpp`) and restore
  `ir-pass/test/lowering_reject_stale_reader_inloop_invariant_seed.ll` from the same patch. Both were
  measured green (`lit --filter 'stale_reader'`: 11/11 PASS on `33af6130`).
* **ACCEPT ruling:** nothing to do — the branch tip already accepts r5. File the r5 family as the
  written, measured boundary of the fence (this document is that record), and take the `1 → 2`
  discontinuity of point 1 above as a second ruling.

The ACCEPT fixture `ir-pass/test/lowering_stale_reader_inloop_selfassign_accept.ll` is landed either
way: it accepts on **P and S alike** and pins the φ-carried in-loop chain, which no fixture pinned
before.
