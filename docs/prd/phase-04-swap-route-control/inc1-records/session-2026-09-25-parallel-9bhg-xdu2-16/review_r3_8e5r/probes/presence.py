#!/usr/bin/env python3
"""presence.py — is each guard-MISSED member really in the BUILD's TaintSet?
Compiles, with each of the two real compile commands for ir-pass/src/TaintPropagation.cpp
(CQPass and cq-opt, from compile_commands.json), a TU that includes the mutated header and
static_asserts the raw member's type. rc 0 = member present in that target's view."""
import json, os, shlex, shutil, subprocess, sys, tempfile
sys.dont_write_bytecode = True
ROOT = sys.argv[1]
sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
db = json.load(open(os.path.join(ROOT, "build", "compile_commands.json")))
want = os.path.realpath(os.path.join(ROOT, "ir-pass/src/TaintPropagation.cpp"))
cmds = {}
for e in db:
    if os.path.realpath(os.path.join(e["directory"], e["file"])) != want:
        continue
    a = e.get("arguments") or shlex.split(e["command"])
    tgt = "CQPass" if "CQPass.dir" in e["output"] else ("cq-opt" if "cq-opt.dir" in e["output"] else e["output"])
    out, skip = [a[0]], False
    for x in a[1:]:
        if skip: skip = False; continue
        if x in ("-o", "-MF", "-MT", "-MQ"): skip = True; continue
        if x in ("-c", "-MD", "-MMD") or os.path.realpath(os.path.join(e["directory"], x)) == want: continue
        out.append(x)
    cmds[tgt] = (out, e["directory"])
hdr = open(G.HEADER).read(); ANCH = "struct TaintSet {"
def ins(member, pre=""):
    h = hdr.replace("#include <set>\n", "#include <set>\n" + G.EXTRA_INCLUDES, 1)
    return h.replace(ANCH, pre + ANCH + "\n  " + member, 1)
def ins_noextra(member, pre=""):
    return hdr.replace(ANCH, pre + ANCH + "\n  " + member, 1)
CASES = [
  ("B1", ins("R3Spec<unsigned> R3S;", "template <typename T> struct R3Spec { T X{}; };\n"
             "template <> struct R3Spec<unsigned> { llvm::Value *P = nullptr; };\n"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3S.P), llvm::Value *>::value, \"B1\");"),
  ("B2", ins("R3PS<int *> R3P;", "template <typename T> struct R3PS { T X{}; };\n"
             "template <typename T> struct R3PS<T *> { llvm::Value *P = nullptr; };\n"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3P.P), llvm::Value *>::value, \"B2\");"),
  ("B2b", ins("R3N<kR3Rel> R3NM;", "#ifdef NDEBUG\nconstexpr bool kR3Rel = true;\n#else\nconstexpr bool kR3Rel = false;\n#endif\n"
              "template <bool B> struct R3N { unsigned X = 0; };\n"
              "template <> struct R3N<true> { llvm::SmallPtrSet<llvm::Value *, 4> Raw; };\n"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3NM.Raw), llvm::SmallPtrSet<llvm::Value *, 4>>::value, \"B2b\");"),
  ("B3", ins("#ifndef CQPass_EXPORTS\n  llvm::Value *R3NotPlugin = nullptr;\n#endif"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3NotPlugin), llvm::Value *>::value, \"B3\");"),
  ("B4", ins_noextra("#ifndef LLVM_ANALYSIS_LOOPINFO_H\n  llvm::Value *R3PchCtx = nullptr;\n#endif"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3PchCtx), llvm::Value *>::value, \"B4\");"),
  ("B7", ins("std::set<R3Key> R3KS;", "struct R3Key { llvm::WeakVH H; bool operator<(const R3Key &O) const {"
             " return static_cast<llvm::Value *>(H) < static_cast<llvm::Value *>(O.H); } };\n"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3KS), std::set<cq::R3Key>>::value, \"B7\");"),
  ("B8", ins("R3Rec *R3AP = nullptr;", "namespace r3other { struct R3Rec { unsigned X = 0; }; }\n"
             "struct R3RawRec2 { llvm::Value *P = nullptr; };\nusing R3Rec = R3RawRec2;\n"),
   "static_assert(std::is_same<decltype(cq::TaintSet::R3AP->P), llvm::Value *>::value, \"B8\");"),
]
for name, h, sa in CASES:
    d = tempfile.mkdtemp(prefix="r3pres_")
    for f in os.listdir(G.INCLUDE_DIR):
        if f.endswith(".h"): shutil.copyfile(os.path.join(G.INCLUDE_DIR, f), os.path.join(d, f))
    open(os.path.join(d, "TaintPropagation.h"), "w").write(h)
    tu = os.path.join(d, "tu.cpp")
    open(tu, "w").write('#include "TaintPropagation.h"\n#include <type_traits>\n' + sa + "\n")
    row = []
    for tgt, (base, cwd) in sorted(cmds.items()):
        r = subprocess.run(base + ["-fsyntax-only", "-w", tu], capture_output=True, text=True, cwd=cwd)
        row.append(f"{tgt}:{'PRESENT' if r.returncode == 0 else 'absent/err'}")
    print(name, " ".join(row))
    shutil.rmtree(d, ignore_errors=True)
