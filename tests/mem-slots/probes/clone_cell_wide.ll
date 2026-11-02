; cq-05pa (CR rules 9, 18, 20; musl __lgamma_r: *signgamp = 1, then = -1 under a quantum predicate): a clone's
; caller cell written unconditionally and then under a quantum predicate is one value select(p, -1, 1) (cq-4e6m), in
; a body of more than 32 blocks: reachesItself searches the whole CFG (isPotentiallyReachable answers maybe past 32).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @clone_cell_wide(i32 %a) {
  %s = alloca i32, align 4
  store i32 0, ptr %s, align 4
  %x = call i32 @cq_theta_si32(i32 %a, double 3.000000e-01)
  %r = call i32 @wide(i32 %x, ptr %s)
  %m = call i32 @cq_measure_si32(i32 %r)
  %v = load i32, ptr %s, align 4
  %n = call i32 @cq_measure_si32(i32 %v)
  %t = add i32 %m, %n
  ret i32 %t
}
define internal i32 @wide(i32 %x, ptr nocapture %s) noinline {
entry:
  store i32 1, ptr %s, align 4
  br label %b0
b0:
  %c0 = and i32 %x, 1
  %t0 = icmp ne i32 %c0, 0
  br i1 %t0, label %a0, label %b1
a0:
  br label %b1
b1:
  %c1 = and i32 %x, 2
  %t1 = icmp ne i32 %c1, 0
  br i1 %t1, label %a1, label %b2
a1:
  br label %b2
b2:
  %c2 = and i32 %x, 4
  %t2 = icmp ne i32 %c2, 0
  br i1 %t2, label %a2, label %b3
a2:
  store i32 -1, ptr %s, align 4
  br label %b3
b3:
  %c3 = and i32 %x, 8
  %t3 = icmp ne i32 %c3, 0
  br i1 %t3, label %a3, label %b4
a3:
  br label %b4
b4:
  %c4 = and i32 %x, 16
  %t4 = icmp ne i32 %c4, 0
  br i1 %t4, label %a4, label %b5
a4:
  br label %b5
b5:
  %c5 = and i32 %x, 32
  %t5 = icmp ne i32 %c5, 0
  br i1 %t5, label %a5, label %b6
a5:
  br label %b6
b6:
  %c6 = and i32 %x, 64
  %t6 = icmp ne i32 %c6, 0
  br i1 %t6, label %a6, label %b7
a6:
  br label %b7
b7:
  %c7 = and i32 %x, 128
  %t7 = icmp ne i32 %c7, 0
  br i1 %t7, label %a7, label %b8
a7:
  br label %b8
b8:
  %c8 = and i32 %x, 256
  %t8 = icmp ne i32 %c8, 0
  br i1 %t8, label %a8, label %b9
a8:
  br label %b9
b9:
  %c9 = and i32 %x, 512
  %t9 = icmp ne i32 %c9, 0
  br i1 %t9, label %a9, label %b10
a9:
  br label %b10
b10:
  %c10 = and i32 %x, 1024
  %t10 = icmp ne i32 %c10, 0
  br i1 %t10, label %a10, label %b11
a10:
  br label %b11
b11:
  %c11 = and i32 %x, 2048
  %t11 = icmp ne i32 %c11, 0
  br i1 %t11, label %a11, label %b12
a11:
  br label %b12
b12:
  %c12 = and i32 %x, 4096
  %t12 = icmp ne i32 %c12, 0
  br i1 %t12, label %a12, label %b13
a12:
  br label %b13
b13:
  %c13 = and i32 %x, 8192
  %t13 = icmp ne i32 %c13, 0
  br i1 %t13, label %a13, label %b14
a13:
  br label %b14
b14:
  %c14 = and i32 %x, 16384
  %t14 = icmp ne i32 %c14, 0
  br i1 %t14, label %a14, label %b15
a14:
  br label %b15
b15:
  %c15 = and i32 %x, 32768
  %t15 = icmp ne i32 %c15, 0
  br i1 %t15, label %a15, label %b16
a15:
  br label %b16
b16:
  %c16 = and i32 %x, 1
  %t16 = icmp ne i32 %c16, 0
  br i1 %t16, label %a16, label %b17
a16:
  br label %b17
b17:
  %c17 = and i32 %x, 2
  %t17 = icmp ne i32 %c17, 0
  br i1 %t17, label %a17, label %b18
a17:
  br label %b18
b18:
  %c18 = and i32 %x, 4
  %t18 = icmp ne i32 %c18, 0
  br i1 %t18, label %a18, label %b19
a18:
  br label %b19
b19:
  %c19 = and i32 %x, 8
  %t19 = icmp ne i32 %c19, 0
  br i1 %t19, label %a19, label %b20
a19:
  br label %b20
b20:
  %c20 = and i32 %x, 16
  %t20 = icmp ne i32 %c20, 0
  br i1 %t20, label %a20, label %b21
a20:
  br label %b21
b21:
  %c21 = and i32 %x, 32
  %t21 = icmp ne i32 %c21, 0
  br i1 %t21, label %a21, label %b22
a21:
  br label %b22
b22:
  %c22 = and i32 %x, 64
  %t22 = icmp ne i32 %c22, 0
  br i1 %t22, label %a22, label %b23
a22:
  br label %b23
b23:
  %c23 = and i32 %x, 128
  %t23 = icmp ne i32 %c23, 0
  br i1 %t23, label %a23, label %b24
a23:
  br label %b24
b24:
  %c24 = and i32 %x, 256
  %t24 = icmp ne i32 %c24, 0
  br i1 %t24, label %a24, label %b25
a24:
  br label %b25
b25:
  %c25 = and i32 %x, 512
  %t25 = icmp ne i32 %c25, 0
  br i1 %t25, label %a25, label %b26
a25:
  br label %b26
b26:
  %c26 = and i32 %x, 1024
  %t26 = icmp ne i32 %c26, 0
  br i1 %t26, label %a26, label %b27
a26:
  br label %b27
b27:
  %c27 = and i32 %x, 2048
  %t27 = icmp ne i32 %c27, 0
  br i1 %t27, label %a27, label %b28
a27:
  br label %b28
b28:
  %c28 = and i32 %x, 4096
  %t28 = icmp ne i32 %c28, 0
  br i1 %t28, label %a28, label %b29
a28:
  br label %b29
b29:
  %c29 = and i32 %x, 8192
  %t29 = icmp ne i32 %c29, 0
  br i1 %t29, label %a29, label %b30
a29:
  br label %b30
b30:
  %c30 = and i32 %x, 16384
  %t30 = icmp ne i32 %c30, 0
  br i1 %t30, label %a30, label %b31
a30:
  br label %b31
b31:
  %c31 = and i32 %x, 32768
  %t31 = icmp ne i32 %c31, 0
  br i1 %t31, label %a31, label %b32
a31:
  br label %b32
b32:
  %c32 = and i32 %x, 1
  %t32 = icmp ne i32 %c32, 0
  br i1 %t32, label %a32, label %b33
a32:
  br label %b33
b33:
  %c33 = and i32 %x, 2
  %t33 = icmp ne i32 %c33, 0
  br i1 %t33, label %a33, label %b34
a33:
  br label %b34
b34:
  %c34 = and i32 %x, 4
  %t34 = icmp ne i32 %c34, 0
  br i1 %t34, label %a34, label %b35
a34:
  br label %b35
b35:
  %c35 = and i32 %x, 8
  %t35 = icmp ne i32 %c35, 0
  br i1 %t35, label %a35, label %b36
a35:
  br label %b36
b36:
  %c36 = and i32 %x, 16
  %t36 = icmp ne i32 %c36, 0
  br i1 %t36, label %a36, label %b37
a36:
  br label %b37
b37:
  %c37 = and i32 %x, 32
  %t37 = icmp ne i32 %c37, 0
  br i1 %t37, label %a37, label %b38
a37:
  br label %b38
b38:
  %c38 = and i32 %x, 64
  %t38 = icmp ne i32 %c38, 0
  br i1 %t38, label %a38, label %b39
a38:
  br label %b39
b39:
  %c39 = and i32 %x, 128
  %t39 = icmp ne i32 %c39, 0
  br i1 %t39, label %a39, label %b40
a39:
  br label %b40
b40:
  %y = xor i32 %x, 77
  ret i32 %y
}
; CHECK clone_cell_wide: call i32 @__cq_q_wide_11(i32 %{{x}}, ptr %{{s}})
; USERCHECK clone_cell_wide
