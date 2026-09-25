#!/usr/bin/env python3
"""rm2.s1.ll: rm1's linked module with @f rewritten to TWO `ret`s (one returning the
specialization result `t`, one returning the register `q`) — the shape `-O1`
merges into one `ret` of a `select`, hand-written so the per-return clause of
`returnTaintIsSpecProvisional` ("EVERY tainted return value in the cone") has a
subject."""
import pathlib
import re

P = pathlib.Path(__file__).resolve().parent
body = (P / "rm1.s1.ll").read_text()
f = """define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %t = tail call i32 @h(i32 noundef %q, i32 noundef %0) #5
  %c = icmp sgt i32 %1, 2
  br i1 %c, label %rt, label %rq

rt:                                               ; preds = %entry
  ret i32 %t

rq:                                               ; preds = %entry
  ret i32 %q
}
"""
new, n = re.subn(r"define i32 @f\(.*?\n}\n", f, body, count=1, flags=re.S)
assert n == 1
(P / "rm2.s1.ll").write_text(new)
print("wrote", P / "rm2.s1.ll")
