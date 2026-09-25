// ScrubOnDelete.h — pointer-keyed containers that CANNOT hold a deleted Value.
//
// bd test_C_libtooling-8e5r (P1), -um24 (P2), -j8sk (the class). Every
// pointer-keyed side table of `TaintSet` (`Tainted`, `BirthOrder`,
// `HandleWidth`, `ThetaCalls`, ... — the list is in TaintPropagation.h) used to
// be a raw `std::set<Value *>` / `SmallPtrSet` / `DenseMap` / `SmallVector`. A
// stage that ERASED an instruction without also erasing it from every table
// that named it left a DANGLING KEY, and what that key then did was decided by
// the system allocator:
//
//   * nothing, if the freed address was never reused;
//   * a use-after-free READ, if a consumer dereferenced the key (bd um24:
//     `lowerLoops`' per-function scan, SIGSEGV on four shipped fixtures under a
//     reusing allocator);
//   * a SILENT MISCOMPILE, if a fresh instruction of the same size landed at the
//     freed address and then answered `Tainted.count() == true` (bd 8e5r: a
//     Phase-6 clone's CLASSICAL `mul` lowered as `cq_template_mul_i32_hl(7, m)`,
//     the constant used as a handle — `opt` exit 0, verify-clean, stage 2b clean).
//
// The pre-existing defence was a PREDICTION: every erase site must remember to
// scrub every table first. There are ~180 erase sites in `ir-pass/src/` plus
// the LLVM utilities that delete internally, and at least seven of them did not
// (Rule-13 r1B's detector, `review_r1B_9bhg/REVIEW.md`). This header replaces
// the prediction with an OBSERVATION: each container arms one
// `llvm::CallbackVH` per key, and LLVM itself calls it back from inside
// `~Value()` — whoever deleted the value, by whatever route. A deleted key is
// therefore never a member, never yielded by iteration, and never aliased by a
// later allocation at its address. It cannot MISS a deletion, because it is not
// asked to predict one.
//
// ⚠ DEFERRED REMOVAL, AND WHY — THE ITERATION-ORDER ARGUMENT. The callback does
// NOT physically remove the key. It records the address as DEAD, and every
// query (`count`, `find`, `lookup`, iteration, `size`, `empty`) treats a dead
// address as absent. Two reasons, both load-bearing:
//   (1) ITERATION SAFETY. A loop over a container whose body erases an
//       instruction that is a key of THAT container (e.g. `lowerMeasures`
//       walking `MeasureCalls` and erasing each call) would have its iterator
//       invalidated by a physical removal. Marking touches only the dead set.
//   (2) THE EMITTED STREAM MUST NOT MOVE. `SmallPtrSet` erases in small mode by
//       swapping the LAST element into the hole, and `DenseMap` re-uses a
//       tombstone on the next insert, so a physical removal would change the
//       ITERATION ORDER of the surviving keys — and several emitters walk these
//       tables in order. With deferred removal the surviving keys keep EXACTLY
//       the slots and the order they had on the unfixed binary; the only
//       observable differences are the ones that were reads of freed memory:
//       a dead address is absent, and a fresh object inserted at a dead address
//       is a NEW member (`insert(...).second == true`) that inherits the dead
//       slot — which is precisely where the unfixed binary put it.
//   A LIST (`CallList`) nulls the dead SLOTS instead, because a vector can hold
//   the same address twice: the dead slot stays null forever, and a fresh object
//   pushed at that address gets its own slot.
//
// ⚠ IDENTITY, NEVER RAUW. `allUsesReplacedWith` is the inherited no-op: a key is
// the OBJECT it named, exactly as with the raw pointer it replaces. A table that
// must follow a RAUW already uses `WeakTrackingVH` and is not this header's.
//
// ⚠ WHAT IT DOES NOT COVER. A LOCAL snapshot built from one of these tables into
// a plain LLVM container (`SmallPtrSet<CallInst *> GateCalls(taint.ThetaCalls
// ...)`) is a raw copy again, and is exactly as safe as the code between its
// construction and its last read. The copy of a table INTO ANOTHER TABLE OF THIS
// HEADER (`TaintedSet Before = taint.Tainted;`) is self-cleaning. See the
// residual list in `TRACK_8E5R.md` before relying on a local snapshot across an
// erase.
//
// Cost: one heap-allocated `CallbackVH` per distinct key per container, and a
// dead-set probe on each query (skipped when nothing has died).

#ifndef CQ_IRPASS_SCRUB_ON_DELETE_H_
#define CQ_IRPASS_SCRUB_ON_DELETE_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Instructions.h"  // SpineOpSet names llvm::CallInst — self-contained (r1A F-EA-9)
#include "llvm/IR/Value.h"
#include "llvm/IR/ValueHandle.h"

#include <algorithm>
#include <cstddef>
#include <iterator>
#include <memory>
#include <set>
#include <type_traits>
#include <utility>

namespace cq {
namespace scrub {

// The receiver of a key's deletion. One per container, heap-allocated and owned
// by it through a `unique_ptr`, so a hook's back-pointer survives a MOVE of the
// container (`taint = propagate(M, wd)`).
class Owner {
public:
  virtual ~Owner() = default;
  virtual void keyDeleted(const llvm::Value *V) = 0;
};

class KeyHook final : public llvm::CallbackVH {
  Owner *O;

public:
  KeyHook(const llvm::Value *V, Owner *O) : CallbackVH(V), O(O) {}
  ~KeyHook() = default;
  KeyHook(const KeyHook &) = delete;
  KeyHook &operator=(const KeyHook &) = delete;
  void rearm(const llvm::Value *V) { setValPtr(const_cast<llvm::Value *>(V)); }
  bool armed() const { return static_cast<llvm::Value *>(*this) != nullptr; }
  void deleted() override {
    const llvm::Value *V = *this;
    // MUST come first and MUST happen: a value handle still registered on a
    // Value whose `~Value()` has finished is `llvm_unreachable` — UB in a
    // Release build, not an assertion.
    setValPtr(nullptr);
    O->keyDeleted(V);
  }
  // allUsesReplacedWith(): the inherited no-op — IDENTITY, never RAUW.
};

// At most one hook per distinct key Value. A hook whose Value died stays in the
// map, disarmed, and is re-armed if a fresh object at the same address becomes
// a key.
class HookTable {
  llvm::DenseMap<const llvm::Value *, std::unique_ptr<KeyHook>> M;

public:
  void arm(const llvm::Value *V, Owner *O) {
    if (!V)
      return;
    std::unique_ptr<KeyHook> &H = M[V];
    if (!H)
      H = std::make_unique<KeyHook>(V, O);
    else if (!H->armed())
      H->rearm(V);
  }
  void disarm(const llvm::Value *V) { M.erase(V); }
  void clear() { M.clear(); }
};

template <typename PtrT> const llvm::Value *asValue(PtrT P) {
  return static_cast<const llvm::Value *>(P);
}

// ---------------------------------------------------------------------------
// A SET of Value-derived pointers over an unchanged backing container
// (`std::set<T *>`, `SmallPtrSet<T *, N>`), so live keys keep their order.
// ---------------------------------------------------------------------------
template <typename StorageT, typename PtrT> class Set {
  static_assert(std::is_pointer<PtrT>::value, "a Set holds pointers");
  using Pointee = std::remove_pointer_t<PtrT>;
  using KeyArg = const std::remove_const_t<Pointee> *;

  struct Core final : Owner {
    StorageT S;
    llvm::DenseSet<const llvm::Value *> Dead;
    HookTable H;
    void keyDeleted(const llvm::Value *V) override {
      // `V` is mid-destruction: only its ADDRESS is used (a static_cast within
      // a single-inheritance hierarchy rooted at Value is a no-op on it).
      if (S.count(toStore(static_cast<KeyArg>(V))))
        Dead.insert(V);
    }
    bool dead(const llvm::Value *V) const { return !Dead.empty() && Dead.count(V); }
  };
  std::unique_ptr<Core> C;

  static PtrT toStore(KeyArg V) { return const_cast<PtrT>(V); }

public:
  class const_iterator {
    using BaseIt = typename StorageT::const_iterator;
    BaseIt I, E;
    const Core *Co = nullptr;
    void skip() {
      if (Co->Dead.empty())
        return;
      while (I != E && Co->Dead.count(asValue(*I)))
        ++I;
    }

  public:
    using iterator_category = std::forward_iterator_tag;
    using value_type = PtrT;
    using difference_type = std::ptrdiff_t;
    using pointer = const PtrT *;
    using reference = PtrT;
    const_iterator(BaseIt I, BaseIt E, const Core *Co) : I(I), E(E), Co(Co) { skip(); }
    PtrT operator*() const { return *I; }
    const_iterator &operator++() {
      ++I;
      skip();
      return *this;
    }
    const_iterator operator++(int) {
      const_iterator T = *this;
      ++*this;
      return T;
    }
    bool operator==(const const_iterator &O) const { return I == O.I; }
    bool operator!=(const const_iterator &O) const { return I != O.I; }
  };
  using iterator = const_iterator;
  using value_type = PtrT;

  Set() : C(std::make_unique<Core>()) {}
  template <typename It> Set(It B, It E) : Set() { insert(B, E); }
  Set(const Set &O) : Set() { insert(O.begin(), O.end()); }
  Set(Set &&O) : C(std::move(O.C)) { O.C = std::make_unique<Core>(); }
  Set &operator=(const Set &O) {
    if (this != &O) {
      Set T(O);
      std::swap(C, T.C);
    }
    return *this;
  }
  Set &operator=(Set &&O) {
    if (this != &O) {
      C = std::move(O.C);
      O.C = std::make_unique<Core>();
    }
    return *this;
  }

  const_iterator begin() const { return const_iterator(C->S.begin(), C->S.end(), C.get()); }
  const_iterator end() const { return const_iterator(C->S.end(), C->S.end(), C.get()); }

  std::pair<const_iterator, bool> insert(PtrT V) {
    const llvm::Value *K = asValue(V);
    if (C->dead(K)) {
      // A fresh object at a dead key's address: a NEW member, in the dead slot.
      C->Dead.erase(K);
      C->H.arm(K, C.get());
      return {find(V), true};
    }
    auto R = C->S.insert(V);
    if (R.second)
      C->H.arm(K, C.get());
    return {const_iterator(R.first, C->S.end(), C.get()), R.second};
  }
  template <typename It> void insert(It B, It E) {
    for (; B != E; ++B)
      insert(*B);
  }

  std::size_t count(KeyArg V) const {
    if (C->dead(asValue(V)))
      return 0;
    return C->S.count(toStore(V)) ? 1 : 0;
  }
  bool contains(KeyArg V) const { return count(V) != 0; }
  const_iterator find(KeyArg V) const {
    if (C->dead(asValue(V)))
      return end();
    return const_iterator(C->S.find(toStore(V)), C->S.end(), C.get());
  }

  std::size_t erase(KeyArg V) {
    const llvm::Value *K = asValue(V);
    bool WasDead = C->dead(K);
    bool Had = C->S.erase(toStore(V)) != 0;
    C->Dead.erase(K);
    C->H.disarm(K);
    return (Had && !WasDead) ? 1 : 0;
  }

  bool empty() const { return C->S.size() == C->Dead.size(); }
  std::size_t size() const { return C->S.size() - C->Dead.size(); }
  void clear() {
    C->H.clear();
    C->Dead.clear();
    C->S.clear();
  }

  template <typename Pred> bool remove_if(Pred P) {
    llvm::SmallVector<PtrT, 8> Doomed;
    for (PtrT V : *this)
      if (P(V))
        Doomed.push_back(V);
    for (PtrT V : Doomed)
      erase(V);
    return !Doomed.empty();
  }
};

// ---------------------------------------------------------------------------
// A MAP keyed by Value-derived pointers over an unchanged `DenseMap`.
// ---------------------------------------------------------------------------
template <typename KeyT, typename ValT> class Map {
  static_assert(std::is_pointer<KeyT>::value, "a Map is keyed by pointers");
  using StorageT = llvm::DenseMap<KeyT, ValT>;
  using Pointee = std::remove_pointer_t<KeyT>;
  using KeyArg = const std::remove_const_t<Pointee> *;

  struct Core final : Owner {
    StorageT S;
    llvm::DenseSet<const llvm::Value *> Dead;
    HookTable H;
    void keyDeleted(const llvm::Value *V) override {
      if (S.count(toStore(static_cast<KeyArg>(V))))
        Dead.insert(V);
    }
    bool dead(const llvm::Value *V) const { return !Dead.empty() && Dead.count(V); }
  };
  std::unique_ptr<Core> C;

  static KeyT toStore(KeyArg V) { return const_cast<KeyT>(V); }

  template <typename BaseIt, typename CoreP> class iter_impl {
    BaseIt I, E;
    CoreP Co = nullptr;
    void skip() {
      if (Co->Dead.empty())
        return;
      while (I != E && Co->Dead.count(asValue(I->first)))
        ++I;
    }

  public:
    using iterator_category = std::forward_iterator_tag;
    using value_type = typename std::iterator_traits<BaseIt>::value_type;
    using difference_type = std::ptrdiff_t;
    using pointer = typename std::iterator_traits<BaseIt>::pointer;
    using reference = typename std::iterator_traits<BaseIt>::reference;
    iter_impl(BaseIt I, BaseIt E, CoreP Co) : I(I), E(E), Co(Co) { skip(); }
    reference operator*() const { return *I; }
    pointer operator->() const { return &*I; }
    iter_impl &operator++() {
      ++I;
      skip();
      return *this;
    }
    iter_impl operator++(int) {
      iter_impl T = *this;
      ++*this;
      return T;
    }
    bool operator==(const iter_impl &O) const { return I == O.I; }
    bool operator!=(const iter_impl &O) const { return I != O.I; }
    BaseIt base() const { return I; }
  };

public:
  using iterator = iter_impl<typename StorageT::iterator, Core *>;
  using const_iterator = iter_impl<typename StorageT::const_iterator, const Core *>;

  Map() : C(std::make_unique<Core>()) {}
  Map(const Map &O) : Map() {
    for (const auto &KV : O)
      insert({KV.first, KV.second});
  }
  Map(Map &&O) : C(std::move(O.C)) { O.C = std::make_unique<Core>(); }
  Map &operator=(const Map &O) {
    if (this != &O) {
      Map T(O);
      std::swap(C, T.C);
    }
    return *this;
  }
  Map &operator=(Map &&O) {
    if (this != &O) {
      C = std::move(O.C);
      O.C = std::make_unique<Core>();
    }
    return *this;
  }

  iterator begin() { return iterator(C->S.begin(), C->S.end(), C.get()); }
  iterator end() { return iterator(C->S.end(), C->S.end(), C.get()); }
  const_iterator begin() const {
    return const_iterator(C->S.begin(), C->S.end(), C.get());
  }
  const_iterator end() const { return const_iterator(C->S.end(), C->S.end(), C.get()); }

  // A dead key's address is logically ABSENT: its stale mapped value is reset
  // before a fresh object at that address is handed a reference to it.
  ValT &operator[](KeyT K) {
    const llvm::Value *KV = asValue(K);
    if (C->dead(KV)) {
      C->Dead.erase(KV);
      C->H.arm(KV, C.get());
      ValT &Slot = C->S[K];
      Slot = ValT();
      return Slot;
    }
    auto R = C->S.try_emplace(K);
    if (R.second)
      C->H.arm(KV, C.get());
    return R.first->second;
  }
  std::pair<iterator, bool> insert(const std::pair<KeyT, ValT> &KV) {
    const llvm::Value *K = asValue(KV.first);
    if (C->dead(K)) {
      C->Dead.erase(K);
      C->H.arm(K, C.get());
      auto It = C->S.find(KV.first);
      It->second = KV.second;
      return {iterator(It, C->S.end(), C.get()), true};
    }
    auto R = C->S.insert(KV);
    if (R.second)
      C->H.arm(K, C.get());
    return {iterator(R.first, C->S.end(), C.get()), R.second};
  }
  template <typename... Ts> std::pair<iterator, bool> try_emplace(KeyT K, Ts &&...Args) {
    const llvm::Value *KV = asValue(K);
    if (C->dead(KV)) {
      C->Dead.erase(KV);
      C->H.arm(KV, C.get());
      auto It = C->S.find(K);
      It->second = ValT(std::forward<Ts>(Args)...);
      return {iterator(It, C->S.end(), C.get()), true};
    }
    auto R = C->S.try_emplace(K, std::forward<Ts>(Args)...);
    if (R.second)
      C->H.arm(KV, C.get());
    return {iterator(R.first, C->S.end(), C.get()), R.second};
  }

  std::size_t count(KeyArg K) const {
    if (C->dead(asValue(K)))
      return 0;
    return C->S.count(toStore(K)) ? 1 : 0;
  }
  bool contains(KeyArg K) const { return count(K) != 0; }
  iterator find(KeyArg K) {
    if (C->dead(asValue(K)))
      return end();
    return iterator(C->S.find(toStore(K)), C->S.end(), C.get());
  }
  const_iterator find(KeyArg K) const {
    if (C->dead(asValue(K)))
      return end();
    return const_iterator(C->S.find(toStore(K)), C->S.end(), C.get());
  }
  ValT lookup(KeyArg K) const {
    if (C->dead(asValue(K)))
      return ValT();
    return C->S.lookup(toStore(K));
  }

  bool erase(KeyArg K) {
    const llvm::Value *KV = asValue(K);
    bool WasDead = C->dead(KV);
    bool Had = C->S.erase(toStore(K));
    C->Dead.erase(KV);
    C->H.disarm(KV);
    return Had && !WasDead;
  }
  void erase(iterator It) { erase(It->first); }

  bool empty() const { return C->S.size() == C->Dead.size(); }
  std::size_t size() const { return C->S.size() - C->Dead.size(); }
  void clear() {
    C->H.clear();
    C->Dead.clear();
    C->S.clear();
  }
};

// ---------------------------------------------------------------------------
// An ordered LIST of call sites (`SmallVector<CallInst *, N>`). A deleted call's
// SLOTS are nulled — never removed, so an iteration in progress is not shifted —
// and iteration skips null slots.
// ---------------------------------------------------------------------------
template <typename PtrT, unsigned N> class List {
  static_assert(std::is_pointer<PtrT>::value, "a List holds pointers");
  using StorageT = llvm::SmallVector<PtrT, N>;

  struct Core final : Owner {
    StorageT S;
    HookTable H;
    void keyDeleted(const llvm::Value *V) override {
      for (PtrT &Slot : S)
        if (Slot && asValue(Slot) == V)
          Slot = nullptr;
    }
  };
  std::unique_ptr<Core> C;

public:
  class const_iterator {
    const PtrT *I = nullptr, *E = nullptr;
    void skip() {
      while (I != E && !*I)
        ++I;
    }
    friend class List;

  public:
    using iterator_category = std::forward_iterator_tag;
    using value_type = PtrT;
    using difference_type = std::ptrdiff_t;
    using pointer = const PtrT *;
    using reference = PtrT;
    const_iterator(const PtrT *I, const PtrT *E) : I(I), E(E) { skip(); }
    PtrT operator*() const { return *I; }
    const_iterator &operator++() {
      ++I;
      skip();
      return *this;
    }
    const_iterator operator++(int) {
      const_iterator T = *this;
      ++*this;
      return T;
    }
    bool operator==(const const_iterator &O) const { return I == O.I; }
    bool operator!=(const const_iterator &O) const { return I != O.I; }
  };
  using iterator = const_iterator;
  using value_type = PtrT;

  List() : C(std::make_unique<Core>()) {}
  List(const List &O) : List() {
    for (PtrT V : O)
      push_back(V);
  }
  List(List &&O) : C(std::move(O.C)) { O.C = std::make_unique<Core>(); }
  List &operator=(const List &O) {
    if (this != &O) {
      List T(O);
      std::swap(C, T.C);
    }
    return *this;
  }
  List &operator=(List &&O) {
    if (this != &O) {
      C = std::move(O.C);
      O.C = std::make_unique<Core>();
    }
    return *this;
  }

  const_iterator begin() const {
    return const_iterator(C->S.begin(), C->S.end());
  }
  const_iterator end() const { return const_iterator(C->S.end(), C->S.end()); }

  void push_back(PtrT V) {
    C->S.push_back(V);
    C->H.arm(asValue(V), C.get());
  }
  // Insert BEFORE the live element `Pos` names (at the end if `Pos == end()`).
  void insert(const_iterator Pos, PtrT V) {
    std::size_t Idx = static_cast<std::size_t>(Pos.I - C->S.begin());
    C->S.insert(C->S.begin() + Idx, V);
    C->H.arm(asValue(V), C.get());
  }
  // ⚠ NOT `llvm::is_contained(*this, V)`: LLVM 19's `is_contained` forwards to
  // a member `contains()` when one exists, i.e. back here — unbounded recursion
  // (measured: a stack overflow, SIGILL, on four shipped fixtures).
  bool contains(const std::remove_pointer_t<PtrT> *V) const {
    return V && std::find(begin(), end(), V) != end();
  }
  // Physically remove every slot naming `V` (the explicit scrub spelling).
  void erase_value(const std::remove_pointer_t<PtrT> *V) {
    C->S.erase(std::remove(C->S.begin(), C->S.end(), V), C->S.end());
  }
  template <typename Pred> void remove_if(Pred P) {
    C->S.erase(std::remove_if(C->S.begin(), C->S.end(),
                              [&P](PtrT V) { return V && P(V); }),
               C->S.end());
  }
  bool empty() const { return begin() == end(); }
  std::size_t size() const { return std::distance(begin(), end()); }
  void clear() {
    C->H.clear();
    C->S.clear();
  }
};

// ---------------------------------------------------------------------------
// A SET of (Value, BasicBlock) pairs (`TaintSet::ClaimedRailRoots`): a pair is
// dropped when EITHER component is deleted. Membership-only by design — it has
// no iterator, so a physical removal cannot perturb an iteration order.
// ---------------------------------------------------------------------------
template <typename AT, typename BT> class PairSet {
  using PairT = std::pair<AT, BT>;
  struct Core final : Owner {
    llvm::DenseSet<PairT> S;
    HookTable H;
    void keyDeleted(const llvm::Value *V) override {
      llvm::SmallVector<PairT, 4> Doomed;
      for (const PairT &P : S)
        if (asValue(P.first) == V || asValue(P.second) == V)
          Doomed.push_back(P);
      for (const PairT &P : Doomed)
        S.erase(P);
    }
  };
  std::unique_ptr<Core> C;

public:
  PairSet() : C(std::make_unique<Core>()) {}
  PairSet(PairSet &&O) : C(std::move(O.C)) { O.C = std::make_unique<Core>(); }
  PairSet &operator=(PairSet &&O) {
    if (this != &O) {
      C = std::move(O.C);
      O.C = std::make_unique<Core>();
    }
    return *this;
  }
  PairSet(const PairSet &O) : PairSet() {
    for (const PairT &P : O.C->S)
      insert(P);
  }
  PairSet &operator=(const PairSet &O) {
    if (this != &O) {
      PairSet T(O);
      std::swap(C, T.C);
    }
    return *this;
  }
  bool insert(const PairT &P) {
    bool Ins = C->S.insert(P).second;
    C->H.arm(asValue(P.first), C.get());
    C->H.arm(asValue(P.second), C.get());
    return Ins;
  }
  std::size_t count(const PairT &P) const { return C->S.count(P); }
  bool contains(const PairT &P) const { return C->S.contains(P); }
  bool erase(const PairT &P) { return C->S.erase(P); }
  bool empty() const { return C->S.empty(); }
  std::size_t size() const { return C->S.size(); }
  void clear() {
    C->H.clear();
    C->S.clear();
  }
};

}  // namespace scrub

// The spellings `TaintSet` uses (bd test_C_libtooling-8e5r / -j8sk).
using TaintedValueSet = scrub::Set<std::set<llvm::Value *>, llvm::Value *>;
template <typename PtrT, unsigned N>
using ScrubPtrSet = scrub::Set<llvm::SmallPtrSet<PtrT, N>, PtrT>;
template <typename KeyT, typename ValT> using ScrubMap = scrub::Map<KeyT, ValT>;
template <typename PtrT, unsigned N> using ScrubCallList = scrub::List<PtrT, N>;
// `TaintSet::SpineOps`, named because `EmitInverse`/`BreakReversePlay` take it
// by pointer.
using SpineOpSet = ScrubPtrSet<const llvm::CallInst *, 16>;

}  // namespace cq

#endif  // CQ_IRPASS_SCRUB_ON_DELETE_H_
