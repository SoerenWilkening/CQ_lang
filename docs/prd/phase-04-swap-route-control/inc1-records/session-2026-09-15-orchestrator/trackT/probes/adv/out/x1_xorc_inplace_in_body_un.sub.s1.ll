; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !20
    #dbg_declare(ptr %1, !15, !DIExpression(), !21)
  store volatile i32 3, ptr %1, align 4, !dbg !21, !tbaa !22
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !26
    #dbg_value(i32 %2, !17, !DIExpression(), !27)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 3.000000e-01) #3, !dbg !28
    #dbg_value(i32 %3, !18, !DIExpression(), !27)
    #dbg_value(i32 0, !19, !DIExpression(), !27)
  %4 = load volatile i32, ptr %1, align 4, !dbg !29, !tbaa !22
  %5 = xor i32 %4, %3, !dbg !30
    #dbg_value(i32 %5, !18, !DIExpression(), !27)
  %6 = and i32 %2, 1, !dbg !31
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !31
    #dbg_value(i32 %7, !19, !DIExpression(), !27)
  %8 = load volatile i32, ptr %1, align 4, !dbg !32, !tbaa !22
  %9 = xor i32 %5, %8, !dbg !33
    #dbg_value(i32 %9, !18, !DIExpression(), !27)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !34
  %11 = add nsw i32 %10, %7, !dbg !35
    #dbg_value(i32 %11, !19, !DIExpression(), !27)
  %12 = load volatile i32, ptr %1, align 4, !dbg !36, !tbaa !22
  %13 = xor i32 %9, %12, !dbg !37
    #dbg_value(i32 %13, !18, !DIExpression(), !27)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !38
  %15 = add nsw i32 %11, %14, !dbg !39
    #dbg_value(i32 %15, !19, !DIExpression(), !27)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %2) #3, !dbg !40
  %17 = add nsw i32 %15, %16, !dbg !41
  %18 = tail call i32 @cq_measure_si32(i32 noundef %13) #3, !dbg !42
  %19 = add nsw i32 %17, %18, !dbg !43
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !44
  ret i32 %19, !dbg !45
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !46 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare !dbg !51 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !54 {
  %1 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !55
    #dbg_declare(ptr %1, !15, !DIExpression(), !57)
  store volatile i32 3, ptr %1, align 4, !dbg !57, !tbaa !22
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !58
    #dbg_value(i32 %2, !17, !DIExpression(), !59)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 3.000000e-01) #3, !dbg !60
    #dbg_value(i32 %3, !18, !DIExpression(), !59)
    #dbg_value(i32 0, !19, !DIExpression(), !59)
  %4 = load volatile i32, ptr %1, align 4, !dbg !61, !tbaa !22
  %5 = xor i32 %4, %3, !dbg !62
    #dbg_value(i32 %5, !18, !DIExpression(), !59)
  %6 = and i32 %2, 1, !dbg !63
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !63
    #dbg_value(i32 %7, !19, !DIExpression(), !59)
  %8 = load volatile i32, ptr %1, align 4, !dbg !64, !tbaa !22
  %9 = xor i32 %5, %8, !dbg !65
    #dbg_value(i32 %9, !18, !DIExpression(), !59)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !66
  %11 = add nsw i32 %10, %7, !dbg !67
    #dbg_value(i32 %11, !19, !DIExpression(), !59)
  %12 = load volatile i32, ptr %1, align 4, !dbg !68, !tbaa !22
  %13 = xor i32 %9, %12, !dbg !69
    #dbg_value(i32 %13, !18, !DIExpression(), !59)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !70
  %15 = add nsw i32 %11, %14, !dbg !71
    #dbg_value(i32 %15, !19, !DIExpression(), !59)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %2) #3, !dbg !72
  %17 = add nsw i32 %15, %16, !dbg !73
  %18 = tail call i32 @cq_measure_si32(i32 noundef %13) #3, !dbg !74
  %19 = add nsw i32 %17, %18, !dbg !75
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !76
  ret i32 %19, !dbg !77
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "3a3fd4e8db39719250786ea57bbd61d9")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !18, !19}
!15 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 3, type: !16)
!16 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!17 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!18 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 5, type: !13)
!19 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!20 = !DILocation(line: 3, column: 5, scope: !10)
!21 = !DILocation(line: 3, column: 18, scope: !10)
!22 = !{!23, !23, i64 0}
!23 = !{!"int", !24, i64 0}
!24 = !{!"omnipotent char", !25, i64 0}
!25 = !{!"Simple C/C++ TBAA"}
!26 = !DILocation(line: 4, column: 13, scope: !10)
!27 = !DILocation(line: 0, scope: !10)
!28 = !DILocation(line: 5, column: 13, scope: !10)
!29 = !DILocation(line: 7, column: 10, scope: !10)
!30 = !DILocation(line: 7, column: 7, scope: !10)
!31 = !DILocation(line: 7, column: 18, scope: !10)
!32 = !DILocation(line: 8, column: 10, scope: !10)
!33 = !DILocation(line: 8, column: 7, scope: !10)
!34 = !DILocation(line: 8, column: 18, scope: !10)
!35 = !DILocation(line: 8, column: 15, scope: !10)
!36 = !DILocation(line: 9, column: 10, scope: !10)
!37 = !DILocation(line: 9, column: 7, scope: !10)
!38 = !DILocation(line: 9, column: 18, scope: !10)
!39 = !DILocation(line: 9, column: 15, scope: !10)
!40 = !DILocation(line: 10, column: 16, scope: !10)
!41 = !DILocation(line: 10, column: 14, scope: !10)
!42 = !DILocation(line: 10, column: 32, scope: !10)
!43 = !DILocation(line: 10, column: 30, scope: !10)
!44 = !DILocation(line: 11, column: 1, scope: !10)
!45 = !DILocation(line: 10, column: 5, scope: !10)
!46 = !DISubprogram(name: "cq_theta_si32", scope: !47, file: !47, line: 38, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13, !50}
!50 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!51 = !DISubprogram(name: "cq_measure_si32", scope: !47, file: !47, line: 83, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DISubroutineType(types: !53)
!53 = !{!13, !13}
!54 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!55 = !DILocation(line: 3, column: 5, scope: !10, inlinedAt: !56)
!56 = distinct !DILocation(line: 12, column: 25, scope: !54)
!57 = !DILocation(line: 3, column: 18, scope: !10, inlinedAt: !56)
!58 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !56)
!59 = !DILocation(line: 0, scope: !10, inlinedAt: !56)
!60 = !DILocation(line: 5, column: 13, scope: !10, inlinedAt: !56)
!61 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !56)
!62 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !56)
!63 = !DILocation(line: 7, column: 18, scope: !10, inlinedAt: !56)
!64 = !DILocation(line: 8, column: 10, scope: !10, inlinedAt: !56)
!65 = !DILocation(line: 8, column: 7, scope: !10, inlinedAt: !56)
!66 = !DILocation(line: 8, column: 18, scope: !10, inlinedAt: !56)
!67 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !56)
!68 = !DILocation(line: 9, column: 10, scope: !10, inlinedAt: !56)
!69 = !DILocation(line: 9, column: 7, scope: !10, inlinedAt: !56)
!70 = !DILocation(line: 9, column: 18, scope: !10, inlinedAt: !56)
!71 = !DILocation(line: 9, column: 15, scope: !10, inlinedAt: !56)
!72 = !DILocation(line: 10, column: 16, scope: !10, inlinedAt: !56)
!73 = !DILocation(line: 10, column: 14, scope: !10, inlinedAt: !56)
!74 = !DILocation(line: 10, column: 32, scope: !10, inlinedAt: !56)
!75 = !DILocation(line: 10, column: 30, scope: !10, inlinedAt: !56)
!76 = !DILocation(line: 11, column: 1, scope: !10, inlinedAt: !56)
!77 = !DILocation(line: 12, column: 18, scope: !54)
