; lowering_uncompute_fanout_dag.ll — Phase 5 WI-4 fan-out headline (PRD §2.11 /
; IMPLEMENTATION §4 WI-4). REPLACES the retired lowering_uncompute_chain_fanout.ll
; NO-EMIT lock: an intermediate handle `%h1` fans out to BOTH `%h2 = h1 + 1` and
; `%h3 = h1 * 2`, so there are two dead terminals whose recovered DAGs SHARE the
; prefix (`ry`, `add → h1`). The conservative WI-3 slice BAILED (reversing each
; terminal independently double-adjoints + double-frees the shared prefix); WI-4
; reverses the WHOLE DAG once.
;
; The single reverse-topological (LIFO) pass adjoints each gate EXACTLY ONCE and
; frees each rail right after its LAST reverse-use — the canonical §2.11 trace:
;   mul_unc(h3,h1); free h3;  add_unc(h2,h1); free h2;  add_unc(h1,h); free h1;
;   ry(-θ) on h;    free h
; `%h1` is read by BOTH `mul_unc(h3,h1)` and `add_unc(h2,h1)`, so it is freed ONLY
; after `add_unc(h1,h)` (its own producer's adjoint, emitted last among its
; reverse-touches) — never before a sibling's adjoint still reads it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=UNC
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=FRE
;
; Forward DAG (theta root, then the fan-out):
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 1.000000e-01)
; CHECK:     %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H1]], i32 1)
; CHECK:     %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H1]], i32 2)
;
; Reversed whole-DAG (LIFO): each gate's `_unc` once, h1 freed AFTER its last
; consumer's adjoint (add_unc(h1,h)):
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[H3]], i32 %[[H1]], i32 2)
; CHECK:     call void @cqrt_free(i32 %[[H3]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[H2]], i32 %[[H1]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[H2]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[H1]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[H1]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -1.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_add_i32_hl_inv
; CHECK-NOT: cq_template_mul_i32_hl_inv
; CHECK-NOT: cq_theta_si32
;
; Each gate adjointed ONCE and each rail freed ONCE — exactly 3 `_unc` (the two
; adds + the mul) and 4 frees (h3, h2, h1, h). A double-reversed shared prefix
; (the bug the WI-3 bail avoided) would show 4+ `_unc` / 5+ frees:
; UNC-COUNT-3: _unc(i32 %
; UNC-NOT:     _unc(i32 %
; FRE-COUNT-4: call void @cqrt_free(
; FRE-NOT:     call void @cqrt_free(
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 1.000000e-01)
  %h1 = add i32 %h, 1
  %h2 = add i32 %h1, 1                            ; dead terminal A (shares %h1)
  %h3 = mul i32 %h1, 2                            ; dead terminal B (shares %h1)
  ret void
}
