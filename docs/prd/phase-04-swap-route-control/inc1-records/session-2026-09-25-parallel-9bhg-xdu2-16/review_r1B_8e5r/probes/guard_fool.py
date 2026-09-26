#!/usr/bin/env python3
"""guard_fool.py — review r1B_8e5r: try to fool tools/taintset_scrub_guard.py.
Each mutant edits the TaintSet header (or the selftest / ScrubOnDelete.h) TEXT
and asks the guard's own check(). MISSED = the guard reports 0 problems on a tree
that carries a raw pointer-bearing TaintSet table. Controls first: the pristine
tree must be clean (null control) and the guard's own M11 mutant must be KILLED
(positive control), else the harness measures itself."""
import sys, re
W = sys.argv[1]
sys.path.insert(0, W + "/tools")
import taintset_scrub_guard as g
hdr = open(g.HEADER).read(); st = open(g.SELFTEST).read(); sc = open(g.SCRUB_HDR).read()
ANCH = "struct TaintSet {"
assert hdr.count(ANCH) == 1

def ins(member, pre=""):
    h = hdr.replace(ANCH, pre + ANCH + "\n  " + member, 1)
    assert h != hdr
    return h

cases = [
 # (label, header, selftest, scrubhdr, expect_raw)
 ("NULL: pristine tree", hdr, st, sc, False),
 ("POS: guard's own M11 alias retarget", hdr, st, sc.replace(
     "using TaintedValueSet = scrub::Set<std::set<llvm::Value *>, llvm::Value *>;",
     "using TaintedValueSet = std::set<llvm::Value *>;"), True),
 ("POS: plain raw SmallPtrSet member", ins("llvm::SmallPtrSet<llvm::Value *, 4> NewRaw;"), st, sc, True),
 ("G1 brace-initialized raw member `std::set<Value*> X{};`", ins("std::set<llvm::Value *> NewRaw{};"), st, sc, True),
 ("G2 llvm::SmallSet<Value*,8>", ins("llvm::SmallSet<llvm::Value *, 8> NewRaw;"), st, sc, True),
 ("G3 alias declared OUTSIDE TaintSet", ins("RawTbl NewRaw;", "using RawTbl = std::set<llvm::Value *>;\n"), st, sc, True),
 ("G4 typedef INSIDE TaintSet", ins("typedef llvm::DenseMap<llvm::Value *, unsigned> RawMap;\n  RawMap NewRaw;"), st, sc, True),
 ("G5 macro-spelled type", ins("CQ_RAW_SET NewRaw;", "#define CQ_RAW_SET std::set<llvm::Value *>\n"), st, sc, True),
 ("G6 parenthesised template arg", ins("llvm::SmallPtrSet<llvm::Value *, (4)> NewRaw;"), st, sc, True),
 ("G7 std::unordered_map<const Value*,..>", ins("std::unordered_map<const llvm::Value *, unsigned> NewRaw;"), st, sc, True),
 ("G8 SmallDenseMap", ins("llvm::SmallDenseMap<llvm::Value *, unsigned, 4> NewRaw;"), st, sc, True),
 ("G9 MapVector", ins("llvm::MapVector<llvm::Value *, unsigned> NewRaw;"), st, sc, True),
 ("G10 pointer in a pair KEY", ins("llvm::DenseSet<std::pair<llvm::Value *, unsigned>> NewRaw;"), st, sc, True),
 ("G11 std::array<Value*,4>", ins("std::array<llvm::Value *, 4> NewRaw;"), st, sc, True),
 ("G12 std::optional<Instruction*>", ins("std::optional<llvm::Instruction *> NewRaw;"), st, sc, True),
 ("G13 std::pair<Value*,unsigned> field", ins("std::pair<llvm::Value *, unsigned> NewRaw;"), st, sc, True),
 ("G14 StringMap<Value*>", ins("llvm::StringMap<llvm::Value *> NewRaw;"), st, sc, True),
 ("G15 nested record declared `final`", ins("struct RawRec final { llvm::Value *P = nullptr; };\n  llvm::SmallVector<RawRec, 2> Recs;"), st, sc, True),
 ("G16 anonymous struct member", ins("struct { llvm::Value *P = nullptr; } Anon;"), st, sc, True),
 ("G17 union member", ins("union { llvm::Value *P; unsigned U; } Un;"), st, sc, True),
 ("G18 raw key, wrapped MAPPED type + a selftest mention", ins("llvm::DenseMap<llvm::Value *, ScrubPtrSet<llvm::Value *, 4>> NewRaw;"), st + "\n// T.NewRaw\n", sc, True),
 ("G19 wrapped member 'exercised' by a COMMENT only", ins("ScrubPtrSet<llvm::Value *, 4> NewWrapped;"), st + "\n// T.NewWrapped is exercised elsewhere\n", sc, False),
 ("G20 foreign record held DIRECTLY (not in a container)", ins("LoopBreakRegion OneRegion;"), st, sc, True),
 ("G21 decltype/paren default initializer", ins("llvm::DenseMap<llvm::Value *, unsigned> NewRaw = decltype(NewRaw)();"), st, sc, True),
 ("G22 ScrubMap with a RAW MAPPED pointer (+ exercised)", ins("ScrubMap<llvm::Value *, llvm::Instruction *> NewMap;"), st + "\n  checkMap(\"NewMap\", T.NewMap, Add, (llvm::Instruction *)nullptr);\n", sc, True),
 ("G23 class-scope alias SHADOWING ScrubPtrSet (all 17 ScrubPtrSet members go raw)", ins("template <typename P, unsigned N> using ScrubPtrSet = llvm::SmallPtrSet<P, N>;"), st, sc, True),
 ("G24 nested record with a BASE class", ins("struct RawRec2 : Base0 { llvm::Value *P = nullptr; };\n  llvm::SmallVector<RawRec2, 2> Recs2;"), st, sc, True),
]
missed_raw, bad_ctl = [], []
for label, h, s, x, expect_raw in cases:
    errs, n = g.check(h, s, g.ALLOWLIST, x)
    verdict = "KILLED" if errs else "MISSED"
    if label.startswith(("NULL", "POS")):
        ok = (bool(errs) == expect_raw)
        print(f"[control] {label}: {'problems' if errs else 'clean'} -> {'OK' if ok else 'CONTROL FAILED'}")
        if not ok: bad_ctl.append(label)
        continue
    tag = verdict if expect_raw else ("(coverage) " + verdict)
    print(f"  {tag:18s} {label}   [{len(errs)} problem(s), {n} members]")
    if expect_raw and not errs: missed_raw.append(label)
n_mut = sum(1 for c in cases if not c[0].startswith(("NULL", "POS")) and c[4])
print(f"guard_fool: {n_mut} raw-member mutants, {len(missed_raw)} MISSED; controls failed: {len(bad_ctl)}")
