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
//  An update chain may sit past a quantum arm's merge, and a merge of an arm's update with the carried value
//  itself is cleaned with the composite inverse, its final rail kept whether read or not; a bus load copy as
//  the initial rail is excepted on trip 0 under a classical branch (planRuleSixMerges, 109).
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
#include "cq/Bus.h"
#include "cq/Predicate.h"
#include "cq/Switch.h"
#include "../../spine/SpineInternal.h"

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

namespace {
cq::RailType railOf(Type *t) { return t->isPointerTy() ? cq::RailType{cq::Kind::Int, 64} : cq::railTypeOf(t); }
} // namespace

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


bool samePred(const Pred &a, const Pred &b) { return (a & !b).isBottom() && (b & !a).isBottom(); }

// CR rule 6's bijections in y (the list of rule 6, but a select of updates and a controlled swap,
// which a carried value's single reader cannot be): add, sub, xor with an operand other than y, mul
// by an odd literal, fneg, bswap, bitreverse, fshl/fshr with y in both value slots.
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
  if (auto *g = dyn_cast<GetElementPtrInst>(&U)) {   // rule 3: a pointer is an i64, a constant gep an add
    APInt off(64, 0);
    return g->getPointerOperand() == Y && g->accumulateConstantOffset(g->getDataLayout(), off);
  }
  if (auto *II = dyn_cast<IntrinsicInst>(&U)) {
    Intrinsic::ID id = II->getIntrinsicID();
    if (id == Intrinsic::bswap || id == Intrinsic::bitreverse)
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
  spec.w = railOf(U.getType());
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
  if (auto *g = dyn_cast<GetElementPtrInst>(&U)) {
    APInt off(64, 0);
    g->accumulateConstantOffset(g->getDataLayout(), off);
    spec.op = "sub";
    return normalized(spec, {yp, Operand{ConstantInt::get(ctx.M.getContext(), off), false}});
  }
  auto *II = cast<IntrinsicInst>(&U);
  if (II->getIntrinsicID() == Intrinsic::bswap || II->getIntrinsicID() == Intrinsic::bitreverse) {
    spec.op = II->getIntrinsicID() == Intrinsic::bswap ? "bswap" : "bitreverse";   // an involution
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
  // cq-h5uj (CR rule 14, case 1 or 3 inside a K-loop trip): the loop runs inside one unrolled trip of an
  // enclosing quantum-exit loop, under that trip's rail `trip` (its effects controlled by it, a case-3 chain
  // seeded by it), on the classical path loops-cutoff branched on. Its reverse is deferred after the readers
  // of its exit values, guarded by "the loop's exit was passed" (the trip may skip the loop classically).
  Value *runInTrip(Case c, Value *trip) {
    outerTrip = trip;
    inTrip = true;
    run(c);
    return stopFinal;
  }
  Value *stopFinal = nullptr;   // the XOR of the arm flags of this unit, for the enclosing K-loop (nullptr: none)

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
    BasicBlock *head;   // bb unless a body instruction branched inside the trip (rule 5's Readers test)
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
  bool inTrip = false;     // cq-h5uj: lowered inside a K-loop trip (runInTrip)
  Value *stopCur = nullptr;   // the stop rail at the builder (see the mint in lowerLoop), nullptr when this unit has none
  unsigned copyScope = ~0u;   // cq-h5uj: the copies of exit values a per-trip loop reads in place
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
  // cq-pfpy: a composite phi's value per field at a mixed join's real edge (rule 26 over rule 9).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, SmallVector<Operand, 4>> edgeFieldsM;

  bool readersKeep(const Value *v);
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
    segs.push_back({bb, ctx.unc().openScope(), bb});
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
    return seed(o.v, railOf(ty));
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
  bool writesCallerCells(const CallBase &CB) const;
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
    // A merge of an arm's update with p itself (109's overflow_arg_area): the next value is the merge, cleaned with the
    // composite inverse a ? y' : U^-1(y'). Rule 6's rolled-loop clause: the trip predicate does not read p, the final
    // rail stays allocated whether or not it is read, and a bus load copy as the initial rail is excepted on trip 0.
    bool merge = false;
    bool initLoad = false;
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
  void planRuleSixMerges(Loop &L);
  void cleanInvariantOnExit(Loop &L, BasicBlock *T);
  // cq-j5mq: a loop with several classical exit edges into one exit block. T's phi naming the edge taken, and per edge
  // the segment block it leaves from: the reverse starts at that segment.
  PHINode *exitIndex = nullptr;
  std::vector<BasicBlock *> exitSegs;
  BasicBlock *unitExit = nullptr;   // the outermost loop's T
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

bool Unit::initDead(Loop &L, const Value *init, const PHINode *p) { return exits::initDead(ctx, L, init, p); }

void Unit::planRuleSix(Loop &L, Case c) {
  BasicBlock *header = L.getHeader(), *latch = L.getLoopLatch(), *pre = L.getLoopPredecessor();
  if (!pre)
    return;   // several entries: the initial value is a merge of them, undone by the reverse like any record
  if (exits::liveExiting(L) != latch || !exits::unitOf(L).abort.empty())
    return;   // a trip may end before the update: the exit value is not the chain's
  const bool c3 = c == Case::ClassicalBoundQuantumExit;
  if (!c3 && !qp(header).isTop())
    return;
  DominatorTree &DT = spine::shared(ctx).dt(F);
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
      // Run on every trip at the header's predicate: the header, or a block past a quantum arm's merge (109's s).
      if (!W || !L.contains(W) || !DT.dominates(W->getParent(), latch) || !samePred(qp(W->getParent()), qp(header)) ||
          !bijectiveIn(*W, x) || !isQ(W)) {
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

// Rule 6's rolled-loop clause on a carried value whose update is a merge in the trip: p' = phi [p, arm], [U(p), arm'] past
// a quantum branch whose condition does not read p. The other readers of p in the trip must not feed a carried value or
// anything else the reverse loop would undo: each is a kept store's value, or reaches only a chain planned above.
void Unit::planRuleSixMerges(Loop &L) {
  BasicBlock *header = L.getHeader(), *latch = L.getLoopLatch(), *pre = L.getLoopPredecessor();
  if (!pre || !qp(header).isTop() || exits::liveExiting(L) != latch || !exits::unitOf(L).abort.empty())
    return;
  DominatorTree &DT = spine::shared(ctx).dt(F);
  auto chainEnd = [&](const Value *v) {
    return any_of(plan6, [&](const R6 &r) { return r.U.back() == v; });
  };
  for (PHINode &p : header->phis()) {
    if (!isQ(&p) || r6Of(&p) || !(p.getType()->isIntegerTy() || p.getType()->isPointerTy()))
      continue;
    auto *M = dyn_cast<PHINode>(p.getIncomingValueForBlock(latch));
    if (!M || M->getParent() == header || !L.contains(M) || M->getNumIncomingValues() != 2 ||
        !DT.dominates(M->getParent(), latch) || !samePred(qp(M->getParent()), qp(header)))
      continue;
    unsigned self = M->getIncomingValue(0) == &p ? 0 : 1;
    auto *Up = dyn_cast<Instruction>(M->getIncomingValue(1 - self));
    if (M->getIncomingValue(self) != &p || !Up || !L.contains(Up) || !isQ(Up) || !bijectiveIn(*Up, &p))
      continue;
    // The branch deciding the merge.
    auto *node = DT.getNode(M->getParent());
    auto *br = node && node->getIDom() ? dyn_cast<BranchInst>(node->getIDom()->getBlock()->getTerminator()) : nullptr;
    if (!br || !br->isConditional() || !isQ(br->getCondition()))
      continue;
    // Does a value depend on p, inside the trip? A load or call in the way counts as a dependence.
    bool ok = true;
    DenseSet<const Value *> seen;
    SmallVector<const Value *, 8> work{br->getCondition()};
    while (ok && !work.empty()) {
      const Value *v = work.pop_back_val();
      auto *I = dyn_cast<Instruction>(v);
      if (!I || !L.contains(I) || !seen.insert(v).second)
        continue;
      if (v == &p || I->mayReadOrWriteMemory())
        ok = false;
      else
        work.append(I->op_begin(), I->op_end());
    }
    // Who p reaches: nothing carried but through M, nothing past the loop.
    seen.clear();
    work.assign({&p});
    while (ok && !work.empty()) {
      const Value *v = work.pop_back_val();
      if (!seen.insert(v).second)
        continue;
      for (const User *usr : v->users()) {
        auto *ui = dyn_cast<Instruction>(usr);
        if (ui == M || chainEnd(ui))
          continue;
        if (auto *st = dyn_cast_or_null<StoreInst>(ui); st && st->getValueOperand() == v && L.contains(st))
          continue;   // a kept store's value rail: no _unc reads p
        if (!ui || !L.contains(ui) || isa<CallBase>(ui) || (isa<PHINode>(ui) && ui->getParent() == header) ||
            isa<StoreInst>(ui)) {
          ok = false;
          break;
        }
        work.push_back(ui);
      }
    }
    if (!ok)
      continue;
    const Value *init = p.getIncomingValueForBlock(pre);
    R6 r{&p, {Up}, false, initDead(L, init, &p)};
    r.merge = true;
    r.initLoad = isa<LoadInst>(init) && isQ(init);
    plan6.push_back(std::move(r));
  }
}

// CR rule 6 in a rolled loop (75): a loop-invariant kept rail x (a rotated register) whose only reader is an update
// y = f(x, z) run in every trip, a bijection in x, with y kept in every trip (a kept store's value rail): nothing will
// ever uncompute through x, so it is cleaned from the last trip's image on the exit edge, at T. A zero-trip path never
// reaches T: x stays the live register there.
void Unit::cleanInvariantOnExit(Loop &L, BasicBlock *T) {
  BasicBlock *latch = L.getLoopLatch();
  if (!latch || exits::liveExiting(L) != latch || !exits::unitOf(L).abort.empty())
    return;
  DominatorTree DT(F);
  Module &M = Mod;
  for (BasicBlock *b : L.blocks()) {
    if (!DT.dominates(b, latch) || !qp(b).isTop())
      continue;
    for (Instruction &Y : *b) {
      if (!isQ(&Y) || !ctx.bound(&Y) || isa<PHINode>(Y))
        continue;
      for (Value *X : Y.operands()) {
        if (isa<Constant>(X) || !isQ(X) || !bijectiveIn(Y, X) || !ctx.bound(X))
          continue;
        if (auto *XI = dyn_cast<Instruction>(X); XI && L.contains(XI))
          continue;
        if (!all_of(X->users(), [&](const User *u) { return u == &Y; }))
          continue;
        Operand xo = ctx.operand(X), yo = ctx.operand(&Y);
        if (!xo.handle || !yo.handle || !isa<CallInst>(xo.v))
          continue;
        std::optional<Role> xr = U.liveRole(U.idOf(xo.v)), yr = U.liveRole(U.idOf(yo.v));
        if (!xr || !yr || (*xr != Role::UserRegister && *xr != Role::Frozen) || *yr != Role::Kept)
          continue;
        Inv inv = inverseOf(ctx, Y, X, yo);
        SmallVector<Value *, 3> args;
        for (const Operand &o : inv.ops)
          args.push_back(o.v);
        IRBuilder<> &B = ctx.B();
        Value *t = B.CreateCall(abi::declare(M, inv.spec, false), args);
        B.CreateCall(abi::declare(M, abi::CoreSpec{abi::Core::Copy, railOf(Y.getType())}), {t, xo.v});
        SmallVector<Value *, 4> uargs{t};
        uargs.append(args.begin(), args.end());
        B.CreateCall(abi::declare(M, inv.spec, true), uargs);
        FunctionCallee fr = abi::declare(M, abi::CoreSpec{abi::Core::Free});
        B.CreateCall(fr, {t});
        B.CreateCall(fr, {xo.v});
        for (const Operand &o : inv.ops)
          if (o.handle)
            U.noteUse(U.idOf(o.v), cast<Instruction>(t));
      }
    }
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

// Does the clone call write a caller cell (a minted or forwarded slot result through a pointer argument)?
bool Unit::writesCallerCells(const CallBase &CB) const {
  const Specialization *S = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!S)
    return false;
  (void)S;
  return false;   // rule 18: a clone writes the bus at its address, no caller cell (W5: writesMemory)
}

bool Unit::twinOf(const CallBase &CB) const {
  const Specialization *S = ctx.T.calleeSpecialization(CB, ctx.S);
  if (!S)
    return true;
  if (!CB.getType()->isVoidTy() && is_contained(ctx.T.fieldMask(&CB, ctx.S), true))
    return true;
  return false;
}

void Unit::check(Loop &L, Case c) {
  if (!L.getLoopLatch())
    unimplemented("loops-classical: a rule-14 loop with more than one latch", L.getHeader()->getTerminator());
  // An exit into an effect-free dead end (131's unreachable switch default) is UB to take: no exit. A
  // case-3 loop with several exits (121) is lowerLoop's multi-exit form.
  if (c != Case::ClassicalBoundQuantumExit && (!exits::liveExiting(L) || !exits::liveExit(L)))
    unimplemented("loops-classical: a rule-14 loop with more than one exiting block or exit block",
                  L.getHeader()->getTerminator());
  for (PHINode &p : L.getHeader()->phis())
    if (isQ(&p) && !(p.getType()->isIntegerTy() || p.getType()->isFloatingPointTy()) &&
        !p.getType()->isPointerTy())   // rule 3: a carried pointer is an i64 handle
      unimplemented("loops-classical: a quantum carried value of non-scalar type (aggr, rule 3)", &p);
  for (BasicBlock *b : L.blocks())
    for (Instruction &I : *b) {
      if (isa<DbgInfoIntrinsic>(I))
        continue;
      // CR rule 20: a store in a case-3 trip runs under the trip rail, a quantum predicate (a select into a
      // fresh rail, rule 9): mem's stores take currentFlag(), the trip rail & the block's quantum part, as their
      // control (cq-k471), and the reverse loop undoes the select with the trip's pushed operands.
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
        case calls::Class::Fenv:
          // Rule 23 inside a rule-14 trip: a constrained op is a template (or the host op) of the trip like
          // any opcode, recorded in the trip's scope and mirrored by the reverse; a <fenv.h> call that leaves
          // the quantum part alone is the host call. A change of the quantum part inside the loop (its
          // loop-carried state) is eff-fenv's own construction (requirePlaced).
          break;
        case calls::Class::Lift:
        case calls::Class::LibmIntrinsic:
        case calls::Class::Declared:
          // Rule 27 inside a rule-14 trip: a declared clone is a call group like a lifted one (its twin always
          // exists), its _ctl form under the trip rail in case 3 (cq-ro82).
          // Rule 18 inside a rule-14 trip (124): a clone call with nothing to undo (no quantum result, no
          // caller cell it writes) records no call item, so each trip's call is a gate sequence of its own.
          // One with a twin (a quantum result) is a call group recorded in the trip's scope: the reverse
          // emits its twin with the trip's pushed operands, as it emits a template's _unc (Uncompute's item
          // of a call group). A clone writing caller cells in the trip (slot results across trips) is the
          // default below.
          // Case 3: the call runs under the trip rail (currentFlag(): its _ctl clone, rules 19, 27; calls tests
          // the trip rail, cq-ro82), recorded in the trip's scope like case 1's.
          if (!twinOf(*CB) || !writesCallerCells(*CB))
            break;
          [[fallthrough]];
        default:
          unimplemented("loops-classical: a call of this class inside a rule-14 loop (calls-loops / loops-mem "
                        "integration)",
                        &I);
        }
        continue;
      }
      if (isa<LoadInst>(I) || isa<StoreInst>(I))
        continue;   // rules 5, 20: per trip, by the spine's dispatch
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
  // A quantum exit into a noreturn arm (rule 16) has this form too: e = a & f is the arm's flag, its abort_i1 made at the
  // exit test (the arm is no part of the continuation), the trip going on under a' = a & NOT f.
  exits::Unit UX = exits::unitOf(L);
  const bool mx = c3 && (UX.multi() || exits::liveExiting(L) != latch || !UX.abort.empty());
  // With every quantum exit into a noreturn arm the trip that leaves for C is the last one the classical bound gives, so a
  // classical value of the loop keeps its classical exit value (taint's dead-end rule, 45): no capture.
  bool noLiveQ = true;
  {
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    for (BasicBlock *u : exiting) {
      const Instruction *t = u->getTerminator();
      const Value *cnd = nullptr;
      if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
        cnd = br->getCondition();
      else if (auto *sw = dyn_cast<SwitchInst>(t))
        cnd = sw->getCondition();
      else if (auto *ib = dyn_cast<IndirectBrInst>(t))
        cnd = ib->getAddress();
      if (cnd && isQ(cnd) && any_of(successors(u), [&](BasicBlock *x) { return !L.contains(x) && is_contained(UX.live, x); }))
        noLiveQ = false;
    }
  }
  if (!mx && (!exits::liveExiting(L) || !exitB))
    unimplemented("loops-classical: a rule-14 loop with more than one exiting block or exit block",
                  header->getTerminator());
  if (c3 && !mx && exits::liveExiting(L) != latch)
    unimplemented("loops-classical: a quantum exit test that is not the latch's (rule 14 case 3)",
                  exits::liveExiting(L)->getTerminator());
  auto inUnit = [&](const BasicBlock *b) { return UX.contains(L, b); };
  // cq-j5mq: several classical exit edges into one exit block (a `break` on a classical test): each edge is a real
  // branch to T. The exit block's phis are bound at T, over the edges.
  const bool cx = !c3 && outermost && !exits::liveExiting(L);
  // A sub-loop's classical edges are real branches to wherever they go, in its parent or out of the unit.
  if (outermost)
    unitExit = T;

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
          if (auto *xp = dyn_cast<PHINode>(ui); cx && xp && xp->getParent() == exitB && L.contains(xp->getIncomingBlock(us)))
            continue;   // read by the exit block's phi on its edge: bound at T
          if (auto *xp = dyn_cast<PHINode>(ui);
              cx && UX.multi() &&
              (UX.contains(L, ui->getParent()) || (xp && xp->getParent() == UX.cont && inUnit(xp->getIncomingBlock(us)))))
            continue;   // read by the exit arm (it runs in the exit edge's segment) or by C's phi on a unit edge
          if (mx) {
            if (noLiveQ && !isQ(&I))
              continue;
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
          // A classical pointer read after the loop stays classical (taint cq-1v3i: an address is evaluated per
          // trip, never a rail); a classical scalar of a case-3 loop is captured below.
          if (!c3 || isQ(&I) || !I.getType()->isPointerTy())
            liveOut.push_back(&I);
          break;
        }
  struct CPhi {
    PHINode *P;                     // a phi of C, or nullptr for a read after the loop (xreads)
    const Instruction *x = nullptr; // that read's loop value: its incoming on every unit edge into C
    SmallVector<PHINode *, 2> cap;  // the carried capture rails, one per field
    SmallVector<Value *, 2> res;    // this trip's res, one per field
    SmallVector<Value *, 2> atCx;   // the captures as cxb's classical exit into the arm sees them (cxArm)
    SmallVector<RailType, 2> rails; // the fields' rail types
    bool ptr = false;
    bool shaped = false;
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
  BasicBlock *cxArm = nullptr;                      // the arm block cxb's classical exit edge enters (nullptr: C itself)
  std::unique_ptr<LoopInfo> mxLI;
  DenseMap<const BasicBlock *, Loop *> armUnit;     // a block of a loop of the exit arm's unit -> that loop
  // Classical exit edges into the exit arm (case 3: cxb's; case 1, cq-y7kw: each classical exit edge not into C): each
  // runs the arm once, in a segment of its own after the trips.
  struct ArmExit {
    ArmExit(BasicBlock *u, BasicBlock *x, BasicBlock *Y) : u(u), x(x), Y(Y) {}
    BasicBlock *u, *x, *Y;
    BasicBlock *end = nullptr;                      // where that segment leaves for T
    DenseMap<const PHINode *, Operand> contVal;     // case 1: C's phis on this edge
  };
  SmallVector<ArmExit, 2> armExits;
  BasicBlock *tgtFrom = nullptr;                    // the block whose terminator is being emitted
  SmallVector<Disj, 4> mixedDs;   // cq-h8y6: the classical disjuncts of a mixed exit test at cxb (empty: cxb is classical)
  auto buildArmUnits = [&]() {
    if ((UX.arm.empty() && UX.abort.empty()) || mxLI)
      return;
    mxLI = std::make_unique<LoopInfo>(*mxDT);
    for (auto *blocks : {&UX.arm, &UX.abort})
      for (BasicBlock *a : *blocks) {
        Loop *l = mxLI->getLoopFor(a), *last = nullptr;
        for (; l && !l->contains(header); l = l->getParentLoop())
          last = l;
        if (!last || armUnit.count(last->getHeader()))
          continue;
        exits::Unit SU = exits::unitOf(*last);
        for (BasicBlock *b : last->blocks())
          armUnit[b] = last;
        for (auto *list : {&SU.arm, &SU.abort, &SU.dead})
          for (BasicBlock *b : *list)
            if (is_contained(*blocks, b) && b != UX.cont)
              armUnit[b] = last;
      }
  };
  // cq-y7kw (CR rule 14 case 1 with rules 8, 9): a classically bounded loop whose classical exits reach several exit
  // blocks. Each exit edge is a real branch; an exit into the arm runs the arm in a segment of its own, under the loop's
  // predicate, and C's phis take that edge's value (the cx form's copy-out at T).
  const bool c1Arm = cx && UX.multi();
  if (c1Arm) {
    mxDT = std::make_unique<DominatorTree>(*header->getParent());
    buildArmUnits();
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    for (BasicBlock *u : exiting)
      for (BasicBlock *x : successors(u))
        if (!L.contains(x) && x != UX.cont && is_contained(UX.live, x) &&
            none_of(armExits, [&](const ArmExit &e) { return e.u == u && e.x == x; }))
          armExits.emplace_back(u, x, newBlock());
  }
  if (mx) {
    SmallVector<BasicBlock *, 4> exiting;
    L.getExitingBlocks(exiting);
    SmallVector<BasicBlock *, 2> abortTests;   // purely classical tests with an edge into a noreturn arm
    for (BasicBlock *u : exiting) {
      if (none_of(successors(u), [&](BasicBlock *s) { return !L.contains(s) && is_contained(UX.live, s); })) {
        // Only into dead ends: an effect-free one is UB to reach; a noreturn arm on a classical test is below.
        const Instruction *ut = u->getTerminator();
        auto *ubr = dyn_cast<BranchInst>(ut);
        const Value *uc = ubr ? (ubr->isConditional() ? ubr->getCondition() : nullptr)
                              : isa<SwitchInst>(ut) ? cast<SwitchInst>(ut)->getCondition() : nullptr;
        if (uc && !isQ(uc) && any_of(successors(u), [&](BasicBlock *s) { return is_contained(UX.abort, s); }))
          abortTests.push_back(u);
        continue;
      }
      auto *br = dyn_cast<BranchInst>(u->getTerminator());
      if (br && br->isConditional() && isQ(br->getCondition()))
        continue;
      if (auto *sw = dyn_cast<SwitchInst>(u->getTerminator()); sw && isQ(sw->getCondition()))
        continue;
      if (auto *ib = dyn_cast<IndirectBrInst>(u->getTerminator()); ib && isQ(ib->getAddress()))
        continue;   // rule 13: a quantum computed goto is a quantum exit test
      if (cxb)
        unimplemented("loops-classical: a multi-exit case-3 loop with more than one classical exit test",
                      u->getTerminator());
      cxb = u;
    }
    // cq-h8y6 (CR rule 14 case 3, "a mixed exit c_classical || q"): with no purely classical exit test, the bound is
    // a classical disjunct of a quantum exit test (strncmp: `n && *r && *l == *r` at the header). That block is the
    // classical exit test for its classical disjuncts (the loop branches on them) and a quantum exit for the whole
    // test: e = a & f, f the flag of the exit condition with its classical terms seeded (rule 8), so where a
    // classical disjunct holds the trip exits through it under a and the captures take its value. The header is
    // preferred, then the latch; another mixed exit stays a quantum exit (its classical terms seeded in its flag).
    SmallVector<BasicBlock *, 4> byPref{header, latch};
    for (BasicBlock *u : exiting)
      if (!is_contained(byPref, u))
        byPref.push_back(u);
    // A mixed test into a noreturn arm is the bound only where no mixed test into a live exit is.
    for (bool intoAbort : {false, true})
      for (BasicBlock *u : byPref) {
          if (cxb || !is_contained(exiting, u))
            continue;
          auto *br = dyn_cast<BranchInst>(u->getTerminator());
          if (!br || !br->isConditional() || !isQ(br->getCondition()) ||
              L.contains(br->getSuccessor(0)) == L.contains(br->getSuccessor(1)) ||
              none_of(successors(u), [&](BasicBlock *x) {
                return !L.contains(x) && (is_contained(UX.live, x) || (intoAbort && is_contained(UX.abort, x)));
              }))
            continue;
          SmallVector<Disj, 4> d;
          SmallPtrSet<const Value *, 8> inner;
          disjuncts(br->getCondition(), !L.contains(br->getSuccessor(0)), d, inner);
          SmallVector<Disj, 4> c;
          for (const Disj &x : d)
            if (!isQ(x.v))
              c.push_back(x);
          if (c.empty())
            continue;
          cxb = u;
          mixedDs = c;
        }
    // With no other classical exit a classical test into a noreturn arm is the bound itself (rule 14 "No live exit"): the
    // arm is the segment after the trips on that real edge. Any other such test is abortTest below, inside the trip.
    if (!cxb)
      for (BasicBlock *u : byPref)
        if (!cxb && is_contained(abortTests, u)) {
          cxb = u;
          for (BasicBlock *x : successors(u))
            if (is_contained(UX.abort, x))
              cxArm = x;
        }
    if (cxb && cxb != latch && cxb != header)
      unimplemented("loops-classical: a multi-exit case-3 loop whose classical exit test is neither its latch's nor "
                    "its header's",
                    cxb->getTerminator());
    auto *lbr = dyn_cast<BranchInst>(latch->getTerminator());
    if (!lbr)
      unimplemented("loops-classical: a multi-exit case-3 loop whose latch test is quantum", latch->getTerminator());
    // A quantum latch test is a quantum exit of the trip (e = a & f, the back edge taken under a & NOT f): the
    // classical bound is tested at the header (cq-nqa6, 117), or is a classical disjunct of the latch's own test or
    // of the header's (mixedDs above). Its back edge is the classical branch on the bound's disjuncts (at the latch)
    // or unconditional (the bound tested at the header).
    // The classical exit test may leave into the exit arm (strlen's alignment loop, strcpy's): a classical exit runs
    // once per activation, so the arm on that edge is no part of a trip. It is one more segment after the trips,
    // entered by the real branch and run under the trip predicate at that test (lowerClassicalExitArm below).
    // A mixed test at the header into the arm likewise (`while (q && m < N)`): where a classical disjunct holds the loop
    // leaves at the test, before the latch where the trip's quantum exits walk the arm.
    if (cxb && (mixedDs.empty() || (cxb == header && cxb != latch)))
      for (BasicBlock *x : successors(cxb))
        if (!L.contains(x) && x != UX.cont && is_contained(UX.live, x))
          cxArm = x;
    // The loops of the exit arm (Exits.h): each unit one node of the arm. armUnit: its blocks and its own arm's -> it.
    buildArmUnits();
    if (cxArm)
      armExits.emplace_back(cxb, cxArm, newBlock());
    for (BasicBlock *a : UX.arm)
      for (Instruction &I : *a) {
        // The arm's branches are flags of its blocks and edges, its phis rule 9 selects, its effects run
        // under its flag (latchExits).
        if (I.isTerminator() && !isa<BranchInst>(I) && !isa<SwitchInst>(I) && !isa<IndirectBrInst>(I))
          internalError("loops-classical: an exit arm block ending in other than a branch, switch or computed goto", &I);
        // A value of the arm read after the loop other than by C's phi: its block dominates the reader and so C
        // (SSA), every unit edge into C passes it in the exiting trip: a capture of its own (xreads), as a
        // loop value's.
        for (const Use &us : I.uses())
          if (auto *ui = cast<Instruction>(us.getUser()); !inUnit(ui->getParent()) &&
                                                         !(isa<PHINode>(ui) && ui->getParent() == UX.cont)) {
            if (isa<PHINode>(ui) || !mxDT->dominates(UX.cont, ui->getParent()) ||
                !(I.getType()->isIntegerTy() || I.getType()->isFloatingPointTy()))
              unimplemented("loops-classical: a value of a case-3 loop's exit arm read after the loop other than by a "
                            "phi of its continuation or a scalar read C dominates",
                            &I);
            if (!is_contained(xreads, &I))
              xreads.push_back(&I);
          }
      }
    const Pred hb = ctx.preds().block(header);
    if (UX.cont)
    for (PHINode &P : UX.cont->phis()) {
      bool fromUnit = any_of(P.blocks(), [&](const BasicBlock *u) { return inUnit(u); });
      if (!fromUnit)
        continue;
      if (noLiveQ && !isQ(&P))
        continue;   // its classical exit value: the walker binds it
      // A classical phi whose every incoming is one value from before the loop is that value wherever the loop exits
      // (the walker binds it); any other phi joining the exits holds the value of the edge the exiting trip took,
      // which depends on the quantum exit (rule 14: quantum), whatever its type: captured per field below.
      if (!isQ(&P)) {
        const Value *v0 = P.getIncomingValue(0);
        auto *vi = dyn_cast<Instruction>(v0);
        if (all_of(P.incoming_values(), [&](const Value *v) { return v == v0; }) && !(vi && inUnit(vi->getParent())))
          continue;
      }
      // cq-h8y6: an incoming from a tail block (Exits.h) on the outside paths, not classically excluded from the
      // unit: the walker selects it in over this binding (the unit's capture), a classical one it joins.
      for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
        if (BasicBlock *u = P.getIncomingBlock(i); is_contained(UX.tail, u)) {
          Pred e = exits::tailPred(ctx, L, UX, u, *mxDT) & ctx.preds().edge(u, UX.cont);
          if (!e.isBottom() && !(e & hb.classicalFactor(ctx.T, ctx.S)).isBottom())
            ctx.addJoinArm(&P, e, P.getIncomingValue(i));
        }
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
    // CR rule 14 (ruling 2026-11-02, cq-w3cd): a classical value of the loop read after it has a quantum exit
    // value (it depends on which trip the quantum exit ended; taint reads it as quantum there, cq-1v3i): it
    // takes a capture rail like a quantum value, cap_j = select(a_{j-1}, v_j, cap_{j-1}) with v_j the trip's
    // classical value, a record of the trip uncomputed by the reverse after its readers (nothing kept).
  }

  plan6.clear();
  // cq-h5uj: inside a K-loop trip the loop's final value is a value of that trip (the K-loop selects it into
  // its state and its mirror undoes the trip), never a register of the program: no rule 6 chain keeps it.
  if (outermost && !inTrip)
    planRuleSix(L, c);
    if (c != Case::ClassicalBoundQuantumExit)
      planRuleSixMerges(L);

  // Entry: the trip predicate, the seeds.
  unsigned seedScope = 0;
  Value *aInit = nullptr;
  BasicBlock *seedHead = ctx.B().GetInsertBlock();
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
  // CR rules 14, 16: inside a K-loop's trip an edge into a noreturn arm is an exit edge of that K-loop too (a_K, cq-9isy0).
  // The stop rail is the XOR of this unit's arm flags (at most one reads 1), an exit rail handed to the K-loop: carried like
  // the trip predicate, a fresh rail per arm flag (gates on fresh rails only).
  if (outermost && inTrip && exits::hasNoreturnArm(L)) {
    stopCur = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
    externalInits.push_back(stopCur);
  }
  else if (aInit && outermost)
    externalInits.push_back(aInit);
  BasicBlock *entryFrom = cur;
  struct Carried {
    PHINode *orig;
    PHINode *np;
    bool q;
    bool walked = false;   // cq-e6ky: a walked pointer carried as its trip index (walkedStep)
  };
  std::vector<Carried> carried;
  std::vector<std::pair<Value *, bool>> inits;
  // A header phi's start: its incoming from the preheader, or, with several blocks outside the loop entering
  // the header (no preheader), the one value they agree on, else their merge: the walker's classical phi of
  // its edges into the header (the spine's, bound before the unit, for the outermost loop; this walk's real
  // edges for a sub-loop), and for a quantum phi rule 9's select chain over the entry edges' predicates
  // (outermost) or a phi of handles over the real entry edges, a classical incoming seeded at the end of its
  // edge's output block (rule 7).
  SmallVector<BasicBlock *, 4> outsideP;
  for (BasicBlock *u : predecessors(header))
    if (!L.contains(u) && !is_contained(outsideP, u))
      outsideP.push_back(u);
  std::unique_ptr<DominatorTree> sDT = std::make_unique<DominatorTree>(*header->getParent());
  std::unique_ptr<LoopInfo> sLI = std::make_unique<LoopInfo>(*sDT);
  auto startOf = [&](PHINode &p) -> Operand {
    // The continuation of a loop just before this one: that unit bound p on its exit edge.
    if (isQ(&p) && exits::boundByLoopBefore(ctx, p, *sLI))
      return ctx.operand(&p);
    if (pre)
      return ctx.operand(p.getIncomingValueForBlock(pre));
    Value *v0 = p.getIncomingValueForBlock(outsideP.front());
    if (all_of(outsideP, [&](BasicBlock *u) { return p.getIncomingValueForBlock(u) == v0; }))
      return ctx.operand(v0);
    const bool q = isQ(&p);
    if (outermost) {
      if (!q) {
        Operand v = ctx.operand(&p);
        if (v.handle)
          internalError("loops-classical: a classical carried value's start bound to a rail", &p);
        return v;
      }
      std::vector<std::pair<Pred, Operand>> arms;
      for (BasicBlock *u : outsideP)
        arms.push_back({ctx.preds().edge(u, header), ctx.operand(p.getIncomingValueForBlock(u))});
      return Operand{selectChain(ctx, arms, railOf(p.getType())), true};
    }
    PHINode *np = PHINode::Create(q ? handleTy(ctx.M.getContext()) : p.getType(), outsideP.size(), p.getName());
    np->insertInto(cur, cur->getFirstNonPHIIt());
    for (BasicBlock *u : outsideP) {
      auto it = edgeFrom.find({u, header});
      if (it == edgeFrom.end() || pred_size(cur) != outsideP.size() || !is_contained(predecessors(cur), it->second))
        internalError("loops-classical: a sub-loop entered by several edges that are not real edges into its "
                      "entry block",
                      &p);
      Operand o = ctx.operand(p.getIncomingValueForBlock(u));
      if (q && !o.handle) {
        IRBuilderBase::InsertPointGuard g(ctx.B());
        ctx.B().SetInsertPoint(it->second->getTerminator());
        o = Operand{seed(o.v, railOf(p.getType())), true};
      }
      np->addIncoming(o.v, it->second);
    }
    if (q)
      ctx.unc().recordMerge(np);
    return Operand{np, q};
  };
  for (PHINode &p : header->phis()) {
    Operand o = startOf(p);
    bool q = isQ(&p);
    if (const R6 *r = q ? r6Of(&p) : nullptr) {
      // Trip 0 cleans the rail its phi names: a fresh seed, this function's own dead rail, or else a
      // copy of the initial value (which then stays as it is, as in straight-line code). Each is kept
      // for Uncompute: the trip's clean-up frees it.
      Value *h;
      if (!o.handle) {
        h = asHandle(o, p.getType());
      } else if (r->initLoad) {
        // Rule 5 sentence 1 decides the load copy: the phi names it, trip 0 does not clean it.
        externalInits.push_back(o.v);
        inits.push_back({o.v, true});
        continue;
      } else if (r->initDirect) {
        h = o.v;
      } else {
        RailType w = railOf(p.getType());
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
        RailType w = railOf(v->getType());
        capInits.push_back(seed(Constant::getNullValue(irTypeOf(ctx.M.getContext(), w)), w));
      }
    for (CPhi &cp : cphis) {
      Type *ty = cp.type();
      LLVMContext &C = ctx.M.getContext();
      if (ty->isAggregateType() || ty->isVectorTy()) {
        std::function<void(Type *)> leaves = [&](Type *t) {
          if (auto *st = dyn_cast<StructType>(t))
            for (Type *e : st->elements())
              leaves(e);
          else if (auto *at = dyn_cast<ArrayType>(t))
            for (uint64_t k = 0; k < at->getNumElements(); ++k)
              leaves(at->getElementType());
          else if (auto *vt = dyn_cast<FixedVectorType>(t))
            for (unsigned k = 0; k < vt->getNumElements(); ++k)
              leaves(vt->getElementType());
          else
            cp.rails.push_back(railOf(t));
        };
        leaves(ty);
      } else {
        cp.rails = {railOf(ty)};
      }
      // The capture's start: the value where no trip exits. A phi's incomings from outside the unit on a quantum edge
      // that excludes the loop (a pre-header guard, strlen's `!*s`) are taken exactly where the trip predicate is 0 from
      // the start: rule 9's select chain over those edges, built here; a classical skip is the walker's join.
      std::vector<std::pair<Pred, Operand>> outside;
      if (cp.P && cp.rails.size() == 1) {
        const Pred hb = ctx.preds().block(header);
        const Pred cH = hb.classicalFactor(ctx.T, ctx.S);
        for (unsigned i = 0; i < cp.P->getNumIncomingValues(); ++i) {
          BasicBlock *u = cp.P->getIncomingBlock(i);
          const Pred &e = ctx.preds().edge(u, UX.cont);
          if (inUnit(u) || (e & cH).isBottom() || !(e & hb).isBottom())
            continue;
          Value *v = cp.P->getIncomingValue(i);
          if ((!ctx.bound(v) && !isa<Constant>(v)) || !predReadable(ctx, e)) {
            ctx.addJoinArm(cp.P, e, v);   // lowered after the loop: the walker selects it in
            continue;
          }
          Operand o = ctx.operand(v);
          if (ty->isPointerTy() && !o.handle)
            o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(C)), false};
          outside.push_back({e, o});
        }
      }
      if (outside.size() == 1) {
        capInits.push_back(asHandle(outside.front().second, ty->isPointerTy() ? Type::getInt64Ty(C) : ty));
        continue;
      }
      if (outside.size() > 1) {
        capInits.push_back(selectChain(ctx, outside, cp.rails.front()));
        continue;
      }
      for (RailType w : cp.rails)
        capInits.push_back(seed(Constant::getNullValue(irTypeOf(C, w)), w));
    }
  }
  BasicBlock *H = newBlock();
  ctx.B().CreateBr(H);
  if (outermost) {
    ctx.unc().closeScope(seedScope);
    // Rules 5, 9, 14: a rail the entry's predicate minted on an edge into a join above the loop (a don't-care seed of a carried
    // flag: mbsrtowcs) exists on that edge's paths only, which the reverse's end does not imply; a flush frees it under its run flag.
    ctx.unc().leaveScope(seedScope, seedHead);
    segOpen = false;
  }
  startSeg(H);
  heads.push_back({H, entryFrom});
  {
    unsigned k = 0;
    for (PHINode &p : header->phis()) {
      auto [v, q] = inits[k++];
      PHINode *np = ctx.B().CreatePHI(q ? handleTy(ctx.M.getContext()) : v->getType(), 2, p.getName());
      np->addIncoming(v, entryFrom);
      if (q) {
        ctx.unc().recordExternal(np, Role::UserRegister);
        if (!r6Of(&p))
          ctx.unc().noteCarried(np);
      }
      if (ctx.bound(&p))
        ctx.rebind(&p, {Operand{np, q}});   // the spine's classical choice of several starts (its operand above)
      else
        ctx.bind(&p, np);
      carried.push_back({&p, np, q, false});
    }
  }
  PHINode *notFirst = nullptr;
  if (any_of(plan6, [&](const R6 &r) { return r.initLoad && L.contains(r.p); })) {
    notFirst = ctx.B().CreatePHI(Type::getInt1Ty(ctx.M.getContext()), 2, "nfirst");
    notFirst->addIncoming(ConstantInt::getFalse(ctx.M.getContext()), entryFrom);
  }
  PHINode *aPhi = nullptr;
  Value *aCur = nullptr;   // multi-exit: the trip predicate after the quantum exits so far
  if (c3) {
    aPhi = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "trip");
    aPhi->addIncoming(aInit, entryFrom);
    ctx.unc().recordExternal(aPhi, Role::UserRegister);
    aCur = aPhi;
    unsigned nf = 0;
    for (const CPhi &cp : cphis)
      nf += unsigned(cp.rails.size());
    unsigned at = unsigned(capInits.size()) - nf;
    for (CPhi &c : cphis)
      for (unsigned f = 0; f < c.rails.size(); ++f) {
        PHINode *cp = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "xcap");
        cp->addIncoming(capInits[at++], entryFrom);
        ctx.unc().recordExternal(cp, Role::UserRegister);
        c.cap.push_back(cp);
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

  PHINode *stopPhi = nullptr;
  if (stopCur) {
    stopPhi = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), 2, "stop");
    stopPhi->addIncoming(stopCur, entryFrom);
    ctx.unc().recordExternal(stopPhi, Role::UserRegister);
    stopCur = stopPhi;
  }

  // cq-h8y6: a value's fields as the continuation phi (or read after the loop) cp takes it, at the builder: a data
  // pointer's fat (tag, idx) at cp's exit shape (rule 21), an aggregate's or vector's scalar leaves (rule 26), a
  // scalar itself (a classical code address as its i64, rule 13).
  auto fieldsOf = [&](CPhi &cp, const Value *val) -> SmallVector<Operand, 2> {
    Type *ty = cp.type();
    if (ty->isAggregateType() || ty->isVectorTy()) {
      SmallVector<Operand, 4> fs = aggr::flattenResult(ctx, val);
      return SmallVector<Operand, 2>(fs.begin(), fs.end());
    }
    Operand o = ctx.operand(val);
    if (ty->isPointerTy() && !o.handle)
      o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(ctx.M.getContext())), false};
    return {o};
  };

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
  // CR rule 14 (nested K-loops, "inner chain seeded by the outer trip predicate"): a quantum-exit sub-loop
  // is one node of the trip, lowered by loops-cutoff (exits::lowerNestedCutoff) as a K-loop nested in a
  // K-loop is: its K trips unrolled into the trip's open block under its seed, its unit (the loop, its exit
  // arm, its noreturn and dead arms) always ending at its continuation C, every phi of C with an incoming
  // from the unit bound by it. kOf: the unit's blocks inside L -> the sub-loop.
  DenseMap<const BasicBlock *, Loop *> kOf;
  // A case-3 sub-loop with several exits (its exit arm, lowered with it) is such a unit too: its classical
  // exit is a real branch into C, its C phis bound by it.
  for (Loop *s : L.getSubLoops())
    if (Case sc = classify(*s, ctx.T, ctx.S);
        sc == Case::QuantumExit ||
        (sc == Case::ClassicalBoundQuantumExit && (exits::unitOf(*s).multi() || !exits::unitOf(*s).abort.empty()))) {
      exits::Unit SU = exits::unitOf(*s);
      for (BasicBlock *b : s->blocks())
        kOf[b] = s;
      for (auto *list : {&SU.arm, &SU.abort, &SU.dead})
        for (BasicBlock *b : *list)
          if (L.contains(b))
            kOf[b] = s;
    }
  auto kunit = [&](const BasicBlock *b) -> Loop * { return kOf.lookup(b); };
  // The classical fact on the edge p -> b where p's flow ran (rule 8): p's fact and the edge's classical
  // factor; a K-unit's edge into its continuation holds wherever the unit ran (it always ends there).
  auto edgeFact = [&](const BasicBlock *p, const BasicBlock *b) {
    auto it = factOf.find(p);
    Pred f = it == factOf.end() ? Pred::top() : it->second;
    if (Loop *k = kunit(p); k && kunit(b) != k)
      return f;
    return f & cfOf(ctx.preds().edge(p, b));
  };
  // The phis of a K-unit's continuation that the unit bound (their value where the unit ran), and the
  // output block each unit's flow leaves from with the edge that stands for its exits (real form).
  DenseSet<const PHINode *> kBound;
  DenseMap<const Loop *, const BasicBlock *> kRep;
  auto fwdPreds = [&](const BasicBlock *s) {
    SmallVector<const BasicBlock *, 4> ps;
    Loop *sl = subOf(s);
    Loop *ks = kunit(s);
    for (const BasicBlock *p : predecessors(s))
      if (!(sl && sl->contains(p)) && !(ks && kunit(p) == ks) && !is_contained(ps, p))
        ps.push_back(p);
    return ps;
  };
  enum class EK { Linear, Merge, Real };
  auto termQ = [&](const Instruction *t) {
    if (auto *br = dyn_cast<BranchInst>(t))
      return br->isConditional() && isQ(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return isQ(sw->getCondition());
    if (auto *ib = dyn_cast<IndirectBrInst>(t))
      return isQ(ib->getAddress());   // rule 13: a switch on the address
    return false;
  };
  // A K-unit's edges into its continuation C: one linearized edge (the unit's code runs in the open block,
  // under its seed), unless C is also entered by a real edge from outside the unit (a classical skip of the
  // loop): then the unit ends in a real branch to C, a classical join.
  // A classical test with an edge into a noreturn arm that is not the bound (cxb): the arm runs in the trip, at the test,
  // and the test leaves no other trace (abortTest): its one other successor continues the trip.
  auto isAbortTest = [&](const BasicBlock *u) {
    return !termQ(u->getTerminator()) && !(u == cxb && cxArm && is_contained(UX.abort, cxArm)) &&
           any_of(successors(u), [&](const BasicBlock *x) { return is_contained(UX.abort, x); });
  };
  auto abortTestNext = [&](const BasicBlock *u) -> BasicBlock * {
    auto *br = dyn_cast<BranchInst>(u->getTerminator());
    if (!br || !br->isConditional() || !isAbortTest(u))
      return nullptr;
    BasicBlock *a = br->getSuccessor(0), *b = br->getSuccessor(1);
    if (is_contained(UX.abort, a) == is_contained(UX.abort, b))
      return nullptr;
    return is_contained(UX.abort, a) ? b : a;
  };
  std::function<EK(const BasicBlock *, const BasicBlock *)> edgeKind;
  auto kReal = [&](Loop *k) {
    if (classify(*k, ctx.T, ctx.S) != Case::QuantumExit)
      return true;   // a classically bounded unit leaves by its classical exit
    BasicBlock *C = exits::unitOf(*k).cont;
    for (const BasicBlock *p : fwdPreds(C))
      if (!kunit(p) && edgeKind(p, C) == EK::Real)   // another K-unit's edge into C never makes this one real
        return true;
    return false;
  };
  edgeKind = [&](const BasicBlock *u, const BasicBlock *s) {
    if (Loop *k = kunit(u); k && kunit(s) != k)
      return kReal(k) ? EK::Real : EK::Linear;
    if (subOf(u))
      return EK::Real;   // a sub-loop always ends in a real branch
    if (u == cxb && !mixedDs.empty())
      return EK::Real;   // cq-h8y6: a mixed exit test branches classically on its classical disjuncts
    const Instruction *t = u->getTerminator();
    if (termQ(t))
      return EK::Linear;
    if (auto *br = dyn_cast<BranchInst>(t); br && (!br->isConditional() || abortTestNext(u))) {
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
        if (!(cfOf(ctx.preds().block(s)) & !cfOf(ctx.preds().block(u))).isBottom()) {
          // Quantum arms under one classical fact that meet at s (strtod's `if (i < 7) { q ? a : b; }`): the code of the
          // later arm runs in the same open block, so only the last arm walked leaves by the real edge; the earlier ones
          // are its linearized incomings (the mixed join).
          const Pred uc = cfOf(ctx.preds().block(u));
          auto at = find(rpo, u);
          for (const BasicBlock *p : fwdPreds(s))
            if (p != u && !termQ(p->getTerminator()) && armed(p) && find(rpo, p) > at) {
              const Pred pc = cfOf(ctx.preds().block(p));
              if ((pc & !uc).isBottom() && (uc & !pc).isBottom())
                return EK::Linear;
            }
          return EK::Real;
        }
        return EK::Linear;
      }
      return fwdPreds(s).size() == 1 ? EK::Merge : EK::Real;
    }
    return EK::Real;
  };
  auto target = [&](const BasicBlock *s) -> BasicBlock * {
    if (s == header)
      return H;
    for (const ArmExit &e : armExits)
      if (e.u == tgtFrom && e.x == s)
        return e.Y;
    if (L.contains(s) || top.contains(s))
      return ob(s);
    // A classical switch's edge into a noreturn arm: abortTest ran the arm; the switch stands for its other edges.
    if (tgtFrom && is_contained(UX.abort, s) && isa<SwitchInst>(tgtFrom->getTerminator()))
      for (BasicBlock *o : successors(tgtFrom))
        if (!is_contained(UX.abort, o))
          return o == header ? H : (L.contains(o) || top.contains(o)) ? ob(o) : unitExit;
    return unitExit;   // cq-j5mq: an edge out of the whole unit, also from a sub-loop
  };

  // Next values of the carried phis, computed at the latch before its terminator.
  std::vector<Value *> nexts;
  auto latchNexts = [&]() {
    Value *notFirstNow = notFirst;
    for (Carried &cv : carried) {
      if (cv.walked) {
        // Rule 14 (affine induction, cq-e6ky): the walked pointer's trip index advances by one per trip.
        nexts.push_back(ctx.B().CreateAdd(cv.np, ConstantInt::get(cv.np->getType(), 1)));
        continue;
      }
      Operand o = ctx.operand(cv.orig->getIncomingValueForBlock(latch));
      if (!cv.q) {
        if (o.handle)
          internalError("loops-classical: a classical carried value whose next is a rail", cv.orig);
        nexts.push_back(o.v);
      } else if (const R6 *r = r6Of(cv.orig); r && r->merge) {
        // y' = select(c, a, b), one arm the old rail: t = c ? y' : U^-1(y') (or the arms swapped). U^-1(y') is garbage
        // the clean-up reads (noted as a use of y so the clean-up follows it).
        auto *sc = o.handle ? dyn_cast<CallInst>(o.v) : nullptr;
        const unsigned nargs = sc ? sc->arg_size() : 0;
        if (nargs != 3 || (sc->getArgOperand(1) != cv.np && sc->getArgOperand(2) != cv.np)) {
          noteUnbuilt("loops-classical: rule 6 on a merge that is no select of the old rail", cv.orig);
          nexts.push_back(asHandle(o, cv.orig->getType()));
          continue;
        }
        bool selfTrue = sc->getArgOperand(1) == cv.np;
        RailId old = ctx.unc().idOf(cv.np);
        ctx.unc().setRole(ctx.unc().idOf(o.v), Role::UserRegister);
        Inv inv = inverseOf(ctx, *r->U[0], r->p, o);
        Value *inner = ctx.emitTemplate(inv.spec, inv.ops);
        ctx.unc().noteUse(old, cast<Instruction>(inner));
        abi::TemplateSpec ss;
        ss.op = "select";
        ss.w = railOf(cv.orig->getType());
        Operand c{sc->getArgOperand(0), true}, y{o.v, true}, in{inner, true};
        SmallVector<Operand, 3> ops{c, selfTrue ? y : in, selfTrue ? in : y};
        if (r->initLoad)
          ctx.unc().cleanupBijectiveUnder(old, notFirstNow, ss, ops, /*everyPath=*/false);
        else
          ctx.unc().cleanupBijective(old, ss, ops);
        keptFinal.insert(o.v);
        spine::shared(ctx).carriedFinal.insert(o.v);
        nexts.push_back(o.v);
      } else if (const R6 *r = r6Of(cv.orig)) {
        Operand u = ctx.operand(r->U.back());
        if (!o.handle || !u.handle || o.v != u.v || !isa<Instruction>(o.v) ||
            cast<Instruction>(o.v)->getParent() != H)
          internalError("loops-classical: rule 6 on a carried value whose update is not its next rail in the "
                        "header's segment",
                        cv.orig);
        RailType w = railOf(cv.orig->getType());
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
          spine::shared(ctx).carriedFinal.insert(o.v);
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
          spine::shared(ctx).carriedFinal.insert(sel);
          nexts.push_back(sel);
        }
      } else if (c3) {
        nexts.push_back(select(aCur, o, Operand{cv.np, true}, railOf(cv.orig->getType())));
      } else {
        nexts.push_back(asHandle(o, cv.orig->getType()));
      }
    }
    for (auto &[v, cp] : caps)
      cp->addIncoming(select(aPhi, ctx.operand(v), Operand{cp, true}, railOf(v->getType())), cur);
  };

  // The seeds minted for classical incomings of phis of handles (mintEdgeSeeds below), per (phi, edge source).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> &edgeSeed = edgeSeedM;
  // Mixed joins: the value of each phi of b on the real edge u -> b (mintEdgeSeeds).
  DenseMap<std::pair<const PHINode *, const BasicBlock *>, Value *> &edgeVal = edgeValM;
  auto emitPhis = [&](BasicBlock *b, bool real) {
    for (PHINode &p : b->phis()) {
      bool q = isQ(&p);
      if (kBound.count(&p)) {
        // A phi a nested K-unit bound: its value where the unit ran (rule 14), with the incomings it could
        // not read (lowered after it, on edges that exclude the loop) selected in where their edges hold
        // (rule 9, as the spine's cq-mgkr join arms). At a classical join (the unit's real form) each real
        // edge from outside the unit carries its own incoming (a seed where classical, rule 7).
        std::vector<std::pair<Pred, const Value *>> ja = ctx.takeJoinArms(&p);
        Operand uo = ctx.operand(&p);
        RailType w = railOf(p.getType());
        if (!ja.empty()) {
          if (real)
            internalError("loops-classical: a join arm of a K-unit's phi at a classical join (the unit's real "
                          "form is taken only where C is entered by a real edge, and a join arm's edge is linear)",
                          &p);
          std::vector<std::pair<Pred, Operand>> arms;
          Pred E = Pred::bottom();
          for (auto &[e, v] : ja) {
            Pred eq = e.quantumPart(ctx.T, ctx.S);
            E = E | eq;
            arms.push_back({eq, ctx.operand(v)});
          }
          arms.push_back({!E, uo});
          uo = Operand{selectChain(ctx, arms, w), true};
          ctx.rebind(&p, {uo});
        }
        if (!real)
          continue;
        if (!uo.handle)
          internalError("loops-classical: a K-unit bound a phi of its continuation to no rail", &p);
        PHINode *np = PHINode::Create(handleTy(ctx.M.getContext()), 2, p.getName());
        DenseSet<const Loop *> doneUnit;
        SmallVector<std::pair<BasicBlock *, Value *>, 4> ins;
        for (unsigned i = 0; i < p.getNumIncomingValues(); ++i) {
          BasicBlock *u = p.getIncomingBlock(i);
          if (edgeKind(u, b) != EK::Real)
            continue;
          Loop *k = kunit(u);
          if (k && !doneUnit.insert(k).second)
            continue;
          const BasicBlock *ru = k ? kRep.lookup(k) : u;
          auto it = edgeFrom.find({ru, b});
          if (it == edgeFrom.end())
            internalError("loops-classical: a join edge with no output block", &p);
          Value *v;
          if (k) {
            v = uo.v;
          } else if (auto e = edgeVal.find({&p, u}); e != edgeVal.end()) {
            v = e->second;
          } else if (auto e2 = edgeSeed.find({&p, u}); e2 != edgeSeed.end()) {
            v = e2->second;
          } else {
            Operand o = ctx.operand(p.getIncomingValue(i));
            if (!o.handle)
              internalError("loops-classical: a classical incoming of a phi of handles with no edge seed", &p);
            v = o.v;
          }
          ins.push_back({it->second, v});
        }
        np->insertInto(ob(b), ob(b)->getFirstNonPHIIt());
        for (auto &[from, v] : ins)
          np->addIncoming(v, from);
        ctx.unc().recordMerge(np);
        ctx.rebind(&p, {Operand{np, true}});
        continue;
      }
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
        // Every arm names one rail (a register rotated in place on one arm, rule 10; 126): the merge is
        // that rail, no choice to make (the spine's state-prep merge).
        Value *one = ctx.operand(p.getIncomingValue(0)).v;
        bool code = p.getType()->isPointerTy();   // rule 3: an i64 integer
        if (!p.getType()->isVectorTy() && !p.getType()->isAggregateType() && (!p.getType()->isPointerTy() || code) &&
            all_of(p.incoming_values(), [&](Value *v) { return ctx.operand(v).v == one; })) {
          ctx.bind(&p, asHandle(ctx.operand(p.getIncomingValue(0)), p.getType()));
          continue;
        }
        // cq-pfpy: a composite merges field by field (rule 26).
        if (p.getType()->isAggregateType() || p.getType()->isVectorTy())
          lowerMergeFields(ctx, p);
        else
          ctx.bind(&p, lowerMerge(ctx, p));
        continue;
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
        else if (auto ef = edgeFieldsM.find({&p, u}); ef != edgeFieldsM.end())
          in.f = ef->second;
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
              in.f[k] = Operand{seed(in.f[k].v, railOf(in.f[k].v->getType())), true};
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
    auto factAt = [&](const BasicBlock *p) { return edgeFact(p, s); };
    const Pred uf = factAt(u);
    for (PHINode &p : s->phis()) {
      if (edgeVal.count({&p, u}) || edgeFieldsM.count({&p, u}) || kBound.count(&p))
        continue;
      const bool composite = p.getType()->isAggregateType() || p.getType()->isVectorTy();
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
        arms.push_back({e, composite ? Operand{nullptr, false} : ctx.operand(v)});
      }
      if (arms.empty())
        internalError("loops-classical: a real edge into a mixed join carries no incoming", &p);
      if (!isQ(&p)) {
        if (arms.size() > 1)
          internalError("loops-classical: a classical phi at a mixed join chosen by a quantum edge", &p);
        continue;   // the classical incoming of u's own edge (emitPhis)
      }
      if (p.getType()->isAggregateType() || p.getType()->isVectorTy()) {
        if (arms.size() == 1)
          continue;   // u's own incoming, field-wise (emitPhis)
        // cq-pfpy (rules 9, 26): a quantum choice of a composite is rule 9's select chain per field, made
        // at the end of u's output block like a scalar's.
        std::vector<SmallVector<Operand, 4>> fields;
        for (const Value *v : vals)
          fields.push_back(aggr::flattenResult(ctx, v));
        SmallVector<Type *, 8> leafTys;
        std::function<void(Type *)> leaves = [&](Type *t) {
          if (auto *st = dyn_cast<StructType>(t))
            for (Type *e : st->elements())
              leaves(e);
          else if (auto *at = dyn_cast<ArrayType>(t))
            for (uint64_t i = 0; i < at->getNumElements(); ++i)
              leaves(at->getElementType());
          else if (auto *vt = dyn_cast<FixedVectorType>(t))
            for (unsigned i = 0; i < vt->getNumElements(); ++i)
              leafTys.push_back(vt->getElementType());
          else
            leafTys.push_back(t);
        };
        leaves(p.getType());
        if (leafTys.size() != fields[0].size())
          unimplemented("pred: a merge of a composite with a packed integer leaf (cq-0umd: its field widths are not "
                        "recorded)", &p);
        SmallVector<Operand, 4> out;
        for (unsigned k = 0; k < fields[0].size(); ++k) {
          bool same = true;
          for (auto &f : fields) {
            if (f.size() != fields[0].size())
              internalError("loops-classical: incomings of one composite phi with different field counts", &p);
            same &= f[k].v == fields[0][k].v;
          }
          if (same) {
            out.push_back(fields[0][k]);
            continue;
          }
          std::vector<std::pair<Pred, Operand>> fa;
          for (size_t a = 0; a < arms.size(); ++a)
            fa.push_back({arms[a].first, fields[a][k]});
          Type *lt = leafTys[k];
          out.push_back(Operand{selectChain(ctx, fa, lt->isPointerTy() ? RailType{Kind::Int, 64} : railOf(lt)), true});
        }
        edgeFieldsM[{&p, u}] = out;
        continue;
      }
      Value *h = arms.size() == 1 ? asHandle(arms[0].second, p.getType())
                                  : selectChain(ctx, arms, railOf(p.getType()));
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
      edgeSeed[{&p, u}] = seed(o.v, railOf(p.getType()));
    }
  };

  auto noteStop = [&](Value *f) {
    if (!f || !stopCur)
      return;
    Value *n = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
    gate(abi::Core::XorI1, {stopCur, n});
    gate(abi::Core::XorI1, {f, n});
    stopCur = n;
  };
  // One evaluation of the exit arm: the flags of the edges it enters by (a quantum exit edge's e in a trip, the trip
  // predicate on a classical exit), of its blocks and of their edges.
  struct ArmEval {
    DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> entry;
    DenseMap<const BasicBlock *, Value *> flag;
    DenseMap<std::pair<const BasicBlock *, const BasicBlock *>, Value *> edge;
    DenseMap<const BasicBlock *, Value *> creach;   // the classical path to a reached arm block, as a classical i1
    DenseSet<const PHINode *> bound;                // phis a loop of the arm bound
    Value *plain = nullptr;                         // case 1: the |1> rail that marks a reached edge, no predicate of its own
  };
  // The flag of the edge u -> x in this evaluation (nullptr: not taken in it): an entry edge's, a loop of the arm's
  // edge into its continuation (it always ends there) its header's flag, or, from an arm block u, u's flag & the
  // edge's own condition when u branches (rule 8 inside the arm: a quantum or classical condition, a classical term
  // seeded), once per edge.
  auto flagOfEdge = [&](ArmEval &ev, const BasicBlock *u, const BasicBlock *x) -> Value * {
    if (L.contains(u)) {
      auto it = ev.entry.find({u, x});
      return it == ev.entry.end() ? nullptr : it->second;
    }
    if (Loop *S = armUnit.lookup(u)) {
      if (armUnit.lookup(x) == S)
        return nullptr;
      return exits::unitOf(*S).cont == x ? ev.flag.lookup(S->getHeader()) : nullptr;
    }
    Value *fu = ev.flag.lookup(u);
    if (!fu || u->getSingleSuccessor())
      return fu;
    if (Value *e = ev.edge.lookup({u, x}))
      return e;
    Pred ep = exits::tripEdge(u, x);
    if (ep.isBottom())
      return nullptr;
    Value *g = ctx.preds().flag(ctx, ep);
    Value *e = fu;
    if (g && fu == ev.plain) {
      e = g;
    } else if (g) {
      e = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::AndI1, {fu, g, e});
    }
    ev.edge[{u, x}] = e;
    return e;
  };
  // The classical path of u -> x in this evaluation, as a classical i1 (a quantum condition counts as true): a
  // classical phi's incoming edge is chosen by classical conditions alone (taint).
  auto creachEdge = [&](ArmEval &ev, const BasicBlock *u, const BasicBlock *x) -> Value * {
    LLVMContext &Cx = ctx.M.getContext();
    if (L.contains(u))
      return ConstantInt::getTrue(Cx);
    if (Loop *S = armUnit.lookup(u))
      return ev.creach.lookup(S->getHeader());
    return ctx.B().CreateAnd(ev.creach.lookup(u), exits::classicalEdge(ctx, u, x));
  };
  auto rebindPhi = [&](PHINode &P, Operand o) {
    if (ctx.bound(&P))
      ctx.rebind(&P, {o});
    else
      ctx.bindFields(&P, {o});
  };
  // The exit arm under one evaluation's entry flags: every block some entered edge reaches, in the arm's topological
  // order, its phis rule 9's selects over the edges taken, its instructions under its flag, a loop of the arm one node
  // (rule 14 nested in this evaluation: its chain seeded by the block's flag). A block no entered edge reaches is no
  // part of this evaluation.
  auto walkArm = [&](ArmEval &ev, const SmallVectorImpl<BasicBlock *> &armBlocks) {
    LLVMContext &Cx = ctx.M.getContext();
    // The lowering branched inside the arm (a loop of the arm, rule 5's Readers test): the segment goes on where it joined.
    auto followBuilder = [&]() {
      if (BasicBlock *now = ctx.B().GetInsertBlock(); now != cur) {
        segIdx[now] = segs.size() - 1;
        segs.back().bb = now;
        cur = now;
      }
    };
    for (BasicBlock *b : armBlocks) {
      Loop *S = armUnit.lookup(b);
      if (S && S->getHeader() != b)
        continue;   // lowered with its loop
      SmallVector<Value *, 2> in;
      Value *cr = ConstantInt::getFalse(Cx);
      for (BasicBlock *p : predecessors(b)) {
        if (S && S->contains(p))
          continue;   // the back edge of the arm's loop
        if (Value *f = flagOfEdge(ev, p, b)) {
          if (!is_contained(in, f))
            in.push_back(f);
          cr = ctx.B().CreateOr(cr, creachEdge(ev, p, b));
        }
      }
      if (in.empty())
        continue;
      Value *f = in.front();
      if (in.size() > 1) {
        // Disjoint edges (one evaluation leaves through one): their OR is their XOR.
        f = seed(ConstantInt::getFalse(Cx), RailType{Kind::Int, 1});
        for (Value *x : in)
          gate(abi::Core::XorI1, {x, f});
      }
      ev.flag[b] = f;
      ev.creach[b] = cr;
      if (S) {
        spine::Shared &sh = spine::shared(ctx);
        exits::Unit SU = exits::unitOf(*S);
        SmallVector<PHINode *, 4> contPhis;
        if (SU.cont)
          for (PHINode &P : SU.cont->phis())
            if (any_of(P.blocks(), [&](const BasicBlock *u) { return armUnit.lookup(u) == S; })) {
              sh.binds.erase(&P);
              contPhis.push_back(&P);
            }
        Value *sf = f;
        if (f == ev.plain)
          if (Pred hp = qp(b); !hp.isTop())
            sf = ctx.preds().flag(ctx, hp);
        if (classify(*S, ctx.T, ctx.S) == Case::QuantumExit) {
          noteStop(exits::lowerNestedCutoff(ctx, *S, sf));
        } else {
          noteStop(exits::lowerClassicalInTrip(ctx, *S, sf));
          followBuilder();
        }
        for (PHINode *P : contPhis)
          if (ctx.bound(P))
            ev.bound.insert(P);
        continue;
      }
      for (PHINode &P : b->phis()) {
        if (ev.bound.count(&P))
          continue;
        SmallVector<unsigned, 4> ins;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (flagOfEdge(ev, P.getIncomingBlock(i), b))
            ins.push_back(i);
        if (ins.empty())
          internalError("loops-classical: a phi of a reached exit arm block with no incoming in this evaluation", &P);
        const bool q = isQ(&P);
        if (P.getType()->isAggregateType() || P.getType()->isVectorTy()) {
          noteUnbuilt("loops-classical: a composite phi of a case-3 loop's exit arm", &P);
          continue;
        }
        auto opOf = [&](unsigned i) {
          Operand o = ctx.operand(P.getIncomingValue(i));
          if (P.getType()->isPointerTy() && !o.handle && q)
            o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(Cx)), false};
          return o;
        };
        if (ins.size() == 1 ||
            all_of(ins, [&](unsigned i) { return P.getIncomingValue(i) == P.getIncomingValue(ins[0]); })) {
          Operand o = opOf(ins[0]);
          rebindPhi(P, q ? Operand{asHandle(o, P.getType()), true} : o);
          continue;
        }
        if (!q) {
          // Rule 9: a classical choice is a classical select over the edges' classical paths.
          Operand o = opOf(ins.back());
          if (o.handle)
            internalError("loops-classical: a classical phi of an exit arm with a rail incoming", &P);
          Value *r = o.v;
          for (unsigned k = unsigned(ins.size()) - 1; k-- > 0;) {
            Operand ok = opOf(ins[k]);
            if (ok.handle)
              internalError("loops-classical: a classical phi of an exit arm with a rail incoming", &P);
            r = ctx.B().CreateSelect(creachEdge(ev, P.getIncomingBlock(ins[k]), b), ok.v, r);
          }
          rebindPhi(P, Operand{r, false});
          continue;
        }
        // A quantum phi (rule 9): its incoming on the edge taken, a select chain over the edges' flags.
        RailType w = railOf(P.getType());
        Value *acc = nullptr;
        for (unsigned k = unsigned(ins.size()); k-- > 0;) {
          unsigned i = ins[k];
          Operand o = opOf(i);
          if (!acc) {
            acc = asHandle(o, P.getType());
            continue;
          }
          acc = select(flagOfEdge(ev, P.getIncomingBlock(i), b), o, Operand{acc, true}, w);
        }
        rebindPhi(P, Operand{acc, true});
      }
      // The arm's flag is the block's whole predicate here: its instructions run under it, its effects controlled by it.
      const Pred bq = qp(b);
      for (Instruction &I : *b)
        if (!isa<PHINode>(I) && !I.isTerminator()) {
          if (f == ev.plain)
            lowerInstruction(ctx, I, nullptr);   // no predicate but the block's own (case 1)
          else
            lowerInstruction(ctx, I, f, &bq);
          followBuilder();
        }
    }
  };
  // A value cp takes on the unit edge u -> C: the incoming, or the phi itself where a loop of the arm bound it.
  auto contFields = [&](ArmEval &ev, CPhi &cp, const Value *val) {
    return fieldsOf(cp, cp.P && ev.bound.count(cp.P) ? static_cast<const Value *>(cp.P) : val);
  };
  // Multi-exit, at the latch: the exit arm, the captures, res, and the trip predicate's back edge.
  auto latchExits = [&]() {
    ArmEval ev;
    for (auto &[e, f] : exitFlag)
      ev.entry[e] = f;
    walkArm(ev, UX.arm);
    for (CPhi &cp : cphis) {
      SmallVector<Value *, 2> c(cp.cap.begin(), cp.cap.end());
      SmallVector<Operand, 2> vl;
      for (auto &[u, val] : cp.incomings(inUnit, UX.cont)) {
        if (u == cxb && mixedDs.empty()) {
          if (u == latch)
            vl = fieldsOf(cp, val);
          continue;   // the classical exit: res (at the header, headerRes)
        }
        Value *g = flagOfEdge(ev, u, UX.cont);
        if (!g)
          continue;   // an edge of the arm this trip's exits do not reach (the classical exit's)
        SmallVector<Operand, 2> fv = contFields(ev, cp, val);
        for (unsigned f = 0; f < c.size(); ++f)
          c[f] = select(g, fv[f], Operand{c[f], true}, cp.rails[f]);
      }
      for (unsigned f = 0; f < c.size(); ++f)
        cp.cap[f]->addIncoming(c[f], cur);
      if (cxArm && cxb == latch)
        cp.atCx.assign(c.begin(), c.end());
      else if (cxb != header || cxb == latch) {
        cp.res.clear();
        for (unsigned f = 0; f < c.size(); ++f)
          cp.res.push_back(!vl.empty() ? select(aCur, vl[f], Operand{c[f], true}, cp.rails[f]) : c[f]);
      }
    }
    aPhi->addIncoming(aCur, cur);
  };
  // Multi-exit with the classical bound tested at the header (cxb): its exit edge is taken before any
  // quantum exit of the trip, so res = select(a, v, cap) over the captures of the earlier trips.
  auto headerRes = [&]() {
    for (CPhi &cp : cphis) {
      if (cxArm) {
        cp.atCx.assign(cp.cap.begin(), cp.cap.end());
        continue;
      }
      const Value *val = nullptr;
      for (auto &[u, v] : cp.incomings(inUnit, UX.cont))
        if (u == header)
          val = v;
      if (!val)
        internalError("loops-classical: a case-3 loop's classical exit edge with no value for its continuation",
                      cp.orig());
      SmallVector<Operand, 2> fv = fieldsOf(cp, val);
      cp.res.clear();
      for (unsigned f = 0; f < cp.cap.size(); ++f)
        cp.res.push_back(select(aCur, fv[f], Operand{cp.cap[f], true}, cp.rails[f]));
    }
  };

  // The noreturn arm on the edge u -> x under its flag e: rule 16's abort arm, here in the trip.
  auto noreturnArm = [&](BasicBlock *u, BasicBlock *x, Value *e) {
    ArmEval ev;
    ev.entry[{u, x}] = e;
    walkArm(ev, UX.abort);
    noteStop(e);
  };
  auto followInsert = [&]() {
    if (BasicBlock *now = ctx.B().GetInsertBlock(); now != cur) {
      segIdx[now] = segs.size() - 1;
      segs.back().bb = now;
      cur = now;
    }
  };
  // Rule 16 on a classical test with an edge into a noreturn arm, in the trip. Under a quantum predicate (the trip's chain,
  // an enclosing trip, the block's own): e = trip & the edge's flag, its classical terms seeded (rule 8). With none: the
  // real branch to the arm, the ordinary call (cq-o75xb); the segment goes on where it rejoins.
  auto abortTest = [&](BasicBlock *u) {
    SmallVector<BasicBlock *, 2> xs;
    for (BasicBlock *x : successors(u))
      if (is_contained(UX.abort, x) && !is_contained(xs, x))
        xs.push_back(x);
    LLVMContext &Cx = ctx.M.getContext();
    Value *trip = aCur ? aCur : outerTrip;
    const bool noExit = cx && UX.live.empty();   // nothing else ends the classical loop: this edge leaves it as well
    for (BasicBlock *x : xs) {
      Value *cnd = exits::classicalEdge(ctx, u, x);
      Pred qu = qp(u);
      BasicBlock *N = nullptr;
      if (trip || !qu.isTop()) {
        Value *f = ctx.preds().flag(ctx, qu & exits::tripEdge(u, x));
        if (!f)
          internalError("loops-classical: a noreturn arm's classical test with no flag", u->getTerminator());
        Value *e = seed(ConstantInt::getFalse(Cx), RailType{Kind::Int, 1});
        if (trip)
          gate(abi::Core::AndI1, {trip, f, e});
        else
          gate(abi::Core::XorI1, {f, e});
        noreturnArm(u, x, e);
        followInsert();
        if (!noExit)
          continue;
        N = newBlock();
        ctx.B().CreateCondBr(cnd, unitExit, N);
        edgeFrom[{u, x}] = cur;
      } else {
        BasicBlock *Y = newBlock();
        N = newBlock();
        ctx.B().CreateCondBr(cnd, Y, N);
        ctx.B().SetInsertPoint(Y);
        followInsert();
        std::optional<Pred> wasAssumed = ctx.preds().assume(ctx.preds().edge(u, x), ctx.T, ctx.S);
        ArmEval ev;
        ev.plain = ConstantInt::getTrue(Cx);
        ev.entry[{u, x}] = ev.plain;
        walkArm(ev, UX.abort);
        ctx.preds().assume(wasAssumed, ctx.T, ctx.S);
        if (noExit) {
          ctx.B().CreateBr(unitExit);
          edgeFrom[{u, x}] = ctx.B().GetInsertBlock();
        } else {
          ctx.B().CreateBr(N);
        }
      }
      ctx.B().SetInsertPoint(N);
      followInsert();
    }
  };

  Value *aAtCx = nullptr;   // the trip predicate at cxb's classical exit test
  auto emitTerminator = [&](BasicBlock *u) {
    tgtFrom = u;
    Instruction *t = u->getTerminator();
    if (isAbortTest(u))
      abortTest(u);
    const bool qExit = mx && termQ(t) && any_of(successors(u), [&](const BasicBlock *s) { return !L.contains(s); });
    if (u == latch && !qExit)
      latchNexts();
    if (mx && u == latch && !qExit)
      latchExits();
    if (mx && u == cxb && u == header && u != latch)
      headerRes();
    if (u == cxb)
      aAtCx = aCur;
    if (u == cxb && cxArm && u != header && u != latch) {
      noteUnbuilt("loops-classical: a case-3 loop whose only classical exit, into its exit or noreturn arm, is mid-trip", t);
      for (CPhi &cp : cphis)
        cp.atCx.assign(cp.cap.begin(), cp.cap.end());
    }
    if (qExit) {
      // A quantum exit before the latch: e = a & f, a' = a & NOT f; the trip goes on in the loop. A quantum
      // switch with exit cases (rule 13) is one such exit per exit block x: f_x the flag of its edge's quantum
      // predicate, e_x = a & f_x, a' = a ^ sum_x (a & f_x) (its edges are disjoint). An edge into an
      // effect-free dead end is UB to take: no exit.
      SmallVector<BasicBlock *, 4> xs;
      SmallVector<std::pair<BasicBlock *, Value *>, 2> intoArm;   // the noreturn arms' edges (rule 16) and their e
      for (BasicBlock *s : successors(u))
        if (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s)) && !is_contained(xs, s))
          xs.push_back(s);
      for (BasicBlock *s : successors(u))
        if (s == header && u != latch)
          internalError("loops-classical: a back edge from a block that is not the loop's latch", t);
      auto *br = dyn_cast<BranchInst>(t);
      Value *a2 = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::XorI1, {aCur, a2});
      // The exit condition read whole as the exit's atom (cq-s7c4): computed as data even where pred factored the
      // branch (a mixed test `c && q`, rule 8).
      if (br)
        if (auto *ci = dyn_cast<Instruction>(br->getCondition()); ci && !ctx.bound(ci))
          lowerConditionAsData(ctx, *ci);
      for (BasicBlock *x : xs) {
        Pred ex;
        if (br) {
          bool onTrue = br->getSuccessor(0) == x;
          ex = qp(u) & (onTrue ? Pred::atom(br->getCondition()) : !Pred::atom(br->getCondition()));
        } else if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
          ex = qp(u) & computedGotoEdge(*ib, x);   // rule 13: the address cases into x
        } else {
          // Rule 13: the function-wide edge stands for the loop as a unit: with one live exit block its quantum part is
          // the loop's own (true outside any arm), no test of this trip. The trip's test is the cases into x.
          ex = ctx.preds().edge(u, x).quantumPart(ctx.T, ctx.S);
          if (!UX.abort.empty() || ex.isTop())
            ex = qp(u) & exits::tripEdge(u, x);
        }
        Value *f = ctx.preds().flag(ctx, ex);
        if (!f)
          internalError("loops-classical: a quantum exit condition with no flag", t);
        Value *e = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
        gate(abi::Core::AndI1, {aCur, f, e});
        gate(abi::Core::AndI1, {aCur, f, a2});
        if (is_contained(UX.abort, x))
          intoArm.push_back({x, e});
        else
          exitFlag[{u, x}] = e;
      }
      aCur = a2;
      if (br)
        lowerBranch(ctx, *br);
      else if (auto *sw = dyn_cast<SwitchInst>(t))
        sw::lowerSwitch(ctx, *sw);
      else if (!isa<IndirectBrInst>(t))   // rule 13: a quantum computed goto's edges are pred's; nothing to emit
        internalError("loops-classical: a quantum exit terminator other than br, switch or computed goto", t);
      for (auto &[x, e] : intoArm)
        noreturnArm(u, x, e);
      followInsert();
      // cq-h8y6: a mixed exit test (cxb with classical disjuncts) leaves the loop classically where one of them
      // holds: there its flag is 1, so this trip's exit took its value under a (the captures, or res).
      Value *cExit = nullptr;
      if (u == cxb)
        for (const Disj &d : mixedDs) {
          Operand o = ctx.operand(d.v);
          Value *x = d.pos ? o.v : ctx.B().CreateNot(o.v);
          cExit = cExit ? ctx.B().CreateOr(cExit, x) : x;
        }
      if (u == latch) {
        // The quantum exit at the latch (cq-nqa6): the next values and captures under a', then the back edge.
        latchNexts();
        latchExits();
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        if (cExit)
          ctx.B().CreateCondBr(cExit, T, H);
        else
          ctx.B().CreateBr(H);
        cur = nullptr;
        return;
      }
      for (BasicBlock *s : successors(u))
        edgeFrom[{u, s}] = cur;
      if (cExit) {
        BasicBlock *in = nullptr;
        for (BasicBlock *s : successors(u))
          if (L.contains(s))
            in = s;
        for (BasicBlock *s : successors(u))
          mintEdgeSeeds(u, s);
        ctx.B().CreateCondBr(cExit, cxArm ? target(cxArm) : T, target(in));
        cur = nullptr;
      }
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
      if (BasicBlock *next = abortTestNext(u); next || !br->isConditional()) {
        BasicBlock *s = next ? next : br->getSuccessor(0);
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
        // A quantum edge out of the trip is a case-3 exit (the latch test, or the multi-exit form's qExit
        // above): here only an edge into an effect-free dead end can leave, UB to take (no exit).
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s))))
            internalError("loops-classical: a quantum edge out of the trip outside the case-3 exit forms", t);
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
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s))))
            internalError("loops-classical: a quantum switch edge out of the trip outside the case-3 exit forms", t);
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
    if (auto *ib = dyn_cast<IndirectBrInst>(t)) {
      // CR rule 13 (b137e75): a computed goto is a switch on its address. A quantum one emits nothing (its
      // edges are pred's address cases); a classical one is the switch on the address's position among its
      // destinations.
      if (termQ(t)) {
        for (BasicBlock *s : successors(u))
          if (s == header || (!L.contains(s) && (is_contained(UX.live, s) || UX.contains(L, s))))
            internalError("loops-classical: a quantum computed goto edge out of the trip outside the case-3 exit forms",
                          t);
        for (BasicBlock *s : successors(u))
          edgeFrom[{u, s}] = cur;
        return;
      }
      Operand a = ctx.operand(ib->getAddress());
      if (a.handle)
        internalError("loops-classical: a classical computed goto on a rail", t);
      for (BasicBlock *s : successors(u))
        mintEdgeSeeds(u, s);
      SmallVector<BasicBlock *, 4> ds = computedGotoDestinations(*ib);
      Value *pos = computedGotoPosition(ctx.B(), a.v, *ib);
      SwitchInst *ns = ctx.B().CreateSwitch(pos, target(ds.back()), ds.size() - 1);
      for (unsigned k = 0; k + 1 < ds.size(); ++k)
        ns->addCase(ctx.B().getInt32(k), target(ds[k]));
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
    // ret and unreachable end no block of a loop (no successor); callbr is inline asm (rule 27); the EH pads
    // come from no C translation unit.
    if (isa<CallBrInst>(t))
      unimplemented("loops-classical: asm goto (callbr) in a loop: inline asm (rule 27) waits for its CQ_spec example "
                    "(build step 3)",
                    t);
    internalError("loops-classical: a loop body terminator other than br, switch or computed goto", t);
  };

  auto emitInstructions = [&](BasicBlock *b) {
    for (Instruction &I : *b) {
      if (isa<PHINode>(I) || I.isTerminator() || skip.count(&I))
        continue;
      // case 3: the body runs under a_{j-1}; case 1: under the enclosing case-3 trip's rail, if any
      lowerInstruction(ctx, I, aPhi ? aPhi : outerTrip);
      // Rule 5 Readers: the lowering branched on a classical test inside the trip; the segment goes on where it joined.
      if (BasicBlock *now = ctx.B().GetInsertBlock(); cur && now != cur) {
        segIdx[now] = segs.size() - 1;
        segs.back().bb = now;
        cur = now;
      }
    }
  };

  // The trip predicate and the stop rail at the end of each walked block.
  DenseMap<const BasicBlock *, Value *> aOut, stopOut;
  auto joinTrip = [&](BasicBlock *b, DenseMap<const BasicBlock *, Value *> &outOf, Value *&var, Value *fallback) {
    SmallVector<std::pair<BasicBlock *, Value *>, 4> in;
    bool differ = false;
    for (const BasicBlock *p : fwdPreds(b)) {
      Value *v = outOf.lookup(p);
      if (!v)
        v = fallback;   // the exit of a sub-loop, whose walk had no entry here
      auto ef = edgeFrom.find({p, b});
      if (ef == edgeFrom.end())
        continue;
      differ |= !in.empty() && in.front().second != v;
      in.push_back({ef->second, v});
    }
    if (!in.empty())
      var = in.front().second;
    if (!differ)
      return;
    PHINode *ph = ctx.B().CreatePHI(handleTy(ctx.M.getContext()), unsigned(in.size()));
    for (BasicBlock *pb : predecessors(ob(b)))
      for (auto &[from, v] : in)
        if (from == pb) {
          ph->addIncoming(v, pb);
          break;
        }
    ctx.unc().recordMerge(ph);
    var = ph;
  };
  // The header (its phis are the carried values above). The outermost header runs under the spine's
  // guard; a sub-loop's header fact is set by its parent's walk.
  if (outermost)
    curFact = cfOf(ctx.preds().block(header));
  requireFact(header);
  emitInstructions(header);
  emitTerminator(header);
  aOut[header] = aCur;
  stopOut[header] = stopCur;
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
    for (const BasicBlock *p : fwdPreds(b))
      need = need | edgeFact(p, b);
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
      for (const BasicBlock *p : fwdPreds(b))
        f = f | edgeFact(p, b);
      curFact = f;
      // The trip predicate and the stop rail at a classical join: an exit taken in one classical arm of the trip is in that
      // arm's only.
      if (aPhi)
        joinTrip(b, aOut, aCur, aPhi);
      if (stopPhi)
        joinTrip(b, stopOut, stopCur, stopCur);
    } else if (!cur) {
      internalError("loops-classical: a linearized block walked with no open block", &*b->begin());
    }
    if (!sl)
      requireFact(b);
    if (sl) {
      Case sc = classify(*sl, ctx.T, ctx.S);
      if (sc == Case::QuantumExit) {
        // CR rule 14, nested K-loops: the chain's seed is this trip's predicate (case 3: a_{j-1}; a case-1
        // trip inside a case-3 trip: that trip's rail) & the sub-loop header's quantum predicate within the
        // trip, a fresh rail (gates on fresh rails only); |1> when both are true. Its a_K is kept once per
        // trip of this loop (B > K or no bound), every other rail is a record of this segment, mirrored by
        // the reverse loop per trip.
        exits::Unit SU = exits::unitOf(*sl);
        BasicBlock *C = SU.cont;
        if (!C || !L.contains(C))
          unimplemented("loops-classical: a sub-loop that leaves its parent loop", sl->getHeader()->getTerminator());
        Value *trip = c3 ? static_cast<Value *>(aPhi) : outerTrip;
        Pred hp = qp(b);
        Value *f = hp.isTop() ? nullptr : ctx.preds().flag(ctx, hp);
        Value *sd;
        if (trip && f) {
          sd = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
          gate(abi::Core::AndI1, {trip, f, sd});
        } else if (trip || f) {
          sd = trip ? trip : f;
        } else {
          sd = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
        }
        DenseSet<const PHINode *> was;
        for (PHINode &P : C->phis())
          if (ctx.bound(&P))
            was.insert(&P);
        BasicBlock *at = cur;
        noteStop(exits::lowerNestedCutoff(ctx, *sl, sd));
        if (ctx.B().GetInsertBlock() != at)
          internalError("loops-classical: a nested K-loop left the trip's open block", sl->getHeader()->getTerminator());
        for (PHINode &P : C->phis())
          if (!was.count(&P) && ctx.bound(&P))
            kBound.insert(&P);
        for (auto &[blk, k] : kOf)
          if (k == sl)
            factOf[blk] = curFact;
        const BasicBlock *rep = nullptr;
        for (const BasicBlock *p : predecessors(C))
          if (kunit(p) == sl) {
            edgeFrom[{p, C}] = cur;
            if (!rep)
              rep = p;
          }
        if (!rep)
          internalError("loops-classical: a K-unit with no edge into its continuation", sl->getHeader()->getTerminator());
        kRep[sl] = rep;
        if (edgeKind(rep, C) == EK::Real) {
          ctx.B().CreateBr(ob(C));
          cur = nullptr;
        }
        return;
      }
      exits::Unit SU = exits::unitOf(*sl);
      BasicBlock *sx = SU.multi() ? SU.cont : exits::liveExit(*sl);
      if (!sx || !L.contains(sx))
        unimplemented("loops-classical: a sub-loop that leaves its parent loop", sl->getHeader()->getTerminator());
      if (!c3 && sc == Case::ClassicalBound && anyReal && sl->getExitingBlock() && SU.abort.empty() && tripLocal(*sl, L)) {
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
      DenseSet<const PHINode *> was;
      for (PHINode &P : sx->phis())
        if (ctx.bound(&P))
          was.insert(&P);
      // A case-1 sub-loop's continuation may lie outside this loop (cq-j5mq): its edges are real branches (target).
      auto subOut = lowerLoop(*sl, sc, sx && L.contains(sx) ? ob(sx) : nullptr, false);
      outerTrip = savedTrip;
      for (size_t i = 0; i < subOut.size();) {
        const Value *v = subOut[i].first;
        SmallVector<Operand, 2> ops;
        for (; i < subOut.size() && subOut[i].first == v; ++i)
          ops.push_back(subOut[i].second);
        if (ctx.bound(v))
          ctx.rebind(v, ops);
        else
          ctx.bindFields(v, ops);   // a phi of the multi-exit sub-loop's continuation (its exit value)
      }
      if ((SU.multi() || !SU.abort.empty()) && sc != Case::ClassicalBound) {
        for (PHINode &P : sx->phis())
          if (!was.count(&P) && ctx.bound(&P))
            kBound.insert(&P);
        for (const BasicBlock *p : predecessors(sx))
          if (kunit(p) == sl && edgeFrom.count({p, sx}))
            kRep[sl] = p;
        if (!kRep.count(sl))
          internalError("loops-classical: a multi-exit sub-loop with no real edge into its continuation",
                        sl->getHeader()->getTerminator());
        for (auto &[blk, k] : kOf)
          if (k == sl && !factOf.count(blk))
            factOf[blk] = curFact;
      }
      return;
    }
    emitPhis(b, anyReal);
    emitInstructions(b);
    emitTerminator(b);
    aOut[b] = aCur;
    stopOut[b] = stopCur;
  };
  for (BasicBlock *b : rpo) {
    if (b == header || !L.contains(b))
      continue;
    if (Loop *sl = subOf(b); sl && sl->getHeader() != b)
      continue;
    if (Loop *k = kunit(b); k && k->getHeader() != b)
      continue;   // a K-unit's exit arm: lowered with the unit
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
    if (notFirst)
      notFirst->addIncoming(ConstantInt::getTrue(ctx.M.getContext()), it->second);
    if (stopPhi)
      stopPhi->addIncoming(stopOut.lookup(latch), it->second);
  }
  // CR rule 14 case 3 with rules 8, 9: the classical exit test left into the exit arm. It holds once per activation, on
  // a real branch, so the arm on that edge runs once, in a segment of its own, under the trip predicate at the test (a
  // loop of the arm seeded by it); the phis of C take the arm's value where its edges into C hold over the captures of
  // the quantum exits. Its records are mirrored first by the reverse (the segment precedes the exit).
  for (ArmExit &ax : armExits) {
    startSeg(ax.Y);
    if (stopPhi)
      stopCur = stopOut.lookup(ax.u);
    ArmEval ev;
    if (mx) {
      if (!aAtCx)
        internalError("loops-classical: a classical exit into the arm with no trip predicate at its test",
                      ax.u->getTerminator());
      // A copy of the trip rail: rule 5 keeps the control of a kept store of the arm, this one activation's rail, never the
      // rail every trip's a_j has as its one SSA value.
      Value *armCtl = seed(ConstantInt::getFalse(ctx.M.getContext()), RailType{Kind::Int, 1});
      gate(abi::Core::XorI1, {aAtCx, armCtl});
      ev.entry[{ax.u, ax.x}] = armCtl;
    } else {
      ev.plain = seed(ConstantInt::getTrue(ctx.M.getContext()), RailType{Kind::Int, 1});
      ev.entry[{ax.u, ax.x}] = ev.plain;
    }
    // The arm runs here for this edge's paths only: every predicate under it.
    std::optional<Pred> wasAssumed = ctx.preds().assume(ctx.preds().edge(ax.u, ax.x), ctx.T, ctx.S);
    const bool intoAbort = is_contained(UX.abort, ax.x);
    walkArm(ev, intoAbort ? UX.abort : UX.arm);
    ctx.preds().assume(wasAssumed, ctx.T, ctx.S);
    if (intoAbort && mx)
      noteStop(ev.entry[{ax.u, ax.x}]);
    for (CPhi &cp : cphis) {
      SmallVector<Value *, 2> c(cp.atCx.begin(), cp.atCx.end());
      if (UX.cont)
        for (auto &[u, val] : cp.incomings(inUnit, UX.cont)) {
          Value *g = flagOfEdge(ev, u, UX.cont);
          if (!g)
            continue;
          SmallVector<Operand, 2> fv = contFields(ev, cp, val);
          for (unsigned f = 0; f < c.size(); ++f)
            c[f] = select(g, fv[f], Operand{c[f], true}, cp.rails[f]);
        }
      cp.res.assign(c.begin(), c.end());
    }
    if (!mx && UX.cont)
      for (PHINode &P : UX.cont->phis()) {
        // Case 1: the value on this edge: its one reached incoming, or rule 9's select chain over their flags.
        std::vector<std::pair<const Value *, Value *>> in;
        for (unsigned i = 0; i < P.getNumIncomingValues(); ++i)
          if (Value *g = flagOfEdge(ev, P.getIncomingBlock(i), UX.cont))
            in.push_back({P.getIncomingValue(i), g});
        if (in.empty())
          continue;
        if (ev.bound.count(&P)) {
          ax.contVal[&P] = ctx.operand(&P);
          continue;
        }
        Operand o = ctx.operand(in.back().first);
        const bool q = isQ(&P);
        if (q && P.getType()->isPointerTy() && !o.handle)
          o = Operand{ctx.B().CreatePtrToInt(o.v, Type::getInt64Ty(ctx.M.getContext())), false};
        for (unsigned k = unsigned(in.size()) - 1; k-- > 0;) {
          if (!q) {
            noteUnbuilt("loops-classical: a classical phi of a case-1 loop's continuation chosen inside its exit arm", &P);
            break;
          }
          Operand ok = ctx.operand(in[k].first);
          if (P.getType()->isPointerTy() && !ok.handle)
            ok = Operand{ctx.B().CreatePtrToInt(ok.v, Type::getInt64Ty(ctx.M.getContext())), false};
          o = Operand{select(in[k].second, ok, o, railOf(P.getType())), true};
        }
        ax.contVal[&P] = o;
      }
    if (UX.cont)
      for (BasicBlock *p : predecessors(UX.cont))
        if (inUnit(p) && !L.contains(p))
          edgeFrom[{p, UX.cont}] = cur;
    ax.end = cur;
    ctx.B().CreateBr(T ? T : unitExit);
    cur = nullptr;
  }
  closeSeg();
  // The stop rail where the loop leaves for T.
  if (stopPhi && (cx || armExits.size() > 1 || (armExits.empty() && !(mx ? cxb : exits::liveExiting(L))))) {
    noteUnbuilt("loops-classical: the stop rail of a loop with several exit edges misses the leaving trip's arm flags", header->getTerminator());
    stopCur = stopPhi;
  } else if (stopPhi && armExits.empty()) {
    stopCur = stopOut.lookup(mx ? cxb : exits::liveExiting(L));
  }

  std::vector<std::pair<const Value *, Operand>> out;
  std::vector<RailType> outW;
  DenseSet<const Value *> unbound;   // multi-exit: C's phis, bound here for the first time
  DenseMap<const Value *, unsigned> nFields;
  DenseSet<const Value *> fat;
  for (CPhi &cp : cphis) {
    if (cp.res.empty())
      internalError("loops-classical: a continuation phi of a case-3 loop with no exit value", cp.orig());
    for (unsigned f = 0; f < cp.res.size(); ++f) {
      out.push_back({cp.orig(), Operand{cp.res[f], true}});
      outW.push_back(cp.rails[f]);
    }
    if (cp.res.size() != 1 || cp.ptr || cp.type()->isAggregateType() || cp.type()->isVectorTy())
      nFields[cp.orig()] = unsigned(cp.res.size());
    if (cp.ptr)
      fat.insert(cp.orig());
    if (cp.P)
      unbound.insert(cp.P);
  }
  DenseMap<const Value *, SmallVector<Operand, 2>> pend;
  auto put = [&](const Value *v, Operand op) {
    SmallVector<Operand, 2> ops{op};
    if (auto nf = nFields.find(v); nf != nFields.end()) {
      SmallVector<Operand, 2> &p = pend[v];
      p.push_back(op);
      if (p.size() < nf->second)
        return;
      ops = p;
      pend.erase(v);
    }
    // A unit lowered once per trip of an enclosing K-loop (cq-h5uj) binds its continuation's phis again.
    if (unbound.erase(v) && !ctx.bound(v))
      ctx.bindFields(v, ops);
    else
      ctx.rebind(v, ops);
  };
  for (const Instruction *v : liveOut) {
    if (!isQ(v) && !c3)
      continue;
    if (c3) {
      if (auto n = nextOf.find(v); n != nextOf.end()) {
        unsigned k = 0;
        while (carried[k].orig != n->second)
          ++k;
        out.push_back({v, Operand{nexts[k], true}});
        outW.push_back(railOf(v->getType()));
      } else {
        for (auto &[cv, cp] : caps)
          if (cv == v) {
            out.push_back({v, Operand{cp->getIncomingValueForBlock(edgeFrom[{latch, header}]), true}});
            outW.push_back(railOf(v->getType()));
          }
      }
    } else {
      out.push_back({v, ctx.operand(v)});
      outW.push_back(railOf(v->getType()));
    }
  }
  if (outermost) {
    ctx.B().SetInsertPoint(T);
    // Rules 5, 14: a rail a segment's predicate minted on an edge into a join above the loop (a flag seed) runs once; no
    // trip undoes it (calloc).
    closeSeg();
    if (!segs.empty())
      for (const Seg &sg : segs)
        U.leaveScope(sg.scope, segs.front().bb);
    if (c == Case::ClassicalBound && !nested && !inTrip)
      cleanInvariantOnExit(L, T);
    if (cx) {
      // One fresh block per exit edge, where the edge's value of each exit phi is read: a classical one by a phi of T,
      // a rail copied out (alloc + copy; a classical incoming the seed itself), the copy an output of the loop.
      LLVMContext &Cx = ctx.M.getContext();
      SmallVector<PHINode *, 4> xphis;
      if (BasicBlock *xb = exitB ? exitB : (c1Arm ? UX.cont : nullptr))
        for (PHINode &P : xb->phis())
          if (any_of(P.blocks(), [&](const BasicBlock *u) { return inUnit(u); }))
            xphis.push_back(&P);
      SmallVector<PHINode *, 4> nps;
      for (PHINode *P : xphis) {
        PHINode *np = PHINode::Create(isQ(P) ? handleTy(Cx) : P->getType(), 2, P->getName(), T->begin());
        nps.push_back(np);
        // Rule 9: an incoming from outside the unit on a quantum edge that excludes the loop (a pre-header guard): the
        // walker selects it in over this binding, where its edge holds; a classical skip is its classical join.
        if (isQ(P)) {
          const Pred hb = ctx.preds().block(header);
          const Pred cH = hb.classicalFactor(ctx.T, ctx.S);
          for (unsigned i = 0; i < P->getNumIncomingValues(); ++i) {
            BasicBlock *u = P->getIncomingBlock(i);
            const Pred &e = ctx.preds().edge(u, P->getParent());
            if (!inUnit(u) && !(e & cH).isBottom() && (e & hb).isBottom())
              ctx.addJoinArm(P, e, P->getIncomingValue(i));
          }
        }
      }
      exitIndex = PHINode::Create(Type::getInt32Ty(Cx), 2, "exit", T->begin());
      unsigned k = 0;
      // One real edge into T: the phis' values on it, and the segment the reverse starts at.
      auto exitEdge = [&](BasicBlock *from, const std::function<Operand(PHINode *)> &valueOf) {
        BasicBlock *Eb = newBlock();
        from->getTerminator()->replaceSuccessorWith(T, Eb);
        ctx.B().SetInsertPoint(Eb);
        for (unsigned j = 0; j < xphis.size(); ++j) {
          Operand o = valueOf(xphis[j]);
          if (!isQ(xphis[j])) {
            if (o.handle)
              internalError("loops-classical: a classical exit phi with a rail incoming", xphis[j]);
            nps[j]->addIncoming(o.v, Eb);
            continue;
          }
          RailType w = railOf(xphis[j]->getType());
          CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                     {o.handle ? Constant::getNullValue(irTypeOf(Cx, w)) : o.v});
          if (o.handle)
            U.noteUse(U.idOf(o.v), ctx.emitCore(abi::CoreSpec{abi::Core::Copy, w}, {o.v, f}));
          U.recordExternal(f, Role::Output);
          nps[j]->addIncoming(f, Eb);
        }
        exitIndex->addIncoming(ConstantInt::get(Type::getInt32Ty(Cx), k++), Eb);
        exitSegs.push_back(from);
        ctx.B().CreateBr(T);
      };
      for (BasicBlock *u : L.blocks()) {
        BasicBlock *xs = nullptr;
        for (BasicBlock *y : successors(u))
          if (!top.contains(y))
            xs = y;
        auto ef = edgeFrom.find({u, xs});
        if (!xs || ef == edgeFrom.end() || exitIndex->getBasicBlockIndex(ef->second) >= 0 ||
            !is_contained(predecessors(T), ef->second))
          continue;   // no real edge out of the unit from here (an edge into a dead end needs none)
        exitEdge(ef->second, [&](PHINode *P) {
          // An edge into another exit block than this phi's (its exit arm): any value serves.
          return P->getBasicBlockIndex(u) >= 0 ? ctx.operand(P->getIncomingValueForBlock(u))
                                               : Operand{Constant::getNullValue(P->getType()), false};
        });
      }
      for (ArmExit &ax : armExits)
        exitEdge(ax.end, [&](PHINode *P) {
          auto it = ax.contVal.find(P);
          return it != ax.contVal.end() ? it->second : Operand{Constant::getNullValue(P->getType()), false};
        });
      ctx.B().SetInsertPoint(T);
      for (unsigned j = 0; j < xphis.size(); ++j) {
        bool q = isQ(xphis[j]);
        if (q)
          U.recordExternal(nps[j], Role::Output);
        if (ctx.bound(xphis[j]))
          ctx.rebind(xphis[j], {Operand{nps[j], q}});
        else
          ctx.bindFields(xphis[j], {Operand{nps[j], q}});
      }
    }
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
        if (!r.forward->getType()->isVoidTy() && !U.leftScope(sc, r.forward)) {
          ownedH.insert(r.forward);
          // A clone with rule-19 extras returns a struct: its rails are the call's extractvalues (cq-f96c8).
          for (const User *u : r.forward->users())
            if (isa<ExtractValueInst>(u))
              ownedH.insert(u);
        }
    std::vector<RailId> exits;
    if (stopCur) {
      stopFinal = stopCur;
      exits.push_back(U.idOf(stopCur));   // read in place by the enclosing K-loop's predicate
    }
    std::vector<unsigned> copied;   // the values whose exit rail is no record of the loop: copied out, below
    for (unsigned oi = 0; oi < out.size(); ++oi) {
      const Value *v = out[oi].first;
      Operand op = out[oi].second;
      if (!op.handle)
        internalError("loops-classical: a quantum value read after the loop whose exit value is classical", v);
      if (keptFinal.count(op.v)) {
        // A cleaned chain's final rail is the register itself: the reverse never touches it.
        put(v, op);
        continue;
      }
      // A carried register every trip leaves on its rail (rotated in place, rule 10; 126): the header phi
      // names the entry's seed on every edge, so the seed is the register, kept, read in place.
      if (auto *ph = dyn_cast<PHINode>(op.v)) {
        Value *one = nullptr;
        bool single = true;
        for (Value *in : ph->incoming_values())
          if (in != ph && in != one)
            single = single && !one, one = in;
        auto *seed = dyn_cast_or_null<CallInst>(one);
        if (single && seed && ownedH.count(seed) && seed->getCalledFunction() &&
            seed->getCalledFunction()->getName().starts_with("cqrt_alloc_")) {
          U.setRole(U.idOf(seed), Role::UserRegister);
          put(v, Operand{seed, true});
          continue;
        }
      }
      if (ownedH.count(op.v)) {
        put(v, op);
        RailId x = U.idOf(op.v);
        if (!is_contained(exits, x))
          exits.push_back(x);
        continue;
      }
      copied.push_back(oi);
    }
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
        RailId x = U.idOf(r.forward);
        if (!is_contained(exits, x))
          exits.push_back(x);
      }
    for (unsigned oi : copied) {
      const Value *v = out[oi].first;
      Operand op = out[oi].second;
      RailType w = outW[oi];
      CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w},
                                 {Constant::getNullValue(irTypeOf(ctx.M.getContext(), w))});
      // cq-h5uj, cq-k7zkw (CR rule 14 case 1: "after the result is copied out (alloc + copy) a reverse loop pops"; rule 5:
      // every rail is uncomputed after its last consumer, §6 item 1): a loop whose reverse runs after its readers anyway (one
      // that runs per trip of an enclosing loop, or that has an exit rail read in place) keeps no output of its own: the copy
      // is a record of the loop's own copy scope, an exit rail read in place after the loop, and the deferred reverse
      // un-copies it first (reverse(): the copy scope's mirror before the last trip's). A reader that keeps it (a measurement,
      // an escape) is recordDeferred's kept exit rail.
      // The same for a copy some reader only computes from (cq-ii0vf: a trip's join of handles, read by a template): rule 5
      // uncomputes it after that reader, and nothing can once the reverse has run.
      bool scoped = nested || inTrip || !exits.empty() || !readersKeep(v);
      if (scoped && copyScope == ~0u)
        copyScope = U.openScope();   // closed after the last copy (below)
      RailId fid = ctx.unc().recordSeed(f);
      abi::CoreSpec cp{abi::Core::Copy, w};
      CallInst *cc = ctx.emitCore(cp, {op.v, f});
      ctx.unc().recordCore(cc, cp, {op, Operand{f, true}}, fid);
      if (!scoped)
        ctx.unc().setRole(fid, Role::Output);
      else {
        ownedH.insert(f);
        if (!is_contained(exits, fid))
          exits.push_back(fid);
      }
      put(v, Operand{f, true});
    }
    if (copyScope != ~0u) {
      U.closeScope(copyScope);
      scs.push_back(copyScope);
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
        // cq-odo1: the initial rails from before the loop the header phis name are read by the reverse (its anchor
    // notes them); one the loop's own seed scope minted is the item's.
        for (Value *h : self->externalInits)
          if (RailId x = self->U.idOf(h); !ownedH.count(h) && !is_contained(reads, x))
            reads.push_back(x);
        self->U.recordDeferred(scs, exits,
                               [self, T, seedScope](IRBuilder<> &B) { self->reverse(B, T, seedScope, true); },
                               reads, self->hostScopes);
      };
      ctx.B().SetInsertPoint(Cont);
      return {};
    }
    if (exits.empty()) {
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
    // cq-odo1: the initial rails from before the loop the header phis name are read by the reverse (its anchor
    // notes them); one the loop's own seed scope minted is the item's.
    for (Value *h : externalInits)
      if (RailId x = U.idOf(h); !ownedH.count(h) && !is_contained(reads, x))
        reads.push_back(x);
    BasicBlock *Cont = newBlock();
    BranchInst::Create(Cont, T);
    auto self = shared_from_this();
    deferred = true;
    U.recordDeferred(scs, exits,
                     [self, T, seedScope](IRBuilder<> &B) { self->reverse(B, T, seedScope, true); }, reads, {});
    ctx.B().SetInsertPoint(Cont);
    return {};
  }
  return out;
}

// Is v read after the loop only by what keeps its rail (rule 5, §6 item 1): a measurement, a return, the value of a store?
bool Unit::readersKeep(const Value *v) {
  SmallVector<const Value *, 4> work{v};
  SmallPtrSet<const Value *, 8> seen{v};
  while (!work.empty()) {
    const Value *x = work.pop_back_val();
    for (const User *u : x->users()) {
      auto *ui = dyn_cast<Instruction>(u);
      if (!ui || top.contains(ui))
        continue;
      if (auto *P = dyn_cast<PHINode>(ui)) {
        if (seen.insert(P).second)
          work.push_back(P);
        continue;
      }
      if (isa<ReturnInst>(ui))
        continue;
      if (auto *st = dyn_cast<StoreInst>(ui); st && st->getValueOperand() == x)
        continue;
      if (auto *CB = dyn_cast<CallBase>(ui); CB && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Measure)
        continue;
      return false;
    }
  }
  return true;
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
    for (BasicBlock *p : predecessors(segs[i].head)) {
      Instruction *t = p->getTerminator();
      for (unsigned k = 0; k < t->getNumSuccessors(); ++k)
        if (t->getSuccessor(k) == segs[i].head && !entering[i].first)
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
                                                         : segs[i].head;
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

  // cq-h5uj: the copies of the exit values are undone first (they read the last trip's rails, a trip's merge's arms included).
  BasicBlock *copyBlock = nullptr;
  if (copyScope != ~0u) {
    copyBlock = newBlock();
    IRBuilder<> Bc(copyBlock);
    U.emitMirror(copyScope, Bc);
  }

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
    BasicBlock *start;
    if (exitIndex) {
      // cq-j5mq: the reverse starts at the segment of the exit edge taken.
      start = newBlock();
      Value *ix = guarded ? carryTo(guardBlock, X, exitIndex, PoisonValue::get(exitIndex->getType()), "exit", resetAt)
                          : static_cast<Value *>(exitIndex);
      SwitchInst *sw = SwitchInst::Create(ix, R[segOf.lookup(exitSegs[0])], exitSegs.size() - 1, start);
      for (unsigned k = 1; k < exitSegs.size(); ++k)
        sw->addCase(ConstantInt::get(i32, k), R[segOf.lookup(exitSegs[k])]);
    } else {
      BasicBlock *exitSeg = nullptr;
      for (BasicBlock *p : predecessors(X)) {
        if (!region.count(p) || (exitSeg && exitSeg != p))
          internalError("loops-classical: the loop's exit block is not reached from exactly one segment",
                        top.getHeader()->getTerminator());
        exitSeg = p;
      }
      start = R[segOf.lookup(exitSeg)];
    }
    if (copyBlock) {
      BranchInst::Create(start, copyBlock);
      start = copyBlock;
    }
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
    SmallVector<BasicBlock *, 8> revBlocks(R.begin(), R.end());
    if (copyBlock) {
      rev.insert(copyBlock);
      revBlocks.push_back(copyBlock);
    }
    std::vector<Use *> outside;
    for (BasicBlock *b : revBlocks)
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
  // cq-h5uj: inside a K-loop trip the preheader's rails are the trip's (lowered before the classical branch
  // around the loop): the spine places them after every reader, the deferred reverse included.
  if (!inTrip)
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

namespace exits {

Value *lowerClassicalInTrip(LoweringContext &ctx, Loop &L, Value *trip) {
  Case c = classify(L, ctx.T, ctx.S);
  if (c == Case::QuantumExit)
    internalError("loops-classical: lowerClassicalInTrip of a quantum-exit loop (loops-cutoff)", L.getHeader()->getTerminator());
  if (!trip)
    internalError("loops-classical: a loop in a K-loop trip with no trip rail", L.getHeader()->getTerminator());
  // The unit is lowered once per unrolled trip: its phis (and the continuation phis a multi-exit case-3 unit
  // binds) still name the previous trip's lowering, which this one replaces (as lowerInstruction does, cq-lx8f).
  spine::Shared &sh = spine::shared(ctx);
  Unit SU = unitOf(L);
  auto forget = [&](BasicBlock *b) {
    for (PHINode &p : b->phis())
      sh.binds.erase(&p);
  };
  for (BasicBlock *b : L.blocks())
    forget(b);
  for (BasicBlock *b : SU.arm)
    forget(b);
  if (c == Case::ClassicalBoundQuantumExit && SU.cont &&
      (SU.multi() || liveExiting(L) != L.getLoopLatch() || !SU.abort.empty()))
    for (PHINode &p : SU.cont->phis())
      if (any_of(p.blocks(), [&](const BasicBlock *u) { return SU.contains(L, u); }))
        sh.binds.erase(&p);
  return std::make_shared<cq::loops::Unit>(ctx, L)->runInTrip(c, trip);
}

} // namespace exits

} // namespace cq::loops
