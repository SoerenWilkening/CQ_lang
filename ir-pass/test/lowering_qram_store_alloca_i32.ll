; lowering_qram_store_alloca_i32.ll — ACCEPT (Phase 7.5 Inc 2 + bug sxuk): an
; alloca-backed tainted-index STORE + LOAD (Shadow-shaped) `arr[q]=v; … arr[p] …;
; measure`. Once a dynamic access forces the `alloca [8 x i32]` to survive clang -O1
; (a static-index array is SROA'd away, §1), the tainted store/load survive. Lowers
; to one `cqrt_qram_alloc_i32` (a TAINTED in-place-mutated array register) + a
; materialized basis-state value handle (`cqrt_alloc_i32(7)`) + `cqrt_qram_store_i32`
; (void in-place on the array handle) + `cqrt_qram_load_i32` (Toffoli-copy-out).
;
; sxuk: the loaded value DIRECTLY escapes (the user measures it) in a non-main fn —
; a LOCAL scratch array. WITHOUT the fix the loaded value is the sole data terminal,
; FreePoint classifies it Measured, and the whole reversal — including the array's
; STORES — is skipped, leaving the measured value entangled with the leaked dirty
; array (a dephasing silent miscompile). The fix copies the loaded value out to a
; kept carrier (`cqrt_alloc_i32(0)` + `cqrt_copy_i32`), which the user measures, so
; the load+store chain uncomputes (method-B): `cqrt_qram_load_i32_unc` then
; `cqrt_qram_store_i32_unc`, the index rotation rails reverse-play and are then LEFT
; ALLOCATED (frozen by the bd 5pio record freeze — they used to be freed; the
; `CHECK-NOT`s below are the pin, and this header formerly contradicted them), and the
; array handle is left allocated but CLEAN |0> (a classical resource, never freed,
; §2.9). NO measurement is inserted that the user did not write (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @shadow_store_load(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %arr)
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)   ; zero-init
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 7, ptr %gq, align 4                ; arr[q] = 7  (classical value)
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  %v = load i32, ptr %gp, align 4              ; arr[p]  (tainted-index load)
  %m = call i32 @cq_measure_si32(i32 %v)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %arr)
  ret i32 %m
}

; The array handle is born once at entry (count 8); the classical store value is
; materialized into a basis-state handle; the store is void in-place; the load copies
; the cell out into a fresh value handle:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IQ:[a-zA-Z0-9_.]+]], i32 %[[VAL]])
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IP:[a-zA-Z0-9_.]+]])
; sxuk method-B copy-out: the loaded value is copied to a kept |0> carrier, which is
; what the user measures (so the load+store chain can uncompute):
; CHECK:     %[[RET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[V]], i32 %[[RET]])
; The local array uncomputes: the load + store reverse (cells back to |0>); the array
; handle is NEVER freed (a classical resource, §2.9):
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[IP]])
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[IQ]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
;
; THE INDEX ROOTS ARE FROZEN, NOT FREED (bd 5pio, owner ruling 2026-08-11), and this
; is the LIT-layer pin for the ancestor half of that freeze. `%[[V]]` — the copy
; SOURCE — is a `cqrt_qram_load_<W>` result, a basis permutation of arr/idx, so it
; stays freeable and IS freed above. Its ANCESTORS `%[[IP]]`/`%[[IQ]]` reach the kept
; carrier `%[[RET]]` through it, and their own gate is `cqrt_ry_`, which is not a
; basis permutation — so they are fully reverse-played and then LEFT ALLOCATED.
; Freeing them would be a hidden measurement of a rail the carrier is entangled with
; (Rules 6/8).
;
; These are DISCRIMINATION CONTROLS, and the pin matters because of how the change was
; found to be invisible: 8 of the 9 lit fixtures this ruling moved changed SILENTLY —
; only one had a CHECK pinning any removed free, so the lit layer could not witness
; the ancestor freeze at all and only the e2e goldens moved. Pre-ruling the pass
; emitted `cqrt_free(%[[IP]])` and `cqrt_free(%[[IQ]])` on the two lines immediately
; before the measure below, so this window catches a revert.
; CHECK-NOT: call void @cqrt_free(i32 %[[IP]])
; CHECK-NOT: call void @cqrt_free(i32 %[[IQ]])
; The carrier — NOT the loaded value — is what gets measured:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[RET]])
; CHECK-NOT: alloca
; CHECK-NOT: getelementptr
; CHECK-NOT: = load
; CHECK-NOT: llvm.memset
; CHECK-NOT: cq taint escape
