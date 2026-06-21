; lowering_reject_io_i128_arg.ll — DECLINE (Phase 7.6): a tainted i128 `printf`
; argument. i128 is an INTERMEDIATE-only width (n0ui Tier-1): there is NO
; `cqrt_tape_write_i128`, so the tape lowering gates on `widthHasReversibleCopy`
; (true only for {i1,i8,i16,i32,i64}), NEVER on `abiWidthFromType(..).empty()`
; (which i128 satisfies — minting a phantom symbol would link-fail). A tainted i64
; (suffix `sll`) widened to i128 reaches the printf as an i128; it declines LOUDLY.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i64 @cq_theta_sll(i64, double)
declare i32 @printf(ptr, ...)
@.s = private constant [5 x i8] c"%lld\00"

define void @slice(i64 %u0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %w = zext i64 %q to i128
  %r = call i32 (ptr, ...) @printf(ptr @.s, i128 %w)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: tainted argument is not a lowerable integer scalar
