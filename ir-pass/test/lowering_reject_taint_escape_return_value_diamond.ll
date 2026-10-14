; lowering_reject_taint_escape_return_value_diamond.ll — DECLINE: a value-arm
; (method-B) diamond whose merge result is RETURNED at NON-i32 width
; (test_C_libtooling-udw, member 3/3).
;
; `if (q > 5) { p = p*5 + 15; } return p;` — the i32-width twin is an ACCEPT case
; (the controlled-copy merge, `SelectMergeEmit`: `cqrt_copy_i32_controlled` into a
; fresh rail produces the merged handle `%out`, ALWAYS i32). Returning that always-i32 `%out` from a function declared to return
; i64 leaves `ret i64 <i32 handle>` — so a shape PRD Part II §8.5 sanctions (ret is
; a legitimate consumer of `out`) crashes the verifier on ACCEPT-class input rather
; than declining. declineTaintEscapes catches the tainted non-i32 ret pre-RAUW.
;
; bd p3kd.21 / bd jx32 (2026-10-14) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. The function has no in-module use (an entry
; point / export, `declineQuantumReturnCalls`' Escaped contract), so its non-i32
; tainted `ret` returns the register's i32 runtime HANDLE: the return is
; re-declared `i32` after lowering (`retypeQuantumExportReturns`,
; SpecializeGateInline.h) and the verifier-abort hazard described above cannot
; arise (a `ret` still carrying a non-i32 value there fails loudly with the same
; non-i32 string). The gate stream is the one the i32-typed twin of the same body
; emits (measured on the value diamond: identical, call for call; the twin's arm
; chain is left allocated exactly as there). The non-i32 decline remains for a
; function WITH an in-module use: spec_reject_gate_sub_indirect_nonI32.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(i64 %u0, i64 %v0)
; CHECK: [[OUT:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK: call void @cqrt_copy_i64_controlled(i32 {{%[a-z0-9_.]+}}, i32 {{%[a-z0-9_.]+}}, i32 [[OUT]])
; CHECK: call void @cqrt_copy_i64_controlled(i32 {{%[a-z0-9_.]+}}, i32 {{%[a-z0-9_.]+}}, i32 [[OUT]])
; CHECK-NOT: call void @cqrt_free(i32 [[OUT]])
; CHECK: ret i32 [[OUT]]
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)

define i64 @example(i64 %u0, i64 %v0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %p = call i64 @cq_theta_sll(i64 %v0, double 2.500000e-01)
  %c = icmp sgt i64 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i64 %p, 5
  %v2 = add i64 %v1, 15
  br label %merge
merge:
  %pm = phi i64 [ %v2, %arm ], [ %p, %entry ]
  ret i64 %pm                                      ; non-i32 escape — cannot launder
}

