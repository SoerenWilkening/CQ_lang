; libm_bind_reject_note_user_site.ll — DECLINE with a located NOTE (bd test_C_libtooling-3c6m.82).
; A quantum `foo(q)` binds the injected `__cq_libm_foo`, whose body holds a construct
; the lift does not lower yet (a store), so the specializer declines at the store,
; inside the BUNDLE: no `!dbg` there, `<unknown>:0:0`. Measured on the e0af16ed
; census: no cqc decline named the user's call site. The error is now preceded by a
; note at the user's call (`x.c:7:11`), from LiftDiagnostics.h.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK:      note: x.c:7:11: in function example double (double): cq specialization: the error below is inside the quantum call to 'foo' lifted from here
; CHECK:      error: {{.*}}in function __cq_libm_foo double (double): cq specialization: callee contains a non-reversibilizable construct
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @foo(double)

@__cq_libm_buf = global double 0.0

define double @__cq_libm_foo(double %x) {
  store double %x, ptr @__cq_libm_buf
  %y = fadd double %x, 1.000000e+00
  ret double %y
}

define double @example(double %u0) !dbg !5 {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01), !dbg !8
  %s = call double @foo(double %q), !dbg !9
  %m = call double @cq_measure_f64(double %s), !dbg !10
  ret double %m, !dbg !10
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "x.c", directory: "/tmp")
!3 = !{i32 7, !"Dwarf Version", i32 5}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "example", scope: !1, file: !1, line: 4, type: !6, scopeLine: 4, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!6 = !DISubroutineType(types: !7)
!7 = !{}
!8 = !DILocation(line: 6, column: 3, scope: !5)
!9 = !DILocation(line: 7, column: 11, scope: !5)
!10 = !DILocation(line: 8, column: 3, scope: !5)
