#!/usr/bin/env python3
"""Build the combined (llvm-linked) stage-1 module of every run_slice_multi.sh
ctest entry, exactly as the harness does (CQ TU with -include CQ.h, libs plain),
into scratchpad d88e/multi/<test>.ll, and write the list to d88e/multilist.txt."""
import os
import re
import subprocess

W = ("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
     "agent-acf961e52a2f9e440")
S = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
     "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/d88e")
L = "/usr/local/opt/llvm@19/bin"
E2E = os.path.join(W, "tests/e2e")
text = open(os.path.join(E2E, "CMakeLists.txt")).read()
os.makedirs(os.path.join(S, "multi"), exist_ok=True)
out = []
for m in re.finditer(r"add_test\(NAME\s+(\S+)\s+COMMAND\s+bash\s+\"\$\{CMAKE_CURRENT_SOURCE_DIR\}/run_slice_multi\.sh\"(.*?)\)\s*\n", text, re.S):
    name, args = m.group(1), m.group(2)
    toks = re.findall(r'"([^"]*)"', args)
    # positional: CLANG OPT LLVMLINK PASS INC CQSRC LIBSRCS RT TPL GOLDEN [FLAGS]
    if len(toks) < 10:
        print("SKIP (unparsed)", name, len(toks))
        continue
    cq = toks[5].replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E)
    libs = toks[6].replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E).split()
    d = os.path.join(S, "multi", name)
    os.makedirs(d, exist_ok=True)
    ins = [os.path.join(d, "cq.ll")]
    subprocess.run([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1",
                    "-emit-llvm", "-S", cq, "-o", ins[0]], check=True)
    for i, lib in enumerate(libs):
        p = os.path.join(d, f"lib_{i}.ll")
        subprocess.run([L + "/clang", "-I" + W + "/include", "-O1", "-emit-llvm",
                        "-S", lib, "-o", p], check=True)
        ins.append(p)
    comb = os.path.join(S, "multi", name + ".ll")
    subprocess.run([L + "/llvm-link", "-S"] + ins + ["-o", comb], check=True)
    out.append(comb)
open(os.path.join(S, "multilist.txt"), "w").write("\n".join(out) + "\n")
print(len(out), "multi-TU modules")
