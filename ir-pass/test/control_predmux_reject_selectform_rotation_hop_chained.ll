; control_predmux_reject_selectform_rotation_hop_chained.ll — REJECT (bd u1rp).
; THE FENCE MUST BE A RECURSION, NOT AN OPERAND CHECK. This fixture exists
; because the first draft of the sibling fence was evaded by ONE MORE HOP, and a
; Rule-13 round exhibited it end to end.
;
; `RotationLowering` RAUWs a `cq_phi` result to OPERAND 0 verbatim
; (`Phi->replaceAllUsesWith(Op)`), so `cq_phi` is NOT a defined cone leaf — its
; value IS operand 0. A draft that merely inspected the rotation's ARGUMENTS for
; `undef`/`poison` therefore fenced depth 1 and nothing else:
;
;     %r1 = call i32 @cq_phi_si32(i32 poison, double 2.500000e-01)   ; caught
;     %r2 = call i32 @cq_phi_si32(i32 %r1,    double 7.500000e-01)   ; NOT caught
;
; because `%r1` is an Instruction, not an `undef` Constant, so the argument scan
; saw nothing. `classifyConeNode` now returns `ConeNode::PassThrough` for
; `cq_phi` and both walkers follow operand 0, so the chain is traversed to its
; root at any depth.
;
; ON THE PRE-FIX PLUGIN this module CLAIMED AND FLATTENED (`opt` exit 0,
; `opt -verify` clean, `free_pairing_check` STRICT 6/6, 5 toffolis) and the
; linked -O0 binary printed the same pairing break the depth-1 exhibit did:
; a forward `cq_template_icmp_slt_i32_hl(h0, 73896)` against an adjoint
; `_unc(h4, h0, 1401299752)`, then `cqrt_free(h4)` on a rail that is neither
; |0> nor unentangled. Rules 6 and 8.
;
; IT IS REACHABLE FROM STOCK clang -O1, not only from hand-written IR: an
; uninitialised local passed through two chained `cq_phi` phases emits
; `cq_phi_si32(i32 noundef undef, ...)` into a genuine two-merge-phi shielded
; diamond.
;
; SIBLINGS: control_predmux_reject_selectform_rotation_poison_arg.ll is depth 1;
; control_predmux_reject_selectform_rotation_hop_inherent_poison.ll is the same
; hop laundering an op that has no flag to drop at all. The positive control for
; all three is control_predmux_accept_selectform_seed_flags_preserved.ll, whose
; `cq_theta` seed is a defined, non-trivial expression and must still accept —
; `cq_theta` remains a genuine leaf because its result is a fresh
; `cqrt_alloc_<W>` handle that does not depend on the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:  | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r1 = call i32 @cq_phi_si32(i32 poison, double 2.500000e-01)
  %r2 = call i32 @cq_phi_si32(i32 %r1, double 7.500000e-01)
  %b = icmp slt i32 %q, %r2
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; CHECK: error: {{.*}}in function probe i32 (i32): cq controlled lowering: control flow under quantum control
