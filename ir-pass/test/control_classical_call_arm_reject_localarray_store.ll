; control_classical_call_arm_reject_localarray_store.ll — DECLINE (dugh, Phase 4×6;
; the DEFERRED capability, follow-on bead d3ji): a 6.5 classical-call arm whose
; UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`) is STORED into a local scratch
; array (`arr[i] = y`) at a CLASSICAL index, then loaded back and measured.
;
; Storing a QUANTUM HANDLE into memory is NOT reachable by dugh's re-propagation: the
; store of a tainted value is an escape (taint is SSA-only). The Phase-7.5 Shadow
; model accepts only `arr[q] = classical_value` (TAINTED index, CLASSICAL value) — it
; never models a quantum handle written into a slot (`matchQramAccess` returns nullopt
; for the classical-index gep here). So after `repropagateControlMerges` re-taints
; `%out`, the store declines via the precise `kMsgStore`. Owner-directed defer
; (2026-07-04): the clean fix is a g7ip-sibling store→load forwarding (prove the
; scratch slot is single-write/single-read/no-alias/no-escape, RAUW the load to
; `%out`) — a distinct mechanism tracked in the follow-on bead. the follow-on
; bead is CLOSED not-reachable (2026-07-04): that forwarding is UNREACHABLE on the
; clang -O1/-O2/-O3 validated floor — GVN already forwards every provably-same-address
; round-trip before cq-lowering runs (d3ji's accept-set is a strict subset of GVN's),
; so this shape arises ONLY in hand-authored off-floor IR like below. This fixture pins
; the PERMANENT SAFE over-decline (Prime Directive). NEVER lowered. See `bd memories
; d3ji-gvn-subsumption-finding` + docs/prd/phase-04-swap-route-control/d3ji-*.md.
;
; ── AMENDMENT, bd `xdu2` / L-1a (Track B, 2026-09-14c) — TWO CLAIMS ABOVE ARE
;    NARROWED, AND ONE OF THEM IS MEASURED FALSE AS STATED ──────────────────────
;
; ⚠ (1) *"that forwarding is UNREACHABLE on the clang -O1/-O2/-O3 validated floor —
; GVN already forwards every provably-same-address round-trip before cq-lowering
; runs"* IS FALSE AS WRITTEN, and `SCOPE_L1a.md` §3(b) measured the
; counterexample. In `trackL/probes/a_loop_n3.c` at `-O1`, `%9` and `%15` are the
; SAME address and `%16` is NOT forwarded — because the store sits in the
; conditional arm and is only PARTIALLY AVAILABLE. GVN forwards FULLY AVAILABLE
; stores; the claim holds for those and for no others. The store→load forwarding
; this header calls unreachable is exactly what bd `xdu2`'s per-activation
; promoter (`RailBankPromote.cpp`) now performs, on the `-O1` floor, for a
; rail-bank cell.
;
; ⚠ (2) *"Storing a QUANTUM HANDLE into memory is NOT reachable … taint is
; SSA-only"* is still TRUE OF THIS TREE (there is no load/store taint rule) and
; is being NARROWED rather than retired: L-1a's deferred half adds one rule — a
; `load` from a `!cq.railbank` alloca is tainted. The doctrine sentence must not
; be read as a permanent property of the design.
;
; ⚠ THIS FIXTURE IS NOT RETIRED AND ITS VERDICT DOES NOT MOVE. MEASURED on the
; Track B subject binary: the promoter fires ZERO times on this module. It fails
; three of the bank clauses independently — its index `%i` is a FUNCTION ARGUMENT
; with no enclosing loop, so C2' has no `{0,+,1}` add-recurrence at all; its array
; has no proven zero initializer; and the module is off the `-O1` floor by this
; header's own last sentence. The `PERMANENT SAFE over-decline` line stands for
; THIS module; what is no longer permanent is the general claim it rests on.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value stored to memory
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_twin_accept_partial_callee.ll (a VISIBLE partial body,
; hoisted since batch 053 only as its divisor-guarded twin). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a, i32 %i) {
entry:
  %arr = alloca [8 x i32]
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]         ; UNTAINTED merge (a quantum handle)
  %slot = getelementptr [8 x i32], ptr %arr, i32 0, i32 %i
  store i32 %y, ptr %slot                           ; store the qubit handle to memory
  %v = load i32, ptr %slot
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
