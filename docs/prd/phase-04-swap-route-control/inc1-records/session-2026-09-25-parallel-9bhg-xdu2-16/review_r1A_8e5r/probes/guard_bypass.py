#!/usr/bin/env python3
"""guard_bypass.py WORKTREE — feed tools/taintset_scrub_guard.py's check() a TaintSet
header with ONE added raw pointer-bearing member per case and report which the guard
MISSES (L10: an instrument's failure mode is to report a pass). Null control first:
the unmodified header must be clean, and a known-killed mutant must be killed."""
import importlib.util, sys
W = sys.argv[1]
spec = importlib.util.spec_from_file_location("g", f"{W}/tools/taintset_scrub_guard.py")
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
hdr = open(g.HEADER).read(); st = open(g.SELFTEST).read(); sc = open(g.SCRUB_HDR).read()
base, n = g.check(hdr, st, g.ALLOWLIST, sc)
print(f"null control: {len(base)} problems over {n} members (must be 0)")
A = "struct TaintSet {"
cases = {
  "CONTROL raw SmallPtrSet (must be KILLED)": "llvm::SmallPtrSet<llvm::Value *, 4> X;",
  "llvm::SmallSet<Value*>": "llvm::SmallSet<llvm::Value *, 4> X;",
  "std::multiset<Value*>": "std::multiset<llvm::Value *> X;",
  "std::array<Value*,4>": "std::array<llvm::Value *, 4> X;",
  "std::optional<Value*>": "std::optional<llvm::Value *> X;",
  "llvm::StringMap<Value*>": "llvm::StringMap<llvm::Value *> X;",
  "std::pair<Value*,int> by value": "std::pair<llvm::Value *, int> X;",
  "lowercase ptr typedef in container": "llvm::SmallPtrSet<vptr_t, 4> X;",
  "template alias container": "PtrSetOf<llvm::Value> X;",
  "by-value foreign record": "LoopBreakRegion LastBreak;",
  "default init with parens": "std::set<llvm::Value *> X = std::set<llvm::Value *>();",
  "alignas member": "alignas(8) llvm::Value *Stray;",
  "raw ptr, brace-init": "llvm::Value *Stray{nullptr};",
  "brace-init raw DenseMap (X{})": "llvm::DenseMap<llvm::Value *, unsigned> X{};",
  "brace-init raw SmallPtrSet (X{})": "llvm::SmallPtrSet<llvm::Instruction *, 4> X{};",
  "unique_ptr to raw map": "std::unique_ptr<llvm::DenseMap<llvm::Value *, int>> X;",
}
miss = 0
for label, decl in cases.items():
    h = hdr.replace(A, A + "\n  " + decl, 1)
    e, _ = g.check(h, st, g.ALLOWLIST, sc)
    v = "KILLED" if e else "MISSED"
    miss += (not e) and not label.startswith("CONTROL")
    print(f"  {v:7s} {label:40s} {decl}")
print(f"{len(cases)-1} bypass candidates, {miss} MISSED")
