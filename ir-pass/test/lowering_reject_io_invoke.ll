; lowering_reject_io_invoke.ll — DECLINE (Phase 7.6): an `invoke` of `@printf`
; (rather than a direct `call`) is NOT carved as an I/O sink. The carve is
; restricted to a direct `CallInst` (`isa<CallInst>(CB)`); an `invoke` is a
; CallBase-but-not-CallInst terminator with normal + unwind successors that the
; call-position tape lowering has no story for, so it falls through to the loud
; unknown-callee decline. Mirrors how the front-end intrinsic guards treat invoke.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
declare i32 @__gxx_personality_v0(...)
@.d = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) personality ptr @__gxx_personality_v0 {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = invoke i32 (ptr, ...) @printf(ptr @.d, i32 %q) to label %ok unwind label %lp
ok:
  ret void
lp:
  %l = landingpad { ptr, i32 } cleanup
  ret void
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
