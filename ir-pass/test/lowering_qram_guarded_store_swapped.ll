; lowering_qram_guarded_store_swapped.ll — ACCEPT (g5gi): a guarded Shadow store
; whose arm is the FALSE successor of the branch. `clang -O1` canonicalizes
; `if (q != 3) { arr[i] = 7; }` to `icmp eq; br eq, %merge, %arm` (Rule 9): the
; side-effect-only store arm is the FALSE successor, so the store must fire on
; `¬(q==3)` = `q!=3`.
;
; g5gi lowers this by a NEGATED MINT — the path-predicate flag is minted with the
; INVERSE predicate (`icmp eq` → `icmp ne`), so `flag = [q!=3]` fires the guarded
; store exactly on the taken (false) edge. NO `cqrt_x` bracket: the whole-DAG LIFO
; uncompute reverses the negated compare via its own `_unc`
; (`cq_template_icmp_ne_i32_hl_unc`) IDENTICALLY to the un-negated case — only the
; predicate string differs. The store-reverse-then-strip order (the pred-lifetime
; invariant) is preserved. The array handle is NEVER freed (§2.9); NO measurement
; is inserted the user did not write (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @swapped(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp eq i32 %q, 3
  br i1 %f, label %merge, label %arm              ; store arm is the FALSE successor

arm:
  %si = sext i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; Forward: array birth, the NEGATED flag mint (`ne`, not `eq`), the store value
; handle, then the GUARDED store (flag arg 0). The diamond is FLATTENED:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call void @cqrt_qram_store_i32_controlled(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[IDX:[a-zA-Z0-9_.]+]], i32 %[[VAL]])
; The post-diamond load is accepted (unconditional) and copied out to a kept carrier:
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[Q]])
; CHECK:     %[[RET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[V]], i32 %[[RET]])
; Reversal (LIFO): load_unc + free, then the GUARDED store `_controlled_unc` with the
; flag STILL LIVE (arg 0), then the NEGATED-predicate flag STRIP, then free — the
; store-reverse-BEFORE-strip order is the pred-lifetime invariant:
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[Q]])
; CHECK:     call void @cqrt_qram_store_i32_controlled_unc(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[IDX]], i32 %[[VAL]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[FLAG]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; The carrier is measured; the array handle is NEVER freed (a classical resource):
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[RET]])
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
; The diamond, the raw store, and the raw compare are all gone; no un-negated `eq`
; flag survives (the mint is `ne`):
; CHECK-NOT: br i1
; CHECK-NOT: store i32
; CHECK-NOT: = icmp
; CHECK-NOT: cq_template_icmp_eq
; CHECK-NOT: cq taint escape
