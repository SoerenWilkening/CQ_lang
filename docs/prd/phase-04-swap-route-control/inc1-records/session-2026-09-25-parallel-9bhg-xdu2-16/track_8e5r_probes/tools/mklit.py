#!/usr/bin/env python3
"""mklit.py TAG PLAIN [DEBUGALLOC] — a private lit site config whose %cq-opt is
PLAIN and whose %debugalloc-cq-opt is DEBUGALLOC (default: PLAIN), both copied
into $T so a later rebuild of build/ cannot move them, with a private exec root.
Run with: lit $T/lit_TAG --filter ..."""
import os, shutil, sys
T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r"
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"
tag, plain = sys.argv[1], sys.argv[2]
dbg = sys.argv[3] if len(sys.argv) > 3 else plain
d = f"{T}/lit_{tag}"
os.makedirs(f"{d}/exec", exist_ok=True)
dp, dd = f"{T}/cq-opt.lit_{tag}", f"{T}/cq-opt-debugalloc.lit_{tag}"
for src, dst in ((plain, dp), (dbg, dd)):
    if os.path.abspath(src) != dst:
        shutil.copyfile(src, dst)
        os.chmod(dst, 0o755)
s = open(f"{W}/build/ir-pass/test/lit.site.cfg.py").read()
s = s.replace(f'config.cq_opt = "{W}/build/ir-pass/cq-opt"', f'config.cq_opt = "{dp}"')
s = s.replace(f'config.cq_opt_debugalloc = "{W}/build/ir-pass/cq-opt-debugalloc"', f'config.cq_opt_debugalloc = "{dd}"')
s = s.replace(f'config.test_exec_root = "{W}/build/ir-pass/test"', f'config.test_exec_root = "{d}/exec"')
assert dp in s and dd in s and f"{d}/exec" in s, "site config substitution failed"
open(f"{d}/lit.site.cfg.py", "w").write(s)
print(f"lit site {d}: %cq-opt={os.path.basename(plain)} %debugalloc-cq-opt={os.path.basename(dbg)}")
