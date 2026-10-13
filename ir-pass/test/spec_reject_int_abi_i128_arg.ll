; spec_reject_int_abi_i128_arg.ll — DECLINE (bd p3kd.9, the decline cell of the
; widened lift-boundary ABI).
;
; Since p3kd.9 a tainted argument crosses a lifted call as an i32 handle iff its
; width has a reversible copy-out (`cqrt_copy_<W>`): the integer widths i1..i64 and
; the fp widths f16..f80 (`liftHandleWidth`, SpecializeClone.h). i128 is a recognized
; INTERMEDIATE width (n0ui Tier-1: templates exist, so `(__int128)q * q` lowers in
; the caller) but has no `cqrt_copy_i128`, so a tainted i128 argument still has no
; handle copy and the site declines at the per-site ABI check, loud and located at
; the call. This is a compiler gap, not a physics limit (R1): it closes the day an
; i128 copy-out exists. RETIREMENT TRIGGER (L7): when `tools/opcode_table.yaml`
; gains `cqrt_copy_i128`, `liftHandleWidth` admits i128 and this fixture becomes an
; accept.
;
; C source (clang -O1, then the IR below trimmed of attributes and metadata):
;   __attribute__((noinline)) int fold128(__int128 w) { return (int)(w >> 64) + (int)w; }
;   int example(long u0) {
;     long q = u0;
;     cq_theta(&q, 0.5);
;     return cq_measure(fold128((__int128)q * q));
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @fold128(i128 noundef %w) {
  %hi = lshr i128 %w, 64
  %h = trunc i128 %hi to i32
  %l = trunc i128 %w to i32
  %s = add i32 %h, %l
  ret i32 %s
}

define i32 @example(i64 noundef %u0) {
  %q = tail call i64 @cq_theta_sl(i64 noundef %u0, double noundef 5.000000e-01)
  %e = sext i64 %q to i128
  %w = mul nsw i128 %e, %e
  %r = tail call i32 @fold128(i128 noundef %w)
  %m = tail call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %m
}
