#!/usr/bin/env python3
"""Rule-13 r3 (8e5r): try to fool the AST taintset_scrub_guard at 9cce073d.
Imports the guard UNMODIFIED from the subject tree (no .pyc written) and calls its
check() with mutated TaintPropagation.h texts, exactly as the r2 corpus did.
Controls first: pristine clean (null), raw `llvm::Value *` refused (positive).
Each attack prints CAUGHT (first diagnostic) or MISSED. A MISS is only possible
when the mutated header COMPILED with the build's command (a compile error is a
refusal), so every MISS is a header the build accepts.
usage: guard_fool_r3.py <subject-worktree> [--no-pch]"""
import os, sys, time, shutil, tempfile
sys.dont_write_bytecode = True
ROOT = sys.argv[1]
sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
if "--no-pch" in sys.argv:
    G.USE_PCH = False

hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
ANCH = "struct TaintSet {"
assert hdr.count(ANCH) == 1

def ins(member, pre=""):
    h = hdr.replace("#include <set>\n", "#include <set>\n" + G.EXTRA_INCLUDES, 1)
    assert h != hdr
    return h.replace(ANCH, pre + ANCH + "\n  " + member, 1)

def ins_noextra(member, pre=""):
    # WITHOUT the guard's EXTRA_INCLUDES, so the TU's own include closure is the header's
    return hdr.replace(ANCH, pre + ANCH + "\n  " + member, 1)

P = [
  ("NULL: pristine header", hdr, True, False),
  ("NULL: pristine + extra includes", ins(""), True, False),
  ("NULL: bitfield member", ins("unsigned R3Bits : 3;"), True, False),
  ("POS: raw llvm::Value * member", ins("llvm::Value *R3Stray = nullptr;"), True, True),
  ("POS: raw ptr in a BASE of a project record",
   ins("R3Der R3D;", "struct R3Base { llvm::Value *P = nullptr; };\nstruct R3Der : R3Base { int X = 0; };\n"), True, True),
  ("POS: project template base instantiated with a Value type",
   ins("R3DD R3DDm;", "template <class T> struct R3TB { T *P = nullptr; };\nstruct R3DD : R3TB<llvm::Instruction> {};\n"), True, True),
  ("POS: pimpl to a type defined only in a .cpp",
   ins("std::unique_ptr<R3Fwd> R3Pimpl;", "struct R3Fwd;\n"), True, True),
  ("POS: raw pointer to a type forward-declared only",
   ins("R3Fwd2 *R3FwdP = nullptr;", "struct R3Fwd2;\n"), True, True),
  ("POS: lambda static member capturing a Value*",
   ins("static inline auto R3L = [P = static_cast<llvm::Value *>(nullptr)]() { return P; };"), True, True),
  ("POS: std::function returning Value*", ins("std::function<llvm::Value *()> R3Fn;"), True, True),
  ("POS: named union with a Value* arm",
   ins("R3U R3Um;", "union R3U { llvm::Value *P; unsigned long I; };\n"), True, True),
  ("POS: pair<WeakVH,int> KEY of std::map (HKEY positive twin of B7)",
   ins("std::map<std::pair<llvm::WeakVH, int>, int> R3PK;"), True, True),
  # --- attacks
  ("B1 explicit FULL specialization of a project class template holds a raw Value*",
   ins("R3Spec<unsigned> R3S;",
       "template <typename T> struct R3Spec { T X{}; };\n"
       "template <> struct R3Spec<unsigned> { llvm::Value *P = nullptr; };\n"), False, True),
  ("B2 PARTIAL specialization of a project class template holds a raw Value*",
   ins("R3PS<int *> R3P;",
       "template <typename T> struct R3PS { T X{}; };\n"
       "template <typename T> struct R3PS<T *> { llvm::Value *P = nullptr; };\n"), False, True),
  ("B2b full specialization selected only under NDEBUG (Release) via a constexpr flag",
   ins("R3N<kR3Rel> R3NM;",
       "#ifdef NDEBUG\nconstexpr bool kR3Rel = true;\n#else\nconstexpr bool kR3Rel = false;\n#endif\n"
       "template <bool B> struct R3N { unsigned X = 0; };\n"
       "template <> struct R3N<true> { llvm::SmallPtrSet<llvm::Value *, 4> Raw; };\n"), False, True),
  ("B3 raw member present in cq-opt's build but not in CQPass's (#ifndef CQPass_EXPORTS)",
   ins("#ifndef CQPass_EXPORTS\n  llvm::Value *R3NotPlugin = nullptr;\n#endif"), False, True),
  ("B4 raw member hidden by the guard's PCH context (#ifndef LLVM_ANALYSIS_LOOPINFO_H)",
   ins_noextra("#ifndef LLVM_ANALYSIS_LOOPINFO_H\n  llvm::Value *R3PchCtx = nullptr;\n#endif"), False, True),
  ("B7 value handle wrapped in a project record, as an ordered std::set KEY",
   ins("std::set<R3Key> R3KS;",
       "struct R3Key { llvm::WeakVH H; bool operator<(const R3Key &O) const {"
       " return static_cast<llvm::Value *>(H) < static_cast<llvm::Value *>(O.H); } };\n"), False, True),
  ("B8 unqualified pointer to an ALIAS whose short name is also a clean record's",
   ins("R3Rec *R3AP = nullptr;",
       "namespace r3other { struct R3Rec { unsigned X = 0; }; }\n"
       "struct R3RawRec2 { llvm::Value *P = nullptr; };\nusing R3Rec = R3RawRec2;\n"), False, True),
  ("B8b qualified pointer to a project record whose short name a clean record shares (control)",
   ins("r3a::R3Q *R3QP = nullptr;",
       "namespace r3a { struct R3Q { llvm::Value *P = nullptr; }; }\nnamespace r3b { struct R3Q { unsigned X = 0; }; }\n"),
   True, True),
]

t0 = time.time(); missed = []; bad_ctl = []
for label, h, is_ctl, expect in P:
    errs, n = G.check(h, st, G.ALLOWLIST, sc)
    caught = bool(errs)
    if is_ctl:
        ok = (caught == expect)
        tag = ("ok " if ok else "BAD") + (" control-refused" if caught else " control-clean")
        if not ok:
            bad_ctl.append(label)
    else:
        tag = "CAUGHT" if caught else "MISSED"
        if not caught:
            missed.append(label)
    print(f"{tag:22s} {label}  [{n} members]")
    for e in errs[:2]:
        print("        " + e.splitlines()[0][:220])

# B14: a raw identity table added to the ALLOWLISTED foreign record in ANOTHER header
d = tempfile.mkdtemp(prefix="r3inc_")
for f in os.listdir(G.INCLUDE_DIR):
    if f.endswith(".h"):
        shutil.copyfile(os.path.join(G.INCLUDE_DIR, f), os.path.join(d, f))
lp = open(os.path.join(d, "LoopPlan.h")).read()
anchor = "struct LoopBreakRegion {"
assert lp.count(anchor) == 1
open(os.path.join(d, "LoopPlan.h"), "w").write(
    lp.replace(anchor, anchor + "\n  llvm::SmallPtrSet<llvm::Value *, 4> R3IdentityTable;", 1))
saved = G.INCLUDE_DIR; G.INCLUDE_DIR = d
try:
    errs, n = G.check(hdr, st, G.ALLOWLIST, sc)
finally:
    G.INCLUDE_DIR = saved
    shutil.rmtree(d, ignore_errors=True)
tag = "CAUGHT" if errs else "MISSED"
if not errs:
    missed.append("B14")
print(f"{tag:22s} B14 raw identity table added to allowlisted LoopBreakRegion (LoopPlan.h)  [{n} members]")
for e in errs[:2]:
    print("        " + e.splitlines()[0][:220])

print(f"\ncontrols bad: {len(bad_ctl)} {bad_ctl}")
print(f"attacks: {sum(1 for p in P if not p[2]) + 1}, MISSED {len(missed)}: {missed}")
print(f"PCH state: {G._PCH['state']}  USE_PCH={G.USE_PCH}  elapsed {time.time() - t0:.1f}s")
if G._PCH["dir"]:
    shutil.rmtree(G._PCH["dir"], ignore_errors=True)
