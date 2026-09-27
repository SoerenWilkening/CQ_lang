#!/usr/bin/env python3
"""Build stage-1 modules for the A/B sweep:
  * every tests/e2e/CMakeLists.txt run_slice_multi.sh registration (CQ TU at -O1
    with -include CQ.h, plain-C libs at -O1, llvm-link) -> multi/m<i>.ll
  * every tests/e2e/*.c compiled standalone (default CASE) -> single/<stem>.ll
Writes multi.lst and single.lst (only modules that built) and prints counts."""
import pathlib
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor

W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
P = pathlib.Path(__file__).resolve().parent
E = W / "tests/e2e"
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
(P / "multi").mkdir(exist_ok=True)
(P / "single").mkdir(exist_ok=True)

cm = (E / "CMakeLists.txt").read_text()
blocks = re.findall(r'run_slice_multi\.sh"(.*?)\)', cm, re.S)
multi = []
for i, b in enumerate(blocks):
    srcs = re.findall(r'"\$\{CMAKE_CURRENT_SOURCE_DIR\}/([^"]*)"', b)
    srcs = [s for s in srcs if not s.endswith(".expected.log")]
    if not srcs:
        continue
    cq, libs = srcs[0], []
    for s in srcs[1:]:
        for x in re.split(r"[;\s]+", s.replace("${CMAKE_CURRENT_SOURCE_DIR}/", "")):
            if x:
                libs.append(x)
    parts = [P / "multi" / f"m{i}_cq.ll"]
    subprocess.run([str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1",
                    "-emit-llvm", "-S", str(E / cq), "-o", str(parts[0])], check=True)
    for j, lib in enumerate(libs):
        p = P / "multi" / f"m{i}_l{j}.ll"
        subprocess.run([str(L / "clang"), "-O1", "-emit-llvm", "-S", str(E / lib), "-o", str(p)],
                       check=True)
        parts.append(p)
    out = P / "multi" / f"m{i}.ll"
    subprocess.run([str(L / "llvm-link"), "-S", *map(str, parts), "-o", str(out)], check=True)
    multi.append(out)
(P / "multi.lst").write_text("".join(f"{m}\n" for m in multi))
print(f"multi: {len(multi)} linked modules from {len(blocks)} registrations")


def one(c):
    s1 = P / "single" / (c.stem + ".ll")
    r = subprocess.run([str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1",
                        "-emit-llvm", "-S", str(c), "-o", str(s1)], capture_output=True)
    return s1 if r.returncode == 0 else None


srcs = sorted(E.glob("*.c"))
with ThreadPoolExecutor(8) as ex:
    single = [s for s in ex.map(one, srcs) if s]
(P / "single.lst").write_text("".join(f"{m}\n" for m in single))
print(f"single: {len(single)} of {len(srcs)} tests/e2e/*.c compiled standalone")
