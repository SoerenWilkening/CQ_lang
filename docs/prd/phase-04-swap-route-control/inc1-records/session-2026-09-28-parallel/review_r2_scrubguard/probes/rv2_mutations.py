"""Review r2 (scrubguard) — the mutated headers, shared by guard_fool_r2.py (the guard's
verdict) and build_compiles_r2.py (does the BUILD compile the mutated header, and does a real
TU of the build contain the raw member?).
Every entry: (id, label, kind, header_text, extra_headers, usage_tu_or_None, marker_or_None)
kind: "null" (must be clean) | "pos" (must be refused) | "attack" (MISSED = false pass).
`marker`: an identifier that must appear in the -E output of a REAL build TU when the attack
is include-order dependent (build_compiles_r2.py greps CQLoweringPass.cpp's -E for it)."""
import os

ANCH = "struct TaintSet {"
LB = "struct LoopBreakRegion {"
CTX = "CQ_IRPASS_CQ_LOWERING_PASS_H_"   # defined by CQLoweringPass.h, which CQLoweringPass.cpp
#                                        includes BEFORE TaintPropagation.h (measured: -E order)


def load(root):
    inc = os.path.join(root, "ir-pass", "include")
    return (open(os.path.join(inc, "TaintPropagation.h")).read(),
            open(os.path.join(inc, "LoopPlan.h")).read())


def build(root, extra_includes):
    hdr, lp = load(root)
    assert hdr.count(ANCH) == 1 and lp.count(LB) == 1

    def inc(h, more=""):
        h2 = h.replace("#include <set>\n", "#include <set>\n" + extra_includes + more, 1)
        assert h2 != h
        return h2

    def ins(member, pre="", more=""):
        return inc(hdr, more).replace(ANCH, pre + ANCH + "\n  " + member, 1)

    def lb(member, more=""):
        lp2 = lp.replace(LB, LB + "\n  " + member, 1)
        lp2 = lp2.replace('#include "llvm/ADT/DenseMap.h"\n', '#include "llvm/ADT/DenseMap.h"\n' + more, 1)
        return {"LoopPlan.h": lp2}

    U = '#include "CQLoweringPass.h"\n#include "TaintPropagation.h"\n'
    P = []
    # ---------------- controls ----------------
    P.append(("N0", "NULL: pristine tree", "null", hdr, None, None, None))
    P.append(("C1", "POS: the B1 table (unnamed struct with Value *Tab[64]) held STRICTLY in TaintSet", "pos",
              ins("RvMidC RvMC;", pre="struct RvMidC { struct { llvm::Value *Tab[64]; unsigned N = 0; } U; };\n"),
              None, None, None))
    P.append(("C2", "POS: the B7 member written in TaintPropagation.h itself (A5 shape, the closure file)", "pos",
              ins(f"#ifdef {CTX}\n  std::set<llvm::Value *> RvCtxSelf;\n#endif"), None, None, None))
    # ---------------- (2) unnamed-record identity ----------------
    P.append(("B1", "MODE CONFUSION: unnamed struct walked RELAXED inside the allowlisted LoopBreakRegion, "
                    "its type reused by a STRICT record via decltype", "attack",
              ins("RvMid RvM;", pre="struct RvMid { decltype(LoopBreakRegion::RvU) E; };\n"),
              lb("struct { llvm::Value *Tab[64]; unsigned N = 0; } RvU;"),
              U + "void rv(cq::TaintSet &T, llvm::Value *V) { T.RvM.E.Tab[T.RvM.E.N++] = V; }\n"
                  "bool rq(cq::TaintSet &T, llvm::Value *V) { for (unsigned i = 0; i < T.RvM.E.N; ++i) "
                  "if (T.RvM.E.Tab[i] == V) return true; return false; }\n", None))
    P.append(("B4", "KEY COLLISION by macro: one expansion defines a clean unnamed field and a raw unnamed "
                    "struct inside a member class template; decltype of the latter", "attack",
              ins("#define RV_TWO struct { unsigned N = 0; } RvClean4; template <class = void> struct RvH4 "
                  "{ struct { std::set<llvm::Value *> T; } U; };\n  RV_TWO\n  decltype(RvH4<>::U) RvEvil4;"),
              None, U + "void rv(cq::TaintSet &T, llvm::Value *V) { T.RvEvil4.T.insert(V); }\n", None))
    P.append(("B5", "KEY COLLISION by #line: a raw unnamed struct outside TaintSet forged to the "
                    "clean one's FILE:LINE:COL", "attack",
              ins("\n#line 7000\n  struct { unsigned N = 0; } RvClean5; decltype(RvHolder5::U) RvEvil5;",
                  pre="struct RvHolder5 {\n#line 7000\n  struct { std::set<llvm::Value *> T; } U; };\n"),
              None, U + "void rv(cq::TaintSet &T, llvm::Value *V) { T.RvEvil5.T.insert(V); }\n", None))
    # ---------------- (7) LoopBreakRegion "fields" policy ----------------
    P.append(("B2", "ALLOWLISTED LoopBreakRegion: identity TABLES spelled as direct fields "
                    "(C array, heap array, SmallVector of a one-pointer record)", "attack",
              hdr, lb("llvm::Value *RvTab[64] = {}; llvm::Value **RvHeap = nullptr; unsigned RvN = 0;\n"
                      "  struct RvSlot { llvm::Value *V = nullptr; }; llvm::SmallVector<RvSlot, 8> RvSlots;"),
              U + "bool rq(cq::TaintSet &T, llvm::Value *V) { for (auto &B : T.BreakRegions) { "
                  "for (unsigned i = 0; i < B.RvN; ++i) if (B.RvTab[i] == V) return true; "
                  "for (auto &S : B.RvSlots) if (S.V == V) return true; } return false; }\n", None))
    # ---------------- (3) base identity ----------------
    P.append(("B3", "BASE ALIAS: D : cq::RvB (clean), anon-ns RvB (raw); D declares `using RvB = cq::RvB` "
                    "so `typename D::RvB` is unambiguous and names the clean record", "attack",
              ins("RvD RvDV;", pre="struct RvB { unsigned N = 0; };\n"
                                   "namespace { struct RvB { std::set<llvm::Value *> S; }; using RvRawB = RvB; }\n"
                                   "struct RvD : ::cq::RvB, RvRawB { using RvB = ::cq::RvB; };\n"),
              None, U + "void rv(cq::TaintSet &T, llvm::Value *V) { static_cast<cq::RvRawB &>(T.RvDV).S.insert(V); }\n",
              None))
    # ---------------- (1) include-order check ----------------
    ctxhdr = lambda g, name: (f"#ifndef {g}\n#define {g}\n#include <set>\n#include \"llvm/IR/Value.h\"\n"
                              f"namespace cq {{\nstruct {name} {{\n  unsigned N = 0;\n#ifdef {CTX}\n"
                              f"  std::set<llvm::Value *> S;\n#endif\n}};\n}}\n#endif\n")
    P.append(("B6", "INCLUDE ORDER through `#line N \"other\"`: the member's -E lines are attributed to a "
                    "non-closure file", "attack",
              ins(f"\n#line 1 \"RvElsewhere.h\"\n#ifdef {CTX}\n  static inline std::set<llvm::Value *> RvLineCtx;\n#endif"),
              None, U + "void rv(llvm::Value *V) { cq::TaintSet::RvLineCtx.insert(V); }\n", "RvLineCtx"))
    P.append(("B7", "INCLUDE ORDER through an ANGLE include of a project header (not in the quote-only closure)",
              "attack", ins("RvCtx7 RvC7;", more="#include <RvCtx7.h>\n"),
              {"RvCtx7.h": ctxhdr("RV_CTX7_H", "RvCtx7")},
              U + "void rv(cq::TaintSet &T, llvm::Value *V) { T.RvC7.S.insert(V); }\n", None))
    P.append(("B8", "INCLUDE ORDER through a COMPUTED include (#include MACRO)", "attack",
              ins("RvCtx8 RvC8;", more="#define RV_CTX8_HDR \"RvCtx8.h\"\n#include RV_CTX8_HDR\n"),
              {"RvCtx8.h": ctxhdr("RV_CTX8_H", "RvCtx8")},
              U + "void rv(cq::TaintSet &T, llvm::Value *V) { T.RvC8.S.insert(V); }\n", None))
    P.append(("B9", "INCLUDE DEPTH: `#if __INCLUDE_LEVEL__ > 1` (every probe includes the header at level 1; "
                    "real TUs reach it deeper)", "attack",
              ins("\n#if __INCLUDE_LEVEL__ > 1\n  static inline std::set<llvm::Value *> RvLevel;\n#endif"),
              None, '#include "SpecializeSeed.h"\nvoid rv(llvm::Value *V) { cq::TaintSet::RvLevel.insert(V); }\n',
              "RvLevel"))
    P.append(("B10", "SEMANTIC include-order dependence (no macro): SFINAE on the COMPLETENESS of "
                     "cq::CQLoweringPass — identical tokens, different type", "attack",
              ins("RvSel<CQLoweringPass>::type RvCtxSem;",
                  pre="struct CQLoweringPass;\n"
                      "template <class T, class = void> struct RvSel { using type = unsigned; };\n"
                      "template <class T> struct RvSel<T, std::void_t<decltype(sizeof(T))>> "
                      "{ using type = std::set<llvm::Value *>; };\n"),
              None, U + "void rv(cq::TaintSet &T, llvm::Value *V) { T.RvCtxSem.insert(V); }\n", None))
    G = "#define CQ_IRPASS_TAINT_PROPAGATION_H_\n"
    assert hdr.count(G) == 1
    P.append(("B11", "INCLUDE ORDER through a CLOSURE file's own guard: `#ifdef CQ_IRPASS_LOOP_PLAN_H_` tested "
                     "BEFORE TaintPropagation.h includes LoopPlan.h (LoopLowering.cpp includes LoopPlan.h FIRST; "
                     "the union context #undef's every closure guard before the final include)", "attack",
              ins("\n#ifdef CQ_RV_LOOPPLAN_FIRST\n  static inline std::set<llvm::Value *> RvLpFirst;\n#endif")
              .replace(G, G + "#ifdef CQ_IRPASS_LOOP_PLAN_H_\n#define CQ_RV_LOOPPLAN_FIRST 1\n#endif\n", 1),
              None, '#include "LoopPlan.h"\n#include "TaintPropagation.h"\n'
                    'void rv(llvm::Value *V) { cq::TaintSet::RvLpFirst.insert(V); }\n', "RvLpFirst"))
    # ---------------- (5) type-erased / library templates battery ----------------
    P.append(("B12", "LIBRARY TEMPLATE battery (each member must appear in the refusals; RvE11 is the "
                     "documented byte-storage out-of-scope case)", "pos",
              ins("llvm::SmallVectorImpl<llvm::Value *> *RvE1 = nullptr;\n"
                  "  std::function<void()> RvE2;\n"
                  "  llvm::PointerIntPair<llvm::Value *, 1> RvE3;\n"
                  "  llvm::PointerUnion<llvm::Value *, llvm::BasicBlock *> RvE4;\n"
                  "  llvm::MutableArrayRef<llvm::Value *> RvE5;\n"
                  "  std::any RvE6;\n"
                  "  llvm::unique_function<void()> RvE7;\n"
                  "  llvm::DenseMapBase<llvm::DenseMap<unsigned, llvm::Value *>, unsigned, llvm::Value *, "
                  "llvm::DenseMapInfo<unsigned>, llvm::detail::DenseMapPair<unsigned, llvm::Value *>> *RvE8 = nullptr;\n"
                  "  std::shared_ptr<void> RvE9;\n"
                  "  llvm::SmallVectorTemplateCommon<llvm::Value *> *RvE10 = nullptr;\n"
                  "  std::array<unsigned char, 64> RvE11;\n"
                  "  llvm::function_ref<void()> RvE12;\n"
                  "  std::reference_wrapper<llvm::Value> *RvE13 = nullptr;\n"
                  "  llvm::iterator_range<llvm::Value **> *RvE14 = nullptr;\n"
                  "  std::pair<llvm::Value *, int> *RvE15 = nullptr;",
                  more="#include <any>\n#include \"llvm/ADT/PointerUnion.h\"\n#include \"llvm/ADT/FunctionExtras.h\"\n"
                       "#include \"llvm/ADT/STLFunctionalExtras.h\"\n#include \"llvm/ADT/iterator_range.h\"\n"),
              None, None, None))
    return P
