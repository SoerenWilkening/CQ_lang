#!/usr/bin/env python3
"""Negative controls for railbank_stale_accept_runtime_condprep_gate_order.ll:
each prefix run against a WRONG module must fail; against the real one, pass."""
import pathlib, subprocess
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
SP = pathlib.Path(__file__).parent
F = WT / "ir-pass/test/railbank_stale_accept_runtime_condprep_gate_order.ll"
FC = "/usr/local/opt/llvm@19/bin/FileCheck"
good = (SP / "out/h04_condprep_control.bank.s2.ll").read_text()
muts = {
    "good": good,
    "h05-other-module": (SP / "out/h05_passH_control.bank.s2.ll").read_text(),
    "ctl/target-swapped": good.replace("cqrt_ry_i32_controlled(i32 %h_cmp, i32 %cq.bank.seed",
                                       "cqrt_ry_i32_controlled(i32 %cq.bank.seed, i32 %h_cmp"),
    "seed-alloc-after-flag": good.replace(
        "  %cq.bank.seed = call i32 @cqrt_alloc_i32(i32 0), !cq.railbank.seed !7\n  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 1)\n",
        "  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 1)\n  %cq.bank.seed = call i32 @cqrt_alloc_i32(i32 0), !cq.railbank.seed !7\n"),
    "seed-freed": good.replace("  call void @cqrt_free(i32 %h_cmp1)\n",
                               "  call void @cqrt_free(i32 %h_cmp1)\n  call void @cqrt_free(i32 %cq.bank.seed)\n"),
}
for name, txt in muts.items():
    changed = name == "good" or txt != good
    p = SP / "ctl" / (name.replace("/", "_") + ".ll"); p.parent.mkdir(exist_ok=True); p.write_text(txt)
    res = {}
    for pre in ("IR", "CRYC", "CMEAS", "NOTS"):
        res[pre] = subprocess.run([FC, f"--check-prefix={pre}", f"--input-file={p}", str(F)],
                                  capture_output=True).returncode
    print(f"{name:24s} applied={changed} " + " ".join(f"{k}={v}" for k, v in res.items()))
print("denominator: 4 mutants + 1 good")
