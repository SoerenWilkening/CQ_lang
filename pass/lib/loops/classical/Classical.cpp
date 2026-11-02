// Module loops-classical (cq-w1-loops-classical): CR rule 14, case 1 (classical bound, quantum body)
// and case 3 (classical bound with a quantum exit, `c || q`).
//
// Reference for the reverse replay: BennettVM.jl src/history/Replay.jl:unrun! (a history tape of the
// forward run, replayed last-in-first-out), and Bennett.jl src/bennett_transform.jl:_bennett_default
// (forward, copy-out, every forward gate replayed in reverse order).
//
// CONSTRUCTION. loops::lowerClassical(ctx, L, case) is called by the spine at L's header with the
// builder in a fresh block E (the loop entry; it runs once per activation of the loop).
//
//  Forward. The loop stays a classical loop over fresh output blocks. A quantum header phi becomes a
//  phi over handles (recordExternal, a kept role: it aliases the seed or the previous trip's rail and
//  is never resolved itself); a classical incoming becomes a seed rail allocated in E. The body is
//  walked in reverse post-order: a classical branch stays a classical branch, a quantum branch is
//  linearized (pred's lowerBranch / sw::lowerSwitch, the arms fall through, a quantum join is
//  pred's lowerMerge), a classical join of handles is a phi over handles (recordMerge, U1). Each
//  original non-phi instruction goes through the spine's lowerInstruction. A sub-loop (case 1 or
//  3) is lowered the same way inside its parent's trip, with no copy-out and no mirror of its own:
//  its reverse runs inside the parent's reverse trip (27, 139).
//  Case 3: the trip predicate a_{-1} is the flag of the header's quantum predicate (the loop sits in
//  an arm; the guard test re-rolled, 26) or a |1> seed; the exit test's quantum disjunct q gives
//  a_j = a_{j-1} & NOT q (as a_{j-1} ^ (a_{j-1} & q), for a positive q); every quantum carried value advances by
//  select(a_{j-1}, next, prev); a quantum value read after the loop that is no carried value's next
//  gets its own capture rail cap_j = select(a_{j-1}, v_j, cap_{j-1}); the loop branches on the
//  classical disjuncts only. Every body instruction is lowered under the trip rail a_{j-1}
//  (lowerInstruction's tripFlag, cq-99f7): a cq_theta / cq_phi in the trip is controlled by it. No predicate is kept: the mirror uncomputes every a_j, the last included.
//
//  Rule 6 on carried values (cq-b13w, outermost loop, Unit::planRuleSix). A carried value read only
//  by a chain of bijective updates in the header (the next value the chain's last rail, perhaps rotated
//  in place) cleans each old rail in its trip, the previous trip's register included, so the trip's
//  last rail is the register (kept, never mirrored nor copied out). Trip 0 cleans the initial rail: a
//  seed minted for the loop, this function's own rail when nothing reads it once the loop is entered
//  (lcw-h2 c2: the register before the loop), or else a copy of it. Case 3 cleans through the advancing
//  select (125). An unrotated chain is a register only when its final value is read after the loop.
//
//  Slot memory (rule 20, cq-sujx). A load or store of a slot object at a classical offset goes
//  through mem::lowerSlotLoad / lowerSlotStore once in the trip (the spine's dispatch): a cell loaded
//  per trip is an alias (kept, never undone), a register stored back changes nothing, a seed or
//  computed rail stored into a cell takes the role mem-slots gives it. The reverse undoes no memory:
//  the cells hold classical handles and every mirror operand is pushed. QRAM objects and fat pointers
//  in the trip are not built yet.
//
//  Per-trip uncompute (rule 5, as early as allowed). Before the reverse, each segment is flushed at
//  its terminator (Uncompute::flushBefore) with the region's back edges cut, so a rail made and last
//  read within one segment is undone in its own trip (60: the Toffoli flag of q[j] && q[i]); only a
//  path that re-executes the record could put another segment's gate between them. Rule 5's
//  invariant across trips: if the region has a non-diagonal gate (Ry, quantum-angle Ry) on a rail
//  that is not made by a record of the region, and the reverse loop still undoes anything, a later
//  trip's gate may touch a rail an earlier trip's record read: cq::unimplemented. Likewise (cq-vqid)
//  a non-diagonal gate on a rail that an item undone by the reverse loop reads (a merge read: each
//  arm), on a path after that item's forward record that does not make the rail again (later in
//  the same trip, or a later trip on a rail the trip does not remake): cq::unimplemented.
//
//  Deferred reverse (cq-fx3s, CR rule 14: 153, 178). A quantum value read after the outermost loop
//  whose exit rail is made by a record of the loop (a trip's template, a seed of the entry) is read in
//  place (no copy-out), and the reverse is an Uncompute deferred item (recordDeferred) placed after its
//  readers: the loop's exit block X branches to a fresh continuation, and the item, wherever Uncompute
//  places it, starts with a classical branch on "X was passed" (an SSA value: false at the function's
//  entry, true at X), so a path where the loop did not run (the zero-trip guard's skip edge, 178) skips
//  it; the values from before the region it reads are read through phis that name them where the loop
//  ran (poison elsewhere). A value whose exit rail is not the loop's own (an alias of a carried value, a
//  rail from before the loop) is still copied out first; with no deferred value the reverse runs at X.
//
//  Segments. Every forward output block is a segment with its own Uncompute scope (sequential, never
//  nested). After the outermost loop exits, each other quantum value read after the loop is copied out
//  (alloc + copy, Role::Output) and rebound to the copy; then the reverse runs: one reverse block
//  R(F) per segment F, holding emitMirror(scope of F), whose operands defined in the forward region
//  are replaced by pops; F pushes exactly those values before its terminator (i32 words, a wider
//  value low word first, §1.3), so every classical per-trip value is pushed rather than recomputed.
//  A segment with several predecessors pushes a come-from index first, and R(F) pops it last and
//  goes to the reverse of that predecessor: the reverse replays the forward path backwards (loop
//  headers included: come-from "entry" ends that loop's reverse). The reverse of the entry edge is
//  the block Z, where the seeds allocated in E are released (emitMirror of E's scope); the builder
//  is left at the end of Z, where the loop's exit block continues.
//
// Shapes that are not built yet stop with cq::unimplemented (the instruction printed): a loop with
// more than one exiting block or latch; a case-3 exit test not at the latch, with more than one
// quantum disjunct, or with a sub-loop or a memory write; a classical
// value read after a case-3 loop; calls other than classical, template intrinsics and the CQ.h
// surface; QRAM / fat-pointer memory accesses (187, 188: wave 2); a deferred record with a
// non-diagonal gate on a rail from outside its trip; a classical branch inside a quantum arm
// of the body; a quantum-exit loop nested in a classically bounded one; a body block whose
// classical factor (rule 8) the trip's path does not establish, a classical conjunct of a quantum arm
// condition (cq-pkjc: the trip builds no classical guard).
#include "cq/Loops.h"
#include "../cutoff/Exits.h"

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <tuple>
#include <vector>

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Aggregates.h"
#include "cq/FatPtr.h"
#include "cq/Memory.h"
#include "cq/Predicate.h"
#include "cq/Switch.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq::loops {

namespace {

// cq-r8-d (185): the SSA value at the end of `at` of a variable that is `v` at the end of block D and
// `dflt` at the entry (and at the end of `reset`, when given), with phis at the joins over the real predecessors. The construction is still
// filling its own phis' incomings when a deferred reverse is placed, and SSAUpdater reads a block's
// predecessors through its leading phi: an empty one hides them, and the value came out poison (a
// `br i1 poison` guard, a free of poison). Uncompute's carryTo, for the loop's guard and reads.
Value *carryTo(BasicBlock *at, BasicBlock *D, Value *v, Value *dflt, const Twine &name,
              BasicBlock *reset = nullptr) {
  DenseMap<BasicBlock *, Value *> memo;
  std::vector<PHINode *> made;
  std::function<Value *(BasicBlock *)> end = [&](BasicBlock *b) -> Value * {
    if (b == D)
      return v;
    if (b == reset)
      return dflt;
    if (auto it = memo.find(b); it != memo.end())
      return it->second;
    SmallVector<BasicBlock *, 4> ps(predecessors(b));
    if (ps.empty())
      return memo[b] = dflt;
    if (ps.size() == 1)
      return memo[b] = end(ps[0]);
    PHINode *phi = PHINode::Create(v->getType(), ps.size(), name);
    phi->insertInto(b, b->begin());
    memo[b] = phi;
    made.push_back(phi);
    for (BasicBlock *p : ps)
      phi->addIncoming(end(p), p);
    return phi;
  };
  Value *r = end(at);
  for (bool changed = true; changed;) {
    changed = false;
    for (PHINode *&phi : made) {
      if (!phi)
        continue;
      Value *same = nullptr;
      bool trivial = true;
      for (Value *in : phi->incoming_values()) {
        if (in == phi || in == same)
          continue;
        if (same) {
          trivial = false;
          break;
        }
        same = in;
      }
      if (!trivial || !same)
        continue;
      phi->replaceAllUsesWith(same);
      if (r == phi)
        r = same;
      phi->eraseFromParent();
      phi = nullptr;
      changed = true;
    }
  }
  return r;
}

// CR rule 2 through memory (M3): some load of S's object that S may reach measures the loaded value
// (directly or through a trunc to i1 / freeze view). mem-slots then gave S's rail Role::Measured at the
// store (Slots.cpp, measuredThroughMemory, which also requires the load's cell to may-alias S's); this is
// the same test coarsened to the object (and to overwrites through S's own pointer), so a rail it calls kept may still be garbage there (the reverse
// then frees it before a read names it: an internal error, never a wrong circuit).
bool measuredThroughMemory(LoweringContext &ctx, const StoreInst &S) {
  ArrayRef<ObjectId> mine = ctx.T.provenance(S.getPointerOperand(), ctx.S);
  auto measures = [](const Value *v) {
    SmallVector<const Value *, 4> work{v};
    SmallPtrSet<const Value *, 8> seen{v};
    while (!work.empty()) {
      const Value *x = work.pop_back_val();
      for (const User *u : x->users()) {
        if (auto *c = dyn_cast<CallInst>(u); c && c->getCalledFunction() &&
                                             c->getCalledFunction()->getName().starts_with("cq_measure_"))
          return true;
        bool view = isa<FreezeInst>(u) || (isa<TruncInst>(u) && cast<TruncInst>(u)->getDestTy()->isIntegerTy(1));
        if (view && seen.insert(u).second)
          work.push_back(u);
      }
    }
    return false;
  };
  // cq-lvx8: a path from S to the load on which no store through S's own pointer value comes first (while
  // the path has not re-executed a definition that pointer is computed from). mem-slots kills at every
  // store of exactly S's cell, a superset of these, so this test keeps every rail mem-slots keeps.
  SmallPtrSet<const Instruction *, 8> defs;
  {
    SmallVector<const Value *, 8> w{S.getPointerOperand()};
    while (!w.empty()) {
      const Value *v = w.pop_back_val();
      auto *I = dyn_cast<Instruction>(v);
      if (!I || !defs.insert(I).second)
        continue;
      if (isa<GetElementPtrInst>(I) || isa<CastInst>(I) || isa<BinaryOperator>(I))
        for (const Value *o : I->operands())
          w.push_back(o);
    }
  }
  auto hit = [&](const Instruction &X) {
    auto *L = dyn_cast<LoadInst>(&X);
    if (!L || !L->getPointerOperand()->getType()->isPointerTy())
      return false;
    bool shared = false;
    for (ObjectId o : ctx.T.provenance(L->getPointerOperand(), ctx.S))
      shared |= is_contained(mine, o);
    return shared && measures(L);
  };
  auto kill = [&](const Instruction &X) {
    auto *so = dyn_cast<StoreInst>(&X);
    return so && so != &S && so->getPointerOperand() == S.getPointerOperand() && !so->isVolatile() &&
           !so->isAtomic() && so->getValueOperand()->getType() == S.getValueOperand()->getType();
  };
  SmallVector<std::tuple<const BasicBlock *, BasicBlock::const_iterator, bool>, 16> work;
  std::set<std::pair<const BasicBlock *, bool>> seen;
  work.push_back({S.getParent(), std::next(S.getIterator()), true});
  while (!work.empty()) {
    auto [bb, it, fresh] = work.pop_back_val();
    bool stop = false;
    for (; it != bb->end(); ++it) {
      if (&*it == &S) {
        stop = true;
        break;
      }
      if (defs.count(&*it))
        fresh = false;
      if (hit(*it))
        return true;
      if (fresh && kill(*it)) {
        stop = true;
        break;
      }
    }
    if (stop)
      continue;
    for (const BasicBlock *n : successors(bb))
      if (seen.insert({n, fresh}).second)
        work.push_back({n, n->begin(), fresh});
  }
  return false;
}

bool samePred(const Pred &a, const Pred &b) { return (a & !b).isBottom() && (b & !a).isBottom(); }

// CR rule 6's bijections in y (the list of rule 6, but a select of updates and a controlled swap,
// which a carried value's single reader cannot be): add, sub, xor with an operand other than y, mul
// by an odd literal, fneg, bswap, fshl/fshr with y in both value slots. bitreverse has no template.
bool bijectiveIn(const Instruction &U, const Value *Y) {
  if (auto *bo = dyn_cast<BinaryOperator>(&U); bo && bo->getType()->isIntegerTy()) {
    Value *a0 = bo->getOperand(0), *a1 = bo->getOperand(1);
    if (a0 == a1 || (a0 != Y && a1 != Y))
      return false;
    auto opc = bo->getOpcode();
    if (opc == Instruction::Add || opc == Instruction::Sub || opc == Instruction::Xor)
      return true;
    if (opc == Instruction::Mul) {
      auto *k = dyn_cast<ConstantInt>(a0 == Y ? a1 : a0);
      return k && k->getValue()[0];
    }
    return false;
  }
  if (auto *un = dyn_cast<UnaryOperator>(&U))
    return un->getOpcode() == Instruction::FNeg && un->getOperand(0) == Y;
  if (auto *II = dyn_cast<IntrinsicInst>(&U)) {
    Intrinsic::ID id = II->getIntrinsicID();
    if (id == Intrinsic::bswap)
      return II->getArgOperand(0) == Y;
    if (id == Intrinsic::fshl || id == Intrinsic::fshr)
      return II->getArgOperand(0) == Y && II->getArgOperand(1) == Y && II->getArgOperand(2) != Y;
  }
  return false;
}

struct Inv {
  abi::TemplateSpec spec;
  SmallVector<Operand, 3> ops;
};

// The template spelling of an inverse (CR §1.2 shapes): binary "" / "hl" / "lh", a literal first
// operand of a commutative op swapped behind the rail.
Inv normalized(abi::TemplateSpec spec, SmallVector<Operand, 3> ops) {
  if (ops.size() == 2) {
    if (ops[0].handle && ops[1].handle) {
      spec.shape = "";
    } else if (ops[0].handle) {
      spec.shape = "hl";
    } else if (spec.op == "add" || spec.op == "xor" || spec.op == "mul") {
      std::swap(ops[0], ops[1]);
      spec.shape = "hl";
    } else {
      spec.shape = "lh";
    }
  } else if (ops.size() == 3) {
    std::string sh;
    bool all = true;
    for (const Operand &o : ops) {
      sh += o.handle ? 'q' : 'l';
      all &= o.handle;
    }
    spec.shape = all ? "" : sh;
  }
  return Inv{std::move(spec), std::move(ops)};
}

APInt oddInverse(const APInt &k) {
  APInt x(k.getBitWidth(), 1);
  for (int i = 0; i < 7; ++i)   // Newton: x <- x (2 - k x), doubling the correct bits
    x = x * (APInt(k.getBitWidth(), 2) - k * x);
  return x;
}

// The inverse of U = f(Y, z) in Y, read from yp (U's value): the template and its operands.
Inv inverseOf(LoweringContext &ctx, Instruction &U, const Value *Y, Operand yp) {
  if (!bijectiveIn(U, Y))
    internalError("loops-classical: rule 6 inverse of an update that is no bijection in the carried value", &U);
  abi::TemplateSpec spec;
  spec.w = railTypeOf(U.getType());
  if (auto *bo = dyn_cast<BinaryOperator>(&U)) {
    unsigned i = bo->getOperand(0) == Y ? 0 : 1;
    Value *Z = bo->getOperand(1 - i);
    switch (bo->getOpcode()) {
    case Instruction::Add:
      spec.op = "sub";
      return normalized(spec, {yp, ctx.operand(Z)});   // y = y' - z
    case Instruction::Xor:
      spec.op = "xor";
      return normalized(spec, {yp, ctx.operand(Z)});   // y = y' ^ z
    case Instruction::Sub:
      if (i == 0) {
        spec.op = "add";
        return normalized(spec, {yp, ctx.operand(Z)}); // y' = y - z: y = y' + z
      }
      spec.op = "sub";
      return normalized(spec, {ctx.operand(Z), yp});   // y' = z - y: y = z - y'
    default: {                                         // mul by an odd literal k: y = y' * k^-1
      auto *k = cast<ConstantInt>(Z);
      spec.op = "mul";
      return normalized(spec, {yp, Operand{ConstantInt::get(k->getType(), oddInverse(k->getValue())), false}});
    }
    }
  }
  if (isa<UnaryOperator>(U)) {
    spec.op = "fneg";
    return normalized(spec, {yp});
  }
  auto *II = cast<IntrinsicInst>(&U);
  if (II->getIntrinsicID() == Intrinsic::bswap) {
    spec.op = "bswap";   // an involution
    return normalized(spec, {yp});
  }
  spec.op = II->getIntrinsicID() == Intrinsic::fshl ? "fshr" : "fshl";   // a rotation's inverse
  return normalized(spec, {yp, yp, ctx.operand(II->getArgOperand(2))});
}

struct Disj {
  const Value *v;
  bool pos;   // the loop exits when v == pos
};

class Unit : public std::enable_shared_from_this<Unit> {
public:
  Unit(LoweringContext &ctx, Loop &top)
      : ctx(ctx), top(top), F(*top.getHeader()->getParent()), Mod(ctx.M), Out(ctx.out()), U(ctx.unc()) {
    ReversePostOrderTraversal<Function *> rpot(&F);
    for (BasicBlock *b : rpot)
      rpo.push_back(b);
  }

  void run(Case c);

private:
  LoweringContext &ctx;   // only while lowerClassical runs: a deferred reverse (cq-fx3s) uses Mod, Out, U
  Loop &top;
  Function &F;
  Module &Mod;
  Function &Out;
  Uncompute &U;
  std::vector<BasicBlock *> rpo;

  struct Seg {
    BasicBlock *bb;
    unsigned scope;
  };
  std::vector<Seg> segs;
  DenseMap<const BasicBlock *, unsigned> segIdx;
  bool segOpen = false;
  BasicBlock *cur = nullptr;   // the open output block, null after a real branch
  BasicBlock *E = nullptr;     // the outermost loop's entry block (outside the region)
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, BasicBlock *> edgeFrom;
  DenseMap<const BasicBlock *, BasicBlock *> obMap;
  std::vector<Value *> externalInits;   // handles defined outside the region read through header phis
  std::vector<std::pair<BasicBlock *, BasicBlock *>> heads;   // every loop's output header H and its entry block

  // Trip-local sub-loops (CR rules 5, 14; 176): a classically bounded sub-loop whose quantum values read
  // after it die within the parent's trip is its own unit, with its own reverse loop placed in the
  // parent's trip after the readers of its exit values (the deferred reverse of cq-fx3s, one per trip).
  // nested: this unit is such a sub-loop; resetAt: the parent's output header (where "the sub-loop ran"
  // is false again). The parent finishes it (flushTrips, the deferred item) inside its own flushTrips,
  // after flushing the segment the sub-loop is entered from.
  bool nested = false;
  BasicBlock *resetAt = nullptr;
  Value *outerTrip = nullptr;
  bool deferred = false;   // the outermost loop's reverse is an Uncompute deferred item   // while a sub-loop of a case-3 trip is walked: that trip's rail a_{j-1}
  bool reversed = false;
  BasicBlock *revAt = nullptr;   // where this unit's reverse begins (a trip-local sub-loop: inside the parent's trip)
  std::function<void()> finish;
  unsigned ownSeedScope = ~0u;
  std::vector<unsigned> hostScopes;   // the enclosing units' scopes (Uncompute F2)
  struct Sub {
    std::shared_ptr<Unit> unit;
    unsigned entrySeg;
    BasicBlock *cont;   // the sub-unit's continuation (its forward exit into the parent)
  };
  std::vector<Sub> subs;
  DenseMap<const BasicBlock *, BasicBlock *> throughSub;   // a sub-unit's continuation -> the parent segment entering it
  DenseSet<const BasicBlock *> subBlocks;                  // the blocks of the sub-units' regions
  std::vector<std::pair<Instruction *, unsigned>> entering;   // per segment, an entering edge (flushTrips)
  bool tripLocal(Loop &sl, Loop &L);
  // The seeds minted for classical incomings of phis of handles, per (phi, edge source), and a mixed
  // join's value per real edge: shared by the walks of a loop and its sub-loops (a sub-loop's exit edge
  // enters a block of its parent).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> edgeSeedM, edgeValM;

  bool isQ(const Value *v) {
    if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      return false;
    return ctx.T.isQuantum(v, ctx.S);
  }
  Pred qp(const BasicBlock *b) { return ctx.preds().block(b).quantumPart(ctx.T, ctx.S); }
  // Rule 8 / P1 (cq-pkjc): the classical facts the output path into the block being walked
  // establishes, and those of every walked original block.
  Pred curFact = Pred::top();
  DenseMap<const BasicBlock *, Pred> factOf;
  Pred cfOf(const Pred &p) { return p.isBottom() ? Pred::top() : p.classicalFactor(ctx.T, ctx.S); }
  // The classical factor of b's predicate must hold wherever b's code runs: the trip builds no
  // classical guard, so a factor the path does not establish (a classical conjunct of a quantum arm's
  // condition, select(i != 0, q, false)) would run the arm, a slot load at its classical offset
  // included, outside its classical domain and drop the conjunct from every control.
  void requireFact(const BasicBlock *b) {
    if (!(curFact & !cfOf(ctx.preds().block(b))).isBottom())
      unimplemented("loops-classical: a block of a classically bounded loop body whose classical guard (rule 8: "
                    "the classical factor of its predicate, a classical conjunct of a quantum arm condition) the "
                    "trip does not establish (a classical guard inside a trip is not built yet)",
                    &*b->getFirstNonPHIOrDbg());
    factOf[b] = curFact;
  }

  BasicBlock *newBlock() { return BasicBlock::Create(Mod.getContext(), "", &Out); }
  BasicBlock *ob(const BasicBlock *b) {
    auto it = obMap.find(b);
    if (it != obMap.end())
      return it->second;
    return obMap[b] = newBlock();
  }

  void closeSeg() {
    if (segOpen)
      ctx.unc().closeScope(segs.back().scope);
    segOpen = false;
  }
  void startSeg(BasicBlock *bb) {
    closeSeg();
    segIdx[bb] = segs.size();
    segs.push_back({bb, ctx.unc().openScope()});
    segOpen = true;
    cur = bb;
    ctx.B().SetInsertPoint(bb);
  }

  Value *seed(Value *classical, RailType w) {
    CallInst *call = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {classical});
    ctx.unc().recordSeed(call);
    return call;
  }
  Value *asHandle(Operand o, Type *ty) {
    if (o.handle)
      return o.v;
    return seed(o.v, railTypeOf(ty));
  }
  Value *select(Value *cond, Operand t, Operand f, RailType w) {
    abi::TemplateSpec spec;
    spec.op = "select";
    spec.w = w;
    std::string shape = std::string(t.handle ? "h" : "l") + (f.handle ? "h" : "l");
    spec.shape = shape == "hh" ? "" : shape;
    return ctx.emitTemplate(spec, {Operand{cond, true}, t, f});
  }
  void gate(abi::Core op, ArrayRef<Value *> args) {
    abi::CoreSpec spec{op, RailType{Kind::Int, 1}};
    CallInst *call = ctx.emitCore(spec, args);
    SmallVector<Operand, 3> ops;
    for (Value *a : args)
      ops.push_back(Operand{a, true});
    ctx.unc().recordCore(call, spec, ops, ctx.unc().idOf(args.back()));
  }

  void check(Loop &L, Case c);
  bool twinOf(const CallBase &CB) const;
  void resolvePreheader();

  // CR rule 6 on a carried value (cq-b13w). A quantum header phi p read only by a chain of updates
  // U_1 = f_1(p, z_1), U_2 = f_2(U_1, z_2), ... in the header, each a bijection in its predecessor and
  // its predecessor's only reader (so no z_i reads p), whose next value is the last U or it rotated in
  // place (cq_theta chain), is cleaned in its trip: each old rail (U_{i-1}; p's, which is the previous
  // trip's last U or the initial value in trip 0) is recomputed by t = f_i^-1(U_i, z_i) and cleaned
  // (Uncompute::cleanupBijective), so the trip's last U is the carried register itself (kept, never
  // undone by the reverse loop, never copied out). Case 3 asks the same of the select advancing it:
  // y'' = a ? F(y) : y, t = a ? F^-1(y'') : y'' (125), the trip-local U_i uncomputed first.
  // A garbage U (no rotation) is a register only when the loop's final value is read after the
  // loop: else rule 5 uncomputes the whole chain and the old value is never dead (rule 6, 42).
  struct R6 {
    PHINode *p;
    SmallVector<Instruction *, 2> U;   // the update chain, U.back() the next value's rail
    bool rotated;
    bool initDirect;   // the initial rail is this function's own and dead after the loop entry: trip 0 cleans it
  };
  std::vector<R6> plan6;
  DenseSet<const Value *> keptFinal;   // the final rails of cleaned chains: read after the loop in place
  const R6 *r6Of(const PHINode *p) const {
    for (const R6 &r : plan6)
      if (r.p == p)
        return &r;
    return nullptr;
  }
  void planRuleSix(Loop &L, Case c);
  bool initDead(Loop &L, const Value *init, const PHINode *p);
  void disjuncts(const Value *v, bool pos, SmallVectorImpl<Disj> &out, SmallPtrSetImpl<const Value *> &inner);
  // Lowers L with the builder at `cur`; its exit edge goes to T. Returns the exit operand of every
  // value of L read after it (quantum ones only).
  std::vector<std::pair<const Value *, Operand>> lowerLoop(Loop &L, Case c, BasicBlock *T, bool outermost);
  void flushTrips();
  // The reverse from B's block (unterminated); leaves B at the end of an unterminated block. guarded:
  // B's block may be reached on a path where the loop did not run (cq-fx3s): branch around on that.
  void reverse(IRBuilder<> &B, BasicBlock *X, unsigned seedScope, bool guarded);
};

void Unit::disjuncts(const Value *c, bool positive, SmallVectorImpl<Disj> &out,
                     SmallPtrSetImpl<const Value *> &inner) {
  // cq-bea6 (as the spine's loops::classify, cq-dtvp): select c, t, true is !c | t, select c, false, f
  // is !c & f (the condition enters negated), and xor x, true is !x; -O1 writes `i + 1 >= n || q` as
  // select(i + 1 < n, q, true).
  const Value *a = nullptr, *b = nullptr;
  bool isOr = false, isAnd = false, negA = false;
  auto isTrue = [](const Value *v) {
    auto *k = dyn_cast<ConstantInt>(v);
    return k && k->isOne();
  };
  auto isFalse = [](const Value *v) {
    auto *k = dyn_cast<ConstantInt>(v);
    return k && k->isZero();
  };
  if (auto *bo = dyn_cast<BinaryOperator>(c); bo && bo->getType()->isIntegerTy(1)) {
    if (bo->getOpcode() == Instruction::Or) { isOr = true; a = bo->getOperand(0); b = bo->getOperand(1); }
    if (bo->getOpcode() == Instruction::And) { isAnd = true; a = bo->getOperand(0); b = bo->getOperand(1); }
    if (bo->getOpcode() == Instruction::Xor)
      for (unsigned i = 0; i < 2; ++i)
        if (isTrue(bo->getOperand(i))) {
          inner.insert(c);
          return disjuncts(bo->getOperand(1 - i), !positive, out, inner);
        }
  } else if (auto *sel = dyn_cast<SelectInst>(c); sel && sel->getType()->isIntegerTy(1)) {
    const Value *t = sel->getTrueValue(), *f = sel->getFalseValue();
    if (isTrue(t)) {
      isOr = true; a = sel->getCondition(); b = f;
    } else if (isFalse(f)) {
      isAnd = true; a = sel->getCondition(); b = t;
    } else if (isTrue(f)) {
      isOr = true; negA = true; a = sel->getCondition(); b = t;
    } else if (isFalse(t)) {
      isAnd = true; negA = true; a = sel->getCondition(); b = f;
    }
  }
  if ((isOr && positive) || (isAnd && !positive)) {
    inner.insert(c);
    disjuncts(a, negA ? !positive : positive, out, inner);
    disjuncts(b, positive, out, inner);
    return;
  }
  out.push_back({c, positive});
}

// Is the initial value of p a rail this function made for itself (a template result, or a classical
// value cq_theta minted, rotated in place any number of times) that nothing reads once the loop is
// entered? Its readers other than p and its own rotations must be phi incomings on edges no path
// from the loop reaches (the zero-trip edge of the loop's guard).
bool Unit::initDead(Loop &L, const Value *init, const PHINode *p) {
  if (!isQ(init))
    return true;   // a seed minted for the loop
  SmallVector<const Instruction *, 4> A;
  for (const Value *x = init;;) {
    auto *I = dyn_cast<Instruction>(x);
    if (!I)
      return false;
    A.push_back(I);
    if (auto *CB = dyn_cast<CallInst>(I); CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Theta) {
      if (isQ(CB->getArgOperand(1)))
        return false;
      x = CB->getArgOperand(0);
      if (!isQ(x))
        break;   // minted by this cq_theta
      continue;
    }
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I))
      break;
    return false;
  }
  DenseSet<const BasicBlock *> reach;
  SmallVector<const BasicBlock *, 16> work{L.getHeader()};
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (!reach.insert(b).second)
      continue;
    for (const BasicBlock *s : successors(b))
      work.push_back(s);
  }
  for (const Instruction *a : A)
    for (const Use &u : a->uses()) {
      const User *usr = u.getUser();
      if (usr == p || is_contained(A, usr))
        continue;
      auto *phi = dyn_cast<PHINode>(usr);
      if (!phi || reach.count(phi->getIncomingBlock(u)))
        return false;
    }
  return true;
}

void Unit::planRuleSix(Loop &L, Case c) {
  BasicBlock *header = L.getHeader(), *latch = L.getLoopLatch(), *pre = L.getLoopPredecessor();
  if (exits::liveExiting(L) != latch)
    return;   // a trip may end before the update: the exit value is not the chain's
  const bool c3 = c == Case::ClassicalBoundQuantumExit;
  if (!c3 && !qp(header).isTop())
    return;
  for (PHINode &p : header->phis()) {
    if (!isQ(&p) || !(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()) || !p.hasOneUse())
      continue;
    // The next value: the last update, or it rotated in place by unconditional cq_theta calls with
    // classical angles.
    SmallVector<const Instruction *, 4> chain;
    const Value *nx = p.getIncomingValueForBlock(latch);
    bool rotated = false, ok = true;
    while (auto *CB = dyn_cast<CallInst>(nx)) {
      if (calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Theta)
        break;
      nx = CB->getArgOperand(0);
    }
    SmallVector<Instruction *, 2> ups;
    for (const Value *x = &p;;) {
      if (!x->hasOneUse()) {
        ok = false;
        break;
      }
      auto *W = dyn_cast<Instruction>(const_cast<User *>(*x->user_begin()));
      if (!W || W->getParent() != header || !bijectiveIn(*W, x) || !isQ(W)) {
        ok = false;
        break;
      }
      ups.push_back(W);
      if (W == nx)
        break;
      x = W;
    }
    if (!ok)
      continue;
    Instruction *U = ups.back();
    nx = p.getIncomingValueForBlock(latch);
    while (nx != U) {
      auto *CB = dyn_cast<CallInst>(nx);
      if (!CB || !L.contains(CB) || calls::classify(*CB, ctx.T, ctx.S) != calls::Class::Theta ||
          isQ(CB->getArgOperand(1)) || !samePred(qp(CB->getParent()), qp(header))) {
        ok = false;
        break;
      }
      chain.push_back(CB);
      rotated = true;
      nx = CB->getArgOperand(0);
    }
    if (!ok || (c3 && rotated))
      continue;
    chain.push_back(U);
    // Nothing else in the loop reads the chain (the clean-up of the next trip frees it); a reader after
    // the loop reads the final rail.
    bool live = false;
    for (const Instruction *x : chain)
      for (const User *usr : x->users()) {
        if (usr == &p || is_contained(chain, usr))
          continue;
        auto *ui = dyn_cast<Instruction>(usr);
        if (!ui || L.contains(ui))
          ok = false;
        else
          live = true;
      }
    if (!ok || (!rotated && !live))
      continue;
    plan6.push_back({&p, ups, rotated, initDead(L, p.getIncomingValueForBlock(pre), &p)});
  }
}

// A clone call that has a twin (U2): a quantum result field, or a caller cell it stores a handle into.
// A sub-loop sl of L (case 1) is trip-local when the quantum values of sl read after it are read, through
// their forward slice, only by instructions of L's trip outside every sub-loop of L (no header phi of L,
// no store, no call, nothing after L), sl writes no quantum value to memory, makes no non-diagonal gate
// and calls nothing but the CQ.h surface: its rails are dead before the trip ends, so its reverse runs in
// the trip, before any later gate of the trip on the rails it read (rule 5; 176's value(x) loops before
// A^dag / A).
bool Unit::tripLocal(Loop &sl, Loop &L) {
  if (!qp(sl.getHeader()).isTop() || !sl.getSubLoops().empty())
    return false;
  bool any = false;
  for (BasicBlock *b : sl.blocks())
    for (Instruction &I : *b) {
      if (auto *si = dyn_cast<StoreInst>(&I); si && isQ(si->getValueOperand()))
        return false;
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        if (isa<DbgInfoIntrinsic>(CB))
          continue;
        calls::Class k = calls::classify(*CB, ctx.T, ctx.S);
        if (k != calls::Class::Classical && k != calls::Class::TemplateIntrinsic && k != calls::Class::Phi)
          return false;
        if (k == calls::Class::Classical && CB->mayWriteToMemory())
          return false;
      }
      if (!isQ(&I))
        continue;
      SmallVector<const Instruction *, 8> work;
      SmallPtrSet<const Instruction *, 16> seen;
      for (const User *u : I.users())
        if (auto *ui = dyn_cast<Instruction>(u); ui && !sl.contains(ui))
          work.push_back(ui);
      while (!work.empty()) {
        const Instruction *x = work.pop_back_val();
        if (!seen.insert(x).second)
          continue;
        any = true;
        if (!L.contains(x) || (x->getParent() == L.getHeader() && isa<PHINode>(x)) || isa<StoreInst>(x) ||
            isa<CallBase>(x) || isa<ReturnInst>(x))
          return false;
        for (Loop *o : L.getSubLoops())
          if (o->contains(x))
            return false;
        if (x->isTerminator())
          continue;
        for (const User *u : x->users())
          if (auto *ui = dyn_cast<Instruction>(u))
            work.push_back(ui);
      }
    }
  return any;
}

bool Unit::twinOf(const CallBase &CB) const {
  const Specialization *S = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!S)
    return true;
  if (!CB.getType()->isVoidTy() && is_contained(ctx.T.fieldMask(&CB, ctx.S), true))
    return true;
  for (unsigned i = 0; i < CB.arg_size(); ++i)
    if (CB.getArgOperand(i)->getType()->isPointerTy())
      for (unsigned c : ctx.T.cellsWritten(*S, i))
        if (ctx.T.cellForward(*S, i, c) < 0)
          return true;   // a minted slot result (T5: a forwarded formal's handle is none)
  return false;
}

void Unit::check(Loop &L, Case c) {
  if (!L.getLoopPredecessor())
    unimplemented("loops-classical: a rule-14 loop whose header has more than one predecessor outside the loop",
                  L.getHeader()->getTerminator());
  if (!L.getLoopLatch())
    unimplemented("loops-classical: a rule-14 loop with more than one latch", L.getHeader()->getTerminator());
  // An exit into an effect-free dead end (131's unreachable switch default) is UB to take: no exit. A
  // case-3 loop with several exits (121) is lowerLoop's multi-exit form.
  if (c != Case::ClassicalBoundQuantumExit && (!exits::liveExiting(L) || !exits::liveExit(L)))
    unimplemented("loops-classical: a rule-14 loop with more than one exiting block or exit block",
                  L.getHeader()->getTerminator());
  for (PHINode &p : L.getHeader()->phis())
    if (isQ(&p) && !(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()))
      unimplemented("loops-classical: a quantum carried value of non-scalar type (aggr, fatptr)", &p);
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b) {
      if (isa<DbgInfoIntrinsic>(I))
        continue;
      // CR rule 20: a store in a case-3 trip runs under the trip rail, a quantum predicate (a select into a
      // fresh rail, rule 9). mem decides "under a quantum predicate" by currentPredicate(), which does not
      // see the trip (cq-hmv1): it would store unconditionally in every trip, after the quantum exit too.
      if (c == Case::ClassicalBoundQuantumExit && I.mayWriteToMemory() && !isa<CallBase>(I))
        unimplemented("loops-classical: a memory write in a case-3 trip (blocked on cq-k471: mem lowers a store "
                      "under the trip rail as unconditional)",
                      &I);
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        calls::Class k = calls::classify(*CB, ctx.T, ctx.S);
        switch (k) {
        case calls::Class::Classical:
        case calls::Class::TemplateIntrinsic:
          break;
        case calls::Class::Theta:
        case calls::Class::Measure:
        case calls::Class::Phi:
          break;   // case 3: under the trip rail (lowerInstruction's tripFlag, cq-99f7)
        case calls::Class::Lift:
          // Rule 18 inside a rule-14 trip (124): a clone call with nothing to undo (no quantum result, no
          // caller cell it writes) records no call item, so each trip's call is a gate sequence of its own.
          // One with a twin (a result or a written cell: the reverse would have to replay the twin) is not
          // built yet.
          if (c != Case::ClassicalBoundQuantumExit && !twinOf(*CB))
            break;
          [[fallthrough]];
        default:
          unimplemented("loops-classical: a call of this class inside a rule-14 loop (calls-loops / loops-mem "
                        "integration)",
                        &I);
        }
        continue;
      }
      // Rule 20 slot cells at classical offsets go through mem-slots per trip (cq-sujx); a fat pointer
      // (rule 21) or a QRAM object (rule 20, 187, 188) in the trip is not built yet.
      if (isa<LoadInst>(I) || isa<StoreInst>(I)) {
        const Value *ptr = getLoadStorePointerOperand(&I);
        bool isStore = isa<StoreInst>(I);
        ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
        // Rule 14 case 1 with rule 20 (72, 188): a QRAM or QROM access of one object in the trip goes through
        // mem-qram per trip (a quantum offset included); its POP and un-copy are mirrored by the reverse
        // loop with pushed operands (F1b). A pointer of one QRAM object at a quantum offset carries offset
        // lanes only (no quantum tag: the spine routes it to mem-qram); a fat pointer over several objects
        // (rule 21) is not built.
        bool qram = objs.size() == 1 && ctx.T.classOf(objs.front()) == ObjClass::Qram;
        bool qrom = !isStore && objs.size() == 1 && ctx.T.classOf(objs.front()) == ObjClass::Classical && isQ(ptr) &&
                    isa<GlobalVariable>(getUnderlyingObject(ptr)) &&
                    cast<GlobalVariable>(getUnderlyingObject(ptr))->isConstant();
        if (c == Case::ClassicalBoundQuantumExit && (qram || qrom))
          unimplemented(std::string("loops-classical: a QRAM or QROM access in a case-3 loop"), &I);
        if ((ctx.T.isFatPointer(ptr, ctx.S) || isQ(ptr)) && !qram && !qrom)
          unimplemented(std::string("loops-classical: a ") + (isStore ? "store" : "load") +
                            " through a quantum (fat) pointer in a classically bounded loop (rule 21)",
                        &I);
        continue;
      }
      if (I.mayWriteToMemory() && (isQ(&I) || any_of(I.operands(), [&](const Use &u) { return isQ(u.get()); })))
        unimplemented("loops-classical: a quantum memory effect in a classically bounded loop", &I);
    }
}

std::vector<std::pair<const Value *, Operand>> Unit::lowerLoop(Loop &L, Case c, BasicBlock *T, bool outermost) {
  check(L, c);
  const bool c3 = c == Case::ClassicalBoundQuantumExit;
  BasicBlock *header = L.getHeader(), *pre = L.getLoopPredecessor(), *latch = L.getLoopLatch();
  BasicBlock *exitB = exits::liveExit(L);

  // CASE-3 MULTI-EXIT form (121: `n < cap && s[n] != 0`; strcmp's two quantum tests): quantum exits
  // leave from blocks before the latch, the latch's test is the classical bound. Each quantum exit edge
  // u -> x of a trip is taken under e = a & f, f the flag of u's quantum predicate & the exit condition;
  // the trip goes on under a' = a & NOT f (a ^ (a & f): gates on fresh rails only, so the mirror's undo
  // reads f as the forward did). The exit arm (Exits.h; pure instructions only) is computed in the trip,
  // under the OR of its exit edges' e; each phi P of the continuation C carries a capture rail cap =
  // select(g, v, cap) per unit edge into C (g its e or its arm block's flag), and the latch's classical
  // exit edge gives res = select(a, v_latch, cap), the trip's value of P were the bound reached now: the
  // last trip's res is P's exit value (the reference 121's r_i chain and its final select). Every rail is
  // a record of its trip, uncomputed by the mirror (nothing kept, case 3). The walker joins P with a
  // classical skip edge of the loop (its zero-trip guard) itself.
  exits::Unit UX = exits::unitOf(L);
  const bool mx = c3 && (UX.multi() || exits::liveExiting(L) != latch);
  if (mx && !outermost)
    unimplemented("loops-classical: a nested case-3 loop with several exits", header->getTerminator());
  if (!mx && (!exits::liveExiting(L) || !exitB))
    unimplemented("loops-classical: a rule-14 loop with more than one exiting block or exit block",
                  header->getTerminator());
  if (c3 && !mx && exits::liveExiting(L) != latch)
    unimplemented("loops-classical: a quantum exit test that is not the latch's (rule 14 case 3)",
                  exits::liveExiting(L)->getTerminator());
  auto inUnit = [&](const BasicBlock *b) { return UX.contains(L, b); };

  // Values of L read after it. Multi-exit (cq-nqa6, 117's is_marked): a scalar loop value read by a
  // non-phi in C or a block C dominates is the exit value of the trip that left, as a phi of C with that
  // value on every unit edge into C would be (SSA: the value dominates C, so each unit edge into C
  // carries its latest trip's value); it is a capture of its own (xreads), bound after the loop.
  std::unique_ptr<DominatorTree> mxDT = mx ? std::make_unique<DominatorTree>(*header->getParent()) : nullptr;
  std::vector<const Instruction *> liveOut, xreads;
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b)
      for (const Use &us : I.uses())
        if (auto *ui = dyn_cast<Instruction>(us.getUser()); ui && !L.contains(ui)) {
          if (mx) {
            auto *phi = dyn_cast<PHINode>(ui);
            if (UX.contains(L, ui->getParent()) ||
                (phi && phi->getParent() == UX.cont && inUnit(phi->getIncomingBlock(us))))
              continue;   // read by the exit arm or by C's phi on a unit edge
            if (!phi && mxDT->dominates(UX.cont, ui->getParent()) &&
                (I.getType()->isIntegerTy() || I.getType()->isFloatingPointTy())) {
              if (!is_contained(xreads, &I))
                xreads.push_back(&I);
              continue;
            }
            unimplemented("loops-classical: a value of a multi-exit case-3 loop read after it other than by a "
                          "phi of its continuation or a scalar read C dominates",
                          &I);
          }
          liveOut.push_back(&I);
          break;
        }
  // Multi-exit: the latch, the exit arm, the phis of C.
  struct CPhi {
    PHINode *P;                     // a phi of C, or nullptr for a read after the loop (xreads)
    const Instruction *x = nullptr; // that read's loop value: its incoming on every unit edge into C
    PHINode *cap = nullptr;         // the carried capture rail
    Value *res = nullptr;           // this trip's res
    const Value *orig() const { return P ? static_cast<const Value *>(P) : x; }
    Type *type() const { return orig()->getType(); }
    // The unit edges into C and their values.
    SmallVector<std::pair<BasicBlock *, const Value *>, 4> incomings(const std::function<bool(const BasicBlock *)> &in,
                                                                     BasicBlock *C) const {
      SmallVector<std::pair<BasicBlock *, const Value *>, 4> r;
      if (P) {
        for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
          if (in(P->getIncomingBlock(i)))
            r.push_back({P->getIncomingBlock(i), P->getIncomingValue(i)});
      } else {
        for (BasicBlock *u : predecessors(C))
          if (in(u) && none_of(r, [&](const auto &e) { return e.first == u; }))
            r.push_back({u, x});
      }
      return r;
    }
  };
  std::vector<CPhi> cphis;
  DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> exitFlag;   // quantum exit edge -> e
  // Multi-exit: the one block whose classical test leaves the loop (the bound): the latch (121), or the
  // header with the quantum exit at the latch (cq-nqa6, 117's is_marked: `k + 1 == n` at the header,
  // `v == m[k + 1]` at the latch). Its exit edge gives res; it enters C directly.
  BasicBlock *cxb = nullptr;
  if (mx) {
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    for (BasicBlock *u : exiting) {
      if (none_of(successors(u), [&](BasicBlock *s) { return !L.contains(s) && is_contained(UX.live, s); }))
        continue;   // only into dead ends (UB to reach)
      auto *br = dyn_cast<BranchInst>(u->getTerminator());
      if (br && br->isConditional() && isQ(br->getCondition()))
        continue;
      if (cxb)
        unimplemented("loops-classical: a multi-exit case-3 loop with more than one classical exit test",
                      u->getTerminator());
      cxb = u;
    }
    if (cxb && cxb != latch && cxb != header)
      unimplemented("loops-classical: a multi-exit case-3 loop whose classical exit test is neither its latch's nor "
                    "its header's",
                    cxb->getTerminator());
    auto *lbr = dyn_cast<BranchInst>(latch->getTerminator());
    if (!lbr)
      unimplemented("loops-classical: a multi-exit case-3 loop whose latch test is quantum", latch->getTerminator());
    if (lbr->isConditional() && isQ(lbr->getCondition()) &&
        !(cxb == header && cxb != latch && L.contains(lbr->getSuccessor(0)) != L.contains(lbr->getSuccessor(1))))
      unimplemented("loops-classical: a multi-exit case-3 loop whose latch test is quantum (other than its quantum exit "
                    "with the classical bound tested at the header)",
                    latch->getTerminator());
    if (cxb)
      for (BasicBlock *x : successors(cxb))
        if (!L.contains(x) && x != UX.cont && is_contained(UX.live, x))
          unimplemented("loops-classical: a multi-exit case-3 loop whose classical exit enters its exit arm",
                        cxb->getTerminator());
    for (BasicBlock *a : UX.arm)
      for (Instruction &I : *a) {
        if (isa<PHINode>(I))
          unimplemented("loops-classical: a phi in a case-3 loop's exit arm", &I);
        if (auto *br = dyn_cast<BranchInst>(&I); br && !br->isConditional())
          continue;
        if (I.isTerminator())
          unimplemented("loops-classical: a branch inside a case-3 loop's exit arm", &I);
        if (auto *II = dyn_cast<IntrinsicInst>(&I); II && (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II)))
          continue;
        if (isa<CallBase>(I) || I.mayHaveSideEffects() || I.mayWriteToMemory())
          unimplemented("loops-classical: an effect in a case-3 loop's exit arm", &I);
        for (const Use &us : I.uses())
          if (auto *ui = cast<Instruction>(us.getUser()); !inUnit(ui->getParent()) &&
                                                         !(isa<PHINode>(ui) && ui->getParent() == UX.cont))
            unimplemented("loops-classical: a value of a case-3 loop's exit arm read after the loop other than by a "
                          "phi of its continuation",
                          &I);
      }
    const Pred hb = ctx.preds().block(header);
    for (PHINode &P : UX.cont->phis()) {
      bool fromUnit = any_of(P.blocks(), [&](const BasicBlock *u) { return inUnit(u); });
      if (!fromUnit)
        continue;
      if (!isQ(&P) || !(P.getType()->isIntegerTy() || P.getType()->isFloatingPointTy()))
        unimplemented("loops-classical: a classical or non-scalar phi joining a case-3 loop's exits", &P);
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
        if (!inUnit(P.getIncomingBlock(i)) && !(ctx.preds().edge(P.getIncomingBlock(i), UX.cont) & hb).isBottom())
          unimplemented("loops-classical: a phi joining a case-3 loop's exits with an incoming from outside the loop "
                        "on an edge that does not exclude the loop",
                        &P);
      cphis.push_back({&P});
    }
    for (const Instruction *x : xreads)
      cphis.push_back({nullptr, x});
  }

  // Case 3: the exit test.
  SmallVector<Disj, 4> ds;
  SmallPtrSet<const Value *, 8> skip;
  // The quantum disjuncts: one leaf q (exit when q == qPos), or several, whose disjunction qExitP is one
  // flag (rule 8: a disjunction of flags is or_i1).
  const Value *qLeaf = nullptr;
  bool qPos = false;
  Pred qExitP = Pred::bottom();
  unsigned nQ = 0;
  if (c3 && !mx) {
    auto *br = dyn_cast<BranchInst>(latch->getTerminator());
    if (!br || !br->isConditional() || !isQ(br->getCondition()))
      internalError("loops-classical: a case-3 loop whose latch is no quantum conditional branch",
                    latch->getTerminator());
    bool exitOnTrue = !L.contains(br->getSuccessor(0));
    disjuncts(br->getCondition(), exitOnTrue, ds, skip);
    bool anyClassical = false;
    for (const Disj &d : ds) {
      if (!isQ(d.v)) {
        anyClassical = true;
        continue;
      }
      qExitP = qExitP | (d.pos ? Pred::atom(d.v) : !Pred::atom(d.v));
      ++nQ;
      qLeaf = d.v;
      qPos = d.pos;
    }
    if (!anyClassical || !qLeaf)
      internalError("loops-classical: a case-3 exit test without a classical and a quantum disjunct", br);
    // An inner node of the test is not lowered when nothing but the test reads it.
    for (bool changed = true; changed;) {
      changed = false;
      for (const Value *n : SmallVector<const Value *, 8>(skip.begin(), skip.end()))
        for (const User *u : n->users())
          if (u != br && !skip.count(u)) {
            skip.erase(n);
            changed = true;
            break;
          }
    }
    for (const Instruction *v : liveOut)
      if (!isQ(v))
        unimplemented("awaiting owner ruling: SPEC_ISSUES rule 14 case 3: a classical value read after a "
                      "classically bounded loop with a quantum exit (its exit value depends on the quantum exit)",
                      v);
  }

  plan6.clear();
  if (outermost)
    planRuleSix(L, c);

  // Entry: the trip predicate, the seeds.
  unsigned seedScope = 0;
  Value *aInit = nullptr;
  if (outermost)
    ownSeedScope = seedScope = ctx.unc().openScope();
  // a_{-1} is minted inside the outermost loop's seed scope, so Z tears it down after the reverse (cq-t71u): under
  // a classical guard its definition does not dominate the return and no exit flush could free it. An atom rail
  // flag() returns has no record in the scope and is untouched.
  if (c3) {
    Pred hp = qp(header);
    if (!hp.isTop())
      aInit = ctx.preds().flag(ctx, hp);
  }
  // CR rule 14 (`continue`, `return` inside a K-loop, nested loops: "same chain, inner chain seeded by the
  // outer trip predicate"): a case-3 loop nested in a case-3 trip seeds its chain with the outer trip rail
  // (and its header's arm flag): a_{-1} = a_outer & F, a fresh rail (gates on fresh rails only).
  if (c3 && outerTrip) {
    if (!aInit) {
      aInit = outerTrip;
    } else {
      Value *both = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::AndI1, {outerTrip, aInit, both});
      aInit = both;
    }
  }
  if (c3 && !aInit)
    aInit = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
  else if (aInit && outermost)
    externalInits.push_back(aInit);
  BasicBlock *entryFrom = cur;
  struct Carried {
    PHINode *orig;
    PHINode *np;
    bool q;
  };
  std::vector<Carried> carried;
  std::vector<std::pair<Value *, bool>> inits;
  for (PHINode &p : header->phis()) {
    Operand o = ctx.operand(p.getIncomingValueForBlock(pre));
    bool q = isQ(&p);
    if (const R6 *r = q ? r6Of(&p) : nullptr) {
      // Trip 0 cleans the rail its phi names: a fresh seed, this function's own dead rail, or else a
      // copy of the initial value (which then stays as it is, as in straight-line code). Each is kept
      // for Uncompute: the trip's clean-up frees it.
      Value *h;
      if (!o.handle) {
        h = asHandle(o, p.getType());
      } else if (r->initDirect) {
        h = o.v;
      } else {
        RailType w = railTypeOf(p.getType());
        CallInst *c0 = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                    {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
        CallInst *cc = ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {o.v, c0});
        ctx.unc().noteUse(ctx.unc().idOf(o.v), cc);
        ctx.unc().recordExternal(c0, Role::UserRegister);
        h = c0;
      }
      ctx.unc().setRole(ctx.unc().idOf(h), Role::UserRegister);
      inits.push_back({h, true});
    } else if (q) {
      Value *h = asHandle(o, p.getType());
      if (o.handle && outermost)
        externalInits.push_back(h);
      inits.push_back({h, true});
    } else {
      if (o.handle)
        internalError("loops-classical: a classical carried value with a rail as its initial value", &p);
      inits.push_back({o.v, false});
    }
  }
  // Case 3: capture rails for values read after the loop that are no carried value's next.
  std::vector<std::pair<const Instruction *, PHINode *>> caps;
  std::vector<Value *> capInits;
  DenseMap<const Value *, PHINode *> nextOf;   // a carried value's next -> its header phi (orig)
  if (c3) {
    for (PHINode &p : header->phis())
      if (isQ(&p))
        nextOf[p.getIncomingValueForBlock(latch)] = &p;
    for (const Instruction *v : liveOut)
      if (!nextOf.count(v)) {
        if (!(v->getType()->isIntegerTy() || v->getType()->isFloatingPointTy()))
          unimplemented("loops-classical: a non-scalar value read after a case-3 loop", v);
        RailType w = railTypeOf(v->getType());
        capInits.push_back(seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), w)), w));
      }
    for (CPhi &cp : cphis) {
      RailType w = railTypeOf(cp.type());
      capInits.push_back(seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), w)), w));
    }
  }
  BasicBlock *H = newBlock();
  ctx.B().CreateBr(H);
  if (outermost) {
    ctx.unc().closeScope(seedScope);
    segOpen = false;
  }
  startSeg(H);
  heads.push_back({H, entryFrom});
  {
    unsigned k = 0;
    for (PHINode &p : header->phis()) {
      auto [v, q] = inits[k++];
      PHINode *np = ctx.B().CreatePHI(q ? handleTy(ctx.M.getContext()) : p.getType(), 2, p.getName());
      np->addIncoming(v, entryFrom);
      if (q)
        ctx.unc().recordExternal(np, Role::UserRegister);
      ctx.bind(&p, np);
      carried.push_back({&p, np, q});
    }
  }
  PHINode *aPhi = nullptr;
  Value *aCur = nullptr;   // multi-exit: the trip predicate after the quantum exits so far
  if (c3) {
    aPhi = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "trip");
    aPhi->addIncoming(aInit, entryFrom);
    ctx.unc().recordExternal(aPhi, Role::UserRegister);
    aCur = aPhi;
    for (unsigned k = 0; k < cphis.size(); ++k) {
      PHINode *cp = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "xcap");
      cp->addIncoming(capInits[capInits.size() - cphis.size() + k], entryFrom);
      ctx.unc().recordExternal(cp, Role::UserRegister);
      cphis[k].cap = cp;
    }
    unsigned k = 0;
    for (const Instruction *v : liveOut)
      if (!nextOf.count(v)) {
        PHINode *cp = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "cap");
        cp->addIncoming(capInits[k++], entryFrom);
        ctx.unc().recordExternal(cp, Role::UserRegister);
        caps.push_back({v, cp});
      }
  }

  // The body walk.
  const Pred hq = qp(header);
  // Multi-exit: a block on every path of a trip that goes on (it dominates the latch) is in no arm: its
  // predicate's extra conjuncts are the negated quantum exits, which the trip predicate a carries.
  auto armed = [&](const BasicBlock *u) {
    if (mx && mxDT->dominates(u, latch))
      return false;
    return !samePred(qp(u), hq);
  };
  auto subOf = [&](const BasicBlock *b) -> Loop * {
    for (Loop *s : L.getSubLoops())
      if (s->contains(b))
        return s;
    return nullptr;
  };
  auto fwdPreds = [&](const BasicBlock *s) {
    SmallVector<const BasicBlock *, 4> ps;
    Loop *sl = subOf(s);
    for (const BasicBlock *p : predecessors(s))
      if (!(sl && sl->contains(p)) && !is_contained(ps, p))
        ps.push_back(p);
    return ps;
  };
  enum class EK { Linear, Merge, Real };
  auto termQ = [&](const Instruction *t) {
    if (auto *br = dyn_cast<BranchInst>(t))
      return br->isConditional() && isQ(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return isQ(sw->getCondition());
    return false;
  };
  auto edgeKind = [&](const BasicBlock *u, const BasicBlock *s) {
    if (subOf(u))
      return EK::Real;   // a sub-loop always ends in a real branch
    const Instruction *t = u->getTerminator();
    if (termQ(t))
      return EK::Linear;
    if (auto *br = dyn_cast<BranchInst>(t); br && !br->isConditional()) {
      // A classical join inside a quantum arm (rule 8: the classical branch nested in the arm stays a
      // classical branch, and its arms meet again under the same quantum predicate) is a real join.
      if (armed(u)) {
        SmallVector<const BasicBlock *, 4> ps = fwdPreds(s);
        if (ps.size() > 1 && all_of(ps, [&](const BasicBlock *p) {
              return !termQ(p->getTerminator()) && samePred(qp(p), qp(s));
            }))
          return EK::Real;
        // An exit of a classical branch nested in the arm (u's classical factor is stronger than s's):
        // the classical arms' flows are distinct output blocks and meet at s by a real edge (a mixed
        // join when s is also a quantum join).
        if (!(cfOf(ctx.preds().block(s)) & !cfOf(ctx.preds().block(u))).isBottom())
          return EK::Real;
        return EK::Linear;
      }
      return fwdPreds(s).size() == 1 ? EK::Merge : EK::Real;
    }
    return EK::Real;
  };
  auto target = [&](const BasicBlock *s) -> BasicBlock * {
    if (s == header)
      return H;
    if (!L.contains(s))
      return T;
    return ob(s);
  };

  // Next values of the carried phis, computed at the latch before its terminator.
  std::vector<Value *> nexts;
  auto latchNexts = [&]() {
    for (Carried &cv : carried) {
      Operand o = ctx.operand(cv.orig->getIncomingValueForBlock(latch));
      if (!cv.q) {
        if (o.handle)
          internalError("loops-classical: a classical carried value whose next is a rail", cv.orig);
        nexts.push_back(o.v);
      } else if (const R6 *r = r6Of(cv.orig)) {
        Operand u = ctx.operand(r->U.back());
        if (!o.handle || !u.handle || o.v != u.v || !isa<Instruction>(o.v) ||
            cast<Instruction>(o.v)->getParent() != H)
          internalError("loops-classical: rule 6 on a carried value whose update is not its next rail in the "
                        "header's segment",
                        cv.orig);
        RailType w = railTypeOf(cv.orig->getType());
        RailId old = ctx.unc().idOf(cv.np);
        if (!c3) {
          if (!r->rotated)
            ctx.unc().setRole(ctx.unc().idOf(o.v), Role::UserRegister);
          for (unsigned i = r->U.size(); i-- > 0;) {
            const Value *prev = i ? r->U[i - 1] : r->p;
            Inv inv = inverseOf(ctx, *r->U[i], prev, ctx.operand(r->U[i]));
            ctx.unc().cleanupBijective(i ? ctx.unc().idOf(ctx.operand(prev).v) : old, inv.spec, inv.ops);
          }
          keptFinal.insert(o.v);
          nexts.push_back(o.v);
        } else {
          // y'' = a ? f(y) : y; t = a ? f^-1(y'') : y''. The inner f^-1(y'') is garbage the clean-up
          // reads (noted as a use of y so the clean-up follows it); f(y) is uncomputed first (rule 5).
          Value *sel = select(aPhi, o, Operand{cv.np, true}, w);
          ctx.unc().setRole(ctx.unc().idOf(sel), Role::UserRegister);
          Value *inner = sel;
          for (unsigned i = r->U.size(); i-- > 0;) {
            Inv inv = inverseOf(ctx, *r->U[i], i ? r->U[i - 1] : r->p, Operand{inner, true});
            inner = ctx.emitTemplate(inv.spec, inv.ops);
            ctx.unc().noteUse(old, cast<Instruction>(inner));
          }
          abi::TemplateSpec ss;
          ss.op = "select";
          ss.w = w;
          ctx.unc().cleanupBijective(old, ss, {Operand{aPhi, true}, Operand{inner, true}, Operand{sel, true}});
          keptFinal.insert(sel);
          nexts.push_back(sel);
        }
      } else if (c3) {
        nexts.push_back(select(aCur, o, Operand{cv.np, true}, railTypeOf(cv.orig->getType())));
      } else {
        nexts.push_back(asHandle(o, cv.orig->getType()));
      }
    }
    for (auto &[v, cp] : caps)
      cp->addIncoming(select(aPhi, ctx.operand(v), Operand{cp, true}, railTypeOf(v->getType())), cur);
  };

  // The seeds minted for classical incomings of phis of handles (mintEdgeSeeds below), per (phi, edge source).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> &edgeSeed = edgeSeedM;
  // Mixed joins: the value of each phi of b on the real edge u -> b (mintEdgeSeeds).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> &edgeVal = edgeValM;
  auto emitPhis = [&](BasicBlock *b, bool real) {
    for (PHINode &p : b->phis()) {
      bool q = isQ(&p);
      if (p.getNumIncomingValues() == 1 || all_of(p.incoming_values(), [&](const Value *v) {
            return v == p.getIncomingValue(0);
          })) {
        Operand o = ctx.operand(p.getIncomingValue(0));
        ctx.bind(&p, q ? asHandle(o, p.getType()) : o.v);
        continue;
      }
      if (!real) {
        if (!q)
          internalError("loops-classical: a classical phi at a linearized join", &p);
        ctx.bind(&p, lowerMerge(ctx, p));
        continue;
      }
      if (q && p.getType()->isPointerTy()) {
        // Rule 21: a quantum pointer phi is a fat-pointer merge, fatptr's construction (its uses lower it).
        fatptr::lower(ctx, &p);
        internalError("loops-classical: fatptr::lower of a quantum pointer phi returned", &p);
      }
      // A classical join over handles (rule 9: a classical phi over the handles, no gate), field-wise for
      // a composite (rule 26: one phi per scalar leaf; a quantum leaf a phi of handles, a classical leaf a
      // classical phi). One incoming per output edge: a terminator with several edges to b (a switch's
      // cases) has one entry per edge in the original phi and in the output terminator alike, with the
      // same value (LLVM's rule). A real edge ends its output block, so an output block names one
      // original block. At a mixed join (a quantum join that classical branches nested in an arm also
      // reach) the edges absorbed by the linearization carry nothing: each real edge carries its value
      // (edgeVal, mintEdgeSeeds).
      const bool composite = p.getType()->isAggregateType() || p.getType()->isVectorTy();
      struct In {
        BasicBlock *from;
        SmallVector<Operand, 4> f;
      };
      SmallVector<In, 4> ins;
      DenseMap<BasicBlock *, BasicBlock *> from;
      for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
        BasicBlock *u = p.getIncomingBlock(i);
        if (edgeKind(u, b) != EK::Real)
          continue;   // absorbed by the linearization: its flow reaches b through a real edge
        auto it = edgeFrom.find({u, b});
        if (it == edgeFrom.end())
          internalError("loops-classical: a join edge with no output block", &p);
        if (auto [f, fresh] = from.insert({it->second, u}); !fresh && f->second != u)
          internalError("loops-classical: two original blocks leave through one output block on real edges", &p);
        In in{it->second, {}};
        if (auto e = edgeVal.find({&p, u}); e != edgeVal.end())
          in.f.push_back(Operand{e->second, true});
        else if (composite)
          in.f = aggr::flattenResult(ctx, p.getIncomingValue(i));
        else
          in.f.push_back(ctx.operand(p.getIncomingValue(i)));
        if (q && !composite && !in.f[0].handle)
          if (auto e = edgeSeed.find({&p, u}); e != edgeSeed.end())
            in.f[0] = Operand{e->second, true};
        ins.push_back(std::move(in));
      }
      if (ins.empty())
        internalError("loops-classical: a real join with no real edge", &p);
      const unsigned nf = ins[0].f.size();
      SmallVector<Operand, 4> outF;
      for (unsigned k = 0; k < nf; ++k) {
        bool fq = false;
        for (In &in : ins) {
          if (in.f.size() != nf)
            internalError("loops-classical: incomings of one phi with different field counts", &p);
          fq |= in.f[k].handle;
        }
        if (fq && !q)
          internalError("loops-classical: a classical phi with a rail incoming", &p);
        if (fq) {
          // A classical leaf on some edge of a quantum leaf: a seed minted at the end of that edge's
          // output block (rule 7). Only composite leaves get here: a scalar's seed is mintEdgeSeeds'.
          for (In &in : ins)
            if (!in.f[k].handle) {
              if (!composite)
                internalError("loops-classical: a classical incoming of a phi of handles with no edge seed", &p);
              IRBuilderBase::InsertPointGuard g(ctx.B());
              ctx.B().SetInsertPoint(in.from->getTerminator());
              in.f[k] = Operand{seed(in.f[k].v, railTypeOf(in.f[k].v->getType())), true};
            }
        }
        Type *ty = fq ? handleTy(ctx.M.getContext()) : ins[0].f[k].v->getType();
        PHINode *np = PHINode::Create(ty, ins.size(), p.getName());
        np->insertInto(ob(b), ob(b)->getFirstNonPHIIt());
        for (In &in : ins)
          np->addIncoming(in.f[k].v, in.from);
        if (fq)
          ctx.unc().recordMerge(np);
        outF.push_back(Operand{np, fq});
      }
      if (composite)
        ctx.bindFields(&p, outF);
      else
        ctx.bind(&p, outF[0].v);
    }
  };

  // A MIXED JOIN (rules 8, 9): s is a quantum join of arms one of which holds a classical branch whose arms
  // reach s directly (`if (q) { if (c) a; else b; }`): the linearized edges into s (from the quantum
  // branch, from arm blocks) carry no flow of their own, it went on through the classical branch; the
  // classical arms meet at s as a real join. On the real edge u -> s each phi of s is the rule-9 merge of
  // the incomings that edge's path can carry: u's own, and each linearized incoming whose classical fact
  // holds wherever u's edge is taken (an incoming whose fact excludes u's is not on that path), each under
  // its edge's quantum part (u's classical fact holds on that path). One select chain per edge, made at
  // the end of u's output block (rule 9: one select per distinct incoming, a fresh rail).
  auto mixedEdge = [&](BasicBlock *u, BasicBlock *s) {
    auto factAt = [&](const BasicBlock *p) {
      auto it = factOf.find(p);
      return (it == factOf.end() ? Pred::top() : it->second) & cfOf(ctx.preds().edge(p, s));
    };
    const Pred uf = factAt(u);
    for (PHINode &p : s->phis()) {
      if (edgeVal.count({&p, u}))
        continue;
      std::vector<std::pair<Pred, Operand>> arms;
      SmallVector<const Value *, 4> vals;
      for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
        BasicBlock *pi = p.getIncomingBlock(i);
        if (pi != u) {
          if (edgeKind(pi, s) == EK::Real)
            continue;   // another classical arm: not on u's path
          if (!factOf.count(pi))
            unimplemented("loops-classical: a classical branch nested in a quantum arm of a trip whose region does not close at one join before other linearized code of the trip runs (its arms leave toward several blocks, or the other quantum arm holds code still to walk): the rejoin of a classical region inside an arm is not built", &p);
          Pred pf = factAt(pi);
          if ((uf & pf).isBottom())
            continue;
          if (!(uf & !pf).isBottom())
            internalError("loops-classical: a linearized incoming of a mixed join whose classical fact holds on part "
                          "of a real edge's path",
                          &p);
        }
        Pred e = ctx.preds().edge(pi, s).quantumPart(ctx.T, ctx.S);
        const Value *v = p.getIncomingValue(i);
        if (auto k = find(vals, v); k != vals.end()) {
          arms[k - vals.begin()].first = arms[k - vals.begin()].first | e;
          continue;
        }
        vals.push_back(v);
        arms.push_back({e, ctx.operand(v)});
      }
      if (arms.empty())
        internalError("loops-classical: a real edge into a mixed join carries no incoming", &p);
      if (!isQ(&p)) {
        if (arms.size() > 1)
          internalError("loops-classical: a classical phi at a mixed join chosen by a quantum edge", &p);
        continue;   // the classical incoming of u's own edge (emitPhis)
      }
      if (p.getType()->isAggregateType() || p.getType()->isVectorTy() || p.getType()->isPointerTy()) {
        if (arms.size() == 1)
          continue;   // u's own incoming, field-wise (emitPhis)
        lowerMerge(ctx, p);   // a quantum choice of a composite: pred's merge
        internalError("loops-classical: pred's merge of a composite phi returned", &p);
      }
      Value *h = arms.size() == 1 ? asHandle(arms[0].second, p.getType())
                                  : selectChain(ctx, arms, railTypeOf(p.getType()));
      edgeVal[{&p, u}] = h;
    }
  };

  // Rule 7 (176): a classical incoming of a phi of handles at a classical join of the body (the value on
  // the edge u -> s, e.g. -O1's zero-trip skip of an inner accumulator loop) is a seed rail minted at the
  // end of u's output block, in u's segment, before u's branch: its item (a direct release) follows the
  // merge's readers, and u's segment runs on every path through s's edge from u.
  // A sub-loop's exit edge enters a block of its parent (an exit phi with a classical incoming): the seed is
  // minted here, in the sub-loop's segment, and read by the parent's join.
  auto mintEdgeSeeds = [&](BasicBlock *u, BasicBlock *s) {
    if (s == header || !top.contains(s) || subOf(s))
      return;
    for (Loop *x : top.getLoopsInPreorder())
      if (x->getHeader() == s)
        return;   // a loop header's phis are its carried values (lowerLoop)
    if (L.contains(s) && edgeKind(u, s) == EK::Real) {
      bool lin = false;
      for (const BasicBlock *p : fwdPreds(s))
        lin |= edgeKind(p, s) != EK::Real;
      if (lin)
        mixedEdge(u, s);
    }
    for (PHINode &p : s->phis()) {
      if (!isQ(&p) || edgeSeed.count({&p, u}) || edgeVal.count({&p, u}))
        continue;
      Value *v = p.getIncomingValueForBlock(u);
      Operand o = ctx.operand(v);
      if (o.handle)
        continue;
      if (!(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()))
        continue;   // emitPhis refuses the phi itself
      edgeSeed[{&p, u}] = seed(o.v, railTypeOf(p.getType()));
    }
  };

  // Multi-exit, at the latch: the exit arm, the captures, res, and the trip predicate's back edge.
  auto latchExits = [&]() {
    DenseMap<const BasicBlock *, Value *> armFlag;
    auto flagOfEdge = [&](const BasicBlock *u, const BasicBlock *x) -> Value * {
      if (L.contains(u)) {
        auto it = exitFlag.find({u, x});
        return it == exitFlag.end() ? nullptr : it->second;
      }
      return armFlag.lookup(u);
    };
    for (BasicBlock *b : UX.arm) {
      SmallVector<Value *, 2> in;
      for (BasicBlock *p : predecessors(b))
        if (Value *f = flagOfEdge(p, b); f && !is_contained(in, f))
          in.push_back(f);
      if (in.empty())
        internalError("loops-classical: an exit arm block reached by no quantum exit edge", b->getTerminator());
      Value *f = in.front();
      if (in.size() > 1) {
        // Disjoint exit edges (one trip leaves through one): their OR is their XOR.
        f = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
        for (Value *x : in)
          gate(abi::Core::XorI1, {x, f});
      }
      armFlag[b] = f;
      for (Instruction &I : *b)
        if (!isa<PHINode>(I) && !I.isTerminator())
          lowerInstruction(ctx, I, aPhi);
    }
    for (CPhi &cp : cphis) {
      RailType w = railTypeOf(cp.type());
      Value *c = cp.cap;
      Operand vl{nullptr, false};
      for (auto &[u, val] : cp.incomings(inUnit, UX.cont)) {
        if (u == cxb) {
          if (u == latch)
            vl = ctx.operand(val);
          continue;   // the classical exit: res (at the header, headerRes)
        }
        Value *g = flagOfEdge(u, UX.cont);
        if (!g)
          internalError("loops-classical: a unit edge into a case-3 loop's continuation with no exit flag",
                        cp.orig());
        c = select(g, ctx.operand(val), Operand{c, true}, w);
      }
      cp.cap->addIncoming(c, cur);
      if (cxb != header || cxb == latch)
        cp.res = vl.v ? select(aCur, vl, Operand{c, true}, w) : c;
    }
    aPhi->addIncoming(aCur, cur);
  };
  // Multi-exit with the classical bound tested at the header (cxb): its exit edge is taken before any
  // quantum exit of the trip, so res = select(a, v, cap) over the captures of the earlier trips.
  auto headerRes = [&]() {
    for (CPhi &cp : cphis) {
      const Value *val = nullptr;
      for (auto &[u, v] : cp.incomings(inUnit, UX.cont))
        if (u == header)
          val = v;
      if (!val)
        internalError("loops-classical: a case-3 loop's classical exit edge with no value for its continuation",
                      cp.orig());
      cp.res = select(aCur, ctx.operand(val), Operand{cp.cap, true}, railTypeOf(cp.type()));
    }
  };

  auto emitTerminator = [&](BasicBlock *u) {
    Instruction *t = u->getTerminator();
    const bool qExit = mx && termQ(t) && any_of(successors(u), [&](const BasicBlock *s) { return !L.contains(s); });
    if (u == latch && !qExit)
      latchNexts();
    if (mx && u == latch && !qExit)
      latchExits();
    if (mx && u == cxb && u == header && u != latch)
      headerRes();
    if (qExit) {
      // A quantum exit before the latch: e = a & f, a' = a & NOT f; the trip goes on in the loop.
      auto *br = dyn_cast<BranchInst>(t);
      if (!br || L.contains(br->getSuccessor(0)) == L.contains(br->getSuccessor(1)))
        unimplemented("loops-classical: a quantum exit of a case-3 loop that is not a two-way branch out of the trip",
                      t);
      bool exitOnTrue = !L.contains(br->getSuccessor(0));
      BasicBlock *x = br->getSuccessor(exitOnTrue ? 0 : 1);
      if (x == header || (br->getSuccessor(exitOnTrue ? 1 : 0) == header && u != latch))
        unimplemented("loops-classical: a quantum exit test whose other edge is the back edge", t);
      Pred ex = qp(u) & (exitOnTrue ? Pred::atom(br->getCondition()) : !Pred::atom(br->getCondition()));
      Value *f = ctx.preds().flag(ctx, ex);
      if (!f)
        internalError("loops-classical: a quantum exit condition with no flag", t);
      Value *e = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::AndI1, {aCur, f, e});
      Value *a2 = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::XorI1, {aCur, a2});
      gate(abi::Core::AndI1, {aCur, f, a2});
      exitFlag[{u, x}] = e;
      aCur = a2;
      lowerBranch(ctx, *br);
      if (u == latch) {
        // The quantum exit at the latch (cq-nqa6): the next values and captures under a', then the back edge.
        latchNexts();
        latchExits();
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        ctx.B().CreateBr(H);
        cur = nullptr;
        return;
      }
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      return;
    }
    if (c3 && !mx && u == latch) {
      IRBuilder<> &B = ctx.B();
      Value *cExit = nullptr;
      for (const Disj &d : ds) {
        if (isQ(d.v))
          continue;
        Operand o = ctx.operand(d.v);
        if (o.handle)
          internalError("loops-classical: a classical exit disjunct that is a rail", d.v);
        Value *x = d.pos ? o.v : B.CreateNot(o.v);
        cExit = cExit ? B.CreateOr(cExit, x) : x;
      }
      Value *q = nQ == 1 ? ctx.rail(qLeaf) : ctx.preds().flag(ctx, qExitP);
      if (!q)
        internalError("loops-classical: a case-3 exit test's quantum disjunction with no flag", latch->getTerminator());
      const bool qExit = nQ == 1 ? qPos : true;
      Value *a = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      // a = a_prev & q, or a_prev & NOT q = a_prev ^ (a_prev & q): gates on a alone, so the mirror's
      // undo of a reads q in the state the forward read it (no bracket on q).
      if (qExit)
        gate(abi::Core::XorI1, {aPhi, a});
      gate(abi::Core::AndI1, {aPhi, q, a});
      aPhi->addIncoming(a, cur);
      B.CreateCondBr(cExit, T, H);
      edgeFrom[{u, exitB}] = cur;
      edgeFrom[{u, header}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *br = dyn_cast<BranchInst>(t)) {
      if (!br->isConditional()) {
        BasicBlock *s = br->getSuccessor(0);
        EK k = (s == header || !L.contains(s)) ? EK::Real : edgeKind(u, s);
        edgeFrom[{u, s}] = cur;
        if (k != EK::Real)
          return;
        mintEdgeSeeds(u, s);
        ctx.B().CreateBr(target(s));
        cur = nullptr;
        return;
      }
      if (termQ(t)) {
        for (BasicBlock *s : successors(u))
          if (s == header || !L.contains(s))
            unimplemented("loops-classical: a quantum branch leaving the trip that is not a case-3 latch test", t);
        lowerBranch(ctx, *br);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      Operand cnd = ctx.operand(br->getCondition());
      if (cnd.handle)
        internalError("loops-classical: a classical branch on a rail", t);
      for (BasicBlock *s : successors(u))
        mintEdgeSeeds(u, s);
      ctx.B().CreateCondBr(cnd.v, target(br->getSuccessor(0)), target(br->getSuccessor(1)));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    if (auto *sw = dyn_cast<SwitchInst>(t)) {
      if (termQ(t)) {
        exits::Unit U = exits::unitOf(L);
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && is_contained(U.live, s)))
            unimplemented("loops-classical: a quantum switch leaving the trip", t);
        sw::lowerSwitch(ctx, *sw);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      Operand cnd = ctx.operand(sw->getCondition());
      if (cnd.handle)
        internalError("loops-classical: a classical switch on a rail", t);
      for (BasicBlock *s : successors(u))
        mintEdgeSeeds(u, s);
      SwitchInst *ns = ctx.B().CreateSwitch(cnd.v, target(sw->getDefaultDest()), sw->getNumCases());
      for (auto &cs : sw->cases())
        ns->addCase(cs.getCaseValue(), target(cs.getCaseSuccessor()));
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      cur = nullptr;
      return;
    }
    // An invoke is a call first: the spine's dispatch lowers it (its own construction, CR rule 18).
    if (isa<InvokeInst>(t)) {
      lowerInstruction(ctx, *t, aPhi);
      internalError("loops-classical: the spine's dispatch returned from an invoke", t);
    }
    // ret and unreachable end no block of a loop (no successor), classify stops on indirectbr and callbr
    // in a loop; the EH pads come from no C translation unit.
    internalError("loops-classical: a loop body terminator other than br or switch", t);
  };

  auto emitInstructions = [&](BasicBlock *b) {
    for (Instruction &I : *b) {
      if (isa<PHINode>(I) || I.isTerminator() || skip.count(&I))
        continue;
      // case 3: the body runs under a_{j-1}; case 1: under the enclosing case-3 trip's rail, if any
      lowerInstruction(ctx, I, aPhi ? aPhi : outerTrip);
    }
  };

  // The header (its phis are the carried values above). The outermost header runs under the spine's
  // guard; a sub-loop's header fact is set by its parent's walk.
  if (outermost)
    curFact = cfOf(ctx.preds().block(header));
  requireFact(header);
  emitInstructions(header);
  emitTerminator(header);
  // The walk order (rule 8 inside a trip). A block entered by classical edges only starts a segment of
  // its own and needs no open block; a block entered by linearized edges only continues the open block,
  // which must run exactly where the block's classical factor holds (a quantum arm's code runs on every
  // path its classical guard admits, no fewer: an arm block reached in RPO while a classical branch
  // nested in another arm is open waits for that branch's join). A block whose turn comes before its
  // place exists waits (pending) and is walked as soon as it can be, in RPO among the waiting ones.
  auto entryKinds = [&](BasicBlock *b) {
    bool anyReal = false, anyLin = false;
    for (const BasicBlock *p : fwdPreds(b))
      (edgeKind(p, b) == EK::Real ? anyReal : anyLin) = true;
    return std::make_pair(anyReal, anyLin);
  };
  std::vector<BasicBlock *> pending;
  DenseSet<const BasicBlock *> pendSet;
  auto mustWait = [&](BasicBlock *b) {
    for (const BasicBlock *p : fwdPreds(b))
      if (pendSet.count(p) && p != b)
        return true;
    auto [anyReal, anyLin] = entryKinds(b);
    if (anyReal)
      return cur != nullptr;
    if (!cur)
      return true;
    // Where b runs: where one of its walked predecessors ran and the edge's classical factor held.
    Pred need = Pred::bottom();
    for (const BasicBlock *p : fwdPreds(b)) {
      auto it = factOf.find(p);
      need = need | ((it == factOf.end() ? Pred::top() : it->second) & cfOf(ctx.preds().edge(p, b)));
    }
    return !(need & !curFact).isBottom();
  };
  auto visit = [&](BasicBlock *b) {
    Loop *sl = subOf(b);
    auto [anyReal, anyLin] = entryKinds(b);
    if (anyReal) {
      if (cur)
        internalError("loops-classical: a classical join walked while a block is open", &*b->begin());
      startSeg(ob(b));
      Pred f = Pred::bottom();
      for (const BasicBlock *p : fwdPreds(b)) {
        auto it = factOf.find(p);
        f = f | ((it == factOf.end() ? Pred::top() : it->second) & cfOf(ctx.preds().edge(p, b)));
      }
      curFact = f;
    } else if (!cur) {
      internalError("loops-classical: a linearized block walked with no open block", &*b->begin());
    }
    if (!sl)
      requireFact(b);
    if (sl) {
      Case sc = classify(*sl, ctx.T, ctx.S);
      if (sc == Case::QuantumExit)
        unimplemented("loops-classical: a quantum-exit loop nested in a classically bounded loop (loops-cutoff)",
                      sl->getHeader()->getTerminator());
      BasicBlock *sx = exits::liveExit(*sl);
      if (!sx || !L.contains(sx))
        unimplemented("loops-classical: a sub-loop that leaves its parent loop", sl->getHeader()->getTerminator());
      if (!c3 && sc == Case::ClassicalBound && anyReal && sl->getExitingBlock() && tripLocal(*sl, L)) {
        // A trip-local sub-loop (176): its own unit, entered from the segment just opened at its header.
        BasicBlock *entry = cur;
        size_t nb = Out.size();
        auto sub = std::make_shared<Unit>(ctx, *sl);
        sub->nested = true;
        sub->resetAt = H;
        sub->run(sc);
        unsigned k = 0;
        for (BasicBlock &ob2 : Out)
          if (k++ >= nb)
            subBlocks.insert(&ob2);
        subBlocks.insert(sub->subBlocks.begin(), sub->subBlocks.end());
        BasicBlock *bk = ctx.B().GetInsertBlock();
        ctx.B().CreateBr(ob(sx));
        edgeFrom[{sl->getExitingBlock(), sx}] = bk;
        throughSub[bk] = entry;
        subs.push_back({sub, unsigned(segs.size() - 1), bk});
        cur = nullptr;
        return;
      }
      Value *savedTrip = outerTrip;
      if (c3)
        outerTrip = aPhi;   // the sub-loop's trips run inside this trip: under a_{j-1}
      auto subOut = lowerLoop(*sl, sc, ob(sx), false);
      outerTrip = savedTrip;
      for (auto &[v, op] : subOut)
        ctx.rebind(v, {op});
      return;
    }
    emitPhis(b, anyReal);
    emitInstructions(b);
    emitTerminator(b);
  };
  for (BasicBlock *b : rpo) {
    if (b == header || !L.contains(b))
      continue;
    if (Loop *sl = subOf(b); sl && sl->getHeader() != b)
      continue;
    if (mustWait(b)) {
      pending.push_back(b);
      pendSet.insert(b);
    } else {
      visit(b);
    }
    for (unsigned k = 0; k < pending.size();) {
      BasicBlock *w = pending[k];
      if (!pendSet.count(w) || mustWait(w)) {
        ++k;
        continue;
      }
      pendSet.erase(w);
      visit(w);
      k = 0;
    }
  }
  if (!pendSet.empty())
    unimplemented("loops-classical: a classical branch nested in a quantum arm of a trip whose region does not close at one join before other linearized code of the trip runs (its arms leave toward several blocks, or the other quantum arm holds code still to walk): the rejoin of a classical region inside an arm is not built", &*(*pendSet.begin())->begin());
  if (cur)
    internalError("loops-classical: the trip walk ended with an open block", latch->getTerminator());

  // Back edges.
  {
    auto it = edgeFrom.find({latch, header});
    if (it == edgeFrom.end())
      internalError("loops-classical: no back edge out of the latch", latch->getTerminator());
    for (unsigned k = 0; k < carried.size(); ++k)
      carried[k].np->addIncoming(nexts[k], it->second);
  }
  closeSeg();

  // Exit values of the values read after the loop.
  std::vector<std::pair<const Value *, Operand>> out;
  DenseSet<const Value *> unbound;   // multi-exit: C's phis, bound here for the first time
  for (CPhi &cp : cphis) {
    if (!cp.res)
      internalError("loops-classical: a continuation phi of a case-3 loop with no exit value", cp.orig());
    out.push_back({cp.orig(), Operand{cp.res, true}});
    if (cp.P)
      unbound.insert(cp.P);
  }
  auto put = [&](const Value *v, Operand op) {
    if (unbound.erase(v))
      ctx.bindFields(v, {op});
    else
      ctx.rebind(v, {op});
  };
  for (const Instruction *v : liveOut) {
    if (!isQ(v))
      continue;
    if (c3) {
      if (auto n = nextOf.find(v); n != nextOf.end()) {
        unsigned k = 0;
        while (carried[k].orig != n->second)
          ++k;
        out.push_back({v, Operand{nexts[k], true}});
      } else {
        for (auto &[cv, cp] : caps)
          if (cv == v)
            out.push_back({v, Operand{cp->getIncomingValueForBlock(edgeFrom[{latch, header}]), true}});
      }
    } else {
      out.push_back({v, ctx.operand(v)});
    }
  }
  if (outermost) {
    ctx.B().SetInsertPoint(T);
    // cq-fx3s: a value read after the loop whose exit rail is made by a record of the loop (a trip's
    // template, a seed of the entry) is read in place, and the reverse loop is deferred until after its
    // readers (Uncompute::recordDeferred, CR rule 14: 153, 178); any other (an alias of a carried value,
    // a rail from before the loop) is copied out first, as before.
    std::vector<unsigned> scs{seedScope};
    for (const Seg &sg : segs)
      scs.push_back(sg.scope);
    DenseSet<const Value *> ownedH;
    for (unsigned sc : scs)
      for (const Record &r : U.scopeRecords(sc))
        if (!r.forward->getType()->isVoidTy())
          ownedH.insert(r.forward);
    std::vector<RailId> exits;
    for (auto &[v, op] : out) {
      RailType w = railTypeOf(v->getType());
      if (!op.handle)
        internalError("loops-classical: a quantum value read after the loop whose exit value is classical", v);
      if (keptFinal.count(op.v)) {
        // A cleaned chain's final rail is the register itself: the reverse never touches it.
        put(v, op);
        continue;
      }
      if (ownedH.count(op.v)) {
        put(v, op);
        RailId x = U.idOf(op.v);
        if (!is_contained(exits, x))
          exits.push_back(x);
        continue;
      }
      if (nested)
        unimplemented("loops-classical: a trip-local sub-loop whose value read after it is not its own rail (a "
                      "copy-out per trip)",
                      cast<Instruction>(v));
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cc = ctx.emitCore(cp, {op.v, f});
      ctx.unc().recordCore(cc, cp, {op, Operand{f, true}}, fid);
      ctx.unc().setRole(fid, Role::Output);
      put(v, Operand{f, true});
    }
    // M3 (CR rules 5, 20): a rail a trip made and stored into a slot cell may be read after the loop
    // through the cell (a run-time read names it, Uncompute::recordCellLoad): it is an exit rail, so the
    // reverse runs after those reads and the clean-ups of their readers (75, 179).
    for (unsigned sc : scs)
      for (const Record &r : U.scopeRecords(sc)) {
        if (r.forward->getType()->isVoidTy() || !std::holds_alternative<abi::TemplateSpec>(r.spec))
          continue;   // a seed stored into a cell is that cell's register (58, 59), never an exit
        bool stored = any_of(r.forward->users(), [&](const User *u) {
          auto *si = dyn_cast<StoreInst>(u);
          return si && si->getValueOperand() == r.forward;
        });
        if (!stored)
          continue;
        // A register of a slot cell (a register update's new rail, 114) is kept: never undone, so no exit.
        if (mem::isSlotRegister(ctx, r.forward))
          continue;
        // A rail mem-slots made Measured at its store is kept: the reverse never undoes it, and its
        // reads after the loop need not wait for the reverse (179's y[i]).
        bool kept = false;
        for (BasicBlock *bb : L.blocks())
          for (Instruction &I : *bb)
            if (auto *si = dyn_cast<StoreInst>(&I); si && ctx.T.isQuantum(si->getValueOperand(), ctx.S) &&
                                                    ctx.operand(si->getValueOperand()).v == r.forward)
              kept |= measuredThroughMemory(ctx, *si);
        if (kept)
          continue;
        RailId x = U.idOf(r.forward);
        if (!is_contained(exits, x))
          exits.push_back(x);
      }
    if (nested) {
      // Finished by the parent (Unit::flushTrips): the reverse runs in the parent's trip.
      Instruction *xt = nullptr;
      for (BasicBlock *p : predecessors(T))
        xt = p->getTerminator();
      if (!xt)
        internalError("loops-classical: the loop's exit block has no predecessor", latch->getTerminator());
      for (RailId x : exits)
        U.noteUse(x, xt);
      BasicBlock *Cont = newBlock();
      BranchInst::Create(Cont, T);
      std::weak_ptr<Unit> wself = shared_from_this();
      finish = [wself, T, Cont, seedScope, scs, exits, ownedH]() {
        auto self = wself.lock();
        self->flushTrips();
        if (exits.empty()) {
          T->getTerminator()->eraseFromParent();
          IRBuilder<> B(T);
          self->reverse(B, T, seedScope, false);
          B.CreateBr(Cont);
          return;
        }
        std::vector<RailId> reads;
        for (unsigned sc : scs)
          for (const Record &r : self->U.scopeRecords(sc))
            for (const Operand &o : r.ops)
              if (o.handle && !ownedH.count(o.v))
                if (RailId x = self->U.idOf(o.v); !is_contained(reads, x))
                  reads.push_back(x);
        self->U.recordDeferred(scs, exits,
                               [self, T, seedScope](IRBuilder<> &B) { self->reverse(B, T, seedScope, true); },
                               reads, self->hostScopes);
      };
      ctx.B().SetInsertPoint(Cont);
      return {};
    }
    // F1b (72, 188): a QRAM store of the trip on an object the program accesses after the loop: its cell
    // values are read there, so the reverse (which pops the store) is deferred after those accesses.
    bool busAfter = false;
    if (exits.empty() && !nested) {
      DenseSet<ObjectId> stored;
      for (BasicBlock *bb : L.blocks())
        for (Instruction &I : *bb)
          if (auto *si = dyn_cast<StoreInst>(&I))
            for (ObjectId o : ctx.T.provenance(si->getPointerOperand(), ctx.S))
              if (ctx.T.classOf(o) == ObjClass::Qram)
                stored.insert(o);
      for (BasicBlock &bb : F)
        for (Instruction &I : bb)
          if (!L.contains(&I) && (isa<LoadInst>(I) || isa<StoreInst>(I) || isa<CallBase>(I)))
            for (const Use &u : I.operands())
              if (u->getType()->isPointerTy() && !isa<Function>(u.get()))
                for (ObjectId o : ctx.T.provenance(u.get(), ctx.S))
                  if (stored.count(o) && !(isa<IntrinsicInst>(I) && cast<IntrinsicInst>(I).isLifetimeStartOrEnd()))
                    busAfter = true;
    }
    if (exits.empty() && !busAfter) {
      flushTrips();
      IRBuilder<> B(T);
      reverse(B, T, seedScope, false);
      ctx.B().SetInsertPoint(B.GetInsertBlock());
      return {};
    }
    // The exit rails are read after the loop: no trip's flush may resolve them in their own trip.
    {
      Instruction *xt = nullptr;
      for (BasicBlock *p : predecessors(T))
        xt = p->getTerminator();
      if (!xt)
        internalError("loops-classical: the loop's exit block has no predecessor", latch->getTerminator());
      for (RailId x : exits)
        U.noteUse(x, xt);
    }
    flushTrips();
    std::vector<RailId> reads;
    for (unsigned sc : scs)
      for (const Record &r : U.scopeRecords(sc))
        for (const Operand &o : r.ops)
          if (o.handle && !ownedH.count(o.v))
            if (RailId x = U.idOf(o.v); !is_contained(reads, x))
              reads.push_back(x);
    BasicBlock *Cont = newBlock();
    BranchInst::Create(Cont, T);
    auto self = shared_from_this();
    deferred = true;
    U.recordDeferred(scs, exits,
                     [self, T, seedScope](IRBuilder<> &B) { self->reverse(B, T, seedScope, true); }, reads, {},
                     busAfter);
    ctx.B().SetInsertPoint(Cont);
    return {};
  }
  return out;
}

// ---- the reverse --------------------------------------------------------------------------------

// The push/pop stack (CR §1.3: i32 words, a wider value low word first). Every first-class type a per-trip
// value can have: a scalar (integer of any width, floating point, pointer) is its bits in words; a vector,
// struct or array is its elements in order (popped in reverse).
unsigned scalarBits(Type *t, const DataLayout &DL) {
  if (t->isIntegerTy())
    return t->getIntegerBitWidth();
  if (t->isPointerTy())
    return DL.getPointerSizeInBits(t->getPointerAddressSpace());
  if (t->isFloatingPointTy())
    return unsigned(t->getPrimitiveSizeInBits());
  internalError("loops-classical: a per-trip SSA value of a type that is no first-class data type");
}

void pushValue(IRBuilder<> &B, FunctionCallee push, Value *v, const DataLayout &DL) {
  LLVMContext &C = v->getContext();
  IntegerType *i32 = Type::getInt32Ty(C);
  Type *t = v->getType();
  if (auto *st = dyn_cast<StructType>(t)) {
    for (unsigned k = 0; k < st->getNumElements(); ++k)
      pushValue(B, push, B.CreateExtractValue(v, k), DL);
    return;
  }
  if (auto *at = dyn_cast<ArrayType>(t)) {
    for (unsigned k = 0; k < at->getNumElements(); ++k)
      pushValue(B, push, B.CreateExtractValue(v, k), DL);
    return;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    for (unsigned k = 0; k < vt->getNumElements(); ++k)
      pushValue(B, push, B.CreateExtractElement(v, B.getInt64(k)), DL);
    return;
  }
  if (t == i32) {
    B.CreateCall(push, {v});
    return;
  }
  unsigned bits = scalarBits(t, DL), w = (bits + 31) / 32;
  Value *x = t->isPointerTy() ? B.CreatePtrToInt(v, B.getIntNTy(bits))
             : t->isIntegerTy() ? v
                                : B.CreateBitCast(v, B.getIntNTy(bits));
  x = B.CreateZExt(x, B.getIntNTy(32 * w));
  for (unsigned j = 0; j < w; ++j)
    B.CreateCall(push, {B.CreateTrunc(j ? B.CreateLShr(x, 32 * j) : x, i32)});
}

Value *popValue(IRBuilder<> &B, FunctionCallee pop, Type *t, const DataLayout &DL) {
  LLVMContext &C = t->getContext();
  IntegerType *i32 = Type::getInt32Ty(C);
  if (isa<StructType>(t) || isa<ArrayType>(t)) {
    unsigned n = isa<StructType>(t) ? cast<StructType>(t)->getNumElements() : cast<ArrayType>(t)->getNumElements();
    Value *agg = PoisonValue::get(t);
    for (unsigned k = n; k-- > 0;) {
      Type *et = isa<StructType>(t) ? cast<StructType>(t)->getElementType(k) : cast<ArrayType>(t)->getElementType();
      agg = B.CreateInsertValue(agg, popValue(B, pop, et, DL), k);
    }
    return agg;
  }
  if (auto *vt = dyn_cast<FixedVectorType>(t)) {
    Value *vec = PoisonValue::get(t);
    for (unsigned k = vt->getNumElements(); k-- > 0;)
      vec = B.CreateInsertElement(vec, popValue(B, pop, vt->getElementType(), DL), B.getInt64(k));
    return vec;
  }
  if (t == i32)
    return B.CreateCall(pop);
  unsigned bits = scalarBits(t, DL), w = (bits + 31) / 32;
  IntegerType *wide = Type::getIntNTy(C, 32 * w);
  Value *x = ConstantInt::get(wide, 0);
  for (unsigned j = w; j-- > 0;) {
    Value *word = B.CreateZExt(B.CreateCall(pop), wide);
    x = B.CreateOr(x, j ? B.CreateShl(word, 32 * j) : word);
  }
  x = B.CreateTrunc(x, Type::getIntNTy(C, bits));
  if (t->isPointerTy())
    return B.CreateIntToPtr(x, t);
  return t->isIntegerTy() ? x : B.CreateBitCast(x, t);
}

// Per trip (rule 5, as early as allowed): a rail made and last read within one segment is uncomputed
// at the end of that segment, in every trip (60: the Toffoli flag of q[j] && q[i]). What is left
// waits for the reverse loop.
// The flush runs with every back edge of the region cut: an item placed in its record's segment is
// reached from a gate of another segment only by a path that re-executes the record (a later trip),
// so only the acyclic trip may count as "between" for Uncompute's barrier check.
void Unit::flushTrips() {
  // An edge entering each segment, taken before any item is placed: an item placed inside a segment
  // (a trip-local sub-loop's reverse, 176) splits its block, the head and the incoming edges moving to a
  // fresh block (Uncompute::placeDeferred), so the segment's head is found again through this edge.
  entering.assign(segs.size(), {nullptr, 0});
  for (unsigned i = 0; i < segs.size(); ++i)
    for (BasicBlock *p : predecessors(segs[i].bb)) {
      Instruction *t = p->getTerminator();
      for (unsigned k = 0; k < t->getNumSuccessors(); ++k)
        if (t->getSuccessor(k) == segs[i].bb && !entering[i].first)
          entering[i] = {t, k};
    }
  BasicBlock *cut = newBlock();
  new UnreachableInst(Mod.getContext(), cut);
  std::vector<std::tuple<Instruction *, unsigned, unsigned>> backEdges;   // (terminator, successor, head index)
  std::vector<std::pair<Instruction *, unsigned>> headEntry(heads.size(), {nullptr, 0});
  for (unsigned h = 0; h < heads.size(); ++h) {
    auto [H, from] = heads[h];
    Instruction *ft = from->getTerminator();
    for (unsigned k = 0; ft && k < ft->getNumSuccessors(); ++k)
      if (ft->getSuccessor(k) == H)
        headEntry[h] = {ft, k};
    for (BasicBlock *p : predecessors(H)) {
      if (p == from)
        continue;
      Instruction *t = p->getTerminator();
      for (unsigned k = 0; k < t->getNumSuccessors(); ++k)
        if (t->getSuccessor(k) == H && !is_contained(backEdges, std::make_tuple(t, k, h)))
          backEdges.push_back({t, k, h});
    }
  }
  for (auto &[t, k, h] : backEdges)
    t->setSuccessor(k, cut);
  auto finishSubs = [&](unsigned upTo) {
    for (Sub &sb : subs)
      if (sb.entrySeg < upTo && sb.unit->finish) {
        sb.unit->hostScopes = hostScopes;
        sb.unit->hostScopes.push_back(ownSeedScope);
        for (const Seg &sg : segs)
          sb.unit->hostScopes.push_back(sg.scope);
        auto f = std::move(sb.unit->finish);
        sb.unit->finish = nullptr;
        f();
      }
  };
  for (unsigned i = 0; i < segs.size(); ++i) {
    U.flushBefore(segs[i].bb->getTerminator());
    finishSubs(i + 1);
  }
  finishSubs(~0u);
  for (unsigned h = 0; h < heads.size(); ++h)
    if (headEntry[h].first)
      heads[h].first = headEntry[h].first->getSuccessor(headEntry[h].second);
  for (auto &[t, k, h] : backEdges)
    t->setSuccessor(k, heads[h].first);
  cut->eraseFromParent();
  // Every trip-local sub-loop's reverse must have been placed in this region's trip (its exit values'
  // readers are the trip's): otherwise it would run once, after the loop, for the last trip only.
  for (Sub &sb : subs)
    if (!sb.unit->reversed)
      unimplemented("loops-classical: a trip-local sub-loop's reverse could not be placed inside its parent's "
                    "trip (rule 14 in a rule-14 trip)",
                    sb.unit->top.getHeader()->getTerminator());
}

void Unit::reverse(IRBuilder<> &BX, BasicBlock *X, unsigned seedScope, bool guarded) {
  Module &M = Mod;
  LLVMContext &C = M.getContext();
  FunctionCallee push = abi::declare(M, abi::CoreSpec{abi::Core::Push});
  FunctionCallee pop = abi::declare(M, abi::CoreSpec{abi::Core::Pop});
  IntegerType *i32 = Type::getInt32Ty(C);
  reversed = true;
  revAt = BX.GetInsertBlock();
  const unsigned n = segs.size();
  // A segment is the blocks from its head to its block segs[i].bb, which keeps its terminator: one
  // block, unless an item placed inside it split it (flushTrips' entering edge finds the head).
  std::vector<BasicBlock *> headOf(n);
  DenseMap<const BasicBlock *, unsigned> segOf;
  std::vector<SmallVector<BasicBlock *, 4>> blocksOf(n);
  for (unsigned i = 0; i < n; ++i)
    headOf[i] = i < entering.size() && entering[i].first ? entering[i].first->getSuccessor(entering[i].second)
                                                         : segs[i].bb;
  DenseSet<const BasicBlock *> stops;
  for (unsigned i = 0; i < n; ++i) {
    stops.insert(headOf[i]);
    stops.insert(segs[i].bb);
  }
  for (unsigned i = 0; i < n; ++i) {
    SmallVector<BasicBlock *, 8> work{headOf[i]};
    while (!work.empty()) {
      BasicBlock *b = work.pop_back_val();
      if (segOf.count(b))
        continue;
      segOf[b] = i;
      blocksOf[i].push_back(b);
      if (b == segs[i].bb)
        continue;
      for (BasicBlock *x : successors(b))
        if (!stops.count(x) && !subBlocks.count(x))
          work.push_back(x);
        else if (x == segs[i].bb)
          work.push_back(x);
    }
    if (!segOf.count(segs[i].bb) || segOf.lookup(segs[i].bb) != i)
      internalError("loops-classical: a segment's head does not reach its block", segs[i].bb->getTerminator());
  }
  // cq-x00t (CR rules 5, 14; 176): a trip-local sub-loop's reverse pops the frames its forward trips
  // pushed, so nothing of this region may be pushed between the sub-loop's exit and that reverse. This
  // region pushes a segment's path record (below) at the start of the segment's block segs[i].bb, after
  // any item placed in the segment, and its read-back values at that block's terminator. So the reverse
  // must lie in the segment the sub-loop exits into, before segs[i].bb.
  for (const Sub &sb : subs) {
    BasicBlock *at = sb.unit->revAt;
    if (!at)
      continue;
    auto it = segOf.find(at);
    unsigned i = it == segOf.end() ? n : it->second;
    if (i == n || at == segs[i].bb || !is_contained(predecessors(headOf[i]), sb.cont))
      unimplemented("loops-classical: a trip-local sub-loop's reverse placed outside the segment its loop exits "
                    "into (a record of the parent pushed between the sub-loop's exit and its reverse)",
                    sb.unit->top.getHeader()->getTerminator());
  }
  DenseSet<const BasicBlock *> region;
  for (auto &kv : segOf)
    region.insert(kv.first);
  // The forward predecessor of a segment: a sub-unit's continuation stands for the segment entering it.
  auto mapPred = [&](BasicBlock *p) -> BasicBlock * {
    if (auto it = throughSub.find(p); it != throughSub.end())
      return it->second;
    return p;
  };
  auto predsOf = [&](unsigned i) {
    SmallVector<BasicBlock *, 4> ps;
    for (BasicBlock *p : predecessors(headOf[i]))
      ps.push_back(p);
    return ps;
  };

  // Forward dominance over the region (the entry E outside it is the root).
  std::vector<BitVector> dom(n, BitVector(n, true));
  {
    bool changed = true;
    while (changed) {
      changed = false;
      for (unsigned i = 0; i < n; ++i) {
        BitVector d(n, true);
        bool anyPred = false;
        for (BasicBlock *p0 : predsOf(i)) {
          BasicBlock *p = mapPred(p0);
          anyPred = true;
          if (region.count(p))
            d &= dom[segOf.lookup(p)];
          else
            d.reset();
        }
        if (!anyPred)
          d.reset();
        d.set(i);
        if (d != dom[i]) {
          dom[i] = d;
          changed = true;
        }
      }
    }
  }

  // Rule 5's invariant across trips: the reverse loop undoes trip t's records after every later trip
  // has run, so a non-diagonal gate in the loop must not touch a rail an undone record reads. A gate
  // on a rail made in its own trip (by a record of the region) cannot touch an earlier trip's rails;
  // a gate on any other rail (a slot cell loaded per trip, a carried value, a rail from before the
  // loop) may, and then no deferred item may remain (cq-sujx).
  const Instruction *crossGate = nullptr;
  {
    DenseSet<const Value *> fresh;
    for (const Seg &s : segs)
      for (const Record &r : U.scopeRecords(s.scope))
        fresh.insert(r.forward);
    for (unsigned si = 0; si < n; ++si)
      for (BasicBlock *sbb : blocksOf[si])
      for (Instruction &I : *sbb) {
        auto *call = dyn_cast<CallInst>(&I);
        Function *callee = call ? call->getCalledFunction() : nullptr;
        if (!callee || crossGate)
          continue;
        std::optional<abi::CoreSpec> cs = abi::parseCore(callee->getName());
        if (!cs || cs->unc || (cs->op != abi::Core::Ry && cs->op != abi::Core::RyQAngle))
          continue;
        for (Value *a : call->args())
          if (a->getType() == i32 && !isa<Constant>(a) && !fresh.count(a))
            crossGate = call;
      }
  }
  auto checkDeferred = [&](BasicBlock *bb, BasicBlock::iterator from) {
    if (!crossGate)
      return;
    for (auto it = from; it != bb->end(); ++it) {
      // The release of a seed never written (rule 7: an edge seed of the trip, 176) reads no other rail
      // and its own is never a gate's target: no later trip's gate can change what it undoes.
      if (auto *fr = dyn_cast<CallInst>(&*it); fr && fr->getCalledFunction() && fr->arg_size() == 1) {
        std::optional<abi::CoreSpec> cs = abi::parseCore(fr->getCalledFunction()->getName());
        auto *src = dyn_cast<CallInst>(fr->getArgOperand(0));
        std::optional<abi::CoreSpec> as =
            src && src->getCalledFunction() ? abi::parseCore(src->getCalledFunction()->getName()) : std::nullopt;
        if (cs && cs->op == abi::Core::Free && as && as->op == abi::Core::Alloc &&
            all_of(src->users(), [&](const User *u) {
              return u == fr || isa<PHINode>(u) || isa<SelectInst>(u) ||
                     (isa<CallInst>(u) && cast<CallInst>(u)->getCalledFunction() &&
                      cast<CallInst>(u)->getCalledFunction()->getName() == "cqrt_push");
            }))
          continue;
      }
      if (isa<CallInst>(*it))
        unimplemented("loops-classical: a non-diagonal gate in a classically bounded loop on a rail that is not "
                      "made in its own trip, while the reverse loop still undoes a record (rule 5's invariant "
                      "across trips: a later trip's gate may touch a rail an earlier trip's record read)",
                      crossGate);
    }
  };

  // Rule 5's invariant within the deferral (cq-vqid): an item the reverse loop undoes reads the rails
  // its records read, and they must still hold the value those records read. A non-diagonal gate
  // in the region on such a rail (a merge read reads every arm it may name) that can run after one
  // of the item's forward records, before the rail is made again, rotates it under the deferred
  // undo: the same trip after the record, or a later trip of an enclosing loop of the region on a
  // rail that the trip does not make again. cq::unimplemented (the undo is never placed before the
  // gate: it waits for the reverse loop).
  struct Gate {
    CallInst *call;
    Value *target;
  };
  std::vector<Gate> gates;
  for (unsigned si = 0; si < n; ++si)
    for (BasicBlock *sbb : blocksOf[si])
    for (Instruction &I : *sbb)
      if (auto *call = dyn_cast<CallInst>(&I))
        if (Function *callee = call->getCalledFunction())
          if (std::optional<abi::CoreSpec> cs = abi::parseCore(callee->getName());
              cs && !cs->unc && (cs->op == abi::Core::Ry || cs->op == abi::Core::RyQAngle))
            gates.push_back({call, call->getArgOperand(cs->ctl ? 1 : 0)});
  std::vector<CallInst *> fwdRecords;
  for (const Seg &s : segs)
    for (const Record &r : U.scopeRecords(s.scope))
      fwdRecords.push_back(r.forward);
  auto leavesOf = [&](Value *v) {
    SmallVector<Value *, 4> out, work{v};
    SmallPtrSet<Value *, 8> seen;
    while (!work.empty()) {
      Value *x = work.pop_back_val();
      if (!seen.insert(x).second)
        continue;
      if (auto *p = dyn_cast<PHINode>(x); p && p->getType() == i32) {
        for (Value *in : p->incoming_values())
          work.push_back(in);
        continue;
      }
      if (auto *sl = dyn_cast<SelectInst>(x); sl && sl->getType() == i32) {
        work.push_back(sl->getTrueValue());
        work.push_back(sl->getFalseValue());
        continue;
      }
      if (!isa<Constant>(x))
        out.push_back(x);
    }
    return out;
  };
  // May G run after f, on a path that does not make `rail` again? f == nullptr: f is before the region.
  auto runsAfter = [&](const Instruction *f, const Instruction *G, const Value *rail) {
    if (!f || !region.count(f->getParent()))
      return true;
    if (f->getParent() == G->getParent() && f->comesBefore(G))
      return true;
    auto *d = dyn_cast<Instruction>(rail);
    const BasicBlock *db = d && region.count(d->getParent()) ? d->getParent() : nullptr;
    SmallVector<const BasicBlock *, 8> work;
    SmallPtrSet<const BasicBlock *, 16> seen;
    for (const BasicBlock *b : successors(f->getParent()))
      work.push_back(b);
    while (!work.empty()) {
      const BasicBlock *b = work.pop_back_val();
      if (!(region.count(b) || subBlocks.count(b)) || !seen.insert(b).second)
        continue;
      if (b == db) {
        if (G->getParent() == b && G->comesBefore(d))
          return true;
        continue;
      }
      if (G->getParent() == b)
        return true;
      for (const BasicBlock *nb : successors(b))
        work.push_back(nb);
    }
    return false;
  };
  auto checkUndoneReads = [&](BasicBlock *bb) {
    if (gates.empty())
      return;
    for (Instruction &I : *bb) {
      auto *m = dyn_cast<CallInst>(&I);
      Function *callee = m ? m->getCalledFunction() : nullptr;
      if (!callee)
        continue;
      StringRef name = callee->getName();
      SmallVector<Value *, 4> args(m->args());
      // The forward records this item undoes: the call it was spelled from (the same name, or the
      // name + "_unc"; the forward argument list, after the out handle for a template).
      SmallVector<const Instruction *, 2> anchors;
      for (CallInst *fwd : fwdRecords) {
        StringRef fn = fwd->getCalledFunction() ? fwd->getCalledFunction()->getName() : StringRef();
        if (fn.empty() || !(name == fn || name == (fn + "_unc").str()))
          continue;
        SmallVector<Value *, 4> fa(fwd->args());
        bool same = args == fa;
        bool withOut = !same && args.size() == fa.size() + 1 && args[0] == fwd &&
                       std::equal(fa.begin(), fa.end(), args.begin() + 1);
        if (same || withOut)
          anchors.push_back(fwd);
      }
      if (anchors.empty()) {
        // A free (or an item with no forward call of its own): its rails are read from their
        // definitions on.
        for (Value *a : args)
          if (a->getType() == i32 && !isa<Constant>(a))
            for (Value *l : leavesOf(a))
              anchors.push_back(dyn_cast<Instruction>(l));
      }
      for (Value *a : args) {
        if (a->getType() != i32 || isa<Constant>(a))
          continue;
        for (Value *l : leavesOf(a))
          for (const Gate &g : gates)
            for (Value *t : leavesOf(g.target))
              if (t == l)
                for (const Instruction *f : anchors)
                  if (runsAfter(f, g.call, l))
                    unimplemented("loops-classical: a non-diagonal gate in a classically bounded loop on a rail "
                                  "that a record undone by the reverse loop reads, after that record (rule 5: "
                                  "the reverse loop would undo it against the rotated rail)",
                                  g.call);
      }
    }
  };

  BasicBlock *Z = newBlock();
  std::vector<BasicBlock *> R(n);
  for (unsigned i = 0; i < n; ++i)
    R[i] = newBlock();
  Instruction *anchor = nullptr;   // a reverse instruction for the uses of the external initial rails

  for (unsigned i = n; i-- > 0;) {
    IRBuilder<> B(R[i]);
    U.emitMirror(segs[i].scope, B);
    checkUndoneReads(R[i]);
    checkDeferred(R[i], R[i]->begin());
    std::vector<Instruction *> mirror;
    for (Instruction &I : *R[i])
      mirror.push_back(&I);
    // The forward values the mirror reads: popped here, pushed at the end of the segment.
    std::vector<Value *> needs;
    for (Instruction *I : mirror)
      for (Use &u : I->operands())
        if (auto *d = dyn_cast<Instruction>(u.get()); d && region.count(d->getParent()) && !is_contained(needs, d)) {
          if (!dom[i].test(segOf.lookup(d->getParent())))
            internalError("loops-classical: a mirror item reads a value defined in a segment that does not dominate "
                          "its own",
                          d);
          needs.push_back(d);
        }
    DenseMap<Value *, Value *> popped;
    {
      IRBuilder<> P(R[i], R[i]->begin());
      for (unsigned k = needs.size(); k-- > 0;)
        popped[needs[k]] = popValue(P, pop, needs[k]->getType(), M.getDataLayout());
    }
    for (Instruction *I : mirror)
      for (Use &u : I->operands())
        if (auto it = popped.find(u.get()); it != popped.end())
          u.set(it->second);
    {
      IRBuilder<> Pu(segs[i].bb->getTerminator());
      for (Value *v : needs)
        pushValue(Pu, push, v, M.getDataLayout());
    }
    // Where the reverse goes next: the reverse of the forward predecessor.
    SmallVector<BasicBlock *, 4> uniq;
    for (BasicBlock *p : predsOf(i))
      if (!is_contained(uniq, mapPred(p)))
        uniq.push_back(mapPred(p));
    auto back = [&](BasicBlock *p) { return region.count(p) ? R[segOf.lookup(p)] : Z; };
    if (uniq.size() == 1) {
      B.CreateBr(back(uniq[0]));
      continue;
    }
    BasicBlock *hd = headOf[i];
    PHINode *cf = PHINode::Create(i32, pred_size(hd), "from");
    cf->insertInto(hd, hd->begin());
    for (BasicBlock *p : predecessors(hd))
      cf->addIncoming(ConstantInt::get(i32, find(uniq, mapPred(p)) - uniq.begin()), p);
    // After any item placed in the segment (a trip-local sub-loop's reverse pops the frames under it).
    BasicBlock *pb = segs[i].bb;
    IRBuilder<>(pb, pb->getFirstInsertionPt()).CreateCall(push, {cf});
    CallInst *k = B.CreateCall(pop);
    if (!anchor && any_of(uniq, [&](BasicBlock *p) { return !region.count(p); }))
      anchor = k;
    SwitchInst *sw = B.CreateSwitch(k, back(uniq[0]), uniq.size() - 1);
    for (unsigned j = 1; j < uniq.size(); ++j)
      sw->addCase(ConstantInt::get(i32, j), back(uniq[j]));
  }

  // The reverse starts at the reverse of the segment that exits; guarded (cq-fx3s), only where the
  // loop ran: the value "the loop's exit block was passed" (false at the function's entry, true at
  // X), read at the start of the item.
  BasicBlock *join = nullptr;
  BasicBlock *guardBlock = BX.GetInsertBlock();
  {
    BasicBlock *exitSeg = nullptr;
    for (BasicBlock *p : predecessors(X)) {
      if (!region.count(p) || (exitSeg && exitSeg != p))
        internalError("loops-classical: the loop's exit block is not reached from exactly one segment");
      exitSeg = p;
    }
    BasicBlock *start = R[segOf.lookup(exitSeg)];
    Value *ran = ConstantInt::getTrue(C);
    if (guarded) {
      // a trip-local sub-loop's guard is reset per parent trip (false at the end of resetAt)
      ran = carryTo(guardBlock, X, ConstantInt::getTrue(C), ConstantInt::getFalse(C), "ran", resetAt);
    }
    if (auto *k = dyn_cast<ConstantInt>(ran); k && k->isOne()) {
      BX.CreateBr(start);
    } else {
      join = newBlock();
      BX.CreateCondBr(ran, start, join);
    }
  }
  if (!anchor && !externalInits.empty())
    internalError("loops-classical: no reverse instruction reads the loop's initial rails");
  for (Value *h : externalInits)
    U.noteUse(U.idOf(h), anchor);
  IRBuilder<> BZ(Z);
  U.emitMirror(seedScope, BZ);
  checkUndoneReads(Z);
  checkDeferred(Z, Z->begin());
  if (join) {
    // A value from before the region the reverse reads (a seed of the entry E, a rail made on the
    // loop's path only) need not dominate the guarded start: it is read through a phi that names it on
    // the paths where the loop ran (poison where it did not: the reverse does not run there).
    DenseSet<const BasicBlock *> rev(R.begin(), R.end());
    rev.insert(Z);
    std::vector<Use *> outside;
    for (BasicBlock *b : R)
      for (Instruction &I : *b)
        for (Use &u : I.operands())
          if (auto *d = dyn_cast<Instruction>(u.get()); d && !rev.count(d->getParent()))
            outside.push_back(&u);
    for (Instruction &I : *Z)
      for (Use &u : I.operands())
        if (auto *d = dyn_cast<Instruction>(u.get()); d && !rev.count(d->getParent()))
          outside.push_back(&u);
    DenseMap<std::pair<Instruction *, BasicBlock *>, Value *> carried;
    for (Use *u : outside) {
      auto *d = cast<Instruction>(u->get());
      if (d->getParent() == &Out.getEntryBlock())
        continue;
      // the value at the use: at the end of the incoming block for a phi, else at the end of the
      // block before the reverse (the guard's block dominates every reverse block)
      auto *ui = cast<Instruction>(u->getUser());
      BasicBlock *at = isa<PHINode>(ui) ? cast<PHINode>(ui)->getIncomingBlock(*u) : guardBlock;
      Value *&c = carried[{d, at}];
      if (!c)
        c = carryTo(at, d->getParent(), d, PoisonValue::get(d->getType()), d->getName());
      u->set(c);
    }
    BZ.CreateBr(join);
    BX.SetInsertPoint(join);
  } else {
    BX.SetInsertPoint(Z);
  }
}

void Unit::run(Case c) {
  E = ctx.B().GetInsertBlock();
  cur = E;
  BasicBlock *X = newBlock();
  lowerLoop(top, c, X, true);
  resolvePreheader();
}

// cq-ot39 (CR rule 5, U5): -O1's LICM hoists a quantum loop invariant into the loop's guarded preheader
// (179's x[j] view, a shift or mul of a register). When the preheader does not dominate the loop's exit
// block (the guard's skip edge joins there), no flush can place the rail's item: it is resolved here, on
// the loop's own exit path, once the loop (and its reverse) has read it. Only template results defined in
// the preheader and read nowhere but there and in the loop.
void Unit::resolvePreheader() {
  BasicBlock *pre = top.getLoopPredecessor();
  BasicBlock *exitB = exits::liveExit(top);
  if (!pre || !exitB)
    return;
  DominatorTree DT(*pre->getParent());
  if (DT.dominates(pre, exitB))
    return;
  std::vector<RailId> rails;
  for (Instruction &I : *pre) {
    if (I.isTerminator() || !isQ(&I) || isa<CallBase>(I) || isa<PHINode>(I))
      continue;
    bool inside = true;
    for (const User *u : I.users()) {
      auto *ui = dyn_cast<Instruction>(u);
      inside &= ui && (ui->getParent() == pre || top.contains(ui));
    }
    if (!inside)
      continue;
    Operand op = ctx.operand(&I);
    auto *ci = op.handle ? dyn_cast<CallInst>(op.v) : nullptr;
    if (!ci || !ci->getCalledFunction() || !ci->getCalledFunction()->getName().starts_with("cq_template_"))
      continue;   // a view naming its operand's rail, or a value that is not a fresh template result
    RailId r = ctx.unc().idOf(op.v);
    if (!is_contained(rails, r))
      rails.push_back(r);
  }
  // A deferred reverse (cq-fx3s) reads the hoisted rails after the loop's exit: their items wait for it
  // (Uncompute::recordDeferred's reads) and follow it wherever it is placed.
  if (rails.empty() || deferred)
    return;
  IRBuilder<> &B = ctx.B();
  BasicBlock *Cont = newBlock();
  BranchInst *br = B.CreateBr(Cont);
  ctx.unc().resolveAt(br, rails);
  B.SetInsertPoint(Cont);
}

} // namespace

void lowerClassical(LoweringContext &ctx, Loop &L, Case c) {
  if (c == Case::QuantumExit)
    internalError("loops-classical: lowerClassical of a quantum-exit loop (loops-cutoff)", L.getHeader()->getTerminator());
  std::make_shared<Unit>(ctx, L)->run(c);
}

} // namespace cq::loops
