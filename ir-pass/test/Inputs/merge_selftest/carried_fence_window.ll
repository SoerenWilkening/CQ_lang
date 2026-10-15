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
;                                 loop: loud at the tagged call.
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

attributes #0 = { "cq-selftest-expect"="loud" "cq-selftest-message"="cq merge discharge: non-diagonal gate on a register a leaked loop-carried merge rail records" }
attributes #1 = { "cq-selftest-expect"="kept" }

!0 = !{}
!2 = !{i32 32}

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
