; carried_fence_window.ll — cq-merge-selftest input (NOT a lit test: `Inputs/`
; is excluded; ctest `ir-pass-merge-discharge-selftest` runs it). bd
; test_C_libtooling-01po.19 S5: `handleAliases`' MEMORY HOP admits a
; `!cq.railwindow` handle array (the S4 window arrays), with the whole array
; family as the class (`railWindowFamily`: every cell read and every stored
; rail — array-granular, a superset of any one cell). Before S5 the hop refused
; every window store ("parked in memory"), so a merge rail parked in a window
; cell had no alias class at all and the carried-merge fence failed closed on
; the QUIET control below too. These are carried_fence_bank.ll's two
; memory-carried cases with the bank replaced by a window array:
;   * memcarried_window_kept      the rail carried through a window cell; the
;                                 recorded condition is only measured (quiet);
;   * memcarried_window_cond_ry_loud  a Ry on the recorded condition inside the
;                                 loop: loud at the tagged call;
;   * fresh_park_two_memories_loud  (review S5 B-F2) a rail parked in a window
;                                 cell AND a rail bank, coupled through the bank
;                                 spelling, then rotated: loud.
; The `freshAt` store skip (MergeCarriedFenceFresh.h ⚠) stays sound: a park
; into a window cell moves no state, and every later coupling of that cell's
; rail is a use of a cell read, which the family puts in the class.

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_free(i32)
declare void @cqrt_cnot(i32, i32)
declare i32 @cqrt_measure_i32(i32)

define i32 @memcarried_window_cond_ry_loud(i32 %u) #0 !dbg !908 {
entry:
  %win = alloca i32, i64 4, align 4, !cq.railwindow !2
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  store i32 %seed, ptr %win, align 4
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %ci = getelementptr i32, ptr %win, i64 %i
  %a = load i32, ptr %ci, align 4
  %ii = trunc i64 %i to i32
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %ii)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %ii)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i64 %i, 1
  %cn = getelementptr i32, ptr %win, i64 %i1
  store i32 %out, ptr %cn, align 4
  call void @cqrt_ry_i32(i32 %h, double 2.000000e-01), !cq.selftest.fires !0, !dbg !909
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}

define i32 @memcarried_window_kept(i32 %u) #1 {
entry:
  %win = alloca i32, i64 4, align 4, !cq.railwindow !2
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  store i32 %seed, ptr %win, align 4
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %ci = getelementptr i32, ptr %win, i64 %i
  %a = load i32, ptr %ci, align 4
  %ii = trunc i64 %i to i32
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %ii)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %ii)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i64 %i, 1
  %cn = getelementptr i32, ptr %win, i64 %i1
  store i32 %out, ptr %cn, align 4
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}

; review S5 B-F2 (L2): the memory hop's window skip must ask THIS store's
; pointer, not "is V stored into some window". %g is parked in a window cell
; AND in a rail bank; the bank spelling %gb is CNOT-coupled to the recorded
; condition %h, then %g is rotated. Asked of "any window store", both parks
; were skipped, %gb never joined %g's class and freshness cleared the Ry.
define i32 @fresh_park_two_memories_loud(i32 %u) #0 !dbg !910 {
entry:
  %win = alloca i32, i64 2, align 4, !cq.railwindow !2
  %bank = alloca [1 x i32], align 4, !cq.railbank !3
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %g = call i32 @cqrt_alloc_i32(i32 0)
  store i32 %g, ptr %win, align 4
  %b0 = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %g, ptr %b0, align 4
  %gb = load i32, ptr %b0, align 4
  call void @cqrt_cnot(i32 %h, i32 %gb)
  call void @cqrt_ry_i32(i32 %g, double 3.000000e-01), !cq.selftest.fires !0, !dbg !911
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %m2 = call i32 @cqrt_measure_i32(i32 %g)
  %r0 = add nsw i32 %m1, %m
  %r = add nsw i32 %r0, %m2
  ret i32 %r
}

attributes #0 = { "cq-selftest-expect"="loud" "cq-selftest-message"="cq merge discharge: non-diagonal gate on a register a leaked loop-carried merge rail records" }
attributes #1 = { "cq-selftest-expect"="kept" }

!0 = !{}
!2 = !{i32 32}
!3 = !{i32 1}

; debug info: only the tagged call carries a !dbg line (cq-merge-selftest
; checks the diagnostic fired at that line).
!llvm.dbg.cu = !{!890}
!llvm.module.flags = !{!891}
!890 = distinct !DICompileUnit(language: DW_LANG_C11, file: !892, producer: "hand", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!891 = !{i32 2, !"Debug Info Version", i32 3}
!892 = !DIFile(filename: "carried_fence_window.ll", directory: "ir-pass/test/Inputs/merge_selftest")
!893 = !DISubroutineType(types: !{})
!908 = distinct !DISubprogram(name: "memcarried_window_cond_ry_loud", scope: !892, file: !892, line: 104, type: !893, scopeLine: 104, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!909 = !DILocation(line: 104, scope: !908)
!910 = distinct !DISubprogram(name: "fresh_park_two_memories_loud", scope: !892, file: !892, line: 105, type: !893, scopeLine: 105, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!911 = !DILocation(line: 105, scope: !910)
