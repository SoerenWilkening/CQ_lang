# TRACK_RHK5 — a Phase-6 clone call inside a derived chain's discharge window

bd `test_C_libtooling-rhk5` (P1, wrong circuit, warned, C-reachable, PRE-EXISTING;
Rule-13 r3A F-XA-4). Implementer record, session 2026-09-28 (parallel). Branch
`worktree-agent-a7712272d6ca568e9` off `main` `9a230646`. Frozen ORACLE =
`cq-opt.main_9a230646` (`3f6db37f5cf937b4d70f5736`); this worktree's pre-change build
was BIT-IDENTICAL to it (`3f6db37f5cf937b4d70f5736`, measured before the first edit).

Probes, tools and raw results: `rhk5_probes/` (`src/` sources + stage-1 IR, `tools/`,
`results/`). Every number below names the command that produced it.

---

## §1 The defect, measured

`d4.c` (2-TU, llvm-linked exactly as `tests/e2e/run_slice_multi.sh` does):

    lib:  int h(int a, int k) { return k + 1; }
    main: q = cq_theta(m&7, .5); p = q*3; u = p^q; s = h(m, q);
          if (u == 10) cq_phi(PI); ms = cq_measure(s); q = cq_theta(q, .7);
          return ms + cq_measure(q);

ORACLE, lowered `@main` (read, not guessed — Rule 11; `results/battery_out/`):

    %h     = cqrt_alloc_i32(%6); cqrt_ry_i32(%h, 0.5)
    %h_op  = cq_template_mul_i32_hl(%h, 3)
    %h_op1 = cq_template_xor_i32(%h, %h_op)
    %7     = __cq_q_h_10(0, %h)                      ; <-- the clone call
    %h_cmp = cq_template_icmp_eq_i32_hl(%h_op1, 10)
    cqrt_rz_i1(%h_cmp, PI) !cq.branchphase
    cq_template_icmp_eq_i32_hl_unc(%h_cmp, %h_op1, 10); cqrt_free(%h_cmp)
    cqrt_measure_i32(%7); cqrt_ry_i32(%h, 0.7); cqrt_measure_i32(%h)

No `xor_i32_unc`, no `mul_i32_hl_unc`: `3q` and `3q ^ q` stay allocated and
ENTANGLED with `q` across `cqrt_ry_i32(%h, 0.7)` (Rule 8), `opt` exit 0, one
`warning: … non-diagonal gate over a live derived record` (lyyf-(B)). The hand-inlined
twin `d4T.c` (`s = q + 1`) emits the two adjoints and frees after the strip, no warning,
2b census `0 left dirty`.

### §1.1 The refusing predicate — located by EXPERIMENT, then read

Hypothesis from the brief: some spine owner treats the clone call as a barrier. The
chain `3q`, `3q ^ q` is not a dead terminal (its consumers are the flag mint and the
strip), so it belongs to the **M-B INTERIOR partition** (`planInteriorComponent`),
with `q` as the component's BORROWED parent. That planner's clause-(d) scan asks, of
every user `M` of a borrowed parent `P`, whether `M` can change `P`'s basis label
inside the window `(First, At)` — `First` = the first recovered gate reading `P` (the
`mul`), `At` = after the strip. A user is excused if `preservesBorrowedParent(M, P)`
proves it read-only, or `(W2)` proves it outside the window, or it is a whole recorded
route group. The clone call `__cq_q_h_10(0, %h)` is a user of `%h` strictly inside the
window, and `preservesBorrowedParent` proved exactly three shapes read-only
(diagonal `cqrt_rz_*`, controlled diagonal `cqrt_rz_*_controlled`, a forward template
producer). A clone call is none of them, so the scan returned `false`, the component
LEAKED (Rule 6's fallback), and the late M-A guard then read two records standing at
the Ry and warned.

EXPERIMENT (before any real edit, reverted): a throwaway `getenv`-gated line making
`preservesBorrowedParent` return `true` for `__cq_q_*` turned d4's stream into the
discharged one, census `0 left dirty`, no warning. So the refusal is exactly there.

The second predicate that names the same gate (L3) is `ChainWalk::isInteriorConsumer`,
whose "everything else DISQUALIFIES the rail" list named "a `__cq_q_*` clone call".
Family member `f02` (`s = h(m, p)` — the clone reads the chain rail `3q` ITSELF)
fails there: `3q` cannot be interior, the `3q ^ q` component then has `3q` as a
borrowed parent whose user is the same clone call, and both leak (oracle: warned,
`2 left dirty`; twin `s = p + 1`: clean).

### §1.2 Why the clone call is a different event from the inlined `add`

The twin's `cq_template_add_i32_hl(q, 1)` is a forward reassigning producer; the
spine admits it from the SYMBOL GRAMMAR alone — a producer has no mutating slot. A
clone call executes a whole function body at one program point; its write set is
whatever that body writes, so the spine could not admit it without reading the body,
and it did not read the body. Hand-inlining a pure callee changed the circuit.

Is the call provably READ-ONLY on its argument? Yes, and it is provable from the IR the
spine already holds: the specializer builds and LOWERS every clone inside
`specialize()` (`buildClone`: flatten, inner-clone drain, `lowerCloneSelect`,
`lowerQramReads`, `lowerOps(…, inBennettClone=true)`, `emitBennettWrap`), long before
`uncompute`, and no later stage emits into a clone body (§5, L1). In d4's clone

    %h_op   = cq_template_add_i32_hl(%k, 1)
    %cqq.out = cqrt_alloc_i32(0); cqrt_copy_i32(%h_op, %cqq.out)
    cq_template_add_i32_hl_unc(%h_op, %k, 1); cqrt_free(%h_op); ret %cqq.out

the formal `%k` is read by a forward producer and by an out-first adjoint in slot 1,
and written by nothing.

---

## §2 The fix

ONE new predicate, `cq::cloneCallPreservesArg(C, V, taint)` (`ChainWalk.{h,cpp}`),
and two callers.

**The predicate** (full contract in `ChainWalk.h`). `C` passes `V` only in argument
slots of a callee that is (C1) a defined non-varargs `Function` resolved from the
called OPERAND, RECORDED in `taint.SpecHandleArgMask` (the specializer's own record,
bd l3oi F-R7-1 — never the `__cq_q_` prefix), with (C2) every such slot marked a
HANDLE in that record and `V` never the callee or a bundle operand; and for each slot
the FORMAL is proven label-preserving by walking its uses: each is an argument of a
`CallInst` that is

* (B1) a forward producer (`isTemplateProducer` — the same test
  `preservesBorrowedParent` clause (2) uses);
* (B2) an out-first `cq_template_*_unc` reading it in a handle slot ≥ 1
  (`isUncHandleSlot`, the ONE slot table — slot 0, the written rail, refuses);
* (B3) the source of an uncontrolled copy (`isCopyOutSink`, refuses `src == dst`), or
  (B3′) the control/source — never the destination — of a controlled copy
  `cqrt_copy_<W>_controlled` (the 5po2 clone-select merge; VOID + arity 3);
* (B4) another call this predicate proves, recursively (inner clone, inner `_unc`
  twin), with a (function, slot) cycle and a nesting deeper than 16 refusing.

Anything else — a non-call user (`ret`, φ, store, cast, classical op), `cqrt_x`, a
rotation, a measure, a free, a toffoli/cnot, a copy destination, an adjoint's out
slot, an unrecorded or unresolvable callee — refuses the WHOLE call. Fail direction:
LEAK, the oracle's behaviour byte for byte.

**Caller 1** — `Uncomputation::preservesBorrowedParent` gains clause (3) (and a
`TaintSet` parameter; its one call site in `planInteriorComponent` passes it).
**Caller 2** — `ChainWalk::isInteriorConsumer` gains clause (b′), beside (b): a clone
call that reads the rail and provably never writes it is a forward consumer exactly
as a template reader is. Its (b) F5 fence (the rail must reach a QUANTUM slot) is the
record's handle-slot mask, which (C2) already requires.

### §2.1 Why it is sound — the one sentence and its premises

Clause (d) needs, at each emitted `_unc`, that every borrowed parent hold the
BASIS LABEL it held when the forward gate ran (an out-first `_unc` is a label-only
reader; the file's `routeGroupFullyInside` header carries that argument). A call whose
callee body never writes the formal it binds `P` to leaves `P`'s label as it found it,
so an adjoint after it reads the same label an adjoint before it would. For the
consumer role the same fact gives what (b) gives a template reader: the consumer has
read `R` and is done with it; that it has EXECUTED before the discharge and never
re-reads `R` is still the driver's positional proof (`useCompleteBeforeDischarge`),
untouched.

Premises, each checked rather than assumed:
1. The walked body IS the body that runs — clones are final before `uncompute`
   (§5 L1), and the proof is made at ask time, not recorded.
2. A value in a clone body can name the caller's register only through the formal:
   the body's other handles are fresh mints (`cqrt_alloc`, producer results); an
   ALIAS through a non-call instruction (`%k2 = or i32 %k, 0`) is a non-call user of
   the formal and refuses (pinned: `spec_leak_clone_read_twin_alias.ll`).
3. The record is NOT a proof of authorship: `Specialization::ensureTwin` REUSES a
   pre-supplied `<clone>_unc` definition and `buildClone` records it. That is why the
   predicate walks every recorded body instead of trusting the record (pinned by the
   four `spec_leak_clone_read_twin_*.ll`).
4. What is licensed is label preservation only; entanglement with the clone's result
   is untouched and needs nothing (the result is a function of the label).

### §2.2 What was NOT changed, deliberately

* `ln16` (a clone RESULT as an interior PRODUCER, adjointed by its twin) is NOT this
  and is not subsumed. This change admits clone calls as read-only USERS/CONSUMERS.
  It does discharge ln16's written prerequisite (b) — "prove the twin restores the
  clone's parameters" — for every twin this predicate admits: noted on ln16.
* The whole-DAG spine's moved-anchor clause-(d) scan (`reverseTerminalGroup`) asks
  `isInPlaceGateOn`, which already treats every clone call as non-mutating. Left as
  is; the premise it rests on is TRUE for specializer-synthesized bodies and NOT
  guaranteed for a pre-supplied twin (IR-only). Filed, not fixed (§8).
* `preservesBorrowedParent` itself was NOT taught the (B2)/(B3′) rows at the top
  level. They are sound there too (neither writes `P`), but they would widen the
  caller-side scan beyond this bead's population; `6uqc.1` is the open bead for the
  recorded-strip half of that question.

---

## §3 L1 / L2 / L3

**L1.** `cloneCallPreservesArg` is asked only from `uncompute` (both entry points
call it after every control round, after `specialize()`, `lowerOps`, `lowerMeasures`,
`lowerBreakReversePlay`, `lowerLateReassignments`) and from `planInteriorDischarges`
(the M-C late round, one stage earlier, on the same fully lowered module). It reads the
clone BODY and `taint.SpecHandleArgMask`, both written inside `specialize()` and final
after it: `lowerLateReassignments` keys on MODULE `taint.HandleWidth`/`Tainted`, which
never holds a clone-body value (clones lower under their own `cloneTaint`, C-Taint),
and `uncompute` finds no module-tainted producer in a clone body. Nothing it reads is
computed between the two control rounds, so no round-2 delta can falsify it; and it
records nothing — it is asked at use. (Even a hypothetical later write into a clone
body would be SEEN, since the walk is at ask time — the fail direction is a refusal.)

**L2 — widened sets and what else was computed over the same closure.**
* `preservesBorrowedParent`'s admitted users → consumed only by the clause-(d) scan.
* `isInteriorConsumer`'s admitted consumers → the SAME predicate is what
  `isInteriorTerminalHandle` (I3), `recoverDataDag`'s interior closure (`IP->Owned`)
  and therefore `planInteriorDischarges` ask, so they move together by construction
  (Rule 14). (I4) counts a clone consumer as a FORWARD consumer, which is right (it
  mints a fresh rail).
* NOT moved, and consistently so: `isTerminalHandle` (a clone consumer still makes a
  rail non-terminal) and the dead-terminal `recoverDataDag` closure (a clone consumer
  still marks that DAG `NotClosed`) — the interior partition owns these rails now,
  and the two partitions keep single ownership.
* The late M-A guard reads discharges as facts; it simply stops warning.

**L3 — other predicates naming the same gate.**
* `isInPlaceGateOn(clone, ·)` = false: consistent (a clone call is not an in-place gate).
* `EmitInverse::isInverseEmittable` admits `__cq_q_*` by name; can a clone call now
  enter an interior `D.Calls`? No: `recoverDataDag` walks back from OWNED rails, which
  are `cq_template_*` producers only ((I1)); a clone RESULT operand is not owned, so it
  is a BORROWED frontier and never walked. (ln16 would change this.)
* `RotationLowering::isCloneCallHop` / `cloneArgReachesResult` (M-A's exemption walk):
  untouched and unaffected.
* The moved-anchor scan: see §2.2.
* `free_pairing_check.py` models a clone as writing no argument (bd e5ha) — this
  predicate is the pass-side proof of that model for the bodies it admits; the
  checker's own gap (it proves nothing about the body) stays open.

---

## §4 Fixtures and e2e

### §4.1 lit — 5 ACCEPTs (red on the ORACLE) and 4 LEAKs (the ORACLE's disposition)

Red-green through a scratch lit site config that points `%cq-opt` at a COPY of the
frozen oracle (`scratchpad/rhk5/litora/lit.site.cfg.py`; the oracle directory is never
written): `lit litora --filter 'clone_read|clone_consumes'` → ORACLE **5 FAIL (the five
accepts), 4 PASS (the four leaks)**; subject `lit ir-pass/test --filter` same →
**9/9 PASS**. The leak fixtures pass on both binaries by design (they pin the ORACLE's
disposition); each goes red only under the mutant that admits its write route (§6).

| fixture | pins | ORACLE |
|---|---|---|
| `spec_accept_clone_read_in_discharge_window.ll` | d4: chain `_unc`+free after the strip, before the 2nd Ry; clone body unchanged; no warning | FAIL (warns, no chain adjoint) |
| `…_nested.ll` | f05: the proof goes through an inner clone AND its twin (B4) | FAIL |
| `…_identity.ll` | f06: formal only a copy SOURCE (B3); no `ret %k` | FAIL |
| `…_select.ll` | f07: formal a controlled-copy SOURCE (B3′) + compare + adjoint read (the twin DECLINES, so no twin stream) | FAIL |
| `spec_accept_clone_consumes_chain_rail.ll` | f02: clone CONSUMES `3q` (isInteriorConsumer (b′)); `3q` discharged after the call | FAIL |
| `spec_leak_clone_read_twin_writes_arg.ll` | pre-supplied inner twin does `cqrt_x(%k)` → refused → leak + warning | PASS (same) |
| `spec_leak_clone_read_twin_copy_dst.ll` | twin writes `%k` as a CONTROLLED-COPY DESTINATION | PASS (same) |
| `spec_leak_clone_read_twin_unc_out.ll` | twin writes `%k` as an ADJOINT OUT slot | PASS (same) |
| `spec_leak_clone_read_twin_alias.ll` | twin writes `%k` through a non-call ALIAS (`or %k, 0`) | PASS (same) |

The four LEAK fixtures are the adversarial "a clone that WRITES its argument" family
the brief asked for. A specializer-built clone cannot write a formal (§1.2), so the
only way to hand the spine a writing callee from IR is the pre-supplied-twin route
(`ensureTwin`'s reuse — the same threat model bd jj3o / xy9n fence elsewhere). A
DECLARED `@__cq_q_h_10` was also tried: it declines upstream (`cq taint escape:
tainted value consumed by an unknown callee`), so it needs no fixture here; a DEFINED
user function named `@__cq_q_h_10` is itself re-specialized into a recorded clone.

### §4.2 e2e — three 2-TU slices, their hand-inlined twins, three `*-twin-equivalent` gates

| subject (2-TU) | lib | twin | gate |
|---|---|---|---|
| `slice_spec_clone_read_in_window.c` (d4) | `spec_dropped_arg_lib.c` (reused, Rule 14) | `…_twin.c` | `e2e-spec-clone-read-in-window-twin-equivalent` |
| `slice_spec_clone_consumes_chain_rail.c` (f02) | `spec_dropped_arg_lib.c` | `…_twin.c` | `e2e-spec-clone-consumes-chain-rail-twin-equivalent` |
| `slice_spec_clone_read_nested.c` (f05′) | `spec_clone_read_nested_lib.c` (new) | `…_twin.c` | `e2e-spec-clone-read-nested-twin-equivalent` |

plus `e2e-trace-twin-equiv-selftest`. 10 ctest entries; `ctest -R "spec-clone|trace-twin-equiv"`
→ **10/10 passed**.

**WHY `*-twin-equivalent` AND NOT `*-twin-identical` — this is the part to challenge.**
Byte identity with a hand-inlined twin is impossible for a clone returning a quantum
value: its Bennett wrap emits four lines the twin does not (compute, alloc, copy,
uncompute, free vs one template), and `-O1` sinks the twin's inlined op past the
oracle while the cross-TU call stays put. `tools/trace_twin_equiv.py` (new) decides the
precise weaker relation: after contracting every Bennett COPY-OUT (rule 1) and every
inner-twin RECOMPUTE-ADJOINT (rule 2) — both rewrites argued in its docstring and each
guarded by an operand-not-clobbered check — the two traces must be Mazurkiewicz
equivalent up to a consistent handle renaming (same gates, same literals, same operand
roles — Q+Q `add/mul/xor/and/or` may swap their two operands — and every DEPENDENT pair
in the same order; dependence = a shared handle one of them WRITES; `cqrt_rz` is
conservatively a write). It refuses an unclassified symbol. 30 boundary controls run
on every invocation (null, rename-only, the rhk5 oracle defect → DIFF, the fixed
shape → EQUIV, dependent swaps → DIFF, literal/angle/role changes → DIFF, each
contraction's clobbered/free-first/scratch-reused negatives → DIFF, commutative vs
`sub` swaps). Measured: all three pairs **EQUIV** on the subject's goldens and
**DIFF** on the ORACLE's streams of the same sources; each twin's stream is
byte-identical on the oracle and the subject (`results/goldens_v3.txt`).

**The nested lib is `g(k) ^ k`, not `g(k) + 1`, and that is a disclosed choice.** With
a classical immediate the twin's `q*5 + 1` lowers IN PLACE (M-C `cqrt_addc_i32`), which
clone bodies never do (`inBennettClone`): the two circuits are the same but their gate
VOCABULARY differs, beyond what the checker can witness (it would say DIFF, the safe
direction). `f05` (the `+ 1` spelling) is in the battery (§5.2) and is clean by the
other two instruments.

## §5 Measurements

Box: 6 cores shared by five agents, load average 119–169 during this work; every
timing below is under that load and not comparable with a quiet-box figure.

### §5.1 Binaries

| binary | cq-opt | libCQPass.so |
|---|---|---|
| ORACLE (main 9a230646) | `3f6db37f5cf937b4d70f5736` | `356df92e0b58bbf787c41a25` |
| this worktree, before the first edit | `3f6db37f5cf937b4d70f5736` (bit-identical) | `356df92e0b58bbf787c41a25` |
| SUBJECT v2 (the measured binary) | `fa71e37a884ba4489e96a66a` | `c21a35eff3059cf6b8f64a3a` |
| mutant-tree base build (scratch copy of the sources) | `fa71e37a884ba4489e96a66a` (bit-identical) | — |

### §5.2 The family battery — every member against its hand-inlined twin

`tools/battery.py BIN 5 PAIRS…` (2-TU build as `run_slice_multi.sh`; per side: verdict,
warnings, 2b STRICT census, entangle.py Rule-8 findings; per pair:
`trace_twin_equiv.py`). ORACLE: `results/battery_oracle_arg5.txt`; SUBJECT:
`results/battery_subject_v1_arg5.txt` (v1 binary; f07 re-run on v2 after (B3′)).
`r8` = entangle.py `!!` lines on the subject trace.

| member | shape | ORACLE subject | SUBJECT subject | twin | SUBJECT vs twin |
|---|---|---|---|---|---|
| d4 | the bead's probe | warn, dirty 2, r8 1 | clean, dirty 0, r8 0 | clean | **EQUIV** |
| d3 | d4, `s` measured after the Ry | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** |
| d1 | three calls, two dead slots | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** |
| d1b | d1 as IR | warn, dirty 4 | clean, dirty 2 (†) | clean | **EQUIV** |
| d2 | lib `if (a>3) (void)K;` (vsfp stl3 customer) | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** |
| d5 | call AFTER the kickback (control) | clean | clean | clean | EQUIV (both) |
| f02 | clone CONSUMES `3q` | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** |
| f03 | clone consumes `u` | warn, dirty 1 | clean, dirty 0, r8 0 | clean | DIFF — twin lowers `u + 1` IN PLACE (M-C `addc` on `u`) |
| f04 | two clone calls | warn, dirty 2 | clean, dirty 0, r8 0 | clean | DIFF — twin CSEs `q+1` into one add measured twice |
| f05 | nested clone, `g(k) + 1` | warn, dirty 2 | clean, dirty 0, r8 0 | clean | DIFF — twin's `+ 1` is M-C in place (§4.2; the `^ k` spelling is EQUIV) |
| f06 | identity clone | warn, dirty 2 | clean, dirty 0, r8 0 | clean | DIFF — twin measures `q` itself; the clone measures a CNOT copy |
| f07 | clone with a select | warn, dirty 2, r8 2 | clean, dirty 0, r8 1 (‡) | DECLINES (condition predates a non-diagonal gate) | n/a |
| f08 | Ry on `q` before the call | DECLINE | DECLINE (same string) | DECLINE | — |
| f09 | call inside the kickback arm | DECLINE | DECLINE (same) | DECLINE (other string) | — |
| f10 | two kickbacks, call between | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** |
| f11 | `short` parameter | DECLINE (bd mg6f) | same | clean | — |
| f12 / f13 | call before chain / after kickback | clean | clean | clean | EQUIV (both) |
| f14 | per-trip chain in a loop | DECLINE | same | DECLINE (same) | — |
| f15 | Q+Q clone `h(p, q)` | warn, dirty 2 | clean, dirty 0, r8 0 | clean | DIFF — twin's `+ 1` in place |
| f16 | QROM read in the clone | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** (r8 counts entangle.py's unclassified QRAM lines) |
| f17 | multi-template clone | warn, dirty 2 | clean, dirty 0, r8 0 | clean | DIFF — twin's `+3`, `^6` in place |
| f18 | clone result dead | clean | clean | clean | EQUIV |
| f19 | d3's measure order | warn, dirty 2 | clean, dirty 0 | clean | **EQUIV** |
| f20 | M-C `q += 5` after the kickback | warn (both sides — the program's own) | same class | same | **EQUIV** |
| f21 / f22 | loop, register outside | DECLINE (operand predates…) | same | same | — |
| f23 | clone consumer in a loop, rail outside | warn, dirty 1 | IDENTICAL to oracle | warn, dirty 1 | DIFF (twin LICM-hoists `p + 1`) |
| n01 | `_Bool` parameter | DECLINE (bd mg6f) | same | DECLINE | — |
| n02 | Ry on `q`, then call, chain read by a template | clean | clean | clean | EQUIV (both) |
| n03 | no control flow at all | clean | clean | clean | EQUIV (both) |
| n04 | lib-internal call inlined in the lib | warn, dirty 2 | clean, dirty 0, r8 0 | clean | DIFF — twin's `+ 1` in place |

(†) d1b's residual `dirty 2` is the known bd jr8q / F-XA-5 CENSUS artefact: the 2b
census counts a clone call's CLASSICAL result as a dirty template rail (d1b has two
classical-verdict clone calls). Its trace is EQUIV to the twin's.
(‡) f07's remaining entangle finding is inside the CLONE's own select wrap (two
controlled copies of `%k` into `%cqq.sel`, which entangle.py's conservative union
model cannot cancel) and is present identically on the ORACLE; the Rule-8 finding at
the second Ry is gone.

**Every accepting member is now warning-free with 0 dirty template rails on the
subject** (except the two artefacts above), and every one the checker can compare is
EQUIV. The DIFF rows are vocabulary differences of the TWIN (M-C in-place, CSE, a
direct alias), each argued above — not leftover rails. `f23` is the one member whose
subject stream did not move at all: byte-identical to the ORACLE's, warned like its
twin. Something upstream of (b′) still refuses a loop-resident clone consumer of a
rail minted outside the loop; I did NOT trace which clause (the anchor or the
multiplicity key are the candidates) — it is the conservative direction and the twin
warns too, but it is listed in §7 as unattacked.

### §5.3 Corpus A/B vs the frozen ORACLE

`tools/run_ab.sh subject_v2` → `tools/ab.py` over four populations sharing ONE
persistent stage-1 cache (so the null and the real run read byte-identical inputs);
4 workers; exit code, stdout sha-256, first `error:` line and presence of a
`warning:`. The binaries are COPIES (`scratchpad/rhk5/bin/`), so no relink could
land under the sweep.

**NULL CONTROL FIRST — the SUBJECT twice** (`results/ab_null_subject_v2_twice.txt`):

| population | denominator | movers |
|---|---|---|
| lit (`ir-pass/test/*.ll`) | 2415 | 0 |
| e2e (`tests/e2e/*.c` × CASE, alone) | 614 swept (26 not buildable alone — library TUs etc. — NOT swept) | 0 |
| multi (every `run_slice_multi.sh` registration, built as that harness builds it) | 35 | 0 |
| probes (r2B/r3A/r3B vsfp review probe dirs + `rhk5_probes/src`) | 290 | 0 |

**ORACLE vs SUBJECT** (`results/ab_oracle_vs_subject_v2.txt`): **39 movers, every one
STREAM; 0 D→A, 0 A→D, 0 STRING.** Warned modules: lit 58 → 53, multi 6 → 3, probes
33 → 6, e2e 5 → 5. ⚠ (Round 3, Rule-13 r2A F-r2A-2.) "0 D→A" covers the SWEPT corpus
ONLY. r2A found a D→A mover outside every swept population — `l2i`, a clone call reading
a LICM-hoisted `p = q*3` inside a rolled loop: the oracle declines at bd tu9q's
postcondition (`hoisted invariant rail admitted for in-loop discharge was not
discharged`), rhk5 accepts, matching the hand-unrolled twin. Now pinned (§R3).

| population | movers | classification |
|---|---|---|
| lit (2416) | 6 | 5 = this change's new accept fixtures (red on the oracle by design). 1 EXISTING: `lowering_live_record_sibling_clone_arg_measured_accept.ll` — `c = 3a` is read only by a clone call; it was left allocated and is now discharged right after the call, exactly where the hand-inlined twin (`z = c * 3`) discharges it (measured). Its checks never pinned `c`'s disposition; the new stream is now pinned (prefix `RHK5`, red on the oracle). |
| e2e (614 swept) | 2 | `slice_libm_real_atan2l.c`, `slice_libm_real_coshl.c` — see §5.4; goldens REGENERATED deliberately. |
| multi (35) | 3 | the three new slices. |
| probes (290) | 28 | the rhk5 family and the r3A `d1/d1b/d2/d3/d4` (all warned → clean), and r2B's `k2`, `k2F`, `k2T`, `g12B` — each a clone call CONSUMING `p = 3q` before a `cq_theta(q, .7)` (the (b′) half of this defect, found by the sweep): warned → clean. `f20` moves its stream and keeps a warning on both sides (its twin warns too — the program's own). |

`tools/ab_extra.py` (railbank register-twin pairs + `example/**/*.c`, the other C
populations ctest compiles): **34 sources, 34 built, 0 movers.** Not swept: the
generated cells of `e2e-loop-twin-matrix` — single-TU programs with no `noinline`
helper (`grep -c noinline tools/loop_twin_matrix.py` = 0), so they build no clone
and `cloneCallPreservesArg` cannot return true on them (argued, not run: the matrix
takes 20+ minutes on this box).

### §5.4 The two EXISTING goldens that moved — regenerated, and why that is right

`tools/golden_movers.sh` (`results/golden_movers.txt`): for each, the oracle's trace
is byte-identical to the committed golden, and the subject's differs ONLY by
`_unc`+`cqrt_free` pairs:

* **atan2l** — `h26 = fabs(h25)` is read only by a clone call (`__cq_q_…`); it was
  left allocated, and `h25 = 0.25·x` (its parent) was discharged right after `h26`'s
  mint. Now `h26` is discharged right after the clone returns, and `h25`'s discharge
  moves with it (LIFO, one component). Census 13 → **12** dirty, frees 417 → 418.
* **coshl** — the same shape three times (`h11 = |x|·0.5` read by `expl`'s clone, and
  two `fabs(x)` rails each read by an `expl` clone call). Census 42 → **39** dirty,
  frees 857 → 860.

Both: stage 2b STRICT `0 violation(s), 0 unproven` on both binaries; entangle.py
reports the SAME number of findings on the old golden and the new trace (182 / 182,
1007 / 1007 — the libm bodies' union-model noise, unchanged, none added, none
removed). No line of either diff adds or moves a forward gate; every added line is a
discharge of a rail after its last reader. `ctest -R "libm-real-atan2l|libm-real-coshl"`
→ 2/2 after regeneration.

### §5.5 Suites, literally

All on the FINAL binaries (`cq-opt` `fa71e37a884ba4489e96a66a`, `libCQPass.so`
`c21a35eff3059cf6b8f64a3a`, `cq-opt-debugalloc` `a41086f078cc77724e5f3d98`).

* **lit, full** (`cd build && lit -j4 ir-pass/test`, `results/lit_final.txt`):
  **2416 discovered, 2415 passed, 1 XFAIL** (`lowering_invert_add_i32.ll`, the
  standing one), 0 failed, in 439 s under load. (The pre-pin run on the same
  binary, before the `RHK5` prefix and the select fixture were added, was 2412 /
  2411 / 1 XFAIL.) main has 2407 fixtures; this branch adds **9** (5 accepts,
  4 leaks) and changes **1** (`lowering_live_record_sibling_clone_arg_measured_accept.ll`,
  +1 prefix): `ls ir-pass/test/*.ll | wc -l` = 2416.
* **ctest, affected entries** (`ctest -j4 -R "e2e-slice-spec|e2e-spec-|libm-real-atan2l|libm-real-coshl|trace-twin-equiv"`,
  `results/ctest_affected.txt`): **49/49 passed** (every `spec`/`specialize` slice,
  the 10 new entries, the two regenerated libm goldens, the checker selftest).
  Earlier on this branch: the 10 new entries **10/10**, the two regenerated libm
  slices **2/2**, and the record gates `e2e-census-slice-sync`,
  `e2e-keepset-vendor-check`, `e2e-fixture-guard-liveness`,
  `e2e-free-pairing-selftest`, `e2e-negative-vacuity-selftest` **5/5**.
* **Allocator sweeps** (`tools/alloc_sweep.py`, `results/alloc_sweep.txt`), once:
  boundary control `CQ_OPT_DEBUG_ALLOC=BOGUS → exit 2` (the variable is read);
  **2416 fixtures, plain vs `lifo` vs `nofree`: 0 disagreements** (exit, stdout
  sha-256, first error).
* **Code map**: `tools/update_code_map.py` then `--check` → exit 0 (re-run after
  staging, since the generator lists `git ls-files` only).
* **NOT run** (Rule 19 / brief): the full `ctest -j6` (the merge gate's);
  `e2e-loop-twin-matrix` (argued unreachable, §5.3); `cq-opt-equivalence-full`
  (no diagnostic or analysis-surface change: no new string, no new decline);
  `taintset-scrub-guard` (no `TaintSet` member added or changed — the predicate
  only READS `SpecHandleArgMask`); an `+Asserts` build.

## §6 Mutation matrix

### §6.1 The compiler predicate — 8 mutants + a null

`tools/mutants.py` builds each mutant in a SCRATCH COPY of the sources
(`scratchpad/rhk5/mut`, rsync of the worktree minus build/docs/.git), one textual
replacement per mutant, anchor required EXACTLY ONCE, the tree restored after each.
The scratch tree's base build is BIT-IDENTICAL to the subject (`fa71e37a…`), the
NULL mutant's binary is bit-identical to the base (checked by the script, which
aborts otherwise), and after the last mutant the restored tree rebuilt identical.
`tools/mutmatrix.sh` runs lit (`-j4 --timeout 120`) through the scratch site config
with each mutant's `cq-opt` + `cq-opt-debugalloc` over the fixtures matching
`spec_|uncompute|clone|interior|live_record` — **401 of 2416** — with two HARNESS
CONTROLS in the same run: the subject binary (must fail 0) and the oracle (must fail
exactly the five new accepts). `results/mutmatrix_subset.txt`:

| mutant | removes / widens | failed / 401 | killed by | verdict |
|---|---|---|---|---|
| control: subject | — | 0 | — | as required |
| control: ORACLE | the whole change | 5 | the five `spec_accept_clone_*` | as required |
| N0_null | a comment; binary = subject | 0 | — | null |
| M1_trust_record | "the record says clone ⇒ read-only" (no body walk) | 4 | all four `spec_leak_clone_read_twin_*` | KILLED |
| M2_ccopy_dst | (B3′) admits the copy DESTINATION | 1 | `…_twin_copy_dst` | KILLED |
| M3_no_clause3 | `preservesBorrowedParent` clause (3) | 4 | the four window accepts (`…window`, `_identity`, `_nested`, `_select`) | KILLED |
| M4_no_bprime | `isInteriorConsumer` clause (b′) | 1 | `spec_accept_clone_consumes_chain_rail` | KILLED |
| M5_skip_noncall | non-call users of the formal skipped | 1 | `…_twin_alias` | KILLED |
| M6_unc_any_slot | (B2) admits any `_unc` slot (and so any `*_unc` CALL, twins included, unwalked) | 4 | all four hostile twins | KILLED |
| M7_no_handle_mask | (C2)'s handle-slot mask | 0 | — | see below |
| M8_no_record | (C1)'s `SpecHandleArgMask` membership | 0 | — | see below |

M7 and M8 remove fences that no reachable input distinguishes, and I could not
construct one: every call that passes a tainted value to a defined function is
retargeted to a RECORDED clone (a declared `__cq_q_*` callee declines as `cq taint
escape`, a defined user function of that name is itself re-specialized — both tried,
§4.1), and the mask is built from the same operand taint that puts the value in the
slot. They are kept because each is the fail-closed answer on an input nobody has
exhibited, and their result beyond the subset is §6.1′. Rule 12 cannot supply a
fixture for an unreachable shape; I say so rather than claim a kill.

### §6.1′ M7 / M8 beyond the subset

`tools/mut_multidef.sh subject_v2 M7_no_handle_mask M8_no_record` over every
MULTI-FUNCTION fixture outside the §6.1 subset (a fixture with one `define` builds no
clone, so the predicate cannot return true there — modulo a self-recursive call with a
quantum argument, which I did not construct; the filter selected 325, a superset
of the 314 such fixtures because lit's filter is a substring regex):
subject 0, **M7 0, M8 0** failures (`results/mutmatrix_multidef.txt`). With §6.1 that
covers every fixture the predicate can reach: **M7 and M8 are EQUIVALENT over the
corpus** — fences on inputs no fixture (and, as far as I could construct, no C
program) supplies. Not MISSED in the sense of a missing fixture for a reachable
shape; recorded as the honest limit.

⚠ CORRECTED IN ROUND 2 (Rule-13 r1A F-r1A-4): "no input distinguishes M7 / M8" is
wrong. A PRE-SUPPLIED twin separates both — `m8_twin_unrecorded_helper.ll` (the twin
reads `k` through a DEFINED, unrecorded, read-only helper: refused by (C1), admitted by
M8) — but ONLY in the ACCEPT direction: once the body is walked neither conjunct is
load-bearing for soundness. They are SCOPE limiters, not fences. See §R2.2.

### §6.2 The e2e instrument — `tools/trace_twin_equiv.py`

`tools/equiv_tool_mutants.py`: 8 mutants of the CHECKER + a null, each must turn its
own `--selftest` RED (`results/equiv_tool_mutants.txt`). **All 8 RED, null GREEN** —
after one real finding: on the first run **`T5` (an adjoint READS its out slot
instead of writing it) survived every control**, i.e. the checker could not see an
adjoint moved across a read of the rail it zeroes. Control `unc-writes-out` was added
and kills it; `T8` was re-spelled once because its first spelling was a no-op (the
selftest proved that too — it stayed GREEN on a non-mutation).

## §7 ATTACK FIRST — where I would look to break it

1. **The body vocabulary is NAME-keyed inside the walked body.** (B1)
   `isTemplateProducer`, (B2) `isUncHandleSlot`, (B3) `isCopyOutSink` and (B3′) read the
   CALLEE NAME of each use. A module that DEFINES a function named like a runtime
   template (`define i32 @cq_template_add_i32_hl(i32 %h, i32 %l) { cqrt_x(%h) … }`)
   and reaches it from a pre-supplied twin would be admitted by (B1). Every other
   spine predicate is name-keyed the same way (and the pass's own emissions would bind
   to such a definition too), so this is a reserved-namespace question, not specific
   to this predicate — but it is the first thing I would try, together with an
   `alias` / `bitcast` callee (refused: the callee is resolved by `dyn_cast<Function>`
   on the called operand) and a same-named NON-void or off-arity fake (only (B3′)
   checks void + arity; (B1)/(B2) take `isTemplateProducer`/`isUncHandleSlot`'s own
   fences as they are).
2. **The pre-supplied-twin route.** `ensureTwin` reuses a module-supplied
   `<clone>_unc` and `buildClone` records it. Four hostile twins are pinned; try
   others: a twin that writes `%k` through a nested user function it calls (must be
   refused — not recorded, or recorded and walked), through a `select`/`phi` of `%k`
   (non-call user — refused), through an operand BUNDLE (refused), or a twin whose
   `out` parameter is passed the caller's register (slot 0 is a handle slot in the
   record, and the body writes it — must be refused by the copy-destination rule).
3. **Premise 1 — "the walked body is the body that runs".** Find ANY stage after
   `specialize()` that emits into, erases from, or re-targets a call inside a clone
   body (I found none: `lowerLateReassignments` keys on MODULE taint, `uncompute`
   finds no module-tainted producer there, and nothing after `uncompute` emits gates).
   A second clone built later for the same (callee, mask) from a cache hit is the
   same `Function`.
4. **The consumer row (b′) is a wider change than clause (3).** It turns rails whose
   consumer is a clone call from never-interior into interior candidates, so it moves
   (I3)/(I4), the interior `recoverDataDag` closure and the M-C late round's plan.
   Attack it with a clone consumer INSIDE A LOOP whose rail is minted outside (the
   multiplicity key and `anchorForConsumer` must refuse or place correctly), a clone
   consumer that is itself inside a tainted region (6.5 / value arm hoist), and a rail
   read by TWO clone calls and a template.
5. **The e2e gates rest on a NEW instrument.** `tools/trace_twin_equiv.py` is the
   witness for "same circuit as the twin"; attack its two rewrite rules (docstring) and
   its commutativity table. It was made to fail on purpose (31 controls, 8 checker
   mutants all RED, null GREEN — §6.2), and its first mutation run found a real blind
   spot (an adjoint's out slot modelled as a read survived every control) that is now
   a control. It is conservative by construction (Rz is a write; unclassified symbols
   refuse), so its failure mode should be DIFF — look for a false EQUIV.
6. **Vocabulary DIFFs were classified by hand** (§5.2): f03/f04/f05/f06/f15/f17/n04
   are DIFF because the twin uses M-C in-place gates, CSE or a direct alias where the
   clone copies; I argued each is the same circuit and checked 2b + entangle, but no
   instrument witnessed those seven equalities.
7. **Found by the corpus sweep, not by me:** r2B's `k2`/`k2F`/`k2T`/`g12B` and two
   openlibm bodies (`atan2l`, `coshl` — a `fabs(x)` rail read only by `expl`'s clone)
   moved. I classified them (§5.3/§5.4) but they are exactly where a reviewer should
   look for a discharge placed before a clone call that still reads the rail.
8. **Not attacked by me:** `f23` (a clone consumer inside a loop of a rail minted
   outside it — its stream did not move and I did not trace which clause holds it),
   rolled loops beyond `f14`/`f21`/`f22` (both sides decline upstream),
   fp clones (`f11`/`n01`-style narrow params decline at bd mg6f; no fp member was
   built), tainted-region-internal clone calls beyond `f09` (declines both sides),
   and `-g` builds (debug records are not `Use`s in LLVM 19 — argued, not measured).

## §8 Beads noted (append-notes; nothing closed, no new bead filed)

* **rhk5** — this record; implemented on the branch, owed two Rule-13 rounds.
* **ln16** — NOT subsumed (a clone RESULT as interior producer is untouched); this
  change discharges ln16's written prerequisite (b), "prove the twin restores the
  clone's parameters", for every twin `cloneCallPreservesArg` admits.
* **e5ha** — the pass now PROVES, for the bodies it relies on, the model
  `free_pairing_check.py` assumes (a clone writes no argument rail); the checker's
  own gap stays open, and a pre-supplied twin is exactly where the model can fail.
* **jj3o** — related observation, ARGUED and NOT constructed: the whole-DAG spine's
  moved-anchor clause-(d) scan (`reverseTerminalGroup`) asks `isInPlaceGateOn`, false
  for every clone call, so it trusts a clone call not to write its operands; true for
  specializer-built bodies, not guaranteed when an inner `_unc` twin is pre-supplied
  (jj3o's threat model). `cloneCallPreservesArg` is the predicate a fix would call.
  IR-only, pre-existing; not a new bead because it is unmeasured and inside jj3o's
  surface.
* **mg6f** — family members `f11` (`short k`) and `n01` (`_Bool b`) decline at
  mg6f's mislabelled narrow-parameter clone decline on BOTH binaries. RETIREMENT
  TRIGGER (L8): when mg6f lifts, re-run the rhk5 family at narrow widths — (C2)'s
  handle-slot mask and the `_Bool`-condition clone select (which may bracket the
  formal with `cqrt_x`, refused by this predicate) become reachable.

## §9 Proposed CLAUDE.md text (for the orchestrator; I did not edit CLAUDE.md)

**§1 "What lowers today", a new row:**

| a Phase-6 **clone call inside a derived chain's discharge window** — reading the chain's borrowed parent (`s = h(m, q)` between `p = q*3; u = p^q` and `if (u == 10)`), or consuming a chain rail (`s = h(m, p)`) | the call is PROVEN read-only on what it is passed by WALKING THE CLONE BODY (forward producers, adjoint read slots, copy sources/controls, inner clones/twins recursively; anything else refuses), keyed on the specializer's record `taint.SpecHandleArgMask` and never on the `__cq_q_` name; the chain is then discharged exactly as around the hand-inlined template. ⚠ The record is NOT proof of authorship — `ensureTwin` reuses a pre-supplied `_unc` twin — which is why the body is walked | `ChainWalk::cloneCallPreservesArg`, `preservesBorrowedParent` (3), `isInteriorConsumer` (b′) (bd `rhk5`) |

**Witnesses paragraph, one sentence:** a clone returning a quantum value can NEVER be
byte-identical to its hand-inlined twin (the Bennett copy-out adds lines and `-O1`
sinks the twin's inlined op), so those pairs are gated `*-twin-equivalent` by
`tools/trace_twin_equiv.py` — same circuit up to the Bennett contraction and commuting
independent gates, 31 boundary controls, made to fail by 8 checker mutants — and a
DIFF from it on an M-C in-place / CSE / alias twin is a vocabulary difference the
tool deliberately does not bridge.

---

# ROUND 2 — the fixes for Rule-13 round 1 (r1A, r1B: both NOT-CLEAR)

Records of the two round-1 reviews: `review_r1A_rhk5/REVIEW.md`,
`review_r1B_rhk5/REVIEW.md` (committed verbatim in the round-2 commit, content
untouched). Their probes were COPIED verbatim to `rhk5_probes/round2/r1A/` and
`rhk5_probes/round2/r1B/`; the reviewers' own directories were never written.

## §R2.1 What changed, by file

| file | change |
|---|---|
| `ir-pass/src/ChainWalk.cpp` | `cloneCallPreservesArg` rewritten: (C1) requires `hasExactDefinition()`; the name-keyed vocabulary (B1)–(B3) is asked ONLY of a callee the module DECLARES; (B3) CALLS `isCopyGate`; the walk returns a three-valued `Proof` with a per-query memo; the dead `callee == V` conjunct removed. `isInteriorConsumer` / `isInteriorTerminalHandle` take `AdmitCloneCalls` |
| `ir-pass/include/ChainWalk.h` | the contract re-written: the false "Nothing is read off the NAME" corrected at the source (L7), the residual trust stated, the L3 parenthetical corrected (`_Bool` clone-select `cqrt_x` bracket), the memo / cycle argument |
| `ir-pass/src/RotationLowering.cpp` / `.h` | `isCopyGate` EXPORTED (the anonymous namespace closed around it; body byte-identical) |
| `ir-pass/include/DagTraversal.h` / `.cpp` | `InteriorPlan::AdmitCloneCalls`, read by the interior closure scan |
| `ir-pass/src/Uncomputation.cpp` | `preservesBorrowedParent` clause (3) and `planInteriorComponent` gated on `AdmitCloneCalls`; the planner is `collectInteriorPlansMode(…, AdmitCloneCalls)` with the PER-COMPONENT fallback; `collectInteriorPlans` is the FUNCTION-LEVEL backstop (ON vs OFF, ON only if a superset) |
| `tools/trace_twin_equiv.py` | `result_width` (rule 1 AND rule 2); 11 new controls (31 → 42); the module docstring corrected |
| tests | 10 lit fixtures (6 accepts, 4 leaks); 1 e2e slice (`e2e-slice-spec-clone-consumer-after-ry`) |

## §R2.2 The findings, one by one

**kyy1 (r1B F-r1B-1, P1) — FIXED in two layers.** The mechanism was exactly r1B's: (b′)
widened OWNED, and the component and its ANCHOR were computed over the widened closure
(L2 — the question my round-1 L2 section did not ask). (1) PER COMPONENT
(`collectInteriorPlansMode`): a component holding (b′)-admitted rails is ALSO split into
its pre-rhk5 pieces — same linking rules (`buildComponents`, one lambda), the (b′) rails
left as borrowed parents — and the whole plan is kept only when its discharged set is a
SUPERSET of the pieces'. (2) PER FUNCTION (`collectInteriorPlans`): the whole planner runs
ON and OFF (OFF = the pre-rhk5 planner verbatim), and ON is used only when its FINAL
discharged set — after the cross-plan ordering check, the only place one plan can lose
another's discharge — is a superset of OFF's. Layer (2) is what makes "never worse than
the pre-rhk5 planner" a CHECKED property; layer (1) is what keeps a function's other rhk5
wins when one component regresses. ⚠ Layer (2) exists because layer (1) alone is NOT
total, argued and not constructed: clause (3) can make a PIECE plan exist that the
pre-rhk5 planner refused, and that piece, as an INNER plan reading an OUTER plan's rail,
can make the ordering check drop an outer plan the pre-rhk5 planner kept.
Measured (`results/r2_kfamily_{oracle,r1,r2}.txt`, 7 members `k01`–`k07` around `b2n`):
`k01` (= `b2n`), `k02` (= `b2`), `k03` (Q+Q clone after the Ry), `k04` (clone consumes the
CONDITION rail), `k06` (a second, unrelated chain beside the shape): round-2 trace
BYTE-IDENTICAL to the ORACLE's (round 1 lost a discharge on every one). `k05` (the clone
consumes `p` BEFORE the Ry — the whole plan must win): round-2 trace byte-identical to
round 1's (the oracle leaks `p`). `k07`: see F-5. The PRE-EXISTING twin half (`s = p + 1`
leaks `u` on every binary) is NOT fixed and stays under kyy1.

**fb5y (r1A F-r1A-1 + F-r1A-2, P1) — FIXED.** A name is trusted only for a DECLARED
callee; a DEFINED one goes through (B4) (recorded + walked) or refuses; (C1) requires an
EXACT definition. Measured: r1A's `a1f` (hand IR), `a1c_c` (2-TU C) and `a5_weak_twin`
(with its strong interposer linked at stage 3) — round-2 traces byte-identical to the
ORACLE's (warned leak, no dirty free); round 1 freed two dirty rails silently on each.
The residual trust — a DECLARED name-shaped callee whose body arrives in a link-time
object — is written into `ChainWalk.h`; it is the boundary every emitter already stands
on, not a new one.

**tcpq (r1A F-r1A-3, P2) — FIXED.** Per-query memo per (function, formal slot). Measured
(under load 200–350): r1A `a3_d12` `opt` user time ORACLE 0.25 s · round 1 **17.84 s** ·
round 2 **0.25 s**; `a3_d10` 0.21 / 1.30 / 0.21 s. Why the cache cannot let a cycle
license itself: `ChainWalk.h` (two reasons; the second — one query, aborted at its first
refusal — carries the weight, so the "never memoise a provisional refusal" rule is
belt-and-braces, and a mutant of it could not change a verdict; recorded as argued).

**P3s.** r1B F-2 (width substring) FIXED by `result_width`, which reads the RESULT width
(`_to_<W>` for a cast, `i1` for a compare) — and the same hole in RULE 2 was then found by
this tool's own checker mutant T10, which survived every control after A9 was adopted:
control `recompute-width-cast` added. r1B F-3: rows A9, A12, A18, A22–A28 adopted as
controls; r1B's own `checker_mutants.py`, re-run on the new checker
(`round2/r1B_checker_mutants_after.txt`): U3, U6, U7, U8, U9, U10, U11 now **RED**; U2/U4
no longer apply (their anchor was the retired substring test — re-spelled as my T9/T10,
both RED); U14 (compare commutes) RED via A12 (my T11). Still GREEN: U1, U5, U12, U13 —
~~as r1B argued them equivalent on real traces~~ ⚠ CORRECTED IN ROUND 3 (Rule-13 r2B
F-r2B-1): U12 and U13 were NOT equivalent — they were UNPINNED-BUT-SOUND (correct
conjuncts with no control), and r2B built a non-equivalent pair for each that the shipped
checker calls DIFF and the mutant calls EQUIV; both are now pinned (§R3). U1/U5 remain
unpinned-but-sound on real compiler traces (r2B F-r2B-2, §R3). r1B's
`attack_checker.py` on the new checker: **FALSE EQUIV 0 of 28**. r1B F-4 (docstring)
FIXED. r1B F-5 (`l1` warns on a clean trace): isolated by family member `k07` (`l1`
minus the chain) — warns on the ORACLE, round 1 and round 2 with byte-identical traces,
and the only record at the Ry is the per-trip clone result measured in the loop body:
bd **58tc**'s class (an in-body observation cannot be proven before the Ry through the
back edge), with bd jr8q's by-name record classification. Pre-existing; noted on 58tc,
not traced inside the guard. r1B F-6 / r1A F-6: (B3) CALLS `isCopyGate` (exported). r1A
F-4: M7/M8 are separable in the accept direction — §6.1′ corrected. r1A F-5: cycle and
cap pinned (§R2.3). r1A F-7: the L3 parenthetical corrected at the source.

**z0re reviewer's addendum — `k3L`** (literal-seed controlled state prep behind a clone
call between a derived chain and its condition): ORACLE warned leak, `trace_twin_equiv`
DIFF; round 1 and round 2 **EQUIV** to `k3LT` (my hand-inlined twin), no warning, 0 dirty.
Pinned by `spec_accept_clone_read_before_state_prep.ll`. The runtime-seed `k3C` needs
z0re and is the merge gate's (the z0re twin `k3T.c` is kept as
`rhk5_probes/src/k3T_z0re_runtime_seed.c`).

## §R2.3 Fixtures and e2e

Red-green through the scratch lit config on three binaries (`tools/redgreen.sh`):

| fixture | ORACLE | round 1 | round 2 |
|---|---|---|---|
| `spec_accept_clone_consumer_after_ry_keeps_sibling.ll` (kyy1, `b2n`) | PASS | **FAIL** | PASS |
| `spec_accept_clone_consumer_after_ry_cond_rail.ll` (kyy1, `k04`) | PASS | **FAIL** | PASS |
| `spec_accept_clone_consumer_before_ry_whole_plan.ll` (kyy1 control, `k05`) | **FAIL** | PASS | PASS |
| `spec_accept_clone_two_components_both_discharged.ll` (kyy1, both layers) | **FAIL** | **FAIL** | PASS |
| `spec_leak_clone_read_defined_template_name.ll` (fb5y, r1A `a1f` body) | PASS | **FAIL** | PASS |
| `spec_leak_clone_read_weak_twin.ll` (fb5y, r1A `a5` body) | PASS | **FAIL** | PASS |
| `spec_leak_clone_read_twin_cycle.ll` (r1A `cyc_self_twin` body) | PASS | PASS | PASS |
| `spec_accept_clone_read_depth_at_cap.ll` (16 pairs) | **FAIL** | PASS | PASS |
| `spec_leak_clone_read_depth_cap.ll` (17 pairs) | PASS | PASS | PASS |
| `spec_accept_clone_read_before_state_prep.ll` (z0re `k3L`) | **FAIL** | PASS | PASS |

The leak fixtures that pass everywhere are pinned by MUTANTS (§R2.5), not by a red on a
shipped binary. The e2e slice `e2e-slice-spec-clone-consumer-after-ry` (the 2-TU `b2n`):
golden **byte-identical to the ORACLE's trace**, round 1 differs (`gen_golden3.sh`);
deliberately no twin gate (the twin is the pre-existing defect).

## §R2.4 Measurements (round 2)

Binaries, `shasum -a 256` prefixes: **round 2** `cq-opt` `aa0dff29ea088cde195e222c`,
`libCQPass.so` `2d9c71bc8067627a30a637e1`, `cq-opt-debugalloc` `2da6e185c4e223b67019179e`
(snapshot `scratchpad/rhk5/bin/cq-opt.r2`, bit-identical; the mutant tree's base build is
bit-identical too). Round 1 = `fa71e37a…` (`cq-opt.subject_v2`); ORACLE = `3f6db37f…`.
Load: 200–350 during the first half of the round, ~2 after the 23:52 restart.

* **lit, full** (`lit -j4 ir-pass/test`, `round2/lit_r2.txt`): **2425 discovered, 2424
  passed, 1 XFAIL** (`lowering_invert_add_i32.ll`), 0 failed, 456 s under load 200–350.
  `ls ir-pass/test/*.ll | wc -l` = **2426** after the last fixture
  (`spec_accept_clone_two_components_both_discharged.ll`) was added; that one was run
  on its own and in the mutant matrix (both GREEN on round 2), not in the full run.
* **ctest, affected** (`tools/ctest_affected.sh`, `round2/ctest_affected_r2.txt`):
  **53/53 passed** — every `spec`/`specialize` e2e slice incl. the new
  `e2e-slice-spec-clone-consumer-after-ry`, the three `*-twin-equivalent` gates,
  `e2e-trace-twin-equiv-selftest` (42 controls), the two regenerated libm slices, and the
  record gates `e2e-census-slice-sync`, `e2e-keepset-vendor-check`,
  `e2e-free-pairing-selftest`.
* **Corpus A/B**, same four populations as round 1 (lit 2426 · e2e 615 [26 multi-TU
  not buildable alone, NOT swept] · multi 36 · probes 307):
  * NULL control, round 2 against itself, run FIRST: **0 movers** (`round2/ab_null_r2_twice.txt`).
  * ORACLE vs round 2 (`round2/ab_oracle_vs_r2.txt`): **45 movers, ALL STREAM — 0 A→D,
    0 D→A, 0 STRING, 0 unwarned→warned** (⚠ over the SWEPT corpus only — r2A's `l2i`,
    outside it, is a D→A mover; §R3). Round 1's 39, plus 4 new lit accepts
    (`…before_ry_whole_plan`, `…before_state_prep`, `…depth_at_cap`,
    `…two_components_both_discharged` — each an rhk5 win the oracle leaks), plus 2 new
    probes (`k05`, `k3L` — same). The kyy1 family members `k01`–`k04`, `k06` and the new
    slice `slice_spec_clone_consumer_after_ry` are NOT movers: byte-identical to the oracle.
    Warned: lit 66→57, multi 6→3, probes 40→11.
  * ROUND 1 vs round 2 (`round2/ab_r1_vs_r2.txt`): **11 movers, all STREAM**, every one
    the round-2 fix's own population: the 3 kyy1 lit accepts (round 1 lost a discharge),
    the 2 fb5y leak fixtures (round 1 unwarned and freed dirty; round 2 the oracle's
    warned leak), the new e2e slice, and probes `k01`–`k04`, `k06`. **Nothing else moved**
    — in particular none of round 1's 39 wins (the three e2e gates, the libm goldens,
    r2B's `k2`/`g12B`, the `d*`/`f*` family) changed.
  * Extra (railbank pairs + `example/`, `round2/ab_extra_oracle_vs_r2.txt`): 34 sources,
    0 movers.
* **Both reviewers' batteries** (`round2/rbattery.py`, verbatim copies of their probes,
  argument 5; `battery_{oracle,subject_v2,r2}.txt`, joined in `battery_compare.txt`).
  Columns: verdict, `w`arnings, 2b `d`irty template rails, trace sha / `opt` user time;
  `=O` = round-2 trace byte-identical to the oracle's, `=R1` = to round 1's.

```
probe                          ORACLE             ROUND 1            ROUND 2            r2 twin    flags
A:a0_writes_arg                A w1 d2 0ed92b     A w1 d2 0ed92b     A w1 d2 0ed92b                =O =R1
A:a1_name_producer             A w1 d3 0ed92b     A w0 d1 d97223     A w1 d3 0ed92b                =O
A:a1b_name_unc                 A w1 d2 0ed92b     A w0 d0 d97223     A w1 d2 0ed92b                =O
A:a1c_ccopy                    A w1 d2 833a2e     A w0 d0 cf9985     A w0 d0 cf9985                =R1
A:a1d_direct_evil              DECLINE            DECLINE            DECLINE                       =O(decl)
A:a1e_redefine_unc             LINKFAIL           LINKFAIL           LINKFAIL                      
A:a1f_evil_after_uncompute     A w1 d3 44892e     A w0 d1 cb3cf0     A w1 d3 44892e                =O
A:c1_deadterm_hostile          DECLINE            DECLINE            DECLINE                       =O(decl)
A:c2_deadterm_hostile_nomq     A w1 d1 665a57     A w1 d1 665a57     A w1 d1 665a57                =O =R1
A:cyc_self_twin                A w1 d2 69693d     A w1 d2 69693d     A w1 d2 69693d                =O =R1
A:m8_twin_unrecorded_helper    A w1 d2 0cfb19     A w1 d2 0cfb19     A w1 d2 0cfb19                =O =R1
A:m8_unrecorded_cqrt           DECLINE            DECLINE            DECLINE                       =O(decl)
A:a5_weak_twin                 A w1 d2 44892e     A w0 d0 cb3cf0     A w1 d2 44892e                =O
A:a1c_c                        A w1 d2 44892e     A w0 d0 cb3cf0     A w1 d2 44892e                =O
A:a2_d3                        A w1 d2 0.19s      A w0 d0 0.19s      A w0 d0 0.19s                 
A:a2_d6                        A w1 d2 0.20s      A w0 d0 0.19s      A w0 d0 0.20s                 
A:a2_d9                        A w1 d2 0.20s      A w0 d0 0.20s      A w0 d0 0.20s                 
A:a2_d12                       A w1 d2 0.23s      A w0 d0 0.24s      A w0 d0 0.24s                 
A:a3_d6                        A w1 d2 0.20s      A w0 d0 0.20s      A w0 d0 0.20s                 
A:a3_d8                        A w1 d2 0.20s      A w0 d0 0.26s      A w0 d0 0.20s                 
A:a3_d10                       A w1 d2 0.21s      A w0 d0 1.30s      A w0 d0 0.21s                 
A:a3_d12                       A w1 d2 0.25s      A w0 d0 17.84s     A w0 d0 0.25s                 
A:a4_mem                       DECLINE            DECLINE            DECLINE                       =O(decl)
A:a4b_rot                      DECLINE            DECLINE            DECLINE                       =O(decl)
A:d4                           A w1 d2 ee7013     A w0 d0 135eab     A w0 d0 135eab                =R1
A:b1_after_ry                  A w0 d1 83ae7d     A w0 d1 83ae7d     A w0 d1 83ae7d     DIFF       =O =R1
A:b2_twoclones                 A w1 d2 7a315a     A w0 d0 738a18     A w0 d0 738a18     EQUIV      =R1
A:b3_condcall                  A w1 d2 4c4c16     A w1 d1 b17b98     A w1 d1 b17b98     EQUIV      =R1
A:b4_loopcall                  A w1 d2 50aa9f     A w1 d0 4c9f0f     A w1 d0 4c9f0f     n/a        =R1
A:b5_mc_inwindow               A w1 d2 ec4641     A w1 d0 07fe6d     A w1 d0 07fe6d     EQUIV      =R1
A:comp_deadslot                A w1 d2 40ec85     A w0 d0 2983a4     A w0 d0 2983a4     EQUIV      =R1
B:b0                           A w1 d2 ee7013     A w0 d0 135eab     A w0 d0 135eab     EQUIV      =R1
B:b1                           A w1 d1 82e2d4     A w0 d0 60a022     A w0 d0 60a022     EQUIV      =R1
B:b14                          A w1 d2 224805     A w0 d0 440ab7     A w0 d0 440ab7     DIFF       =R1
B:b2                           A w0 d1 ab78ec     A w1 d2 b3d88f     A w0 d1 ab78ec     DIFF       =O
B:b2n                          A w0 d1 90942c     A w1 d2 783381     A w0 d1 90942c     DIFF       =O
B:b3                           A w1 d2 597c2d     A w0 d0 b37eba     A w0 d0 b37eba     EQUIV      =R1
B:b4                           A w1 d2 c6ae86     A w0 d0 fa06e6     A w0 d0 fa06e6     DIFF       =R1
B:b5                           A w1 d2 f956e2     A w0 d0 35684d     A w0 d0 35684d     EQUIV      =R1
B:b6                           A w1 d2 ee7013     A w0 d0 135eab     A w0 d0 135eab     EQUIV      =R1
B:c1                           DECLINE            DECLINE            DECLINE                       =O(decl)
B:c2                           DECLINE            DECLINE            DECLINE                       =O(decl)
B:c3                           DECLINE            DECLINE            DECLINE            n/a        =O(decl)
B:c4                           DECLINE            DECLINE            DECLINE                       =O(decl)
B:c5                           A w1 d1 ebeef9     A w0 d0 8e5c1f     A w0 d0 8e5c1f     DIFF       =R1
B:k2x                          A w1 d1 336b56     A w0 d0 843225     A w0 d0 843225     DIFF       =R1
B:l1                           A w1 d2 50aa9f     A w1 d0 4c9f0f     A w1 d0 4c9f0f     n/a        =R1
B:l2                           A w1 d2 a4f36d     A w1 d1 082812     A w1 d1 082812     EQUIV      =R1
B:r2B_g12B                     A w1 d1 0bb081     A w0 d0 54c5bc     A w0 d0 54c5bc     DIFF       =R1
B:r2B_k2                       A w1 d1 550d98     A w0 d0 74596a     A w0 d0 74596a     DIFF       =R1
B:r2B_k2F                      A w1 d1 550d98     A w0 d0 74596a     A w0 d0 74596a     DIFF       =R1
B:r2B_k2T                      A w1 d1 550d98     A w0 d0 74596a     A w0 d0 74596a     DIFF       =R1
B:v1                           DECLINE            DECLINE            DECLINE            n/a        =O(decl)
B:z1                           A w1 d2 429e8f     A w0 d0 9f4c9e     A w0 d0 9f4c9e     EQUIV      =R1
B:z2                           DECLINE            DECLINE            DECLINE            n/a        =O(decl)
```

  Reading it: every r1A hostile-twin probe round 1 ADMITTED (`a1_name_producer`,
  `a1b_name_unc`, `a1f`, `a5_weak_twin`, `a1c_c`) is `=O` on round 2 — the oracle's warned
  leak. Every r1B kyy1 exhibit (`b2`, `b2n`) is `=O`. Every other accept is `=R1` — the
  round-1 win kept (`d4`, `b0`–`b6`, `c5`, `k2x`, `l1`, `l2`, r2B's four, `z1`,
  `comp_deadslot`, `b2_twoclones`, …). `a1c_ccopy` (r1A's CONTROL: a twin reading `k` as a
  controlled copy's SOURCE) is admitted on rounds 1 and 2 — correctly; its 2b
  `viol=1` is present on all three binaries (pre-existing, the twin names `out` as both
  control and destination). Depth probes: `a3_d12` `opt` user time **0.25 / 17.84 / 0.25 s**
  (oracle / round 1 / round 2), `a3_d10` 0.21 / 1.30 / 0.21 s. Declines are the same
  string on all three binaries (`=O(decl)`).
* **kyy1 family** (`results/r2_kfamily_{oracle,r1,r2}.txt`, `tools/battery.py`, 2-TU C
  with hand-inlined twins): see §R2.2 — `k01`–`k04`, `k06` byte-identical to the oracle,
  `k05` byte-identical to round 1, `k07` identical on all three.
* **`k3L`** (argument `13 6`): round 2 `trace_twin_equiv` **EQUIV** to `k3LT`, warn 0,
  dirty 0; oracle DIFF, warned, dirty 2.
* **`tools/trace_twin_equiv.py`**: selftest **42/42**; r1B's `attack_checker.py` **FALSE
  EQUIV 0 of 28** (was 1 — A9); my checker mutants T0–T11 all as required
  (`results/equiv_tool_mutants_r2.txt`, T9/T10/T11 new); r1B's U-mutants: §R2.2.
* **Code map**: `update_code_map.py` then `--check` → exit 0.

## §R2.5 Mutants of the new conjuncts (9 + a null — one over the ≤8 budget — two of them re-spelled)

`tools/mutants_r2.py` in the scratch mutant tree (synced to round 2; base bit-identical
`aa0dff29…`; NULL `N0_null` bit-identical to the base; tree restored and rebuilt identical
after), `tools/mutmatrix.sh` over the 411 fixtures matching
`spec_|uncompute|clone|interior|live_record`, controls round 2 (0 failures) and ORACLE
(10 failures — the rhk5 accepts, as expected). `round2/mutmatrix_r2_subset.txt`:

| mutant | what it breaks | failures | killed by |
|---|---|---|---|
| N0_null | a comment | 0 | (control) |
| R1_name_trusts_defined | a DEFINED callee with a forward-template NAME admitted by that name (round 1's hole, exactly) | 1 | `spec_leak_clone_read_defined_template_name` (re-spelled — see below) |
| R2_interposable_ok | `hasExactDefinition` → `!isDeclaration` | 1 | `spec_leak_clone_read_weak_twin` |
| R3_cycle_licenses | a cycle returns YES | 1 | `spec_leak_clone_read_twin_cycle` |
| R4_no_depth_cap | cap deleted | 1 | `spec_leak_clone_read_depth_cap` |
| R5_cap_15 | cap 16 → 15 | 1 | `spec_accept_clone_read_depth_at_cap` |
| R6_copy_dst_admitted | (B3) admits the copy DESTINATION | 1 | `spec_leak_clone_read_twin_copy_dst` |
| R7_whole_plan_always | per-component fallback never taken | 1 | `spec_accept_clone_two_components_both_discharged` |
| R8_pieces_always | per-component fallback always taken | 3 | `…before_ry_whole_plan`, `…consumes_chain_rail`, `lowering_live_record_sibling_clone_arg_measured_accept` |
| R9_no_function_backstop | function-level ON/OFF comparison removed | **0** | **SURVIVES** |

* ⚠ **R1's FIRST SPELLING DID NOT RE-OPEN THE HOLE IT WAS NAMED FOR.** `if (UCallee) {`
  sent EVERY defined callee — the recorded inner clones included — into the name
  vocabulary, which refuses a `__cq_q_*` name, so the walk refused at the first inner
  clone and never reached the evil call: it killed two nested ACCEPTS
  (`…read_in_discharge_window_nested`, `…read_depth_at_cap`) and left
  `spec_leak_clone_read_defined_template_name.ll` GREEN (`round2/mutmatrix_r2_subset.txt`).
  Found by reading the mutant's lowered IR, not assumed. Re-spelled as round 1's exact
  behaviour — `isDeclaration() || isTemplateProducer(UC)` — it is killed by exactly the
  fb5y fixture and nothing else (`round2/mutmatrix_r2_R1respell.txt`). The first
  spelling is kept in the record as what it is: a different mutant ("defined callees are
  never walked"), whose two kills pin (B4)'s reach.
* **R7's first spelling was EQUIVALENT BY CONSTRUCTION** (`bool FullWins = true;` — the
  superset loop right below reset it; `round2/mutmatrix_r2_subset_R7first.txt`, 0
  failures). Diagnosed from the code, re-spelled so the fallback branch is dead
  (`round2/mutmatrix_r2_R7respell.txt`): killed by exactly the one fixture built to pin
  layer (1) on its own. Counted as one mutant, not two.
* **R9 survives** the subset AND the 325-fixture multi-`define` complement
  (`round2/mutmatrix_r2_multidef_R9.txt`), and a full corpus A/B round 2 vs R9
  (`round2/ab_r2_vs_R9.txt`) moves **0 of 3,384** modules. Layer (2) — the function-level
  backstop — changes no module anywhere in the tree; it is UNPINNED, its distinguishing
  input (§R2.6) argued and not constructed. Belt-and-braces by measurement, and an
  `e1gr`-shaped item.
* Not re-run: round 1's M1–M8 (their conjuncts moved but their files did not change
  meaning: M7/M8 are the scope limiters r1A F-r1A-4 describes).

## §R2.6 What round 2 did NOT do

* **The kyy1 twin half** (M-B component granularity leaks the dead sibling for the
  hand-inlined twin too) — pre-existing, left under kyy1. Splitting components by
  consumer anchor was r1B's other suggestion; not attempted (it changes shipped streams
  outside rhk5's population and owes its own round).
* **Layer (2)'s distinguishing input was not constructed.** The function-level backstop
  exists for an argued case (a clause-(3)-enabled piece dropping an outer plan through
  the cross-plan ordering check); no fixture reaches it, so mutant R9 is expected to
  survive (§R2.5) and that is recorded, not hidden.
* **r1B's surviving checker mutants U1, U5, U12, U13** — argued equivalent by r1B; no
  controls added. ⚠ Superseded in round 3: U12/U13 were unpinned-but-sound, NOT
  equivalent, and are now pinned; U1/U5 stay unpinned (§R3).
* **The residual name trust** (a DECLARED name-shaped callee supplied by a link-time
  object) — stated in `ChainWalk.h`, not fenced; it is the same boundary every emitter
  stands on.
* **Allocator sweeps** — not re-run (brief: only if the memo changes allocation-sensitive
  state). It does not: the memo is a local `DenseMap` that lives for one query and is
  keyed on `Function *` of bodies that are final while it exists; no side table persists
  across stages, no pointer outlives an erase.
* **Full `ctest -j6`**, `e2e-loop-twin-matrix`, `cq-opt-equivalence-full`, `+Asserts`,
  `taintset-scrub-guard` (no `TaintSet` member changed) — not run.
* **`k3C`** (runtime seed) — needs z0re; for the merge gate on the composed binary.

## §R2.7 ATTACK FIRST (round 2)

1. **The ON/OFF comparison is on DISCHARGED RAIL SETS, not on circuits.** It guarantees
   the pre-rhk5 compiler's discharges are all present; it does NOT compare where they
   are placed. A rail discharged by ON at a DIFFERENT anchor than OFF discharges it at is
   counted as present. Attack: a program where ON discharges the same rail set as OFF
   but one discharge moves to a point that is wrong for a reason clause (d) does not see.
2. **Clause (3) inside a PIECE plan.** The pieces are planned with clause (3) ON (the
   (b′) rails as borrowed parents, a clone call reading them admitted). So a piece can
   exist that the pre-rhk5 planner refused — the case layer (2) is the backstop for.
   Construct it (a loop + a multiplicity split + a clone call in the inner plan's window)
   and check the ordering-check interaction.
3. **`hasExactDefinition()` is the whole F-r1A-2 fix.** It also refuses `weak_odr` /
   `linkonce_odr` clones (conservative — the specializer builds `internal` ones). Try an
   `alias`, an `ifunc`, a `define available_externally` pre-supplied twin, and a twin
   reached through a `bitcast` of a function pointer.
4. **"A DECLARED callee is the runtime."** A pre-supplied twin calling a DECLARED
   `cq_template_evil_i32` whose body comes from a separate object is accepted. The claim
   is that this is no different from a user object overriding `cq_template_add_i32_hl`
   for every emitter; attack that claim if you think the clone walk makes it worse.
5. **The memo.** One query, aborted at the first refusal — check there is no path where
   a query continues after a `NoProvisional` (the recursion returns it upward through
   `clonePassPreserves` and `formalLabelPreserved` without being swallowed).
6. **The two-layer redundancy is itself an `e1gr` shape** for single-component
   functions: layer (1) is individually pinned only by
   `spec_accept_clone_two_components_both_discharged.ll`, and layer (2) by nothing.
7. **The kyy1 family is 7 members plus `b2`/`b2n`.** Shapes not built: a (b′) rail read
   by TWO clone calls on opposite sides of the Ry; a (b′) chain whose clone consumer is
   in a loop body; a (b′) rail that is also a borrowed parent of a THIRD component.

---

# ROUND 3 — the round-2 review items (both reviews CLEAR-WITH-ITEMS, 0 P1)

Records: `review_r2A_rhk5/REVIEW.md`, `review_r2B_rhk5/REVIEW.md`, committed verbatim in
this commit (content untouched; 475 files, sha-256 manifest checked before commit). This
round changes **no pass source code**: comments, fixtures, the checker's controls and
records only. The rebuilt binaries are **bit-identical** to round 2's:

| binary | sha-256 |
|---|---|
| `cq-opt` | `aa0dff29ea088cde195e222c350c6d20e5e37d14ec52ccb6fd6c616164b92e09` |
| `libCQPass.so` | `2d9c71bc8067627a30a637e147c1423e9e83e66b5a57d8a485c208f3f4c70003` |
| `cq-opt-debugalloc` | `2da6e185c4e223b67019179e0d7be20a6e6f2967206791c356c1e0b8caddecc7` |

## §R3.1 Items

* **r2A F-r2A-1 (P2, disclosed) — layer (2) unpinned.** The source comment at
  `collectInteriorPlans` now says it is unpinned (R9 moves 0 of 3,384 modules, no
  fixture fails), WHY no C program reaches it (r2A's 13 probes `l2a`–`l2m`: every
  spelling that makes the cross-plan ordering check fire declines earlier on both
  binaries — the P4 cross-block gap, or clause (ii-d) refusing a hoisted rail with an
  out-of-loop user), that it fails safe (it can only choose OFF), and its RETIREMENT
  TRIGGER (P4 admitting a guarded / `break`-exited loop over a hoisted rail, or (ii-d)
  admitting a hoisted rail with an out-of-loop user — then it owes a fixture that fails
  under R9).
* **r2A F-r2A-2 (P3) — `l2i` pinned.** New ACCEPT fixture
  `ir-pass/test/spec_accept_clone_read_hoisted_rail_in_rolled_loop.ll`, body = r2A's
  stage-1 `l2i.s1.ll` VERBATIM. Four prefixes: SILENT (no warning), EXIT (`mul_unc(h_op)`
  + free immediately before the trailing `cqrt_ry(h, .9)`), BODY (no `mul_unc` between
  the clone call and the back edge), ONCE (exactly one `mul_unc` in the module, its own
  prefix). Red-green (`tools/redgreen.sh`): **FAIL on the oracle** (it declines), PASS on
  rounds 1 and 2. Injection check (`tools/inject_l2i.py`, `round2/inject_l2i.txt`): null
  passes; discharge moved into the body, an extra discharge in the body, discharge after
  the Ry, discharge dropped, free dropped — **MISSED 0 of 5**. The "0 D→A" statements
  in §5.3 and §R2.4 are corrected to say they cover the swept corpus only.
* **r2A F-r2A-3 (P3) — filed** as bd **`test_C_libtooling-ezyg`** (P3, discovered-from
  rhk5, related kyy1): layer (1) tries only all (b′) rails or none; a mixed plan clause
  (d) would accept (`f2.c`) is a missed win, byte-identical to the oracle. A comment at
  the per-component fallback names it.
* **r2A F-r2A-4 (P3, L7) — comment scoped.** `collectInteriorPlans` and `ChainWalk.h`
  now say "never worse than pre-rhk5" is checked PER CALL, on the module the call sees:
  the M-C late round (`planInteriorDischarges`, `ArithLowering` arm (d2)) asks the same
  ON/OFF question one stage earlier, and why that stays safe is r2A's argument
  (recorded as argued, not constructed).
* **r2B F-r2B-1 (P3) — U12/U13 pinned.** Two controls added to
  `tools/trace_twin_equiv.py` (44 total), both r2B's pairs: `r2B-U12-measure-past-copy-src`
  (a measure reordered past a copy that reads the same rail) and
  `r2B-U13-renaming-injective` (two CNOTs on two targets vs one target twice — no mints,
  on purpose: r2B's alloc-first spelling does not reach the conjunct, measured by
  `tools/u12_u13_probe.py`: shipped DIFF / U13 DIFF). Checker mutants T12 (measure is a
  read) and T13 (injectivity dropped) are now RED, each killed by exactly its control;
  T0 null GREEN; all 14 as required (`results/equiv_tool_mutants_r3.txt`). The three
  e2e gate pairs stay EQUIV. The record's "equivalent" for U12/U13 is corrected to
  "unpinned-but-sound, now pinned".
* **r2B F-r2B-2 (P3, pre-existing) — U1/U5 noted, not pinned.** The contraction's
  narrowness conjuncts (`len(ua) != 4`, `uc[1] != j`) remain unpinned; r2B argues them
  sound on real compiler traces (a scratch rail is used by exactly its four Bennett
  lines and downstream checks reject the relaxed cases). No control added.
* **r2B F-r2B-3 (P3) — fixture headers.** `spec_leak_clone_read_twin_cycle.ll`,
  `spec_leak_clone_read_depth_cap.ll` (green on oracle, round 1 and round 2) now say in
  their headers that they do not by themselves distinguish the fix and rest on the
  out-of-tree mutant matrix (R3, R4); `spec_accept_clone_read_depth_at_cap.ll` says its
  cap-value claim rests on R5.
* **r2B F-r2B-4** is r2A F-r2A-1 (above).

## §R3.2 What was run

* Rebuilt all four targets; `cq-opt`, `libCQPass.so`, `cq-opt-debugalloc` bit-identical
  to round 2 (table above).
* lit, the new and changed fixtures only (`spec_accept_clone_read_hoisted_rail_in_rolled_loop`,
  `spec_leak_clone_read_twin_cycle`, `spec_leak_clone_read_depth_cap`,
  `spec_accept_clone_read_depth_at_cap`): **4/4 PASS**. The new fixture red-green on
  oracle / round 1 / round 2: FAIL / PASS / PASS.
* ctest `e2e-trace-twin-equiv-selftest` + the three `e2e-spec-clone-*-twin-equivalent`
  gates: **4/4**. Selftest **44/44** controls.
* `update_code_map.py` then `--check`: exit 0.
* NOT run (per the orchestrator's round-3 profile): full lit, full ctest, corpus A/B,
  mutant matrix — no pass source changed and the binaries are bit-identical.

