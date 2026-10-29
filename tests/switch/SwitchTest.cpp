// Unit tests of module switch (cq-w1-switch): sw::switchEdges against rule 13, on real taint.
//
// For every quantum switch in the owned examples' -O1 IR and in synthetic shapes (a case sharing the
// default's block, a case to an `unreachable` block, an unreachable default whose last case shares a
// block, a single reachable case), with computeTaint's entry specialization:
//   1. semantics: for every tested scrutinee value whose destination is reachable (an `unreachable`
//      destination is undefined, out of the domain), exactly the destination's edge predicate is true;
//      every successor has exactly one entry; every atom is an eqAtom on this switch's scrutinee;
//   2. rule 13's flag count: one eqAtom per reachable case, none for the last reachable case when the
//      default is unreachable (it is the complement), none for a case into an unreachable block.
// Scrutinees of at most 8 bits are tested on every value; wider ones on the case values and their
// neighbours, 0, +-1, MIN, MAX and a seeded random set.
#include "PredInternal.h"

#include <cstdio>
#include <random>
#include <set>

#include "cq/Switch.h"
#include "cq/Taint.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/MemoryBuffer.h"
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
      errs() << "FAIL " << __LINE__ << " [" << where << "]: " << msg << "\n";                      \
    }                                                                                              \
  } while (0)

static std::string where;

static bool unreachableBlock(const BasicBlock *bb) {
  const Instruction *i = bb->getFirstNonPHIOrDbg();
  return i && isa<UnreachableInst>(i);
}

static std::vector<APInt> testValues(const SwitchInst &si) {
  unsigned w = si.getCondition()->getType()->getIntegerBitWidth();
  std::vector<APInt> vs;
  if (w <= 8) {
    for (uint64_t v = 0; v < (uint64_t(1) << w); ++v)
      vs.push_back(APInt(w, v));
    return vs;
  }
  for (const auto &c : si.cases()) {
    const APInt &v = c.getCaseValue()->getValue();
    vs.push_back(v);
    vs.push_back(v + 1);
    vs.push_back(v - 1);
  }
  vs.push_back(APInt(w, 0));
  vs.push_back(APInt(w, 1));
  vs.push_back(APInt::getAllOnes(w));
  vs.push_back(APInt::getSignedMinValue(w));
  vs.push_back(APInt::getSignedMaxValue(w));
  std::mt19937_64 rng(0x5317c4);
  for (int i = 0; i < 64; ++i)
    vs.push_back(APInt(w, rng()));
  return vs;
}

static void checkSwitch(const SwitchInst &si, const TaintInfo &T, const Specialization &S) {
  EdgePreds ep = sw::switchEdges(si, T, S);
  Bdd &m = Bdd::get();

  // Every successor exactly once.
  std::set<const BasicBlock *> succs(succ_begin(&si), succ_end(&si)), seen;
  for (auto &[bb, p] : ep.succ) {
    CHECK(succs.count(bb), "an entry for a block that is no successor");
    CHECK(seen.insert(bb).second, "two entries for one successor");
  }
  CHECK(seen.size() == succs.size(), "a successor without an entry");

  // Every atom is an eqAtom on this scrutinee; count them.
  std::set<unsigned> sup;
  for (auto &e : ep.succ)
    m.support(nodeOf(e.second), sup);
  for (unsigned v : sup) {
    const Atom &a = atomOf(v);
    CHECK(a.kind == AtomKind::Eq && a.v == si.getCondition(), "an atom other than scrutinee == v");
  }
  unsigned reachableCases = 0;
  for (const auto &c : si.cases())
    reachableCases += !unreachableBlock(c.getCaseSuccessor());
  unsigned want = reachableCases - (unreachableBlock(si.getDefaultDest()) ? 1 : 0);
  CHECK(sup.size() == want, "rule 13 flag count: " << sup.size() << " eq atoms, want " << want);

  // Semantics on every tested value in the domain.
  for (const APInt &x : testValues(si)) {
    const BasicBlock *dest = si.getDefaultDest();
    for (const auto &c : si.cases())
      if (c.getCaseValue()->getValue() == x)
        dest = c.getCaseSuccessor();
    if (unreachableBlock(dest))
      continue;   // undefined in LLVM: out of the domain
    for (auto &[bb, p] : ep.succ) {
      bool v = m.eval(nodeOf(p), [&](unsigned var) { return atomOf(var).c == x; });
      CHECK(v == (bb == dest), "scrutinee " << x << ": edge to " << bb->getName() << " is " << v);
    }
  }
}

static unsigned runModule(Module &M, const std::string &name) {
  TaintInfo T = computeTaint(M, TaintOptions{});
  unsigned n = 0;
  for (const Specialization &S : T.specializations()) {
    for (Instruction &I : instructions(*S.F)) {
      auto *si = dyn_cast<SwitchInst>(&I);
      if (!si || !T.isQuantum(si->getCondition(), S))
        continue;
      where = name + ":" + S.F->getName().str() + ":" + si->getParent()->getName().str();
      checkSwitch(*si, T, S);
      ++n;
    }
  }
  return n;
}

static const char *SYNTH = R"(
declare signext i8 @cq_theta_si8(i8 signext, double)
declare signext i8 @cq_measure_si8(i8 signext)

; a case sharing the default's block (case 1, case 3, default -> %a)
define i8 @shared_default(i8 %x0, double %t) {
e:
  %x = call i8 @cq_theta_si8(i8 %x0, double %t)
  switch i8 %x, label %a [ i8 1, label %a
                           i8 2, label %b
                           i8 3, label %a ]
a:
  br label %j
b:
  br label %j
j:
  %r = phi i8 [ 7, %a ], [ %x, %b ]
  %m = call i8 @cq_measure_si8(i8 %r)
  ret i8 %m
}

; a case into an unreachable block, reachable default
define i8 @case_unreachable(i8 %x0, double %t) {
e:
  %x = call i8 @cq_theta_si8(i8 %x0, double %t)
  switch i8 %x, label %c [ i8 0, label %a
                           i8 1, label %u
                           i8 2, label %b ]
a:
  br label %j
b:
  br label %j
c:
  br label %j
u:
  unreachable
j:
  %r = phi i8 [ 1, %a ], [ 2, %b ], [ %x, %c ]
  %m = call i8 @cq_measure_si8(i8 %r)
  ret i8 %m
}

; unreachable default; the last case shares its block with the first
define i8 @default_unreachable_shared_last(i8 %x0, double %t) {
e:
  %x = call i8 @cq_theta_si8(i8 %x0, double %t)
  %k = and i8 %x, 3
  switch i8 %k, label %u [ i8 0, label %a
                           i8 1, label %b
                           i8 2, label %c
                           i8 3, label %a ]
a:
  br label %j
b:
  br label %j
c:
  br label %j
u:
  unreachable
j:
  %r = phi i8 [ 1, %a ], [ 2, %b ], [ %x, %c ]
  %m = call i8 @cq_measure_si8(i8 %r)
  ret i8 %m
}

; unreachable default and one reachable case: the case is the complement (no flag at all)
define i8 @single_case(i8 %x0, double %t) {
e:
  %x = call i8 @cq_theta_si8(i8 %x0, double %t)
  switch i8 %x, label %u [ i8 5, label %a ]
a:
  %m = call i8 @cq_measure_si8(i8 %x)
  ret i8 %m
u:
  unreachable
}

; reachable default only on a wide scrutinee, sparse negative cases
define i64 @wide_sparse(i64 %x0, double %t) {
e:
  %x = call i64 @cq_theta_sl(i64 %x0, double %t)
  switch i64 %x, label %c [ i64 -9223372036854775808, label %a
                            i64 -1, label %b
                            i64 4294967296, label %a ]
a:
  br label %j
b:
  br label %j
c:
  br label %j
j:
  %r = phi i64 [ 1, %a ], [ 2, %b ], [ %x, %c ]
  %m = call i64 @cq_measure_sl(i64 %r)
  ret i64 %m
}
declare i64 @cq_theta_sl(i64, double)
declare i64 @cq_measure_sl(i64)
)";

int main() {
  const char *examples[] = {"22_switch_quantum", "49_switch_shared_unreachable", "123_enum_switch_fallthrough",
                            "147_switch_sparse_default", "148_nested_switch"};
  unsigned switches = 0;
  for (const char *ex : examples) {
    std::string dir = ex, name = dir.substr(dir.find('_') + 1);
    std::string path = std::string(CQ_SPEC_DIR) + "/examples/" + dir + "/" + name + ".O1.ll";
    LLVMContext C;
    SMDiagnostic err;
    std::unique_ptr<Module> M = parseIRFile(path, err, C);
    where = dir;
    CHECK(M != nullptr, "cannot read " << path);
    if (!M)
      continue;
    unsigned n = runModule(*M, dir);
    CHECK(n > 0, "no quantum switch found");
    switches += n;
  }
  {
    LLVMContext C;
    SMDiagnostic err;
    std::unique_ptr<Module> M = parseIR(MemoryBufferRef(SYNTH, "synthetic"), err, C);
    where = "synthetic";
    if (!M)
      err.print("switch_unit", errs());
    CHECK(M != nullptr, "cannot parse the synthetic module");
    if (M) {
      unsigned n = runModule(*M, "synthetic");
      CHECK(n == 5, "synthetic quantum switches: " << n);
      switches += n;
    }
  }
  std::printf("switch_unit: %u quantum switches, %d checks, %d failures\n", switches, checks, failures);
  return failures ? 1 : 0;
}
