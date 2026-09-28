#!/usr/bin/env python3
"""bankmut.py — mutation-validate spec_accept_predicted_classical_bank.ll's two prefixes
(Rule 12: validate by mutation). Lowers the fixture with build/ir-pass/cq-opt, then
FileChecks the output (null) and two injected regressions:
  m1 — a `cqrt_measure_i32` call on a loaded integer (the Rule-3 wire crossing);
  m2 — the load no longer feeding the sum directly (a copy through an extra op).
Each prefix must pass the null and each injection must fail at least one prefix."""
import subprocess
import sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
FC = "/usr/local/opt/llvm@19/bin/FileCheck"
F = W + "/ir-pass/test/spec_accept_predicted_classical_bank.ll"
out = subprocess.run([W + "/build/ir-pass/cq-opt", "-passes=cq-lowering", "-S", F],
                     capture_output=True, text=True).stdout
anchor = "  %21 = add nsw i32 %20, %18"
assert out.count(anchor) == 1, "anchor moved; re-derive the injections"
cases = {
    "null": out,
    "m1": out.replace(anchor, "  %mm = call i32 @cqrt_measure_i32(i32 %20)\n  %21 = add nsw i32 %mm, %18"),
    "m2": out.replace(anchor, "  %mx = xor i32 %20, 0\n  %21 = add nsw i32 %mx, %18"),
}


def fc(prefix, text):
    args = [FC, F] + (["--check-prefix=" + prefix] if prefix else [])
    return subprocess.run(args, input=text, capture_output=True, text=True).returncode == 0


bad = 0
for name, text in cases.items():
    c, m = fc(None, text), fc("MEAS", text)
    ok = (c and m) if name == "null" else not (c and m)
    bad += not ok
    print(f"{name:5s} CHECK={'pass' if c else 'FAIL'} MEAS={'pass' if m else 'FAIL'} -> {'OK' if ok else 'WRONG'}")
sys.exit(1 if bad else 0)
