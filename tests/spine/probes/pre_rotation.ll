; cq-s32y: a use of a register's pre-rotation value after its in-place rotation reads a copy taken
; just before the Ry (alloc 0, copy_<W>); a rotation whose old value nothing reads later copies
; nothing. cq-nvfi: a value computed from a register before its rotation never collapses to the
; register's later outcome.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i8 @cq_theta_ui8(i8, double)

; invert-h2 q6n: w = x; cq_theta(&x, phi); return cq_measure(w).
define i32 @old_read(i32 %x0, double %th, double %phi) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %x2 = call i32 @cq_theta_si32(i32 %x, double %phi)
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK old_read: %{{x}} = call i32 @cqrt_alloc_i32(i32 %{{x0}})
; CHECK old_read: call void @cqrt_ry_i32(i32 %{{x}}, double %{{th}})
; CHECK old_read: %{{c}} = call i32 @cqrt_alloc_i32(i32 0)
; CHECK old_read: call void @cqrt_copy_i32(i32 %{{x}}, i32 %{{c}})
; CHECK old_read: call void @cqrt_ry_i32(i32 %{{x}}, double %{{phi}})
; CHECK old_read: %{{m}} = call i32 @cqrt_measure_i32(i32 %{{c}})
; CHECK-COUNT old_read: cqrt_copy_i32 1

; No later reader of the old value (38's shape): in place, nothing copied.
define i32 @no_old_read(i32 %x0, double %a, double %b) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %a)
  %x2 = call i32 @cq_theta_si32(i32 %x, double %b)
  %m = call i32 @cq_measure_si32(i32 %x2)
  ret i32 %m
}
; CHECK-COUNT no_old_read: cqrt_copy 0
; CHECK-COUNT no_old_read: cqrt_alloc_i32 1

; qangle-h1 p6 (cq-nvfi): y = r + 1 read r before r's rotation; after measuring r, y is still
; measured from its own rail (three measurements), never recomputed from r's outcome.
define i32 @before_rot(i32 %x0, double %tx, i32 %r0, double %tr) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %r = call i32 @cq_theta_si32(i32 %r0, double %tr)
  %y = add nsw i32 %r, 1
  %r2 = call i32 @cq_theta_si32(i32 %r, double %tx)
  %mr = call i32 @cq_measure_si32(i32 %r2)
  %mx = call i32 @cq_measure_si32(i32 %x)
  %s = add nsw i32 %mx, %mr
  %my = call i32 @cq_measure_si32(i32 %y)
  %t = add nsw i32 %s, %my
  ret i32 %t
}
; CHECK-COUNT before_rot: cqrt_measure_i32 3
; CHECK-COUNT before_rot: cqrt_copy 0

; fatptr-h2 c13 without the pointers: a rule 10 controlled rotation; the merge names the rotated
; register itself, and the old value read after the join reads the copy.
define i32 @ctl(i8 %x0, i8 %y0, double %th, double %th2) {
entry:
  %x = call i8 @cq_theta_ui8(i8 %x0, double %th)
  %y = call i8 @cq_theta_ui8(i8 %y0, double %th)
  %b = and i8 %y, 1
  %z = icmp eq i8 %b, 0
  br i1 %z, label %j, label %t
t:
  %x2 = call i8 @cq_theta_ui8(i8 %x, double %th2)
  br label %j
j:
  %xm = phi i8 [ %x2, %t ], [ %x, %entry ]
  %e1 = zext i8 %x to i32
  %e2 = zext i8 %xm to i32
  %d = sub nsw i32 %e1, %e2
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
; CHECK ctl: %{{x}} = call i32 @cqrt_alloc_i8(i8 %{{x0}})
; CHECK ctl: %{{c}} = call i32 @cqrt_alloc_i8(i8 0)
; CHECK ctl: call void @cqrt_copy_i8(i32 %{{x}}, i32 %{{c}})
; CHECK ctl: call void @cqrt_ry_i8_controlled(i32 %{{f}}, i32 %{{x}}, double %{{th2}})
; CHECK ctl: %{{e1}} = call i32 @cq_template_zext_i8_to_i32(i32 %{{c}})
; CHECK ctl: %{{e2}} = call i32 @cq_template_zext_i8_to_i32(i32 %{{x}})
; CHECK-COUNT ctl: cqrt_copy_i8 1
; CHECK-COUNT ctl: cq_template_select 0
