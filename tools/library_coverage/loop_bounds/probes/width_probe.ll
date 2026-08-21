; bd 8zj2 — MECHANISM PROBE. Is the constant max BTC a BIT-WIDTH fact (⇒ provably
; input-independent) or an artifact of the counter's nsw overflow (the L3 memo's
; §3 "P3" vacuous-bound hazard)? Same loop, three widths, and one copy with the
; counter DELETED. If the bound tracks the type width and survives counter
; removal, it is the shift analysis, not the counter.

; i32 — the ilogb.f64 / ilogbf.f32 shape verbatim (shl nuw, icmp sgt .., 0)
define i32 @shift_i32(i32 %init) {
entry:
  %c = icmp sgt i32 %init, 0
  br i1 %c, label %loop, label %exit
loop:
  %ix = phi i32 [ -1043, %entry ], [ %ixn, %loop ]
  %v  = phi i32 [ %init, %entry ], [ %vn, %loop ]
  %ixn = add nsw i32 %ix, -1
  %vn  = shl nuw i32 %v, 1
  %t   = icmp sgt i32 %vn, 0
  br i1 %t, label %loop, label %exit
exit:
  %r = phi i32 [ -1043, %entry ], [ %ixn, %loop ]
  ret i32 %r
}

; i64 — same shape, wider type. A width fact must report 64 here.
define i64 @shift_i64(i64 %init) {
entry:
  %c = icmp sgt i64 %init, 0
  br i1 %c, label %loop, label %exit
loop:
  %ix = phi i64 [ -1043, %entry ], [ %ixn, %loop ]
  %v  = phi i64 [ %init, %entry ], [ %vn, %loop ]
  %ixn = add nsw i64 %ix, -1
  %vn  = shl nuw i64 %v, 1
  %t   = icmp sgt i64 %vn, 0
  br i1 %t, label %loop, label %exit
exit:
  %r = phi i64 [ -1043, %entry ], [ %ixn, %loop ]
  ret i64 %r
}

; i16 — narrower. A width fact must report 16 here.
define i16 @shift_i16(i16 %init) {
entry:
  %c = icmp sgt i16 %init, 0
  br i1 %c, label %loop, label %exit
loop:
  %ix = phi i16 [ -1043, %entry ], [ %ixn, %loop ]
  %v  = phi i16 [ %init, %entry ], [ %vn, %loop ]
  %ixn = add nsw i16 %ix, -1
  %vn  = shl nuw i16 %v, 1
  %t   = icmp sgt i16 %vn, 0
  br i1 %t, label %loop, label %exit
exit:
  %r = phi i16 [ -1043, %entry ], [ %ixn, %loop ]
  ret i16 %r
}

; i32 with NO counter at all — if the bound survives, it cannot be counter-derived.
define i32 @shift_i32_nocounter(i32 %init) {
entry:
  %c = icmp sgt i32 %init, 0
  br i1 %c, label %loop, label %exit
loop:
  %v  = phi i32 [ %init, %entry ], [ %vn, %loop ]
  %vn = shl nuw i32 %v, 1
  %t  = icmp sgt i32 %vn, 0
  br i1 %t, label %loop, label %exit
exit:
  ret i32 0
}

; i32, counter present but WITHOUT nsw — removes the overflow-based bound source.
define i32 @shift_i32_counter_wrapping(i32 %init) {
entry:
  %c = icmp sgt i32 %init, 0
  br i1 %c, label %loop, label %exit
loop:
  %ix = phi i32 [ -1043, %entry ], [ %ixn, %loop ]
  %v  = phi i32 [ %init, %entry ], [ %vn, %loop ]
  %ixn = add i32 %ix, -1
  %vn  = shl i32 %v, 1
  %t   = icmp sgt i32 %vn, 0
  br i1 %t, label %loop, label %exit
exit:
  %r = phi i32 [ -1043, %entry ], [ %ixn, %loop ]
  ret i32 %r
}

; CONTROL: a genuinely UNBOUNDABLE loop (the L4 "normalize" class the L3 memo
; reports Unpredictable for) — the shift amount is data-dependent.
define i32 @shift_i32_datadep(i32 %init, i32 %amt) {
entry:
  %c = icmp sgt i32 %init, 0
  br i1 %c, label %loop, label %exit
loop:
  %v  = phi i32 [ %init, %entry ], [ %vn, %loop ]
  %vn = shl i32 %v, %amt
  %t  = icmp sgt i32 %vn, 0
  br i1 %t, label %loop, label %exit
exit:
  ret i32 0
}
