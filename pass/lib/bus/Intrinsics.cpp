// Rule 22: memcpy, memmove and memset as byte accesses on the bus, one rolled construction for every length. A copy loads
// all its source bytes and then stores all of them: its load loop pushes, its store loop pops.
//
// The handles the loops make (a byte rail, a p_j, an address rail of one trip) outlive their SSA values or are undone in
// their trip, so Uncompute holds them as external kept rails and places no item for them: a byte rail is the value rail
// of a kept store, p_j its control rail (rule 5 sentence 3).
#include "BusInternal.h"

#include "cq/Abi.h"
#include "../spine/SpineInternal.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"

using namespace llvm;

namespace cq::bus {

namespace {

const RailType W8{Kind::Int, 8}, W64{Kind::Int, 64}, W1{Kind::Int, 1};

abi::TemplateSpec addHl() {
  abi::TemplateSpec a;
  a.op = "add";
  a.w = W64;
  a.shape = "hl";
  return a;
}

abi::TemplateSpec ugtHl() {
  abi::TemplateSpec g;
  g.op = "icmp";
  g.pred = "ugt";
  g.w = W64;
  g.shape = "hl";
  return g;
}

// A template no Uncompute item undoes: the caller undoes it in the trip, or it is kept.
CallInst *rawTemplate(LoweringContext &ctx, const abi::TemplateSpec &t, ArrayRef<Value *> args) {
  CallInst *c = ctx.B().CreateCall(abi::declare(ctx.M, t, /*unc=*/false), args);
  ctx.unc().recordExternal(c, Role::Kept);
  return c;
}

void undoRaw(LoweringContext &ctx, const abi::TemplateSpec &t, CallInst *fwd) {
  SmallVector<Value *, 4> args{fwd};
  args.append(fwd->arg_begin(), fwd->arg_end());
  ctx.B().CreateCall(abi::declare(ctx.M, t, /*unc=*/true), args);
  ctx.emitCore(abi::CoreSpec{abi::Core::Free}, {fwd});
}

// One classical host loop over j in [0, trips) or (trips, 0], guarded when `trips` is not a constant: `body` gets the
// byte index. Leaves the builder in a fresh block after the loop.
template <typename Body>
void hostLoop(LoweringContext &ctx, Value *trips, bool down, Body body) {
  IRBuilder<> &B = ctx.B();
  LLVMContext &C = ctx.M.getContext();
  Type *I64 = Type::getInt64Ty(C);
  auto *k = dyn_cast<ConstantInt>(trips);
  BasicBlock *pre = B.GetInsertBlock();
  BasicBlock *after = BasicBlock::Create(C, "", &ctx.out());
  if (k && k->isZero()) {
    B.CreateBr(after);
    B.SetInsertPoint(after);
    return;
  }
  BasicBlock *loop = BasicBlock::Create(C, "", &ctx.out(), after);
  Value *start = down ? B.CreateNSWAdd(trips, ConstantInt::getSigned(I64, -1)) : ConstantInt::get(I64, 0);
  if (k)
    B.CreateBr(loop);
  else
    B.CreateCondBr(B.CreateICmpEQ(trips, ConstantInt::get(I64, 0)), after, loop);
  B.SetInsertPoint(loop);
  PHINode *j = B.CreatePHI(I64, 2);
  j->addIncoming(start, pre);
  body(j);
  BasicBlock *end = B.GetInsertBlock();
  Value *next, *done;
  if (down) {
    next = B.CreateNSWAdd(j, ConstantInt::getSigned(I64, -1));
    done = B.CreateICmpEQ(j, ConstantInt::get(I64, 0));
  } else {
    next = B.CreateNUWAdd(j, ConstantInt::get(I64, 1));
    done = B.CreateICmpEQ(next, trips);
  }
  B.CreateCondBr(done, after, loop);
  j->addIncoming(next, end);
  B.SetInsertPoint(after);
}

// The address of byte j: a classical sum, or the fresh rail add_i64_hl(r, j) for an address rail (j = 0 included).
struct ByteAddr {
  Operand addr;
  CallInst *rail = nullptr;
};
ByteAddr byteAddress(LoweringContext &ctx, Operand base, Value *j) {
  if (!base.handle)
    return {Operand{ctx.B().CreateAdd(base.v, j), false}, nullptr};
  CallInst *r = rawTemplate(ctx, addHl(), {base.v, j});
  return {Operand{r, true}, r};
}
void endByteAddress(LoweringContext &ctx, const ByteAddr &a) {
  if (a.rail)
    undoRaw(ctx, addHl(), a.rail);
}

CallInst *byteLoad(LoweringContext &ctx, Value *c, Operand addr) {
  abi::CoreSpec s{abi::Core::QramLoad, W8, /*ctl=*/c != nullptr, /*hl=*/!addr.handle};
  SmallVector<Value *, 3> args;
  if (c)
    args.push_back(c);
  args.append({mem(ctx), addr.v});
  CallInst *h = ctx.emitCore(s, args);
  ctx.unc().recordExternal(h, Role::Kept);
  return h;
}

CallInst *byteStore(LoweringContext &ctx, Value *c, Operand addr, Value *v) {
  abi::CoreSpec s{abi::Core::QramStore, W8, /*ctl=*/c != nullptr, /*hl=*/!addr.handle};
  SmallVector<Value *, 4> args;
  if (c)
    args.push_back(c);
  args.append({mem(ctx), addr.v, v});
  return ctx.emitCore(s, args);
}

// p_j = icmp_ugt_i64_hl(n, j); under a predicate c in scope the byte's ONE predicate is their conjunction and p_j is
// undone at once (rule 22: "a predicate c in scope is conjoined with p_j").
Value *bytePredicate(LoweringContext &ctx, Value *n, Value *j, Value *c) {
  abi::TemplateSpec g = ugtHl();
  CallInst *p = rawTemplate(ctx, g, {n, j});
  if (!c)
    return p;
  CallInst *t = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, W1}, {ConstantInt::getFalse(ctx.M.getContext())});
  ctx.unc().recordExternal(t, Role::Kept);
  ctx.emitCore(abi::CoreSpec{abi::Core::AndI1}, {p, c, t});
  undoRaw(ctx, g, p);
  return t;
}

bool isRailCall(const Value *v) {
  auto *c = dyn_cast<CallInst>(v);
  if (!c || !c->getCalledFunction() || !c->getType()->isIntegerTy(32))
    return false;
  StringRef n = c->getCalledFunction()->getName();
  return n.starts_with("cq_template_") || n.starts_with("cqrt_qram_load_") || n.starts_with("cqrt_alloc_");
}

// Rail handles the original program may still read: every binding with a reading use that does not dominate the
// instruction being lowered. Over-approximate: a kept rail stays only overtaken, never wrong.
void liveLaterRails(LoweringContext &ctx, DenseSet<const Value *> &live) {
  spine::Shared &sh = spine::shared(ctx);
  const Instruction *cur = sh.cur;
  DominatorTree &DT = sh.dt(*ctx.S.F);
  for (auto &[orig, ops] : sh.binds) {
    SmallVector<const Use *, 8> uses;
    spine::readingUses(sh, orig, uses);
    for (const Use *U : uses) {
      auto *ui = dyn_cast<Instruction>(U->getUser());
      if (!ui || ui == cur || (cur && DT.dominates(ui, cur)))
        continue;
      for (const Operand &o : ops)
        if (o.handle)
          live.insert(o.v);
      break;
    }
  }
}

// `from` reaches `to` over single-successor blocks only: every path from `from` passes `to`.
bool onEveryPath(const BasicBlock *from, const BasicBlock *to) {
  SmallPtrSet<const BasicBlock *, 8> seen;
  for (const BasicBlock *b = from; b != to; b = b->getSingleSuccessor())
    if (!b || !seen.insert(b).second)
      return false;
  return true;
}

// `cqrt_invert_begin` with no end yet: rule 17 places no uncompute of an earlier rail inside the region.
bool inInvertRegion(LoweringContext &ctx) {
  int open = 0;
  for (BasicBlock &b : ctx.out())
    for (Instruction &I : b)
      if (auto *c = dyn_cast<CallInst>(&I); c && c->getCalledFunction()) {
        StringRef n = c->getCalledFunction()->getName();
        open += n == "cqrt_invert_begin" ? 1 : n == "cqrt_invert_end" ? -1 : 0;
      }
  return open > 0;
}

// Rule 22: "the length rail (and what produced it) has its last consumer in the load loop and is uncomputed between the
// two loops"; rule 5: a load copy among them is then freed before the first store. Places, before the terminator of a
// fresh block, the items of `roots` and of the rails that produced them, except what is read later (`liveToo`, or the
// original program's later uses). A rule-14 trip's mirror reads them instead (a loop unit resolves its own).
void resolveFinished(LoweringContext &ctx, ArrayRef<Value *> roots, ArrayRef<Value *> liveToo) {
  IRBuilder<> &B = ctx.B();
  BasicBlock *mid = B.GetInsertBlock();
  BasicBlock *next = BasicBlock::Create(ctx.M.getContext(), "", &ctx.out());
  BranchInst *term = B.CreateBr(next);
  B.SetInsertPoint(next);
  if (ctx.loopUnit() || inInvertRegion(ctx))
    return;
  DenseSet<const Value *> live;
  liveLaterRails(ctx, live);
  // The producers of what stays live stay with it.
  SmallVector<Value *, 16> work(liveToo.begin(), liveToo.end());
  for (const Value *v : live)
    work.push_back(const_cast<Value *>(v));
  DenseSet<const Value *> kept;
  while (!work.empty()) {
    Value *v = work.pop_back_val();
    if (!kept.insert(v).second || !isRailCall(v))
      continue;
    for (Value *a : cast<CallInst>(v)->args())
      work.push_back(a);
  }
  // The candidates: every rail call `roots` were made from.
  SetVector<Value *> cands;
  work.assign(roots.begin(), roots.end());
  while (!work.empty()) {
    Value *v = work.pop_back_val();
    if (!isRailCall(v) || kept.count(v) || !cands.insert(v))
      continue;
    for (Value *a : cast<CallInst>(v)->args())
      work.push_back(a);
  }
  Uncompute &U = ctx.unc();
  auto pendingRail = [&](Value *h) {
    std::optional<Role> r = U.liveRole(U.idOf(h));
    return r && (*r == Role::Garbage || *r == Role::Seed);
  };
  // A rail stays when a pending reader outside the set reads it, or when its definition may be skipped on the way here.
  for (bool changed = true; changed;) {
    changed = false;
    for (Value *h : cands.getArrayRef()) {
      bool blocked = !onEveryPath(cast<Instruction>(h)->getParent(), mid);
      for (User *u : h->users()) {
        if (blocked)
          break;
        auto *c = dyn_cast<CallInst>(u);
        if (!c || !c->getCalledFunction()) {
          blocked = true;
          break;
        }
        StringRef n = c->getCalledFunction()->getName();
        if (n.ends_with("_unc") || n == "cqrt_free" || n == "cqrt_push" || n.starts_with("cqrt_qram_store_"))
          continue;
        if (!isRailCall(c)) {
          blocked = true;
          continue;
        }
        if (!cands.contains(c) && pendingRail(c))
          blocked = true;
      }
      if (blocked) {
        cands.remove(h);
        changed = true;
        break;
      }
    }
  }
  SmallVector<RailId, 16> rails;
  for (Value *h : cands)
    if (pendingRail(h))
      rails.push_back(U.idOf(h));
  if (!rails.empty())
    U.resolveAt(term, rails);
}

} // namespace

void emitCopy(LoweringContext &ctx, const CopySpec &s) {
  bool quantumLength = s.length.handle;
  bool first = true;
  // Load loop: each byte under its predicate; p_j first, then the byte rail.
  hostLoop(ctx, s.trips, /*down=*/false, [&](Value *j) {
    Value *c = quantumLength ? bytePredicate(ctx, s.length.v, j, s.ctl) : s.ctl;
    ByteAddr a = byteAddress(ctx, s.src, j);
    CallInst *h = byteLoad(ctx, c, a.addr);
    endByteAddress(ctx, a);
    if (quantumLength)
      ctx.emitCore(abi::CoreSpec{abi::Core::Push}, {c});
    ctx.emitCore(abi::CoreSpec{abi::Core::Push}, {h});
  });
  SmallVector<Value *, 2> roots, dstLive;
  if (s.length.handle)
    roots.push_back(s.length.v);
  if (s.src.handle)
    roots.push_back(s.src.v);
  if (s.dst.handle)
    dstLive.push_back(s.dst.v);
  resolveFinished(ctx, roots, dstLive);
  // Store loop: bytes n-1 down to 0; each store is a kept store (rule 5), its rails stay.
  hostLoop(ctx, s.trips, /*down=*/true, [&](Value *j) {
    Value *h = ctx.emitCore(abi::CoreSpec{abi::Core::Pop}, {});
    ctx.unc().recordExternal(h, Role::Kept);
    Value *c = s.ctl;
    if (quantumLength) {
      c = ctx.emitCore(abi::CoreSpec{abi::Core::Pop}, {});
      ctx.unc().recordExternal(c, Role::Kept);
    }
    ByteAddr a = byteAddress(ctx, s.dst, j);
    CallInst *st = byteStore(ctx, c, a.addr, h);
    endByteAddress(ctx, a);
    if (first) {
      first = false;
      ctx.unc().noteKeptStore(st, h, c);
      ctx.unc().noteVersionChange(st);
    }
  });
  if (s.dst.handle) {
    SmallVector<Value *, 1> dstRoot{s.dst.v};
    resolveFinished(ctx, dstRoot, {});
  }
}

// Rule 22 memset: ONE loop of byte stores of one i8 value rail.
static void emitSet(LoweringContext &ctx, Operand dst, Operand byte, Operand length, Value *trips, Value *ctl) {
  auto *k = dyn_cast<ConstantInt>(trips);
  if (k && k->isZero())
    return;
  Value *v = byte.v;
  if (!byte.handle) {
    CallInst *seed = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, W8}, {byte.v});
    ctx.unc().recordSeed(seed);
    v = seed;
  }
  bool quantumLength = length.handle;
  bool first = true;
  hostLoop(ctx, trips, /*down=*/false, [&](Value *j) {
    Value *c = quantumLength ? bytePredicate(ctx, length.v, j, ctl) : ctl;
    ByteAddr a = byteAddress(ctx, dst, j);
    CallInst *st = byteStore(ctx, c, a.addr, v);
    endByteAddress(ctx, a);
    if (first) {
      first = false;
      ctx.unc().noteKeptStore(st, v, c);
      ctx.unc().noteVersionChange(st);
    }
  });
  SmallVector<Value *, 2> roots;
  if (length.handle)
    roots.push_back(length.v);
  if (dst.handle)
    roots.push_back(dst.v);
  if (!roots.empty())
    resolveFinished(ctx, roots, {});
}

// A rail length: min(K2, B) trips, and the kept overflow predicate n > K2 when B > K2 or no bound is known.
static Value *quantumTrips(LoweringContext &ctx, Operand n, std::optional<uint64_t> bound) {
  uint64_t k2 = K2(ctx);
  Type *I64 = Type::getInt64Ty(ctx.M.getContext());
  if (!bound || *bound > k2) {
    Value *o = ctx.emitTemplate(ugtHl(), {n, Operand{ConstantInt::get(I64, k2), false}});
    ctx.unc().setRole(ctx.unc().idOf(o), Role::KeptOverflow);
    return ConstantInt::get(I64, k2);
  }
  return ConstantInt::get(I64, *bound);
}

void lowerMemIntrinsic(LoweringContext &ctx, MemIntrinsic &MI) {
  const Value *len = MI.getLength();
  Operand n = ctx.operand(len);
  if (!len->getType()->isIntegerTy(64))
    report_fatal_error("cq: unimplemented: bus: a memory intrinsic whose length is not i64", /*gen_crash_diag=*/false);
  Value *ctl = accessControl(ctx);
  Operand dst = address(ctx, MI.getRawDest());
  if (auto *M = dyn_cast<MemSetInst>(&MI)) {
    Operand byte = ctx.operand(M->getValue());
    Value *trips = n.handle ? quantumTrips(ctx, n, rangeBound(ctx, len)) : n.v;
    emitSet(ctx, dst, byte, n, trips, ctl);
    return;
  }
  if (auto *M = dyn_cast<MemSetInlineInst>(&MI)) {
    Operand byte = ctx.operand(M->getValue());
    Value *trips = n.handle ? quantumTrips(ctx, n, rangeBound(ctx, len)) : n.v;
    emitSet(ctx, dst, byte, n, trips, ctl);
    return;
  }
  auto *T = dyn_cast<MemTransferInst>(&MI);
  auto *TI = dyn_cast<MemCpyInlineInst>(&MI);
  if (!T && !TI)
    report_fatal_error("cq: unimplemented: bus: a memory intrinsic that is neither a set nor a transfer",
                       /*gen_crash_diag=*/false);
  const Value *origSrc = T ? T->getRawSource() : TI->getRawSource();
  CopySpec s;
  s.dst = dst;
  s.src = address(ctx, origSrc);
  s.length = n;
  s.trips = n.handle ? quantumTrips(ctx, n, rangeBound(ctx, len)) : n.v;
  s.ctl = ctl;
  s.at = &MI;
  emitCopy(ctx, s);
}

void lowerCopy(LoweringContext &ctx, Operand dst, Operand src, Operand len, Value *ctl, Instruction &at) {
  CopySpec s;
  s.dst = dst;
  s.src = src;
  s.length = len;
  s.trips = len.handle ? quantumTrips(ctx, len, std::nullopt) : len.v;
  s.ctl = ctl;
  s.at = &at;
  emitCopy(ctx, s);
}

} // namespace cq::bus
