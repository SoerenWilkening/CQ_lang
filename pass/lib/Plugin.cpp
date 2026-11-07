// The cq-lower and cq-verify passes (scaffold, cq-arch "Pass pipeline").
//
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower
//       [-cq-k=<fn>=<k>,...] [-cq-k-default=<k>] [-cq-k2=<fn>=<k>,...] [-cq-k2-default=<k>] [-cq-roots=<file>]
//       [-cq-dump-taint]
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-verify            (our output)
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes='cq-verify<reference>' (a reference)
//
// cq-lower: a preliminary taint, used only for isTainted(F) and by eff-conc's pre-taint rewrites (rule 24:
// the thread calls collapsed, setjmp/longjmp made explicit control flow, Setjmp.h); FixIrreduciblePass on those
// functions; if any function changed, a fresh taint over the module with the preliminary result
// discarded; construct per specialization; calls::finalize; verifyLowered. Taint is computed once
// over the final CFG and nothing mutates the CFG after it (owner ruling on cq-5k5, option (a)).
// Q2 (rulings): a module with no call to a CQ.h function, no -cq-roots and no reference to a declared clone of a
// linked lowered library (no __cq_q_* declaration) is returned untouched before anything runs (owner ruling 2 on
// cq-arch: the condition is on calls, not declarations or other uses): the pass's identity (NORTHSTAR principle 1,
// kernel tier 1). Inside any other module every function is rewritten unless it has no bus access, no cq_* call and
// no call (rule 19, TaintInfo::isTainted).
#include <functional>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Effects.h"
#include "cq/Lowering.h"
#include "cq/Loops.h"
#include "cq/Taint.h"
#include "cq/Verify.h"
#include "calls/LibCalls.h"
#include "eff/conc/Setjmp.h"
#include "eff/invert/Split.h"
#include "loops/cutoff/Exits.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/FixIrreducible.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/IR/DataLayout.h"

using namespace llvm;

namespace {

cl::list<std::string> KPerFunction("cq-k", cl::CommaSeparated, cl::value_desc("fn=k"),
                                   cl::desc("cq: per-function loop cutoff K, e.g. -cq-k=fmod=2046,sin=53"));
cl::opt<unsigned> KDefault("cq-k-default", cl::value_desc("k"),
                           cl::desc("cq: global loop cutoff K (built-in default 4)"));
cl::list<std::string> K2PerFunction("cq-k2", cl::CommaSeparated, cl::value_desc("fn=k"),
                                    cl::desc("cq: per-function allocation bound K2, e.g. -cq-k2=f=8192"));
cl::opt<unsigned> K2Default("cq-k2-default", cl::value_desc("k"),
                            cl::desc("cq: global allocation bound K2 (built-in default 4096)"));
cl::opt<std::string> RootsFile("cq-roots", cl::value_desc("file"),
                               cl::desc("cq: library-build roots, one clone name (CR §1.4) per line"));
cl::opt<bool> DumpTaint("cq-dump-taint", cl::desc("cq: print the taint result to stderr"));
// Private to scaffold (Plugin.cpp and tests/scaffold): one stderr line per pipeline step, so a test
// can see that the taint the constructions read is the one computed over the final CFG.
cl::opt<bool> TracePipeline("cq-trace-pipeline", cl::Hidden,
                            cl::desc("cq: print each cq-lower pipeline step to stderr"));

// Private to eff-conc's tests: the module after the rule-24 setjmp rewrite, on stderr.
cl::opt<bool> DumpSetjmp("cq-dump-setjmp", cl::Hidden,
                         cl::desc("cq: print the module after the rule 24 setjmp rewrite to stderr"));

void trace(const Twine &step) {
  if (TracePipeline)
    errs() << "cq-lower: " << step << "\n";
}

[[noreturn]] void usageError(const Twine &msg) {
  report_fatal_error("cq: " + msg, /*gen_crash_diag=*/false);
}

// -cq-k and -cq-k-default. The precedence (flag, CQ_K, global, default 4) is loops::resolveK's.
cq::loops::KOptions readKOptions() {
  cq::loops::KOptions K;
  for (const std::string &item : KPerFunction) {
    auto [fn, k] = StringRef(item).split('=');
    unsigned v = 0;
    if (fn.empty() || k.empty() || k.getAsInteger(10, v) || v == 0)
      usageError("-cq-k: expected <fn>=<k> with k >= 1, got '" + item + "'");
    K.perFunction[fn.str()] = v;
  }
  if (KDefault.getNumOccurrences()) {
    if (KDefault == 0)
      usageError("-cq-k-default: expected k >= 1");
    K.global = KDefault;
  }
  for (const std::string &item : K2PerFunction) {
    auto [fn, k] = StringRef(item).split('=');
    unsigned v = 0;
    if (fn.empty() || k.empty() || k.getAsInteger(10, v) || v == 0)
      usageError("-cq-k2: expected <fn>=<k> with k >= 1, got '" + item + "'");
    K.k2PerFunction[fn.str()] = v;
  }
  if (K2Default.getNumOccurrences()) {
    if (K2Default == 0)
      usageError("-cq-k2-default: expected k >= 1");
    K.k2Global = K2Default;
  }
  return K;
}

cq::TaintOptions readTaintOptions() {
  cq::TaintOptions TO;
  if (RootsFile.empty())
    return TO;
  auto buf = MemoryBuffer::getFile(RootsFile);
  if (!buf)
    usageError("-cq-roots: cannot read '" + RootsFile + "': " + buf.getError().message());
  SmallVector<StringRef, 64> lines;
  (*buf)->getBuffer().split(lines, '\n', -1, /*KeepEmpty=*/false);
  for (StringRef line : lines) {
    line = line.trim();
    if (line.empty())
      continue;
    // Rule 27: a C name is a bodiless function a root list names (Q6); a clone name is a library-build root.
    if (!line.starts_with("__cq_q_")) {
      TO.listed.push_back(line.str());
      continue;
    }
    std::optional<cq::abi::CloneSpec> spec = cq::abi::parseClone(line);
    if (!spec)
      usageError("-cq-roots: not a clone name: '" + line + "'");
    TO.roots.push_back(std::move(*spec));
  }
  return TO;
}

// The CQ.h surface: cq_theta_*, cq_measure_*, cq_phi, __cq_invert_begin, __cq_invert_end.
// CR rules 13, 14: a switch on a phi of constants that are all among its cases never takes its default (clang's cleanup-dest switch after a
// loop that leaves by goto). The dead edge would count as a live exit of an enclosing loop, moving that loop's continuation past the code
// after the join. The same kind of rewrite as unifyReturns: the default goes to the first case's block, its target loses this predecessor.
bool dropDeadSwitchDefaults(Function &F) {
  bool any = false;
  for (BasicBlock &BB : F) {
    auto *sw = dyn_cast<SwitchInst>(BB.getTerminator());
    auto *p = sw ? dyn_cast<PHINode>(sw->getCondition()) : nullptr;
    if (!p || sw->getNumCases() == 0)
      continue;
    bool covered = all_of(p->incoming_values(), [&](Value *v) {
      auto *c = dyn_cast<ConstantInt>(v);
      return c && sw->findCaseValue(c) != sw->case_default();
    });
    BasicBlock *dflt = sw->getDefaultDest(), *first = sw->case_begin()->getCaseSuccessor();
    if (!covered || dflt == first)
      continue;
    bool otherEdge = any_of(sw->cases(), [&](auto &k) { return k.getCaseSuccessor() == dflt; });
    if (!otherEdge)
      dflt->removePredecessor(&BB);
    Value *firstIn = nullptr;
    sw->setDefaultDest(first);
    for (PHINode &q : first->phis()) {
      firstIn = q.getIncomingValueForBlock(&BB);
      q.addIncoming(firstIn, &BB);
    }
    any = true;
  }
  if (any)
    removeUnreachableBlocks(F);
  return any;
}

// cq-jkq8: one return block per tainted function, the same kind of rewrite as fix-irreducible (CR rule 14:
// a semantics-preserving CFG rewrite before the final taint; §6 compares semantics, never CFG shape). Each
// return becomes a branch to one block returning the phi of their values, so a return under a quantum
// predicate is the function's only return (the paths outside its predicate never return: they abort or never
// end, rules 14 and 16) and returns on several quantum paths merge by rule 9 at that phi. A musttail call
// (clang's [[clang::musttail]]) becomes an ordinary tail call: the lowering calls clones of other signatures
// anyway, and C semantics do not depend on the frame being reused.
bool unifyReturns(Function &F) {
  SmallVector<ReturnInst *, 4> rets;
  for (BasicBlock &BB : F)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      rets.push_back(R);
  if (rets.size() < 2)
    return false;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I); CI && CI->isMustTailCall())
        CI->setTailCallKind(CallInst::TCK_Tail);
  LLVMContext &C = F.getContext();
  BasicBlock *U = BasicBlock::Create(C, "cq.ret", &F);
  PHINode *PN = nullptr;
  if (!F.getReturnType()->isVoidTy()) {
    PN = PHINode::Create(F.getReturnType(), unsigned(rets.size()), "cq.retval");
    PN->insertInto(U, U->end());
  }
  ReturnInst::Create(C, PN, U);
  for (ReturnInst *R : rets) {
    BasicBlock *BB = R->getParent();
    if (PN)
      PN->addIncoming(R->getReturnValue(), BB);
    R->eraseFromParent();
    BranchInst::Create(U, BB);
  }
  return true;
}

// Rule 16: "The `unreachable` after an unconditional `noreturn` call is a return of zero-valued results". A noreturn call on a
// classical path that some clone lowers to abort_i1 (a _ctl clone's predicate, an effect entry's seed) comes back: where that
// flag reads 0 the program goes on, so the path returns instead of running into `unreachable`. A call another clone keeps as
// the host call never gets there. Runs before unifyReturns. A loop that any clone runs on a quantum condition keeps its arm
// (rule 14's abort arm under the trip's flag), and longjmp and a thread's exit are rule 24's.
bool returnFromClassicalAborts(Function &F, const cq::TaintInfo &T, const LoopInfo &LI) {
  if (F.doesNotReturn())
    return false;
  bool changed = false;
  SmallVector<const cq::Specialization *, 4> specs;
  for (const cq::Specialization &S : T.specializations())
    if (S.F == &F)
      specs.push_back(&S);
  for (BasicBlock &BB : F) {
    auto *U = dyn_cast<UnreachableInst>(BB.getTerminator());
    auto *CB = U ? dyn_cast_or_null<CallBase>(U->getPrevNonDebugInstruction()) : nullptr;
    const Function *G = CB ? CB->getCalledFunction() : nullptr;
    if (!G || !CB->doesNotReturn() || CB->hasFnAttr(Attribute::ReturnsTwice))
      continue;
    StringRef n = G->getName();
    if (n == "longjmp" || n == "_longjmp" || n == "siglongjmp" || n == "__longjmp_chk" || n == "pthread_exit" || n == "thrd_exit")
      continue;
    if (none_of(specs, [&](const cq::Specialization *S) {
          return !T.controlTainted(&BB, *S) && (S->ctl || T.isEffectEntry(*CB, *S));
        }))
      continue;
    bool quantumLoop = false;
    if (const Loop *L = LI.getLoopFor(&BB))
      for (const BasicBlock *X : L->getOutermostLoop()->blocks())
        for (const cq::Specialization *S : specs)
          quantumLoop = quantumLoop || T.controlTainted(X, *S);
    if (quantumLoop)
      continue;
    Type *RT = F.getReturnType();
    ReturnInst::Create(F.getContext(), RT->isVoidTy() ? nullptr : Constant::getNullValue(RT), U->getIterator());
    U->eraseFromParent();
    changed = true;
  }
  if (changed)
    for (Attribute::AttrKind A : {Attribute::Range, Attribute::NonNull, Attribute::Dereferenceable, Attribute::DereferenceableOrNull})
      F.removeRetAttr(A);   // the zero result of the new path
  return changed;
}

// Rule 26: an aggregate is its scalar fields. A loop-carried aggregate (a cmpxchg's { i32, i1 } carried round musl's
// __lockfile) is one phi per field, so the loop modules carry scalars only. No CFG change.
bool splitCarriedAggregates(Function &F) {
  DominatorTree DT(F);
  SmallVector<PHINode *, 4> phis;
  for (BasicBlock &BB : F) {
    if (!any_of(predecessors(&BB), [&](BasicBlock *P) { return DT.dominates(&BB, P); }))
      continue;
    for (PHINode &P : BB.phis())
      if (P.getType()->isAggregateType())
        phis.push_back(&P);
  }
  for (PHINode *P : phis) {
    SmallVector<SmallVector<unsigned, 2>, 4> paths;
    SmallVector<Type *, 4> leaves;
    std::function<void(Type *, SmallVector<unsigned, 2> &)> walk = [&](Type *T, SmallVector<unsigned, 2> &at) {
      if (!T->isAggregateType()) {
        paths.push_back(at);
        leaves.push_back(T);
        return;
      }
      unsigned n = isa<StructType>(T) ? cast<StructType>(T)->getNumElements() : cast<ArrayType>(T)->getNumElements();
      for (unsigned k = 0; k < n; ++k) {
        at.push_back(k);
        walk(GetElementPtrInst::getTypeAtIndex(T, k), at);
        at.pop_back();
      }
    };
    SmallVector<unsigned, 2> at;
    walk(P->getType(), at);
    SmallVector<PHINode *, 4> parts;
    for (unsigned k = 0; k < leaves.size(); ++k) {
      PHINode *N = PHINode::Create(leaves[k], P->getNumIncomingValues(), P->getName(), P->getIterator());
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
        IRBuilder<> B(P->getIncomingBlock(i)->getTerminator());
        N->addIncoming(B.CreateExtractValue(P->getIncomingValue(i), paths[k]), P->getIncomingBlock(i));
      }
      parts.push_back(N);
    }
    SmallVector<User *, 4> users(P->users());
    for (User *U : users)
      if (auto *EV = dyn_cast<ExtractValueInst>(U))
        for (unsigned k = 0; k < paths.size(); ++k)
          if (EV->getIndices() == ArrayRef<unsigned>(paths[k])) {
            EV->replaceAllUsesWith(parts[k]);
            EV->eraseFromParent();
            break;
          }
    if (!P->use_empty()) {
      IRBuilder<> B(P->getParent(), P->getParent()->getFirstNonPHIIt());
      Value *whole = PoisonValue::get(P->getType());
      for (unsigned k = 0; k < parts.size(); ++k)
        whole = B.CreateInsertValue(whole, parts[k], paths[k]);
      P->replaceAllUsesWith(whole);
    }
    P->eraseFromParent();
  }
  return !phis.empty();
}

// CR rule 14 "Irreducible control flow" (cq-0ygtj): LLVM's fix-irreducible takes `br`, `ret` and `unreachable` only (its
// precondition is lower-switch first; a hub over a switch predecessor crashes this release build, plain
// `opt -passes=fix-irreducible` included). In a function with an irreducible cycle, a switch or computed goto with an edge
// into a cycle becomes rule 13's chain: one equality test per case, the same predicates, so its edges can join the hub.
// Every other switch keeps its form.
void chainDispatch(Instruction *T) {
  BasicBlock *B = T->getParent();
  Function &F = *B->getParent();
  LLVMContext &C = F.getContext();
  // The tests in order, and where the last one's false edge goes.
  SmallVector<std::pair<Constant *, BasicBlock *>, 8> tests;
  BasicBlock *last = nullptr;
  Value *cond;
  if (auto *SI = dyn_cast<SwitchInst>(T)) {
    cond = SI->getCondition();
    for (auto &K : SI->cases())
      tests.push_back({K.getCaseValue(), K.getCaseSuccessor()});
    last = SI->getDefaultDest();
  } else {
    auto *IB = cast<IndirectBrInst>(T);
    cond = IB->getAddress();
    SmallVector<BasicBlock *, 8> dests;
    for (BasicBlock *d : successors(IB))
      if (!is_contained(dests, d))
        dests.push_back(d);
    last = dests.pop_back_val();
    for (BasicBlock *d : dests)
      tests.push_back({BlockAddress::get(&F, d), d});
  }
  // The value each successor's phis take from B; every edge of the chain carries it.
  DenseMap<PHINode *, Value *> in;
  SmallSetVector<BasicBlock *, 8> succs(succ_begin(B), succ_end(B));   // a phi edit re-threads use lists: never hash order
  for (BasicBlock *s : succs)
    for (PHINode &P : s->phis()) {
      in[&P] = P.getIncomingValueForBlock(B);
      P.removeIncomingValueIf([&](unsigned i) { return P.getIncomingBlock(i) == B; }, /*DeletePHIIfEmpty=*/false);
    }
  auto edge = [&](BasicBlock *from, BasicBlock *to) {
    for (PHINode &P : to->phis())
      P.addIncoming(in.lookup(&P), from);
  };
  BasicBlock *cur = B;
  BasicBlock *pos = B->getNextNode();
  T->eraseFromParent();
  for (auto &[v, to] : tests) {
    BasicBlock *rest = BasicBlock::Create(C, "cq.case", &F, pos);
    IRBuilder<> IB(cur);
    IB.CreateCondBr(IB.CreateICmpEQ(cond, v), to, rest);
    edge(cur, to);
    cur = rest;
  }
  IRBuilder<>(cur).CreateBr(last);
  edge(cur, last);
}

bool chainIrreducibleDispatch(Function &F) {
  DominatorTree DT(F);
  // A graph is reducible iff the target of every retreating edge of a DFS dominates the source.
  bool irreducible = false;
  DenseSet<const BasicBlock *> seen, onStack;
  std::vector<std::pair<const BasicBlock *, const_succ_iterator>> stack;
  const BasicBlock *E = &F.getEntryBlock();
  seen.insert(E);
  onStack.insert(E);
  stack.push_back({E, succ_begin(E)});
  while (!stack.empty() && !irreducible) {
    auto &[b, it] = stack.back();
    if (it == succ_end(b)) {
      onStack.erase(b);
      stack.pop_back();
      continue;
    }
    const BasicBlock *s = *it++;
    if (onStack.count(s))
      irreducible = !DT.dominates(s, b);
    else if (seen.insert(s).second) {
      onStack.insert(s);
      stack.push_back({s, succ_begin(s)});
    }
  }
  if (!irreducible)
    return false;
  // A nested cycle lies inside a cycle of the whole function: every block a hub can be entered from has an edge into one.
  DenseSet<const BasicBlock *> onCycle;
  for (auto I = scc_begin(&F); !I.isAtEnd(); ++I)
    if (I->size() > 1)
      onCycle.insert(I->begin(), I->end());
  SmallVector<Instruction *, 4> todo;
  for (BasicBlock &B : F)
    if (isa<SwitchInst, IndirectBrInst>(B.getTerminator()) &&
        any_of(successors(&B), [&](BasicBlock *s) { return onCycle.count(s) != 0; }))
      todo.push_back(B.getTerminator());
  for (Instruction *T : todo)
    chainDispatch(T);
  return !todo.empty();
}

// CR rule 14 "No live exit", rule 16 (cq-0etzs): -O1 merges noreturn blocks, so a loop's noreturn arm may also be entered
// from outside the loop (the pre-header guard of `while (1) { if (t) exit(0); ... }`). The loop module lowers an arm per trip
// for the loop's own edges and nothing else runs it, so each edge from outside would lose its abort. The outside edges get a
// copy of the arm from the block they enter on, the same kind of rewrite as unifyReturns: there it is an ordinary dead end
// under that edge's predicate, and the arm stays the loop's alone.
bool splitSharedNoreturnArms(Function &F) {
  bool any = false;
  for (bool changed = true; changed;) {
    changed = false;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (Loop *L : LI.getLoopsInPreorder()) {
      cq::loops::exits::Unit U = cq::loops::exits::unitOf(*L);
      if (U.abort.empty())
        continue;
      auto own = [&](BasicBlock *b) { return L->contains(b) || is_contained(U.abort, b) || is_contained(U.arm, b); };
      SmallPtrSet<BasicBlock *, 8> shared;
      SmallSetVector<BasicBlock *, 8> outside;   // found order, as copySet: their edits re-thread use lists
      for (BasicBlock *b : U.abort)
        for (BasicBlock *p : predecessors(b))
          if (!own(p)) {
            shared.insert(b);
            outside.insert(p);
          }
      if (shared.empty())
        continue;
      SmallPtrSet<BasicBlock *, 8> entered(shared);
      // U.abort is topological and closed under successors: what a shared block reaches is copied with it.
      SmallVector<BasicBlock *, 8> copied;
      for (BasicBlock *b : U.abort)
        if (shared.count(b) || any_of(predecessors(b), [&](BasicBlock *p) { return shared.count(p) != 0; })) {
          shared.insert(b);
          copied.push_back(b);
        }
      ValueToValueMapTy VM;
      SmallSetVector<BasicBlock *, 8> copySet;
      for (BasicBlock *b : copied) {
        BasicBlock *n = CloneBasicBlock(b, VM, ".out", &F);
        VM[b] = n;
        copySet.insert(n);
      }
      for (BasicBlock *n : copySet)
        for (Instruction &I : *n)
          RemapInstruction(&I, VM, RF_IgnoreMissingLocals | RF_NoModuleLevelChanges);
      // The outside edges move to the copy: each side's phis keep their own edges.
      for (BasicBlock *n : copySet)
        for (PHINode &P : n->phis())
          P.removeIncomingValueIf(
              [&](unsigned i) {
                BasicBlock *f = P.getIncomingBlock(i);
                return !copySet.count(f) && !outside.count(f);
              },
              /*DeletePHIIfEmpty=*/false);
      for (BasicBlock *b : copied)
        for (PHINode &P : b->phis())
          P.removeIncomingValueIf([&](unsigned i) { return outside.count(P.getIncomingBlock(i)) != 0; },
                                  /*DeletePHIIfEmpty=*/false);
      for (BasicBlock *p : outside) {
        Instruction *t = p->getTerminator();
        for (unsigned i = 0; i < t->getNumSuccessors(); ++i)
          if (entered.count(t->getSuccessor(i)))
            t->setSuccessor(i, cast<BasicBlock>(VM[t->getSuccessor(i)]));
      }
      any = changed = true;
      break;
    }
  }
  return any;
}

// CR rule 14 (`continue`, `return` inside a K-loop, nested K-loops: "same chain"): a sub-loop whose live exits meet only
// outside its parent (printf_core's overflow return from its literal scan) ends through ONE block of the parent, the same
// kind of rewrite as fix-irreducible and unifyReturns: its live exit edges meet at a hub, phis of the hub carry the values
// their targets' phis and later readers take (poison on an edge whose value does not reach), and the hub branches on which
// edge came in. The parent's trip then reads the sub-loop as one node ending at the hub, and the edge out of the parent is
// the parent's own exit, taken from the parent's own block.
bool unifySubLoopExits(Function &F) {
  bool any = false;
  LLVMContext &C = F.getContext();
  for (bool changed = true; changed;) {
    changed = false;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (Loop *S : LI.getLoopsInPreorder()) {
      Loop *P = S->getParentLoop();
      if (!P)
        continue;
      cq::loops::exits::Unit U = cq::loops::exits::unitOf(*S);
      SmallVector<BasicBlock *, 4> targets;
      for (BasicBlock *x : U.live)
        targets.push_back(x);
      // Several live exits whose common post-dominator lies outside the parent: no join within the parent's trip, so the
      // exit arm would run through the parent's own back edge (twoway_strstr's inner match scan).
      if (!U.multi() || P->contains(U.cont))
        continue;
      // The live exit edges, one (from, to) per pair.
      SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> edges;
      for (BasicBlock *u : S->blocks())
        for (BasicBlock *x : successors(u))
          if (is_contained(targets, x) && !is_contained(edges, std::make_pair(u, x)))
            edges.push_back({u, x});
      BasicBlock *E = BasicBlock::Create(C, "cq.exits", &F);
      // Values of the loop read outside it, taken before any edge moves: per edge, whether the value reaches it.
      SmallVector<Instruction *, 8> outs;
      for (BasicBlock *b : S->blocks())
        for (Instruction &I : *b)
          if (any_of(I.uses(), [&](Use &us) {
                auto *ui = cast<Instruction>(us.getUser());
                if (S->contains(ui))
                  return false;
                // A target's phi on an exit edge is rewritten below; any other outside read is a later reader.
                auto *ph = dyn_cast<PHINode>(ui);
                return !(ph && S->contains(ph->getIncomingBlock(us)));
              }))
            outs.push_back(&I);
      std::vector<std::vector<bool>> reaches(outs.size(), std::vector<bool>(edges.size()));
      for (size_t k = 0; k < outs.size(); ++k)
        for (size_t e = 0; e < edges.size(); ++e)
          reaches[k][e] = DT.dominates(outs[k]->getParent(), edges[e].first);
      // An edge's source in the hub: u itself, or a block of its own where u leaves for another target too.
      SmallVector<BasicBlock *, 4> from(edges.size());
      for (size_t e = 0; e < edges.size(); ++e) {
        auto [u, x] = edges[e];
        const bool shared = count_if(edges, [&](const auto &o) { return o.first == u; }) > 1;
        BasicBlock *f = u;
        if (shared) {
          f = BasicBlock::Create(C, "cq.exit", &F);
          BranchInst::Create(E, f);
        }
        Instruction *t = u->getTerminator();
        for (unsigned i = 0; i < t->getNumSuccessors(); ++i)
          if (t->getSuccessor(i) == x)
            t->setSuccessor(i, shared ? f : E);
        from[e] = f;
      }
      // The target's phis: one hub phi each.
      for (BasicBlock *x : targets)
        for (PHINode &P : x->phis()) {
          PHINode *h = PHINode::Create(P.getType(), edges.size(), P.getName() + ".hub");
          h->insertInto(E, E->end());
          for (size_t e = 0; e < edges.size(); ++e)
            h->addIncoming(edges[e].second == x ? P.getIncomingValueForBlock(edges[e].first) : PoisonValue::get(P.getType()),
                           from[e]);
          for (auto &[u, y] : edges)
            if (y == x)
              while (P.getBasicBlockIndex(u) >= 0)
                P.removeIncomingValue(u, /*DeletePHIIfEmpty=*/false);
          P.addIncoming(h, E);
        }
      // Later readers of the loop's values.
      for (size_t k = 0; k < outs.size(); ++k) {
        Instruction *I = outs[k];
        PHINode *h = PHINode::Create(I->getType(), edges.size(), I->getName() + ".hub");
        h->insertInto(E, E->begin());
        for (size_t e = 0; e < edges.size(); ++e)
          h->addIncoming(reaches[k][e] ? static_cast<Value *>(I) : PoisonValue::get(I->getType()), from[e]);
        for (Use &us : make_early_inc_range(I->uses())) {
          auto *ui = cast<Instruction>(us.getUser());
          if (ui != h && !S->contains(ui) && ui->getParent() != E) {
            if (auto *ph = dyn_cast<PHINode>(ui); ph && ph->getParent() != E)
              if (S->contains(ph->getIncomingBlock(us)))
                continue;   // the incoming of an edge inside the loop: a phi the loop itself owns
            us.set(h);
          }
        }
      }
      // Which edge came in: a branch for two targets, a switch for more.
      if (targets.size() == 2) {
        PHINode *w = PHINode::Create(Type::getInt1Ty(C), edges.size(), "cq.which");
        w->insertInto(E, E->begin());
        for (size_t e = 0; e < edges.size(); ++e)
          w->addIncoming(ConstantInt::getBool(C, edges[e].second == targets[0]), from[e]);
        BranchInst::Create(targets[0], targets[1], w, E);
      } else {
        PHINode *w = PHINode::Create(Type::getInt32Ty(C), edges.size(), "cq.which");
        w->insertInto(E, E->begin());
        for (size_t e = 0; e < edges.size(); ++e)
          w->addIncoming(ConstantInt::get(Type::getInt32Ty(C),
                                          find(targets, edges[e].second) - targets.begin()),
                         from[e]);
        SwitchInst *sw = SwitchInst::Create(w, targets.back(), targets.size() - 1, E);
        for (size_t i = 0; i + 1 < targets.size(); ++i)
          sw->addCase(ConstantInt::get(Type::getInt32Ty(C), i), targets[i]);
      }
      changed = any = true;
      break;   // the loops changed: LoopInfo again
    }
  }
  return any;
}

// cq-jkq8 (CR rule 23): llvm.get.rounding (C's FLT_ROUNDS) and llvm.set.rounding read and write the rounding
// mode, the environment's mode part, which C17 §7.6 reads and writes by fegetround / fesetround. In a tainted
// function each becomes that call with x86-64's encoding change around it (FLT_ROUNDS 0 toward zero, 1 nearest,
// 2 upward, 3 downward; FE_* the rounding-control bits << 10), so rule 23's fenv construction lowers it, a
// quantum mode included (the encoding change is ordinary arithmetic on the mode). An argument of set.rounding
// outside 0..3 has no defined effect (LangRef), outside the domain.
bool rewriteRoundingIntrinsics(Function &F) {
  SmallVector<IntrinsicInst *, 4> work;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *II = dyn_cast<IntrinsicInst>(&I);
          II && (II->getIntrinsicID() == Intrinsic::get_rounding || II->getIntrinsicID() == Intrinsic::set_rounding))
        work.push_back(II);
  if (work.empty())
    return false;
  Module &M = *F.getParent();
  Type *i32 = Type::getInt32Ty(M.getContext());
  for (IntrinsicInst *II : work) {
    IRBuilder<> B(II);
    if (II->getIntrinsicID() == Intrinsic::get_rounding) {
      FunctionCallee get = M.getOrInsertFunction("fegetround", FunctionType::get(i32, false));
      Value *m = B.CreateCall(get);
      // FLT_ROUNDS = (0x2d >> ((m >> 9) & 6)) & 3 for m one of 0, 0x400, 0x800, 0xc00.
      Value *s = B.CreateAnd(B.CreateLShr(m, 9), 6);
      Value *r = B.CreateAnd(B.CreateLShr(ConstantInt::get(i32, 0x2d), s), 3);
      if (r->getType() != II->getType())
        r = B.CreateZExtOrTrunc(r, II->getType());
      II->replaceAllUsesWith(r);
    } else {
      FunctionCallee set = M.getOrInsertFunction("fesetround", FunctionType::get(i32, {i32}, false));
      // FE_* = ((0x63 >> 2r) & 3) << 10: r = 0, 1, 2, 3 to 0xc00, 0, 0x800, 0x400.
      Value *r = B.CreateZExtOrTrunc(II->getArgOperand(0), i32);
      Value *rc = B.CreateAnd(B.CreateLShr(ConstantInt::get(i32, 0x63), B.CreateShl(r, 1)), 3);
      B.CreateCall(set, {B.CreateShl(rc, 10)});
    }
    II->eraseFromParent();
  }
  return true;
}

bool isCqSurface(StringRef name) {
  return name.starts_with("cq_theta_") || name.starts_with("cq_measure_") || name == "cq_phi" ||
         name == "__cq_invert_begin" || name == "__cq_invert_end";
}

// Q2 (c): a reference to a declared clone of a linked lowered library.
bool referencesDeclaredClone(const Module &M) {
  for (const Function &F : M)
    if (F.isDeclaration() && F.getName().starts_with("__cq_q_"))
      return true;
  return false;
}

// True iff some call site calls a CQ.h surface function directly (owner ruling 2 on cq-arch). Only
// a CallBase whose callee operand is the function counts: a declaration, a store of the address, an
// @llvm.used entry, a constant expression or the function passed as a call argument does not.
// cq_phi alone counts (rule 12 deletes it; the deletion is the pass's to make).
bool callsCqSurface(const Module &M) {
  for (const Function &F : M) {
    if (!isCqSurface(F.getName()))
      continue;
    for (const Use &U : F.uses())
      if (const auto *CB = dyn_cast<CallBase>(U.getUser()); CB && CB->isCallee(&U))
        return true;
  }
  return false;
}

// cq-i9wk (CR rule 19): an in-place callee (reached with no quantum argument) is constructed before its
// callers, which read whether its quantum results are frozen (spine::entryReturn). Otherwise taint's
// order; a cycle of in-place calls keeps it.
std::vector<const cq::Specialization *> constructionOrder(const cq::TaintInfo &T) {
  llvm::ArrayRef<cq::Specialization> all = T.specializations();
  std::vector<const cq::Specialization *> order;
  llvm::DenseMap<const cq::Specialization *, int> state;   // 1 in progress, 2 done
  std::function<void(const cq::Specialization &)> visit = [&](const cq::Specialization &S) {
    int &st = state[&S];
    if (st)
      return;
    st = 1;
    if (!S.F->isDeclaration() && !S.pure)
      for (BasicBlock &BB : *S.F)
        for (Instruction &I : BB)
          if (auto *CB = dyn_cast<CallBase>(&I);
              CB && CB->getCalledFunction() && !CB->getCalledFunction()->isDeclaration() && !CB->isInlineAsm())
            if (const cq::Specialization *C = T.calleeSpecialization(*CB, S); C && C != &S) {
              if (C->isEntry())
                visit(*C);
            }
    state[&S] = 2;
    order.push_back(&S);
  };
  for (const cq::Specialization &S : all)
    visit(S);
  return order;
}

struct CQLowerPass : PassInfoMixin<CQLowerPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {
    cq::TaintOptions TO = readTaintOptions();
    // Read before the identity exit so a malformed flag fails on every module.
    cq::loops::KOptions KO = readKOptions();
    if (TO.roots.empty() && TO.listed.empty() && !callsCqSurface(M) && !referencesDeclaredClone(M))
      return PreservedAnalyses::all();

    FunctionAnalysisManager &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

    // 0. Rules 16, 22, 24: library calls that are memory operations under another name (calls/LibCalls.h).
    cq::calls::canonicalizeLibCalls(M);

    // 1. Preliminary taint. Read only for isTainted(F): which functions step 2 may touch.
    trace("taint: preliminary");
    cq::TaintInfo T = cq::computeTaint(M, TO);
    SmallVector<Function *, 16> Tainted;
    for (Function &F : M)
      if (!F.isDeclaration() && (T.isTainted(F) || T.hasClone(F)))
        Tainted.push_back(&F);

    // 1b. Rule 16: a deferred host call's result the program reads is the library's formatting body on a
    // null buffer (cq-a63l). No CFG change; the taint below is recomputed when it rewrote anything.
    bool CFGChanged = cq::tape::rewriteDeferredResults(M, T);
    if (CFGChanged) {
      T = cq::TaintInfo();
      T = cq::computeTaint(M, TO);
      Tainted.clear();
      for (Function &F : M)
        if (!F.isDeclaration() && (T.isTainted(F) || T.hasClone(F)))
          Tainted.push_back(&F);
    }

    // 1c. CR rule 24 (eff-conc, Setjmp.h), in tainted functions: the thread calls as the sequential schedule, then
    // (it may erase originals, so T is read before) setjmp/longjmp as explicit control flow with its escape clones.
    // Their CFG changes are final-taint input.
    SmallPtrSet<Function *, 8> changed;
    for (Function *F : cq::conc::collapseThreads(M, T))
      changed.insert(F);
    for (Function *F : cq::conc::explicitSetjmp(M, T))   // may erase originals: compared, never read
      changed.insert(F);
    SmallVector<Function *, 8> SJ;
    for (Function &F : M)
      if (changed.count(&F))
        SJ.push_back(&F);
    if (!SJ.empty()) {
      trace("rule 24 rewrites: changed");
      if (DumpSetjmp)
        M.print(errs(), nullptr);
      CFGChanged = true;
      Tainted.clear();
      for (Function &F : M)
        if (!F.isDeclaration() && (T.isTainted(F) || T.hasClone(F) || is_contained(SJ, &F)))
          Tainted.push_back(&F);
      for (Function *F : SJ)
        FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 1d. CR rule 17 (2026-11-02, cq-asfn): a cq_invert marker in a quantum arm whose match is outside the
    // arm: the tail is split per region depth (eff-invert Split.h). Its CFG changes are final-taint input.
    for (Function *F : cq::invert::splitMarkerPaths(M, T)) {
      trace("rule 17 marker paths: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 2. Reducible control flow, on tainted functions only (NORTHSTAR principle 1). The pass
    // returns PreservedAnalyses::all() exactly when it left the function unchanged.
    for (Function *F : Tainted) {
      if (chainIrreducibleDispatch(*F)) {
        trace("irreducible dispatch: changed @" + F->getName());
        CFGChanged = true;
        FAM.invalidate(*F, PreservedAnalyses::none());
      }
      PreservedAnalyses PA = FixIrreduciblePass().run(*F, FAM);
      if (PA.areAllPreserved())
        continue;
      trace("fix-irreducible: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PA);
    }
    // 2b. One return block per tainted function (unifyReturns), and the rounding intrinsics as the C17 calls
    // (rewriteRoundingIntrinsics), cq-jkq8.
    for (Function *F : Tainted) {
      if (!rewriteRoundingIntrinsics(*F))
        continue;
      trace("rounding intrinsics: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }
    for (Function *F : Tainted) {
      if (!dropDeadSwitchDefaults(*F))
        continue;
      trace("dead switch defaults: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }
    for (Function *F : Tainted) {
      if (!returnFromClassicalAborts(*F, T, FAM.getResult<LoopAnalysis>(*F)))
        continue;
      trace("classical abort arms: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }
    for (Function *F : Tainted) {
      if (!unifyReturns(*F))
        continue;
      trace("unify-returns: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }
    // 2c. A sub-loop with an exit that also leaves its parent ends through one block of the parent (unifySubLoopExits).
    for (Function *F : Tainted) {
      if (!unifySubLoopExits(*F))
        continue;
      trace("sub-loop exits: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 2c. A loop's noreturn arm is the loop's alone (splitSharedNoreturnArms).
    for (Function *F : Tainted) {
      if (!splitSharedNoreturnArms(*F))
        continue;
      trace("noreturn arms: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 2c. Rule 26: a loop-carried aggregate is its fields.
    for (Function *F : Tainted) {
      if (!splitCarriedAggregates(*F))
        continue;
      trace("carried aggregates: changed @" + F->getName());
      CFGChanged = true;
      FAM.invalidate(*F, PreservedAnalyses::none());
    }

    // 3. Taint over the final CFG. Step 2 added blocks, phis and branches the preliminary result
    // has no answer for, so it is released first and replaced by a fresh analysis; no handle to
    // it survives. Unchanged CFG: the preliminary result already is the taint of the final CFG.
    if (CFGChanged) {
      T = cq::TaintInfo();
      trace("taint: final (fresh, CFG changed)");
      T = cq::computeTaint(M, TO);
    } else {
      trace("taint: final (preliminary, CFG unchanged)");
    }
    const cq::TaintInfo &Final = T;
    if (DumpTaint)
      Final.print(errs());

    // 4. The general construction, once per specialization. The CFG is final from here on.
    trace("construct");
    for (const cq::Specialization *S : constructionOrder(Final))
      cq::construct(M, Final, *S, KO);

    // 5. Drop originals with no classical caller (rule 18).
    cq::calls::finalize(M);

    // CR rule 13 (b137e75): a lowered computed goto compares its address with blockaddress constants, which a
    // clone (or another lowered function) may take of another function's block. The textual IR names such a
    // block only by name (an unnamed block cannot be referenced from a function printed after its own), so a
    // block whose address is taken outside its own function gets one.
    for (Function &F : M)
      for (BasicBlock &BB : F)
        if (BB.hasAddressTaken() && !BB.hasName())
          if (BlockAddress *BA = BlockAddress::lookup(&BB))
            for (const User *U : BA->users())
              if (auto *CE = dyn_cast<ConstantExpr>(U); CE ? any_of(CE->users(), [&](const User *V) {
                    auto *I = dyn_cast<Instruction>(V);
                    return I && I->getFunction() != &F;
                  })
                                                            : isa<Instruction>(U) &&
                                                                  cast<Instruction>(U)->getFunction() != &F) {
                BB.setName("cq.addr");
                break;
              }

    // 6. The structural verifier, on every run.
    cq::verifyLowered(M);
    return PreservedAnalyses::none();
  }
  static bool isRequired() { return true; }
};

struct CQVerifyPass : PassInfoMixin<CQVerifyPass> {
  cq::VerifyOptions Opts;
  explicit CQVerifyPass(cq::VerifyOptions O) : Opts(O) {}
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    cq::verifyLowered(M, Opts);
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "CQLower", "0", [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
                  if (name == "cq-lower") {
                    MPM.addPass(CQLowerPass());
                    return true;
                  }
                  if (name == "cq-verify") {
                    MPM.addPass(CQVerifyPass(cq::VerifyOptions{}));
                    return true;
                  }
                  if (name == "cq-verify<reference>") {
                    cq::VerifyOptions O;
                    O.reference = true;
                    MPM.addPass(CQVerifyPass(O));
                    return true;
                  }
                  return false;
                });
          }};
}
