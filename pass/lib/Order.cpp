// cq::comesBefore: order labels with gaps (an order-maintenance list), see cq/Order.h (cq-g3h1i).
//
// A label is valid for the block it was given in, named by an epoch: a block gets a fresh epoch the first time
// it is asked about, and both maps drop an entry when its value dies (ValueMap), so neither a reused address
// nor a move to another block can make a stale label look valid. An instruction with no valid label is
// labelled from its labelled neighbours; when no label is free between them a window around it is spread
// evenly. The window doubles until its labels are far enough apart, and a larger window must be sparser
// (spacing >= kMinGap * size), so a window just spread takes as many insertions as it has members before it
// is spread again: O(log n) relabelled instructions per insertion, amortized.
#include "cq/Order.h"

#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/ValueMap.h"

using namespace llvm;

namespace {
template <typename K> struct NoFollow : ValueMapConfig<K> {
  enum { FollowRAUW = false };   // a label stays with its instruction; the replacement gets its own
};
struct Label {
  uint64_t pos;
  uint32_t epoch;
};
struct State {
  ValueMap<const Instruction *, Label, NoFollow<const Instruction *>> labels;
  ValueMap<const BasicBlock *, uint32_t, NoFollow<const BasicBlock *>> epochs;
  uint32_t nextEpoch = 1;
};
State &state() {
  static State *s = new State;   // never destroyed: its handles must not outlive the LLVMContext at exit
  return *s;
}

const uint64_t kBase = uint64_t(1) << 62;   // the first label of a block numbered afresh
const uint64_t kGap = uint64_t(1) << 32;    // the distance between fresh labels
const uint64_t kMinGap = uint64_t(1) << 10; // a spread window of c instructions keeps kMinGap * c between labels
const uint64_t kTop = ~uint64_t(0) - kGap;

bool labelled(State &S, const Instruction *I, uint32_t ep, uint64_t &pos) {
  auto it = S.labels.find(I);
  if (it == S.labels.end() || it->second.epoch != ep)
    return false;
  pos = it->second.pos;
  return true;
}

// Gives I a valid label, relabelling as few of its neighbours as the gaps allow.
void ensure(State &S, const Instruction *I, uint32_t ep) {
  uint64_t lo = 0, hi = 0, tmp;
  if (labelled(S, I, ep, tmp))
    return;
  // The window [first, last]: at first the run of unlabelled instructions around I. L and R are the labelled
  // instructions next to it (null: the block's end on that side).
  const Instruction *first = I, *last = I;
  size_t count = 1;
  const Instruction *L = first->getPrevNode(), *R = last->getNextNode();
  for (; L && !labelled(S, L, ep, lo); L = L->getPrevNode(), ++count)
    first = L;
  for (; R && !labelled(S, R, ep, hi); R = R->getNextNode(), ++count)
    last = R;
  uint64_t start = 0, step = 0;
  for (size_t grow = 1;; grow *= 2) {
    if (!L && !R) {
      start = kBase, step = kGap;
      break;
    }
    if (!R && lo < kTop && (kTop - lo) / kGap > count) {
      start = lo + kGap, step = kGap;
      break;
    }
    if (!L && hi / kGap > count + 1) {
      start = hi - count * kGap, step = kGap;
      break;
    }
    if (L && R) {
      uint64_t s = (hi - lo) / (count + 1);
      // The run alone only needs a free label each; a window that had to grow must end up sparse.
      if (s >= 1 && (grow == 1 || s / kMinGap >= count)) {
        start = lo + s, step = s;
        break;
      }
    }
    // Take `grow` more instructions on each side into the window (their labels are given up).
    for (size_t k = 0; k < grow && L; ++k) {
      first = L, ++count;
      L = L->getPrevNode();
    }
    for (size_t k = 0; k < grow && R; ++k) {
      last = R, ++count;
      R = R->getNextNode();
    }
    // The new boundaries must be labelled instructions: an unlabelled one joins the window.
    for (; L && !labelled(S, L, ep, lo); L = L->getPrevNode(), ++count)
      first = L;
    for (; R && !labelled(S, R, ep, hi); R = R->getNextNode(), ++count)
      last = R;
  }
  uint64_t pos = start;
  for (const Instruction *X = first;; X = X->getNextNode(), pos += step) {
    S.labels[X] = Label{pos, ep};
    if (X == last)
      break;
  }
}
} // namespace

bool cq::comesBefore(const Instruction *a, const Instruction *b) {
#ifdef CQ_ORDER_CHECK
  if (a->getParent() != b->getParent()) {
    fprintf(stderr, "cq: order check: cq::comesBefore across blocks\n");
    abort();
  }
#endif
  if (a == b)
    return false;
  State &S = state();
  const BasicBlock *bb = a->getParent();
  uint32_t ep;
  if (auto it = S.epochs.find(bb); it != S.epochs.end())
    ep = it->second;
  else
    S.epochs[bb] = ep = S.nextEpoch++;
  ensure(S, a, ep);
  ensure(S, b, ep);   // may relabel a
  uint64_t pa = 0, pb = 0;
  labelled(S, a, ep, pa);
  labelled(S, b, ep, pb);
#ifdef CQ_ORDER_CHECK
  if ((pa < pb) != a->comesBefore(b)) {
    fprintf(stderr, "cq: order check: cq::comesBefore disagrees with Instruction::comesBefore\n");
    abort();
  }
#endif
  return pa < pb;
}

void cq::orderReset() {
  State &S = state();
  S.labels.clear();
  S.epochs.clear();
  S.nextEpoch = 1;
}
