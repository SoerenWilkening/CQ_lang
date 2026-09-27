#!/usr/bin/env python3
"""Build yo.s1.ll: ya's linked module (the body of
taint_reject_scrubbed_handle_clone_arg.ll) with @main replaced by yo_main.ll —
the same program with `u = g(t)` laid out in a block BEFORE `t = h(q, m)`'s."""
import pathlib
import re

P = pathlib.Path(__file__).resolve().parent
body = (P / "taint_reject_scrubbed_handle_clone_arg.body.ll").read_text()
main = (P / "yo_main.ll").read_text()
new, n = re.subn(r"define i32 @main\(.*?\n}\n", main, body, count=1, flags=re.S)
assert n == 1
(P / "yo.s1.ll").write_text(new)
print("wrote", P / "yo.s1.ll")
