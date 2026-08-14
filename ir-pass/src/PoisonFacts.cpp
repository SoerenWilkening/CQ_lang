//===- PoisonFacts.cpp ----------------------------------------------------===//
//
// bd s6ao. See PoisonFacts.h for WHY this exists — in particular for the
// measured fact that `UseInstrInfo=false` gates exactly five `InstrInfoQuery`
// accessors and structurally cannot reach `nneg`, `disjoint` or the `range`
// attribute.
//
//===----------------------------------------------------------------------===//

#include "PoisonFacts.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Operator.h"

#include <algorithm>
#include <optional>

using namespace llvm;

namespace cq {

bool curatedIntrinsicCanBePoison(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return true;
  Intrinsic::ID Id = F->getIntrinsicID();
  if (Id != Intrinsic::ctlz && Id != Intrinsic::cttz && Id != Intrinsic::abs)
    return false;
  const auto *Flag = CI->arg_size() >= 2
                         ? dyn_cast<ConstantInt>(CI->getArgOperand(1))
                         : nullptr;
  return !Flag || !Flag->isZero();
}

namespace {

// `V`'s type's full unsigned range at the `Wide` accumulator, or nullopt when the
// type is wider than the accumulator (i.e. unbounded as far as this analysis is
// concerned).
std::optional<APInt> fullOf(const Value *X, unsigned Wide) {
  unsigned W = X->getType()->getScalarSizeInBits();
  return W && W <= Wide ? std::optional<APInt>(APInt::getMaxValue(W).zext(Wide))
                        : std::nullopt;
}

// A non-instruction leaf: a literal's own value, else the type's full range.
std::optional<APInt> leafMax(const Value *V, unsigned Wide) {
  if (const auto *C = dyn_cast<ConstantInt>(V))
    return C->getValue().getBitWidth() <= Wide
               ? std::optional<APInt>(C->getValue().zext(Wide))
               : std::nullopt;
  return fullOf(V, Wide);
}

// The largest UNSIGNED value `I` can take, given its operands' already-computed
// maxima (`ch`), established from OPCODES AND CONSTANT OPERANDS ALONE — no
// annotation, no metadata, no attribute, no poison assumption, no `llvm.assume`.
// `nullopt` means "not bounded by this analysis".
//
// *** THE SHAPE OF THIS QUESTION MATTERS MORE THAN ITS COVERAGE. *** It is NOT
// "is a poison-conditional fact present in the cone". That is what an earlier
// draft asked and it was wrong in the expensive direction: `clang -O1` stamps
// `nneg` on `zext` ROUTINELY — the 220-module stage-1 cache carries 139 such sites across 43 files, and in every one
// the real bound comes from an `and` FURTHER DOWN, so the flag is present and
// irrelevant. Refusing on presence regressed nine committed libm goldens (the
// `exp`/`exp2`/`sinh`/`cosh`/`erf` `ln2HI[xsb]` family) plus both spec-qram
// slices — measured, not predicted.
//
// Asking instead "can this index be bounded WITHOUT any such fact" is both sound
// and precise: if a fact-free bound exists then every annotation in the cone is
// irrelevant by construction, and if none exists we refuse regardless of which
// channel the missing fact would have arrived through. That makes the verdict
// independent of the ENUMERATION of poison channels — which matters, because that
// enumeration is exactly what LLVM keeps changing under us (19 migrated call
// `!range` metadata to the `range` attribute mid-stream, silently reopening a
// channel a fix written against 18 would have considered closed).
//
// EVERY RULE MUST HOLD FOR ALL OPERAND VALUES, INCLUDING POISON ONES. Opcodes
// that wrap or set bits are admitted ONLY behind a no-wrap check computed at the
// wider accumulator (`Add`, `Shl`) or a bit-count argument that needs no such
// check (`Or`, `Xor`). `sub`/`mul`/`ashr`/`sdiv`/`srem`/`sext`/`fptosi`/`fptoui`
// and every unmodelled opcode fall to `full`. Conservative = over-decline = safe.
std::optional<APInt> evalNode(const Instruction *I, unsigned Wide,
                              function_ref<std::optional<APInt>(unsigned)> ch) {
  const Value *V = I;
  auto full = [&] { return fullOf(V, Wide); };
  auto minOf = [](std::optional<APInt> A,
                  std::optional<APInt> B) -> std::optional<APInt> {
    if (!A)
      return B;
    if (!B)
      return A;
    return A->ult(*B) ? A : B;
  };

  if (const auto *BO = dyn_cast<BinaryOperator>(I)) {
    const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1));
    unsigned W = BO->getType()->getScalarSizeInBits();
    switch (BO->getOpcode()) {
    case Instruction::And:  // <= either side's max (masking only clears bits).
      return minOf(ch(0), ch(1));
    case Instruction::URem:
      // < C for a nonzero constant C (`urem X, 0` is poison). The WIDTH GUARD is
      // not defensive tidiness: `Wide` is 65 here, so an `iN` urem with N > 65
      // reached through `Trunc` below made this a DOWN-extension, and
      // `APInt::zext` then memcpy'd getNumWords(N) words into a 2-word buffer —
      // a heap overrun, measured as a DETERMINISTIC SIGSEGV (exit 139, 3/3) from
      // `urem i256`, which `clang -O1 -std=c23` emits for `unsigned
      // _BitInt(256)`.
      if (!C || C->isZero() || C->getValue().getBitWidth() > Wide)
        return full();
      return (C->getValue() - 1).zext(Wide);
    case Instruction::UDiv:
      // `udiv X, Y <= X` HOLDS ONLY FOR Y != 0 — `udiv X, 0` is poison, so an
      // unguarded rule here reinstates exactly the modulo-poison bound this file
      // exists to reject. Measured over-accept before the guard: `udiv i64 %hi,
      // 0` lowered to an UNMASKED `cqrt_qram_load_f64` into a 3-cell table at
      // `opt` exit 0, free-pairing clean, while the guarded `urem` twin declined.
      // This analysis has no min-value lattice, so a nonzero CONSTANT divisor is
      // the only case it can discharge.
      return C && !C->isZero() ? ch(0) : full();
    case Instruction::LShr: {
      std::optional<APInt> A = ch(0);
      if (!A || !C || !C->getValue().ult(W))
        return full();  // a shift >= the operand width is poison.
      // *** THE SHIFT AMOUNT IS BOUNDED BY THE INSTRUCTION'S WIDTH, WHICH CAN
      // EXCEED THE ACCUMULATOR'S. *** `A` is a `Wide`-bit (65) APInt even when
      // the instruction is i128+, because `ZExt` propagates a narrow operand's
      // max upward — so `lshr i128 %z, 120` reached `APInt::lshr(120)` on a
      // 65-bit value, violating `assert(ShiftAmt <= BitWidth)` (APInt.h). The
      // MEASURED, and NOT the scarier story an earlier draft told here: in the
      // shipped Release build `APInt::lshr` ALREADY returns 0 for an over-width
      // amount (verified against llvm@19 with -DNDEBUG for shifts of
      // 64/65/70/100/120/127/128/200 on a 65-bit value; `strings libCQPass.so |
      // grep 'Invalid shift amount'` = 0). So this branch changes NOTHING in the
      // shipped configuration. It is kept because an assertions-enabled build
      // WOULD abort without it, and because 0 is the correct and tightest bound
      // (a value already known below 2^Wide, shifted right by >= Wide, is 0).
      uint64_t Sh = C->getValue().getZExtValue();
      if (Sh >= Wide)
        return APInt::getZero(Wide);
      return A->lshr(Sh);
    }
    // `or`/`xor` cannot produce a value needing more bits than the WIDER
    // operand's max needs. This is unconditional — it does NOT use `disjoint`,
    // which is the whole point: `or disjoint i32 %m, 1` with `%m = and %x, 510`
    // is <= 511 whatever `%m` is, because 510 occupies 9 bits. Modelling `or` as
    // unbounded cost the `exp2`/`exp2l` goldens, whose 512-cell `tbl` is read at
    // BOTH `%m` and `%m|1` — measured, and the second read is what regressed.
    case Instruction::Or:
    case Instruction::Xor: {
      std::optional<APInt> A = ch(0), B = ch(1);
      if (!A || !B)
        return full();
      unsigned K = std::max(A->getActiveBits(), B->getActiveBits());
      if (K == 0)
        return APInt::getZero(Wide);
      if (K > W)
        return full();
      return APInt::getMaxValue(K).zext(Wide);
    }
    // Sound only while the sum/shift provably does NOT wrap the operand width —
    // and that check uses no flag: it compares against 2^W at the wider
    // accumulator width. A cone whose bound needs `nuw` to rule out the wrap
    // falls through to `full` and is refused, which is exactly the `sub nuw`
    // exhibit's fate.
    case Instruction::Add: {
      std::optional<APInt> A = ch(0), B = ch(1);
      if (!A || !B || W >= Wide)
        return full();
      APInt S = *A + *B;
      return S.ult(APInt::getOneBitSet(Wide, W)) ? std::optional<APInt>(S)
                                                 : full();
    }
    case Instruction::Shl: {
      std::optional<APInt> A = ch(0);
      if (!A || !C || !C->getValue().ult(W) || W >= Wide)
        return full();
      // *** GUARD ON THE OPERAND'S MAGNITUDE, NEVER ON THE PRODUCT. ***
      // `APInt::shl` TRUNCATES at `Wide`, so testing the product for wrap reads
      // a product that overflowed 2^Wide as "no wrap" and returns a bound BELOW
      // the truth — the rule then becomes NON-MONOTONE and the fence inverts.
      // MEASURED counterexample on the product form: max 64 (what the ctpop rule
      // returns for i64) shifted by 59 gives 2^65, truncated to 0, so the rule
      // claimed max 0 while the true max is 0xF800_0000_0000_0000 — an UNMASKED
      // read at index 2^59 of a THREE-cell table, `opt` exit 0. The same module
      // with the shift at 58 correctly DECLINED: the smaller index refused and
      // the larger accepted, the signature of a broken bound.
      uint64_t Sh = C->getValue().getZExtValue();
      if (A->getActiveBits() + Sh > W)
        return full();
      return A->shl(Sh);
    }
    default:
      return full();
    }
  }
  if (const auto *CI = dyn_cast<CastInst>(I)) {
    if (CI->getOpcode() == Instruction::ZExt)
      return ch(0);  // value-preserving.
    if (CI->getOpcode() == Instruction::Trunc)
      return minOf(ch(0), full());
    return full();  // sext / fptosi / fptoui / ptr casts.
  }
  if (isa<SelectInst>(I)) {
    std::optional<APInt> A = ch(1), B = ch(2);
    if (!A || !B)
      return std::nullopt;
    return A->ugt(*B) ? A : B;
  }
  if (const auto *PN = dyn_cast<PHINode>(I)) {
    std::optional<APInt> Best(APInt::getZero(Wide));
    for (unsigned N = 0, E = PN->getNumIncomingValues(); N != E; ++N) {
      std::optional<APInt> M = ch(N);
      if (!M)
        return std::nullopt;
      if (M->ugt(*Best))
        Best = M;
    }
    return Best;
  }
  if (const auto *CB = dyn_cast<CallBase>(I)) {
    // `ctpop`/`ctlz`/`cttz` are bounded by the OPERAND'S BIT WIDTH regardless of
    // any `is_zero_poison` immarg or `range` attribute — and that is exactly the
    // point. The unconditional bound for `cttz(x, i1 true)` on i64 is 64, NOT the
    // 63 the immarg licenses, and 64 is what the emitted circuit can actually
    // produce because Rule 15's width-only ABI discards the immarg. This one rule
    // is what turns the `__builtin_ctzll` silent miscompile into a masked read.
    if (const auto *F = CB->getCalledFunction()) {
      Intrinsic::ID Id = F->getIntrinsicID();
      if (Id == Intrinsic::ctpop || Id == Intrinsic::ctlz ||
          Id == Intrinsic::cttz) {
        unsigned SrcW = CB->getArgOperand(0)->getType()->getScalarSizeInBits();
        if (SrcW && SrcW <= Wide)
          return APInt(Wide, SrcW);
      }
    }
    return full();
  }
  return full();
}

// ITERATIVE post-order over the index cone. *** THE ITERATION IS A CORRECTNESS
// REQUIREMENT, NOT A STYLE CHOICE. *** The recursive draft descended one C++
// frame per SSA node with no worklist, and a linear `or i64 %p, 1` chain
// overflowed the stack: MEASURED clean at 8,000 nodes and SIGILL (exit 132,
// stack-guard) from 20,000 up, with the crash report showing nothing but
// recursive frames under `flattenPredMuxRegions`.
//
// THE REASON THAT IS A CORRECTNESS BUG AND NOT MERELY A DoS: the crash fires
// BEFORE any verdict, so it PRE-EMPTS THE LOUD DECLINE. The 20,000-node probe
// ends on an unbounded index, whose Prime-Directive outcome is `exit 1` with
// `kMsgQromUnderControlBounds`; instead `opt` died with no diagnostic, no `!dbg`
// and no lowered module. A crash is not a decline.
//
// Attribution was measured, not inferred: the SAME 80,000-node chain routed to
// `uitofp` + `cq_measure` instead of a QROM gep exits 0 in 0.56s, so taint
// propagation, `lowerOps`, the whole-DAG LIFO uncompute and `EmitInverse` all
// survive an order of magnitude more nodes than this walk did.
//
// *** AUDIT THIS AS NEW CODE. *** It resembles `stripPoisonCone`
// (PredMuxFlatten.cpp) only in the loosest sense — both use a worklist and a
// visited set. That walk is single-phase LIFO reachability: pop, classify,
// mutate, push, with a `SmallPtrSet` and nothing else. This one is a POST-ORDER
// EVALUATOR: an `expanded` flag per entry, an on-stack set for cycle cuts, and a
// value memo whose entries are consumed by the parent. Every hard part is new,
// and claiming lineage from a reviewed walk is a good way to get an unreviewed
// one waved through.
//
// MEMOISATION is likewise required, and for a second, independent reason: the
// `Memo` doubles as the visited set, so a DAG is evaluated once per node rather
// than once per PATH. Without it, 40 nested diamonds took the pass from
// milliseconds to NOT TERMINATING IN 2 MINUTES, and a later draft that memoised
// only the BOUNDED returns merely relocated the same 2^N blowup to the
// `nullopt` exits (N=20 0.80s, N=24 7.20s, on ACCEPTED input).
//
// CYCLES (loop phis) are cut by `OnStack`: an operand currently being expanded
// is not re-pushed, and `ch` then reads it as the type's full range. Cutting to
// the CONSERVATIVE full range is what makes the cut sound in the memo — an entry
// computed under a cut can be less precise than a fresh one, never less safe —
// and it terminates structurally, with no depth budget. A budget would make the
// ANSWER depend on the cut-off (bd
// [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]]).
std::optional<APInt> unconditionalMax(const Value *Root, unsigned Wide) {
  DenseMap<const Value *, std::optional<APInt>> Memo;
  SmallPtrSet<const Value *, 32> OnStack;
  SmallVector<std::pair<const Value *, bool>, 64> Stack;  // (node, expanded)
  Stack.emplace_back(Root, false);
  while (!Stack.empty()) {
    const Value *V = Stack.back().first;
    if (Memo.count(V)) {
      OnStack.erase(V);
      Stack.pop_back();
      continue;
    }
    const auto *I = dyn_cast<Instruction>(V);
    if (!I || V->getType()->isVectorTy()) {
      Memo[V] = leafMax(V, Wide);
      Stack.pop_back();
      continue;
    }
    if (!Stack.back().second) {
      Stack.back().second = true;
      OnStack.insert(V);
      for (const Use &Op : I->operands()) {
        const Value *O = Op.get();
        if (!Memo.count(O) && !OnStack.count(O))
          Stack.emplace_back(O, false);
      }
      continue;
    }
    Memo[V] = evalNode(I, Wide, [&](unsigned N) -> std::optional<APInt> {
      const Value *O = I->getOperand(N);
      auto It = Memo.find(O);
      return It != Memo.end() ? It->second : fullOf(O, Wide);  // cycle cut
    });
    OnStack.erase(V);
    Stack.pop_back();
  }
  return Memo.lookup(Root);
}

}  // namespace

bool indexBoundIsPoisonConditional(const Value *RawIndex, uint64_t Count) {
  unsigned Wide =
      std::max<unsigned>(RawIndex->getType()->getScalarSizeInBits() + 1, 65);
  if (std::optional<APInt> Max = unconditionalMax(RawIndex, Wide))
    if (Max->ult(APInt(Wide, Count)))
      return false;
  return true;
}

}  // namespace cq
