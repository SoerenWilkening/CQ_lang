// Module pred (cq-w0-pred), private. A reduced ordered BDD manager: the canonical form behind Pred.
//
// Variables are condition atoms, numbered in creation order. The variable order is creation order too,
// except for a variable placed with placeAfter (cq-ewzri): it is inserted into the order after an older
// one. Inserting a new variable keeps every existing node a reduced ordered BDD of the same function
// (no node reads it), so node numbers stay canonical and the memos stay valid. Node 0 is false, node 1
// is true. Nodes are never freed: one compiler run builds a bounded number of them.
#pragma once

#include <cstdint>
#include <functional>
#include <set>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace cq::pred_detail {

class Bdd {
public:
  static constexpr unsigned F = 0, T = 1;
  static constexpr unsigned NoVar = ~0u;

  static Bdd &get();   // the one manager of this process

  unsigned var(unsigned n) const { return nodes[n].var; }
  // A variable's position in the order (smaller is nearer the root).
  unsigned level(unsigned v) {
    place(v);
    return lvl[v];
  }
  // Order v (not yet ordered) right after variable `after` (ordered); a variable never placed is
  // appended at its first use, every unordered variable below it first.
  void placeAfter(unsigned v, unsigned after);
  unsigned lo(unsigned n) const { return nodes[n].lo; }
  unsigned hi(unsigned n) const { return nodes[n].hi; }
  bool terminal(unsigned n) const { return n <= T; }

  unsigned mk(unsigned v, unsigned lo, unsigned hi);
  unsigned ithVar(unsigned v) { return mk(v, F, T); }
  unsigned ite(unsigned f, unsigned g, unsigned h);
  unsigned andOp(unsigned a, unsigned b) { return ite(a, b, F); }
  unsigned orOp(unsigned a, unsigned b) { return ite(a, T, b); }
  unsigned notOp(unsigned a) { return ite(a, F, T); }
  unsigned xorOp(unsigned a, unsigned b) { return ite(a, notOp(b), b); }
  // f with variable v fixed to val.
  unsigned cofactor(unsigned f, unsigned v, bool val);
  // Whether f holds for some assignment with v false (first) and with v true (second): f & !v != F and f & v != F,
  // without making either conjunction.
  std::pair<bool, bool> sides(unsigned f, unsigned v);
  // Whether a & b (a & !b when negB) is satisfiable, without making the conjunction (cq-m16f6).
  bool meets(unsigned a, unsigned b, bool negB = false);
  // Existential quantification over every variable `pick` selects.
  unsigned exists(unsigned f, const std::function<bool(unsigned)> &pick);
  // Coudert-Madre restrict: a function that agrees with f wherever c holds, with support within f's.
  unsigned restrict(unsigned f, unsigned c);
  void support(unsigned f, std::set<unsigned> &out) const;
  // f as a Boolean formula over v<i> (for diagnostics and tests).
  std::string str(unsigned f) const;
  // Evaluate f under an assignment (vars absent from the map are false).
  bool eval(unsigned f, const std::function<bool(unsigned)> &value) const;

private:
  Bdd();
  struct Node { unsigned var, lo, hi; };
  struct Key3 {
    unsigned a, b, c;
    bool operator==(const Key3 &o) const { return a == o.a && b == o.b && c == o.c; }
  };
  struct Hash3 {
    size_t operator()(const Key3 &k) const {
      uint64_t h = k.a * 0x9E3779B97F4A7C15ull;
      h ^= (h >> 29) + k.b * 0xBF58476D1CE4E5B9ull;
      h ^= (h >> 31) + k.c * 0x94D049BB133111EBull;
      return size_t(h ^ (h >> 32));
    }
  };
  void place(unsigned v) {
    if (v >= lvl.size() || lvl[v] == NoVar)
      append(v);
  }
  void append(unsigned v);
  unsigned top(unsigned n) { return terminal(n) ? NoVar : level(var(n)); }   // NoVar: below every variable
  std::vector<Node> nodes;
  std::vector<unsigned> lvl, order;   // var -> level, level -> var
  // cofMemo: cofactor results keyed {f, v, val}; like iteMemo it stays valid when a variable is placed (node numbers
  // are canonical and a hit means the walk already made every node it would make).
  std::unordered_map<Key3, unsigned, Hash3> unique, iteMemo, cofMemo;
  // cq-g3h1i: per-walk marks of cofactor and support: seenAt[n] == stamp says n was visited by the current walk
  // (memoVal[n]: cofactor's result for it).
  mutable std::vector<unsigned> seenAt, memoVal;
  mutable unsigned stamp = 0;
};

} // namespace cq::pred_detail
