; lowering_live_record_sibling_qram_store_load_measure_accept.ll — ACCEPT: the
; STORE→ARRAY→LOAD hop reaches an observing sink (M-A, bd
; test_C_libtooling-6uqc; the F1 ruling, 2026-08-28).
;
; SOURCE — lowering_reject_live_record_qram_store_no_readback.ll plus a read-back:
;     int arr[8] = {0};
;     a = cq_theta(a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // the SIBLING
;     p = cq_theta(p, 0.25);             // an independent superposed INDEX
;     w = cq_theta(w, 0.5);              // T — chained, in-place Ry on the wire
;     arr[p] = c;                        // HOP: value into the cell
;     int v  = arr[p];                   // HOP: cell back out       <-- the difference
;     int mv = cq_measure(v);            // SINK                     <-- the difference
;     int y  = a * 5;
;     return mv + cq_measure(y) + cq_measure(w);
;
; WHY IT LOWERS. `%h_op3` (`c`) is the same undischarged, entangled rail that the
; reject twin declines on; what changed is that the value it carries is now
; READABLE. Clause 3's walk follows the chain the compiler actually emits:
;     `cqrt_qram_store_i32(%arr, %idx, c)`   — the VALUE slot, a HOP through the array
;  -> `cqrt_qram_load_i32(%arr, %idx)`       — a later load on the SAME array handle
;  -> `cqrt_copy_i32(%load, %qret)`          — the 7.5 direct-measure copy-out, SRC->DST
;  -> `cqrt_measure_i32(%qret)`              — the OBSERVING SINK
; so `c` is the program's own live data and its dephasing of the rotation is
; source semantics (owner ruling 2026-08-27 (1)).
;
; "SUBSEQUENT" IS A PROOF, NOT AN ORDERING GUESS: only loads with
; `provablyBefore(store, load)` are followed — a load that already ran read the
; old cell contents and cannot observe what the store put there.
;
; NOTE WHAT THIS FIXTURE DOES **NOT** WIDEN. The QRAM ARRAY handle
; (`cqrt_qram_alloc_i32`) is still the ruled-DEFERRED record class (owner
; 2026-08-27, second round, point 4) — it is never pushed as a record and the
; record walk never follows a store into a cell. That deferral is about what
; counts AGAINST the gate; this hop is about whether a user can still SEE a value,
; which is the opposite question and the opposite safety direction.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %c   = mul i32 %q, 3                                          ; the SIBLING — read back below
  %p   = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)  ; independent index wire
  %q2  = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %is  = sext i32 %p to i64
  %gs  = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %is
  store i32 %c, ptr %gs, align 4
  %il  = sext i32 %p to i64
  %gl  = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %il
  %v   = load i32, ptr %gl, align 4                             ; the READ-BACK
  %mv  = call i32 @cq_measure_si32(i32 %v)                      ; the OBSERVING SINK
  %y   = mul i32 %q, 5
  %my  = call i32 @cq_measure_si32(i32 %y)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  %a   = add nsw i32 %mv, %my
  %r   = add nsw i32 %a, %m
  ret i32 %r
}

; The whole hop chain, in emission order:
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[C]])
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32(i32 %[[V]], i32 %[[OUT]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT:  cq rotation lowering

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
