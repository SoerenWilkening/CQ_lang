// Module pred (cq-w0-pred), private. A reduced ordered BDD manager: the canonical form behind Pred.
//
// Variables are condition atoms, numbered in creation order (that is also the variable order). Node 0
// is false, node 1 is true. Nodes are never freed: one compiler run builds a bounded number of them.
#pragma once

#include <cstdint>
#include <functional>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

namespace cq::pred_detail {

class Bdd {
public:
  static constexpr unsigned F = 0, T = 1;
  static constexpr unsigned NoVar = ~0u;

  static Bdd &get();   // the one manager of this process

  unsigned var(unsigned n) const { return nodes[n].var; }
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
  std::vector<Node> nodes;
  std::unordered_map<Key3, unsigned, Hash3> unique, iteMemo;
};

} // namespace cq::pred_detail
