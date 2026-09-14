; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x2_xorc_plus_outofplace.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x2_xorc_plus_outofplace.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !22
    #dbg_declare(ptr %1, !15, !DIExpression(), !23)
  store volatile i32 3, ptr %1, align 4, !dbg !23, !tbaa !24
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !28
    #dbg_value(i32 %2, !17, !DIExpression(), !29)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 3.000000e-01) #3, !dbg !30
    #dbg_value(i32 %3, !18, !DIExpression(), !29)
    #dbg_value(i32 0, !19, !DIExpression(), !29)
    #dbg_value(i32 1, !20, !DIExpression(), !31)
  br label %10, !dbg !32

4:                                                ; preds = %10
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #3, !dbg !33
    #dbg_value(i32 %5, !17, !DIExpression(), !29)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3, !dbg !34
  %7 = add nsw i32 %6, %19, !dbg !35
  %8 = tail call i32 @cq_measure_si32(i32 noundef %15) #3, !dbg !36
  %9 = add nsw i32 %7, %8, !dbg !37
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !38
  ret i32 %9, !dbg !39

10:                                               ; preds = %0, %10
  %11 = phi i32 [ 1, %0 ], [ %20, %10 ]
  %12 = phi i32 [ 0, %0 ], [ %19, %10 ]
  %13 = phi i32 [ %3, %0 ], [ %15, %10 ]
    #dbg_value(i32 %11, !20, !DIExpression(), !31)
    #dbg_value(i32 %12, !19, !DIExpression(), !29)
    #dbg_value(i32 %13, !18, !DIExpression(), !29)
  %14 = load volatile i32, ptr %1, align 4, !dbg !40, !tbaa !24
  %15 = xor i32 %14, %13, !dbg !43
    #dbg_value(i32 %15, !18, !DIExpression(), !29)
  %16 = lshr i32 %2, %11, !dbg !44
  %17 = and i32 %16, 1, !dbg !44
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #3, !dbg !44
  %19 = add nsw i32 %18, %12, !dbg !45
    #dbg_value(i32 %19, !19, !DIExpression(), !29)
  %20 = add nuw nsw i32 %11, 1, !dbg !46
    #dbg_value(i32 %20, !20, !DIExpression(), !31)
  %21 = icmp eq i32 %20, 3, !dbg !47
  br i1 %21, label %4, label %10, !dbg !32, !llvm.loop !48
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !52 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare !dbg !57 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !60 {
  %1 = tail call i32 @slice(), !dbg !61
  ret i32 %1, !dbg !62
}

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x2_xorc_plus_outofplace.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "2b75089eaf68735c2ea86c2a15556243")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !18, !19, !20}
!15 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 7, type: !16)
!16 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!17 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 8, type: !13)
!18 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 9, type: !13)
!19 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 10, type: !13)
!20 = !DILocalVariable(name: "k", scope: !21, file: !8, line: 11, type: !13)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 11, column: 5)
!22 = !DILocation(line: 7, column: 5, scope: !10)
!23 = !DILocation(line: 7, column: 18, scope: !10)
!24 = !{!25, !25, i64 0}
!25 = !{!"int", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C/C++ TBAA"}
!28 = !DILocation(line: 8, column: 13, scope: !10)
!29 = !DILocation(line: 0, scope: !10)
!30 = !DILocation(line: 9, column: 13, scope: !10)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 11, column: 5, scope: !21)
!33 = !DILocation(line: 15, column: 9, scope: !10)
!34 = !DILocation(line: 16, column: 16, scope: !10)
!35 = !DILocation(line: 16, column: 14, scope: !10)
!36 = !DILocation(line: 16, column: 32, scope: !10)
!37 = !DILocation(line: 16, column: 30, scope: !10)
!38 = !DILocation(line: 17, column: 1, scope: !10)
!39 = !DILocation(line: 16, column: 5, scope: !10)
!40 = !DILocation(line: 12, column: 14, scope: !41)
!41 = distinct !DILexicalBlock(scope: !42, file: !8, line: 11, column: 34)
!42 = distinct !DILexicalBlock(scope: !21, file: !8, line: 11, column: 5)
!43 = !DILocation(line: 12, column: 11, scope: !41)
!44 = !DILocation(line: 13, column: 14, scope: !41)
!45 = !DILocation(line: 13, column: 11, scope: !41)
!46 = !DILocation(line: 11, column: 29, scope: !42)
!47 = !DILocation(line: 11, column: 23, scope: !42)
!48 = distinct !{!48, !32, !49, !50, !51}
!49 = !DILocation(line: 14, column: 5, scope: !21)
!50 = !{!"llvm.loop.mustprogress"}
!51 = !{!"llvm.loop.unroll.disable"}
!52 = !DISubprogram(name: "cq_theta_si32", scope: !53, file: !53, line: 38, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13, !56}
!56 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!57 = !DISubprogram(name: "cq_measure_si32", scope: !53, file: !53, line: 83, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!58 = !DISubroutineType(types: !59)
!59 = !{!13, !13}
!60 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 18, type: !11, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!61 = !DILocation(line: 18, column: 25, scope: !60)
!62 = !DILocation(line: 18, column: 18, scope: !60)
