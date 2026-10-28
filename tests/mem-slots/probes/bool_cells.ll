; Rule 20, 58/60's _Bool cells without the loops: `bool q[n]` is i8 memory whose cells hold i1 rails.
; The i8 load of a cell is the handle of its i1 rail and the trunc to i1 is a representation change (no
; gate); the zext back to i8 stored into the cell is one too: the rotation is in place and nothing else is
; emitted (58, 60: "the i8<->i1 zext/trunc are representation changes, no gate").
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)

define i32 @bool_cells(ptr %q, i32 %i, double %t) {
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds i8, ptr %q, i64 %ii
  %b = load i8, ptr %p, align 1, !range !0, !noundef !1
  %c = trunc nuw i8 %b to i1
  %x = call zeroext i1 @cq_theta_i1(i1 zeroext %c, double %t)
  %z = zext i1 %x to i8
  store i8 %z, ptr %p, align 1
  %b2 = load i8, ptr %p, align 1, !range !0, !noundef !1
  %c2 = trunc nuw i8 %b2 to i1
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %c2)
  %r = zext i1 %m to i32
  ret i32 %r
}
!0 = !{i8 0, i8 2}
!1 = !{}
; CHECK bool_cells: %{{p}} = getelementptr inbounds i32, ptr %{{q}}, i64 %{{ii}}
; CHECK bool_cells: %{{h}} = load i32, ptr %{{p}}, align 4
; CHECK bool_cells: call void @cqrt_ry_i1(i32 %{{h}}, double %{{t}})
; CHECK bool_cells: call i1 @cqrt_measure_i1(i32 %{{h}})
; CHECK-COUNT bool_cells: cq_template 0
; CHECK-COUNT bool_cells: load i32 1
