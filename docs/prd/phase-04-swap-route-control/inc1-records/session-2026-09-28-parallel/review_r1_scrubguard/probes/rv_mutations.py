"""Review r1 (scrubguard) — the mutated headers, shared by guard_fool_r1.py (the guard's
verdict) and build_compiles.py (does the BUILD compile the mutated header?).
Every entry: (id, label, kind, header_text, extra_headers, usage_tu_or_None)
kind: "null" (must be clean) | "pos" (must be refused) | "attack" (MISSED = false pass)."""
import os

def load(root):
    inc = os.path.join(root, "ir-pass", "include")
    hdr = open(os.path.join(inc, "TaintPropagation.h")).read()
    lp = open(os.path.join(inc, "LoopPlan.h")).read()
    return hdr, lp

ANCH = "struct TaintSet {"
LB = "struct LoopBreakRegion {"

def build(root, extra_includes):
    hdr, lp = load(root)
    assert hdr.count(ANCH) == 1 and lp.count(LB) == 1
    def inc(h, more=""):
        h2 = h.replace("#include <set>\n", "#include <set>\n" + extra_includes + more, 1)
        assert h2 != h
        return h2
    def ins(member, pre="", more=""):
        return inc(hdr, more).replace(ANCH, pre + ANCH + "\n  " + member, 1)
    def ins_global(member, pre, more=""):
        h = inc(hdr, more)
        return h.replace("namespace cq {", pre + "namespace cq {", 1).replace(ANCH, ANCH + "\n  " + member, 1)
    def lb(member, more=""):
        lp2 = lp.replace(LB, LB + "\n  " + member, 1)
        lp2 = lp2.replace('#include "llvm/ADT/DenseMap.h"\n', '#include "llvm/ADT/DenseMap.h"\n' + more, 1)
        return {"LoopPlan.h": lp2}

    P = []
    # ---- controls ----
    P.append(("N0", "NULL: pristine tree", "null", hdr, None, None))
    P.append(("C1", "POS: unnamed struct DEFINED INSIDE TaintSet holding std::set<Value*>", "pos",
              ins("struct { std::set<llvm::Value *> T; } RvIn;"), None, None))
    P.append(("C2", "POS: const llvm::Value ** (T ** judged by innermost pointee)", "pos",
              ins("const llvm::Value **RvSlots2 = nullptr;"), None, None))
    P.append(("C3", "POS: std::set<llvm::Value *> static member (no macro)", "pos",
              ins("static inline std::set<llvm::Value *> RvOrderIdx0;"), None, None))
    P.append(("C4", "POS: explicit specialization IN THE HEADER of the pointed-at template", "pos",
              ins("RvImpl<int> *RvP0 = nullptr;",
                  pre="template <class T> struct RvImpl { int Clean = 0; };\n"
                      "template <> struct RvImpl<int> { std::set<llvm::Value *> T; };\n"), None, None))
    # ---- attacks ----
    P.append(("A1", "unnamed struct type DEFINED OUTSIDE TaintSet, held by value via decltype", "attack",
              ins("decltype(RvHolder::U) RvAnon;",
                  pre="struct RvHolder { struct { std::set<llvm::Value *> T; } U; };\n"), None,
              "#include \"TaintPropagation.h\"\nvoid rv(cq::TaintSet &TS, llvm::Value *V) { TS.RvAnon.T.insert(V); }\n"))
    P.append(("A1b", "same, via a global unnamed-struct variable and an alias, as a STATIC member", "attack",
              ins_global("static inline RvAnonT RvAnonS;",
                         "inline struct { std::set<llvm::Value *> T; } RvGlobalAnon;\n",
                         ).replace(ANCH, "using RvAnonT = decltype(::RvGlobalAnon);\n" + ANCH, 1), None,
              "#include \"TaintPropagation.h\"\nvoid rv(llvm::Value *V) { cq::TaintSet::RvAnonS.T.insert(V); }\n"))
    P.append(("A2", "const llvm::Value *const * (inner pointer cv-qualified) — a hand-rolled slot table", "attack",
              ins("const llvm::Value *const *RvSlots = nullptr; unsigned RvNumSlots = 0;"), None,
              "#include \"TaintPropagation.h\"\nbool rv(cq::TaintSet &TS, const llvm::Value *V) { for (unsigned i = 0; i < TS.RvNumSlots; ++i) if (TS.RvSlots[i] == V) return true; return false; }\n"))
    P.append(("A2b", "llvm::Value *volatile * (writable) inside a SmallVector", "attack",
              ins("llvm::SmallVector<llvm::Value *volatile *, 2> RvVSlots;"), None, None))
    P.append(("A3", "template PIMPL: primary clean in the header, explicit specialization (raw table) in a .cpp", "attack",
              ins("RvImpl<int> *RvP = nullptr;",
                  pre="template <class T> struct RvImpl { int Clean = 0; };\n"), None,
              "#include \"TaintPropagation.h\"\ntemplate <> struct cq::RvImpl<int> { std::set<llvm::Value *> T; };\n"
              "void rv(cq::TaintSet &TS, llvm::Value *V) { TS.RvP->T.insert(V); }\n"))
    P.append(("A4", "base re-spelled through an ANONYMOUS NAMESPACE (R8 by another mechanism)", "attack",
              ins("RvMid RvM;",
                  pre="struct RvB { int Clean = 0; };\n"
                      "namespace { struct RvB { std::set<llvm::Value *> T; }; struct RvMid : RvB, ::cq::RvB {}; }\n"),
              None,
              "#include \"TaintPropagation.h\"\nvoid rv(cq::TaintSet &TS, llvm::Value *V) { TS.RvM.T.insert(V); }\n"))
    P.append(("A4b", "base that is a LOCAL CLASS whose name re-spells as a same-named global base", "attack",
              ins_global("::RvMid2 RvM2;",
                         "struct RvL { int Clean = 0; };\n"
                         "inline auto rvMake() { struct RvL { std::set<llvm::Value *> T; }; return RvL{}; }\n"
                         "struct RvMid2 : decltype(rvMake()), RvL {};\n"), None, None))
    P.append(("A5", "INCLUDE-ORDER: static raw table under #ifdef of a header real TUs include BEFORE TaintPropagation.h", "attack",
              ins("\n#ifdef CQ_IRPASS_CQ_LOWERING_PASS_H_\n  static inline std::set<llvm::Value *> RvOrderIdx;\n#endif\n"), None,
              "#include \"CQLoweringPass.h\"\n#include \"TaintPropagation.h\"\nvoid rv(llvm::Value *V) { cq::TaintSet::RvOrderIdx.insert(V); }\n"))
    P.append(("A6", "ALLOWLIST over-claim: llvm::EquivalenceClasses<llvm::Value *> (a std::set-backed identity table) in LoopBreakRegion", "attack",
              hdr, lb("llvm::EquivalenceClasses<llvm::Value *> RvEq;", more='#include "llvm/ADT/EquivalenceClasses.h"\n'), None))
    P.append(("A6b", "ALLOWLIST over-claim: llvm::UniqueVector<llvm::Value *> (a std::map-backed identity table) in LoopBreakRegion", "attack",
              hdr, lb("llvm::UniqueVector<llvm::Value *> RvUV;", more='#include "llvm/ADT/UniqueVector.h"\n'), None))
    P.append(("A7", "R1: by-value LIBRARY-NAMED template declared by the project in namespace llvm", "attack",
              ins_global("llvm::RvEvilBox<int> RvBox;",
                         "namespace llvm { template <class T> struct RvEvilBox { std::set<llvm::Value *> S; }; }\n"), None, None))
    P.append(("A8", "type-erasure by a builtin pointer: std::set<const char *> (reinterpret_cast'd Values)", "attack",
              ins("std::set<const char *> RvCharIdx;"), None, None))
    # ---- a scrub::Set's STORAGE argument (never walked: SCRUB_KEYS_ONLY returns before _arg) ----
    P.append(("A9", "scrub::Set<StorageT, PtrT> whose StorageT is a PROJECT record carrying a second, raw table", "attack",
              ins("scrub::Set<RvStore, llvm::Value *> RvScrubbed;",
                  pre="struct RvStore : std::set<llvm::Value *> { std::set<llvm::Value *> Hidden; };\n"), None,
              "#include \"TaintPropagation.h\"\nvoid rv(cq::TaintSet &TS, llvm::Value *V) { TS.RvScrubbed.insert(V); }\n"
              "struct RvPeek : cq::TaintSet {};\n"))
    P.append(("C5", "POS: the same RvStore reached as a plain FIELD (control: RvStore IS refused when walked)", "pos",
              ins("RvStore RvStoreField;",
                  pre="struct RvStore : std::set<llvm::Value *> { std::set<llvm::Value *> Hidden; };\n"), None, None))
    P.append(("A10", "TYPE-ERASED library base: llvm::SmallPtrSetImplBase * to a heap SmallPtrSet<Value*> (void* is refused)", "attack",
              ins("llvm::SmallPtrSetImplBase *RvErased = nullptr;"), None,
              "#include \"TaintPropagation.h\"\nvoid rv(cq::TaintSet &TS, llvm::Value *V) {\n"
              "  if (!TS.RvErased) TS.RvErased = new llvm::SmallPtrSet<llvm::Value *, 8>();\n"
              "  static_cast<llvm::SmallPtrSet<llvm::Value *, 8> *>(TS.RvErased)->insert(V); }\n"))
    # ---- KEY-mode measurements the implementer's §8.8 asked for ----
    P.append(("K1", "POS: KEY record whose BASE holds a WeakVH", "pos",
              ins("std::set<RvKD> RvKS;",
                  pre="struct RvKB { llvm::WeakVH H; };\n"
                      "struct RvKD : RvKB { bool operator<(const RvKD &O) const { return this < &O; } };\n"), None, None))
    P.append(("K2", "POS: KEY std::tuple<WeakVH,int>", "pos",
              ins("std::set<std::tuple<llvm::WeakVH, int>> RvKT;", more="#include <tuple>\n"), None, None))
    P.append(("K3", "POS: KEY std::variant<int,WeakVH> of a std::map", "pos",
              ins("std::map<std::variant<int, llvm::WeakVH>, int> RvKV;", more="#include <variant>\n"), None, None))
    return P
