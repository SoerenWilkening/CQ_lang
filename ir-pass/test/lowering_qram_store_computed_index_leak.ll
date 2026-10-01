; lowering_qram_store_computed_index_leak.ll — the REFUSAL twins of
; lowering_qram_store_computed_index_discharged.ll (bd test_C_libtooling-r2j3.1).
; `ChainWalk::isInteriorConsumer` (b″) makes a QRAM store an interior consumer of
; the rails it reads in its flag/idx/val slots; these two functions pin what that
; row must NOT do.
;
; @premutated — the index is computed BEFORE a chained `cq_theta` on its source:
;     int t = q & 7;  q = cq_theta(q, .25);  arr[t] = 3;  ...  q = cq_theta(q, -.5);
; `t` is a record of the PRE-rotation `q`; after the first chained Ry no adjoint
; can return it to |0> (its `_unc` would recompute `q & 7` from a relabelled
; register — clause (d), owner ruling 2026-08-27). The interior planner's
; clause-(d) scan must refuse the component, so `t` is LEFT ALLOCATED (Rule 6) and
; the M-A guard reports it at the later gate — the program's own record, lowered
; with a warning (owner ruling 2026-08-29, bd lyyf). A mutant that dropped the
; borrowed-parent scan would discharge `t` after the store against the rotated
; `q` — a dirty free.
;
; @reversed — the store IS reversed (non-main; the load result is copied out and
; the dead local array uncomputes). Its index rail is then a DAG parent of the
; store's `_unc` and belongs to the dead-terminal spine, which runs first; the
; interior partition must not ALSO discharge it after the forward store (a second
; `_unc` and a use-after-free by the spine's `store_unc`). Pinned: exactly ONE
; `and_i32_hl_unc` of the store index, after `cqrt_qram_store_i32_unc`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --check-prefix=PRE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREET < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=REV < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=REVCNT < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @premutated(i32 %u) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %t = and i32 %q, 7                                          ; record of the PRE-rotation q
  %q1 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)  ; q moves before the store
  %zt = zext nneg i32 %t to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zt
  store i32 3, ptr %g, align 4
  %u2 = add nsw i32 %u, 2
  %p = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %pi = and i32 %p, 7
  %zp = zext nneg i32 %pi to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4
  %q2 = call i32 @cq_theta_si32(i32 %q1, double -5.000000e-01)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %v1 = add nsw i32 %v, 1
  %mv = call i32 @cq_measure_si32(i32 %v1)
  %s = add nsw i32 %mv, %mq
  ret i32 %s
}

define i32 @reversed(i32 %u) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %t = and i32 %q, 7
  %zt = zext nneg i32 %t to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zt
  store i32 5, ptr %g, align 4
  %u2 = add nsw i32 %u, 2
  %p = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %pi = and i32 %p, 7
  %zp = zext nneg i32 %pi to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; WARN: warning{{.*}}in function premutated{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning

; @premutated: `t` is minted, the source rotates, the store reads `t` — and `t` is
; never adjointed or freed anywhere in the function.
; PRE-LABEL: define i32 @premutated(
; PRE:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; PRE:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 7)
; PRE-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 2.500000e-01)
; PRE:      call void @cqrt_qram_store_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]], i32 %{{[a-zA-Z0-9_.]+}})
; PRE-NOT:  call void @cq_template_and_i32_hl_unc(i32 %[[T]],
; PRE:      ret i32
; NOFREET-LABEL: define i32 @premutated(
; NOFREET: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; NOFREET-NOT: call void @cqrt_free(i32 %[[T2]])
; NOFREET-LABEL: define i32 @reversed(

; @reversed: the spine reverses load and store, and the store index is discharged
; ONCE, by the spine, after `store_unc`.
; REV-LABEL: define i32 @reversed(
; REV:      %[[RQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; REV:      %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[RQ]], i32 7)
; REV:      call void @cqrt_qram_store_i32(i32 %[[RARR:[a-zA-Z0-9_.]+]], i32 %[[RT]], i32 %[[RV:[a-zA-Z0-9_.]+]])
; REV-NOT:  call void @cq_template_and_i32_hl_unc(i32 %[[RT]],
; REV:      call void @cqrt_qram_store_i32_unc(i32 %[[RARR]], i32 %[[RT]], i32 %[[RV]])
; REV-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[RT]], i32 %[[RQ]], i32 7)
; REV-NEXT: call void @cqrt_free(i32 %[[RT]])
; REV-NOT:  call void @cq_template_and_i32_hl_unc(i32 %[[RT]],
; REV:      ret i32
; Exactly two `and` discharges in @reversed (the load index's and the store
; index's), both by the spine's reversal:
; REVCNT-LABEL: define i32 @reversed(
; REVCNT-COUNT-2: call void @cq_template_and_i32_hl_unc(
; REVCNT-NOT:     call void @cq_template_and_i32_hl_unc(
