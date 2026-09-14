; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body.c"
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
    #dbg_value(i32 0, !20, !DIExpression(), !31)
  %4 = and i32 %2, 1
    #dbg_value(i32 0, !20, !DIExpression(), !31)
    #dbg_value(i32 0, !19, !DIExpression(), !29)
    #dbg_value(i32 %3, !18, !DIExpression(), !29)
  br label %10, !dbg !32

5:                                                ; preds = %10
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #3, !dbg !33
  %7 = add nsw i32 %6, %17, !dbg !34
  %8 = tail call i32 @cq_measure_si32(i32 noundef %15) #3, !dbg !35
  %9 = add nsw i32 %7, %8, !dbg !36
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !37
  ret i32 %9, !dbg !38

10:                                               ; preds = %0, %10
  %11 = phi i32 [ 0, %0 ], [ %18, %10 ]
  %12 = phi i32 [ 0, %0 ], [ %17, %10 ]
  %13 = phi i32 [ %3, %0 ], [ %15, %10 ]
    #dbg_value(i32 %11, !20, !DIExpression(), !31)
    #dbg_value(i32 %12, !19, !DIExpression(), !29)
    #dbg_value(i32 %13, !18, !DIExpression(), !29)
  %14 = load volatile i32, ptr %1, align 4, !dbg !39, !tbaa !24
  %15 = xor i32 %14, %13, !dbg !42
    #dbg_value(i32 %15, !18, !DIExpression(), !29)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %4) #3, !dbg !43
  %17 = add nsw i32 %16, %12, !dbg !44
    #dbg_value(i32 %17, !19, !DIExpression(), !29)
  %18 = add nuw nsw i32 %11, 1, !dbg !45
    #dbg_value(i32 %18, !20, !DIExpression(), !31)
  %19 = icmp eq i32 %18, 3, !dbg !46
  br i1 %19, label %5, label %10, !dbg !32, !llvm.loop !47
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !51 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare !dbg !56 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !59 {
  %1 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !60
    #dbg_declare(ptr %1, !15, !DIExpression(), !62)
  store volatile i32 3, ptr %1, align 4, !dbg !62, !tbaa !24
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !63
    #dbg_value(i32 %2, !17, !DIExpression(), !64)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 3.000000e-01) #3, !dbg !65
    #dbg_value(i32 %3, !18, !DIExpression(), !64)
    #dbg_value(i32 0, !19, !DIExpression(), !64)
    #dbg_value(i32 0, !20, !DIExpression(), !66)
  %4 = and i32 %2, 1
    #dbg_value(i32 0, !20, !DIExpression(), !66)
    #dbg_value(i32 0, !19, !DIExpression(), !64)
    #dbg_value(i32 %3, !18, !DIExpression(), !64)
  br label %5, !dbg !67

5:                                                ; preds = %5, %0
  %6 = phi i32 [ 0, %0 ], [ %13, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %12, %5 ]
  %8 = phi i32 [ %3, %0 ], [ %10, %5 ]
    #dbg_value(i32 %6, !20, !DIExpression(), !66)
    #dbg_value(i32 %7, !19, !DIExpression(), !64)
    #dbg_value(i32 %8, !18, !DIExpression(), !64)
  %9 = load volatile i32, ptr %1, align 4, !dbg !68, !tbaa !24
  %10 = xor i32 %9, %8, !dbg !69
    #dbg_value(i32 %10, !18, !DIExpression(), !64)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4) #3, !dbg !70
  %12 = add nsw i32 %11, %7, !dbg !71
    #dbg_value(i32 %12, !19, !DIExpression(), !64)
  %13 = add nuw nsw i32 %6, 1, !dbg !72
    #dbg_value(i32 %13, !20, !DIExpression(), !66)
  %14 = icmp eq i32 %13, 3, !dbg !73
  br i1 %14, label %15, label %5, !dbg !67, !llvm.loop !74

15:                                               ; preds = %5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %2) #3, !dbg !76
  %17 = add nsw i32 %16, %12, !dbg !77
  %18 = tail call i32 @cq_measure_si32(i32 noundef %10) #3, !dbg !78
  %19 = add nsw i32 %17, %18, !dbg !79
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !80
  ret i32 %19, !dbg !81
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "ca36384c89d5c09eedceebc0c3dc2509")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 9, type: !11, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !18, !19, !20}
!15 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 10, type: !16)
!16 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!17 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 11, type: !13)
!18 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 12, type: !13)
!19 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 13, type: !13)
!20 = !DILocalVariable(name: "k", scope: !21, file: !8, line: 14, type: !13)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 5)
!22 = !DILocation(line: 10, column: 5, scope: !10)
!23 = !DILocation(line: 10, column: 18, scope: !10)
!24 = !{!25, !25, i64 0}
!25 = !{!"int", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C/C++ TBAA"}
!28 = !DILocation(line: 11, column: 13, scope: !10)
!29 = !DILocation(line: 0, scope: !10)
!30 = !DILocation(line: 12, column: 13, scope: !10)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 14, column: 5, scope: !21)
!33 = !DILocation(line: 18, column: 16, scope: !10)
!34 = !DILocation(line: 18, column: 14, scope: !10)
!35 = !DILocation(line: 18, column: 32, scope: !10)
!36 = !DILocation(line: 18, column: 30, scope: !10)
!37 = !DILocation(line: 19, column: 1, scope: !10)
!38 = !DILocation(line: 18, column: 5, scope: !10)
!39 = !DILocation(line: 15, column: 14, scope: !40)
!40 = distinct !DILexicalBlock(scope: !41, file: !8, line: 14, column: 33)
!41 = distinct !DILexicalBlock(scope: !21, file: !8, line: 14, column: 5)
!42 = !DILocation(line: 15, column: 11, scope: !40)
!43 = !DILocation(line: 16, column: 14, scope: !40)
!44 = !DILocation(line: 16, column: 11, scope: !40)
!45 = !DILocation(line: 14, column: 28, scope: !41)
!46 = !DILocation(line: 14, column: 23, scope: !41)
!47 = distinct !{!47, !32, !48, !49, !50}
!48 = !DILocation(line: 17, column: 5, scope: !21)
!49 = !{!"llvm.loop.mustprogress"}
!50 = !{!"llvm.loop.unroll.disable"}
!51 = !DISubprogram(name: "cq_theta_si32", scope: !52, file: !52, line: 38, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!53 = !DISubroutineType(types: !54)
!54 = !{!13, !13, !55}
!55 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!56 = !DISubprogram(name: "cq_measure_si32", scope: !52, file: !52, line: 83, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!13, !13}
!59 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 20, type: !11, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!60 = !DILocation(line: 10, column: 5, scope: !10, inlinedAt: !61)
!61 = distinct !DILocation(line: 20, column: 25, scope: !59)
!62 = !DILocation(line: 10, column: 18, scope: !10, inlinedAt: !61)
!63 = !DILocation(line: 11, column: 13, scope: !10, inlinedAt: !61)
!64 = !DILocation(line: 0, scope: !10, inlinedAt: !61)
!65 = !DILocation(line: 12, column: 13, scope: !10, inlinedAt: !61)
!66 = !DILocation(line: 0, scope: !21, inlinedAt: !61)
!67 = !DILocation(line: 14, column: 5, scope: !21, inlinedAt: !61)
!68 = !DILocation(line: 15, column: 14, scope: !40, inlinedAt: !61)
!69 = !DILocation(line: 15, column: 11, scope: !40, inlinedAt: !61)
!70 = !DILocation(line: 16, column: 14, scope: !40, inlinedAt: !61)
!71 = !DILocation(line: 16, column: 11, scope: !40, inlinedAt: !61)
!72 = !DILocation(line: 14, column: 28, scope: !41, inlinedAt: !61)
!73 = !DILocation(line: 14, column: 23, scope: !41, inlinedAt: !61)
!74 = distinct !{!74, !67, !75, !49, !50}
!75 = !DILocation(line: 17, column: 5, scope: !21, inlinedAt: !61)
!76 = !DILocation(line: 18, column: 16, scope: !10, inlinedAt: !61)
!77 = !DILocation(line: 18, column: 14, scope: !10, inlinedAt: !61)
!78 = !DILocation(line: 18, column: 32, scope: !10, inlinedAt: !61)
!79 = !DILocation(line: 18, column: 30, scope: !10, inlinedAt: !61)
!80 = !DILocation(line: 19, column: 1, scope: !10, inlinedAt: !61)
!81 = !DILocation(line: 20, column: 18, scope: !59)
