// Module pred (cq-w0-pred), private. See Bdd.h.
#include "Bdd.h"

#include <algorithm>
#include <string>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"

namespace cq::pred_detail {

Bdd &Bdd::get() {
  static Bdd mgr;
  return mgr;
}

Bdd::Bdd() {
  nodes.push_back({NoVar, F, F});   // false
  nodes.push_back({NoVar, T, T});   // true
}

void Bdd::append(unsigned v) {
  if (v >= lvl.size())
    lvl.resize(v + 1, NoVar);
  for (unsigned u = 0; u <= v; ++u)
    if (lvl[u] == NoVar) {
      lvl[u] = unsigned(order.size());
      order.push_back(u);
    }
}

void Bdd::placeAfter(unsigned v, unsigned after) {
  place(after);
  if (v < lvl.size() && lvl[v] != NoVar)
    return;   // ordered already (used before it was placed)
  if (v >= lvl.size())
    lvl.resize(v + 1, NoVar);
  for (unsigned u = 0; u < v; ++u)
    place(u);
  unsigned at = lvl[after] + 1;
  order.insert(order.begin() + at, v);
  for (unsigned i = at; i < order.size(); ++i)
    lvl[order[i]] = i;
}

unsigned Bdd::mk(unsigned v, unsigned l, unsigned h) {
  if (l == h)
    return l;
  place(v);
  Key3 k{v, l, h};
  auto it = unique.find(k);
  if (it != unique.end())
    return it->second;
  unsigned n = unsigned(nodes.size());
  nodes.push_back({v, l, h});
  unique.emplace(k, n);
  return n;
}

unsigned Bdd::cofactor(unsigned f, unsigned v, bool val) {
  const unsigned lv = level(v);
  if (terminal(f) || top(f) > lv)
    return f;
  if (var(f) == v)
    return val ? hi(f) : lo(f);
  const Key3 key{f, v, unsigned(val)};
  if (auto it = cofMemo.find(key); it != cofMemo.end())
    return it->second;
  // cq-g3h1i: memoized per call (a stamp per node), so the walk is linear in f's nodes and not in its paths.
  // A node is still made the first time its children are done, low child first: the node numbers are the
  // unmemoized walk's.
  if (++stamp == 0) {
    std::fill(seenAt.begin(), seenAt.end(), 0u);
    stamp = 1;
  }
  const unsigned call = stamp;
  if (seenAt.size() < nodes.size()) {   // nodes made during the walk are results, never looked up
    seenAt.resize(nodes.size(), 0u);
    memoVal.resize(nodes.size(), 0u);
  }
  struct Walk {
    Bdd &m;
    unsigned v, lv, call;
    bool val;
    unsigned go(unsigned n) {
      if (m.terminal(n) || m.top(n) > lv)
        return n;
      if (m.var(n) == v)
        return val ? m.hi(n) : m.lo(n);
      if (m.seenAt[n] == call)
        return m.memoVal[n];
      unsigned l = go(m.lo(n));
      unsigned h = go(m.hi(n));
      unsigned r = m.mk(m.var(n), l, h);
      m.seenAt[n] = call;
      m.memoVal[n] = r;
      return r;
    }
  } walk{*this, v, lv, call, val};
  unsigned r = walk.go(f);
  cofMemo.emplace(key, r);
  return r;
}

unsigned Bdd::ite(unsigned f, unsigned g, unsigned h) {
  if (f == T)
    return g;
  if (f == F)
    return h;
  if (g == h)
    return g;
  if (g == T && h == F)
    return f;
  Key3 k{f, g, h};
  auto it = iteMemo.find(k);
  if (it != iteMemo.end())
    return it->second;
  unsigned lv = std::min({top(f), top(g), top(h)}), v = order[lv];
  auto co = [&](unsigned x, bool b) {
    if (terminal(x) || var(x) != v)
      return x;
    return b ? hi(x) : lo(x);
  };
  unsigned r0 = ite(co(f, false), co(g, false), co(h, false));
  unsigned r1 = ite(co(f, true), co(g, true), co(h, true));
  unsigned r = mk(v, r0, r1);
  iteMemo.emplace(k, r);
  return r;
}

unsigned Bdd::exists(unsigned f, const std::function<bool(unsigned)> &pick) {
  std::unordered_map<unsigned, unsigned> memo;
  std::function<unsigned(unsigned)> go = [&](unsigned n) -> unsigned {
    if (terminal(n))
      return n;
    auto it = memo.find(n);
    if (it != memo.end())
      return it->second;
    unsigned l = go(lo(n)), h = go(hi(n));
    unsigned r = pick(var(n)) ? orOp(l, h) : mk(var(n), l, h);
    memo.emplace(n, r);
    return r;
  };
  return go(f);
}

std::pair<bool, bool> Bdd::sides(unsigned f, unsigned v) {
  const unsigned lv = level(v);
  if (++stamp == 0) {
    std::fill(seenAt.begin(), seenAt.end(), 0u);
    stamp = 1;
  }
  if (seenAt.size() < nodes.size()) {
    seenAt.resize(nodes.size(), 0u);
    memoVal.resize(nodes.size(), 0u);
  }
  // Bit 0: satisfiable with v false; bit 1: with v true. A node below v's level does not read v.
  struct Walk {
    Bdd &m;
    unsigned v, lv, call;
    unsigned go(unsigned n) {
      if (n == F)
        return 0;
      if (n == T || m.top(n) > lv)
        return 3;
      if (m.var(n) == v)
        return (m.lo(n) != F ? 1u : 0u) | (m.hi(n) != F ? 2u : 0u);
      if (m.seenAt[n] == call)
        return m.memoVal[n];
      unsigned r = go(m.lo(n));
      if (r != 3)
        r |= go(m.hi(n));
      m.seenAt[n] = call;
      m.memoVal[n] = r;
      return r;
    }
  } walk{*this, v, lv, stamp};
  unsigned r = walk.go(f);
  return {(r & 1) != 0, (r & 2) != 0};
}

bool Bdd::meets(unsigned a, unsigned b, bool negB) {
  // A walk over node pairs that makes no node; a pair found unsatisfiable is not walked again.
  const unsigned bad = negB ? T : F;   // the terminal of b whose side is false
  struct Walk {
    Bdd &m;
    unsigned bad;
    llvm::DenseSet<uint64_t> dead;
    bool go(unsigned a, unsigned b) {
      if (a == F || b == bad)
        return false;
      if (m.terminal(a) || m.terminal(b))   // the other is a non-terminal or the good side: satisfiable
        return true;
      uint64_t key = (uint64_t(a) << 32) | b;
      if (dead.count(key))
        return false;
      unsigned ta = m.top(a), tb = m.top(b);
      unsigned a0 = ta <= tb ? m.lo(a) : a, a1 = ta <= tb ? m.hi(a) : a;
      unsigned b0 = tb <= ta ? m.lo(b) : b, b1 = tb <= ta ? m.hi(b) : b;
      if (go(a0, b0) || go(a1, b1))
        return true;
      dead.insert(key);
      return false;
    }
  } walk{*this, bad, {}};
  return walk.go(a, b);
}

unsigned Bdd::restrict(unsigned f, unsigned c) {
  // A plain recursion over a flat memo (not std::function over node-allocating buckets); children low first.
  struct Walk {
    Bdd &m;
    llvm::DenseMap<uint64_t, unsigned> memo;
    unsigned go(unsigned f, unsigned c) {
      if (c == F || c == T || m.terminal(f))
        return f;
      uint64_t key = (uint64_t(f) << 32) | c;
      if (auto it = memo.find(key); it != memo.end())
        return it->second;
      unsigned r;
      if (m.top(c) < m.top(f)) {
        r = go(f, m.orOp(m.lo(c), m.hi(c)));
      } else if (m.var(c) == m.var(f)) {
        if (m.lo(c) == F)
          r = go(m.hi(f), m.hi(c));
        else if (m.hi(c) == F)
          r = go(m.lo(f), m.lo(c));
        else {
          unsigned l = go(m.lo(f), m.lo(c));
          unsigned h = go(m.hi(f), m.hi(c));
          r = m.mk(m.var(f), l, h);
        }
      } else {
        unsigned l = go(m.lo(f), c);
        unsigned h = go(m.hi(f), c);
        r = m.mk(m.var(f), l, h);
      }
      memo[key] = r;
      return r;
    }
  } walk{*this, llvm::DenseMap<uint64_t, unsigned>()};
  return walk.go(f, c);
}

void Bdd::support(unsigned f, std::set<unsigned> &out) const {
  // cq-g3h1i: the visited set is a stamp per node, and a variable goes into `out` once per run of equal ones.
  if (++stamp == 0) {
    std::fill(seenAt.begin(), seenAt.end(), 0u);
    stamp = 1;
  }
  if (seenAt.size() < nodes.size()) {
    seenAt.resize(nodes.size(), 0u);
    memoVal.resize(nodes.size(), 0u);
  }
  std::vector<unsigned> stack{f};
  unsigned last = NoVar;
  while (!stack.empty()) {
    unsigned n = stack.back();
    stack.pop_back();
    if (terminal(n) || seenAt[n] == stamp)
      continue;
    seenAt[n] = stamp;
    if (var(n) != last)
      out.insert(last = var(n));
    stack.push_back(lo(n));
    stack.push_back(hi(n));
  }
}

bool Bdd::eval(unsigned f, const std::function<bool(unsigned)> &value) const {
  while (!terminal(f))
    f = value(var(f)) ? hi(f) : lo(f);
  return f == T;
}

std::string Bdd::str(unsigned f) const {
  if (f == F)
    return "0";
  if (f == T)
    return "1";
  std::string v = "v" + std::to_string(var(f));
  unsigned l = lo(f), h = hi(f);
  if (l == F && h == T)
    return v;
  if (l == T && h == F)
    return "!" + v;
  if (l == F)
    return "(" + v + " & " + str(h) + ")";
  if (h == F)
    return "(!" + v + " & " + str(l) + ")";
  if (h == T)
    return "(" + v + " | " + str(l) + ")";
  if (l == T)
    return "(!" + v + " | " + str(h) + ")";
  return "(" + v + " ? " + str(h) + " : " + str(l) + ")";
}

} // namespace cq::pred_detail
