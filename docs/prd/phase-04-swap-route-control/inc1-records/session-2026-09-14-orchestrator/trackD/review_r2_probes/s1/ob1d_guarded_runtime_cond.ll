; ModuleID = 'src/ob1d_guarded_runtime_cond.c'
source_filename = "src/ob1d_guarded_runtime_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !18, !DIExpression(), !29)
    #dbg_value(ptr %1, !19, !DIExpression(), !29)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !30
    #dbg_value(i32 %3, !20, !DIExpression(), !29)
    #dbg_value(i32 0, !21, !DIExpression(), !29)
    #dbg_value(i32 0, !22, !DIExpression(), !31)
  br label %5, !dbg !32

4:                                                ; preds = %12
  ret i32 %14, !dbg !33

5:                                                ; preds = %2, %12
  %6 = phi i32 [ 0, %2 ], [ %14, %12 ]
  %7 = phi i32 [ 0, %2 ], [ %15, %12 ]
    #dbg_value(i32 %6, !21, !DIExpression(), !29)
    #dbg_value(i32 %7, !22, !DIExpression(), !31)
  %8 = icmp slt i32 %7, %0, !dbg !34
  br i1 %8, label %9, label %12, !dbg !35

9:                                                ; preds = %5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.000000e-01) #2, !dbg !36
    #dbg_value(i32 %10, !24, !DIExpression(), !37)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !38
    #dbg_value(!DIArgList(i32 %6, i32 %11), !21, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !29)
  br label %12, !dbg !39

12:                                               ; preds = %5, %9
  %13 = phi i32 [ %11, %9 ], [ 1, %5 ]
  %14 = add nsw i32 %13, %6, !dbg !40
    #dbg_value(i32 %14, !21, !DIExpression(), !29)
  %15 = add nuw nsw i32 %7, 1, !dbg !41
    #dbg_value(i32 %15, !22, !DIExpression(), !31)
  %16 = icmp eq i32 %15, 3, !dbg !42
  br i1 %16, label %4, label %5, !dbg !32, !llvm.loop !43
}

declare !dbg !47 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !52 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
!47 = !DISubprogram(name: "cq_theta_si32", scope: !48, file: !48, line: 38, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13, !51}
!51 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!52 = !DISubprogram(name: "cq_measure_si32", scope: !48, file: !48, line: 83, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DISubroutineType(types: !54)
!54 = !{!13, !13}
