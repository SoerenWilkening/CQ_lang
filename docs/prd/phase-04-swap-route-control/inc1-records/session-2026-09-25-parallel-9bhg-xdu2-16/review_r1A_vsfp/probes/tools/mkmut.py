#!/usr/bin/env python3
"""mkmut.py NAME FILE 'old' 'new' — apply a one-site source mutation in the private worktree,
bump mtime, build cq-opt, copy to bin/cq-opt.NAME, restore the source (and rebuild nothing).
Prints the binary hash. Refuses if 'old' does not occur exactly once."""
import sys, subprocess, pathlib, hashlib, time, os, shutil
R = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rA_vsfp")
WT = R / "wt"
name, f = sys.argv[1:3]; pairs = list(zip(sys.argv[3::2], sys.argv[4::2]))
p = WT / "ir-pass" / "src" / f
src = p.read_text()
mut = src
for old, new in pairs:
    if mut.count(old) != 1:
        sys.exit(f"REFUSE: 'old' occurs {mut.count(old)} times in {f}")
    mut = mut.replace(old, new)
try:
    p.write_text(mut)
    t = time.time() + 5
    os.utime(p, (t, t))
    r = subprocess.run(["cmake", "--build", str(WT / "build"), "--target", "cq-opt", "-j6"], capture_output=True, text=True)
    if r.returncode:
        print(r.stdout[-2000:], r.stderr[-2000:]); sys.exit("BUILD FAILED")
    out = R / "bin" / f"cq-opt.{name}"
    shutil.copyfile(WT / "build/ir-pass/cq-opt", out); os.chmod(out, 0o755)
    print(name, hashlib.sha256(out.read_bytes()).hexdigest()[:16])
finally:
    p.write_text(src)
    t = time.time() + 10
    os.utime(p, (t, t))
