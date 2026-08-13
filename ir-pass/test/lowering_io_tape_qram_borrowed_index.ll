; lowering_io_tape_qram_borrowed_index.ll — ACCEPT (Phase 7.5 + 7.6). The QRAM
; instance of the bd 261j(a) interleaved-rotation defect, and coverage for the
; `cqrt_qram_load_` / `cqrt_qram_store_` arms of `preservesBasisUnderRecord`, which
; the Rule-13 round found had ZERO fixture coverage.
;
; THE SHAPE. A QRAM load BORROWS the index rail %IDX, and an in-place `cqrt_ry`
; lands on %IDX AFTER the load; the loaded value is then TAPED:
;     %IDX = x & 3 ; store(arr, %IDX^1, k) ; %U = load(arr, %IDX)
;     ry(%IDX, 0.25) ; tape(%U)
; From ordinary C (clang -O1):
;     int arr[4]={0,0,0,0}; int i0 = cq_theta(seed,0.5) & 3;
;     arr[(i0^1)&3] = k; int u = arr[i0]; (void)cq_theta(i0,0.25); printf("%d", u);
;
; WHY IT IS THE NASTIEST INSTANCE. The victim %U is the RECORDED rail itself —
; Recorded, Correlated, and deliberately NOT frozen, because `preservesBasisUnderRecord`
; accepts `cqrt_qram_load_` via `isTemplateProducer`. So the defect sat INSIDE the
; freeze's own seed set, not at its edge, and no lens that reasoned about "rails
; outside Correlated" could reach it. The first implementation skipped %IDX's
; rotation adjoint, so `cqrt_qram_load_i32_unc(%U, %ARR, %IDX)` popped the cell at a
; POST-rotation index while %U had been filled from the PRE-rotation one — %U was
; not zeroed and `cqrt_free(%U)` was a hidden measurement. The companion half is
; just as bad and has no free at all to flag it: `cqrt_qram_store_i32_unc` firing
; against a rotated index un-stores the WRONG cell, leaving %ARR dirty AND entangled
; with the kept tape (Rule 8) — a wrong unitary that both shipped gates pass.
;
; WHAT THIS PINS. Every adjoint is emitted, in reverse program order, so
; `ry(%IDX,-0.25)` lands BEFORE both `_unc`s and both read the index at its
; producer-time value. %U and the xor rail then free soundly (stage 2b: 2 verified,
; strict); %IDX and its Ry root freeze and are never freed; %ARR is never freed at
; all (a QRAM array handle never is).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEARR < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEIDX < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0, i32 %k) {
entry:
  %arr = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %arr, i8 0, i64 16, i1 false)
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = and i32 %q, 3
  %j   = xor i32 %idx, 1
  %je  = zext nneg i32 %j to i64
  %pj  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %je
  store i32 %k, ptr %pj, align 4
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %ie
  %u   = load i32, ptr %pi, align 4
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)
  %z   = call i32 (ptr, ...) @printf(ptr @.str, i32 %u)
  ret void
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 3)
; CHECK:     %[[J:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[IDX]], i32 1)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[J]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[U:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IDX]])
; The interleaved rotation on the BORROWED index, after the load:
; CHECK:     call void @cqrt_ry_i32(i32 %[[IDX]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[U]])
; THE LOAD-BEARING LINE: the index is restored BEFORE either `_unc` reads it:
; CHECK:     call void @cqrt_ry_i32(i32 %[[IDX]], double -2.500000e-01)
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[U]], i32 %[[ARR]], i32 %[[IDX]])
; CHECK:     call void @cqrt_free(i32 %[[U]])
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[J]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cq_template_xor_i32_hl_unc(i32 %[[J]], i32 %[[IDX]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[J]])
; CHECK:     call void @cq_template_and_i32_hl_unc(i32 %[[IDX]], i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; The frozen index rail, its Ry root, and the array are never freed. ONE PREFIX PER
; HANDLE — a CHECK-NOT is bounded by the next positive directive of its own prefix,
; so three guards in one prefix leave the first two dead (see
; lowering_io_tape_partial_freeze_order.ll's header for the history).
; NOFREEARR:     %[[ARR2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; NOFREEARR-NOT: call void @cqrt_free(i32 %[[ARR2]])
; NOFREEH:       %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREEH-NOT:   call void @cqrt_free(i32 %[[H2]])
; NOFREEIDX:     %[[IDX2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; NOFREEIDX-NOT: call void @cqrt_free(i32 %[[IDX2]])
