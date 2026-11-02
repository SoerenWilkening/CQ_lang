# Spec issues

Contradictions found in the pinned CQ_spec (see `spec.lock`). CONSTRUCTION_RULES.md wins over an
example; the fix lands in CQ_spec (tracked in its §7 table), never as a workaround here. An entry is
removed when the fix is in CQ_spec and `spec.lock` is re-pinned to it. Version 1 requires this list
to be empty.

Entry format:

```
## <example or CR section>: <one-line summary>
- Rule: <CR rule/section the example or text should follow>
- Disagreement: <what the reference, header or text says vs what the rule requires>
- Evidence: <checker output, input sample, line references>
- Bead: <cq-… id>
```

## Open

## 87 vs 190, 189 (CR rule 14): a pointer induction of a quantum-exit loop
- Rule: CR rule 14, quantum-dependent exit: "every carried value advances by a `select` on `a_j`";
  the loop is re-rolled "by SCEV"; rule 20 classifies by the access offset.
- Disagreement: 87 makes the walked pointer `p` a fat pointer whose idx is a carried rail advanced
  by `select`, so `s` is a QRAM. 190's `__cq_q_memcmp_00111001111_b3` computes `l = vl + j`,
  `r = vr + j` from the classical trip index (slot loads checked against the cell count), and 189
  takes its induction `i` as the trip index `j`. The same shape gets two classifications; both are
  §6-equivalent. We follow 190/189 for pointers (owner may override).
- Evidence: 87 pointer_induction.lowered.ll header ("p.idx a loop-carried rail"), 190
  memmove_memcmp_escape.lowered.ll lines 168-200 ("l = vl + j, r = vr + j (SCEV)"), 189
  heap_linked_list.lowered.ll line 36.
- Bead: cq-n7e9

## 2026-11-02 no-stops round 1: shapes no CR rule covers (each is an "awaiting owner ruling: SPEC_ISSUES <title>" stop)
IR and the expected rule for each are in the named bead's worker report/comments.
- tape (cq-py5f): "Tape fields BACKEND_ABI 1.11 has no form for (…)" (quantum string/pointer field, %n, FILE*/write buffer, run-time-format pointer arg, vector arg, fwrite of run-time length, callback); "A deferred host call whose result is used"; "A signal-table host call on the tape"; "raise of a signal whose default action stops the process"; "An observable volatile access involving quantum data".
- invert (cq-eive): "A cq_invert region whose rails outlive it"; "… that uncomputes or frees a rail from before it"; "A clone with results inside a cq_invert region"; "A measurement, tape entry or abort flag inside a cq_invert region"; "The adjoint of a region that never ends"; "cq_invert markers that do not bracket the code between them".
- fenv (cq-hzji): rule 23 exception traps on quantum flags (feenableexcept); a classical call of a body reading the live quantum environment; a quantum rounding mode across a clone boundary; a constrained libm intrinsic with a quantum operand; a fenv_t/fexcept_t object holding a quantum part other code reads or writes.
- rot/aggr/taint (cq-oa67): IR outside the C x86-64 -O1 input language (fp128, scalable/pointer vectors, EH instructions, non-x86 va_start) — proposed: input-contract internal error; a program calling the cqrt_/cq_template_ namespace; rule 10 second prep after a reader or in-place rotation.
- spine (cq-29ej): bitreverse has no §1.2 template though rule 6 lists it; rule 6 composite updates beyond affine (GF(2)-linear, e.g. x ^ (x<<1)); rule 2 re-read of a rail a callee measures on some paths only; unwinding (invoke/landingpad/resume, -fexceptions); blockaddress/computed goto/asm goto in a lowered or cloned function.
- qram/qrom (cq-k65d): QROM of 2^64 cells (byte stride, unbounded i64 index, unknown extent); QRAM or rule-21 triple of >= 2^32 cells; global QRAM with no stated extent (extern T g[]); rule 22 unrolled past 2^20 bytes.
- fatptr (cq-5xm0): rule 21 base address of a slot object (pointer compare/ptrtoint over a slot alloca); bound check of a host object with no known extent; range decoding over a candidate with no known extent (2 sites); i32 idx field when the root's place in its object is unknown.
- calls (cq-s2zz): variadic clone per call-site arity with different variadic actual types; rule 27 declared clone with a pointer result (2); math intrinsic on half/bfloat/vector quantum operand; quantum function pointer not loaded at a quantum index (select of two functions, 2); quantum call through a function pointer with an empty static callee set.
- uncompute (cq-lshe): qram_realloc of a bus the function did not allocate (_unc needs the old size); a gate through a slot cell that may name pending garbage (may lowered code compare handles?); a write into a clone footprint of unknown extent before its twin (2).
- loops (cq-w3cd, cq-b58q): rule 14 case 3 classical value read after the loop (control-dependent exit value); a rule-14 loop with no live exit; computed goto or invoke inside a rule-14 loop.
- mem-slots (cq-e5lj): sret/byval struct parameter of an entry with a quantum field narrower than 4 bytes; reading an internal global slot cell no earlier access wrote (are internal-global rails outputs?); program-slot (102) reads outside the tracked entry shape.
- rule 19 (cq-i9wk): a callee whose returns keep different numbers of registers (kept clone's extra results).
