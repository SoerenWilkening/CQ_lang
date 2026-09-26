#!/usr/bin/env python3
"""Evaluate lit.cfg.py's %debugalloc-cq-opt block (extracted verbatim) under the
site-config values ir-pass/test/CMakeLists.txt produces in each branch:
 (1) target present (today): debugalloc = its own path;
 (2) target ABSENT: CMake sets CQ_OPT_DEBUGALLOC_EXECUTABLE = CQ_OPT_EXECUTABLE (the
     fallback its comment still documents) -> the SAME path as cq-opt;
 (3) debugalloc older than cq-opt (control: must be fatal)."""
import os, re, sys, tempfile, time
src = open(sys.argv[1]).read()
blk = src[src.index("cq_opt_debugalloc = getattr(config"):src.index('config.substitutions.append(("%debugalloc-cq-opt"')]
class Fatal(Exception): pass
class LC:
    def fatal(self, m): raise Fatal(m)
def run(cq_opt, da):
    class C: pass
    config = C(); config.cq_opt_debugalloc = da
    ns = {"config": config, "lit_config": LC(), "os": os, "cq_opt": cq_opt}
    try:
        exec(blk, ns); return "no fatal; %debugalloc-cq-opt -> " + ns["cq_opt_debugalloc"]
    except Fatal as e:
        return "FATAL: " + str(e)[:90]
d = tempfile.mkdtemp()
opt = os.path.join(d, "cq-opt"); da = os.path.join(d, "cq-opt-debugalloc")
open(opt, "w").close(); time.sleep(0.05); open(da, "w").close()
print("(1) target present, debugalloc newer :", run(opt, da))
print("(2) target ABSENT -> CMake fallback   :", run(opt, opt))
os.utime(da, (1, 1))
print("(3) control: debugalloc OLDER        :", run(opt, da))
