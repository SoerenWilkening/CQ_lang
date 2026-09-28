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
33 → 6, e2e 5 → 5.

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
