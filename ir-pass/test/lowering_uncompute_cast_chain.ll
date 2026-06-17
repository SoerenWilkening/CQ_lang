; lowering_uncompute_cast_chain.ll — Phase 5 WI-3 coverage lock for an ARITY-1
; CAST link inside a reverse-played chain (Rule-13 clearance follow-up: the cast
; `_unc` shape is asserted-correct by construction but the goldens only link `_hl`).
;
; `q = cq_theta; w = (i64)q; d = w + 7` — a dead chain mixing a width-changing cast
; (`zext i32 -> i64`) with an i64 arithmetic link. Two DD-3 facts are pinned:
;   * the cast adjoint is the VOID `cq_template_zext_i32_to_i64_unc(out, src)` with
;     BOTH operands i32 (handles are always i32, Rule 15 — the i64 is a value width,
;     never a handle width);
;   * the i64 arithmetic adjoint `cq_template_add_i64_hl_unc(out, src, i64 7)` keeps
;     the i64 classical literal at its real width in the forward slot.
; Liveness is leaf-first: add_unc reads the still-live cast handle, cast_unc reads
; the still-live alloc root, then the rotation un-rotates the root and it is freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward chain (theta -> alloc + ry, then the zext cast, then the i64 add):
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i32_to_i64(i32 %[[H]])
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64_hl(i32 %[[W]], i64 7)
; Reversed adjoint (LIFO): add_unc(out=%d, src=%w, i64 7) BEFORE zext_unc(out=%w,
; src=%h) BEFORE ry(-θ), then free the |0> root %h. All handles i32; no fresh mint.
; CHECK:     call void @cq_template_add_i64_hl_unc(i32 %[[D]], i32 %[[W]], i64 7)
; CHECK:     call void @cq_template_zext_i32_to_i64_unc(i32 %[[W]], i32 %[[H]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_add_i64_hl_inv
; CHECK-NOT: cq_template_zext_i32_to_i64_inv
; CHECK-NOT: cq_theta_si32
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %w = zext i32 %q to i64
  %d = add i64 %w, 7                              ; dead mixed-width chain terminal
  ret void
}
