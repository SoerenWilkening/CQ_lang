// rb8_interpose.cpp — review r1B_8e5r's INDEPENDENT allocator instrument.
// Written from scratch (not derived from ir-pass/tools/cq_debug_alloc.cpp), and
// applied by DYLD_INSERT_LIBRARIES + __interpose to ANY unmodified binary — the
// frozen oracle included — so a finding does not depend on the subject's own
// test driver. RB8_ALLOC=
//   lifo    freed block -> next same-class request (stack)       [policy of cq_debug_alloc]
//   fifo    freed block -> next same-class request, OLDEST first  (maximal reuse, other pairing)
//   lifo2   like lifo but hands out the SECOND most recent block when >=2 pooled
//   nofree  never free
//   rand    malloc(n + 16*r), r uniform in [0,8) from a per-process seed (RB8_SEED or pid^time):
//           system reuse, SCRAMBLED relative address order (attacks address-ordered iteration)
//   (unset) pass-through
// RB8_STATS=1 prints counters to stderr at exit.
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <new>
#include <malloc/malloc.h>
#include <unistd.h>
#include <ctime>

namespace {
enum { M_UNSET=-1, M_SYS=0, M_LIFO, M_FIFO, M_LIFO2, M_NOFREE, M_RAND };
unsigned long long Rng = 0;
int Mode = M_UNSET;
constexpr size_t Q = 16, MAXP = 4096, NC = MAXP / Q + 1;
// intrusive singly-linked stack per class; FIFO keeps a tail pointer too.
void *Head[NC], *Tail[NC];
unsigned long NNew, NDel, NReuse;
int mode() {
  if (Mode == M_UNSET) {
    const char *E = getenv("RB8_ALLOC");
    Mode = M_SYS;
    if (E) {
      if (!strcmp(E, "lifo")) Mode = M_LIFO;
      else if (!strcmp(E, "fifo")) Mode = M_FIFO;
      else if (!strcmp(E, "lifo2")) Mode = M_LIFO2;
      else if (!strcmp(E, "nofree")) Mode = M_NOFREE;
      else if (!strcmp(E, "rand")) { Mode = M_RAND; const char *Sd = getenv("RB8_SEED"); Rng = Sd ? strtoull(Sd, nullptr, 10) : ((unsigned long long)getpid() << 20) ^ (unsigned long long)time(nullptr); Rng |= 1; }
    }
  }
  return Mode;
}
inline void *&nx(void *B) { return *static_cast<void **>(B); }
void *take(size_t c) {
  void *B = Head[c];
  if (!B) return nullptr;
  if (Mode == M_LIFO2 && nx(B)) {  // second most recent
    void *B2 = nx(B);
    nx(B) = nx(B2);
    return B2;
  }
  Head[c] = nx(B);
  if (!Head[c]) Tail[c] = nullptr;
  return B;
}
void put(size_t c, void *B) {
  if (Mode == M_FIFO) {  // append at tail, take from head
    nx(B) = nullptr;
    if (Tail[c]) nx(Tail[c]) = B; else Head[c] = B;
    Tail[c] = B;
  } else {
    nx(B) = Head[c];
    Head[c] = B;
    if (!Tail[c]) Tail[c] = B;
  }
}
void *rbNew(size_t N) {
  if (!N) N = 1;
  ++NNew;
  int m = mode();
  if (m == M_LIFO || m == M_FIFO || m == M_LIFO2) {
    size_t G = malloc_good_size(N);
    if (G <= MAXP && G % Q == 0)
      if (void *B = take(G / Q)) { ++NReuse; return B; }
  }
  if (m == M_RAND) { Rng ^= Rng << 13; Rng ^= Rng >> 7; Rng ^= Rng << 17; N += 16 * (Rng % 8); }
  void *P = malloc(N);
  if (!P) abort();
  return P;
}
void rbDel(void *P) {
  if (!P) return;
  ++NDel;
  int m = mode();
  if (m == M_NOFREE) return;
  if (m == M_LIFO || m == M_FIFO || m == M_LIFO2) {
    size_t G = malloc_size(P);
    if (G <= MAXP && G % Q == 0 && G >= sizeof(void *)) { put(G / Q, P); return; }
  }
  free(P);
}
struct Stats { ~Stats() {
  if (getenv("RB8_STATS"))
    fprintf(stderr, "rb8_interpose: mode=%d new=%lu del=%lu reuse=%lu\n", Mode, NNew, NDel, NReuse);
} } TheStats;
}  // namespace

void *rb_new(size_t n) { return rbNew(n); }
void *rb_new_nt(size_t n, const std::nothrow_t &) noexcept { return rbNew(n); }
void rb_del(void *p) noexcept { rbDel(p); }
void rb_del_sz(void *p, size_t) noexcept { rbDel(p); }
void rb_del_nt(void *p, const std::nothrow_t &) noexcept { rbDel(p); }

#define INTERPOSE(repl, orig) \
  __attribute__((used)) static struct { const void *r; const void *o; } \
  _interpose_##repl##_##__LINE__ __attribute__((section("__DATA,__interpose"))) = { (const void *)&repl, (const void *)&orig };

void *operator_new_ref(size_t) asm("__Znwm");
void *operator_newa_ref(size_t) asm("__Znam");
void *operator_new_nt_ref(size_t, const std::nothrow_t &) asm("__ZnwmRKSt9nothrow_t");
void *operator_newa_nt_ref(size_t, const std::nothrow_t &) asm("__ZnamRKSt9nothrow_t");
void operator_del_ref(void *) asm("__ZdlPv");
void operator_dela_ref(void *) asm("__ZdaPv");
void operator_del_sz_ref(void *, size_t) asm("__ZdlPvm");
void operator_dela_sz_ref(void *, size_t) asm("__ZdaPvm");
void operator_del_nt_ref(void *, const std::nothrow_t &) asm("__ZdlPvRKSt9nothrow_t");
void operator_dela_nt_ref(void *, const std::nothrow_t &) asm("__ZdaPvRKSt9nothrow_t");

__attribute__((used)) static const struct { const void *r, *o; } interposers[] __attribute__((section("__DATA,__interpose"))) = {
  {(const void *)&rb_new, (const void *)&operator_new_ref},
  {(const void *)&rb_new, (const void *)&operator_newa_ref},
  {(const void *)&rb_new_nt, (const void *)&operator_new_nt_ref},
  {(const void *)&rb_new_nt, (const void *)&operator_newa_nt_ref},
  {(const void *)&rb_del, (const void *)&operator_del_ref},
  {(const void *)&rb_del, (const void *)&operator_dela_ref},
  {(const void *)&rb_del_sz, (const void *)&operator_del_sz_ref},
  {(const void *)&rb_del_sz, (const void *)&operator_dela_sz_ref},
  {(const void *)&rb_del_nt, (const void *)&operator_del_nt_ref},
  {(const void *)&rb_del_nt, (const void *)&operator_dela_nt_ref},
};
