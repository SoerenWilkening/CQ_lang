; HAND-WRITTEN. Rules: 15, 12, 8, 4, 5, 2.
; Checked: theta_quantum_angle: r + x; phi_quantum_angle: x (measured).
; Clean: the angle register a = (double)x * c and its sitofp; phi_quantum_angle's flag (x > k).
; Kept: the user register x of each function; theta_quantum_angle's r (rotated by the angle rail, frozen, measured).
; Rotations: theta_quantum_angle: Ry(tx) on x; Ry(tr) on r; Ry(A) on r with A the angle rail holding (double)x * c.
; phi_quantum_angle: Ry(tx) on x; phase(A) on the angle rail A = (double)x * c, uncontrolled; phase(A) under (x > k).
; A QUANTUM ANGLE (rule 15): the angle a = x * c is computed by the ordinary opcode lowering into an f64 REGISTER (the
; program's IEEE double, bit-exact, on a rail: sitofp then fmul_hl, rule 4). The rotation is then ONE gate primitive
; that reads that register: cqrt_ry_i32_qangle(r, A) applies Ry(val(A)) to r controlled by A's bits; the backend
; supplies the circuit (reduce val(A) exactly mod 4π, round it to nearest-even onto the grid 4π·k/2^N, one controlled
; Ry per ladder bit i with the weight 4π·2^(i-N), CONSTRUCTION_RULES §1.3; rotations about one axis add, so the product
; is Ry(val(A)) on every branch up to that rounding; no emitted angle comes out of floating-point arithmetic). The IR never spells the ladder. The angle register is only
; read, so it is uncomputed afterwards by the LIFO spine. cq_phi(a): e^(i a(x)) depends on the register, so it is a
; RELATIVE phase, never a deletable global one (rule 12): uncontrolled it is cqrt_rz_qangle(A), a phase on the angle
; register that A's uncompute kicks back onto x. Under the quantum condition x > k it is
; cqrt_rz_qangle_controlled(flag, A). No NOT-rail identity (rz(-theta) + global phase) may be used here: with a quantum
; theta the "global" leftover e^(i theta(A)) is relative. A fixed-point ladder spelled in the IR would bake the
; ladder's precision into the compiled program; the primitive leaves N to the backend (§0).
source_filename = "quantum_angle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @theta_quantum_angle(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register r]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call i32 @cq_template_sitofp_i32_to_f64(i32 %6)    ; IR: %8 = sitofp i32 %6 to double
  %9 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %4)    ; IR: %9 = fmul double %8, %4  [the angle register: the program's double]
  call void @cqrt_ry_i32_qangle(i32 %7, i32 %9)    ; IR: %10 = cq_theta_si32(%7, %9): Ry(val(%9)) on r, controlled by the bits of %9
  call void @cq_template_fmul_f64_hl_unc(i32 %9, i32 %8, double %4)    ; IR: uncompute %9 (only read by the rotation)
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %8, i32 %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %11 = cq_measure_si32(%10)
  %11 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %12 = cq_measure_si32(%6)
  %12 = add nsw i32 %11, %10    ; IR: %13 = add nsw i32 %12, %11  (classical)
  ret i32 %12    ; IR: ret i32 %13
}

define i32 @phi_quantum_angle(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_sitofp_i32_to_f64(i32 %5)    ; IR: %6 = sitofp i32 %5 to double
  %7 = call i32 @cq_template_fmul_f64_hl(i32 %6, double %2)    ; IR: %7 = fmul double %6, %2  [the angle register]
  call void @cqrt_rz_qangle(i32 %7)    ; IR: cq_phi(%7) in %4, uncontrolled: e^(i val(%7)) is a relative phase on the angle register, kicked back onto x by its uncompute
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %3)    ; IR: %8 = icmp sgt i32 %5, %3  [path predicate of block %9]
  call void @cqrt_rz_qangle_controlled(i32 %8, i32 %7)    ; IR: block %9: cq_phi(%7) under br i1 %8
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %5, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %7, i32 %6, double %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %6, i32 %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %11 = cq_measure_si32(%5)
  ret i32 %9    ; IR: ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_qangle(i32, i32)
declare void @cqrt_rz_qangle(i32)
declare void @cqrt_rz_qangle_controlled(i32, i32)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
