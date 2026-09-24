#!/usr/bin/env python3
"""Collect the round-3 reviewer probes into probes4/ (as *.bank.c, and the
hand-unrolled register twin of a1 as a1_park_after_xor.reg.c)."""
import pathlib, shutil
SP = pathlib.Path(__file__).parent
R = SP.parent / "reviewB_r3"
P = SP / "probes4"; P.mkdir(exist_ok=True)
for f in R.glob("*.c"):
    if f.name == "a1_reg_unrolled.c":
        shutil.copyfile(f, P / "a1_park_after_xor.reg.c")
    else:
        shutil.copyfile(f, P / (f.stem + ".bank.c"))
print(len(list(P.iterdir())))
