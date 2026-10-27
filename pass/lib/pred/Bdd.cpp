// Module pred (cq-w0-pred), private. See Bdd.h.
#include "Bdd.h"

#include <algorithm>
#include <string>

namespace cq::pred_detail {

Bdd &Bdd::get() {
  static Bdd mgr;
  return mgr;
}

Bdd::Bdd() {
  nodes.push_back({NoVar, F, F});   // false
  nodes.push_back({NoVar, T, T});   // true
}

unsigned Bdd::mk(unsigned v, unsigned l, unsigned h) {
  if (l == h)
    return l;
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
  if (terminal(f) || var(f) > v)
    return f;
  if (var(f) == v)
    return val ? hi(f) : lo(f);
  return mk(var(f), cofactor(lo(f), v, val), cofactor(hi(f), v, val));
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
  unsigned v = std::min({var(f), var(g), var(h)});
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

unsigned Bdd::restrict(unsigned f, unsigned c) {
  std::unordered_map<uint64_t, unsigned> memo;
  std::function<unsigned(unsigned, unsigned)> go = [&](unsigned f, unsigned c) -> unsigned {
    if (c == F || c == T || terminal(f))
      return f;
    uint64_t key = (uint64_t(f) << 32) | c;
    auto it = memo.find(key);
    if (it != memo.end())
      return it->second;
    unsigned r;
    if (var(c) < var(f)) {
      r = go(f, orOp(lo(c), hi(c)));
    } else if (var(c) == var(f)) {
      if (lo(c) == F)
        r = go(hi(f), hi(c));
      else if (hi(c) == F)
        r = go(lo(f), lo(c));
      else
        r = mk(var(f), go(lo(f), lo(c)), go(hi(f), hi(c)));
    } else {
      r = mk(var(f), go(lo(f), c), go(hi(f), c));
    }
    memo.emplace(key, r);
    return r;
  };
  return go(f, c);
}

void Bdd::support(unsigned f, std::set<unsigned> &out) const {
  std::vector<unsigned> stack{f};
  std::set<unsigned> seen;
  while (!stack.empty()) {
    unsigned n = stack.back();
    stack.pop_back();
    if (terminal(n) || !seen.insert(n).second)
      continue;
    out.insert(var(n));
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
