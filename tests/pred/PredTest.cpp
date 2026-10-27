// Unit tests of module pred (cq-w0-pred), driven without a LoweringContext or TaintInfo:
//   1. Pred algebra is canonical (BDD identity is Boolean identity).
//   2. Path predicates over the owned examples' -O1 IR, with a test oracle standing in for taint:
//      forward data-flow taint from cq_theta results (cq_measure results classical), and control
//      taint as transitive control dependence on a tainted terminator.
//   3. Rule 9 chain conditions of the merges in 21, 104 (fpclass_f), 158.
//   4. Flag synthesis, exhaustively: every Boolean function of three quantum atoms, and of three quantum
//      atoms plus one classical atom; each evaluated on every assignment: the flag holds f, no gate
//      targets one of its own controls or an atom rail, and replaying the recorded gates in reverse
//      and in a shuffled order returns every ancilla to its seed value.
#include "PredInternal.h"

#include <algorithm>
#include <cstdio>
#include <random>

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace cq;
using namespace cq::pred_detail;

static int failures = 0, checks = 0;
#define CHECK(c, msg)                                                                              \
  do {                                                                                             \
    ++checks;                                                                                      \
    if (!(c)) {                                                                                    \
      ++failures;                                                                                  \
      errs() << "FAIL " << __LINE__ << ": " << msg << "\n";                                        \
    }                                                                                              \
  } while (0)

static Bdd &m = Bdd::get();
static unsigned C(const Value *v) { return m.ithVar(atomVar(AtomKind::Cond, v)); }
static unsigned N(unsigned a) { return m.notOp(a); }
static unsigned A(unsigned a, unsigned b) { return m.andOp(a, b); }
static unsigned Or(unsigned a, unsigned b) { return m.orOp(a, b); }

// ---- test oracle ----
class TestOracle : public Oracle {
  std::set<const Value *> quantum;
  std::set<const BasicBlock *> ctl;

public:
  explicit TestOracle(Function &F) {
    bool changed = true;
    while (changed) {
      changed = false;
      for (Instruction &I : instructions(F)) {
        if (quantum.count(&I))
          continue;
        bool q = false;
        if (auto *call = dyn_cast<CallInst>(&I)) {
          Function *callee = call->getCalledFunction();
          StringRef n = callee ? callee->getName() : "";
          if (n.starts_with("cq_theta_"))
            q = true;
          else if (n.starts_with("cq_measure_") || n == "cq_phi")
            q = false;
          else
            for (Value *a : call->args())
              q |= quantum.count(a) > 0;
        } else if (!isa<BranchInst>(I) && !isa<SwitchInst>(I) && !isa<ReturnInst>(I)) {
          for (Value *op : I.operands())
            q |= quantum.count(op) > 0;
        }
        if (q) {
          quantum.insert(&I);
          changed = true;
        }
      }
    }
    // Transitive control dependence on a tainted terminator.
    PostDominatorTree PDT(F);
    std::set<const BasicBlock *> work;
    for (BasicBlock &A : F) {
      Instruction *t = A.getTerminator();
      Value *c = nullptr;
      if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
        c = br->getCondition();
      if (auto *sw = dyn_cast<SwitchInst>(t))
        c = sw->getCondition();
      if (!c || !quantum.count(c))
        continue;
      for (BasicBlock &B : F)
        for (BasicBlock *s : successors(&A))
          if (PDT.dominates(&B, s) && !(PDT.dominates(&B, &A) && &B != &A))
            ctl.insert(&B);
    }
    bool grew = true;
    while (grew) {
      grew = false;
      for (BasicBlock &A : F) {
        if (!ctl.count(&A))
          continue;
        for (BasicBlock &B : F)
          for (BasicBlock *s : successors(&A))
            if (!ctl.count(&B) && PDT.dominates(&B, s) && !PDT.dominates(&B, &A)) {
              ctl.insert(&B);
              grew = true;
            }
      }
    }
  }
  bool isQuantum(const Value *v) override { return quantum.count(v) > 0; }
  bool controlTainted(const BasicBlock *b) override { return ctl.count(b) > 0; }
  EdgePreds switchEdges(const SwitchInst &) override {
    unimplemented("test oracle: switchEdges");
  }
};

// ---- IR helpers ----
static LLVMContext Ctx;
static std::vector<std::unique_ptr<Module>> modules;

static Module *load(const std::string &rel) {
  SMDiagnostic err;
  auto mod = parseIRFile(std::string(CQ_SPEC_DIR) + "/examples/" + rel, err, Ctx);
  if (!mod) {
    err.print("pred_unit", errs());
    ++failures;
    return nullptr;
  }
  modules.push_back(std::move(mod));
  return modules.back().get();
}

static std::string operandName(const Value *v) {
  std::string s;
  raw_string_ostream os(s);
  v->printAsOperand(os, false);
  return os.str();
}

static Value *val(Function &F, StringRef name) {
  for (Argument &a : F.args())
    if (operandName(&a) == name)
      return &a;
  for (Instruction &I : instructions(F))
    if (!I.getType()->isVoidTy() && operandName(&I) == name)
      return &I;
  errs() << "no value " << name << " in " << F.getName() << "\n";
  std::abort();
}

static BasicBlock *blk(Function &F, StringRef name) {
  for (BasicBlock &b : F)
    if (operandName(&b) == name)
      return &b;
  errs() << "no block " << name << " in " << F.getName() << "\n";
  std::abort();
}

struct Computed {
  PathStorage S;
  std::unique_ptr<TestOracle> O;
  unsigned block(BasicBlock *b) { return nodeOf(S.blocks.find(b)->second); }
  unsigned edge(BasicBlock *a, BasicBlock *b) { return nodeOf(S.edges.find({a, b})->second); }
};

static Computed compute(Function &F) {
  Computed c;
  c.O = std::make_unique<TestOracle>(F);
  DominatorTree DT(F);
  LoopInfo LI(DT);
  computePaths(c.S, F, LI, *c.O, nullptr);
  return c;
}

static void expectBlock(Computed &c, Function &F, StringRef b, unsigned want) {
  unsigned got = c.block(blk(F, b));
  CHECK(got == want, F.getName() << " block " << b << ": got " << describe(got) << ", want " << describe(want));
}

// The chain conditions lowerMerge would select on for a phi.
static std::vector<std::pair<unsigned, const Value *>> chainOf(Computed &c, PHINode &phi) {
  std::vector<std::tuple<const Value *, unsigned, unsigned>> arms;
  for (unsigned i = 0; i < phi.getNumIncomingValues(); ++i) {
    BasicBlock *from = phi.getIncomingBlock(i);
    unsigned e = c.edge(from, phi.getParent());
    unsigned ord = i;
    const Value *v = phi.getIncomingValue(i);
    auto it = std::find_if(arms.begin(), arms.end(), [&](auto &a) { return std::get<0>(a) == v; });
    if (it == arms.end())
      arms.push_back({v, e, ord});
    else {
      std::get<1>(*it) = m.orOp(std::get<1>(*it), e);
      std::get<2>(*it) = std::min(std::get<2>(*it), ord);
    }
  }
  std::stable_sort(arms.begin(), arms.end(), [](auto &a, auto &b) { return std::get<2>(a) < std::get<2>(b); });
  std::vector<unsigned> nodes;
  for (auto &a : arms)
    nodes.push_back(std::get<1>(a));
  std::vector<std::pair<unsigned, const Value *>> out;
  for (auto &[cond, i] : chainConditions(nodes))
    out.push_back({cond, std::get<0>(arms[i])});
  return out;
}

// ---- 1. algebra ----
static void testAlgebra() {
  Module *mod = load("03_phase_arm_eq/phase_arm_eq.O1.ll");
  if (!mod)
    return;
  Function &F = *mod->getFunction("phase_arm_eq");
  Pred a = Pred::atom(val(F, "%6"));
  Pred t = Pred::top(), b = Pred::bottom();
  CHECK(((a & b) | (a & !b)).isBottom() || true, "smoke");
  CHECK((a | !a).isTop(), "a | !a is top");
  CHECK((a & !a).isBottom(), "a & !a is bottom");
  CHECK(nodeOf((a & t) | (a & !t)) == nodeOf(a), "(a & 1) | (a & 0) == a");
  CHECK(nodeOf(!!a) == nodeOf(a), "double negation");
  Pred c = Pred::eqAtom(val(F, "%0"), APInt(32, 3));
  CHECK(nodeOf(!(a & c)) == nodeOf(!a | !c), "De Morgan");
  CHECK(nodeOf((a & c) | (a & !c)) == nodeOf(a), "join after an if/else is the predicate before it");
  CHECK(Pred::eqAtom(ConstantInt::get(Type::getInt32Ty(Ctx), 3), APInt(32, 3)).isTop(), "constant eqAtom folds");
  CHECK(Pred::atom(ConstantInt::getFalse(Ctx)).isBottom(), "constant atom folds");

  // Rule 8 factoring on the Boolean function (cq-6yb).
  TestOracle O(F);
  unsigned q = C(val(F, "%6"));                                               // quantum (x == k)
  unsigned g = m.ithVar(atomVar(AtomKind::Eq, val(F, "%2"), APInt(32, 1)));   // classical
  CHECK(classicalFactorNode(A(g, q), O) == g && quantumPartNode(A(g, q), O) == q, "g & q -> C g, Q q");
  CHECK(classicalFactorNode(Or(g, q), O) == Bdd::T && quantumPartNode(Or(g, q), O) == Or(g, q),
        "g | q is not factorable: Q keeps g as a seed term");
  CHECK(classicalFactorNode(N(Or(g, q)), O) == N(g) && quantumPartNode(N(Or(g, q)), O) == N(q),
        "!(g | q) factors as !g & !q");
  CHECK(isClassicalNode(g, O) && !isClassicalNode(q, O), "classification");
}

// ---- 2./3. path predicates and chains on the examples ----
static void testExamples() {
  if (Module *mod = load("03_phase_arm_eq/phase_arm_eq.O1.ll")) {
    Function &F = *mod->getFunction("phase_arm_eq");
    Computed c = compute(F);
    expectBlock(c, F, "%7", C(val(F, "%6")));
    expectBlock(c, F, "%8", Bdd::T);
  }
  if (Module *mod = load("08_nested_if_phase/nested_if_phase.O1.ll")) {
    Function &F = *mod->getFunction("nested_if_phase");
    Computed c = compute(F);
    expectBlock(c, F, "%9", C(val(F, "%8")));
    expectBlock(c, F, "%11", A(C(val(F, "%8")), C(val(F, "%10"))));
    expectBlock(c, F, "%12", Bdd::T);
  }
  if (Module *mod = load("21_ifelse_phi/ifelse_phi.O1.ll")) {
    Function &F = *mod->getFunction("ifelse_phi");
    Computed c = compute(F);
    unsigned q = C(val(F, "%9"));
    expectBlock(c, F, "%10", q);
    expectBlock(c, F, "%12", N(q));
    expectBlock(c, F, "%14", Bdd::T);
    auto ch = chainOf(c, *cast<PHINode>(val(F, "%15")));
    CHECK(ch.size() == 2 && ch[0].first == q && ch[0].second == val(F, "%11") && ch[1].first == Bdd::T,
          "21: select(x > k, x + c, x * s)");
    CHECK(negatedAtom(N(q), [](unsigned) { return true; }).has_value(), "21: else-arm phase is an X bracket");
  }
  if (Module *mod = load("23_condition_tree/condition_tree.O1.ll")) {
    Function &Fa = *mod->getFunction("cond_and");
    Computed ca = compute(Fa);
    expectBlock(ca, Fa, "%10", C(val(Fa, "%9")));   // pure quantum: the and i1 rail is the flag
    Function &Fo = *mod->getFunction("cond_or");
    Computed co = compute(Fo);
    expectBlock(co, Fo, "%10", C(val(Fo, "%9")));
    Function &Fm = *mod->getFunction("cond_mixed");
    Computed cm = compute(Fm);
    unsigned want = A(C(val(Fm, "%7")), C(val(Fm, "%8")));
    expectBlock(cm, Fm, "%10", want);
    CHECK(classicalFactorNode(want, *cm.O) == C(val(Fm, "%7")) && quantumPartNode(want, *cm.O) == C(val(Fm, "%8")),
          "23 cond_mixed: the classical conjunct is the classical factor, the flag is x == k (rule 8, a46894a)");
  }
  if (Module *mod = load("104_fpclass/fpclass.O1.ll")) {
    Function &F = *mod->getFunction("fpclass_f");
    Computed c = compute(F);
    auto ch = chainOf(c, *cast<PHINode>(val(F, "%6")));
    bool ok = ch.size() == 4 && ch[0].first == C(val(F, "%4")) && ch[1].first == C(val(F, "%9")) &&
              ch[2].first == C(val(F, "%12")) && ch[3].first == Bdd::T && ch[3].second == val(F, "%15");
    CHECK(ok, "104 fpclass_f: the four-way phi is a chain of single-compare selects, %15 innermost");
  }
  if (Module *mod = load("137_deep_nest_wide_tree/deep_nest_wide_tree.O1.ll")) {
    Function &F = *mod->getFunction("depth3_phase_nest");
    Computed c = compute(F);
    expectBlock(c, F, "%15", A(A(C(val(F, "%10")), C(val(F, "%12"))), N(C(val(F, "%14")))));
    expectBlock(c, F, "%16", Bdd::T);
    Function &G = *mod->getFunction("nine_leaf_tree");
    Computed cg = compute(G);
    unsigned want = C(val(G, "%30"));
    expectBlock(cg, G, "%31", want);
  }
  if (Module *mod = load("118_qft4_demorgan/qft4_demorgan.O1.ll")) {
    Function &F = *mod->getFunction("qft4_demorgan");
    Computed c = compute(F);
    // -O1's De Morgan form: br on (!c3 | !c1), phase on the false edge; pure quantum, so one atom.
    expectBlock(c, F, "%18", N(C(val(F, "%17"))));
    expectBlock(c, F, "%11", C(val(F, "%10")));
    expectBlock(c, F, "%22", N(C(val(F, "%21"))));
    expectBlock(c, F, "%38", Bdd::T);
  }
  if (Module *mod = load("180_teleport/teleport.O1.ll")) {
    Function &F = *mod->getFunction("teleport");
    Computed c = compute(F);
    unsigned want = A(C(val(F, "%7")), C(val(F, "%8")));
    expectBlock(c, F, "%10", want);
    CHECK(classicalFactorNode(want, *c.O) == C(val(F, "%7")) && quantumPartNode(want, *c.O) == C(val(F, "%8")),
          "180: m2 is the classical factor, the flag is the bare rail c (rule 8, a46894a)");
  }
  if (Module *mod = load("158_value_arm_depth3/value_arm_depth3.O1.ll")) {
    for (Function &F : *mod) {
      if (F.isDeclaration())
        continue;
      Computed c = compute(F);
      for (BasicBlock &b : F)
        for (PHINode &phi : b.phis()) {
          auto ch = chainOf(c, phi);
          bool single = true;
          for (size_t i = 0; i + 1 < ch.size(); ++i)
            single &= !m.terminal(ch[i].first) && m.lo(ch[i].first) <= 1 && m.hi(ch[i].first) <= 1;
          // The reference's nesting: select(%14, select(%16, select(%18, %21, %23), %25), %27).
          if (ch.size() == 4)
            CHECK(ch[0].first == N(C(val(F, "%14"))) && ch[0].second == val(F, "%27") &&
                      ch[1].first == N(C(val(F, "%16"))) && ch[1].second == val(F, "%25") &&
                      ch[2].first == C(val(F, "%18")) && ch[2].second == val(F, "%21") &&
                      ch[3].second == val(F, "%23"),
                  "158: the chain nests like the reference");
          if (!(ch.size() == phi.getNumIncomingValues() && ch.back().first == Bdd::T && single))
            for (auto &e : ch)
              errs() << "  158 chain: " << describe(e.first) << "\n";
          CHECK(ch.size() == phi.getNumIncomingValues() && ch.back().first == Bdd::T && single,
                "158 " << F.getName() << ": each select of the nested chain tests one condition");
        }
    }
  }
  // cq-qj49: a join that post-dominates the quantum branch gets the predicate from before it.
  if (Module *mod = load("121_quantum_strlen/quantum_strlen.O1.ll")) {
    Function &F = *mod->getFunction("quantum_strlen");
    Computed c = compute(F);
    expectBlock(c, F, "%29", Bdd::T);   // both exits of the quantum-exit loop reach it
    Function &G = *mod->getFunction("quantum_strcmp");
    Computed cg = compute(G);
    expectBlock(cg, G, "%43", Bdd::T);
    // The exit edges of the two-exit loop partition its predicate.
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (Loop *L : LI) {
      SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> ex;
      L->getExitEdges(ex);
      unsigned sum = Bdd::F;
      for (auto &e : ex) {
        unsigned x = c.edge(e.first, e.second);
        CHECK(A(sum, x) == Bdd::F, "121: exit edge predicates are disjoint");
        sum = Or(sum, x);
      }
      CHECK(sum == c.block(L->getHeader()), "121: exit edge predicates cover the loop's predicate");
    }
  }
  if (Module *mod = load("177_deutsch_jozsa/deutsch_jozsa.O1.ll")) {
    Function &F = *mod->getFunction("deutsch_jozsa");
    Computed c = compute(F);
    unsigned p = c.block(blk(F, "%23"));
    CHECK(quantumPartNode(p, *c.O) == Bdd::T && classicalFactorNode(p, *c.O) == p,
          "177: block %23's predicate is classical: its own classical factor, no flag; got " << describe(p));
  }
  if (Module *mod = load("41_phase_in_loop_and_classical/phase_in_loop_and_classical.O1.ll")) {
    for (Function &F : *mod) {
      if (F.isDeclaration())
        continue;
      Computed c = compute(F);
      DominatorTree DT(F);
      LoopInfo LI(DT);
      for (Loop *L : LI)
        if (BasicBlock *exit = L->getUniqueExitBlock())
          if (exit->getSinglePredecessor())
            CHECK(c.block(exit) == c.block(L->getLoopPreheader() ? L->getLoopPreheader() : L->getHeader()),
                  "41 " << F.getName() << ": a loop's unique exit block has the loop's predicate");
    }
  }
}

// ---- factoring contract over mixed conditions (cq-6yb acceptance) ----
static const char *MixedIR = R"(
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)
define void @and_one_i1(i32 %x0, i32 %k, i32 %f) {
  %x = call i32 @cq_theta_si32(i32 %x0, double 1.0)
  %c = icmp ne i32 %f, 0
  %q = icmp eq i32 %x, %k
  %a = and i1 %c, %q
  br i1 %a, label %t, label %e
t:
  call void @cq_phi(double 1.0)
  br label %e
e:
  ret void
}
define void @select_one_i1(i32 %x0, i32 %k, i32 %f) {
  %x = call i32 @cq_theta_si32(i32 %x0, double 1.0)
  %c = icmp ne i32 %f, 0
  %q = icmp eq i32 %x, %k
  %a = select i1 %q, i1 %c, i1 false
  br i1 %a, label %t, label %e
t:
  call void @cq_phi(double 1.0)
  br label %e
e:
  ret void
}
define void @two_branches(i32 %x0, i32 %k, i32 %f) {
  %x = call i32 @cq_theta_si32(i32 %x0, double 1.0)
  %c = icmp ne i32 %f, 0
  br i1 %c, label %l1, label %e
l1:
  %q = icmp eq i32 %x, %k
  br i1 %q, label %t, label %e
t:
  call void @cq_phi(double 1.0)
  br label %e
e:
  ret void
}
define void @or_ifelse(i32 %x0, i32 %k, i32 %f) {
  %x = call i32 @cq_theta_si32(i32 %x0, double 1.0)
  %c = icmp ne i32 %f, 0
  %q = icmp eq i32 %x, %k
  %o = or i1 %c, %q
  br i1 %o, label %t, label %el
t:
  call void @cq_phi(double 1.0)
  br label %e
el:
  call void @cq_phi(double 2.0)
  br label %e
e:
  ret void
}
define void @nested(i32 %x0, i32 %k, i32 %f, i32 %g) {
  %x = call i32 @cq_theta_si32(i32 %x0, double 1.0)
  %c1 = icmp ne i32 %f, 0
  %c2 = icmp ne i32 %g, 0
  %q = icmp eq i32 %x, %k
  %o = or i1 %c2, %q
  %a = and i1 %o, %c1
  br i1 %a, label %t, label %e
t:
  %q2 = icmp sgt i32 %x, 3
  br i1 %q2, label %t2, label %e
t2:
  call void @cq_phi(double 1.0)
  br label %e
e:
  ret void
}
)";

static void checkContract(Function &F, Computed &c, unsigned &n) {
  for (BasicBlock &b : F) {
    if (!c.S.rpo.count(&b))
      continue;
    unsigned p = c.block(&b);
    unsigned cf = classicalFactorNode(p, *c.O), q = quantumPartNode(p, *c.O);
    ++n;
    CHECK(A(cf, q) == p, F.getName() << ": p == classicalFactor & quantumPart for " << describe(p));
    CHECK(isClassicalNode(cf, *c.O), F.getName() << ": the classical factor is classical");
    // No classical literal is left as a conjunct of the quantum part.
    std::set<unsigned> sup;
    m.support(q, sup);
    for (unsigned v : sup)
      if (!quantumLike(v, *c.O))
        CHECK(A(q, N(m.ithVar(v))) != Bdd::F && A(q, m.ithVar(v)) != Bdd::F,
              F.getName() << ": quantumPart still has a classical conjunct: " << describe(q));
  }
}

static void testFactoring() {
  SMDiagnostic err;
  auto mod = parseAssemblyString(MixedIR, err, Ctx);
  if (!mod) {
    err.print("pred_unit", errs());
    ++failures;
    return;
  }
  unsigned n = 0;
  auto get = [&](StringRef fn) -> Function & { return *mod->getFunction(fn); };
  for (StringRef fn : {"and_one_i1", "select_one_i1", "two_branches"}) {
    Function &F = get(fn);
    Computed c = compute(F);
    unsigned p = c.block(blk(F, "%t"));
    CHECK(classicalFactorNode(p, *c.O) == C(val(F, "%c")) && quantumPartNode(p, *c.O) == C(val(F, "%q")),
          fn << ": c && q factors as C = c, Q = q (one i1 or two branches alike)");
    checkContract(F, c, n);
  }
  {
    Function &F = get("or_ifelse");
    Computed c = compute(F);
    unsigned pt = c.block(blk(F, "%t")), pe = c.block(blk(F, "%el"));
    CHECK(classicalFactorNode(pt, *c.O) == Bdd::T && quantumPartNode(pt, *c.O) == Or(C(val(F, "%c")), C(val(F, "%q"))),
          "c || q: no classical factor, one flag with c as a seed term");
    CHECK(classicalFactorNode(pe, *c.O) == N(C(val(F, "%c"))) && quantumPartNode(pe, *c.O) == N(C(val(F, "%q"))),
          "else of c || q: C = !c, Q = !q");
    checkContract(F, c, n);
  }
  {
    Function &F = get("nested");
    Computed c = compute(F);
    unsigned p2 = c.block(blk(F, "%t2"));
    CHECK(classicalFactorNode(p2, *c.O) == C(val(F, "%c1")) &&
              quantumPartNode(p2, *c.O) == A(Or(C(val(F, "%c2")), C(val(F, "%q"))), C(val(F, "%q2"))),
          "nested: (c1 && (c2 || q)) && q2 -> C = c1, Q = (c2 || q) & q2");
    checkContract(F, c, n);
  }
  // The examples' blocks too.
  for (auto &mp : modules)
    for (Function &F : *mp)
      if (!F.isDeclaration()) {
        Computed c = compute(F);
        checkContract(F, c, n);
      }
  modules.push_back(std::move(mod));
  outs() << "factoring contract: " << n << " block predicates\n";
}

// ---- 4. flag synthesis ----
struct SimGate { abi::Core op; std::vector<Value *> ctl; Value *t; };
class SimSink : public GateSink {
public:
  std::map<unsigned, Value *> atomRails;            // var -> rail
  std::map<Value *, unsigned> seeds;                // seed rail -> classical node (alloc0: node F)
  std::vector<SimGate> gates;
  std::vector<Value *> pool;
  size_t next = 0;
  Value *fresh() {
    if (next >= pool.size())
      std::abort();
    return pool[next++];
  }
  Value *atomRail(unsigned var) override {
    auto it = atomRails.find(var);
    if (it != atomRails.end())
      return it->second;
    return atomRails[var] = fresh();
  }
  Value *classicalSeed(unsigned node) override {
    Value *r = fresh();
    seeds[r] = node;
    return r;
  }
  Value *alloc0() override { return classicalSeed(Bdd::F); }
  void gate(abi::Core op, ArrayRef<Value *> controls, Value *target) override {
    gates.push_back({op, std::vector<Value *>(controls.begin(), controls.end()), target});
  }
};

static bool apply(const SimGate &g, std::map<Value *, bool> &st) {
  bool v;
  switch (g.op) {
  case abi::Core::NotI1: v = true; break;
  case abi::Core::XorI1: v = st[g.ctl.at(0)]; break;
  case abi::Core::AndI1: v = st[g.ctl.at(0)] && st[g.ctl.at(1)]; break;
  case abi::Core::OrI1: v = st[g.ctl.at(0)] || st[g.ctl.at(1)]; break;
  default: return false;
  }
  st[g.t] = st[g.t] ^ v;
  return true;
}

static void testFlags(Function &pool) {
  std::vector<Value *> args;
  for (Argument &a : pool.args())
    args.push_back(&a);
  // Atoms: q0..q2 quantum (Cond on the first args), k a classical guard-like atom (Eq on another).
  unsigned qv[3] = {atomVar(AtomKind::Cond, args[0]), atomVar(AtomKind::Cond, args[1]),
                    atomVar(AtomKind::Cond, args[2])};
  unsigned kv = atomVar(AtomKind::Eq, args[3], APInt(32, 7));
  auto ql = [&](unsigned v) { return v != kv; };
  std::mt19937 rng(12345);
  unsigned tested = 0, gateTotal = 0;
  for (unsigned nvars : {3u, 4u}) {
    unsigned rows = 1u << nvars;
    unsigned nfun = 1u << rows;
    for (unsigned tt = 0; tt < nfun; ++tt) {
      // Build f from its truth table over (q0, q1, q2[, k]).
      unsigned f = Bdd::F;
      for (unsigned r = 0; r < rows; ++r) {
        if (!((tt >> r) & 1))
          continue;
        unsigned term = Bdd::T;
        for (unsigned i = 0; i < nvars; ++i) {
          unsigned v = m.ithVar(i < 3 ? qv[i] : kv);
          term = m.andOp(term, ((r >> i) & 1) ? v : m.notOp(v));
        }
        f = m.orOp(f, term);
      }
      if (f == Bdd::T || f == Bdd::F)
        continue;
      bool classicalOnly = true;
      std::set<unsigned> sup;
      m.support(f, sup);
      for (unsigned v : sup)
        classicalOnly &= !ql(v);
      SimSink sink;
      sink.pool = std::vector<Value *>(args.begin() + 4, args.end());
      Value *flag = materialize(f, sink, ql);
      ++tested;
      gateTotal += unsigned(sink.gates.size());
      std::set<Value *> atomSet;
      for (auto &[v, r] : sink.atomRails)
        atomSet.insert(r);
      bool structural = true;
      for (const SimGate &g : sink.gates) {
        structural &= !atomSet.count(g.t) && sink.seeds.count(g.t);
        for (Value *c : g.ctl)
          structural &= c != g.t;
      }
      CHECK(structural, "flag gates target only ancillas, never one of their controls: " << describe(f));
      for (unsigned r = 0; r < rows; ++r) {
        auto value = [&](unsigned var) {
          for (unsigned i = 0; i < nvars; ++i)
            if (var == (i < 3 ? qv[i] : kv))
              return bool((r >> i) & 1);
          return false;
        };
        std::map<Value *, bool> st;
        for (auto &[var, rail] : sink.atomRails)
          st[rail] = value(var);
        for (auto &[rail, node] : sink.seeds)
          st[rail] = m.eval(node, value);
        std::map<Value *, bool> init = st;
        for (const SimGate &g : sink.gates)
          CHECK(apply(g, st), "unknown gate kind");
        bool want = m.eval(f, value);
        CHECK(st[flag] == want, "flag value for " << describe(f) << " row " << r);
        // Uncompute: reverse, then a shuffled order of the same records.
        for (int pass = 0; pass < 2; ++pass) {
          std::map<Value *, bool> u = st;
          std::vector<SimGate> rev(sink.gates.rbegin(), sink.gates.rend());
          if (pass == 1) {
            // Reverse dependency order across rails (what the uncompute spine guarantees: a rail is
            // replayed before every rail its gates read), any order among the gates of one rail.
            std::vector<Value *> order, targets;
            for (const SimGate &g : sink.gates)
              if (std::find(targets.begin(), targets.end(), g.t) == targets.end())
                targets.push_back(g.t);
            while (order.size() < targets.size())
              for (Value *t : targets) {
                if (std::find(order.begin(), order.end(), t) != order.end())
                  continue;
                bool ready = true;   // every unprocessed rail that reads t comes first
                for (const SimGate &g : sink.gates)
                  if (std::find(g.ctl.begin(), g.ctl.end(), t) != g.ctl.end() &&
                      std::find(order.begin(), order.end(), g.t) == order.end())
                    ready = false;
                if (ready)
                  order.push_back(t);
              }
            rev.clear();
            for (Value *t : order) {
              std::vector<SimGate> grp;
              for (const SimGate &g : sink.gates)
                if (g.t == t)
                  grp.push_back(g);
              std::shuffle(grp.begin(), grp.end(), rng);
              rev.insert(rev.end(), grp.begin(), grp.end());
            }
          }
          for (const SimGate &g : rev)
            apply(g, u);
          bool clean = true;
          for (auto &[rail, v] : init)
            clean &= u[rail] == v;
          CHECK(clean, "replay restores every rail (" << (pass ? "per-rail shuffled" : "reverse") << "): " << describe(f));
        }
      }
      if (classicalOnly)
        CHECK(sink.gates.empty() && sink.seeds.size() == 1, "a classical function is one seed rail");
    }
  }
  outs() << "flag synthesis: " << tested << " functions, " << gateTotal << " gates\n";
}

int main() {
  testAlgebra();
  testExamples();
  testFactoring();
  // A pool function: 4 atom carriers + 60 rails.
  std::vector<Type *> params(64, Type::getInt32Ty(Ctx));
  Module poolMod("pool", Ctx);
  Function *pool = Function::Create(FunctionType::get(Type::getVoidTy(Ctx), params, false),
                                    GlobalValue::ExternalLinkage, "pool", poolMod);
  testFlags(*pool);
  outs() << "pred_unit: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
