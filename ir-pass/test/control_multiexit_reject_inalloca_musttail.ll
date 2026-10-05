; control_multiexit_reject_inalloca_musttail.ll — DECLINE (bd test_C_libtooling-dm7f.5,
; review round 1 F3): a `musttail` that forwards the caller's incoming `inalloca`
; argument. LangRef: a `musttail` call forwards an `inalloca` argument IN PLACE, and
; on any other call an `inalloca` argument must be the `alloca` the caller set up for
; that call. The demoted plain call would pass the caller's own incoming argument
; memory — verifier-clean (the verifier inspects `inalloca` provenance only when the
; operand is an `alloca`) yet invalid. Refused before any mutation. IR-only (the
; 32-bit Windows C++ ABI); a compiler gap, not physics. `inalloca` must be the last
; parameter, hence the operand order.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: musttail forward of an inalloca argument under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @ik(i32, ptr inalloca(i32))

define i32 @example(i32 %u0, ptr inalloca(i32) %p) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %fwd, label %done
fwd:
  %r = musttail call i32 @ik(i32 %u0, ptr inalloca(i32) %p)
  ret i32 %r
done:
  ret i32 %q
}
