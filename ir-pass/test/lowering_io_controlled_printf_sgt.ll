; lowering_io_controlled_printf_sgt.ll — ACCEPT (Phase 7.6 Increment 2): a
; tainted-condition conditional output `if (q > 5) printf("%d", q)` lowers
; COHERENTLY to ONE `cqrt_tape_write_<W>_controlled` under the minted flag. The
; tape entry is ALWAYS appended (tape length is classical/deterministic, PRD-7.6
; §2.4); only its CONTENT is committed under `ctrl`. The gate arm here is the TRUE
; successor (`sgt`), so the controlled write fires on the flag directly — NO
; `cqrt_x` bracket (the un-negated polarity; cf. the `_ne` fixture for ¬flag).
;
; q stays coherent: the controlled write is CNOT-class (preserves `src`), the copy
; DESTINATION is the fresh kept out-rail (never q), so q == q0 at flag-strip time.
; The flag is minted, used, stripped (`_inv`) and freed; the kept out-rail is
; registered in OutputRails (never freed/reversed). NO measurement is inserted by
; the I/O lowering (Rule 5) — the only measure is the user's `cq_measure`. The
; diamond is flattened: no `br i1`, no surviving `@printf`, ZERO controlled
; rotations / cswap (a tape write is the only controlled symbol).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; One lazy stdout tape; q lowered to its i32 handle; the flag minted from the
; tainted icmp; ONE controlled tape write (ctrl arg-0, tape arg-1, src arg-2);
; the flag stripped + freed; the user's measure preserved. The CONTROLLED write
; symbol is the only new gate — no cswap, no controlled rotation:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: controlled(i32{{.*}}double
; CHECK-NOT: br i1
; CHECK-NOT: cq controlled lowering
; CHECK-NOT: cq I/O output sink
