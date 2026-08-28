; lowering_io_tape_qram_borrowed_index.ll — ACCEPT (Phase 7.5 + 7.6). The QRAM
; instance of the bd 261j(a) interleaved-rotation defect, and coverage for the
; `cqrt_qram_load_` / `cqrt_qram_store_` arms of `preservesBasisUnderRecord`, which
; the Rule-13 round found had ZERO fixture coverage.
;
; THE SHAPE. A QRAM load BORROWS the index rail %IDX, and an in-place `cqrt_ry`
; lands on %IDX AFTER the load; the loaded value is then TAPED:
;     %IDX = x & 3 ; store(arr, %IDX, k) ; %U = load(arr, %IDX)
;     ry(%IDX, 0.25) ; tape(%U)
; From ordinary C (clang -O1):
;     int arr[4]={0,0,0,0}; int i0 = cq_theta(seed,0.5) & 3;
;     arr[i0] = k; int u = arr[i0]; (void)cq_theta(i0,0.25); printf("%d", u);
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
; producer-time value. %U then frees soundly; %IDX and its Ry root freeze and are
; never freed; %ARR is never freed at all (a QRAM array handle never is).
;
; ── THE `%A = q * 7` LINE IS NOT DECORATION (M-A Increment 3, bd
; test_C_libtooling-6uqc). READ THIS BEFORE DELETING IT. ───────────────────────
; It is a template READ of the ROOT rail %H emitted AFTER the gate whose result is
; taped, i.e. an OBSERVING data use of %H after `T`. Without it this module DECLINES
; with
;     cq rotation lowering: non-diagonal gate over a live derived record
; and CORRECTLY so: at `cqrt_ry_i32(%IDX, 0.25)` the root %H (|a>) is a live,
; undischarged basis record of the index wire (|a&3|), so the wire's reduced state
; is diagonal and the in-place Ry acts on a mixture. Census 0.1 forecast this exact
; module (SPIKE §2R.5, spine-aware column — %H's only post-`T` mentions are the
; spine's own `and_unc` read and its adjoint `cqrt_ry(%H,-0.5)`), and the owner
; ruled that reading in (§2R.5a, 2026-08-27). With %A present, %H is the program's
; own live data (clause 3) and the accept is by principle. EVERYTHING THIS FIXTURE
; PINS IS BYTE-FOR-BYTE UNCHANGED (measured): the interleaved `ry(%IDX,0.25)` after
; the load, `ry(%IDX,-0.25)` landing BEFORE both `_unc`s, `free(%U)`, and %ARR /
; %H / %IDX never freed. The negative form of this hazard is
; lowering_reject_live_record_io_tape_chained_theta.ll (the canonical §2R.5 case).
;
; THE STORE GOES THROUGH THE SAME INDEX, and that is a deliberate 2026-08-28 edit,
; not a simplification. The original body stored at `%IDX^1`, which minted an
; `cq_template_xor_i32_hl` rail — a DEAD descendant record of the index wire at
; the moment `cqrt_ry(%IDX, 0.25)` fires — so the M-A Increment 1 live-record
; guard declines it. That decline is a KNOWN, DELIBERATE OVER-DECLINE (the
; dephasing provably cancels in that module) and it is pinned, with the full
; argument, by the negative twin
; lowering_reject_live_record_qram_borrowed_index_xor.ll. Dropping the xor leg
; here keeps this fixture doing its own job — pinning the interleaved-rotation
; adjoint ORDER — without also pinning an unrelated verdict.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEARR < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEIDX < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
@.str = private constant [6 x i8] c"%d %d\00"

define void @slice(i32 %u0, i32 %k) {
entry:
  %arr = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %arr, i8 0, i64 16, i1 false)
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = and i32 %q, 3
  %je  = zext nneg i32 %idx to i64
  %pj  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %je
  store i32 %k, ptr %pj, align 4
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %ie
  %u   = load i32, ptr %pi, align 4
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)
  %a   = mul i32 %q, 7                                         ; %H read AFTER the gate
  %z   = call i32 (ptr, ...) @printf(ptr @.str, i32 %u, i32 %a)
  ret void
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IDX]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[U:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IDX]])
; The interleaved rotation on the BORROWED index, after the load:
; CHECK:     call void @cqrt_ry_i32(i32 %[[IDX]], double 2.500000e-01)
; The post-gate liveness read of the ROOT (see the Increment-3 note above):
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[U]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[A]])
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; THE LOAD-BEARING LINE: the index is restored BEFORE either `_unc` reads it:
; CHECK:     call void @cqrt_ry_i32(i32 %[[IDX]], double -2.500000e-01)
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[U]], i32 %[[ARR]], i32 %[[IDX]])
; CHECK:     call void @cqrt_free(i32 %[[U]])
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[IDX]], i32 %{{[a-zA-Z0-9_.]+}})
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
