exec(open(__file__.replace("gen_n.py","gen.py")).read())
mk("N2.ll", "  %r = tail call i32 @h(i32 noundef %q, i32 noundef %z)", """
define i32 @h(i32 noundef %a, i32 noundef %b) {
  %t = mul nsw i32 %a, 5
  %r0 = tail call i32 @g(i32 noundef %t, i32 noundef %b)
  %r = add nsw i32 %r0, %a
  ret i32 %r
}""", G_DEAD)
mk("N2T.ll", "  %r = tail call i32 @h(i32 noundef %q, i32 noundef %z)", """
define i32 @h(i32 noundef %a, i32 noundef %b) {
  %r0 = tail call i32 @g(i32 noundef %b)
  %r = add nsw i32 %r0, %a
  ret i32 %r
}""", G_T)
mk("N3.ll", """  %r1 = tail call i32 @h1(i32 noundef %q, i32 noundef %z)
  %r2 = tail call i32 @h2(i32 noundef %q, i32 noundef %z)
  %r3 = tail call i32 @g(i32 noundef %q, i32 noundef %z)
  %r4 = add i32 %r1, %r2
  %r = add i32 %r4, %r3""", """
define i32 @h1(i32 noundef %a, i32 noundef %b) {
  %t = add nsw i32 %a, 1
  %r = tail call i32 @g(i32 noundef %t, i32 noundef %b)
  ret i32 %r
}
define i32 @h2(i32 noundef %a, i32 noundef %b) {
  %r = tail call i32 @g(i32 noundef %a, i32 noundef %b)
  ret i32 %r
}""", G_DEAD)
mk("N3T.ll", """  %r1 = tail call i32 @h1(i32 noundef %z)
  %r2 = tail call i32 @h2(i32 noundef %z)
  %r3 = tail call i32 @g(i32 noundef %z)
  %r4 = add i32 %r1, %r2
  %r = add i32 %r4, %r3""", """
define i32 @h1(i32 noundef %b) {
  %r = tail call i32 @g(i32 noundef %b)
  ret i32 %r
}
define i32 @h2(i32 noundef %b) {
  %r = tail call i32 @g(i32 noundef %b)
  ret i32 %r
}""", G_T)
mk("N5.ll", "  %r = tail call i32 @k(i32 noundef %q, i32 noundef %z)", """
define i32 @k(i32 noundef %a, i32 noundef %b) {
  %t = xor i32 %a, 6
  %r = tail call i32 @h(i32 noundef %t, i32 noundef %b)
  ret i32 %r
}
define i32 @h(i32 noundef %a, i32 noundef %b) {
  %b2 = add nsw i32 %b, 1
  %r = tail call i32 @g(i32 noundef %a, i32 noundef %b2)
  ret i32 %r
}""", G_DEAD)
mk("N5T.ll", "  %r = tail call i32 @k(i32 noundef %q, i32 noundef %z)", """
define i32 @k(i32 noundef %a, i32 noundef %b) {
  %r = tail call i32 @h(i32 noundef %b)
  ret i32 %r
}
define i32 @h(i32 noundef %b) {
  %b2 = add nsw i32 %b, 1
  %r = tail call i32 @g(i32 noundef %b2)
  ret i32 %r
}""", G_T)
