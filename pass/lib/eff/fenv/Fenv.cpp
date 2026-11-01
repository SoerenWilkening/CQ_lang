// Module eff-fenv (cq-w1-eff-fenv): the floating-point environment, CR rule 23 (witnesses 65, 80, 81,
// 82, 100).
//
// MODEL. The environment is program state split in two (rule 23; 80's and 81's headers):
//  - the HOST part is the real FPU state, kept exactly by the real <fenv.h> calls, which stay in the
//    output as host calls, and by every classical floating-point instruction;
//  - the QUANTUM part is two pieces of per-function state this module tracks while the spine walks:
//      MODE   classical (the host mode is the mode) or a handle (an i32 rail holding an FE_* value);
//      FLAGS  empty or a handle (an i32 rail: the exception bits quantum code raised, host encoding
//             INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32).
//    The value C reads is host | quantum: fetestexcept(m) = host call | (FLAGS & m).
//
// CONSTRUCTIONS
//  - A constrained op (llvm.experimental.constrained.*) is QUANTUM when an operand is a rail or it
//    rounds in the dynamic mode while MODE is a handle (80's quantum_mode_classical_op: a + b on
//    classical operands is cq_template_fadd_f64_ll_rmq). Its value template takes the mode last:
//    _rm with a classical i32 (a static rounding metadata as its FE_* literal; the dynamic mode as
//    the last classical fesetround constant of the same block, else a fegetround() host call), _rmq
//    with the MODE handle; round.tonearest takes none. With exceptions other than fpexcept.ignore a
//    second template, the same with _exc, computes the op's exception bits; under a quantum
//    predicate they enter as select(flag, exc, 0) (100's fenv_op_in_arm). FLAGS advances out of
//    place: FLAGS' = or(FLAGS, bits); while FLAGS is empty the bits rail becomes FLAGS. A compare's
//    value is the plain fcmp template, its bits fcmps_exc (signaling) or fcmp_exc (quiet).
//    fmuladd is unfused (CR §2): fmul then fadd, each rounded in the mode, bits or'ed. A classical
//    constrained op is the host op (it rounds in the host mode and raises into the host flags).
//  - fesetround(r): r a classical constant and no quantum predicate: the host call, MODE classical
//    (an invalid constant changes nothing). r quantum: MODE' = valid ? r : MODE with valid =
//    ((r & ~0xC00) == 0), the result valid ? 0 : 1; when known bits prove r valid, MODE' = r itself
//    (80). Under a quantum predicate p: MODE' = select(p, new, MODE). No host call when MODE' is a
//    handle (80, 100's fenv_quantum_mode).
//  - fegetround(): MODE's handle itself (no gate), or the host call.
//  - feraiseexcept(m): under a quantum predicate or with a quantum m, FLAGS' = FLAGS |
//    select(p, m & 63, 0) and no host call (65, 81); otherwise the host call.
//  - feclearexcept(m): the host call, and FLAGS' = FLAGS & ~m (81).
//  - fetestexcept(m): the host call | (FLAGS & m), a fresh i32 (65, 81, 100).
//  - fegetexceptflag(o, m) / fesetexceptflag(o, m): the host calls; the object's quantum part is
//    FLAGS & m, reinstated as (FLAGS & ~m) | (saved & m) (100's fenv_narrow_mask).
//  - fegetenv(e) / feholdexcept(e): the host call; e's quantum part is (MODE, FLAGS); feholdexcept
//    empties FLAGS. fesetenv(e): MODE, FLAGS := e's part; feupdateenv(e): MODE := e's mode, FLAGS :=
//    e's flags | FLAGS (100's fenv_dfl_env: FE_DFL_ENV has an empty quantum part). An object whose
//    quantum part this function never saved has an empty one.
//  - feenableexcept / fedisableexcept / fegetexcept: host calls; trapping is not modelled on rails.
//
// ROLES. Every FLAGS state and every rail feeding one is uncomputed (Role::Garbage) except the
// FINAL flags rail, fenv state the caller can read, an output like 71's global (rule 23: "the final
// flags rail is an output"). The final quantum MODE is kept for the same reason (orchestrator
// decision under rule 23 and NORTHSTAR goal 2, recorded on cq-w1-eff-fenv). A state is final when no
// instruction that may change it is reachable after the current one in the original function: the
// module re-decides after every instruction it lowers and sets Role::Output then. A state rail
// rule 2 makes classical (its sources measured, before or after it was computed: owner ruling
// cq-r6bc) is no output: it is uncomputed and its classical value written back to the host at the
// collapse point, feraiseexcept(v) / fesetround(m) (65; writeBack, after every measurement and
// every instruction this module lowers).
//
// ANCHOR. The state is no SSA value of the original program, so the spine's flushBefore could
// resolve a state rail at the end of its block before a later block reads it. Every rail this
// module keeps as state (MODE, FLAGS, saved parts) gets one extra noted use (Uncompute::noteUse) by
// a never-read `alloca i32` named cq.fenv in the output's entry block, the module's anchor: a
// non-call use keeps flushBefore off the rail, and flushAtExit places its uncompute after its real
// uses (Uncompute.cpp contract).
//
// LIMITS (each an internal compiler error, never an output):
//  - the quantum part changes only in an entry function or a clone carrying it (E1), outside every loop (a loop-carried state), in a block every classical path of its
//    function reaches (a classical join would merge two states), and not in a rule-19 inlined
//    callee; a read of a state rail must be dominated by its definition in the output;
//  - feclearexcept with a quantum mask, and every environment call other than fesetround,
//    fegetround, feraiseexcept and fetestexcept under a quantum predicate;
//  - a classical constrained op that raises under a quantum predicate (its bits would be quantum);
//  - a call, while the quantum part is live, to a function whose body may change the environment,
//    unless it is a quantum call of a clone carrying the environment (E1, 82: the clone takes the
//    caller's mode and flags and returns the new flags; contract at the end of this file), and
//    llvm.set.rounding while MODE is a handle; in such a clone: a quantum MODE (in the caller at the
//    call, or made in the clone), a _ctl clone, a call under a quantum predicate;
//  - round.tonearestaway and the constrained libm intrinsics (pow, sin, nearbyint, lrint, ...).
#include "cq/Effects.h"

#include <array>
#include <map>
#include <memory>
#include <optional>
#include <string>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/FPEnv.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::fenv {

// E1 (proposed Effects.h freeze amendment; contract at the end of this file).
bool cloneCarriesEnv(const Specialization &S);
std::array<Operand, 2> envArgs(LoweringContext &, CallBase &site);
void afterCloneCall(LoweringContext &, CallBase &site, Value *flagsOut);
void bindCloneEnv(LoweringContext &, Argument *mode, Argument *flags);
Value *cloneExitFlags(LoweringContext &, ReturnInst &);

namespace {

// x86-64 <fenv.h>: FE_ALL_EXCEPT and the rounding-control bits of an FE_* mode value.
constexpr int64_t kAllExcept = 63;
constexpr int64_t kModeBits = 0xC00;

// --------------------------------------------------------------------------------------------
// The <fenv.h> calls (C17 7.6), by name: a body-less callee with one of these names.

enum class FenvFn : uint8_t {
  None, ClearExcept, GetExceptFlag, RaiseExcept, SetExceptFlag, TestExcept, GetRound, SetRound,
  GetEnv, HoldExcept, SetEnv, UpdateEnv, GetExcept, EnableExcept, DisableExcept
};

FenvFn fenvFn(const CallBase &CB) {
  const Function *F = CB.getCalledFunction();
  if (!F || !F->isDeclaration())
    return FenvFn::None;
  static const std::pair<const char *, FenvFn> names[] = {
      {"feclearexcept", FenvFn::ClearExcept}, {"fegetexceptflag", FenvFn::GetExceptFlag},
      {"feraiseexcept", FenvFn::RaiseExcept}, {"fesetexceptflag", FenvFn::SetExceptFlag},
      {"fetestexcept", FenvFn::TestExcept},   {"fegetround", FenvFn::GetRound},
      {"fesetround", FenvFn::SetRound},       {"fegetenv", FenvFn::GetEnv},
      {"feholdexcept", FenvFn::HoldExcept},   {"fesetenv", FenvFn::SetEnv},
      {"feupdateenv", FenvFn::UpdateEnv},     {"fegetexcept", FenvFn::GetExcept},
      {"feenableexcept", FenvFn::EnableExcept}, {"fedisableexcept", FenvFn::DisableExcept}};
  for (auto &[n, k] : names)
    if (F->getName() == n)
      return k;
  return FenvFn::None;
}

bool raises(const ConstrainedFPIntrinsic &CI) {
  std::optional<fp::ExceptionBehavior> eb = CI.getExceptionBehavior();
  return eb && *eb != fp::ebIgnore;
}

// May this instruction change the FLAGS / MODE part (when it runs on quantum state)?
bool writesFlags(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB)
    return false;
  if (auto *CI = dyn_cast<ConstrainedFPIntrinsic>(CB))
    return raises(*CI);
  switch (fenvFn(*CB)) {
  case FenvFn::RaiseExcept: case FenvFn::ClearExcept: case FenvFn::SetExceptFlag:
  case FenvFn::SetEnv: case FenvFn::UpdateEnv: case FenvFn::HoldExcept:
    return true;
  default:
    return false;
  }
}

bool writesMode(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB)
    return false;
  if (auto *II = dyn_cast<IntrinsicInst>(CB))
    return II->getIntrinsicID() == Intrinsic::set_rounding;
  switch (fenvFn(*CB)) {
  case FenvFn::SetRound: case FenvFn::SetEnv: case FenvFn::UpdateEnv:
    return true;
  default:
    return false;
  }
}

// Does a function body (transitively through direct calls of bodies) touch the environment?
bool bodyTouchesFenv(const Function &F, SmallPtrSetImpl<const Function *> &seen) {
  if (!seen.insert(&F).second)
    return false;
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      if (isa<ConstrainedFPIntrinsic>(CB) || fenvFn(*CB) != FenvFn::None)
        return true;
      if (auto *II = dyn_cast<IntrinsicInst>(CB))
        if (II->getIntrinsicID() == Intrinsic::set_rounding || II->getIntrinsicID() == Intrinsic::get_rounding)
          return true;
      const Function *G = CB->getCalledFunction();
      if (!G) {
        if (!CB->isInlineAsm())
          return true;   // an indirect call may reach anything
        continue;
      }
      if (!G->isDeclaration() && bodyTouchesFenv(*G, seen))
        return true;
    }
  return false;
}

// E1 (82): does a clone of F carry the environment? F's body, with the bodies it calls directly,
// does constrained floating-point work or calls <fenv.h> (CR rule 23: "a clone that does constrained
// FP work takes the caller's mode and flags rail and returns the new flags rail beside its result").
// Syntactic, so the caller, the clone's construction and the twin agree on the ABI.
bool carriesEnvImpl(const Function &F) {
  if (F.isDeclaration())
    return false;
  SmallPtrSet<const Function *, 8> seen;
  return bodyTouchesFenv(F, seen);
}

// --------------------------------------------------------------------------------------------
// Per-output-function state.

struct Saved {
  Value *mode = nullptr;    // handle or null (classical: the host part restores it)
  Value *flags = nullptr;   // handle or null (empty)
  std::optional<uint64_t> mask;   // fegetexceptflag's mask when a constant
};

struct State {
  const Function *orig = nullptr;   // the walked original function (an entry's)
  Value *mode = nullptr;            // MODE handle, null = classical
  BasicBlock *modeAt = nullptr;     // output block of the last change that involved a rail
  Value *flags = nullptr;           // FLAGS handle, null = empty
  BasicBlock *flagsAt = nullptr;
  // The classical mode value known at a point of one original block.
  Value *modeVal = nullptr;
  const Instruction *modeValAt = nullptr;
  DenseMap<const Value *, Saved> envs;     // fenv_t objects, by underlying object
  DenseMap<const Value *, Saved> xflags;   // fexcept_t objects, by underlying object
  bool anyQuantumSave = false;
  bool traps = false;
  AllocaInst *anchor = nullptr;
  // E1 (82): in a clone carrying the environment, the caller's classical mode (its trailing mode
  // parameter) and whether bindCloneEnv bound the trailing parameters.
  Value *cloneMode = nullptr;
  bool cloneBound = false;
  DenseSet<const Value *> output;          // rails this module set Role::Output
  // Rule 2 collapse probes (writeBack): private binding keys, one per state piece (0 FLAGS, 1 MODE).
  Instruction *probeKey[2] = {nullptr, nullptr};
  // Analyses of original functions (the walked one and any rule-19 inlined callee).
  std::map<const Function *, std::unique_ptr<DominatorTree>> dt;
  std::map<const Function *, std::unique_ptr<LoopInfo>> li;
  std::map<const Function *, std::unique_ptr<PostDominatorTree>> pdt;
  std::map<const Function *, DenseMap<const BasicBlock *, unsigned>> walk;   // the spine's order L
};

// Keyed by the output function. A key reused by a later module's function is reset on first use
// (orig differs).
std::map<const Function *, std::unique_ptr<State>> &states() {
  static thread_local std::map<const Function *, std::unique_ptr<State>> m;
  return m;
}

State &state(LoweringContext &ctx, const Module *M) {
  auto &p = states()[&ctx.out()];
  // The walked original is taken from the first context that reaches this output function; a
  // rule-19 inlined callee is a different original lowered into the same output (requireWritable
  // refuses a quantum change there). An inlined callee's fenv call before any of the walked
  // function's would mis-record it, and then every quantum change is refused: loud, never wrong.
  if (!p || (p->orig && p->orig->getParent() != M))
    p = std::make_unique<State>();
  if (!p->orig)
    p->orig = ctx.S.F;
  return *p;
}

// The state of the function being lowered. In a clone carrying the environment (E1), nothing that
// reads or changes it may be lowered before bindCloneEnv bound the caller's mode and flags: a clone
// lowered without them would round in the host mode and drop what it raises (silent wrong output).
State &state(LoweringContext &ctx, const Instruction &I) {
  State &st = state(ctx, I.getModule());
  if (!ctx.S.isEntry() && ctx.S.F && I.getFunction() == ctx.S.F && !st.cloneBound && carriesEnvImpl(*ctx.S.F))
    unimplemented("eff-fenv: a clone that does floating-point environment work was materialized without the "
                  "caller's mode and flags (rule 23 clone ABI, 82: the calls and spine consumers of "
                  "fenv::cloneCarriesEnv / envArgs / bindCloneEnv / cloneExitFlags / afterCloneCall)",
                  &I);
  return st;
}

LoopInfo &loopInfo(State &st, const Function &F) {
  auto &d = st.dt[&F];
  if (!d)
    d = std::make_unique<DominatorTree>(const_cast<Function &>(F));
  auto &l = st.li[&F];
  if (!l)
    l = std::make_unique<LoopInfo>(*d);
  return *l;
}

PostDominatorTree &postDom(State &st, const Function &F) {
  auto &p = st.pdt[&F];
  if (!p)
    p = std::make_unique<PostDominatorTree>(const_cast<Function &>(F));
  return *p;
}

// --------------------------------------------------------------------------------------------
// Helpers over the lowering context.

bool isQ(LoweringContext &ctx, const Value *v) {
  if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<InlineAsm>(v))
    return false;
  return ctx.T.isQuantum(v, ctx.S);
}

LLVMContext &C(LoweringContext &ctx) { return ctx.M.getContext(); }
RailType i32Rail() { return RailType{Kind::Int, 32}; }
ConstantInt *i32(LoweringContext &ctx, int64_t v) {
  return ConstantInt::get(Type::getInt32Ty(C(ctx)), v, /*IsSigned=*/true);
}

RailType railOf(Type *t, const Value *at) {
  if (!t->isIntegerTy() && !t->isHalfTy() && !t->isBFloatTy() && !t->isFloatTy() && !t->isDoubleTy() &&
      !t->isX86_FP80Ty())
    unimplemented("eff-fenv: a rail of IR type that is not iN/half/bfloat/float/double/x86_fp80", at);
  return railTypeOf(t);
}

// The quantum predicate in scope (rule 8): its flag rail, nullptr when there is none.
Value *predicateFlag(LoweringContext &ctx) {
  if (ctx.currentPredicate().isTop())
    return nullptr;
  return ctx.currentFlag();
}

// The original instruction copied to the host, operands remapped.
Instruction *copyHost(LoweringContext &ctx, Instruction &I) {
  Instruction *n = I.clone();
  for (unsigned i = 0; i < n->getNumOperands(); ++i) {
    Value *v = I.getOperand(i);
    if (isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<Function>(v) || isa<InlineAsm>(v))
      continue;
    Operand op = ctx.operand(v);
    if (op.handle)
      internalError("eff-fenv: a rail handle reaching a host call", &I);
    n->setOperand(i, op.v);
  }
  if (!I.getName().empty())
    n->setName(I.getName());
  ctx.B().Insert(n);
  return n;
}

// A host call of a <fenv.h> function of the original module with these arguments.
CallInst *hostCall(LoweringContext &ctx, const CallBase &like, ArrayRef<Value *> args) {
  return ctx.B().CreateCall(like.getFunctionType(), like.getCalledOperand(), args);
}

CallInst *hostGetRound(LoweringContext &ctx) {
  FunctionCallee f = ctx.M.getOrInsertFunction("fegetround", FunctionType::get(Type::getInt32Ty(C(ctx)), false));
  return ctx.B().CreateCall(f);
}

void anchor(LoweringContext &ctx, State &st, Value *h) {
  if (!st.anchor) {
    BasicBlock &E = ctx.out().getEntryBlock();
    IRBuilder<> B(&E, E.getFirstInsertionPt());
    st.anchor = B.CreateAlloca(Type::getInt32Ty(C(ctx)), nullptr, "cq.fenv");
  }
  ctx.unc().noteUse(ctx.unc().idOf(h), st.anchor);
}

// A template of this module: emitted, recorded (Role::Garbage) and anchored.
Value *tmpl(LoweringContext &ctx, State &st, const abi::TemplateSpec &spec, ArrayRef<Operand> ops,
            const Value *orig = nullptr) {
  Value *h = ctx.emitTemplate(spec, ops, orig);
  anchor(ctx, st, h);
  return h;
}

abi::TemplateSpec intOp(const char *op, const char *shape) {
  abi::TemplateSpec s;
  s.op = op;
  s.w = i32Rail();
  s.shape = shape;
  return s;
}

// a | b over FLAGS parts (null = empty).
Value *orFlags(LoweringContext &ctx, State &st, Value *a, Value *b) {
  if (!a)
    return b;
  if (!b)
    return a;
  return tmpl(ctx, st, intOp("or", ""), {Operand{a, true}, Operand{b, true}});
}

// h & m with m classical.
Value *andLit(LoweringContext &ctx, State &st, Value *h, Value *m) {
  return tmpl(ctx, st, intOp("and", "hl"), {Operand{h, true}, Operand{m, false}});
}

// select(flag, a, b) on i32 arms (handles or classical values).
Value *select32(LoweringContext &ctx, State &st, Value *flag, Operand a, Operand b) {
  std::string sh;
  if (a.handle && b.handle)
    sh = "";
  else
    sh = std::string(a.handle ? "h" : "l") + (b.handle ? "h" : "l");
  abi::TemplateSpec s;
  s.op = "select";
  s.w = i32Rail();
  s.shape = sh;
  return tmpl(ctx, st, s, {Operand{flag, true}, a, b});
}

// Binds a lowered fenv result; taint decides the kind. A classical value taint calls quantum
// becomes a seed rail of that value (rule 7); a rail taint calls classical is a taint bug.
void bindResult(LoweringContext &ctx, const CallBase &CB, Operand r) {
  if (CB.getType()->isVoidTy())
    return;
  bool q = isQ(ctx, &CB);
  if (r.handle && !q)
    internalError("eff-fenv: a quantum fenv result that taint calls classical (rule 23 taint)", &CB);
  if (!r.handle && q) {
    if (CB.use_empty())
      return;
    RailType w = railOf(CB.getType(), &CB);
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {r.v});
    ctx.unc().recordSeed(a);
    r = Operand{a, true};
  }
  ctx.bindFields(&CB, {r});
}

// --------------------------------------------------------------------------------------------
// Where the quantum part may change and be read.

// Is the output block D a dominator of the output block Cur (every path from the entry to Cur passes
// D)? Read on the output built so far: every predecessor of a block being filled already exists.
bool outDominates(BasicBlock *D, BasicBlock *Cur) {
  if (!D || D == Cur)
    return true;
  BasicBlock *entry = &Cur->getParent()->getEntryBlock();
  SmallPtrSet<BasicBlock *, 16> seen;
  SmallVector<BasicBlock *, 16> work{Cur};
  seen.insert(Cur);
  while (!work.empty()) {
    BasicBlock *b = work.pop_back_val();
    if (b == entry)
      return false;
    bool any = false;
    for (BasicBlock *p : predecessors(b)) {
      any = true;
      if (p != D && seen.insert(p).second)
        work.push_back(p);
    }
    if (!any)
      return false;   // not connected yet: no dominance shown
  }
  return true;
}

void requireValid(LoweringContext &ctx, BasicBlock *changedIn, const Instruction &I, const char *what) {
  if (!outDominates(changedIn, ctx.B().GetInsertBlock()))
    unimplemented(std::string("eff-fenv: the quantum ") + what +
                      " changed on a path that does not reach this point on every classical path (rule 23 "
                      "state across a classical branch)",
                  &I);
}

// Is B reached on every classical path of its function: every block it is control dependent on,
// transitively, ends in a quantum terminator (whose arms the spine linearizes)?
bool classicallyTop(LoweringContext &ctx, State &st, const BasicBlock *B) {
  const Function &F = *B->getParent();
  PostDominatorTree &PDT = postDom(st, F);
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 8> work{B};
  seen.insert(B);
  while (!work.empty()) {
    const BasicBlock *X = work.pop_back_val();
    for (const BasicBlock &Y : F) {
      const Instruction *t = Y.getTerminator();
      if (!t || t->getNumSuccessors() < 2)
        continue;
      bool cd = false;
      for (const BasicBlock *s : successors(&Y))
        if ((s == X || PDT.dominates(X, s)) && !(X != &Y && PDT.dominates(X, &Y)))
          cd = true;
      if (!cd)
        continue;
      bool quantum = false;
      if (auto *br = dyn_cast<BranchInst>(t))
        quantum = br->isConditional() && isQ(ctx, br->getCondition());
      else if (auto *sw = dyn_cast<SwitchInst>(t))
        quantum = isQ(ctx, sw->getCondition());
      if (!quantum)
        return false;
      if (seen.insert(&Y).second)
        work.push_back(&Y);
    }
  }
  return true;
}

// Instructions reachable strictly after I in its function (I itself again only through a cycle).
template <typename Pred> bool anyAfter(const Instruction &I, Pred p) {
  for (const Instruction *n = I.getNextNode(); n; n = n->getNextNode())
    if (p(*n))
      return true;
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work;
  for (const BasicBlock *s : successors(I.getParent()))
    if (seen.insert(s).second)
      work.push_back(s);
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    for (const Instruction &n : *b)
      if (p(n))
        return true;
    for (const BasicBlock *s : successors(b))
      if (seen.insert(s).second)
        work.push_back(s);
  }
  return false;
}

// The spine's walk order L of F's blocks (spine/Construct.cpp Walker::plan: reverse post-order with
// successors visited last to first, so a quantum branch's then arm is linearized before its else arm).
const DenseMap<const BasicBlock *, unsigned> &walkOrder(State &st, const Function &F) {
  auto &idx = st.walk[&F];
  if (!idx.empty())
    return idx;
  std::vector<const BasicBlock *> post;
  SmallPtrSet<const BasicBlock *, 32> seen;
  std::vector<std::pair<const BasicBlock *, unsigned>> stack;
  const BasicBlock *E = &F.getEntryBlock();
  seen.insert(E);
  stack.push_back({E, E->getTerminator()->getNumSuccessors()});
  while (!stack.empty()) {
    auto &[b, k] = stack.back();
    if (k == 0) {
      post.push_back(b);
      stack.pop_back();
      continue;
    }
    const BasicBlock *s = b->getTerminator()->getSuccessor(--k);
    if (seen.insert(s).second)
      stack.push_back({s, s->getTerminator()->getNumSuccessors()});
  }
  unsigned n = 0;
  for (auto it = post.rbegin(); it != post.rend(); ++it)
    idx[*it] = n++;
  return idx;
}

// Instructions the output runs after I although the original CFG does not reach them from I: those
// of a later arm of a quantum branch I's block is in, linearized after it (rules 8, 9, 13). A block
// y counts when it comes after I's block x in the spine's walk, is not reachable from x, and the
// nearest common dominator of x and y ends in a quantum terminator (the spine's next(), cq-kti4).
template <typename Pred>
bool anyLinearizedAfter(LoweringContext &ctx, State &st, const Instruction &I, Pred p) {
  const BasicBlock *x = I.getParent();
  const Function &F = *x->getParent();
  const auto &idx = walkOrder(st, F);
  loopInfo(st, F);
  DominatorTree &DT = *st.dt[&F];
  SmallPtrSet<const BasicBlock *, 32> reach;
  SmallVector<const BasicBlock *, 16> work{x};
  while (!work.empty())
    for (const BasicBlock *s : successors(work.pop_back_val()))
      if (reach.insert(s).second)
        work.push_back(s);
  unsigned ix = idx.lookup(x);
  for (const BasicBlock &Y : F) {
    auto it = idx.find(&Y);
    if (it == idx.end() || it->second <= ix || reach.count(&Y))
      continue;
    const BasicBlock *d = DT.findNearestCommonDominator(const_cast<BasicBlock *>(x),
                                                          const_cast<BasicBlock *>(&Y));
    if (!d)
      continue;
    const Instruction *t = d->getTerminator();
    bool quantum = false;
    if (auto *br = dyn_cast<BranchInst>(t))
      quantum = br->isConditional() && isQ(ctx, br->getCondition());
    else if (auto *sw = dyn_cast<SwitchInst>(t))
      quantum = isQ(ctx, sw->getCondition());
    if (!quantum)
      continue;
    for (const Instruction &n : Y)
      if (p(n))
        return true;
  }
  return false;
}

// The quantum part (state or a saved part) may change here: the placement limits (header, LIMITS).
// CR rule 23 gives no construction merging two states at a classical join, so a change in a block a
// classical branch chooses is refused: dropping a quantum MODE by fesetround(const) on one classical
// path, or saving into an object on one classical path, would otherwise hold after the join on every
// path (cq-1dlz).
void requirePlaced(LoweringContext &ctx, State &st, const Instruction &I) {
  if (!ctx.S.isEntry() && !st.cloneBound)
    unimplemented("eff-fenv: the quantum floating-point environment changes in a clone that does not carry it "
                  "(rule 23 clone ABI, 82)",
                  &I);
  if (I.getFunction() != st.orig)
    unimplemented("eff-fenv: the quantum floating-point environment changes in a rule-19 inlined callee", &I);
  if (loopInfo(st, *I.getFunction()).getLoopFor(I.getParent()))
    unimplemented("eff-fenv: the quantum floating-point environment changes inside a loop (a loop-carried "
                  "rule 23 state)",
                  &I);
  if (!classicallyTop(ctx, st, I.getParent()))
    unimplemented("eff-fenv: the quantum floating-point environment changes in a block a classical branch "
                  "chooses (rule 23 state merged at a classical join)",
                  &I);
}

// The quantum part may change here: refuse the shapes the module does not lower (header, LIMITS).
void requireWritable(LoweringContext &ctx, State &st, const Instruction &I) {
  requirePlaced(ctx, st, I);
  // Lifted calls and llvm.set.rounding do not carry the quantum part: none may follow while it lives.
  const Instruction *bad = nullptr;
  anyAfter(I, [&](const Instruction &n) {
    auto *CB = dyn_cast<CallBase>(&n);
    if (!CB || isa<ConstrainedFPIntrinsic>(CB) || fenvFn(*CB) != FenvFn::None)
      return false;
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      if (II->getIntrinsicID() == Intrinsic::set_rounding)
        bad = &n;
      return bad != nullptr;
    }
    const Function *G = CB->getCalledFunction();
    if (G && G->isDeclaration())
      return false;   // a library function leaves the mode alone; what it raises is host flags
    SmallPtrSet<const Function *, 8> seen;
    if (CB->isInlineAsm() || (G && !bodyTouchesFenv(*G, seen)))
      return false;
    // E1 (82): a call of a clone carrying the environment takes the state and returns the new flags.
    if (G && n.getFunction() == ctx.S.F && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Lift)
      if (const Specialization *cs = ctx.T.calleeSpecialization(*CB, ctx.S);
          cs && !cs->isEntry() && carriesEnvImpl(*cs->F))
        return false;
    bad = &n;
    return true;
  });
  if (bad)
    unimplemented("eff-fenv: a call that may change the floating-point environment while its quantum part is "
                  "live (rule 23 state does not cross calls)",
                  bad);
}

void setFlags(LoweringContext &ctx, State &st, Value *f);
void setMode(LoweringContext &ctx, State &st, Value *m);

// The classical value rail h holds at the builder's point when rule 2 collapses it (every source a
// measured rail or classical, at least one measured), else nullptr. The spine's collapse is reached
// through LoweringContext::operand: h is bound to a private key of this module, a detached
// instruction no original program has, so the query reads exactly what operand() of an original
// value bound to h would read. The keys are never freed: a binding outlives this module's state.
Value *collapsedValue(LoweringContext &ctx, State &st, unsigned which, Value *h) {
  Instruction *&key = st.probeKey[which];
  if (!key) {
    key = new AllocaInst(Type::getInt32Ty(C(ctx)), 0, nullptr, Align(4), "", static_cast<Instruction *>(nullptr));
    ctx.bindFields(key, {Operand{h, true}});
  } else {
    ctx.rebind(key, {Operand{h, true}});
  }
  Operand op = ctx.operand(key);
  return op.handle ? nullptr : op.v;
}

// CR rule 2 with rule 23 (owner ruling cq-r6bc, 2026-10-29): a FLAGS or MODE rail computed only from
// measured rails and classical values (data flow, not program order: it may predate the
// measurement) collapses. Its rail is uncomputed (Role::Garbage again if this module had made it
// the final output; the spine's flush uncomputes it while its measured sources hold the outcome),
// and its classical value is written to the HOST environment at the collapse point:
// feraiseexcept(v) for the flags (v = 0 raises nothing), fesetround(m) for the mode. The quantum
// part is then empty / classical, so rule 23's final-rail output covers only what stays quantum.
// Called after every measurement (afterMeasure) and after every instruction this module lowers (a
// state set from a saved part may already be classical). Saved parts in fenv_t / fexcept_t objects
// stay rails until a restore makes them the state. The write-back is a single unconditional host
// write, so the point must be one every path of the entry function passes with no quantum predicate.
void writeBack(LoweringContext &ctx, State &st, const Instruction &I) {
  for (unsigned which = 0; which < 2; ++which) {
    Value *h = which == 0 ? st.flags : st.mode;
    if (!h)
      continue;
    if (which == 0 ? !outDominates(st.flagsAt, ctx.B().GetInsertBlock())
                   : !outDominates(st.modeAt, ctx.B().GetInsertBlock()))
      continue;   // not the state on every path here: no collapse is read (requireValid refuses a use)
    Value *v = collapsedValue(ctx, st, which, h);
    if (!v)
      continue;
    const char *what = which == 0 ? "flags" : "rounding mode";
    auto refuse = [&](const char *why) {
      unimplemented(std::string("eff-fenv: rule 2 collapses the quantum ") + what + " (its sources are measured) " +
                        why + "; its host write-back has no single point (rule 23)",
                    &I);
    };
    if (!ctx.S.isEntry() || I.getFunction() != st.orig)
      refuse("in a clone or a rule-19 inlined callee");
    if (loopInfo(st, *I.getFunction()).getLoopFor(I.getParent()))
      refuse("inside a loop");
    if (predicateFlag(ctx))
      refuse("under a quantum predicate");
    if (!classicallyTop(ctx, st, I.getParent()))
      refuse("in a block a classical branch chooses");
    Type *i32Ty = Type::getInt32Ty(C(ctx));
    FunctionCallee f = ctx.M.getOrInsertFunction(which == 0 ? "feraiseexcept" : "fesetround",
                                                 FunctionType::get(i32Ty, {i32Ty}, false));
    if (v->getType() != i32Ty)
      internalError("eff-fenv: a collapsed fenv state of a type other than i32", &I);
    ctx.B().CreateCall(f, {v});
    if (st.output.erase(h))
      ctx.unc().setRole(ctx.unc().idOf(h), Role::Garbage);
    if (which == 0) {
      setFlags(ctx, st, nullptr);
    } else {
      setMode(ctx, st, nullptr);
      st.modeVal = v;
      st.modeValAt = &I;
    }
  }
}

// A cq_measure of the CQ.h surface (cq_measure_<T>).
bool isMeasure(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  const Function *G = CB ? CB->getCalledFunction() : nullptr;
  return G && G->getName().starts_with("cq_measure");
}

// After every lowered instruction (and every measurement): a state rail with no possible writer and
// no measurement ahead (in the original CFG or in a later linearized quantum arm) is final, an output. A measurement ahead may make it classical (rule 2,
// writeBack), and an output's sources are freed after their last use, which its later uncompute
// would need. A writer or measurement inside a loop is ignored here: if it ever wrote the quantum
// part, requireWritable stops it; a collapse there is refused by writeBack.
void settle(LoweringContext &ctx, State &st, const Instruction &I) {
  writeBack(ctx, st, I);
  if (st.cloneBound)
    return;   // E1: a clone's final flags are copied out at its returns (cloneExitFlags), never an output
  LoopInfo &LI = loopInfo(st, *I.getFunction());
  auto final = [&](bool (*writes)(const Instruction &)) {
    auto later = [&](const Instruction &n) {
      return (writes(n) || isMeasure(n)) && !LI.getLoopFor(n.getParent());
    };
    return !anyAfter(I, later) && !anyLinearizedAfter(ctx, st, I, later);
  };
  if (st.flags && !st.output.count(st.flags) && final(writesFlags)) {
    ctx.unc().setRole(ctx.unc().idOf(st.flags), Role::Output);
    st.output.insert(st.flags);
  }
  if (st.mode && !st.output.count(st.mode) && final(writesMode)) {
    ctx.unc().setRole(ctx.unc().idOf(st.mode), Role::Output);
    st.output.insert(st.mode);
  }
}

void setFlags(LoweringContext &ctx, State &st, Value *f) {
  if (f == st.flags)
    return;
  st.flags = f;
  st.flagsAt = ctx.B().GetInsertBlock();
  if (f)
    anchor(ctx, st, f);
}

void setMode(LoweringContext &ctx, State &st, Value *m) {
  if (m && st.cloneBound)
    unimplemented("eff-fenv: a clone makes the rounding mode quantum (rule 23: a clone returns only the new "
                  "flags rail, 82)",
                  ctx.S.F);
  if (m == st.mode && !m)
    return;
  if (m || st.mode)
    st.modeAt = ctx.B().GetInsertBlock();
  st.mode = m;
  st.modeVal = nullptr;
  if (m)
    anchor(ctx, st, m);
}

// --------------------------------------------------------------------------------------------
// The mode operand of a rounding op.

// Is the classical mode value cached at modeValAt still the mode at I (same original block, no call
// in between that may change it)?
bool cacheValid(const State &st, const Instruction &I) {
  if (!st.modeVal || !st.modeValAt || st.modeValAt->getParent() != I.getParent() ||
      !st.modeValAt->comesBefore(&I))
    return false;
  for (const Instruction *n = st.modeValAt->getNextNode(); n && n != &I; n = n->getNextNode()) {
    auto *CB = dyn_cast<CallBase>(n);
    if (!CB || isa<ConstrainedFPIntrinsic>(CB))
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      if (II->getIntrinsicID() == Intrinsic::set_rounding)
        return false;
      continue;
    }
    const Function *G = CB->getCalledFunction();
    if (G && G->isDeclaration() && (G->getName().starts_with("cq_") || G->getName().starts_with("__cq_")))
      continue;
    if (fenvFn(*CB) != FenvFn::None && !writesMode(*CB))
      continue;
    return false;
  }
  return true;
}

// The classical dynamic mode at I.
Value *classicalMode(LoweringContext &ctx, State &st, const Instruction &I) {
  if (st.cloneBound)
    return st.cloneMode;   // E1: the caller's mode; bindCloneEnv refused a clone that changes it
  if (cacheValid(st, I))
    return st.modeVal;
  st.modeVal = hostGetRound(ctx);
  st.modeValAt = &I;
  return st.modeVal;
}

struct ModeOp {
  abi::TemplateSpec::Rm rm = abi::TemplateSpec::NoRm;
  Operand v{nullptr, false};
  bool dynamic = false;
};

// The mode operand of a constrained op; the classical dynamic value is only fetched on `need`.
ModeOp modeOperand(LoweringContext &ctx, State &st, const ConstrainedFPIntrinsic &CI, bool need) {
  ModeOp m;
  std::optional<RoundingMode> rm = CI.getRoundingMode();
  if (!rm)
    return m;
  switch (*rm) {
  case RoundingMode::NearestTiesToEven:
    return m;
  case RoundingMode::TowardNegative:
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{i32(ctx, 1024), false};
    return m;
  case RoundingMode::TowardPositive:
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{i32(ctx, 2048), false};
    return m;
  case RoundingMode::TowardZero:
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{i32(ctx, 3072), false};
    return m;
  case RoundingMode::Dynamic:
    m.dynamic = true;
    if (st.mode) {
      requireValid(ctx, st.modeAt, CI, "rounding mode");
      m.rm = abi::TemplateSpec::RmRail;
      m.v = Operand{st.mode, true};
    } else if (need) {
      m.rm = abi::TemplateSpec::RmLit;
      m.v = Operand{classicalMode(ctx, st, CI), false};
    } else {
      m.rm = abi::TemplateSpec::RmLit;
    }
    return m;
  default:
    unimplemented("eff-fenv: a constrained op rounding to nearest, ties away (no x86-64 FE_* mode)", &CI);
  }
}

// --------------------------------------------------------------------------------------------
// Constrained ops.

bool provablyNotNaN(const Value *v) {
  if (auto *c = dyn_cast<ConstantFP>(v))
    return !c->isNaN();
  return true;
}

const char *constrainedOp(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::experimental_constrained_fadd: return "fadd";
  case Intrinsic::experimental_constrained_fsub: return "fsub";
  case Intrinsic::experimental_constrained_fmul: return "fmul";
  case Intrinsic::experimental_constrained_fdiv: return "fdiv";
  case Intrinsic::experimental_constrained_frem: return "frem";
  case Intrinsic::experimental_constrained_fma: return "fma";
  case Intrinsic::experimental_constrained_sqrt: return "sqrt";
  case Intrinsic::experimental_constrained_rint: return "rint";
  case Intrinsic::experimental_constrained_floor: return "floor";
  case Intrinsic::experimental_constrained_ceil: return "ceil";
  case Intrinsic::experimental_constrained_trunc: return "trunc";
  case Intrinsic::experimental_constrained_round: return "round";
  case Intrinsic::experimental_constrained_maxnum: return "fmax";
  case Intrinsic::experimental_constrained_minnum: return "fmin";
  case Intrinsic::experimental_constrained_fptrunc: return "fptrunc";
  case Intrinsic::experimental_constrained_fpext: return "fpext";
  case Intrinsic::experimental_constrained_sitofp: return "sitofp";
  case Intrinsic::experimental_constrained_uitofp: return "uitofp";
  case Intrinsic::experimental_constrained_fptosi: return "fptosi";
  case Intrinsic::experimental_constrained_fptoui: return "fptoui";
  case Intrinsic::experimental_constrained_fcmp: return "fcmp";
  case Intrinsic::experimental_constrained_fcmps: return "fcmps";
  default: return nullptr;
  }
}

bool isCast(StringRef op) {
  return op == "fptrunc" || op == "fpext" || op == "sitofp" || op == "uitofp" || op == "fptosi" ||
         op == "fptoui";
}

// One quantum template step: its value spec and operands (mode last), and its _exc twin.
struct Step {
  abi::TemplateSpec spec;
  SmallVector<Operand, 4> ops;
};

// Builds the value template of op over data operands (handles or classical values) and the mode.
Step makeStep(StringRef op, CmpInst::Predicate pred, Type *wTy, Type *toTy, SmallVector<Operand, 3> data,
              const ModeOp &mode, const Value *at) {
  Step s;
  s.spec.op = op.str();
  s.spec.w = railOf(wTy, at);
  if (toTy)
    s.spec.to = railOf(toTy, at);
  bool fcmp = op == "fcmp" || op == "fcmps";
  if (fcmp) {
    // The value of a compare is the plain fcmp (81); compares never take _lh: flip the predicate.
    s.spec.op = "fcmp";
    if (!data[0].handle && data[1].handle) {
      std::swap(data[0], data[1]);
      pred = CmpInst::getSwappedPredicate(pred);
    }
    s.spec.pred = CmpInst::getPredicateName(pred).str();
    s.spec.shape = data[1].handle ? "" : "hl";
  } else if (data.size() == 1) {
    s.spec.shape = data[0].handle ? "" : "l";
  } else if (data.size() == 2) {
    bool comm = op == "fadd" || op == "fmul";
    if (data[0].handle && data[1].handle)
      s.spec.shape = "";
    else if (data[0].handle)
      s.spec.shape = "hl";
    else if (data[1].handle) {
      if (comm && provablyNotNaN(data[0].v)) {
        std::swap(data[0], data[1]);
        s.spec.shape = "hl";
      } else {
        s.spec.shape = "lh";
      }
    } else {
      s.spec.shape = "ll";
    }
  } else {
    // fma: one letter per operand, q or l, bare for qqq; the product operands commute unless the
    // literal is a NaN (CR §1.2).
    if (!data[0].handle && data[1].handle && provablyNotNaN(data[0].v))
      std::swap(data[0], data[1]);
    std::string sh;
    for (const Operand &o : data)
      sh += o.handle ? 'q' : 'l';
    s.spec.shape = sh == "qqq" ? "" : sh;
  }
  s.ops.append(data.begin(), data.end());
  if (!fcmp && mode.rm != abi::TemplateSpec::NoRm) {
    s.spec.rm = mode.rm;
    s.ops.push_back(mode.v);
  }
  return s;
}

// The exception bits of a step: the same template with _exc; a compare's are fcmps/fcmp_exc.
Value *excOf(LoweringContext &ctx, State &st, const Step &s, StringRef origOp) {
  abi::TemplateSpec e = s.spec;
  e.exc = true;
  if (origOp == "fcmp" || origOp == "fcmps")
    e.op = origOp.str();
  return tmpl(ctx, st, e, s.ops);
}

void raiseBits(LoweringContext &ctx, State &st, const Instruction &I, Value *bits) {
  if (st.traps)
    unimplemented("eff-fenv: a quantum op raising after feenableexcept (a trap on quantum flags)", &I);
  if (st.flags)
    requireValid(ctx, st.flagsAt, I, "flags");
  if (Value *flag = predicateFlag(ctx))
    bits = select32(ctx, st, flag, Operand{bits, true}, Operand{i32(ctx, 0), false});
  setFlags(ctx, st, orFlags(ctx, st, st.flags, bits));
}

} // namespace

void lowerConstrained(LoweringContext &ctx, CallBase &CB) {
  auto &CI = cast<ConstrainedFPIntrinsic>(CB);
  State &st = state(ctx, CI);
  const char *op = constrainedOp(CI.getIntrinsicID());
  bool fmuladd = CI.getIntrinsicID() == Intrinsic::experimental_constrained_fmuladd;
  unsigned n = CI.getNonMetadataArgCount();
  SmallVector<Operand, 3> data;
  bool anyHandle = false;
  for (unsigned i = 0; i < n; ++i) {
    data.push_back(ctx.operand(CI.getArgOperand(i)));
    anyHandle |= data.back().handle;
  }
  ModeOp mode0 = modeOperand(ctx, st, CI, /*need=*/false);
  bool quantum = anyHandle || mode0.rm == abi::TemplateSpec::RmRail;

  if (!quantum) {
    // The host op: rounds in the host mode, raises into the host flags.
    if (raises(CI) && !ctx.currentPredicate().isTop())
      unimplemented("eff-fenv: a classical constrained op that raises under a quantum predicate (its "
                    "exception bits are quantum)",
                    &CI);
    bindResult(ctx, CB, Operand{copyHost(ctx, CI), false});
    settle(ctx, st, CI);
    return;
  }
  if (!op && !fmuladd)
    unimplemented("eff-fenv: a quantum constrained op with no rule 4 template (a libm intrinsic)", &CI);
  if (!isQ(ctx, &CI))
    internalError("eff-fenv: a quantum constrained op that taint calls classical (rule 23 taint)", &CI);
  if (raises(CI))
    requireWritable(ctx, st, CI);
  ModeOp mode = modeOperand(ctx, st, CI, /*need=*/true);

  if (fmuladd) {
    // CR §2: unfused, fmul then fadd, each rounded in the mode.
    Type *T = CI.getType();
    Step mul = makeStep("fmul", CmpInst::BAD_FCMP_PREDICATE, T, nullptr, {data[0], data[1]}, mode, &CI);
    Operand prod;
    Value *e1 = nullptr;
    if (!data[0].handle && !data[1].handle && mode.rm != abi::TemplateSpec::RmRail) {
      // A classical product: the host op.
      if (raises(CI) && !ctx.currentPredicate().isTop())
        unimplemented("eff-fenv: a classical constrained product that raises under a quantum predicate", &CI);
      prod = Operand{ctx.B().CreateConstrainedFPBinOp(Intrinsic::experimental_constrained_fmul, data[0].v,
                                                      data[1].v, nullptr, "", nullptr, CI.getRoundingMode(),
                                                      CI.getExceptionBehavior()),
                     false};
    } else {
      prod = Operand{tmpl(ctx, st, mul.spec, mul.ops), true};
      if (raises(CI))
        e1 = excOf(ctx, st, mul, "fmul");
    }
    Step add = makeStep("fadd", CmpInst::BAD_FCMP_PREDICATE, T, nullptr, {prod, data[2]}, mode, &CI);
    ctx.emitTemplate(add.spec, add.ops, &CI);
    if (raises(CI)) {
      Value *e2 = excOf(ctx, st, add, "fadd");
      Value *bits = e1 ? tmpl(ctx, st, intOp("or", ""), {Operand{e1, true}, Operand{e2, true}}) : e2;
      raiseBits(ctx, st, CI, bits);
    }
    settle(ctx, st, CI);
    return;
  }

  StringRef o = op;
  Type *wTy = isCast(o) || o == "fcmp" || o == "fcmps" ? CI.getArgOperand(0)->getType() : CI.getType();
  Type *toTy = isCast(o) ? CI.getType() : nullptr;
  CmpInst::Predicate pred = CmpInst::BAD_FCMP_PREDICATE;
  if (auto *cmp = dyn_cast<ConstrainedFPCmpIntrinsic>(&CI))
    pred = cmp->getPredicate();
  Step s = makeStep(o, pred, wTy, toTy, data, mode, &CI);
  if (!anyHandle && (o == "fcmp" || o == "fcmps" || mode.rm == abi::TemplateSpec::NoRm))
    internalError("eff-fenv: a quantum constrained op with no quantum operand", &CI);
  ctx.emitTemplate(s.spec, s.ops, &CI);
  if (raises(CI))
    raiseBits(ctx, st, CI, excOf(ctx, st, s, o));
  settle(ctx, st, CI);
}

namespace {

const Value *objectOf(const Value *p) { return getUnderlyingObject(p); }

// A saved quantum part goes into a local object only, accessed by nothing but the fenv calls.
void requireSaveTarget(const Value *obj, const Instruction &I) {
  auto *AI = dyn_cast<AllocaInst>(obj);
  if (!AI)
    unimplemented("eff-fenv: a quantum environment part saved into an object that is not a local variable", &I);
  for (const User *u : AI->users()) {
    if (auto *CB = dyn_cast<CallBase>(u)) {
      if (fenvFn(*CB) != FenvFn::None)
        continue;
      if (auto *II = dyn_cast<IntrinsicInst>(CB))
        if (II->isLifetimeStartOrEnd())
          continue;
    }
    unimplemented("eff-fenv: a saved quantum environment part in an object that other code reads or writes", u);
  }
}

// The saved quantum part of the object p points to (an object never saved here has an empty one).
Saved savedOf(LoweringContext &ctx, State &st, DenseMap<const Value *, Saved> &table, const Value *p,
              const Instruction &I) {
  const Value *obj = objectOf(p);
  auto it = table.find(obj);
  if (it != table.end())
    return it->second;
  if (st.anyQuantumSave && !(isa<GlobalVariable>(obj) && cast<GlobalVariable>(obj)->isConstant()))
    unimplemented("eff-fenv: an environment restored from an object that is not the one this function saved "
                  "a quantum part into",
                  &I);
  return Saved{};
}

void save(LoweringContext &ctx, State &st, DenseMap<const Value *, Saved> &table, const Value *p, Saved s,
          const Instruction &I) {
  const Value *obj = objectOf(p);
  auto prev = table.find(obj);
  if (s.mode || s.flags || (prev != table.end() && (prev->second.mode || prev->second.flags)))
    requirePlaced(ctx, st, I);   // the object's saved part changes on every path or is refused (cq-1dlz)
  if (s.mode || s.flags) {
    requireSaveTarget(obj, I);
    st.anyQuantumSave = true;
  }
  table[obj] = s;
}

std::optional<uint64_t> constMask(Value *v) {
  if (auto *c = dyn_cast<ConstantInt>(v))
    return c->getZExtValue();
  return std::nullopt;
}

// ~m as a classical i32 (folded for a constant).
Value *notClassical(LoweringContext &ctx, Value *m) {
  if (auto *c = dyn_cast<ConstantInt>(m))
    return ConstantInt::get(c->getType(), ~c->getValue());
  return ctx.B().CreateNot(m);
}

bool knownValidMode(LoweringContext &ctx, const Value *orig) {
  KnownBits k = computeKnownBits(orig, ctx.M.getDataLayout());
  APInt outside = ~APInt(k.getBitWidth(), kModeBits);
  return (k.Zero & outside) == outside;
}

} // namespace

void lowerFenvCall(LoweringContext &ctx, CallBase &CB) {
  FenvFn fn = fenvFn(CB);
  if (fn == FenvFn::None)
    internalError("eff-fenv: lowerFenvCall on a call that is no <fenv.h> function", &CB);
  State &st = state(ctx, CB);
  Value *flag = predicateFlag(ctx);
  auto arg = [&](unsigned i) { return ctx.operand(CB.getArgOperand(i)); };
  auto noPredicate = [&](const char *name) {
    if (flag)
      unimplemented(std::string("eff-fenv: ") + name + " under a quantum predicate", &CB);
  };
  auto hostCopy = [&]() {
    Instruction *h = copyHost(ctx, CB);
    bindResult(ctx, CB, Operand{h, false});
    return h;
  };

  switch (fn) {
  case FenvFn::GetRound: {
    if (st.mode) {
      requireValid(ctx, st.modeAt, CB, "rounding mode");
      bindResult(ctx, CB, Operand{st.mode, true});   // the mode handle itself, no gate (80)
      break;
    }
    Instruction *h = hostCopy();
    st.modeVal = h;
    st.modeValAt = &CB;
    break;
  }

  case FenvFn::SetRound: {
    Operand r = arg(0);
    if (!r.handle && !flag) {
      if (auto *c = dyn_cast<ConstantInt>(r.v)) {
        bool valid = (c->getZExtValue() & ~uint64_t(kModeBits) & 0xffffffffu) == 0;
        if (valid && st.mode)
          requirePlaced(ctx, st, CB);   // drops the quantum MODE: on every path or refused (cq-1dlz)
        hostCopy();
        if (valid) {
          setMode(ctx, st, nullptr);
          st.modeVal = c;
          st.modeValAt = &CB;
        }
        break;
      }
      if (st.mode)
        unimplemented("eff-fenv: fesetround of a classical run-time value while the mode is quantum", &CB);
      hostCopy();
      st.modeVal = nullptr;
      break;
    }
    requireWritable(ctx, st, CB);
    if (st.mode)
      requireValid(ctx, st.modeAt, CB, "rounding mode");
    Operand old = st.mode ? Operand{st.mode, true} : Operand{classicalMode(ctx, st, CB), false};
    if (!r.handle) {
      // A classical argument under a quantum predicate: no host call; MODE' = select(p, r', MODE).
      Value *nv = r.v, *ret = i32(ctx, 0);
      if (auto *c = dyn_cast<ConstantInt>(r.v)) {
        if ((c->getZExtValue() & ~uint64_t(kModeBits) & 0xffffffffu) != 0)
          unimplemented("eff-fenv: fesetround of an invalid constant under a quantum predicate", &CB);
      } else {
        if (old.handle)
          unimplemented("eff-fenv: fesetround of a classical run-time value under a quantum predicate while the "
                        "mode is quantum",
                        &CB);
        IRBuilder<> &B = ctx.B();
        Value *valid = B.CreateICmpEQ(B.CreateAnd(r.v, notClassical(ctx, i32(ctx, kModeBits))), i32(ctx, 0));
        nv = B.CreateSelect(valid, r.v, old.v);
        ret = B.CreateSelect(valid, i32(ctx, 0), i32(ctx, 1));
      }
      setMode(ctx, st, select32(ctx, st, flag, Operand{nv, false}, old));
      bindResult(ctx, CB, Operand{ret, false});
      break;
    }
    // A quantum argument (100's fenv_quantum_mode; 80 when known bits prove it valid).
    if (knownValidMode(ctx, CB.getArgOperand(0))) {
      Value *nm = flag ? select32(ctx, st, flag, r, old) : r.v;
      setMode(ctx, st, nm);
      if (!CB.use_empty())
        bindResult(ctx, CB, Operand{i32(ctx, 0), false});
      break;
    }
    Value *stray = tmpl(ctx, st, intOp("and", "hl"), {r, Operand{i32(ctx, ~kModeBits), false}});
    abi::TemplateSpec eq = intOp("icmp", "hl");
    eq.pred = "eq";
    Value *valid = tmpl(ctx, st, eq, {Operand{stray, true}, Operand{i32(ctx, 0), false}});
    Value *take = valid;
    if (flag) {
      abi::TemplateSpec a;
      a.op = "and";
      a.w = RailType{Kind::Int, 1};
      take = tmpl(ctx, st, a, {Operand{valid, true}, Operand{flag, true}});
    }
    setMode(ctx, st, select32(ctx, st, take, r, old));
    if (!CB.use_empty())
      bindResult(ctx, CB,
                 Operand{select32(ctx, st, valid, Operand{i32(ctx, 0), false}, Operand{i32(ctx, 1), false}),
                         true});
    break;
  }

  case FenvFn::RaiseExcept: {
    Operand m = arg(0);
    if (!m.handle && !flag) {
      hostCopy();
      break;
    }
    requireWritable(ctx, st, CB);
    Value *bits;
    if (m.handle) {
      KnownBits k = computeKnownBits(CB.getArgOperand(0), ctx.M.getDataLayout());
      APInt outside = ~APInt(k.getBitWidth(), kAllExcept);
      bits = (k.Zero & outside) == outside ? m.v : andLit(ctx, st, m.v, i32(ctx, kAllExcept));
      if (flag)
        bits = select32(ctx, st, flag, Operand{bits, true}, Operand{i32(ctx, 0), false});
    } else {
      Value *lit = isa<ConstantInt>(m.v) ? (Value *)ConstantInt::get(m.v->getType(),
                                                                     cast<ConstantInt>(m.v)->getValue() & kAllExcept)
                                         : ctx.B().CreateAnd(m.v, i32(ctx, kAllExcept));
      bits = select32(ctx, st, flag, Operand{lit, false}, Operand{i32(ctx, 0), false});
    }
    if (st.flags)
      requireValid(ctx, st.flagsAt, CB, "flags");
    setFlags(ctx, st, orFlags(ctx, st, st.flags, bits));
    bindResult(ctx, CB, Operand{i32(ctx, 0), false});   // feraiseexcept succeeds
    break;
  }

  case FenvFn::ClearExcept: {
    noPredicate("feclearexcept");
    Operand m = arg(0);
    if (m.handle)
      unimplemented("eff-fenv: feclearexcept with a quantum mask", &CB);
    hostCopy();
    if (!st.flags)
      break;
    if (auto c = constMask(m.v); c && (*c & kAllExcept) == 0)
      break;
    requireWritable(ctx, st, CB);
    requireValid(ctx, st.flagsAt, CB, "flags");
    setFlags(ctx, st, andLit(ctx, st, st.flags, notClassical(ctx, m.v)));
    break;
  }

  case FenvFn::TestExcept: {
    Operand m = arg(0);
    if (st.flags)
      requireValid(ctx, st.flagsAt, CB, "flags");
    if (!m.handle) {
      Instruction *h = copyHost(ctx, CB);
      if (!st.flags) {
        bindResult(ctx, CB, Operand{h, false});
        break;
      }
      Value *q = tmpl(ctx, st, intOp("and", "hl"), {Operand{st.flags, true}, m});
      bindResult(ctx, CB, Operand{tmpl(ctx, st, intOp("or", "hl"), {Operand{q, true}, Operand{h, false}}), true});
      break;
    }
    // A quantum mask: (host(ALL) | FLAGS) & m.
    CallInst *h = hostCall(ctx, CB, {i32(ctx, kAllExcept)});
    Value *r;
    if (st.flags) {
      Value *u = tmpl(ctx, st, intOp("or", "hl"), {Operand{st.flags, true}, Operand{h, false}});
      r = tmpl(ctx, st, intOp("and", ""), {Operand{u, true}, m});
    } else {
      r = tmpl(ctx, st, intOp("and", "hl"), {m, Operand{h, false}});
    }
    bindResult(ctx, CB, Operand{r, true});
    break;
  }

  case FenvFn::GetExceptFlag: {
    noPredicate("fegetexceptflag");
    Operand m = arg(1);
    if (m.handle)
      unimplemented("eff-fenv: fegetexceptflag with a quantum mask", &CB);
    hostCopy();
    Saved s;
    s.mask = constMask(m.v);
    if (st.flags) {
      requireValid(ctx, st.flagsAt, CB, "flags");
      requireWritable(ctx, st, CB);
      s.flags = andLit(ctx, st, st.flags, m.v);
    }
    save(ctx, st, st.xflags, CB.getArgOperand(0), s, CB);
    break;
  }

  case FenvFn::SetExceptFlag: {
    noPredicate("fesetexceptflag");
    Operand m = arg(1);
    if (m.handle)
      unimplemented("eff-fenv: fesetexceptflag with a quantum mask", &CB);
    hostCopy();
    Saved s = savedOf(ctx, st, st.xflags, CB.getArgOperand(0), CB);
    if (!st.flags && !s.flags)
      break;
    requireWritable(ctx, st, CB);
    std::optional<uint64_t> cm = constMask(m.v);
    if (cm && (*cm & kAllExcept) == 0)
      break;
    Value *cur = nullptr, *sv = nullptr;
    if (st.flags) {
      requireValid(ctx, st.flagsAt, CB, "flags");
      // FE_ALL_EXCEPT (82): every bit is reinstated from the saved part, the current rail is dropped.
      if (!(cm && (*cm & kAllExcept) == kAllExcept))
        cur = andLit(ctx, st, st.flags, notClassical(ctx, m.v));
    }
    if (s.flags) {
      bool covered = cm && s.mask && (*s.mask & ~*cm & kAllExcept) == 0;
      sv = covered ? s.flags : andLit(ctx, st, s.flags, m.v);
    }
    setFlags(ctx, st, orFlags(ctx, st, cur, sv));
    break;
  }

  case FenvFn::GetEnv:
  case FenvFn::HoldExcept: {
    noPredicate(fn == FenvFn::GetEnv ? "fegetenv" : "feholdexcept");
    hostCopy();
    if (st.mode)
      requireValid(ctx, st.modeAt, CB, "rounding mode");
    if (st.flags)
      requireValid(ctx, st.flagsAt, CB, "flags");
    save(ctx, st, st.envs, CB.getArgOperand(0), Saved{st.mode, st.flags, std::nullopt}, CB);
    if (fn == FenvFn::HoldExcept && st.flags) {
      requireWritable(ctx, st, CB);
      setFlags(ctx, st, nullptr);
    }
    break;
  }

  case FenvFn::SetEnv:
  case FenvFn::UpdateEnv: {
    noPredicate(fn == FenvFn::SetEnv ? "fesetenv" : "feupdateenv");
    hostCopy();
    Saved s = savedOf(ctx, st, st.envs, CB.getArgOperand(0), CB);
    if (st.mode || st.flags || s.mode || s.flags)
      requireWritable(ctx, st, CB);
    if (st.flags)
      requireValid(ctx, st.flagsAt, CB, "flags");
    setMode(ctx, st, s.mode);
    if (fn == FenvFn::SetEnv)
      setFlags(ctx, st, s.flags);
    else
      setFlags(ctx, st, orFlags(ctx, st, s.flags, st.flags));
    break;
  }

  case FenvFn::GetExcept:
  case FenvFn::EnableExcept:
  case FenvFn::DisableExcept: {
    noPredicate("the exception trap calls");
    if (!CB.arg_empty() && arg(0).handle)
      unimplemented("eff-fenv: an exception trap call with a quantum mask", &CB);
    hostCopy();
    if (fn == FenvFn::EnableExcept)
      st.traps = true;
    break;
  }

  case FenvFn::None:
    break;
  }
  settle(ctx, st, CB);
}

// After the spine lowered a cq_measure: rule 2 may have made the quantum state classical (65).
void afterMeasure(LoweringContext &ctx, CallInst &measure) {
  auto &m = states();
  auto it = m.find(&ctx.out());
  if (it == m.end() || !it->second || !it->second->orig || it->second->orig->getParent() != measure.getModule())
    return;
  State &st = *it->second;
  if (st.flags || st.mode)
    settle(ctx, st, measure);
}

// --------------------------------------------------------------------------------------------
// E1 (CR rule 23, 82): the clone ABI of the environment. Proposed as a freeze amendment of Effects.h
// (declarations below, consumers calls and spine); until it lands they are declared here.
//
//  - cloneCarriesEnv(S): a clone of S takes two trailing i32 parameters after every other one (the
//    caller's MODE, a classical FE_* value, then its FLAGS, a handle) and returns the new FLAGS handle
//    as the LAST field of its result: `i32` alone for a clone whose result is otherwise void, else a
//    literal struct of its result fields (C types where classical, handles where quantum; the M2 store
//    handles included) followed by i32. The twin's outs are every handle field in that order (the new
//    flags last), then the clone's parameters (mode and flags included).
//  - envArgs(ctx, site): caller, at the builder before the clone call: {mode (classical), flags
//    (handle)}. An empty FLAGS becomes a fresh |0> seed first. Unimplemented: MODE a handle (a clone
//    rounding in a quantum mode), a quantum predicate at the site (a _ctl clone's flags).
//  - afterCloneCall(ctx, site, flagsOut): caller, right after the call and after recordCall recorded
//    flagsOut (the extractvalue of the last field, or the call itself) as an out: FLAGS := flagsOut.
//    This module may set flagsOut's role to Output (the final flags) afterwards.
//  - bindCloneEnv(ctx, mode, flags): clone, at its entry after the formals are bound (before any
//    instruction is lowered): MODE := mode (classical), FLAGS := flags (recorded here as the caller's
//    rail, Role::UserRegister, never freed in the clone).
//  - cloneExitFlags(ctx, ret): clone, at each return before the copy-outs: the FLAGS handle to copy
//    out into the returned flags rail (alloc_i32(0), copy_i32, Role::Result, as the result's).

namespace {
State &stateOfCall(LoweringContext &ctx, const Instruction &I) { return state(ctx, I); }
} // namespace

bool cloneCarriesEnv(const Specialization &S) {
  return S.F && !S.isEntry() && carriesEnvImpl(*S.F);
}

std::array<Operand, 2> envArgs(LoweringContext &ctx, CallBase &site) {
  State &st = stateOfCall(ctx, site);
  if (st.mode)
    unimplemented("eff-fenv: a call of a clone carrying the environment while the rounding mode is quantum "
                  "(rule 23 clone ABI with a mode handle)",
                  &site);
  if (predicateFlag(ctx))
    unimplemented("eff-fenv: a call of a clone carrying the environment under a quantum predicate (its new "
                  "flags rail would merge with the old under the predicate)",
                  &site);
  requireWritable(ctx, st, site);
  Value *mode = classicalMode(ctx, st, site);
  if (st.flags) {
    requireValid(ctx, st.flagsAt, site, "flags");
  } else {
    CallInst *z = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i32Rail()}, {i32(ctx, 0)});
    ctx.unc().recordSeed(z);
    setFlags(ctx, st, z);
  }
  return {Operand{mode, false}, Operand{st.flags, true}};
}

void afterCloneCall(LoweringContext &ctx, CallBase &site, Value *flagsOut) {
  State &st = stateOfCall(ctx, site);
  if (!flagsOut || !flagsOut->getType()->isIntegerTy(32))
    internalError("eff-fenv: afterCloneCall without the clone's returned flags handle", &site);
  setFlags(ctx, st, flagsOut);
  settle(ctx, st, site);
}

void bindCloneEnv(LoweringContext &ctx, Argument *mode, Argument *flags) {
  if (ctx.S.isEntry() || !cloneCarriesEnv(ctx.S))
    internalError("eff-fenv: bindCloneEnv in a function that does not carry the environment", mode);
  if (!mode->getType()->isIntegerTy(32) || !flags->getType()->isIntegerTy(32))
    internalError("eff-fenv: a clone's trailing mode and flags parameters are not i32", mode);
  if (ctx.S.ctl)
    unimplemented("eff-fenv: a _ctl clone carrying the environment (its raised bits under the entry flag)", ctx.S.F);
  for (const BasicBlock &BB : *ctx.S.F)
    for (const Instruction &I : BB)
      if (writesMode(I))
        unimplemented("eff-fenv: a clone that changes the rounding mode (rule 23: a clone returns only the new "
                      "flags rail, 82)",
                      &I);
  State &st = state(ctx, ctx.S.F->getParent());
  if (st.cloneBound)
    internalError("eff-fenv: bindCloneEnv called twice for one clone", mode);
  ctx.unc().recordExternal(flags, Role::UserRegister);
  st.cloneBound = true;
  st.cloneMode = mode;
  st.flags = flags;
  st.flagsAt = nullptr;   // defined at the clone's entry: on every path
}

Value *cloneExitFlags(LoweringContext &ctx, ReturnInst &ret) {
  State &st = stateOfCall(ctx, ret);
  if (!st.cloneBound || !st.flags)
    internalError("eff-fenv: cloneExitFlags in a clone whose environment was not bound", &ret);
  requireValid(ctx, st.flagsAt, ret, "flags");
  return st.flags;
}

} // namespace cq::fenv
