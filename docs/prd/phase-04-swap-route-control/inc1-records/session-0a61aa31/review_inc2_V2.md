# review_inc2_V2 — Rule-13 ROUND 1, lens V2 on Inc 2 (value arms by controlled-copy merge)

Agent `review_inc2_V2`, READ-ONLY, 2026-09-05.
SUBJECT = `$SP/wt/inc2` @ `8c526d9` (branch `3qlq-inc2`; binaries `build/ir-pass/{cq-opt,libCQPass.so}`
stamped 14:59:51, NEWER than every source file — verified, no stale-binary false green).
ORACLE  = `$SP/wt/pre-3qlq` @ `52d7764`.
All artifacts under `$SP/progress/review_inc2_V2/` (`bin/` instruments, `probe/`, `fixture/`,
`golden/`, `census/`).

Lens V2 scope: **V3 switch XOR-delta correctness · fixture truth + injection matrix · the two
regenerated goldens audited line by line · the six new slices + three `cmp` gates · the cswap census.**

---

## Verdict

**CLEAR ON THE MECHANISM — 0 silent miscompiles and 0 over-accepts found in V3, with an
independent basis-state witness the increment did not have. 6 findings, all
DOC-OR-FIXTURE-TRUTH; none blocks. F-V2-1, F-V2-3, F-V2-5 and F-V2-6 should be fixed before
the commit lands.**

I could not construct a wrong mux, a dirty free, a dropped arm, or a disposition widening in
the switch path, from plain C or from hand IR, in 950 fuzzed programs or in 14 targeted probes.
What I did find is that the *record* of the increment has drifted from what it ships: one whole
source-file header still documents the retired route in the present tense, one committed slice
header names a gate and a file that do not exist, the shipped stream leaks one dirty rail per
arm that the PRD's own target stream says is uncomputed, and the re-derived fixtures lost
contiguity so that two physically meaningful mutations now pass.

---

## What I ran (only what I ran)

| layer | command | result |
|---|---|---|
| lit (full) | `lit ir-pass/test` in the subject build | **1586 discovered · 1585 passed · 1 expectedly failed** |
| lit (ctest) | `ctest -R ir-pass-lit` | PASSED, 34.0 s |
| e2e value/switch | `ctest -j4 -R '^e2e-(slice-control-value\|value-.*-twin-identical\|slice-control-switch-value)'` | **11/11 passed** |
| goldens | full pipeline (`clang -O1` → `cq-opt` → `free_pairing_check.py` STRICT → link → run) on both binaries | reproduced byte-for-byte, see F-V2-8 |
| whole-corpus disposition | all 1586 fixtures lowered on BOTH binaries, rc + first control diagnostic diffed | **exactly 3 differences**, see F-V2-9 |
| injection matrix | 14 mutations × 8 accept fixtures × every prefix, clean control first | see F-V2-5 / F-V2-6 |
| basis-state simulation | my own instrument over the emitted gate list | 60 goldens parse, 0 dirty free after the model fix; every value/switch golden semantically correct |
| fuzz | 950 generated switch-value programs, 3 seeds | 928 accepted, **0 mismatch, 0 dirty free, 0 disposition drift** |

I did NOT run the full `ctest` (BRIEF_common anti-stall rule 4), `frontend-lit`, or the runtime entries.

---

## F-V2-1 — `SwitchValueEmit.cpp`'s file header still documents the RETIRED route, in the present tense
**Grade: DOC-OR-FIXTURE-TRUTH (the highest-value finding of this lens).**

`ir-pass/src/SwitchValueEmit.cpp` lines **1–30** are **byte-identical to `main`**:

```
$ diff <(git show main:ir-pass/src/SwitchValueEmit.cpp | sed -n '1,31p') \
       <(sed -n '1,31p' ir-pass/src/SwitchValueEmit.cpp)     # → no output
```

Every load-bearing sentence in it is now FALSE:
* ":12–14 mint f_i → |0> rail r_i → cswap route-in … replay the chain VERBATIM/UNCONTROLLED on
  r_i → cswap route-back" — no rail, no cswap, no replay is emitted.
* ":15–16 After all route-backs `p` holds the muxed answer" — `p` is never written.
* ":15 Then ONE uncontrolled `cqrt_copy_<W>(p, out)` copy-out … **after route-back, before any R†**"
  — the copy is now a **preload**, the FIRST gate of the region.
* ":16–19 the LIFO reverse-play (route-back† · body-chain adjoint · route-in†) … clean rail frees"
  — the emitter performs no reverse-play at all.
* ":24–30 THE §8.5 cswap-arg0 SEAM … The reverse-play hands the inverter the BODY CHAIN ONLY …
  and brackets the route cswaps itself via `emitRoute`, exactly as `emitValueRegion` does in
  `SwapRouteEmit.cpp`" — doubly false; `emitValueRegion` no longer does that either, and the
  `#include "SwapRouteEmit.h" // emitRoute` line was **deleted by this very commit**, so the
  header cites a primitive the TU no longer includes.

Two more sites in the same class:
* `ir-pass/src/SwitchValueEmit.cpp:89–91` — the `CaseStream` doc comment says "One content
  case's **routed** VALUE stream: … the ordered ORIGINAL chain links (… — **erased after
  rewire**)". Line **94**, two lines below, says "(HOISTED, **kept**)", and the emitter's own
  step 4 (:318–321) says "are NOT erased here". The struct's doc comment contradicts its own
  field comment.
* `ir-pass/include/SwitchRouteEmit.h:53–55` — "the N-way method-B (**route + verbatim chain
  replay + one copy-out + LIFO reverse-play** over the shared routed base `p`…)".

This is not cosmetic in this codebase: `CLAUDE.md`'s `fenv` paragraph records the exact failure
mode ("an agent-authored justification that hardened by repetition into a de-facto ruling"), and
the increment **deliberately** retired the equivalent prose in `SwapRouteEmit.h`,
`SwapRouteEmit.cpp` and `ControlPlan.h` in commit `8c526d9` — those three edits I read and they
are accurate. The switch half was simply missed.

**Fix:** rewrite `SwitchValueEmit.cpp:1–30`, `:89–91` and `SwitchRouteEmit.h:53–55` to the
preload + XOR-delta recipe (the `.ll` fixture header `control_swap_switch_value.ll:9–27` is
already a correct, well-written description — reuse it). **Pinning:** none possible (prose);
the reviewer note is the record.

---

## F-V2-2 — `slice_control_value_derived.c`'s header names a `cmp` gate and a twin file that do not exist
**Grade: DOC-OR-FIXTURE-TRUTH.**

`tests/e2e/slice_control_value_derived.c:3–5`: *"Subject of `e2e-value-derived-twin-identical`;
its twin is `slice_control_value_derived_twin.c`."* and `:12` *"This is the third twin pair"*.

Measured: `grep -rn 'e2e-value-derived-twin-identical\|slice_control_value_derived_twin' tests/
ir-pass/ docs/` returns **only those two lines of the header itself**. No ctest entry, no twin
`.c`, no twin golden. The third pair is `mixedops`. `tests/e2e/CMakeLists.txt:274–281` says the
**opposite** and is correct — and I verified its reason by writing the missing twin
(`$SP/progress/review_inc2_V2/probe/derived_twin.c`, `int t = R(p); p = (q>5)?t:p;` after a
pre-region `cq_phi`):

```
NEW    : DECLINE rc=1  cq controlled lowering: control flow under quantum control
ORACLE : DECLINE rc=1  cq controlled lowering: control flow under quantum control
```

So the CMakeLists rationale ("`SelectClassify` conservatively refuses a coherent Rz-lineage
select OPERAND while the `br`-value classifier deliberately ACCEPTS a derived base") is exactly
right, and the slice header contradicts it. A future reader takes the header at face value and
believes this slice is byte-identity-gated when nothing gates it.

**Fix:** replace `slice_control_value_derived.c:3–5` and `:12` with the CMakeLists rationale
(and the measured both-binaries decline above). **Pinning:** the CMakeLists comment already
carries the truth; keep them in one place.

---

## F-V2-3 — the shipped stream leaks ONE DIRTY rail per arm/case that the route did not, and PRD §3/§7.1 say it is uncomputed
**Grade: DOC-OR-FIXTURE-TRUTH (a real behavioural divergence from the PRD; NOT a miscompile).**

PRD §3: *"`t` uncomputed by `_unc` (a function of the unchanged `p`); strip `f`. … `t`, `f`
**freed clean**"*. PRD §7.1's target stream: *"6 ops on p → h9; alloc out; copy_controlled …;
**6 `_unc`**; strip; free f — 2 `copy_controlled_W` (2W Toffoli), **no work rail**"*.

Measured, `tests/e2e/slice_control_value_diamond.expected.log` (reproduced byte-for-byte on the
subject): the chain intermediate `h2` IS uncomputed and freed (lines 9–12), but the chain FINAL
`h3` — which holds `R(p)` — gets **no `_unc` and no `cqrt_free`**. Same shape in the switch:
`slice_control_switch_value.expected.log` uncomputes and frees each `add` intermediate (lines
9–10, 15–16) but leaves both deltas `h4`, `h7` allocated and dirty.

Quantified with the basis-state simulator (`bin/sim.py`, `bin/check.py`) — registers still
allocated when the program ends, and how many of them hold a non-|0> label:

| program | route (`git show main:…`) allocated / **DIRTY** | Inc 2 (HEAD) allocated / **DIRTY** |
|---|---|---|
| `slice_control_value_diamond` | 9 / **3** (q, p, out) | 4 / **4** (q, p, **R(p)**, out) |
| `slice_control_switch_value` | 5 / **3** | 5 / **5** (+ d₀, d₁) |
| 3-content-case switch (`probe/s_three`) | 6 / **3** | 6 / **6** (+ d₀, d₁, d₂) |
| multi-op switch (`probe/s_multiop`) | 11 / **3** | 5 / **5** |

The route returned **every** work/chain rail to |0⟩; Inc 2 returns the intermediates but leaves
the arm's ANSWER rail dirty. Total allocation goes down (the saving is real); the count of
permanently-dirty rails goes **up by one per arm/case**.

Two prose consequences:
* `ir-pass/src/SwapRouteEmit.cpp:437–438` — *"`p` and the chain's final rail are left ALLOCATED
  and entangled with `out` — keep-source-live, **exactly as the route left them**"*. The clause
  "exactly as the route left them" is FALSE for the chain's final rail (measured above). It is
  true for `p`.
* `$SP/progress/impl_inc2.md` AUDIT 1 summarises the replacement as *"6 chain ops on p with M-C
  in-place on the fresh rails **+ their spine `_unc`/free**"* — only ONE of the two fresh rails
  gets that pair.
* The e2e slice headers (`slice_control_value_ifelse.c`, `control_swap_switch_value.ll:29–33`)
  ARE honest about it. The inconsistency is between the honest fixtures and the PRD/source comment.

**Why it is not a miscompile, stated so the next reader does not have to re-derive it:** the
leaked rail is `R(p)` (or `d_i = R_i(p) ^ p`), a deterministic function of `p`, and `p` is
itself kept live and entangled with `out`. Writing `R(p)` into a fresh |0⟩ ancilla is a unitary
acting on (p, ancilla), so tracing the ancilla out leaves the reduced state on (q, p, out)
unchanged. Rule 6 explicitly permits leaving a non-|0⟩ rail allocated. `free_pairing_check.py`
STRICT is rc=0 on every slice and probe (I re-ran it), and my simulator reports **zero** dirty
frees anywhere in the Inc-2 stream.

**Why it still matters:** PRD §9 follow-on **3qlq.5 "freeing the value-arm SOURCE"** becomes
unsound by default under this stream. With `R(p)` / `d_i` retained, a later increment that frees
`p` performs a hidden measurement of a register those rails still record. Under the route that
follow-on was safe in isolation; it no longer is.

**Fix (one of):** (a) restate PRD §3/§7.1 and `SwapRouteEmit.cpp:438` to say the chain final /
delta is left allocated dirty, and add the 3qlq.5 precondition; or (b) actually discharge the
final (that is a spine change, not an Inc-2 change — it would also break the twin byte identity,
because the pre-hoisted select twin leaks identically, so it is not a fix that belongs here).
**I recommend (a).** **Pinning:** the numbers above; `bin/check.py` reproduces them.

---

## F-V2-4 — the `cqrt_cswap` census under-counts the survivors (the material claim is TRUE)
**Grade: DOC-OR-FIXTURE-TRUTH (small, but this project's own error class).**

`impl_inc2.md` step 8 / hand-back §4: *"ONE minter … and **FOUR call sites** after Inc 2:
`AbortParkEmit.cpp:381`, `NestedRouteEmit.cpp:162`, `SwitchRouteEmit.cpp:159` and `:172`."*

Measured (`grep -rn "emitRoute" ir-pass/src ir-pass/include`): **SEVEN** call sites in three files —
`NestedRouteEmit.cpp:162, 176, 178, 194` (**four**, not one: outer route-in, inner route-in,
inner route-BACK, outer route-BACK), `SwitchRouteEmit.cpp:159, :172`, `AbortParkEmit.cpp:381`.
Unrecorded fifth appearance path: `EmitInverse.cpp:261` RE-EMITS an existing `cqrt_cswap` under
the involution family (it never mints the declaration, but the symbol can reach output from there).

**The material claim is TRUE and I confirmed it independently, at the golden level rather than
by grep:** goldens containing `cqrt_cswap` went **5 at `main` → 3 at HEAD**
(`slice_control_abort`, `slice_control_nested_phase`, `slice_control_switch_phase`), and all
three are **byte-identical on both binaries and equal to their committed goldens** — so the two
surviving PHASE routes and the abort park are untouched by Inc 2:

```
slice_control_nested_phase: NEW == ORACLE (19 lines)  and == committed golden
slice_control_switch_phase: NEW == ORACLE (27 lines)  and == committed golden
slice_control_abort:        NEW == ORACLE ( 8 lines)  and == committed golden
```

Zero value-path `emitRoute` call sites remain — confirmed by reading both emitters.
The `value-arm swap-route` retired-string census in the hand-back is **exact**: 6 source sites
(`ArmClassify.cpp:3210,3254`, `ArmHomogeneity.cpp:185`, `SwitchArmProve.cpp:199,280,289`) and
**28** fixtures, both re-measured.

**Fix:** correct the count to "seven `emitRoute` call sites in three files" and add the
`EmitInverse` re-emission note.

---

## F-V2-5 — the re-derivation DROPPED the contiguity contract; a spurious mid-stream gate is now invisible
**Grade: DOC-OR-FIXTURE-TRUTH.**

Measured directive census, `main` → HEAD:

| fixture | main `CHECK:` / `CHECK-NEXT:` | HEAD |
|---|---|---|
| `control_swap_value_ifelse.ll` | 2 / **28** | **12 / 0** |
| `control_swap_value_diamond.ll` | 16 / 0 | 12 / 0 |
| `control_swap_value_diamond_polarity.ll` | 24 / 0 | 12 / 0 |
| `control_swap_switch_value.ll` | 25 / 0 | 20 / 0 |
| `lowering_uncompute_interior_leak_region_valuearm_chain.ll` | 5 / 15 | 4 / **22** (kept) |

All **seven** re-derived accepts now use bare `CHECK:` **exclusively — zero `CHECK-NEXT:`**.
`control_swap_value_ifelse.ll` is a strict regression in *kind*, not just count.

**Reproducer, measured.** Lower `control_swap_value_ifelse.ll` on the subject and insert one line
immediately before the first controlled copy:

```
  call void @cqrt_ry_i32(i32 0, double 1.000000e+00)
```

then re-run every prefix (`$SP/progress/review_inc2_V2/fixture/ifelse_mut.ll`):

```
CHECK: PASS (blind)   NOROUTE: PASS (blind)   FCNT: PASS (blind)   CCNT: PASS (blind)
```

The identical injection into the leak fixture — which KEPT `CHECK-NEXT` — is **CAUGHT by CHECK**.
Across the whole matrix the mutation `M11_stray_ry` is uncaught in **7 of 8** accepts
(`fixture/inject_matrix2.log`). `control_swap_switch_value.ll:3` says "**symbol ORDER is the
contract**"; with bare `CHECK:` an insertion between two pinned lines is not part of that contract.

**Fix:** convert the merge block of each accept (`icmp mint` → `alloc out` → `copy_controlled` →
`x` → `copy_controlled` → `x` → strip → free → measure) to `CHECK-NEXT:`; the streams are
straight-line and contiguous, so it costs nothing.
**Pinning:** the mutation above; the harness is `bin/inject2.py`.

---

## F-V2-6 — `control_swap_value_accept_div_const.ll` is blind to a DIRTY FLAG FREE
**Grade: DOC-OR-FIXTURE-TRUTH (the most physically meaningful fixture gap I found).**

The totality-fence accept discriminator carries only `CHECK` + `NOROUTE`. Measured, all three
mutations pass **every** prefix (`fixture/inject_matrix.log`):

| mutation | disposition |
|---|---|
| `M5` drop the chain `_unc` (`cq_template_mul_i32_hl_unc`) | *** NOT CAUGHT *** |
| `M7` drop the intermediate rail's `cqrt_free` | *** NOT CAUGHT *** |
| `M9` **drop the flag STRIP** (`cq_template_icmp_sgt_i32_hl_unc`) | *** NOT CAUGHT *** |

The fixture pins `CHECK: call void @cqrt_free(i32 %[[F]])` (line 42) but never pins the strip
that must precede it. The lowered stream is:

```
20:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)   <- unpinned
21:  call void @cqrt_free(i32 %h_cmp)                                        <- pinned
```

So a future build that freed the flag **without stripping it** — a dirty free, i.e. a hidden
measurement that collapses `q` (Rule 6) — keeps this fixture green.
Related, same matrix: `control_swap_value_accept_nonclobber.ll` has no `CCNT` prefix, so
`M10_dup_ccopy` (a duplicated merge copy — `out` XORed twice, the identity on that branch) also
passes; `control_swap_value_accept_div_const.ll` misses that too.

**Fix (3 lines):** in `control_swap_value_accept_div_const.ll`, between the second `cqrt_x` and
the free, add
`; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)`;
add an `FCNT-COUNT-2` / `FCNT-NOT` pair and a `CCNT-COUNT-2` / `CCNT-NOT` pair; add `CCNT` to
`control_swap_value_accept_nonclobber.ll`.
Also missing: the switch half of the totality fence has a DECLINE fixture but no ACCEPT
discriminator (`control_swap_switch_value_reject_speculation.ll` has no `..._accept_div_const`
twin), so on the switch side the fence is still indistinguishable from "decline every div".

**Everything else in the injection matrix is clean** — 14 mutations × 8 accepts, clean control
first (all prefixes PASS on the unmutated output for every file), and every other
construct-present cell is CAUGHT, most by two prefixes:
`M1 cswap`→NOROUTE · `M2 work-rail triple`→NOROUTE+FCNT · `M3 drop copy_controlled`→CHECK+CCNT ·
`M4 swap the two copies' sources`→CHECK · `M6 drop an x`→CHECK · `M8 drop the preload copy`→CHECK+PCNT ·
`M12 free before strip`→CHECK · `M13 copy_controlled dst:=src`→CHECK · `M14 out allocated non-zero`→CHECK.

---

## F-V2-7 — V3 (switch preload + XOR-delta): CLEAR, and here is what it took
**Grade: CLEAR.**

The correctness argument is `out = p ⊕ Σᵢ fᵢ·(Rᵢ(p) ⊕ p)` with the `fᵢ` mutually exclusive. I
attacked the three premises.

**Mutual exclusion is STRUCTURAL, not assumed.** `SwitchClassify.cpp:167–170` (G9) declines
≥2 case values targeting one successor **before** `R.SwitchArms` is built, and `:394–398`
pushes exactly ONE value per arm — so the emitter's two new asserts
(`Arm.Values.size() != 1`, the pairwise-distinct scan, `SwitchValueEmit.cpp:174`, `:202–205`)
are provably unreachable, which is exactly how their comments describe them. Both directions
measured:

| probe | NEW | ORACLE |
|---|---|---|
| grouped labels from C (`case 0: case 1:`) — `probe/s_grouped.c` | decline `control flow` | identical |
| two case values → ONE block, hand IR — `probe/h_sw_shared_block.ll` | decline | identical |

**Exhaustiveness / empty default.** Preload `out ^= p` runs first and unconditionally, so a
scrutinee matching no case leaves `out = p`. Verified by simulation over the whole scrutinee
range, not by inspection. A non-empty default carrying a chain declines on both binaries
(`probe/h_default_chain.ll`, `control flow`).

**The remaining shapes, all measured on BOTH binaries:**

| probe | result |
|---|---|
| passthrough case beside content cases (`case 1: break;`) | accepts, 23 lines (oracle 29); `out = p` on that branch — simulated OK |
| 3 content cases | accepts, 31 lines (oracle 40) — simulated OK |
| multi-op chains per case (M-C in place on the FRESH rails, never on `p`) | accepts, 35 (oracle 41) — simulated OK |
| identity chain `p = p + 0` (hand IR) | accepts, delta = 0, `out = p` — simulated OK |
| N = 1 content case | never reaches `emitSwitchValueRegion`: routed to the DIAMOND path on both binaries (two X-bracketed controlled copies) — simulated OK |
| widths i8 / i16 / i32 / i64 | all lower with a CONSISTENT width throughout (alloc/copy/copy_controlled/eq-flag/xor-delta) — all simulated OK |
| i32 scrutinee + i64 value | declines `value-arm swap-route` on BOTH |
| derived scrutinee `switch (q & 3)` | accepts, flags mint off the derived rail — simulated OK |
| derived base `p = r * 3` | accepts — simulated OK |
| scrutinee read as DATA after the switch | declines `condition data use neither escaped nor measured`, both |
| two sequential switches on one scrutinee | declines (same string), both |
| stray gate in a passthrough arm block | declines, both |
| switch value arm inside a classically-bounded loop | declines `control flow inside a loop body`, both |
| `out` dead / `out` returned | accept on both; no spine attempt to invert a controlled copy |

**The independent witness the increment does not have.** A value/switch region contains only
PERMUTATION gates (templates, copies, `x`, `addc`/`xorc`); `Ry`/`Rz` sit outside it. So
re-interpreting the flattened trace as a classical reversible circuit and checking every basis
input **is** a complete check of the region's unitary — and it is the only thing in reach that
witnesses "freed at |0⟩", which `CLAUDE.md` says the golden byte-diff structurally cannot.
I built `bin/sim.py` + `bin/check.py` + `bin/fuzz_switch.py` and ran:

* every shipped value/switch golden (subject AND the pre-Inc-2 `main` versions) over ~4 000
  basis inputs each: **all semantically correct, 0 dirty frees**;
* **950 randomly generated accepted-shape switch-value programs** (1–4 content cases, case
  values −3…11 incl. negatives, chains of 0–3 links over `add/sub/mul/xor/and/or/shl/lshr`,
  passthrough arms), seeds 7/11/23: **928 accepted, 22 declined, 0 semantic mismatch, 0 dirty
  free**; oracle accept/decline parity was checked on the 800 programs of seeds 11 and 23 (the
  parity check was added after the seed-7 batch) — **0 drift**;
* a sweep of all 301 committed e2e goldens: 60 are fully modellable, **0 dirty frees** after the
  inverse-`Ry` model fix. (`slice_loop_break` still flags; that is a model artifact of my
  "prepared value" rule for a non-zero alloc immediate, and it is one of the five
  `--allow-unproven` slices — not a finding.)

Recommend committing the instrument, or at minimum recording this measurement in the PRD: V3 is
the one accept shape in this increment with **no** byte-identity twin (F-V2-10).

---

## F-V2-8 — the two regenerated goldens, the six new slices, the three `cmp` gates: CLEAR
**Grade: CLEAR.**

**Regeneration reproduces, both directions.** On the SUBJECT, `slice_control_value_diamond`
(23 lines) and `slice_control_switch_value` (23 lines) are byte-identical to their committed
goldens; on the ORACLE both are byte-identical to `git show main:…` (28 and 29 lines). So the
goldens are what the two binaries actually emit, not hand edits.

**Line-by-line audit — `slice_control_value_diamond.expected.log`, 28 → 23.**
Unchanged, in place: the 4-line prologue (`alloc_i32(3)`, `ry`, `alloc_i32(7)`, `ry`) and the
final `cqrt_measure_i32(out)`. Deleted: old lines 5–27, the whole route block
(`icmp mint; alloc(0) rail; cswap; 6 out-of-place HL chain ops; cswap; alloc out;
cqrt_copy_i32(p,out); cswap; 6 `_unc`; cswap; free rail; strip; free flag`). Inserted: new lines
5–22 (`mul_hl(p,5)→h2; addc(h2,15); xorc(h2,9); mul_hl(h2,7)→h3; xorc; addc; mul_hl_unc; free h2;
addc(h3,7); xorc(h3,2); icmp mint; alloc out(0); copy_controlled(f,h3,out); x(f);
copy_controlled(f,p,out); x(f); strip; free f`). Two changes are **more than a route→merge
substitution** and should be stated as such rather than folded into it: (i) the chain's form
changed from all-out-of-place `_hl` templates to M-C **in-place** `cqrt_addc`/`cqrt_xorc` on the
fresh intermediates — a `lowerOps` consequence of hoisting the links as ordinary instructions,
and the reason the mixedops pair exists; (ii) the chain's FINAL rail stopped being uncomputed
(F-V2-3). Nothing else moved.

**Line-by-line audit — `slice_control_switch_value.expected.log`, 29 → 23.** Prologue and final
measure unchanged. The preload (`alloc out(0); cqrt_copy_i32(p,out)`) moves to the TOP of the
region (it used to be one uncontrolled copy-out AFTER both route-backs). Per case the route
quadruple (`alloc rail; cswap; add_hl; cswap` + its two reverse-play cswaps and `_unc`) is
replaced by `add_hl(p,k) → t; xor_i32(p,t) → d; add_hl_unc(t,p,k); free t; icmp_eq mint;
copy_i32_controlled(f,d,out)`. The two eq-flag mints and the two strips are unchanged in count,
order and arguments. No line mentioning `cqrt_cswap` survives, and **no `cqrt_x` appears at all**
(positive-polarity eq-flags), which the fixture's `NOROUTE-NOT: call void @cqrt_x(` pins.

**The three `cmp` twin gates are NON-CIRCULAR.** Two independent measurements:
1. The three twin `.c` files really are a different shape. `clang -O1`:
   subject = `2 phi i32` + `2 br i1`, **0 selects**; twin = **2 selects**, 0 phis — for all three
   pairs, and the two modules DIFFER. So the gate compares `emitValueRegion`'s hoist+select
   rewrite against `emitSelectRegion` reached through its own front door.
2. The **ORACLE** binary reproduces all three twin goldens byte-for-byte
   (`slice_control_value_{diamond,ifelse,mixedops}_twin`). The identity therefore says "the
   Inc-2 diamond stream equals a stream the PRE-Inc-2 compiler already emitted for the manually
   hoisted program" — the strongest available form, and not a self-comparison.

`ctest -j4 -R '^e2e-(slice-control-value|value-.*-twin-identical|slice-control-switch-value)'`:
**11/11 passed** (the 7 slices + the 3 `cmp` gates + the switch slice), 3.5 s.
`free_pairing_check.py` STRICT rc=0 on every golden and every probe I lowered.

The impl's FINDING S0-1 (the `?:` spelling is NOT a twin at this arm size) I re-measured and
confirm: subject and `?:` spellings compile to the same `-O1` module for the 6-op and if/else
shapes, so the pre-hoisted select is the only twin that exists. That was the right call.

---

## F-V2-9 — whole-corpus disposition sweep: exactly 3 changes, all of them Inc 2's own new fixtures
**Grade: CLEAR (positive evidence).**

I lowered **all 1586** lit fixtures on BOTH binaries and diffed exit code + first control
diagnostic (`bin/disp.sh`, `fixture/full_disp_delta.log`):

```
DIFF control_swap_value_reject_qq_cond.ll               ORACLE rc=1 (no template for opcode 'icmp i1'…)  NEW rc=1 control flow
DIFF control_swap_value_reject_speculation.ll           ORACLE rc=0 ACCEPTS                              NEW rc=1 value arm op that cannot run unconditionally
DIFF control_swap_switch_value_reject_speculation.ll    ORACLE rc=0 ACCEPTS                              NEW rc=1 value arm op that cannot run unconditionally
```

**Zero pre-existing fixtures changed disposition.** The two speculation cases are NARROWINGS
(always safe); the Q+Q one is a same-disposition move into the control dialect. Re-run over the
56-fixture value/switch family alone: the same three and nothing else.

> ⚠ My own measurement error, recorded because it is the class this project cares about: an
> earlier run of that 56-file subset printed **zero** differences. It was a **zsh** artifact —
> `$FILES` is not word-split by default, so `disp.sh` received one argument containing all 56
> newline-joined paths, `cq-opt` failed identically on both binaries, and the harness reported
> "no difference". Re-run under `bash` (and the 1586-file sweep, which used `xargs -P6 -n20`
> and so split correctly) it prints the three above. A green sweep that never ran the tool is
> exactly the "100% pass on a broken pass" trap `CLAUDE.md` warns about; the numbers I quote
> are the corrected ones.

Both new decline strings match their source
sites character-for-character (`SwapRouteEmit.cpp:357`, `SwitchValueEmit.cpp:163` →
`"cq controlled lowering: " + "value arm op that cannot run unconditionally" + " under quantum control"`),
and `CQ_CTRL_DBG=1` confirms the SWITCH fixture fires the SWITCH site (`%v0 = sdiv i32 %p, %n`
in the case block) and the diamond fixture the diamond site — the switch decline fixture is not
a duplicate of the diamond's.

---

## F-V2-10 — NOTE: V3 ships with no byte-identity witness of any kind
**Grade: NOTE (not a defect; a scope fact the record should carry).**

All three `cmp` gates are V1/V2 (diamond ↔ pre-hoisted select). The switch's preload +
XOR-delta stream has **no source-level spelling** — the uncontrolled `cqrt_copy_<W>(p, out)`
preload is not expressible in C, and the nested-`?:` alternative lowers to a different (4-copy,
X-bracketed) stream by design, because the switch exploits mutual exclusion to drop the
brackets. So a twin genuinely does not exist, and V3's verification at hand-back was: a
self-regenerated golden, a fixture whose CHECKs came from that same output, and an analytic
argument. That is a thinner floor than V1/V2's and is not stated anywhere. F-V2-7's simulation
is the substitute I could build; recommend the PRD record either it or the gap.

---

## F-V2-11 — inherited: one silent `continue` on a shape the comment itself calls "malformed"
**Grade: NOTE (pre-existing, unreachable at HEAD).**

`SwitchValueEmit.cpp:133–134`: `if (!Arm.Block || Arm.Values.empty()) continue;  // straight-to-
merge / malformed — no chain to route.` Every neighbouring off-pattern check in the same loop
bails **loudly** (`bailLoud`), with the comment "never a silent skip". If `Values` were ever
empty for an arm carrying a chain, that arm's value would be dropped and `out` would be `p` on
that branch — a verify-clean wrong mux. It is UNREACHABLE at HEAD (`SwitchClassify.cpp:394–398`
pushes exactly one value and skips null blocks), and the line is **byte-identical to `main`**, so
Inc 2 neither introduced nor widened it. Worth splitting into `!Arm.Block → continue` /
`Values.empty() → bailLoud(R)` when the file header is rewritten (F-V2-1).

---

## Not findings (checked, clean)

* `cqrt_copy_<W>_controlled` is minted by the existing `ControlledSymbols::copyControlledFn`;
  `git diff --stat main..HEAD` touches neither `tools/opcode_table.yaml` nor `runtime/` — **no new
  frozen symbol**, epic decision D3 respected.
* The flag strip reads a PRISTINE scrutinee in every V3 shape: the chains write fresh rails, the
  copies write `out`, and `p ≠ q` is the C2 anchor — I could not construct an in-place gate on
  `q`'s rail between mint and strip (M-C refuses in place wherever a later read exists, and each
  case's own `xor` delta IS a later read of `p`).
* M-C never converts a chain link in place on `p`'s rail in any probe: measured in the diamond,
  ifelse, mixedops and multi-op switch goldens (`mul_hl(h1,·) → fresh` every time).
* The `NOROUTE` / `FCNT` / `CCNT` / `PCNT` prefixes are pure-negative or `COUNT`+`NOT` pairs —
  no windowing bug (the drbq Inc-4 F-R1 class). `NOCHAIN` in the leak fixture IS windowed and
  says so deliberately.
* `ControlPlan.h` and `SwapRouteEmit.h`'s prose retirements (commit `8c526d9`) are accurate; I
  read both diffs against the shipped behaviour.
* The `value-arm swap-route` retired-string census (6 source sites, 28 fixtures) is exact.

---

## Verdict line

**CLEAR ON THE MECHANISM (V3 XOR-delta, the goldens, the twin gates and the census all hold up
under 950 fuzzed programs, 14 targeted probes, a 14×8 injection matrix, a whole-corpus
disposition sweep and an independent basis-state simulation) — with SIX DOC-OR-FIXTURE-TRUTH
findings, of which F-V2-1 (a whole file header documenting the retired route in the present
tense), F-V2-3 (a dirty rail per arm that the PRD says is uncomputed, and its consequence for
follow-on 3qlq.5), F-V2-5 (contiguity dropped: a spurious mid-stream gate now passes the ifelse
fixture) and F-V2-6 (a dropped flag STRIP passes the div-const fixture) should be fixed before
the commit lands. ZERO confirmed miscompiles, ZERO over-accepts, ZERO unintended disposition
changes across all 1586 fixtures.**
