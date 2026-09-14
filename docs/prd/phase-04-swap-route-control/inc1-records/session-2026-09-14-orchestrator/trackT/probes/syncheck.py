import os, subprocess, sys, tempfile
sys.path.insert(0, "tools")
import loop_twin_matrix as M
LLVM = "/usr/local/opt/llvm@19/bin"
cells = M.cells_of_matrix()
names = {M.cell_name(c): c for c in cells}
new = [n for n in names if names[n][1] in M.B_REGION]
print("new bool cells:", len(new), flush=True)
fails = 0; warns = {}
d = tempfile.mkdtemp()
for n in sorted(new):
    r, u = M.sources(*names[n], surface="void")
    for side, txt in (("r", r), ("u", u)):
        p = os.path.join(d, n + side + ".c")
        open(p, "w").write(txt)
        cp = subprocess.run([LLVM+"/clang", "-I", "include", "-include", "CQ.h",
                             "-fsyntax-only", "-Wall", "-Wextra", p],
                            capture_output=True, text=True)
        if cp.returncode:
            fails += 1; print("COMPILE FAIL", n, side, cp.stderr[:400], flush=True)
        for line in cp.stderr.splitlines():
            if "warning:" in line and "-Wunused-parameter" not in line:
                k = line.split("warning:")[1].strip()
                warns[k] = warns.get(k, 0) + 1
print("compile failures:", fails)
for k, v in sorted(warns.items()): print("  warn x%d: %s" % (v, k))
