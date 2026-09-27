#!/usr/bin/env python3
"""Measure census over battery.py's outputs for TAG: for every ACCEPTED module,
count `@cq_measure_*` CALLS in the stage-1 IR and `@cqrt_measure_*` calls in the
lowered IR (any return attributes between `call` and the callee). A lowered
count below the source count is either a bd 21mg classical-measure lowering
(correct: the value is never quantum) or a deleted user measurement (the d88e /
3jru miscompile class); each is printed for a by-hand read. Also prints the
denominator."""
import pathlib
import re
import sys

P = pathlib.Path(__file__).resolve().parent.parent / "merge13" / "p"
tag = sys.argv[1]
CALL = re.compile(r"^\s*(?:%\S+ = )?(?:tail )?call [^@]*@(cq_measure_\w+|cqrt_measure_\w+)\(", re.M)
n = 0
for s2 in sorted(P.glob(f"*.{tag}.s2.ll")):
    m = s2.name[: -len(f".{tag}.s2.ll")]
    err = P / f"{m}.{tag}.err"
    if s2.stat().st_size == 0 or (err.exists() and "error:" in err.read_text(errors="replace")):
        continue
    n += 1
    src = [c for c in CALL.findall((P / f"{m}.s1.ll").read_text()) if c.startswith("cq_measure_")]
    out = [c for c in CALL.findall(s2.read_text()) if c.startswith("cqrt_measure_")]
    if len(src) != len(out):
        print(f"  {m}: source {len(src)} cq_measure {src}, lowered {len(out)} cqrt_measure {out}")
print(f"accepted modules examined: {n}")
