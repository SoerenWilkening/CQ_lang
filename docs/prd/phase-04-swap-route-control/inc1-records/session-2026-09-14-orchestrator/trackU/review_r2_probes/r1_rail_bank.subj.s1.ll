; ModuleID = 'r1_rail_bank.c'
source_filename = "r1_rail_bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca [2 x i8], align 1
    #dbg_value(i32 5, !15, !DIExpression(), !23)
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %1) #3, !dbg !24
    #dbg_declare(ptr %1, !16, !DIExpression(), !25)
    #dbg_value(i32 0, !21, !DIExpression(), !26)
  br label %13, !dbg !27

2:                                                ; preds = %13
  %3 = load i8, ptr %1, align 1, !dbg !28, !tbaa !29, !range !33, !noundef !34
  %4 = trunc nuw i8 %3 to i1, !dbg !28
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #3, !dbg !28
  %6 = zext i1 %5 to i32, !dbg !28
  %7 = getelementptr inbounds i8, ptr %1, i64 1, !dbg !35
  %8 = load i8, ptr %7, align 1, !dbg !35, !tbaa !29, !range !33, !noundef !34
  %9 = trunc nuw i8 %8 to i1, !dbg !35
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9) #3, !dbg !35
  %11 = zext i1 %10 to i32, !dbg !35
  %12 = add nuw nsw i32 %11, %6, !dbg !36
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %1) #3, !dbg !37
  ret i32 %12, !dbg !38

13:                                               ; preds = %0, %13
  %14 = phi i64 [ 0, %0 ], [ %20, %13 ]
    #dbg_value(i64 %14, !21, !DIExpression(), !26)
  %15 = getelementptr inbounds [2 x i8], ptr %1, i64 0, i64 %14, !dbg !39
  %16 = load i8, ptr %15, align 1, !dbg !39, !tbaa !29, !range !33, !noundef !34
  %17 = trunc nuw i8 %16 to i1, !dbg !39
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 5.000000e-01) #3, !dbg !39
  %19 = zext i1 %18 to i8, !dbg !44
  store i8 %19, ptr %15, align 1, !dbg !44, !tbaa !29
  %20 = add nuw nsw i64 %14, 1, !dbg !45
    #dbg_value(i64 %20, !21, !DIExpression(), !26)
  %21 = icmp eq i64 %14, 0, !dbg !46
  br i1 %21, label %13, label %2, !dbg !27, !llvm.loop !47
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !51 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare !dbg !56 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "r1_rail_bank.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "58ce3d4fbe24323767a530f038f73007")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !21}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 5, type: !17)
!17 = !DICompositeType(tag: DW_TAG_array_type, baseType: !18, size: 16, elements: !19)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !{!20}
!20 = !DISubrange(count: 2)
!21 = !DILocalVariable(name: "i", scope: !22, file: !8, line: 6, type: !13)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 5, column: 16, scope: !10)
!25 = !DILocation(line: 5, column: 21, scope: !10)
!26 = !DILocation(line: 0, scope: !22)
!27 = !DILocation(line: 6, column: 5, scope: !22)
!28 = !DILocation(line: 7, column: 12, scope: !10)
!29 = !{!30, !30, i64 0}
!30 = !{!"_Bool", !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C/C++ TBAA"}
!33 = !{i8 0, i8 2}
!34 = !{}
!35 = !DILocation(line: 7, column: 31, scope: !10)
!36 = !DILocation(line: 7, column: 29, scope: !10)
!37 = !DILocation(line: 8, column: 1, scope: !10)
!38 = !DILocation(line: 7, column: 5, scope: !10)
!39 = !DILocation(line: 6, column: 56, scope: !40)
!40 = distinct !DILexicalBlock(scope: !41, file: !8, line: 6, column: 47)
!41 = distinct !DILexicalBlock(scope: !42, file: !8, line: 6, column: 39)
!42 = distinct !DILexicalBlock(scope: !43, file: !8, line: 6, column: 33)
!43 = distinct !DILexicalBlock(scope: !22, file: !8, line: 6, column: 5)
!44 = !DILocation(line: 6, column: 54, scope: !40)
!45 = !DILocation(line: 6, column: 28, scope: !43)
!46 = !DILocation(line: 6, column: 23, scope: !43)
!47 = distinct !{!47, !27, !48, !49, !50}
!48 = !DILocation(line: 6, column: 79, scope: !22)
!49 = !{!"llvm.loop.mustprogress"}
!50 = !{!"llvm.loop.unroll.disable"}
!51 = !DISubprogram(name: "cq_theta_i1", scope: !52, file: !52, line: 32, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!53 = !DISubroutineType(types: !54)
!54 = !{!18, !18, !55}
!55 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!56 = !DISubprogram(name: "cq_measure_i1", scope: !52, file: !52, line: 77, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!18, !18}
