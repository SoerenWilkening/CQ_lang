; control_classical_call_arm_reject_nonI32_ret.ll — NON-i32 RETURN reject (8mld):
; a PURE classical call inside a tainted-condition diamond arm whose merge phi is
; `i64` and is consumed by a DIRECT `ret i64`. The 6.5 emitter RAUWs the merge phi
; to the FRESH `%out` handle, and `cqrt_alloc_<W>` returns an i32 at every width
; (Rule 15) — so accepting this leaves `ret i64 <i32 handle>`, a BROKEN MODULE the
; LLVM verifier aborts on (`report_fatal_error("Broken module found")`), NOT a
; Rule-1 source-located decline. A crash on well-formed valid input (opt -verify
; exit 0, llvm-as exit 0) violates Rule 1.
;
; The merge phi is UNTAINTED (a classical call result + a classical constant), so
; the pre-detection `declineTaintEscapes` non-i32-return net (which is TAINT-gated)
; never sees it — UNLIKE the value/phase diamond, whose TAINTED merge is caught by
; that net (lowering_reject_taint_escape_return_{value,phase}_diamond.ll). The
; MERGE-OUT ESCAPE GATE in `classifyClassicalCallArm` closes this: a `ret` escape
; is sound ONLY at i32 (the caller owns the i32 handle — the Escaped case); a
; non-i32 `ret` DECLINES loudly. NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i64 @f(i64) #0

define i64 @example(i32 %u0, i64 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i64 @f(i64 %a)                       ; PURE, all-classical args — 6.5 shape
  br label %merge
merge:
  %y = phi i64 [ %r, %arm ], [ 5, %entry ]       ; UNTAINTED i64 merge
  ret i64 %y                                     ; non-i32 ret of the RAUW'd i32 handle
}

attributes #0 = { nounwind willreturn memory(none) }
