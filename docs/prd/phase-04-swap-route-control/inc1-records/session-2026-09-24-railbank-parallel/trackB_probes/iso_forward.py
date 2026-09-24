#!/usr/bin/env python3
"""Isolate the FORWARD hop: build a binary with the collapse fence's bank-load hop
disabled (and, second, ALSO with SeedIsCellRead forced false), save both, restore
the tree, rebuild. Then run the probes through each."""
import pathlib, subprocess, shutil
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
SP = pathlib.Path(__file__).parent
LL = WT / "ir-pass/src/LoopLowering.cpp"
OL = WT / "ir-pass/src/OpcodeLowering.cpp"

def sh(cmd):
    return subprocess.run(cmd, cwd=WT, capture_output=True, text=True)

def build(tag):
    r = sh(["cmake", "--build", "build", "-j3", "--target", "CQPass", "cq-opt"])
    assert r.returncode == 0, r.stdout[-2000:]
    shutil.copyfile(WT / "build/ir-pass/cq-opt", SP / f"cq-opt.{tag}")
    (SP / f"cq-opt.{tag}").chmod(0o755)

ll0, ol0 = LL.read_text(), OL.read_text()
A = "    if (railBankCellReadsOf(V, CellReads))\n"
B = "                                    /*SeedIsCellRead=*/Hopped))"
assert ll0.count(A) == 1 and ol0.count(B) == 1
try:
    LL.write_text(ll0.replace(A, "    if (false && railBankCellReadsOf(V, CellReads))\n"))
    build("nocollapsehop")
    OL.write_text(ol0.replace(B, "                                    /*SeedIsCellRead=*/false))"))
    build("nocollapsehop_nocell")
finally:
    LL.write_text(ll0); OL.write_text(ol0)
    build("final")
print(sh(["shasum", "-a", "256", "build/ir-pass/cq-opt"]).stdout[:16])
