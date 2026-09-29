#!/usr/bin/env python3
"""Review r2 (scrubguard): the GATE'S OWN CLI (`taintset_scrub_guard.py --compile-commands ...`,
i.e. main(): no PCH, every configuration, include-order check) run on a PRIVATE worktree of the
subject commit whose REAL tree is mutated — needed because check() copies only the TOP-LEVEL `.h`
files of ir-pass/include into its probe dir, so a closure file in a SUBDIRECTORY or with another
extension (.def/.inc) is read from the real tree. For each case the real build command's -E of
CQLoweringPass.cpp is grepped for the member (proof the member is in the build).
usage: tree_probes_r2.py <private-worktree> <compile-db-rewritten-to-it>"""
import json, os, re, shlex, subprocess, sys
WT, CC = sys.argv[1], sys.argv[2]
INC = os.path.join(WT, "ir-pass", "include")
HDR = os.path.join(INC, "TaintPropagation.h")
CTX = "CQ_IRPASS_CQ_LOWERING_PASS_H_"
orig = open(HDR).read()
ANCH = "struct TaintSet {"
db = json.load(open(CC))
e = next(x for x in db if x["file"].endswith("src/CQLoweringPass.cpp") and "CQPass.dir" in x["command"])
argv = [a for a in shlex.split(e["command"])]
cut = []; skip = False
for a in argv:
    if skip: skip = False; continue
    if a in ("-o", "-c"): skip = (a == "-o"); continue
    if a.endswith("CQLoweringPass.cpp"): continue
    cut.append(a)
def build_has(marker):
    r = subprocess.run(cut + ["-E", "-w", e["file"]], cwd=e["directory"], capture_output=True, text=True)
    s = subprocess.run(cut + ["-fsyntax-only", "-w", e["file"]], cwd=e["directory"], capture_output=True, text=True)
    return r.returncode, s.returncode, [l.strip() for l in r.stdout.splitlines() if re.search(r"\b" + marker + r"\b", l)][:1]
def gate():
    r = subprocess.run([sys.executable, os.path.join(WT, "tools", "taintset_scrub_guard.py"),
                        "--compile-commands", CC, "--jobs", "4"], capture_output=True, text=True, cwd=WT)
    tail = [l for l in r.stdout.splitlines() if "problem" in l or "Rv" in l][-4:]
    return r.returncode, tail
CASES = [
  ("D0", "NULL: pristine private worktree", {}, orig, None, 0),
  ("D3", "POS: the member directly in TaintPropagation.h (A5 shape)", {},
   orig.replace(ANCH, ANCH + f"\n#ifdef {CTX}\n  std::set<llvm::Value *> RvDirect;\n#endif", 1), "RvDirect", 1),
  ("D1", "ATTACK: the same member in a SUBDIRECTORY project header (#include \"detail/RvSub.h\")",
   {"detail/RvSub.h": f"#ifndef RV_SUB_H\n#define RV_SUB_H\n#include <set>\n#include \"llvm/IR/Value.h\"\n"
                      f"namespace cq {{\nstruct RvSub {{\n  unsigned N = 0;\n#ifdef {CTX}\n"
                      f"  std::set<llvm::Value *> RvSubS;\n#endif\n}};\n}}\n#endif\n"},
   orig.replace("#include <set>\n", "#include <set>\n#include \"detail/RvSub.h\"\n", 1)
       .replace(ANCH, ANCH + "\n  RvSub RvSubM;", 1), "RvSubS", 1),
  ("D2", "ATTACK: the same member in an X-MACRO .def file included INSIDE TaintSet",
   {"TaintMembers.def": f"#ifdef {CTX}\n  std::set<llvm::Value *> RvDefMember;\n#endif\n"},
   orig.replace(ANCH, ANCH + "\n#include \"TaintMembers.def\"", 1), "RvDefMember", 1),
]
bad = 0
for cid, label, files, hdr, marker, want in CASES:
    made = []
    try:
        for rel, text in files.items():
            p = os.path.join(INC, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(text); made.append(p)
        open(HDR, "w").write(hdr)
        rc, tail = gate()
        b = build_has(marker) if marker else None
        ok = rc == want
        bad += not ok
        print(f"{'ok ' if ok else 'BAD'} {cid} gate exit {rc} (want {want}) — {label}")
        for t in tail: print("      gate: " + t[:230])
        if b: print(f"      build: CQLoweringPass.cpp -E exit {b[0]}, -fsyntax-only exit {b[1]}, `{marker}`: {b[2]}")
        sys.stdout.flush()
    finally:
        open(HDR, "w").write(orig)
        for p in made: os.remove(p)
print(f"cases {len(CASES)}, BAD {bad}")
