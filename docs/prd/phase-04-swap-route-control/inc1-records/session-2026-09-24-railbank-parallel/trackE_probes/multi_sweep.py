#!/usr/bin/env python3
"""Build every run_slice_multi.sh module (clang -O1 CQ TU with -include CQ.h, libs
plain, llvm-link) and compare this build vs a reference by exit code + stdout sha.
Null control (reference vs itself) first. Prints denominators."""
import hashlib
import pathlib
import re
import subprocess
import sys
import tempfile

W = pathlib.Path(__file__).resolve().parent.parent
E = W / "tests/e2e"
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
NEW = W / "build/ir-pass/cq-opt"
REF = pathlib.Path(sys.argv[1])
cm = (E / "CMakeLists.txt").read_text()
blocks = re.findall(r'run_slice_multi\.sh"(.*?)\)', cm, re.S)
tmp = pathlib.Path(tempfile.mkdtemp())
mods = []
for i, b in enumerate(blocks):
    srcs = re.findall(r'"\$\{CMAKE_CURRENT_SOURCE_DIR\}/([^"]*)"', b)
    srcs = [s for s in srcs if not s.endswith(".expected.log")]
    if not srcs:
        continue
    cq = srcs[0]
    libs = []
    for s in srcs[1:]:
        for x in re.split(r"[;\s]+", s.replace("${CMAKE_CURRENT_SOURCE_DIR}/", "")):
            if x:
                libs.append(x)
    out = tmp / f"m{i}.ll"
    parts = []
    subprocess.run([str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1",
                    "-emit-llvm", "-S", str(E / cq), "-o", str(tmp / f"m{i}_cq.ll")], check=True)
    parts.append(tmp / f"m{i}_cq.ll")
    for j, lib in enumerate(libs):
        p = tmp / f"m{i}_l{j}.ll"
        subprocess.run([str(L / "clang"), "-O1", "-emit-llvm", "-S", str(E / lib), "-o", str(p)],
                       check=True)
        parts.append(p)
    subprocess.run([str(L / "llvm-link"), "-S", *map(str, parts), "-o", str(out)], check=True)
    mods.append((cq, out))


def run(b, f):
    r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True)
    return r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16]


null = sum(run(REF, f) != run(REF, f) for _, f in mods)
print(f"null control: {null} of {len(mods)}")
mv = [(n, run(REF, f), run(NEW, f)) for n, f in mods]
mv = [x for x in mv if x[1] != x[2]]
print(f"built {len(mods)} linked modules from {len(blocks)} registrations; {len(mv)} mover(s)")
for m in mv:
    print("  MOVER", m)
