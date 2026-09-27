# Rule-13 round r3A: bd vsfp round 3, `resolvePhantomCloneArgReads` + `userProgramReads`

**Subject:** `671390fe` (branch `worktree-agent-abf65d7dcfbff38c8`), `build/ir-pass/cq-opt` sha256 `3cb890ef25187b4b`.
**Oracle:** main `aee8f4f8`, `frozen/cq-opt.main_aee8` sha256 `69250feaf68bbe49`. The bd vsfp round-1 (`v5`) and round-2 (`r2g`)
binaries under `scratchpad/vsfp/bin/` were used only to date a finding.
**Scope:** `resolvePhantomCloneArgReads` (neutralise, then decline) and its reader predicate `userProgramReads`. A second
reviewer has `declineStaleTaintSet`, the per-stage re-propagation and the global-fold arm.
**Method:** I wrote C and IR programs against the specific claims and compared each against its hand-inlined twin
(trace identity plus the stage-2b STRICT CENSUS). Where a round mattered I also ran the oracle and rounds 1/2.
Per the owner's efficiency request I ran no corpus sweep, no allocator sweep and no mutation matrix, and I built no
private binary.
Everything is in `probes/`: `src/` holds the programs and the edited `*b.ll` IR-only inputs, `tools/` holds the
harness (its scripts carry scratchpad absolute paths), and `results/results.txt` holds every row quoted below.

## Verdict: **NOT-CLEAR**

Findings: one P1 introduced by round 3 (a crash), two P2s, one P1 that already exists on the oracle but that round 3
feeds more programs into, and two P3 notes. Every introduced finding is IR-only today. Two C routes to the
neutralisation that I tried beyond round 3's are both closed by the slot-B drop (`t1`, `t2` below). That supports
round 3's "IR-only" claim for the phantom route; it does not prove it.

| id | sev | introduced? | one line |
|---|---|---|---|
| F-XA-1 | **P1 (crash)** | **INTRODUCED, round 3** | fp-ABI clone slot neutralised with a constant of the caller operand's **fp** type while the clone parameter is `i32`, so the verifier aborts (exit 134). The oracle compiles all four spellings trace-identical to the twin. bd `test_C_libtooling-f061` |
| F-XA-2 | P2 | INTRODUCED, round 3 (the record dates from round 2) | `SpecDeadArgMask` is not exact for the *built* clone: `lowerOps` still lowers a dead-by-liveness op on a recorded-dead parameter, so the neutralised `0` is read as **runtime handle h0**, a register the caller never passed (at the wrong width when h0 is `_Bool`). Net unitary unchanged (Bennett-bracketed), so the stream is TRACE-DIFF, not a wrong unitary. bd `test_C_libtooling-sqjq` |
| F-XA-3 | P2 | vsfp branch (rounds 1–3); oracle correct | the over-decline round 3 named as "not constructed", now constructed: a 4.4 `%out` whose only other reader is a later 4.4 select's controlled copy counts as "unread". The oracle is TRACE-IDENT with the twin. bd `test_C_libtooling-xh17` |
| F-XA-4 | P1 (warned) | **PRE-EXISTING** (oracle identical); **round 3 adds a C customer** | a clone call placed between a derived chain and that chain's kickback consumer leaves the chain's template rails dirty across a later Ry. The hand-inlined twin discharges them. C-reachable. bd `test_C_libtooling-rhk5` |
| F-XA-5 | P3 | pre-existing (bd `jr8q`) | "CENSUS dirty-rail parity" cannot be read literally for the IR-only branch forms: the checker counts the clone call's classical result as a dirty template rail (+1 on every branch row) |
| F-XA-6 | P3 | pre-existing, safe direction | the slot runs after `lowerLoops`, so the loop layer still sees the phantom read: `l2b.ll` declines `loop-carried tainted value crosses iterations` (oracle too) where the twin, and the C form, compile TRACE-IDENT |

---

### F-XA-1 (P1, crash, INTRODUCED by round 3): the fp-ABI neutralisation is typed from the caller operand

`Specialization.cpp`, `resolvePhantomCloneArgReads` step 1:

```cpp
CB->setArgOperand(A, Constant::getNullValue(Op->getType()));
```

After `retargetSite`, a tainted fp slot of an fp-ABI clone is an **`i32` handle** parameter. The caller's operand is
still the stock `float`/`double`/`x86_fp80` value at this point, because `lowerRotations` and `lowerOps` RAUW it to
the handle later. A constant is never RAUW'd, so the call stays ill-typed and the in-process verifier aborts:

```
Call parameter type does not match function signature!
float 0.000000e+00
 i32  %8 = tail call i32 @__cq_q_hd_01(float noundef 0.000000e+00, i32 noundef %5) #4
LLVM ERROR: Broken module found, compilation aborted!        (exit 134)
```

Measured at every fp width (`results.txt`, F-XA-1 block):

| probe | shape | SUBJECT | ORACLE (vs hand-inlined twin) |
|---|---|---|---|
| `fpfloatb.ll` | `float x = cq_theta(..); r = hd(x, m);`, `hd` branch-reads `a` | **rc 134** | TRACE-IDENT (4 lines) |
| `f1b.ll` | `double`, operand `y = x*2.0`, later measured | **rc 134** | TRACE-IDENT (8 lines) |
| `fplongdb.ll` | `long double` (x86_fp80) | **rc 134** | TRACE-IDENT (4 lines) |
| `f2b.ll` | fp result + fp dead slot (`__cq_q_hf_11`) | **rc 134** | accepts |

Rounds: round 2 (`r2g`) accepts `f1b`, round 1 (`v5`) declines, so the crash is round 3's. The operand in
`fpfloatb` is a `cq_theta` result. That operand is exempt from the decline but still neutralised, so the exemption
does not protect it. The C forms drop at slot B and are TRACE-IDENT, so this is IR-only, but it is an abort on
well-formed input. **No fixture covers it:** T1's 14 killers are all `i32`, which is why the type mismatch was
invisible. Fix direction: take the null from the callee's parameter type
(`Callee->getFunctionType()->getParamType(A)`), and add an fp red-green pair.

### F-XA-2 (P2, INTRODUCED): the record is not exact for the built clone, so the constant IS observable

The record claim this falsifies, from TRACK_VSFP §R3.3: *"Soundness rests on the record: the clone never reads the
slot (r2B verified the record and that no later clone pass adds a read), so the constant is unobservable."*

`buildClone` takes `SpecDeadArgMask[Clone] = deadParamMask(*Clone)` after `lowerCloneControl` and before `lowerOps`.
A tainted instruction that is **dead under liveness** at that point does not keep the parameter live. The clone's
`lowerOps` still lowers it (template, then the wrap's `_unc`, then `cqrt_free`), and that lowered instruction
**reads the parameter**. After neutralisation the parameter is `0`, so the clone operates on runtime handle
**h0**, the first register the process allocated. Two independent routes produce the dead instruction:

1. **The clone's own flatten deletes the branch-only compare but not its operand chain.** In `a2_chain.ll` the
   callee is `h(a,k){ t = a*3; if (t > 3) {} return k+1; }`. The clone emits `cq_template_mul_i32_hl(h0, 3)`; the
   oracle emits `(h1, 3)`, the register actually passed. The same happens under `-g` (`g1c.ll`), so debug records
   play no part: in LLVM 19 they are not `Use`s.
2. **The implementer's own named attack: a clone whose dead slot feeds an inner clone call.** `n5_nested.ll`:
   `h(a,k){ return g(a+1,k); }`, where `g` branch-reads `a`. The inner record kills `a+1`, and the outer record then
   kills `a`. The outer clone emits `cq_template_add_i32_hl(h0, 1)`; the oracle emits `(h2, 1)`. TRACE-DIFF vs the
   twin.

With h0 a `_Bool` register (`a3_width.ll`), the clone applies `cq_template_mul_i32_hl` to a **1-qubit handle**, a
32-bit template on a register of the wrong width. `a1_{deadop,icmp,add,sext,xorself}.ll` show the mechanism is not
opcode-specific.

**Why P2 and not P1.** In all 8 spellings the stray op is compute/uncompute inside the clone's Bennett wrap (LIFO),
so the net unitary equals the twin's. A clone body cannot contain a `cq_*` call (WI-1.5), which rules out an
un-reversed non-diagonal gate between the compute and the uncompute. I did not construct a non-identity instance.
What is wrong is the emitted circuit itself: it addresses a register, and a width, that the call never supplied.
That is not what the source says, and it is not the oracle's stream.

Fix direction: make the record exact by construction. Either delete the clone's dead non-root instructions, by the
same `FunctionLiveness`, before taking the mask, or take the mask after `lowerOps`. After `lowerOps` only
parameters that some emitted instruction actually reads would be live, and a dead op would already be gone.
Correct the §R3.3 sentence at the source (L7-with-a-twist).

### F-XA-3 (P2): `userProgramReads`' emitter-rail rule, the named over-decline, constructed

`e2b.ll` has registers `b` and `b2` (`_Bool`) and `x`. It computes `r = b ? x : 7; t = h(r, m)` (a branch-read)
and `s = b2 ? r : 3`, then returns `t + cq_measure(s)`. `r`'s `%out` is read in the **source slot** of the second
select's `cqrt_copy_i32_controlled(f2, %out, %out2)`, but every runtime call on an emitter rail is skipped as
construction. So `%out` counts as unread, and the module declines `quantum argument to a parameter the lifted
callee never reads`. The oracle accepts it **TRACE-IDENT with the twin (27 lines)**; rounds 1, 2 and 3 all decline;
the C spelling drops at slot B and is TRACE-IDENT. Round 3 named this with a compare reader and recorded it as "not
constructed". The data-copy reader here is the same rule.

Fix direction: an emitter's own traffic is exactly the **destination** operand, the last slot of
`cqrt_copy_<W>[_controlled]`. `free_pairing_check.py`'s `classify()` already encodes these read/write effects.
Anything else is a read.

**The opposite list error (item 3's over-accept direction) I could not construct**, and I argue it closed. An
emitter call exists only because the user wrote the region, so the twin has the same read. A region whose only
consumer is the phantom has its own `%out` in `Done`, and that `%out` then declines, as `e2b`'s mirror
`spec_reject_phantom_arg_read_unread_select.ll` pins. The ancestor of a `Done` operand that is read only through
it stays read as long as the operand is read. I tried: a value whose only other use is a controlled copy into a
phantom-only `%out` (declined via the `%out`); two phantom operands in one call (declined); and a chain `x → add →
phantom` (declined).

### F-XA-4 (P1, warned, PRE-EXISTING; round 3 adds a customer)

This finding sits outside the diff, but I found it while doing item 1's "clone built twice" (`d1b`) and minimised it
to plain C with no phantom at all (`d4.c`):

```c
// lib: int h(int a, int k) { return k + 1; }
q = cq_theta(m&7,.5); p = q*3; u = p^q; s = h(m, q); if (u == 10) cq_phi(PI);
ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);
```

The oracle and the subject both accept it with `warning: … non-diagonal gate over a live derived record`, and both
emit **no** `xor_unc` and **no** `mul_unc`. h1 = 3q and h2 = 3q⊕q stay allocated and entangled across
`cqrt_ry_i32(h0, 0.7)` (Rule 8). The twin (`d4T.c`, `s = q + 1`) uncomputes and frees both, with no warning and
census dirty 0. The trigger is the call's position: `d5.c` puts the same call after the kickback and is clean on
both binaries. `d3` vs `d4` shows that measuring `s` before or after the Ry does not matter.

The lyyf policy (B) premise does not cover this: *"NOT liftable by any uncompute"* is false here, because the twin
lifts both rails. Hand-inlining a pure callee changes the circuit.

**Population:** `d2.c` is the same program with lib `if (a > 3) (void)K;`. It **declines** on the oracle, round 1
and round 2, and **accepts into this defect** on round 3, through the global fold's arm fold (bd `stl3`).
"Pre-existing" is true of the defect and false of its population.

### F-XA-5 (P3): the census artefact on branch forms

Every IR-only `*_branch.ll` row shows `tpl +1, dirty +1` against its twin (`results.txt`, item-4 table).
`free_pairing_check.py`'s internals show the extra "mint" is the clone call `%7 = __cq_q_h_01(…)`, a **classical**
result. This is bd `jr8q`'s by-name classification. Round 3's "0 dirty template rails" claim is stated for the C
forms, and there it holds (verified). A future reader should not take the branch rows' `dirty=1` as a leak.

### F-XA-6 (P3, pre-existing, safe direction): the phantom read is still visible to the loop layer

`l2.c` has `p = q*i` in a loop, with `h(p, …)` and `if (p == 6) cq_phi`. The C form is TRACE-IDENT with the twin
(24 lines). The branch form `l2b.ll` declines `loop-carried tainted value crosses iterations` on both the subject
and the oracle, while the twin accepts. The neutralisation runs after `lowerLoops`, so "from here on no stage can
see the read" is true only from here on. The loop layer saw it and declined, which is the safe direction. IR-only.

---

## Attack-list coverage

**1. Slot-rewrite correctness.**
- *Clone built twice:* `d1b.ll` (three sites, masks `01`, `11`, `01`) neutralises the right slot at every site:
  `__cq_q_h_01(0,…)`, `__cq_q_h_11(0, %h)`. Its trace divergence is F-XA-4 and is identical on the oracle and in the
  C form. The record is keyed per clone `Function`, and the `(callee, mask)` cache gives a cache hit the same body,
  so the record is the same too.
- *Nested clone call:* F-XA-2 (`n5`). Inner calls inside clone bodies are correctly not neutralised; they receive
  the outer parameter, which is 0.
- *fp-ABI:* F-XA-1.
- *`_unc` twins:* argued only. Twins carry no `SpecDeadArgMask` entry, so they are never neutralised, and their
  bodies are skipped through `SpecHandleArgMask`. The spine mints module-level twin calls after the slot, from the
  already-neutralised operands, and the twin body is the same body, so it behaves as F-XA-2 predicts.
- *`cq_theta` result later measured:* `wboolb.ll` (`_Bool`) is TRACE-IDENT. At fp widths it hits F-XA-1.
- *`-g`:* `g1b` is TRACE-IDENT, and `g1c` reproduces F-XA-2.
- *variadic / `byval`:* NOT attacked.

**2. Running after all guards.**
- `s1b.ll` puts the phantom read of a derived record after a Ry on its source. It is TRACE-IDENT with the twin,
  whereas the oracle leaves 2 dirty rails and warns. This is the case the fix was built for, and it holds.
- `c1`/`c2` (phantom on one classical arm, reader elsewhere) decline on every binary for earlier, unrelated
  reasons: the clone result is conservatively tainted and gets muxed by a classical φ. Pre-existing; not pursued.
- Loop: F-XA-6.
- I found no case where the rewrite creates a shape an earlier fence would have refused. Everything the rewrite
  orphans is in `Done`, and it is either still read or declined.

**3. `userProgramReads`.** F-XA-3 (over-decline) constructed. The over-accept direction was argued closed, with
three constructions tried.

**4. Twin identity (trace + STRICT CENSUS).** All TRACE-IDENT:
- Round-3 C forms `k2`, `k5`, `k7`, `k8`, `k14`, `k18`, `k19`, `k24`, with census equal to the twin's.
- IR-only `k2`, `k5`, `k7`, `k8`, `k19`, `k24` `_branch`, with census +1 from F-XA-5 only.
- New spellings: `s1b`, `wboolb`, `g1b`, `t1` (a 3-function transitive dead parameter; slot B drops it inside
  `h`), `t2` (a cross-TU pure call in the arm; slot B folds it), `e2` C, and `l2` C.
- `k19`'s phase oracle P(q) is the twin's: same 14-line stream, `xor`/`mul` uncomputed before the Ry.
- TRACE-DIFF rows are only the findings: `a*`, `n5`, `g1c` (F-XA-2) and `d1b`/`d2` (F-XA-4).

## What I did NOT attack

- Variadic, `byval`, `sret` and `musttail` slots.
- A non-identity F-XA-2: a stray read on h0 interleaved with an un-reversed gate on h0. I argued it impossible
  (no `cq_*` in clone bodies, LIFO wrap) but did not prove it.
- F-XA-2 when h0 was freed before the call. I argued h0 is always the first `cq_theta` register, which is never
  freed.
- The composition with bd 9bhg.
- Any C route to the neutralisation beyond `t1`/`t2` (both closed by slot B).
- Round 3's `declineStaleTaintSet` and the global-fold arm (reviewer B), except as F-XA-4's population note.
- No corpus, allocator or mutation sweep, and no full lit or ctest run.
- I did not verify F-XA-4's root cause in the spine. I only localised the trigger to the position of the clone
  call.
