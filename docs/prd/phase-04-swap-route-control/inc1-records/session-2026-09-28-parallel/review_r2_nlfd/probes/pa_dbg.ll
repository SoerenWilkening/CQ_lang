target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @atoi(ptr)
declare token @llvm.call.preallocated.setup(i32)
declare ptr @llvm.call.preallocated.arg(token, i32)
define i32 @h2(ptr preallocated(i32) %s, i32 %x) noinline {
  %r = add i32 %x, 1
  ret i32 %r
}
define i32 @h(ptr preallocated(i32) %s, i32 %a) noinline !dbg !10 {
  %r = musttail call i32 @h2(ptr preallocated(i32) %s, i32 %a), !dbg !12
  ret i32 %r
}
define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %tok = call token @llvm.call.preallocated.setup(i32 1)
  %p = call ptr @llvm.call.preallocated.arg(token %tok, i32 0) preallocated(i32)
  store i32 3, ptr %p
  %r = call i32 @h(ptr preallocated(i32) %p, i32 %q) [ "preallocated"(token %tok) ]
  %mr = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mr
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}
!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "p", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "pa.c", directory: "/tmp")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 7, !"Dwarf Version", i32 5}
!10 = distinct !DISubprogram(name: "h", scope: !1, file: !1, line: 3, type: !11, scopeLine: 3, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!11 = !DISubroutineType(types: !{})
!12 = !DILocation(line: 4, column: 17, scope: !10)
