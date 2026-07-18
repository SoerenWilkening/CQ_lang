; spec_accept_qram_read.ll — bd 20xt.4 Inc 1: a const-global tainted-index QROM
; read (`tbl[id]`) inside a Phase-6 spec-clone body. This is the spec-callee edition
; of the top-level Phase-7.5 QROM read: `scanBody` admits the gep+load SHAPE
; (`qromReadShapeInScope`, the same `matchQramAccess` structure the emitter
; re-proves — Rule 14), the clone's `lowerQramReads` (under `cloneTaint`,
; `inBennettClone=true` so the top-level coherent-return fence is skipped — the
; wrap handles the escape) lowers it to `cqrt_qram_alloc_f64` (array-handle birth,
; at the clone entry — a CLASSICAL resource token, never freed) + `cqrt_qram_load_f64`
; (Toffoli copy-out), and the Bennett wrap CAPTURES the load: reversed via
; `cqrt_qram_load_f64_unc` (out-first, un-copies the dead value rail using the
; preserved cell) then the value rail is freed clean.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

@T = internal unnamed_addr constant [4 x double] [double 1.500000e+00, double 2.500000e+00, double 3.500000e+00, double 4.500000e+00], align 16

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

; A pure-classical callee with a STRAIGHT-LINE const-global tainted-index read.
define internal double @lookup(double %x) {
entry:
  %i = fptosi double %x to i32
  %m = and i32 %i, 3               ; index masked in-bounds [0,3]
  %idx = zext i32 %m to i64        ; at the pointer-index width (clang -O1 form)
  %p = getelementptr inbounds [4 x double], ptr @T, i64 0, i64 %idx
  %v = load double, ptr %p, align 8
  %r = fadd double %v, %x
  ret double %r
}

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Caller: theta lowered to alloc+ry; the call retargets to the mangled clone.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_lookup_1(i32 %[[H]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[R]])
;
; Clone: array-handle birth at entry, the qram load, the fadd consumer, then the
; Bennett stream — copy-out, reverse (fadd_unc, LOAD_unc, and_unc, fptosi_unc),
; and the scratch frees. The array handle is NEVER a cqrt_free operand.
; CHECK:     define internal {{.*}}i32 @__cq_q_lookup_1(i32 %x)
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:     %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %[[IDX]])
; CHECK:     %[[SUM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64(i32 %[[V]], i32 %x)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %[[SUM]], i32 %[[OUT]])
; CHECK:     call void @cq_template_fadd_f64_unc(i32 %[[SUM]], i32 %[[V]], i32 %x)
; CHECK:     call void @cqrt_qram_load_f64_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[IDX]])
; CHECK:     call void @cq_template_and_i32_hl_unc(i32 %[[IDX]], i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:     call void @cqrt_free(i32 %[[V]])
; CHECK:     ret i32 %[[OUT]]
;
; The original memory access is gone; the array handle leaks (never freed); the
; load's `_unc` is the reverse form, never a fresh-minting `_inv`.
; CHECK-NOT: load double
; CHECK-NOT: cqrt_free(i32 %[[ARR]])
; CHECK-NOT: cqrt_qram_load_f64_inv
