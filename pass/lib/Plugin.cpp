// The cq-lower and cq-verify passes (scaffold, cq-arch "Pass pipeline").
//
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-lower
//       [-cq-k=<fn>=<k>,...] [-cq-k-default=<k>] [-cq-k2=<fn>=<k>,...] [-cq-k2-default=<k>] [-cq-roots=<file>]
//       [-cq-dump-taint]
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-verify            (our output)
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes='cq-verify<reference>' (a reference)
//   opt -load-pass-plugin=build/pass/libCQLower.so -passes=cq-drop-bodies -cq-drop-bodies=<fn>,...
//       (the driver's: the named functions of an injection bundle file become declarations, rule 27)
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
#include <set>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Effects.h"
#include "cq/Lowering.h"
#include "cq/Loops.h"
#include "cq/Order.h"
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
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/ValueHandle.h"

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
                               cl::desc("cq: a rule 27 root list, one C function name per line: a listed function with "
                                        "no body is its declared clone, one with a body exports its table clone. A "
                                        "clone name (CR §1.4) is lowered at that mask"));
cl::list<std::string> HostRoots("cq-host-roots", cl::CommaSeparated, cl::value_desc("fn"),
                                cl::desc("cq: library build: the listed roots that are C library functions. The "
                                         "library exports their clones and leaves the C name to the host library"));
cl::list<std::string> DropBodies("cq-drop-bodies", cl::CommaSeparated, cl::value_desc("fn"),
                                 cl::desc("cq-drop-bodies: the functions whose bodies are removed"));
cl::opt<bool> DumpTaint("cq-dump-taint", cl::desc("cq: print the taint result to stderr"));
cl::opt<bool> NoOutput("cq-no-output",
                       cl::desc("cq: in the functions this module lowers, a call of a stream-output function the module "
                                "does not define fails as on a closed stream (its error value, no output, no formatting)"));
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
    if (fn.empty() || k.empty() || k.getAsInteger(10, v))
      usageError("-cq-k: expected <fn>=<k> with k >= 0, got '" + item + "'");   // K = 0 is legal (owner 2026-11-15)
    K.perFunction[fn.str()] = v;
  }
  if (KDefault.getNumOccurrences())
    K.global = KDefault;   // K = 0 is legal (owner ruling Q2 of 2026-11-15, CR §0)
  for (const std::string &item : K2PerFunction) {
    auto [fn, k] = StringRef(item).split('=');
    unsigned v = 0;
    if (fn.empty() || k.empty() || k.getAsInteger(10, v))
      usageError("-cq-k2: expected <fn>=<k> with k >= 0, got '" + item + "'");
    K.k2PerFunction[fn.str()] = v;
  }
  if (K2Default.getNumOccurrences())
    K.k2Global = K2Default;
  return K;
}

cq::TaintOptions readTaintOptions() {
  cq::TaintOptions TO;
  TO.hostRoots.assign(HostRoots.begin(), HostRoots.end());
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

// A loop (its outermost one) that some clone runs on a quantum condition: a block of it control-dependent on a tainted
// terminator, or an exiting branch on a quantum condition (a loop whose only exit is a noreturn arm post-dominates
// nothing and leaves no block control-dependent: rule 14's "No live exit", its arm under each trip's exit flag).
bool quantumLoopOf(const Loop *L, ArrayRef<const cq::Specialization *> specs, const cq::TaintInfo &T) {
  if (!L)
    return false;
  L = L->getOutermostLoop();
  for (const BasicBlock *X : L->blocks())
    for (const cq::Specialization *S : specs) {
      if (T.controlTainted(X, *S))
        return true;
      if (!L->isLoopExiting(X))
        continue;
      const Instruction *t = X->getTerminator();
      if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional() && T.isQuantum(br->getCondition(), *S))
        return true;
      if (auto *sw = dyn_cast<SwitchInst>(t); sw && T.isQuantum(sw->getCondition(), *S))
        return true;
    }
  return false;
}

// The block lies in such a loop, or in the exit arm (its noreturn arm included, rule 14) of a loop every clone runs on a
// quantum condition: there no clone has the arm on a classical path (noexit.O1.ll's na_only). An arm that some clone
// reaches classically (a table clone's quantum formals aside) comes back, as before.
bool quantumLoop(BasicBlock *BB, const LoopInfo &LI, ArrayRef<const cq::Specialization *> specs, const cq::TaintInfo &T) {
  if (quantumLoopOf(LI.getLoopFor(BB), specs, T))
    return true;
  if (specs.empty())
    return false;
  for (Loop *L : LI.getLoopsInPreorder()) {
    cq::loops::exits::Unit u = cq::loops::exits::unitOf(*L);
    if ((is_contained(u.arm, BB) || is_contained(u.abort, BB) || is_contained(u.tail, BB)) &&
        all_of(specs, [&](const cq::Specialization *S) { return quantumLoopOf(L, {S}, T); }))
      return true;
  }
  return false;
}

// Rule 16: "The `unreachable` after an unconditional `noreturn` call is a return of zero-valued results", only under a
// quantum predicate (owner ruling 2026-11-14 Q1, cq-9tang): a noreturn call on a classical path of a _ctl clone is abort_i1
// of the clone's predicate, and where it reads 0 the program goes on, so the path returns instead of running into
// `unreachable`. So does a call through an address rail (rule 19's dispatch over the candidates' _ctl clones). The body is
// shared by every specialization: what ends there in another one (a host call, an entry under a true seed) gets its
// `unreachable` back after the construction (endAtNoreturn). Runs before unifyReturns. A loop that any clone runs on a
// quantum condition keeps its arm (rule 14's abort arm under the trip's flag), and longjmp and a thread's exit are rule
// 24's. A noreturn-attributed F (cq-zfrb item 2) is rewritten the same way and comes back too: it loses the attribute
// (returnAfterCalls then rewrites the `unreachable` after each call of it; endAtNoreturn gives it back where it ends).
bool returnFromClassicalAborts(Function &F, const cq::TaintInfo &T, const LoopInfo &LI) {
  bool changed = false;
  SmallVector<const cq::Specialization *, 4> specs;
  for (const cq::Specialization &S : T.specializations())
    if (S.F == &F)
      specs.push_back(&S);
  for (BasicBlock &BB : F) {
    auto *U = dyn_cast<UnreachableInst>(BB.getTerminator());
    auto *CB = U ? dyn_cast_or_null<CallBase>(U->getPrevNonDebugInstruction()) : nullptr;
    if (!CB || CB->isInlineAsm() || !CB->doesNotReturn() || CB->hasFnAttr(Attribute::ReturnsTwice))
      continue;
    const Function *G = CB->getCalledFunction();
    bool indirect = !isa<Function>(CB->getCalledOperand()->stripPointerCasts());
    if (!G && !indirect)
      continue;
    if (G) {
      StringRef n = G->getName();
      if (n == "longjmp" || n == "_longjmp" || n == "siglongjmp" || n == "__longjmp_chk" || n == "pthread_exit" ||
          n == "thrd_exit")
        continue;
    }
    // A call through a pointer is rule 19's dispatch over table clones in every clone (calls::lowerIndirect), and a
    // table clone comes back (its noreturn exits are effect entries: the table clone is called after an event), so
    // every clone that reaches the call classically goes on after it (cq-W2 item 1, R3/p11.c).
    // Owner ruling 2026-11-14 Q1 (cq-9tang): only under a quantum predicate: a _ctl clone's (abort_i1 of it), or a call
    // through an address rail (rule 19's dispatch calls each candidate's _ctl clone under its quantum flag). An entry under
    // a true seed (an event before it, a rail argument) ends the shot at abort_i1 (endAtNoreturn).
    if (none_of(specs, [&](const cq::Specialization *S) {
          return !T.controlTainted(&BB, *S) && (S->ctl || (indirect && T.isQuantum(CB->getCalledOperand(), *S)));
        }))
      continue;
    if (quantumLoop(&BB, LI, specs, T))
      continue;
    Type *RT = F.getReturnType();
    ReturnInst::Create(F.getContext(), RT->isVoidTy() ? nullptr : Constant::getNullValue(RT), U->getIterator());
    U->eraseFromParent();
    changed = true;
  }
  if (changed) {
    for (Attribute::AttrKind A : {Attribute::Range, Attribute::NonNull, Attribute::Dereferenceable, Attribute::DereferenceableOrNull})
      F.removeRetAttr(A);   // the zero result of the new path
    F.removeFnAttr(Attribute::NoReturn);
  }
  return changed;
}

// CR rule 16 noreturn (cq-euke1): a function with no return and a dead end (`unreachable`) under a quantum predicate in
// some specialization, outside a loop some clone runs on a quantum condition (rule 14's arm, the loop module's): the spine
// ends the walk at such an end with the zero-valued return (Construct.cpp emitTerminator), so the function comes back.
bool returnsAtQuantumDeadEnd(Function &F, const cq::TaintInfo &T, const LoopInfo &LI) {
  if (any_of(F, [](const BasicBlock &BB) { return isa<ReturnInst>(BB.getTerminator()); }))
    return false;
  SmallVector<const cq::Specialization *, 4> specs;
  for (const cq::Specialization &S : T.specializations())
    if (S.F == &F)
      specs.push_back(&S);
  for (BasicBlock &BB : F)
    if (isa<UnreachableInst>(BB.getTerminator()) && !quantumLoop(&BB, LI, specs, T) &&
        any_of(specs, [&](const cq::Specialization *S) { return T.controlTainted(&BB, *S); }))
      return true;
  return false;
}

// Rule 16 (cq-zfrb item 2, ruling Q7): a call of a function returnFromClassicalAborts made come back (it lost `noreturn`) is
// a noreturn call lowered to abort_i1 inside the callee: where the callee's flag reads 0 the caller goes on, so "the
// `unreachable` after an unconditional `noreturn` call is a return of zero-valued results" in the caller as well, on a
// path no clone of the caller runs under a quantum predicate (there the arm is the predicate's, rules 9 and 16) and outside
// a loop some clone runs on a quantum condition (rule 14's arm). A caller that loses its last `unreachable` that way and was
// `noreturn` itself loses the attribute, and its callers follow (a worklist over the module, in module order). Returns the
// functions it changed.
SmallVector<Function *, 4> returnAfterCalls(Module &M, SmallVector<Function *, 4> work, const cq::TaintInfo &T,
                                            FunctionAnalysisManager &FAM) {
  SmallVector<Function *, 4> changedFns;
  SmallPtrSet<Function *, 8> done(work.begin(), work.end());
  while (!work.empty()) {
    SmallPtrSet<Function *, 8> back(work.begin(), work.end());
    work.clear();
    for (Function &G : M) {
      if (G.isDeclaration())
        continue;
      SmallVector<const cq::Specialization *, 4> specs;
      for (const cq::Specialization &S : T.specializations())
        if (S.F == &G)
          specs.push_back(&S);
      SmallVector<CallBase *, 4> sites;
      for (BasicBlock &BB : G)
        for (Instruction &I : BB)
          if (auto *CB = dyn_cast<CallBase>(&I))
            if (auto *Callee = dyn_cast<Function>(CB->getCalledOperand()->stripPointerCasts()); Callee && back.count(Callee))
              sites.push_back(CB);
      if (sites.empty())
        continue;
      const LoopInfo &LI = FAM.getResult<LoopAnalysis>(G);
      bool changed = false;
      for (CallBase *CB : sites) {
        CB->removeFnAttr(Attribute::NoReturn);
        auto *U = dyn_cast_or_null<UnreachableInst>(CB->getNextNonDebugInstruction());
        if (!U)
          continue;
        BasicBlock *BB = CB->getParent();
        if (!specs.empty() && all_of(specs, [&](const cq::Specialization *S) { return T.controlTainted(BB, *S); }))
          continue;
        if (quantumLoop(BB, LI, specs, T))
          continue;
        Type *RT = G.getReturnType();
        ReturnInst::Create(G.getContext(), RT->isVoidTy() ? nullptr : Constant::getNullValue(RT), U->getIterator());
        U->eraseFromParent();
        changed = true;
      }
      if (!changed)
        continue;
      for (Attribute::AttrKind A : {Attribute::Range, Attribute::NonNull, Attribute::Dereferenceable, Attribute::DereferenceableOrNull})
        G.removeRetAttr(A);
      FAM.invalidate(G, PreservedAnalyses::none());
      changedFns.push_back(&G);
      if (G.doesNotReturn()) {
        G.removeFnAttr(Attribute::NoReturn);
        if (done.insert(&G).second)
          work.push_back(&G);
      }
    }
  }
  return changedFns;
}

// Owner rulings 2026-11-14 (scope of Q7; Q1, cq-9tang; CR rule 16 noreturn, ABI 1.11). returnFromClassicalAborts and
// returnAfterCalls rewrite the body every specialization of a function is built from, so that a _ctl clone, whose noreturn
// call is abort_i1 of a quantum predicate, comes back (the zero-valued return, only under a quantum predicate). Every other
// output function ends where its program ends:
// - after a call of a `noreturn` callee: the ordinary host call (an own symbol no event precedes inside the lowered code,
//   which stays as it is) or a function that itself ends below;
// - after cqrt_abort_i1 of a fresh alloc_i1(true) seed: classical-valued 1, abort_i1 does not return and the shot ends
//   there (Q1): the entry under the true seed of rule 16's noreturn bullet, rule 14's loop with no exit edge.
// The rest of the block is `unreachable` and the dead blocks go. A function with no return left after such a cut gets
// `noreturn` back when it had it in the input (`wasNoreturn`, by name: the own symbol keeps it), and otherwise only where a
// call of it goes on after the call; its call sites then get it too, so its callers end after the call in turn (iterated).
// No attribute is added where nothing needs it (a table clone reached through the clone table alone): the module's
// attribute groups, and with them the text of every function left as it is, stay as they were.
bool trueSeed(const Value *v) {
  auto *A = dyn_cast<CallBase>(v);
  const Function *G = A ? A->getCalledFunction() : nullptr;
  if (!G || G->getName() != "cqrt_alloc_i1" || A->arg_size() != 1)
    return false;
  auto *c = dyn_cast<ConstantInt>(A->getArgOperand(0));
  if (!c || !c->isOne())
    return false;
  // A seed is never written (rule 7): it is read as a predicate (tape) or an abort flag only.
  return all_of(A->users(), [](const User *U) {
    auto *CB = dyn_cast<CallBase>(U);
    const Function *H = CB ? CB->getCalledFunction() : nullptr;
    return H && (H->getName().starts_with("cqrt_tape_") || H->getName() == "cqrt_abort_i1");
  });
}

void endAtNoreturn(Module &M, const std::set<std::string> &wasNoreturn) {
  bool again = true;
  while (again) {
    again = false;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      SmallVector<Instruction *, 4> cuts;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB) {
          auto *CB = dyn_cast<CallBase>(&I);
          if (!CB || CB->isInlineAsm() || CB->hasFnAttr(Attribute::ReturnsTwice) || isa<UnreachableInst>(CB->getNextNode()))
            continue;
          Function *G = CB->getCalledFunction();
          if (!G)
            continue;
          if (G->doesNotReturn() || (G->getName() == "cqrt_abort_i1" && CB->arg_size() == 1 && trueSeed(CB->getArgOperand(0)))) {
            cuts.push_back(CB->getNextNode());
            break;   // the first cut of a block erases the rest of it, a later noreturn call too (_glp_dlsym: two asserts)
          }
        }
      if (cuts.empty())
        continue;
      for (Instruction *I : cuts)
        changeToUnreachable(I);
      removeUnreachableBlocks(F);
      bool returns = any_of(F, [](BasicBlock &BB) { return isa<ReturnInst>(BB.getTerminator()); });
      if (returns || F.doesNotReturn())
        continue;
      bool goesOn = any_of(F.users(), [&](const User *U) {
        auto *CB = dyn_cast<CallBase>(U);
        return CB && CB->getCalledFunction() == &F && !isa<UnreachableInst>(CB->getNextNode());
      });
      if (!wasNoreturn.count(F.getName().str()) && !goesOn)
        continue;
      F.addFnAttr(Attribute::NoReturn);
      for (User *U : F.users())
        if (auto *CB = dyn_cast<CallBase>(U); CB && CB->getCalledFunction() == &F)
          CB->addFnAttr(Attribute::NoReturn);
      again = true;
    }
  }
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

// CR rule 14 "Irreducible control flow" (r7, GMP __gmpn_hgcd2_jacobi): fix-irreducible's guard block is a loop header entered
// by a back edge from every block that went to one of the cycle's entries, so the natural loop it makes has several latches.
// Its back edges meet at ONE block first (LoopSimplify's unique back-edge block, the same kind of rewrite as fix-irreducible
// and unifyReturns): a phi of it per header phi carries the latches' incomings, and it branches to the header. A trip then
// ends on one back edge (rule 14's "same chain"). Run on the functions fix-irreducible changed, before the final taint.
bool oneBackEdge(Function &F) {
  bool any = false;
  for (bool changed = true; changed;) {
    changed = false;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (Loop *L : LI.getLoopsInPreorder()) {
      SmallVector<BasicBlock *, 4> latches;
      L->getLoopLatches(latches);
      if (latches.size() < 2)
        continue;
      BasicBlock *H = L->getHeader();
      BasicBlock *B = BasicBlock::Create(F.getContext(), H->getName() + ".cq.latch", &F, latches.back()->getNextNode());
      // One incoming per edge (a latch whose terminator names H twice enters B twice).
      SmallVector<BasicBlock *, 8> edges;
      for (BasicBlock *p : predecessors(H))
        if (L->contains(p))
          edges.push_back(p);
      for (PHINode &P : H->phis()) {
        PHINode *N = PHINode::Create(P.getType(), edges.size(), P.getName() + ".be", B);
        for (BasicBlock *p : edges)
          N->addIncoming(P.getIncomingValueForBlock(p), p);
        P.removeIncomingValueIf([&](unsigned i) { return L->contains(P.getIncomingBlock(i)); }, false);
        P.addIncoming(N, B);
      }
      BranchInst::Create(H, B);
      for (BasicBlock *p : latches)
        p->getTerminator()->replaceSuccessorWith(H, B);
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

// CR rules 2, 14 (owner, cq-oiclq): one cq_measure is one measurement. A measurement in the exit arm of a loop with a quantum exit, the
// loop also leaving past it (a `return` in the loop), runs once after the trips, on the arm's value merged across them, unconditionally:
// the paths past it are measured too, rule 2's deviation. The same kind of rewrite as unifySubLoopExits: the edges from the unit past the
// measurement meet it at a hub, whose phis carry what their targets and later readers take (poison where a value does not reach), and
// the hub then branches on which edge came in. The hub is the loop's continuation, so the measurement is no part of a trip. Inside an outer
// loop the same holds for one of its trips: once per outer trip, after the inner loop's trips (owner, cq-2z29a).
bool measureAfterTrips(Function &F, const cq::TaintInfo &T) {
  // A hub phi this rewrite made has no taint answer: it is asked through the value it stands for (cq-q7u9y: a second
  // measurement of the arm reads a value the first rewrite routed through the hub).
  DenseMap<const Value *, const Value *> origin;
  auto quantum = [&](const Value *v) {
    for (auto it = origin.find(v); it != origin.end(); it = origin.find(v))
      v = it->second;
    return any_of(T.specializations(), [&](const cq::Specialization &S) { return S.F == &F && T.isQuantum(v, S); });
  };
  LLVMContext &C = F.getContext();
  bool any = false;
  SmallPtrSet<CallInst *, 4> done;   // its hub phi has no taint answer yet
  auto measureOf = [&](Instruction &I) -> CallInst * {
    auto *c = dyn_cast<CallInst>(&I);
    Function *g = c ? c->getCalledFunction() : nullptr;
    return g && g->isDeclaration() && g->getName().starts_with("cq_measure_") && c->arg_size() == 1 ? c : nullptr;
  };
  // Within one trip of every loop around `at`: a back edge to one of their headers starts another trip, another measurement.
  auto reachable = [](BasicBlock *from, Loop *at) {
    SmallPtrSet<BasicBlock *, 32> seen{from};
    SmallVector<BasicBlock *, 16> work{from};
    while (!work.empty())
      for (BasicBlock *x : successors(work.pop_back_val())) {
        bool backEdge = false;
        for (Loop *l = at; l && !backEdge; l = l->getParentLoop())
          backEdge = l->getHeader() == x;
        if (!backEdge && seen.insert(x).second)
          work.push_back(x);
      }
    return seen;
  };
  for (bool changed = true; changed;) {
    changed = false;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (BasicBlock &BB : F) {
      Loop *Host = LI.getLoopFor(&BB);   // a measurement in an outer loop's body stays that loop's: once per its trips
      CallInst *cm = nullptr;
      for (Instruction &I : BB)
        if (CallInst *c = measureOf(I); c && !cm && !done.count(c) && quantum(c->getArgOperand(0)))
          cm = c;
      if (!cm)
        continue;
      // The loop beside the block whose exit arm holds it, by a quantum exit.
      Loop *L = nullptr;
      cq::loops::exits::Unit U;
      SmallVector<Loop *, 4> siblings(Host ? Host->begin() : LI.begin(), Host ? Host->end() : LI.end());
      for (Loop *l : siblings) {
        cq::loops::exits::Unit u = cq::loops::exits::unitOf(*l);
        if (!is_contained(u.arm, &BB))
          continue;
        SmallVector<BasicBlock *, 4> exiting;
        l->getExitingBlocks(exiting);
        if (any_of(exiting, [&](BasicBlock *e) {
              Instruction *t = e->getTerminator();
              auto *br = dyn_cast<BranchInst>(t);
              auto *sw = dyn_cast<SwitchInst>(t);
              return (br && br->isConditional() && quantum(br->getCondition())) || (sw && quantum(sw->getCondition()));
            })) {
          L = l;
          U = std::move(u);
          break;
        }
      }
      if (!L)
        continue;
      // The edges from the unit past the block, in the function's order.
      SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> edges;
      {
        SmallPtrSet<BasicBlock *, 32> toM;
        for (BasicBlock &b : F)
          if (reachable(&b, Host).count(&BB))
            toM.insert(&b);
        for (BasicBlock &u : F) {
          if (&u == &BB || !U.contains(*L, &u) || !toM.count(&u))
            continue;   // the block's own edges follow the measurement
          for (BasicBlock *x : successors(&u))
            if (!toM.count(x) && !is_contained(U.dead, x) && !is_contained(U.abort, x) &&
                !is_contained(edges, std::make_pair(&u, x)))
              edges.push_back({&u, x});
        }
      }
      if (edges.empty())
        continue;
      // Dominance before any edge moves: per edge, whether a value reaches it.
      DominatorTree Old(F);
      Instruction *firstAfter = cm->getNextNode();
      BasicBlock *rest = BB.splitBasicBlock(firstAfter, BB.getName() + ".cq.rest");
      BasicBlock *E = BasicBlock::Create(C, "cq.measure", &F);
      cm->moveBefore(*E, E->end());
      BB.getTerminator()->setSuccessor(0, E);
      SmallVector<BasicBlock *, 4> from;
      SmallVector<BasicBlock *, 4> to;
      from.push_back(&BB);
      to.push_back(rest);
      for (auto [u, x] : edges) {
        // A block of its own per edge: u may leave for the measurement too.
        BasicBlock *f = BasicBlock::Create(C, "cq.past", &F);
        BranchInst::Create(E, f);
        Instruction *t = u->getTerminator();
        for (unsigned i = 0; i < t->getNumSuccessors(); ++i)
          if (t->getSuccessor(i) == x)
            t->setSuccessor(i, f);
        from.push_back(f);
        to.push_back(x);
      }
      SmallVector<BasicBlock *, 4> targets;
      for (BasicBlock *x : to)
        if (!is_contained(targets, x))
          targets.push_back(x);
      // The measured value: the arm's, poison on the paths past it (any value refines it, rule 9).
      {
        Value *arg = cm->getArgOperand(0);
        PHINode *h = PHINode::Create(arg->getType(), from.size(), arg->getName() + ".hub");
        h->insertBefore(cm);
        origin[h] = arg;
        for (size_t e = 0; e < from.size(); ++e)
          h->addIncoming(e ? static_cast<Value *>(PoisonValue::get(arg->getType())) : arg, from[e]);
        cm->setArgOperand(0, h);
      }
      // The targets' phis: one hub phi each.
      for (BasicBlock *x : targets)
        for (PHINode &P : x->phis()) {
          PHINode *h = PHINode::Create(P.getType(), from.size(), P.getName() + ".hub");
          h->insertBefore(cm);
          origin[h] = &P;
          for (size_t e = 0; e < from.size(); ++e)
            h->addIncoming(e && to[e] == x ? P.getIncomingValueForBlock(edges[e - 1].first) : PoisonValue::get(P.getType()), from[e]);
          for (size_t e = 1; e < from.size(); ++e)
            if (to[e] == x)
              while (P.getBasicBlockIndex(edges[e - 1].first) >= 0)
                P.removeIncomingValue(edges[e - 1].first, /*DeletePHIIfEmpty=*/false);
          P.addIncoming(h, E);
        }
      // Which edge came in.
      if (targets.size() == 2) {
        PHINode *w = PHINode::Create(Type::getInt1Ty(C), from.size(), "cq.which");
        w->insertBefore(cm);
        for (size_t e = 0; e < from.size(); ++e)
          w->addIncoming(ConstantInt::getBool(C, to[e] == targets[0]), from[e]);
        BranchInst::Create(targets[0], targets[1], w, E);
      } else {
        PHINode *w = PHINode::Create(Type::getInt32Ty(C), from.size(), "cq.which");
        w->insertBefore(cm);
        for (size_t e = 0; e < from.size(); ++e)
          w->addIncoming(ConstantInt::get(Type::getInt32Ty(C), find(targets, to[e]) - targets.begin()), from[e]);
        SwitchInst *sw = SwitchInst::Create(w, targets.back(), targets.size() - 1, E);
        for (size_t i = 0; i + 1 < targets.size(); ++i)
          sw->addCase(ConstantInt::get(Type::getInt32Ty(C), i), targets[i]);
      }
      // Later readers: a value that no longer dominates a use is read through a hub phi.
      DominatorTree New(F);
      SmallVector<Instruction *, 16> insts;
      for (BasicBlock &b : F)
        for (Instruction &I : b)
          if (!I.getType()->isVoidTy())
            insts.push_back(&I);
      for (Instruction *I : insts) {
        PHINode *h = nullptr;
        for (Use &us : make_early_inc_range(I->uses())) {
          auto *ui = dyn_cast<Instruction>(us.getUser());
          if (!ui || !New.isReachableFromEntry(ui->getParent()) || New.dominates(I, us))
            continue;
          if (!h) {
            h = PHINode::Create(I->getType(), from.size(), I->getName() + ".hub");
            h->insertBefore(&E->front());
            origin[h] = I;
            for (size_t e = 0; e < from.size(); ++e) {
              BasicBlock *src = e ? edges[e - 1].first : &BB;
              bool reach = I->getParent() == src ? true : Old.dominates(I->getParent(), src);
              h->addIncoming(reach ? static_cast<Value *>(I) : PoisonValue::get(I->getType()), from[e]);
            }
          }
          us.set(h);
        }
      }
      done.insert(cm);
      cm->setMetadata("cq.after.trips", MDNode::get(C, {}));
      changed = any = true;
      break;   // the loops changed: LoopInfo again
    }
  }
  return any;
}

// CR rules 3, 14 (owner, cq-os2bx, 2026-11-09 Q1): code after a loop runs once, after the loop. A loop with a quantum exit whose
// exit arm (Exits.h: the blocks between its live exits and their common post-dominator) holds a call or a write to memory never
// runs that arm per trip: each trip would leave its own kept store or tape entry. Its live exit edges meet at ONE hub, the same
// kind of rewrite as unifySubLoopExits: phis of the hub carry what the targets' phis and the later readers take (poison on an
// edge a value does not reach), and the hub branches on which edge came in. The loop then has one live exit; the hub's phis are
// values defined by the loop and read after it, rails (rule 3): the select chain over the exit flags, as 121's quantum_strlen
// builds r_i = select(e_i, i, r_(i-1)). The arm is lowered once, after the loop, under the flags of the hub's branch. An arm that
// keeps nothing (121's quantum_strcmp: a bus load) stays per trip.
bool armOnceAfterTrips(Function &F, const cq::TaintInfo &T) {
  auto quantum = [&](const Value *v) {
    return any_of(T.specializations(), [&](const cq::Specialization &S) { return S.F == &F && T.isQuantum(v, S); });
  };
  // Does I leave something kept per execution: a call, or a write to memory (a bus store, a memory intrinsic, an atomic)?
  auto keeps = [](const Instruction &I) {
    if (auto *II = dyn_cast<IntrinsicInst>(&I)) {
      if (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II) || isa<AssumeInst>(II) ||
          II->getIntrinsicID() == Intrinsic::experimental_noalias_scope_decl)
        return false;
      return II->mayWriteToMemory();
    }
    return isa<CallBase>(I) || I.mayWriteToMemory();
  };
  LLVMContext &C = F.getContext();
  bool any = false;
  SmallPtrSet<const Value *, 8> fresh;   // values this rewrite made: no taint answer for them yet
  for (bool changed = true; changed;) {
    changed = false;
    DominatorTree Old(F);
    LoopInfo LI(Old);
    for (Loop *L : LI.getLoopsInPreorder()) {
      cq::loops::exits::Unit U = cq::loops::exits::unitOf(*L);
      if (!U.multi() || !U.cont)
        continue;
      if (none_of(U.arm, [&](BasicBlock *b) { return any_of(*b, keeps); }))
        continue;   // an arm that keeps nothing may run per trip (121)
      SmallVector<BasicBlock *, 4> exiting;
      L->getExitingBlocks(exiting);
      if (none_of(exiting, [&](BasicBlock *e) {
            Instruction *t = e->getTerminator();
            auto *br = dyn_cast<BranchInst>(t);
            auto *sw = dyn_cast<SwitchInst>(t);
            Value *c = br && br->isConditional() ? br->getCondition() : sw ? sw->getCondition() : nullptr;
            return c && !fresh.count(c) && quantum(c);
          }))
        continue;   // no quantum exit: the loop's exits are classical branches, its arm runs once already
      SmallVector<BasicBlock *, 4> targets(U.live.begin(), U.live.end());
      // The live exit edges, one (from, to) per pair, in the loop's block order.
      SmallVector<std::pair<BasicBlock *, BasicBlock *>, 4> edges;
      for (BasicBlock *u : L->blocks())
        for (BasicBlock *x : successors(u))
          if (is_contained(targets, x) && !is_contained(edges, std::make_pair(u, x)))
            edges.push_back({u, x});
      // A target also entered from outside the loop (a tail, Exits.h) keeps that edge: the walker joins it with the hub's.
      BasicBlock *E = BasicBlock::Create(C, "cq.exits", &F);
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
      // The targets' phis: one hub phi each.
      for (BasicBlock *x : targets)
        for (PHINode &P : x->phis()) {
          PHINode *h = PHINode::Create(P.getType(), edges.size(), P.getName() + ".hub");
          h->insertInto(E, E->end());
          fresh.insert(h);
          for (size_t e = 0; e < edges.size(); ++e)
            h->addIncoming(edges[e].second == x ? P.getIncomingValueForBlock(edges[e].first) : PoisonValue::get(P.getType()),
                           from[e]);
          for (auto &[u, y] : edges)
            if (y == x)
              while (P.getBasicBlockIndex(u) >= 0)
                P.removeIncomingValue(u, /*DeletePHIIfEmpty=*/false);
          P.addIncoming(h, E);
        }
      // Which edge came in: a branch for two targets, a switch for more.
      PHINode *w;
      if (targets.size() == 2) {
        w = PHINode::Create(Type::getInt1Ty(C), edges.size(), "cq.which");
        w->insertInto(E, E->end());
        for (size_t e = 0; e < edges.size(); ++e)
          w->addIncoming(ConstantInt::getBool(C, edges[e].second == targets[0]), from[e]);
        BranchInst::Create(targets[0], targets[1], w, E);
      } else {
        w = PHINode::Create(Type::getInt32Ty(C), edges.size(), "cq.which");
        w->insertInto(E, E->end());
        for (size_t e = 0; e < edges.size(); ++e)
          w->addIncoming(ConstantInt::get(Type::getInt32Ty(C), find(targets, edges[e].second) - targets.begin()), from[e]);
        SwitchInst *sw = SwitchInst::Create(w, targets.back(), targets.size() - 1, E);
        for (size_t i = 0; i + 1 < targets.size(); ++i)
          sw->addCase(ConstantInt::get(Type::getInt32Ty(C), i), targets[i]);
      }
      fresh.insert(w);
      // Later readers of the loop's values: every read the hub dominates goes through a hub phi, so that the loop's value
      // read after it is a phi of its continuation (the exiting trip's value on each edge, rule 3), also where the value
      // still dominates the read. A read the hub does not dominate (a noreturn arm's) keeps its path out of the loop.
      DominatorTree New(F);
      SmallVector<Instruction *, 16> insts;
      for (BasicBlock *b : L->blocks())
        for (Instruction &I : *b)
          if (!I.getType()->isVoidTy())
            insts.push_back(&I);
      for (Instruction *I : insts) {
        PHINode *h = nullptr;
        for (Use &us : make_early_inc_range(I->uses())) {
          auto *ui = dyn_cast<Instruction>(us.getUser());
          if (!ui || ui == h || ui->getParent() == E || !New.isReachableFromEntry(ui->getParent()))
            continue;
          auto *uphi = dyn_cast<PHINode>(ui);
          BasicBlock *at = uphi ? uphi->getIncomingBlock(us) : ui->getParent();
          if (L->contains(at) || !New.dominates(E, at))
            continue;
          if (!h) {
            h = PHINode::Create(I->getType(), edges.size(), I->getName() + ".hub");
            h->insertBefore(&E->front());
            fresh.insert(h);
            for (size_t e = 0; e < edges.size(); ++e)
              h->addIncoming(Old.dominates(I->getParent(), edges[e].first) ? static_cast<Value *>(I)
                                                                          : PoisonValue::get(I->getType()),
                             from[e]);
          }
          us.set(h);
        }
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

// cq-zd8jo: llvm.load.relative(p, off), which clang -O1's RelLookupTableConverter emits for a switch turned into a
// table of pointers (PIC), is by definition (LangRef) p + sext(load i32 from p + off). In a tainted function it
// becomes exactly that, so the ordinary load (rules 20 to 22) and address arithmetic lower it, a quantum index included.
bool rewriteLoadRelative(Function &F) {
  SmallVector<IntrinsicInst *, 4> work;
  for (Instruction &I : instructions(F))
    if (auto *II = dyn_cast<IntrinsicInst>(&I); II && II->getIntrinsicID() == Intrinsic::load_relative)
      work.push_back(II);
  for (IntrinsicInst *II : work) {
    IRBuilder<> B(II);
    Value *p = II->getArgOperand(0);
    Value *rel = B.CreateAlignedLoad(B.getInt32Ty(), B.CreateGEP(B.getInt8Ty(), p, II->getArgOperand(1)), Align(4));
    II->replaceAllUsesWith(B.CreateGEP(B.getInt8Ty(), p, B.CreateSExt(rel, B.getInt64Ty())));
    II->eraseFromParent();
  }
  return !work.empty();
}

// cq-zd8jo, cq-p45s (CR rule 26: an SSA aggregate is one rail per scalar field; extractvalue/insertvalue and their vector
// forms are representation changes): in a tainted function an aggregate or vector phi becomes one phi per field, each
// incoming extracted at the end of its block, and the value rebuilt after the phis. The loop constructions then carry
// and join scalars only (gsl_complex through a K-loop: GSL's complex_LU_det, spmatrix_complex_float_get).
bool scalarizeAggregatePhis(Function &F) {
  SmallVector<PHINode *, 4> work;
  for (BasicBlock &BB : F)
    for (PHINode &P : BB.phis())
      if (P.getType()->isAggregateType() || P.getType()->isVectorTy())
        work.push_back(&P);
  bool changed = !work.empty();
  while (!work.empty()) {
    PHINode *P = work.pop_back_val();
    Type *ty = P->getType();
    auto *vt = dyn_cast<FixedVectorType>(ty);
    unsigned n = vt ? vt->getNumElements() : isa<StructType>(ty) ? ty->getStructNumElements() : ty->getArrayNumElements();
    IRBuilder<> R(P->getParent(), P->getParent()->getFirstInsertionPt());
    Value *whole = PoisonValue::get(ty);
    for (unsigned k = 0; k < n; ++k) {
      PHINode *f = PHINode::Create(vt ? vt->getElementType() : GetElementPtrInst::getTypeAtIndex(ty, k),
                                   P->getNumIncomingValues(), P->getName() + ".f" + Twine(k), P->getIterator());
      // A block listed twice (a switch's cases into one block) takes one extract: LLVM requires one value per block.
      SmallDenseMap<BasicBlock *, Value *, 4> fromBlock;
      for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
        BasicBlock *u = P->getIncomingBlock(i);
        Value *&e = fromBlock[u];
        if (!e) {
          IRBuilder<> B(u->getTerminator());
          Value *v = P->getIncomingValue(i);
          e = vt ? B.CreateExtractElement(v, uint64_t(k)) : B.CreateExtractValue(v, {k});
        }
        f->addIncoming(e, u);
      }
      whole = vt ? R.CreateInsertElement(whole, f, uint64_t(k)) : R.CreateInsertValue(whole, f, {k});
      if (f->getType()->isAggregateType() || f->getType()->isVectorTy())
        work.push_back(f);   // a nested aggregate: its fields in turn
    }
    P->replaceAllUsesWith(whole);
    P->eraseFromParent();
  }
  return changed;
}

// -cq-no-output (owner 2026-11-19): a library lowered for all-quantum arguments builds every error path's message as
// circuit (GSL's gsl_error and cblas_xerbla: printf's formatting under each parameter check). With the flag, a call of a
// stream-output function of <stdio.h>/<wchar.h> that this module only declares is not made: its result is the function's
// error value, what the C program gets on a stream that cannot be written. sprintf and snprintf write memory the program
// reads and are not output. Never used to build the C library itself, whose module defines these functions.
bool dropStreamOutput(Function &F) {
  static const char *const names[] = {"printf",  "fprintf",  "vprintf",  "vfprintf",  "wprintf", "fwprintf", "vwprintf",
                                      "vfwprintf", "puts",   "fputs",    "fputws",    "putc",    "fputc",    "putchar",
                                      "putwc",   "fputwc",   "putwchar", "fwrite",    "perror"};
  SmallVector<CallBase *, 8> work;
  for (Instruction &I : instructions(F))
    if (auto *CB = dyn_cast<CallBase>(&I))
      if (const Function *G = CB->getCalledFunction(); G && G->isDeclaration() && !isa<InvokeInst>(CB)) {
        StringRef n = G->getName();
        if (n.consume_front("\01"))   // an asm label is the object symbol: Mach-O's leading underscore (\01_fputs)
          n.consume_front("_");
        if (is_contained(names, n))
          work.push_back(CB);
      }
  for (CallBase *CB : work) {
    Type *T = CB->getType();
    if (T->isIntegerTy())   // fwrite: no item written; the others: EOF, WEOF or a negative count
      CB->replaceAllUsesWith(CB->getCalledFunction()->getName().ends_with("fwrite") ? ConstantInt::get(T, 0)
                                                                                     : ConstantInt::getAllOnesValue(T));
    else if (!T->isVoidTy())
      continue;
    CB->eraseFromParent();
  }
  return !work.empty();
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

// cq-mjw9 (NORTHSTAR principle 1: classical code is never rewritten; CLAUDE.md pipeline: fix-irreducible on the tainted
// functions only). Step 2's CFG rewrites (fix-irreducible and the ones after it) serve the constructions, which read a
// tainted function's body to build its clones. A tainted function whose own symbol stays the classical original (it has
// no entry specialization: construct rewrites only an entry in place) keeps its body as the input had it: the body is
// copied before step 2 into a module of its own, where every global it names is a declaration of the same name and
// type (so nothing in the lowered module gains a user), and copied back after the constructions.
struct PristineBodies {
  std::unique_ptr<Module> Mod;
  ValueToValueMapTy toCopy;                                    // the lowered module's globals -> the declarations
  std::vector<std::pair<WeakTrackingVH, GlobalValue *>> back;  // and back (tracking a replacement of the global)
  struct Saved {
    WeakVH F;                                                  // the function in the lowered module
    Function *copy;
    std::vector<std::pair<WeakVH, BasicBlock *>> addressed;    // its blocks whose address is taken -> their copies
  };
  std::vector<Saved> saved;

  GlobalValue *declOf(GlobalValue *G) {
    if (auto it = toCopy.find(G); it != toCopy.end())
      return cast<GlobalValue>(static_cast<Value *>(it->second));
    GlobalValue *D;
    if (auto *F = dyn_cast<Function>(G))
      D = Function::Create(F->getFunctionType(), GlobalValue::ExternalLinkage, F->getName(), Mod.get());
    else
      D = new GlobalVariable(*Mod, G->getValueType(), false, GlobalValue::ExternalLinkage, nullptr, G->getName());
    toCopy[G] = D;
    back.push_back({WeakTrackingVH(G), D});
    return D;
  }
  void globalsOf(Value *V, SmallPtrSetImpl<Constant *> &seen) {
    auto *C = dyn_cast<Constant>(V);
    if (!C || !seen.insert(C).second)
      return;
    if (auto *G = dyn_cast<GlobalValue>(C)) {
      declOf(G);
      return;
    }
    for (Value *op : C->operands())
      globalsOf(op, seen);
  }

  void save(Module &M, ArrayRef<Function *> Fs) {
    Mod = std::make_unique<Module>("cq.pristine", M.getContext());
    SmallPtrSet<Constant *, 32> seen;
    for (Function *F : Fs) {
      declOf(F);
      for (Instruction &I : instructions(*F))
        for (Value *op : I.operands())
          globalsOf(op, seen);
      if (F->hasPersonalityFn())
        globalsOf(F->getPersonalityFn(), seen);
    }
    for (Function *F : Fs) {
      auto *C = cast<Function>(static_cast<Value *>(toCopy[F]));
      ValueToValueMapTy VM;
      for (auto kv : toCopy)
        VM[kv.first] = kv.second;
      for (unsigned i = 0; i < F->arg_size(); ++i)
        VM[F->getArg(i)] = C->getArg(i);
      SmallVector<ReturnInst *, 4> rets;
      CloneFunctionInto(C, F, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
      Saved s{WeakVH(F), C, {}};
      for (BasicBlock &BB : *F)
        if (BB.hasAddressTaken())
          s.addressed.push_back({WeakVH(&BB), cast<BasicBlock>(static_cast<Value *>(VM[&BB]))});
      saved.push_back(std::move(s));
    }
  }

  // Copies the saved bodies back into the functions that still exist and have no entry specialization.
  void restore(const cq::TaintInfo &T, FunctionAnalysisManager &FAM) {
    std::set<const Function *> entries;
    for (const cq::Specialization &S : T.specializations())
      if (S.isEntry())
        entries.insert(S.F);
    ValueToValueMapTy base;
    for (auto &[G, D] : back)
      if (G)
        base[D] = G;
    for (Saved &s : saved) {
      auto *F = cast_or_null<Function>(static_cast<Value *>(s.F));
      if (!F || F->isDeclaration() || entries.count(F))
        continue;
      ValueToValueMapTy VM;
      for (auto kv : base)
        VM[kv.first] = kv.second;
      for (unsigned i = 0; i < F->arg_size(); ++i)
        VM[s.copy->getArg(i)] = F->getArg(i);
      SmallVector<std::pair<BasicBlock *, BasicBlock *>, 2> addressed;   // the block now in F -> its copy
      for (auto &[bb, c] : s.addressed)
        if (auto *b = cast_or_null<BasicBlock>(static_cast<Value *>(bb)); b && b->getParent() == F)
          addressed.push_back({b, c});
      // The old body gives its names up first, so the restored values take them unchanged.
      SmallVector<BasicBlock *, 16> old;
      for (BasicBlock &BB : *F) {
        old.push_back(&BB);
        BB.setName("");
        for (Instruction &I : BB)
          I.setName("");
      }
      F->clearMetadata();
      SmallVector<ReturnInst *, 4> rets;
      CloneFunctionInto(F, s.copy, VM, CloneFunctionChangeType::LocalChangesOnly, rets);
      // The restored blocks follow the old ones; a blockaddress of an old block denotes its restored copy.
      for (auto &[b, c] : addressed)
        if (BlockAddress *BA = BlockAddress::lookup(b))
          BA->replaceAllUsesWith(BlockAddress::get(F, cast<BasicBlock>(static_cast<Value *>(VM[c]))));
      for (BasicBlock *BB : old)
        BB->dropAllReferences();
      for (BasicBlock *BB : old)
        BB->eraseFromParent();
      FAM.invalidate(*F, PreservedAnalyses::none());
    }
    saved.clear();
    back.clear();
    toCopy.clear();
    Mod.reset();
  }
};

struct CQLowerPass : PassInfoMixin<CQLowerPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {
    // cq-g3h1i: the order labels (cq/Order.h) live for one run.
    struct OrderScope {
      ~OrderScope() { cq::orderReset(); }
    } orderScope;
    cq::TaintOptions TO = readTaintOptions();
    // Read before the identity exit so a malformed flag fails on every module.
    cq::loops::KOptions KO = readKOptions();
    // cq-m8biu: taint's kept-a_K test (rule 19). cutoffBound reads only the loop, SCEV and the specialization's bounds.
    TO.kOf = [KO](const llvm::Function &F) { return cq::loops::resolveK(F, KO); };
    TO.boundOf = [](const llvm::Loop &L, llvm::ScalarEvolution &SE, const cq::Specialization &P) {
      return cq::loops::exits::cutoffBound(L, SE, P);
    };
    if (TO.roots.empty() && TO.listed.empty() && !callsCqSurface(M) && !referencesDeclaredClone(M))
      return PreservedAnalyses::all();

    FunctionAnalysisManager &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

    // The functions the input marks `noreturn` (endAtNoreturn gives the attribute back where the program ends).
    std::set<std::string> wasNoreturn;
    for (Function &F : M)
      if (!F.isDeclaration() && F.doesNotReturn())
        wasNoreturn.insert(F.getName().str());

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

    // 2a. cq-mjw9: the bodies step 2 on may rewrite, kept for the classical originals (PristineBodies).
    PristineBodies pristine;
    pristine.save(M, Tainted);

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
      if (oneBackEdge(*F)) {
        trace("one back edge: changed @" + F->getName());
        FAM.invalidate(*F, PreservedAnalyses::none());
      }
    }
    // 2b. One return block per tainted function (unifyReturns), and the rounding intrinsics as the C17 calls
    // (rewriteRoundingIntrinsics), cq-jkq8.
    for (Function *F : Tainted) {
      bool rounding = rewriteRoundingIntrinsics(*F);
      bool relative = rewriteLoadRelative(*F);
      bool output = NoOutput && dropStreamOutput(*F);
      if (!scalarizeAggregatePhis(*F) && !rounding && !relative && !output)
        continue;
      trace("rounding intrinsics / load.relative / aggregate phis: changed @" + F->getName());
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
    {
      SmallVector<Function *, 4> nowReturning;
      for (Function *F : Tainted) {
        bool wasNoreturn = F->doesNotReturn();
        if (!returnFromClassicalAborts(*F, T, FAM.getResult<LoopAnalysis>(*F)))
          continue;
        trace("classical abort arms: changed @" + F->getName());
        CFGChanged = true;
        FAM.invalidate(*F, PreservedAnalyses::none());
        if (wasNoreturn)
          nowReturning.push_back(F);
      }
      // CR rule 16 noreturn (cq-euke1): a function with no return whose dead end lies under a quantum predicate gets the
      // zero-valued return there from the spine (the walk's last such end), so it comes back like the functions above.
      for (Function *F : Tainted) {
        if (!F->doesNotReturn() || !returnsAtQuantumDeadEnd(*F, T, FAM.getResult<LoopAnalysis>(*F)))
          continue;
        trace("quantum dead end returns: @" + F->getName());
        for (Attribute::AttrKind A : {Attribute::Range, Attribute::NonNull, Attribute::Dereferenceable, Attribute::DereferenceableOrNull})
          F->removeRetAttr(A);
        F->removeFnAttr(Attribute::NoReturn);
        CFGChanged = true;
        nowReturning.push_back(F);
      }
      for (Function *G : returnAfterCalls(M, nowReturning, T, FAM)) {
        trace("calls of a returning abort: changed @" + G->getName());
        CFGChanged = true;
      }
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
    // 3a. CR rule 17 (cq-oyirf, owner ruling 2026-11-16): a loop inside a cq_invert region whose quantum value is read after
    // the end through a computation runs again after the end (eff-invert Repeat.cpp): which values are quantum is a question
    // of taint, so taint afresh once more when it copied anything.
    {
      SmallVector<Function *, 4> rep = cq::invert::repeatAfterEnd(M, T);
      for (Function *F : rep) {
        trace("rule 17 repeat after end: changed @" + F->getName());
        FAM.invalidate(*F, PreservedAnalyses::none());
      }
      if (!rep.empty()) {
        T = cq::TaintInfo();
        T = cq::computeTaint(M, TO);
      }
    }
    // 3b. A measurement in a loop's exit arm runs once after the trips: which ones is a question of taint, and the rewrite leaves the
    // loops' own CFG as it is, so taint afresh once more.
    {
      bool moved = false;
      for (Function *F : Tainted)
        if (measureAfterTrips(*F, T)) {
          trace("measure after trips: changed @" + F->getName());
          moved = true;
          FAM.invalidate(*F, PreservedAnalyses::none());
        }
      if (moved) {
        T = cq::TaintInfo();
        T = cq::computeTaint(M, TO);
      }
    }
    // 3c. An exit arm with a call or a write to memory runs once after the loop (armOnceAfterTrips, cq-os2bx): which loops have a
    // quantum exit is a question of taint, so taint afresh once more when it rewrote anything.
    {
      bool moved = false;
      for (Function *F : Tainted)
        if (armOnceAfterTrips(*F, T)) {
          trace("exit arm after trips: changed @" + F->getName());
          // cq-fi2wc: a noreturn arm of the loop that the exit arm also entered (step 2c kept it the loop's while the arm ran
          // per trip; read_char's error call) is entered from after the loop now: that edge gets its own copy.
          splitSharedNoreturnArms(*F);
          moved = true;
          FAM.invalidate(*F, PreservedAnalyses::none());
        }
      if (moved) {
        T = cq::TaintInfo();
        T = cq::computeTaint(M, TO);
      }
    }
    const cq::TaintInfo &Final = T;
    if (DumpTaint)
      Final.print(errs());

    // 4. The general construction, once per specialization. The CFG is final from here on.
    trace("construct");
    for (const cq::Specialization *S : constructionOrder(Final))
      cq::construct(M, Final, *S, KO);
    // 4b. cq-mjw9: a tainted function whose own symbol is no entry is the classical original again (principle 1).
    pristine.restore(Final, FAM);

    // 5. Drop originals with no classical caller (rule 18).
    cq::calls::finalize(M);
    // 5b. Owner rulings 2026-11-14 (scope of Q7; Q1): what does not come back ends there (endAtNoreturn).
    endAtNoreturn(M, wasNoreturn);

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

// The driver's tool for rule 27 ("a bodiless callee on a root list is lowered code of a linked library"): the listed
// functions of an injection bundle file become declarations, so the bundle never supplies a body the library has.
// Only an externally visible function is one a root list can name. Nothing else in the module changes.
struct CQDropBodiesPass : PassInfoMixin<CQDropBodiesPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool any = false;
    for (const std::string &n : DropBodies)
      if (Function *F = M.getFunction(n); F && !F->isDeclaration() && !F->hasLocalLinkage()) {
        F->deleteBody();
        F->setComdat(nullptr);
        any = true;
      }
    return any ? PreservedAnalyses::none() : PreservedAnalyses::all();
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
                  if (name == "cq-drop-bodies") {
                    MPM.addPass(CQDropBodiesPass());
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
