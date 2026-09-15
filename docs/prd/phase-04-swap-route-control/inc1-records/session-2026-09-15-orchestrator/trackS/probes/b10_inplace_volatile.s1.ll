; ModuleID = 'b10_inplace_volatile.c'
source_filename = "b10_inplace_volatile.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !20
    #dbg_value(i32 %2, !15, !DIExpression(), !21)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !22
    #dbg_declare(ptr %1, !16, !DIExpression(), !23)
  store volatile i32 1, ptr %1, align 4, !dbg !23, !tbaa !24
    #dbg_value(i32 0, !18, !DIExpression(), !28)
    #dbg_value(i32 %2, !15, !DIExpression(), !21)
  br label %6, !dbg !29

3:                                                ; preds = %6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #3, !dbg !30
    #dbg_value(i32 %4, !15, !DIExpression(), !21)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3, !dbg !31
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !32
  ret i32 %5, !dbg !33

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 0, %0 ], [ %11, %6 ]
  %8 = phi i32 [ %2, %0 ], [ %10, %6 ]
    #dbg_value(i32 %7, !18, !DIExpression(), !28)
    #dbg_value(i32 %8, !15, !DIExpression(), !21)
  %9 = load volatile i32, ptr %1, align 4, !dbg !34, !tbaa !24
  %10 = xor i32 %9, %8, !dbg !36
    #dbg_value(i32 %10, !15, !DIExpression(), !21)
  %11 = add nuw nsw i32 %7, 1, !dbg !37
    #dbg_value(i32 %11, !18, !DIExpression(), !28)
  %12 = icmp eq i32 %11, 3, !dbg !38
  br i1 %12, label %3, label %6, !dbg !29, !llvm.loop !39
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !43 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare !dbg !48 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !51 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !52
    #dbg_value(i32 %2, !15, !DIExpression(), !54)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !55
    #dbg_declare(ptr %1, !16, !DIExpression(), !56)
  store volatile i32 1, ptr %1, align 4, !dbg !56, !tbaa !24
    #dbg_value(i32 0, !18, !DIExpression(), !57)
    #dbg_value(i32 %2, !15, !DIExpression(), !54)
  br label %3, !dbg !58

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %8, %3 ]
  %5 = phi i32 [ %2, %0 ], [ %7, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !57)
    #dbg_value(i32 %5, !15, !DIExpression(), !54)
  %6 = load volatile i32, ptr %1, align 4, !dbg !59, !tbaa !24
  %7 = xor i32 %6, %5, !dbg !60
    #dbg_value(i32 %7, !15, !DIExpression(), !54)
  %8 = add nuw nsw i32 %4, 1, !dbg !61
    #dbg_value(i32 %8, !18, !DIExpression(), !57)
  %9 = icmp eq i32 %8, 3, !dbg !62
  br i1 %9, label %10, label %3, !dbg !58, !llvm.loop !63

10:                                               ; preds = %3
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #3, !dbg !65
    #dbg_value(i32 %11, !15, !DIExpression(), !54)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3, !dbg !66
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !67
  ret i32 %12, !dbg !68
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
!8 = !DIFile(filename: "b10_inplace_volatile.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "d487766d207fa53c48da9e61f486922c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 8, type: !17)
!17 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 9, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!20 = !DILocation(line: 7, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 8, column: 5, scope: !10)
!23 = !DILocation(line: 8, column: 18, scope: !10)
!24 = !{!25, !25, i64 0}
!25 = !{!"int", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C/C++ TBAA"}
!28 = !DILocation(line: 0, scope: !19)
!29 = !DILocation(line: 9, column: 5, scope: !19)
!30 = !DILocation(line: 11, column: 9, scope: !10)
!31 = !DILocation(line: 12, column: 12, scope: !10)
!32 = !DILocation(line: 13, column: 1, scope: !10)
!33 = !DILocation(line: 12, column: 5, scope: !10)
!34 = !DILocation(line: 10, column: 14, scope: !35)
!35 = distinct !DILexicalBlock(scope: !19, file: !8, line: 9, column: 5)
!36 = !DILocation(line: 10, column: 11, scope: !35)
!37 = !DILocation(line: 9, column: 28, scope: !35)
!38 = !DILocation(line: 9, column: 23, scope: !35)
!39 = distinct !{!39, !29, !40, !41, !42}
!40 = !DILocation(line: 10, column: 14, scope: !19)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !{!"llvm.loop.unroll.disable"}
!43 = !DISubprogram(name: "cq_theta_si32", scope: !44, file: !44, line: 38, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13, !47}
!47 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!48 = !DISubprogram(name: "cq_measure_si32", scope: !44, file: !44, line: 83, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13}
!51 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!52 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !53)
!53 = distinct !DILocation(line: 14, column: 25, scope: !51)
!54 = !DILocation(line: 0, scope: !10, inlinedAt: !53)
!55 = !DILocation(line: 8, column: 5, scope: !10, inlinedAt: !53)
!56 = !DILocation(line: 8, column: 18, scope: !10, inlinedAt: !53)
!57 = !DILocation(line: 0, scope: !19, inlinedAt: !53)
!58 = !DILocation(line: 9, column: 5, scope: !19, inlinedAt: !53)
!59 = !DILocation(line: 10, column: 14, scope: !35, inlinedAt: !53)
!60 = !DILocation(line: 10, column: 11, scope: !35, inlinedAt: !53)
!61 = !DILocation(line: 9, column: 28, scope: !35, inlinedAt: !53)
!62 = !DILocation(line: 9, column: 23, scope: !35, inlinedAt: !53)
!63 = distinct !{!63, !58, !64, !41, !42}
!64 = !DILocation(line: 10, column: 14, scope: !19, inlinedAt: !53)
!65 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !53)
!66 = !DILocation(line: 12, column: 12, scope: !10, inlinedAt: !53)
!67 = !DILocation(line: 13, column: 1, scope: !10, inlinedAt: !53)
!68 = !DILocation(line: 14, column: 18, scope: !51)
