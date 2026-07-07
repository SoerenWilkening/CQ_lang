; lowering_reject_qram_guarded_store_cond_mem.ll — DECLINE (iw81.7, §3c): a guarded
; Shadow store whose branch CONDITION reads memory (`if (b[i] < 3) { a[i] = 7; }`).
; The path-predicate flag is derived from a loaded cell; a store could then be writing
; a cell the flag was computed from (the flag would reference a clobbered value — the
; control's-own-data clobber hazard, information-theoretically unfixable). v1 declines
; ANY condition whose tainted lineage contains a load (conservative — over-declining is
; safe; the common theta-compare condition has no load and accepts).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @cond_mem(i32 %u0, i32 %u1) {
entry:
  %a = alloca [8 x i32], align 16
  %b = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 32, i1 false)
  call void @llvm.memset.p0.i64(ptr align 16 %b, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %sib = sext i32 %i to i64
  %gb = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 %sib
  %bi = load i32, ptr %gb, align 4                ; condition reads memory (b[i])
  %f = icmp slt i32 %bi, 3
  br i1 %f, label %arm, label %merge

arm:
  %sia = sext i32 %i to i64
  %ga = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 %sia
  store i32 7, ptr %ga, align 4                   ; a[i] = 7 — guarded on b[i]<3
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: cq controlled lowering: guarded store whose condition reads memory under quantum control
