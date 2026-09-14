; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/ob1d_guarded_runtime_cond.ll'
source_filename = "src/ob1d_guarded_runtime_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !18, !DIExpression(), !29)
    #dbg_value(ptr %1, !19, !DIExpression(), !29)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !30
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !30
    #dbg_value(i32 %h, !20, !DIExpression(), !29)
    #dbg_value(i32 0, !21, !DIExpression(), !29)
    #dbg_value(i32 0, !22, !DIExpression(), !31)
  br label %4, !dbg !32

3:                                                ; preds = %9
  ret i32 %11, !dbg !33

4:                                                ; preds = %9, %2
  %5 = phi i32 [ 0, %2 ], [ %11, %9 ]
  %6 = phi i32 [ 0, %2 ], [ %12, %9 ]
    #dbg_value(i32 %5, !21, !DIExpression(), !29)
    #dbg_value(i32 %6, !22, !DIExpression(), !31)
  %7 = icmp slt i32 %6, %0, !dbg !34
  br i1 %7, label %8, label %9, !dbg !35

8:                                                ; preds = %4
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !36
    #dbg_value(i32 %h, !24, !DIExpression(), !37)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !38
    #dbg_value(!DIArgList(i32 %5, i32 %m), !21, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !29)
  br label %9, !dbg !39

9:                                                ; preds = %8, %4
  %10 = phi i32 [ %m, %8 ], [ 1, %4 ]
  %11 = add nsw i32 %10, %5, !dbg !40
    #dbg_value(i32 %11, !21, !DIExpression(), !29)
  %12 = add nuw nsw i32 %6, 1, !dbg !41
    #dbg_value(i32 %12, !22, !DIExpression(), !31)
  %13 = icmp eq i32 %12, 3, !dbg !42
  br i1 %13, label %3, label %4, !dbg !32, !llvm.loop !43
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "src/ob1d_guarded_runtime_cond.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "f4e2f5b8352bc9b7f41ac7895e4fa234")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !14}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!17 = !{!18, !19, !20, !21, !22, !24}
!18 = !DILocalVariable(name: "argc", arg: 1, scope: !10, file: !8, line: 4, type: !13)
!19 = !DILocalVariable(name: "argv", arg: 2, scope: !10, file: !8, line: 4, type: !14)
!20 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!21 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!22 = !DILocalVariable(name: "i", scope: !23, file: !8, line: 5, type: !13)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!24 = !DILocalVariable(name: "b", scope: !25, file: !8, line: 5, type: !13)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 5, column: 35)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 5, column: 28)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 5, column: 23)
!28 = distinct !DILexicalBlock(scope: !23, file: !8, line: 5, column: 3)
!29 = !DILocation(line: 0, scope: !10)
!30 = !DILocation(line: 4, column: 52, scope: !10)
!31 = !DILocation(line: 0, scope: !23)
!32 = !DILocation(line: 5, column: 3, scope: !23)
!33 = !DILocation(line: 6, column: 3, scope: !10)
!34 = !DILocation(line: 5, column: 29, scope: !26)
!35 = !DILocation(line: 5, column: 28, scope: !27)
!36 = !DILocation(line: 5, column: 43, scope: !25)
!37 = !DILocation(line: 0, scope: !25)
!38 = !DILocation(line: 5, column: 63, scope: !25)
!39 = !DILocation(line: 5, column: 78, scope: !25)
!40 = !DILocation(line: 5, scope: !26)
!41 = !DILocation(line: 5, column: 20, scope: !28)
!42 = !DILocation(line: 5, column: 16, scope: !28)
!43 = distinct !{!43, !32, !44, !45, !46}
!44 = !DILocation(line: 5, column: 91, scope: !23)
!45 = !{!"llvm.loop.mustprogress"}
!46 = !{!"llvm.loop.unroll.disable"}
