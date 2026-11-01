// The search of compare._match_c in C++ (cq-8m6v step 5): the gate-to-C-site matching's two depth-first
// searches (order-free, then with the order and the node budget), node for node as compare.py's dfs
// runs them: the same candidate order, the same memo, the same budget count, the same final assign
// and unprep. compare.py marshals the gates and sites into one int64 array (_match_input) and reads the
// result back; everything around the search (the reasons) stays in compare.py.
//
// Input (int64): n nS m budget, capped[nS], then per gate: is_theta opt free_ok has_target target
//   nsup sup[nsup] pred[nS] afn[nS] rid[nS] wclass ncand cand[ncand] partner_j nks ks[nks]
//   ncomm comm[ncomm] ordered[n]; then per site: is_theta, per sample: nocc, per occurrence:
//   epos a_id reg_id[nW] ... where nW (the number of width classes) follows m in the header.
// Output (int64): status (0 done, 2 out of budget), found_any, found, assign[n] (-1: none), unprep[n].
#include <cstdint>
#include <cstring>
#include <map>
#include <string>
#include <tuple>
#include <unordered_set>
#include <vector>

namespace {

struct Gate {
  bool theta, opt, free_ok, has_target;
  int64_t target;
  std::vector<int64_t> sup;
  std::vector<uint8_t> pred;
  std::vector<int64_t> afn, rid;
  int64_t wclass;
  std::vector<int> cands;
  int partner_j;  // -1: none
  std::vector<int> ks;
  std::vector<uint8_t> comm;  // comm[k]
  std::vector<uint8_t> ordered;
};

struct Occ {
  int64_t epos, a;
  std::vector<int64_t> reg;  // per width class
};

struct Site {
  bool theta;
  std::vector<std::vector<Occ>> occ;  // per sample
};

// The order state of compare.py's dfs (ordst). exc is keyed (sample, gate) here where compare.py keys
// it (rail, sample, gate): a gate records the same position for every rail of its support at once and
// is read only through its maximum per (sample, gate), so the two are in bijection (the rails of a key
// are its gate's support) and the memo identifies exactly the same states (cq-uvgo: 117 at nS = 10
// had 12 support rails per gate). The search keeps one order state, changed in place by order_ok and
// restored from an undo log when a branch fails, so a frame holds no copy of it (cq-uvgo: a copy per
// frame, 2408 frames deep, took gigabytes).
struct OrdState {
  std::map<std::pair<int64_t, int>, int64_t> any, tgt;
  std::map<std::pair<int, int>, int64_t> exc;
};

struct Undo {
  int which;      // 0 any, 1 tgt, 2 exc
  int64_t a;
  int b;
  int64_t old;    // -1: the key was absent
};

struct OutOfBudget {};

struct Matcher {
  int n = 0, nS = 0, m = 0, nW = 0;
  int64_t budget_init = 0;
  std::vector<uint8_t> capped;
  std::vector<int> P;
  std::vector<Gate> g;
  std::vector<Site> st;
  std::vector<size_t> off;  // word offset of (j, s) in the used state
  std::vector<size_t> nwords;
  size_t total_words = 0;

  std::vector<int> assign;
  std::vector<uint8_t> unprep;
  std::unordered_set<std::string> failed;
  bool check_order = false;
  OrdState os;              // the order state of the current node
  std::vector<Undo> undo;   // order_ok's changes, newest last
  bool budgeted = false;
  int64_t budget = 0;

  typedef std::vector<uint64_t> Used;
  typedef std::vector<uint64_t> Bits;  // a set of gates

  static bool bit(const Bits &b, int i) { return (b[i >> 6] >> (i & 63)) & 1; }
  static Bits with(const Bits &b, int i) {
    Bits c = b;
    c[i >> 6] |= (uint64_t)1 << (i & 63);
    return c;
  }

  // take: gate i by site j; hits (s, epos) in sample order. False: it disagrees or takes no reach.
  bool take(int i, int j, const Used &used, Used &out, std::vector<std::pair<int, int64_t>> *hits) {
    const Gate &e = g[i];
    const Site &s_ = st[j];
    bool changed = false;
    for (int s = 0; s < nS; ++s) {
      if (!e.pred[s])
        continue;
      size_t o = off[(size_t)j * nS + s];
      const std::vector<Occ> &occ = s_.occ[s];
      int hit = -1;
      for (size_t t = 0; t < occ.size(); ++t) {
        const uint64_t *w = (changed ? out.data() : used.data()) + o;
        if ((w[t >> 6] >> (t & 63)) & 1)
          continue;
        if (occ[t].a != e.afn[s])
          continue;
        if (s_.theta && occ[t].reg[e.wclass] != e.rid[s])
          continue;
        hit = (int)t;
        break;
      }
      if (hit < 0) {
        if (capped[s])
          continue;
        return false;
      }
      if (!changed) {
        out = used;
        changed = true;
      }
      out[o + (hit >> 6)] |= (uint64_t)1 << (hit & 63);
      if (hits)
        hits->push_back({s, occ[hit].epos});
    }
    return changed;
  }

  bool leftover(const Used &used) {
    for (int j = 0; j < m; ++j) {
      const Site &s_ = st[j];
      auto left = [&](int s, size_t t) {
        const uint64_t *w = used.data() + off[(size_t)j * nS + s];
        return !((w[t >> 6] >> (t & 63)) & 1);
      };
      if (s_.theta) {
        for (int s = 0; s < nS; ++s)
          for (size_t t = 0; t < s_.occ[s].size(); ++t)
            if (left(s, t))
              return true;
      } else if (!P.empty()) {
        std::vector<std::map<int64_t, int64_t>> cnt(nS);
        for (int s = 0; s < nS; ++s)
          for (size_t t = 0; t < s_.occ[s].size(); ++t)
            if (left(s, t))
              cnt[s][s_.occ[s][t].a]++;
        const std::map<int64_t, int64_t> &L = cnt[P[0]];
        for (int s = 0; s < nS; ++s) {
          if (!capped[s]) {
            if (cnt[s] != L)
              return true;
          } else {
            for (auto &kv : cnt[s]) {  // Counter subtraction: anything more than L has
              auto it = L.find(kv.first);
              if (kv.second > (it == L.end() ? 0 : it->second))
                return true;
            }
          }
        }
      } else {
        bool have = false;
        int64_t first = 0;
        for (int s = 0; s < nS; ++s)
          for (size_t t = 0; t < s_.occ[s].size(); ++t)
            if (left(s, t)) {
              if (!have) {
                have = true;
                first = s_.occ[s][t].a;
              } else if (s_.occ[s][t].a != first)
                return true;
            }
      }
    }
    return false;
  }

  // set the map entry to p when p is larger; the old value goes on the undo log
  template <class Map, class Key> void raise(int which, Map &mp, const Key &key, int64_t a, int b, int64_t p) {
    auto it = mp.find(key);
    int64_t old = it == mp.end() ? -1 : it->second;
    if (p > old) {
      undo.push_back({which, a, b, old});
      mp[key] = p;
    }
  }

  void rollback(size_t mark) {
    while (undo.size() > mark) {
      const Undo &u = undo.back();
      if (u.which == 2) {
        if (u.old < 0)
          os.exc.erase({(int)u.a, u.b});
        else
          os.exc[{(int)u.a, u.b}] = u.old;
      } else {
        auto &mp = u.which == 0 ? os.any : os.tgt;
        if (u.old < 0)
          mp.erase({u.a, u.b});
        else
          mp[{u.a, u.b}] = u.old;
      }
      undo.pop_back();
    }
  }

  // compare.py's order_ok on the current order state, in place (its changes logged on undo; on false
  // the caller rolls them back)
  bool order_ok(int i, const std::vector<std::pair<int, int64_t>> &picks) {
    const Gate &e = g[i];
    bool comm_any = false;
    for (uint8_t c : e.comm)
      if (c) {
        comm_any = true;
        break;
      }
    for (auto &pk : picks) {
      int s = pk.first;
      int64_t p = pk.second;
      int64_t lim = -1;
      for (int64_t r : e.sup) {
        auto it = os.tgt.find({r, s});
        if (it != os.tgt.end() && it->second > lim)
          lim = it->second;
      }
      if (e.has_target) {
        auto it = os.any.find({e.target, s});
        int64_t v = it == os.any.end() ? -1 : it->second;
        if (v > lim)
          lim = v;
      }
      for (auto it = os.exc.lower_bound({s, -1}); it != os.exc.end() && it->first.first == s; ++it) {
        int k = it->first.second;
        if (!e.comm[k] && it->second > lim && e.ordered[k])
          lim = it->second;
      }
      if (p < lim)
        return false;
      if (comm_any) {
        if (!e.sup.empty())     // one entry for every rail of the support (see OrdState)
          raise(2, os.exc, std::make_pair(s, i), s, i, p);
        continue;
      }
      for (int64_t r : e.sup)
        raise(0, os.any, std::make_pair(r, s), r, s, p);
      if (e.has_target)
        raise(1, os.tgt, std::make_pair(e.target, s), e.target, s, p);
    }
    return true;
  }

  static void put(std::string &k, const void *p, size_t n) { k.append((const char *)p, n); }

  std::string key(int i, const Used &used, const Bits &unp, const Bits &fr) {
    std::string k;
    put(k, &i, sizeof i);
    put(k, used.data(), used.size() * 8);
    put(k, unp.data(), unp.size() * 8);
    put(k, fr.data(), fr.size() * 8);
    int64_t sz = (int64_t)os.any.size();
    put(k, &sz, 8);
    for (auto &kv : os.any) {
      put(k, &kv.first.first, 8);
      put(k, &kv.first.second, 4);
      put(k, &kv.second, 8);
    }
    sz = (int64_t)os.tgt.size();
    put(k, &sz, 8);
    for (auto &kv : os.tgt) {
      put(k, &kv.first.first, 8);
      put(k, &kv.first.second, 4);
      put(k, &kv.second, 8);
    }
    sz = (int64_t)os.exc.size();
    put(k, &sz, 8);
    for (auto &kv : os.exc) {
      put(k, &kv.first.first, 4);
      put(k, &kv.first.second, 4);
      put(k, &kv.second, 8);
    }
    return k;
  }

  bool dfs(int i, const Used &used, const Bits &unp, const Bits &fr) {
    if (i == n) {
      if (leftover(used))
        return false;
      for (int u = 0; u < n; ++u) {
        if (!bit(unp, u))
          continue;
        for (int k : g[u].ks)
          if (bit(unp, k) || bit(fr, k))
            return false;
      }
      return true;
    }
    // the key is not kept in the frame (it grows with the order state): built again at the failure,
    // where the order state is the node's again
    if (failed.count(key(i, used, unp, fr)))
      return false;
    if (budgeted) {
      budget -= 1;
      if (budget < 0)
        throw OutOfBudget();
    }
    for (int j : g[i].cands) {
      std::vector<std::pair<int, int64_t>> hl;
      Used nxt;
      if (take(i, j, used, nxt, &hl)) {
        size_t mark = undo.size();
        if (check_order && !order_ok(i, hl)) {
          rollback(mark);
          continue;
        }
        assign[i] = j;
        if (dfs(i + 1, nxt, unp, fr))
          return true;
        rollback(mark);
      }
    }
    assign[i] = -1;
    int pj = g[i].partner_j;
    if (pj >= 0 && !bit(unp, pj) && !bit(fr, pj)) {
      if (dfs(i + 1, used, with(unp, i), fr)) {
        unprep[i] = 1;
        return true;
      }
    }
    if (g[i].free_ok) {
      if (dfs(i + 1, used, unp, with(fr, i)))
        return true;
    }
    failed.insert(key(i, used, unp, fr));
    return false;
  }
};

}  // namespace

extern "C" int64_t cq_match_c(const int64_t *in, int64_t nin, int64_t *out, int64_t nout) {
  Matcher M;
  int64_t q = 0;
  auto rd = [&]() -> int64_t { return q < nin ? in[q++] : (q++, 0); };
  M.n = (int)rd();
  M.nS = (int)rd();
  M.m = (int)rd();
  M.nW = (int)rd();
  M.budget_init = rd();
  int n = M.n, nS = M.nS;
  if (nout < 3 + 2 * (int64_t)n)
    return -1;
  M.capped.resize(nS);
  for (int s = 0; s < nS; ++s) {
    M.capped[s] = (uint8_t)rd();
    if (!M.capped[s])
      M.P.push_back(s);
  }
  M.g.resize(n);
  for (int i = 0; i < n; ++i) {
    Gate &e = M.g[i];
    e.theta = rd();
    e.opt = rd();
    e.free_ok = rd();
    e.has_target = rd();
    e.target = rd();
    e.sup.resize((size_t)rd());
    for (auto &x : e.sup)
      x = rd();
    e.pred.resize(nS);
    for (auto &x : e.pred)
      x = (uint8_t)rd();
    e.afn.resize(nS);
    for (auto &x : e.afn)
      x = rd();
    e.rid.resize(nS);
    for (auto &x : e.rid)
      x = rd();
    e.wclass = rd();
    if (e.wclass < 0)
      e.wclass = 0;
    e.cands.resize((size_t)rd());
    for (auto &x : e.cands)
      x = (int)rd();
    e.partner_j = (int)rd();
    e.ks.resize((size_t)rd());
    for (auto &x : e.ks)
      x = (int)rd();
    e.comm.assign(n, 0);
    int64_t nc = rd();
    for (int64_t c = 0; c < nc; ++c)
      e.comm[(size_t)rd()] = 1;
    e.ordered.resize(n);
    for (auto &x : e.ordered)
      x = (uint8_t)rd();
  }
  M.st.resize(M.m);
  M.off.resize((size_t)M.m * nS);
  M.nwords.resize((size_t)M.m * nS);
  for (int j = 0; j < M.m; ++j) {
    Site &s_ = M.st[j];
    s_.theta = rd();
    s_.occ.resize(nS);
    for (int s = 0; s < nS; ++s) {
      s_.occ[s].resize((size_t)rd());
      for (auto &o : s_.occ[s]) {
        o.epos = rd();
        o.a = rd();
        o.reg.resize(M.nW > 0 ? M.nW : 1);
        for (int w = 0; w < M.nW; ++w)
          o.reg[w] = rd();
      }
      size_t words = (s_.occ[s].size() + 63) / 64;
      M.off[(size_t)j * nS + s] = M.total_words;
      M.nwords[(size_t)j * nS + s] = words;
      M.total_words += words;
    }
  }
  if (q != nin)
    return -2;
  Matcher::Used start(M.total_words, 0);
  Matcher::Bits empty((n + 63) / 64 + 1, 0);
  M.assign.assign(n, -1);
  M.unprep.assign(n, 0);
  // first without the order and without a budget, then with both, from scratch
  M.check_order = false;
  M.budgeted = false;
  bool found_any = M.dfs(0, start, empty, empty);
  bool found = false;
  int64_t status = 0;
  if (found_any) {
    std::vector<int> any_assign = M.assign;
    std::vector<uint8_t> any_unprep = M.unprep;
    M.check_order = true;
    M.failed.clear();
    M.os = OrdState();
    M.undo.clear();
    M.unprep.assign(n, 0);
    M.budgeted = true;
    M.budget = M.budget_init;
    try {
      found = M.dfs(0, start, empty, empty);
    } catch (OutOfBudget &) {
      status = 2;
    }
    if (status == 0 && !found) {
      M.assign = any_assign;
      M.unprep = any_unprep;
    }
  }
  out[0] = status;
  out[1] = found_any;
  out[2] = found;
  for (int i = 0; i < n; ++i) {
    out[3 + i] = M.assign[i];
    out[3 + n + i] = M.unprep[i];
  }
  return 0;
}
