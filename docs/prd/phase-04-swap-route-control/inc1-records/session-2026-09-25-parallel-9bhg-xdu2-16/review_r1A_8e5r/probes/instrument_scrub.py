#!/usr/bin/env python3
"""Instrument ScrubOnDelete.h (REVIEW-ONLY, private worktree): log every query/iteration/
size/copy whose answer differs from the pre-8e5r raw container, with the CALL SITE.
Under CQ_OPT_DEBUG_ALLOC=nofree no address is reused, so every logged event is a DEAD
POINTER being asked about / yielded / counted -- exactly the set of behaviour changes
beyond the aliasing fix. Log goes to $CQ_SCRUB_LOG (append); nothing to stdout/stderr."""
import re, sys
p = sys.argv[1]
s = open(p).read()
def sub(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        raise SystemExit(f"anchor count {n} != {count}: {old[:70]!r}")
    s = s.replace(old, new)

sub('#include <utility>\n', '''#include <utility>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <mach-o/dyld.h>
''')
sub('namespace scrub {\n\n', '''namespace scrub {

inline std::FILE *reviewLogF() {
  static std::FILE *F = []() -> std::FILE * {
    const char *P = std::getenv("CQ_SCRUB_LOG");
    return P ? std::fopen(P, "a") : nullptr;
  }();
  return F;
}
__attribute__((noinline)) inline void slog(const char *Kind, const char *File, unsigned Line,
                                           const void *RA) {
  std::FILE *F = reviewLogF();
  if (!F)
    return;
  unsigned long Off = (unsigned long)((uintptr_t)RA - (uintptr_t)_dyld_get_image_vmaddr_slide(0));
  std::fprintf(F, "%s %s:%u ra=0x%lx\\n", Kind, File ? File : "?", Line, Off);
  std::fflush(F);
}
#define CQLOC const char *LF = __builtin_FILE(), unsigned LL = __builtin_LINE()
#define CQRA __builtin_return_address(0)
''')

# ---------------- Set ----------------
sub('''    BaseIt I, E;
    const Core *Co = nullptr;
    void skip() {
      if (Co->Dead.empty())
        return;
      while (I != E && Co->Dead.count(asValue(*I)))
        ++I;
    }
''', '''    BaseIt I, E;
    const Core *Co = nullptr;
    const char *LF = nullptr;
    unsigned LL = 0;
    void skip() {
      if (Co->Dead.empty())
        return;
      while (I != E && Co->Dead.count(asValue(*I))) {
        if (LF)
          slog("DEADITER-SET", LF, LL, nullptr);
        ++I;
      }
    }
''')
sub('''    const_iterator(BaseIt I, BaseIt E, const Core *Co) : I(I), E(E), Co(Co) { skip(); }
    PtrT operator*() const { return *I; }''', '''    const_iterator(BaseIt I, BaseIt E, const Core *Co, const char *LF = nullptr,
                   unsigned LL = 0)
        : I(I), E(E), Co(Co), LF(LF), LL(LL) { skip(); }
    PtrT operator*() const { return *I; }''')
sub('''  Set(const Set &O) : Set() { insert(O.begin(), O.end()); }''',
    '''  __attribute__((noinline)) Set(const Set &O) : Set() {
    if (!O.C->Dead.empty())
      slog("DEADCOPY-SET", nullptr, 0, CQRA);
    insert(O.begin(nullptr, 0), O.end());
  }''')
sub('''  const_iterator begin() const { return const_iterator(C->S.begin(), C->S.end(), C.get()); }
  const_iterator end() const { return const_iterator(C->S.end(), C->S.end(), C.get()); }

  std::pair<const_iterator, bool> insert(PtrT V) {
    const llvm::Value *K = asValue(V);
    if (C->dead(K)) {''', '''  const_iterator begin(CQLOC) const {
    return const_iterator(C->S.begin(), C->S.end(), C.get(), LF, LL);
  }
  const_iterator end() const { return const_iterator(C->S.end(), C->S.end(), C.get()); }

  std::pair<const_iterator, bool> insert(PtrT V, CQLOC) {
    const llvm::Value *K = asValue(V);
    if (C->dead(K)) {
      slog("DEADINS-SET", LF, LL, nullptr);''')
sub('''    for (; B != E; ++B)
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
    bool WasDead = C->dead(K);''', '''    for (; B != E; ++B)
      insert(*B, nullptr, 0);
  }

  std::size_t count(KeyArg V, CQLOC) const {
    if (C->dead(asValue(V))) {
      if (LF)
        slog("DEADQ-SET-count", LF, LL, nullptr);
      return 0;
    }
    return C->S.count(toStore(V)) ? 1 : 0;
  }
  bool contains(KeyArg V, CQLOC) const { return count(V, LF, LL) != 0; }
  const_iterator find(KeyArg V, CQLOC) const {
    if (C->dead(asValue(V))) {
      slog("DEADQ-SET-find", LF, LL, nullptr);
      return end();
    }
    return const_iterator(C->S.find(toStore(V)), C->S.end(), C.get());
  }

  std::size_t erase(KeyArg V, CQLOC) {
    const llvm::Value *K = asValue(V);
    bool WasDead = C->dead(K);
    if (WasDead)
      slog("DEADERASE-SET", LF, LL, nullptr);''')
sub('''  bool empty() const { return C->S.size() == C->Dead.size(); }
  std::size_t size() const { return C->S.size() - C->Dead.size(); }
  void clear() {
    C->H.clear();
    C->Dead.clear();
    C->S.clear();
  }

  template <typename Pred> bool remove_if(Pred P) {
    llvm::SmallVector<PtrT, 8> Doomed;
    for (PtrT V : *this)''', '''  bool empty(CQLOC) const {
    if (!C->Dead.empty() && C->S.size() == C->Dead.size())
      slog("DEADEMPTY-FLIP-SET", LF, LL, nullptr);
    return C->S.size() == C->Dead.size();
  }
  std::size_t size(CQLOC) const {
    if (!C->Dead.empty())
      slog("DEADSIZE-SET", LF, LL, nullptr);
    return C->S.size() - C->Dead.size();
  }
  void clear() {
    C->H.clear();
    C->Dead.clear();
    C->S.clear();
  }

  template <typename Pred> bool remove_if(Pred P) {
    llvm::SmallVector<PtrT, 8> Doomed;
    for (auto It = begin(nullptr, 0), E = end(); It != E; ++It)
      if (P(*It))
        Doomed.push_back(*It);
    for (PtrT V : Doomed)
      erase(V, nullptr, 0);
    return !Doomed.empty();
  }
  template <typename Pred> bool remove_if_UNUSED(Pred P) {
    llvm::SmallVector<PtrT, 8> Doomed;
    for (PtrT V : *this)''')

# ---------------- Map ----------------
sub('''    BaseIt I, E;
    CoreP Co = nullptr;
    void skip() {
      if (Co->Dead.empty())
        return;
      while (I != E && Co->Dead.count(asValue(I->first)))
        ++I;
    }
''', '''    BaseIt I, E;
    CoreP Co = nullptr;
    const char *LF = nullptr;
    unsigned LL = 0;
    void skip() {
      if (Co->Dead.empty())
        return;
      while (I != E && Co->Dead.count(asValue(I->first))) {
        if (LF)
          slog("DEADITER-MAP", LF, LL, nullptr);
        ++I;
      }
    }
''')
sub('''    iter_impl(BaseIt I, BaseIt E, CoreP Co) : I(I), E(E), Co(Co) { skip(); }''',
    '''    iter_impl(BaseIt I, BaseIt E, CoreP Co, const char *LF = nullptr, unsigned LL = 0)
        : I(I), E(E), Co(Co), LF(LF), LL(LL) { skip(); }''')
sub('''  Map(const Map &O) : Map() {
    for (const auto &KV : O)
      insert({KV.first, KV.second});
  }''', '''  __attribute__((noinline)) Map(const Map &O) : Map() {
    if (!O.C->Dead.empty())
      slog("DEADCOPY-MAP", nullptr, 0, CQRA);
    for (auto It = O.begin(nullptr, 0), E = O.end(); It != E; ++It)
      insert({It->first, It->second}, nullptr, 0);
  }''')
sub('''  iterator begin() { return iterator(C->S.begin(), C->S.end(), C.get()); }
  iterator end() { return iterator(C->S.end(), C->S.end(), C.get()); }
  const_iterator begin() const {
    return const_iterator(C->S.begin(), C->S.end(), C.get());
  }''', '''  iterator begin(CQLOC) { return iterator(C->S.begin(), C->S.end(), C.get(), LF, LL); }
  iterator end() { return iterator(C->S.end(), C->S.end(), C.get()); }
  const_iterator begin(CQLOC) const {
    return const_iterator(C->S.begin(), C->S.end(), C.get(), LF, LL);
  }''')
sub('''  ValT &operator[](KeyT K) {
    const llvm::Value *KV = asValue(K);
    if (C->dead(KV)) {''', '''  __attribute__((noinline)) ValT &operator[](KeyT K) {
    const llvm::Value *KV = asValue(K);
    if (C->dead(KV)) {
      slog("DEADINS-MAP-subscript", nullptr, 0, CQRA);''')
sub('''  std::pair<iterator, bool> insert(const std::pair<KeyT, ValT> &KV) {
    const llvm::Value *K = asValue(KV.first);
    if (C->dead(K)) {''', '''  std::pair<iterator, bool> insert(const std::pair<KeyT, ValT> &KV, CQLOC) {
    const llvm::Value *K = asValue(KV.first);
    if (C->dead(K)) {
      if (LF)
        slog("DEADINS-MAP-insert", LF, LL, nullptr);''')
sub('''    const llvm::Value *KV = asValue(K);
    if (C->dead(KV)) {
      C->Dead.erase(KV);
      C->H.arm(KV, C.get());
      auto It = C->S.find(K);
      It->second = ValT(std::forward<Ts>(Args)...);''', '''    const llvm::Value *KV = asValue(K);
    if (C->dead(KV)) {
      slog("DEADINS-MAP-try_emplace", nullptr, 0, CQRA);
      C->Dead.erase(KV);
      C->H.arm(KV, C.get());
      auto It = C->S.find(K);
      It->second = ValT(std::forward<Ts>(Args)...);''')
sub('''  std::size_t count(KeyArg K) const {
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
    bool WasDead = C->dead(KV);''', '''  std::size_t count(KeyArg K, CQLOC) const {
    if (C->dead(asValue(K))) {
      if (LF)
        slog("DEADQ-MAP-count", LF, LL, nullptr);
      return 0;
    }
    return C->S.count(toStore(K)) ? 1 : 0;
  }
  bool contains(KeyArg K, CQLOC) const { return count(K, LF, LL) != 0; }
  iterator find(KeyArg K, CQLOC) {
    if (C->dead(asValue(K))) {
      slog("DEADQ-MAP-find", LF, LL, nullptr);
      return end();
    }
    return iterator(C->S.find(toStore(K)), C->S.end(), C.get());
  }
  const_iterator find(KeyArg K, CQLOC) const {
    if (C->dead(asValue(K))) {
      slog("DEADQ-MAP-cfind", LF, LL, nullptr);
      return end();
    }
    return const_iterator(C->S.find(toStore(K)), C->S.end(), C.get());
  }
  ValT lookup(KeyArg K, CQLOC) const {
    if (C->dead(asValue(K))) {
      slog("DEADQ-MAP-lookup", LF, LL, nullptr);
      return ValT();
    }
    return C->S.lookup(toStore(K));
  }

  bool erase(KeyArg K, CQLOC) {
    const llvm::Value *KV = asValue(K);
    bool WasDead = C->dead(KV);
    if (WasDead && LF)
      slog("DEADERASE-MAP", LF, LL, nullptr);''')
sub('''  void erase(iterator It) { erase(It->first); }

  bool empty() const { return C->S.size() == C->Dead.size(); }
  std::size_t size() const { return C->S.size() - C->Dead.size(); }''',
    '''  void erase(iterator It) { erase(It->first, nullptr, 0); }

  bool empty(CQLOC) const {
    if (!C->Dead.empty() && C->S.size() == C->Dead.size())
      slog("DEADEMPTY-FLIP-MAP", LF, LL, nullptr);
    return C->S.size() == C->Dead.size();
  }
  std::size_t size(CQLOC) const {
    if (!C->Dead.empty())
      slog("DEADSIZE-MAP", LF, LL, nullptr);
    return C->S.size() - C->Dead.size();
  }''')

# ---------------- List ----------------
sub('''  struct Core final : Owner {
    StorageT S;
    HookTable H;
    void keyDeleted(const llvm::Value *V) override {
      for (PtrT &Slot : S)
        if (Slot && asValue(Slot) == V)
          Slot = nullptr;
    }
  };''', '''  struct Core final : Owner {
    StorageT S;
    HookTable H;
    llvm::DenseSet<const llvm::Value *> DeadAddrs;  // REVIEW LOGGING ONLY
    void keyDeleted(const llvm::Value *V) override {
      for (PtrT &Slot : S)
        if (Slot && asValue(Slot) == V) {
          Slot = nullptr;
          DeadAddrs.insert(V);
        }
    }
  };''')
sub('''    const PtrT *I = nullptr, *E = nullptr;
    void skip() {
      while (I != E && !*I)
        ++I;
    }''', '''    const PtrT *I = nullptr, *E = nullptr;
    const char *LF = nullptr;
    unsigned LL = 0;
    void skip() {
      while (I != E && !*I) {
        if (LF)
          slog("DEADITER-LIST", LF, LL, nullptr);
        ++I;
      }
    }''')
sub('''    const_iterator(const PtrT *I, const PtrT *E) : I(I), E(E) { skip(); }''',
    '''    const_iterator(const PtrT *I, const PtrT *E, const char *LF = nullptr, unsigned LL = 0)
        : I(I), E(E), LF(LF), LL(LL) { skip(); }''')
sub('''  List(const List &O) : List() {
    for (PtrT V : O)
      push_back(V);
  }''', '''  __attribute__((noinline)) List(const List &O) : List() {
    for (auto It = O.begin(nullptr, 0), E = O.end(); It != E; ++It)
      push_back(*It);
  }''')
sub('''  const_iterator begin() const {
    return const_iterator(C->S.begin(), C->S.end());
  }''', '''  const_iterator begin(CQLOC) const {
    return const_iterator(C->S.begin(), C->S.end(), LF, LL);
  }''')
sub('''  bool contains(const std::remove_pointer_t<PtrT> *V) const {
    return V && std::find(begin(), end(), V) != end();
  }
  // Physically remove every slot naming `V` (the explicit scrub spelling).
  void erase_value(const std::remove_pointer_t<PtrT> *V) {
    C->S.erase(std::remove(C->S.begin(), C->S.end(), V), C->S.end());
  }''', '''  bool contains(const std::remove_pointer_t<PtrT> *V, CQLOC) const {
    bool R = V && std::find(begin(nullptr, 0), end(), V) != end();
    if (!R && V && C->DeadAddrs.count(asValue(V)))
      slog("DEADQ-LIST-contains", LF, LL, CQRA);
    return R;
  }
  // Physically remove every slot naming `V` (the explicit scrub spelling).
  void erase_value(const std::remove_pointer_t<PtrT> *V, CQLOC) {
    if (V && C->DeadAddrs.count(asValue(V)) && std::find(C->S.begin(), C->S.end(), V) == C->S.end())
      slog("DEADERASE-LIST", LF, LL, nullptr);
    C->S.erase(std::remove(C->S.begin(), C->S.end(), V), C->S.end());
  }''')
sub('''  bool empty() const { return begin() == end(); }
  std::size_t size() const { return std::distance(begin(), end()); }
  void clear() {
    C->H.clear();
    C->S.clear();
  }
};''', '''  bool empty(CQLOC) const {
    bool R = begin(nullptr, 0) == end();
    if (R && !C->S.empty())
      slog("DEADEMPTY-FLIP-LIST", LF, LL, nullptr);
    return R;
  }
  std::size_t size(CQLOC) const {
    std::size_t Cnt = std::distance(begin(nullptr, 0), end());
    if (Cnt != C->S.size())
      slog("DEADSIZE-LIST", LF, LL, nullptr);
    return Cnt;
  }
  void clear() {
    C->H.clear();
    C->S.clear();
  }
};''')

# ---------------- PairSet ----------------
sub('''  struct Core final : Owner {
    llvm::DenseSet<PairT> S;
    HookTable H;
    void keyDeleted(const llvm::Value *V) override {
      llvm::SmallVector<PairT, 4> Doomed;''', '''  struct Core final : Owner {
    llvm::DenseSet<PairT> S;
    HookTable H;
    llvm::DenseSet<const llvm::Value *> DeadAddrs;  // REVIEW LOGGING ONLY
    void keyDeleted(const llvm::Value *V) override {
      DeadAddrs.insert(V);
      llvm::SmallVector<PairT, 4> Doomed;''')
sub('''  std::size_t count(const PairT &P) const { return C->S.count(P); }
  bool contains(const PairT &P) const { return C->S.contains(P); }''',
    '''  std::size_t count(const PairT &P, CQLOC) const {
    std::size_t N = C->S.count(P);
    if (!N && (C->DeadAddrs.count(asValue(P.first)) || C->DeadAddrs.count(asValue(P.second))))
      slog("DEADQ-PAIR-count", LF, LL, nullptr);
    return N;
  }
  bool contains(const PairT &P, CQLOC) const { return count(P, LF, LL) != 0; }''')
open(p, 'w').write(s)
print("instrumented", p)
