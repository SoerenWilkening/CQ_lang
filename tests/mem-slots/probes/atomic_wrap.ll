; cq-qrvh (CR rule 24, rule 4): atomicrmw uinc_wrap / udec_wrap / fmax / fmin (and a volatile atomic) on a slot cell are their
; single-thread read-modify-writes, built from templates.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define i32 @atomic_wrap(i32 %x0, double %t, i32 %v) {
  %c = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  store i32 %x, ptr %c, align 4
  %o1 = atomicrmw uinc_wrap ptr %c, i32 %v seq_cst, align 4
  %o2 = atomicrmw udec_wrap ptr %c, i32 %v seq_cst, align 4
  %o3 = atomicrmw udec_wrap ptr %c, i32 %x seq_cst, align 4
  %l = load i32, ptr %c, align 4
  %m1 = call i32 @cq_measure_si32(i32 %o2)
  %m2 = call i32 @cq_measure_si32(i32 %l)
  %m3 = call i32 @cq_measure_si32(i32 %o3)
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  ret i32 %s2
}

define double @atomic_fminmax(double %x0, double %t, double %v) {
  %c = alloca double, align 8
  %x = call double @cq_theta_f64(double %x0, double %t)
  store double %x, ptr %c, align 8
  %o1 = atomicrmw fmax ptr %c, double %v seq_cst, align 8
  %o2 = atomicrmw fmin ptr %c, double %x seq_cst, align 8
  %l = load double, ptr %c, align 8
  %m1 = call double @cq_measure_f64(double %o2)
  %m2 = call double @cq_measure_f64(double %l)
  %s = fadd double %m1, %m2
  ret double %s
}

; Rule 24 single-thread collapse: a volatile atomic is the same read-modify-write.
define i32 @atomic_volatile(i32 %x0, double %t, i32 %v) {
  %c = alloca i32, align 4
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  store i32 %x, ptr %c, align 4
  %o = atomicrmw volatile add ptr %c, i32 %v seq_cst, align 4
  %l = load i32, ptr %c, align 4
  %m1 = call i32 @cq_measure_si32(i32 %o)
  %m2 = call i32 @cq_measure_si32(i32 %l)
  %s = add i32 %m1, %m2
  ret i32 %s
}
; CHECK atomic_wrap: cq_template_icmp_uge_i32_hl
; CHECK atomic_wrap: cq_template_or_i1
; CHECK atomic_fminmax: cq_template_fmax_f64_hl
; USERCHECK atomic_wrap
; USERCHECK atomic_fminmax
; USERCHECK atomic_volatile
