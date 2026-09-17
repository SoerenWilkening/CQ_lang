; sx (IR half) — the SAME two calls with the pass's own declaration shape: NO
; `signext` on the narrow parameter, which is exactly what `WidthDispatch`
; emits (`FunctionType::get(Handle, {Handle, Classical}, false)` — no attrs).
declare i32 @cq_template_add_i16_hl(i32, i16)
declare i32 @cq_template_add_i8_hl(i32, i8)

define i32 @main() {
entry:
  %a = call i32 @cq_template_add_i16_hl(i32 0, i16 -3)
  %b = call i32 @cq_template_add_i8_hl(i32 0, i8 -3)
  ret i32 0
}
