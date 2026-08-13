; control_mixed_value_io.ll — ACCEPT (Phase 7.2 Increment 2): a MIXED value+I/O
; diamond `if (q > 5) printf("%d", q); int r = (q>5) ? q+1 : q+2; return r;`.
; clang -O1 MERGES the conditional output and the value select into ONE br-diamond
; (the printf is unspeculatable, so the diamond survives; the value arms differ
; only by a constant, so clang hoists the `add` past the merge and the φ selects
; the CONSTANTS [1, 2]). The arm holds the recognized sink; the 2-incoming merge φ
; is a CONSTANT data-mux. Both effects lower under the ONE flag minted from the ONE
; compare: the I/O effect → one `cqrt_tape_write_i32_controlled` (printf is the
; TRUE arm here, so it fires on `flag`, no bracket); the value effect → the 4.4
; controlled-XOR copy (`out=|0>`; copy the flag-set constant 1 on `flag`; copy the
; ¬flag constant 2 in the self-inverse `cqrt_x` bracket; RAUW φ→out). The merged
; `out` then feeds the user's `add q, out` (a Q+Q op) and measure.
;
; The CONSTANT restriction is load-bearing: a constant is a pure basis value with
; NO phase, so the XOR copy cannot dephase (Rule 7). A COMPUTED two-base φ (no
; shared base) stays declining — the 65wb.5 exp2 conservative decline — see
; control_mixed_value_io_reject_twobase.ll. The taped `q` is also read by the value
; path (`add q, out`) in the merge; that fan-out is safe HERE because the tape
; write lands before the spliced merge tail, so q's free point follows the tape
; read (no use-after-free). The bracket span + the constant→polarity wiring are
; VERIFY-CLEAN-INVISIBLE, so both are pinned by the ORDERED CHECK below.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry  (TRUE successor)
  %p = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %sel = phi i32 [ 1, %arm ], [ 2, %entry ]
  %v = add nsw i32 %q, %sel
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; ONE tape, ONE flag; the I/O write UNBRACKETED (printf = TRUE arm; the CHECK-NOT
; forbids a `cqrt_x` between the mint and the write); then the constant data-mux
; (out=|0>; the flag-set constant 1 copied on `flag`; the ¬flag constant 2 copied
; in the self-inverse `cqrt_x` bracket); then the strip+free; then the Q+Q add of q
; with the mux result — EXACTLY in this order:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NOT: call void @cqrt_x(
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[S1]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[S2]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cq_template_add_i32(i32 %[[OUT]], i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: phi
; CHECK-NOT: br i1
; CHECK-NOT: cqrt_cswap
