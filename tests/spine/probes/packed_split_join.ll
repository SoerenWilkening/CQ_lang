; cq-29ej (rule 26 with rule 4, cq-0umd): a packed integer whose quantum field the callee unpacks at other
; boundaries: the caller splits the field (lshr/trunc templates) and the callee joins its fields back (zext,
; shl, or templates) where it reads them whole (were stops).
; CHECK pk2: call i32 @cq_template_lshr_i32_hl(i32 %{{x}}, i32 16)
; CHECK __cq_q_g_110: call i32 @cq_template_or_i32(i32 %{{a}}, i32 %{{b}})
; USERCHECK pk2
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @pk2(i32 %x0, double %t, i32 %c) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %z = zext i32 %x to i64
  %h = zext i32 %c to i64
  %s = shl nuw i64 %h, 32
  %p = or disjoint i64 %s, %z
  %r = call fastcc i32 @g(i64 %p)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

define internal fastcc i32 @g(i64 %p) noinline {
entry:
  %a = trunc i64 %p to i16
  %s1 = lshr i64 %p, 16
  %b = trunc i64 %s1 to i16
  %s2 = lshr i64 %p, 32
  %c = trunc i64 %s2 to i32
  %w = trunc i64 %p to i32
  %a32 = sext i16 %a to i32
  %b32 = sext i16 %b to i32
  %m = mul i32 %a32, 3
  %t = add i32 %m, %b32
  %r0 = add i32 %t, %c
  %r = xor i32 %r0, %w
  ret i32 %r
}
