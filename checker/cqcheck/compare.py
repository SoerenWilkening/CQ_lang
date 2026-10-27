"""§6 comparison (module chk-compare, bead cq-w0-chk-compare).

`compare(ours, other, against) -> List[str]` (frozen by cq-zew) decides CR §6 equality of two
sides, each a sequence of RunResults with one entry per sample, and returns the reasons they differ
(empty = §6-equal):

- against="ref": `other` is the reference lowered.ll run in the evaluator (§6 oracle (a)).
- against="c":   `other` is the C program run under the oracle (§6 oracle (b)).

What is compared (CR §6, CLAUDE.md "The §6 checker"):

- per sample: violations (none allowed on either side), named outputs, measured values;
- every `cqrt_free` on our side sees a rail in a known classical basis state (CR §0);
- oracle "ref" only: kept rails (live at exit, every role, A4's kept_entangled included) as a
  multiset of (type, value function over the group's samples);
- the rotation list: (gate, target, angle or angle-rail value, control predicate per input), up to
  reordering of gates with disjoint support and renaming of rails. Rails are matched by (type,
  value function over the group's samples). A phase P(θ) on a flag is e^{iθ·f}: its predicate is the
  flag's value, whichever rail carries it. Global phases are dropped on both sides: a classical-angle
  phase whose predicate is constant over the group (never an Ry, never an angle-rail phase). Against
  the C oracle rotations are matched by site: each (function, site, occurrence) of a reached
  `cq_theta`/`cq_phi` must be one lowered gate with the same predicate, angle and register value at
  every sample, in an order consistent with every sample's hit order.

Groups. The samples are partitioned by `classical_key(sample)` (the classical arguments; see
`classical_key_from_driver`; without it, by the sample's call). Each group is further split by the
lowered circuit's structure on each side (gate sequence, handles, classical angles, kept, freed and
measured handles); handles are compared only within such a group, where they align. A classical
argument that decides a branch changes the structure (a classical condition stays a classical
branch, NORTHSTAR principle 2), so the structure split refines the call into classical contexts.
With an explicit classical_key, a structure that varies within one classical group while nothing
is measured (the circuit depends on quantum data) is rejected. A gate whose predicate reads 0 at every sample of a group, or whose angle is the
identity (±0; non-finite for Ry and angle rails, CR §1.3), is not a gate there.

Support. A gate's support is its target rail plus the registers (Ry targets) its predicate and its
angle-rail value depend on. Dependence is exact when the group's register values form a full grid
on which the function is determined (the exhaustive case); otherwise every non-constant register is
taken as a dependence (conservative: a reordering is accepted only when provably disjoint).

RunResult contents consumed here (the frozen trace events of cq-arch, plus fields that make a
record self-contained; values are hex bit patterns or ints):

- rotations (lowered side): trace events in emission order,
    {"ev":"ry","h","theta","ctl":[h],"ctlv":[b]}, {"ev":"ry_qangle","h","a","aval","ctl","ctlv"},
    {"ev":"phase","f","fv","theta"}, {"ev":"phase_qangle","a","aval","ctl","ctlv"};
  an Ry record may carry "w" and "v" (the target's type and its value at the gate); missing, they
  are read from the target's entry in `kept` (a rotated rail is never written in place again).
- rotations (C oracle side): {"ev":"site","fn","site","kind":"theta|phi","angle","reg"} per reached
  site, in execution order.
- kept: the exit event's live list, [{"h","w","v","role"}].
- clean: the free events, [{"h","v","known"}].
- measured: the measure events, [{"h","v"}] (a "w" is compared when both sides give one).
- outputs: any JSON (a dict of named outputs); hex strings compare as integers. A leaf that is a
  dict with a rail type "w" and a value "v" ({"w":"f32","v":"0x7fc00000"}) is a typed scalar: its
  value is compared at that width, and an fp one under the fp equality mode below. An untyped
  value carries no fp-ness and is compared bit for bit in both modes.
- violations: a list; any entry fails the comparison.

Floating-point equality (CR §2 NaN row, ruling 2026-10-27, bead cq-8dy). Against the reference
every value is compared bit for bit. Against the C oracle a floating-point value is compared
NaN-insensitively: any NaN equals any NaN (sign and payload ignored), a NaN never equals a
non-NaN. A value is floating point when its type is known: a typed output, a measured rail (its
"w", or the type of the same handle in `kept`), an Ry target's register (the target's type, at
which the C register value is read) and every classical angle (f64). An Ry with a non-finite
angle and an angle-rail gate with a non-finite angle are no gate in either mode (CR §1.3), so a
NaN angle survives only on a classical-angle phase (P(θ), C `cq_phi`), where the mode applies.
x87 f80: a NaN is exponent 0x7FFF with a nonzero fraction (bits 0..62), the explicit integer bit
ignored, so a pseudo-NaN is a NaN and a pseudo-infinity is not.
"""
from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from typing import Any, Callable, Dict, FrozenSet, Hashable, List, Optional, Sequence, Tuple

from .contracts import DriverSpec, RunResult


class CompareError(Exception):
    """A RunResult this module cannot read: an internal error of the checker, never a verdict."""


# ---------------------------------------------------------------- values

def _int(x: Any) -> Optional[int]:
    if x is None:
        return None
    if isinstance(x, bool):
        return int(x)
    if isinstance(x, int):
        return x
    if isinstance(x, str):
        return int(x, 0)
    raise CompareError(f"cq: unimplemented: chk-compare: value {x!r}")


def _bits(w: Optional[str]) -> Optional[int]:
    if not w:
        return None
    if w == "bf16":
        return 16
    if w[0] in "if" and w[1:].isdigit():
        return int(w[1:])
    raise CompareError(f"cq: unimplemented: chk-compare: rail type {w!r}")


def _is_type(w: Any) -> bool:
    if not isinstance(w, str) or not w:
        return False
    return w == "bf16" or (w[0] in "if" and w[1:].isdigit())


# fp layouts: (exponent bits, fraction bits); f80's fraction is bits 0..62 below the integer bit 63
_FP = {"f16": (5, 10), "bf16": (8, 7), "f32": (8, 23), "f64": (11, 52), "f80": (15, 63)}
_NAN = "NaN"                         # the class of every NaN under the NaN-insensitive mode


def _is_nan(v: int, w: str) -> bool:
    if w not in _FP:
        raise CompareError(f"cq: unimplemented: chk-compare: fp type {w!r}")
    e, f = _FP[w]
    shift = 64 if w == "f80" else f
    return ((v >> shift) & ((1 << e) - 1)) == (1 << e) - 1 and (v & ((1 << f) - 1)) != 0


def _fpv(v: Optional[int], w: Optional[str], nan_eq: bool) -> Any:
    """A value masked to its type; under nan_eq an fp NaN becomes the single class _NAN."""
    v = _masked(v, w)
    if nan_eq and v is not None and w and w[0] in "fb" and _is_nan(v, w):
        return _NAN
    return v


def _masked(v: Optional[int], w: Optional[str]) -> Optional[int]:
    b = _bits(w)
    if v is None or b is None:
        return v
    return v & ((1 << b) - 1)


def _norm(x: Any, nan_eq: bool = False) -> Any:
    """Outputs normalized for equality: hex strings as integers, typed scalars at their width and
    under the fp mode, recursively."""
    if isinstance(x, dict):
        if "w" in x and "v" in x and _is_type(x["w"]) and not isinstance(x["v"], (dict, list)):
            return _fpv(_int(x["v"]), x["w"], nan_eq)
        return {k: _norm(v, nan_eq) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [_norm(v, nan_eq) for v in x]
    if isinstance(x, str) and x[:2].lower() in ("0x", "-0"):
        try:
            return int(x, 0)
        except ValueError:
            return x
    return x


def _angle_identity(bits: int, nonfinite_is_identity: bool) -> bool:
    """f64 bit pattern: ±0 is always the identity; non-finite is for Ry and angle rails (CR §1.3)."""
    bits &= (1 << 64) - 1
    if bits & ~(1 << 63) == 0:
        return True
    return nonfinite_is_identity and ((bits >> 52) & 0x7FF) == 0x7FF


def _skey(sample: Any) -> str:
    return json.dumps(sample, sort_keys=True, separators=(",", ":"))


def classical_key_from_driver(driver: DriverSpec) -> Callable[[Any], Hashable]:
    """The classical part of a sample {call, args}: the call and every non-quantum argument."""
    def key(sample: Any) -> Hashable:
        call = sample["call"]
        if isinstance(call, int):
            spec = driver.calls[call]
        else:
            matches = [c for c in driver.calls if c["fn"] == call]
            if len(matches) != 1:
                raise CompareError(f"cq: unimplemented: chk-compare: call {call!r} in {driver.example}")
            spec = matches[0]
        args = sample["args"]
        if len(args) != len(spec["args"]):
            raise CompareError(f"cq: unimplemented: chk-compare: arity of {call!r} in {driver.example}")
        return (_skey(call),) + tuple(_skey(a) for a, s in zip(args, spec["args"]) if not s["quantum"])
    return key


# ---------------------------------------------------------------- lowered rotation events

_KIND = {"ry": "ry", "ry_qangle": "ryq", "phase": "ph", "phase_qangle": "phq"}


def _ctl_on(rec: Dict[str, Any]) -> int:
    return int(all(_int(b) for b in rec.get("ctlv", []) or []))


def _shape(rr: RunResult) -> Tuple:
    """The structure of one lowered run: everything but data values."""
    rots = []
    for rec in rr.rotations or []:
        ev = rec.get("ev")
        if ev not in _KIND:
            raise CompareError(f"cq: unimplemented: chk-compare: rotation event {rec!r}")
        theta = _int(rec.get("theta")) if ev in ("ry", "phase") else None
        rots.append((ev, rec.get("h"), rec.get("a"), rec.get("f"), tuple(rec.get("ctl", []) or []), theta))
    kept = tuple(sorted((k["h"], k.get("w")) for k in rr.kept or []))
    freed = tuple(c["h"] for c in rr.clean or [])
    meas = tuple(m.get("h") for m in rr.measured or [])
    return (tuple(rots), kept, freed, meas)


@dataclass
class _Ev:
    idx: int                         # position in the side's emission order
    kind: str                        # ry ryq ph phq
    target: Optional[int]            # rail handle (ry, ryq)
    tclass: Optional[Tuple]          # (w, value function) of the target
    theta: Optional[int]             # classical angle bits (ry, ph)
    afn: Optional[Tuple]             # angle-rail values where fired, None elsewhere (ryq, phq)
    pred: Tuple[int, ...]            # fired per group sample
    support: FrozenSet[int] = frozenset()
    label: str = ""


def _target_value(rr: RunResult, rec: Dict[str, Any]) -> Tuple[Optional[str], int]:
    h = rec["h"]
    w = rec.get("w")
    v = rec.get("v")
    for k in rr.kept or []:
        if k["h"] == h:
            w = w or k.get("w")
            if v is None:
                v = k.get("v")
    if v is None:
        for m in rr.measured or []:
            if m.get("h") == h:
                v = m.get("v")
                w = w or m.get("w")
    if v is None:
        raise CompareError(f"cq: unimplemented: chk-compare: value of rotated rail {h} unknown "
                           f"(neither on the record nor live at exit)")
    return w, _masked(_int(v), w)


def _dep(fn: Sequence[Any], regs: Dict[int, Tuple]) -> FrozenSet[int]:
    """Registers a function over the group's samples depends on (see module docstring)."""
    if len(set(fn)) <= 1:
        return frozenset()
    varying = {h: vals for h, vals in regs.items() if len(set(vals)) > 1}
    names = sorted(varying)
    if not names:
        return frozenset(regs)       # varies with nothing we can name: depend on everything
    tuples = [tuple(varying[h][s] for h in names) for s in range(len(fn))]
    table: Dict[Tuple, Any] = {}
    determined = True
    for t, f in zip(tuples, fn):
        if table.setdefault(t, f) != f:
            determined = False
            break
    grid = 1
    for h in names:
        grid *= len(set(varying[h]))
    if not determined or grid != len(table):
        return frozenset(names)
    dep = set()
    for t, f in table.items():
        for i, h in enumerate(names):
            if h in dep:
                continue
            for val in set(varying[h]):
                u = t[:i] + (val,) + t[i + 1:]
                if table[u] != f:
                    dep.add(h)
                    break
    return frozenset(dep)


def _lowered_events(runs: List[RunResult]) -> Tuple[List[_Ev], List[_Ev]]:
    """Gate events of one side over one group: (kept events, dropped global phases)."""
    n = len(runs[0].rotations or [])
    recs = [rr.rotations for rr in runs]
    S = range(len(runs))
    evs: List[_Ev] = []
    regs: Dict[int, Tuple] = {}
    for i in range(n):
        r0 = recs[0][i]
        kind = _KIND[r0["ev"]]
        fired: List[int] = []
        afn: List[Optional[int]] = []
        tvals: List[int] = []
        w = None
        theta = _int(r0.get("theta")) if kind in ("ry", "ph") else None
        for s in S:
            rec = recs[s][i]
            if kind == "ph":
                on = int(bool(_int(rec["fv"])))
            else:
                on = _ctl_on(rec)
            if theta is not None and _angle_identity(theta, nonfinite_is_identity=(kind == "ry")):
                on = 0
            aval = None
            if kind in ("ryq", "phq"):
                aval = _int(rec["aval"]) & ((1 << 64) - 1)
                if _angle_identity(aval, nonfinite_is_identity=True):
                    on = 0
            fired.append(on)
            afn.append(aval if on else None)
            if kind in ("ry", "ryq"):
                w, v = _target_value(runs[s], rec)
                tvals.append(v)
        target = r0.get("h") if kind in ("ry", "ryq") else None
        if target is not None and target not in regs:
            regs[target] = tuple(tvals)
        evs.append(_Ev(idx=i, kind=kind, target=target,
                       tclass=(w, tuple(tvals)) if target is not None else None,
                       theta=theta, afn=tuple(afn) if kind in ("ryq", "phq") else None,
                       pred=tuple(fired), label=_describe(r0)))
    live, glob = [], []
    for e in evs:
        if not any(e.pred):
            continue
        if e.kind == "ph" and all(e.pred):
            glob.append(e)
            continue
        sup = set(_dep(e.pred, regs))
        if e.target is not None:
            sup.add(e.target)
        if e.afn is not None:
            sup |= _dep(e.afn, regs)
        e.support = frozenset(sup)
        live.append(e)
    return live, glob


def _describe(rec: Dict[str, Any]) -> str:
    ev = rec.get("ev")
    if ev in ("ry", "ry_qangle"):
        ang = rec.get("theta") if ev == "ry" else f"rail {rec.get('a')}"
        return f"{ev}(h={rec.get('h')}, {ang}, ctl={rec.get('ctl', [])})"
    if ev == "phase":
        return f"phase(f={rec.get('f')}, {rec.get('theta')})"
    return f"{ev}(rail {rec.get('a')}, ctl={rec.get('ctl', [])})"


# ---------------------------------------------------------------- rotation list, oracle (a)

def _same(a: _Ev, b: _Ev, m: Dict[int, int], minv: Dict[int, int]) -> Optional[Tuple[int, int]]:
    """None if a != b; else the rail pair the match needs (or (-1, -1) for none)."""
    if a.kind != b.kind or a.pred != b.pred or a.theta != b.theta or a.afn != b.afn:
        return None
    if a.target is None:
        return (-1, -1)
    if a.tclass != b.tclass:
        return None
    if a.target in m:
        return (a.target, b.target) if m[a.target] == b.target else None
    if b.target in minv:
        return None
    return (a.target, b.target)


def _match_lists(ours: List[_Ev], ref: List[_Ev]) -> Optional[str]:
    """Trace equivalence under partial commutation with a rail bijection; None when equal."""
    best = [-1, ""]
    limit = max(1000, 4 * (len(ours) + len(ref)) + 100)
    if sys.getrecursionlimit() < limit:
        sys.setrecursionlimit(limit)

    def dfs(i: int, rem: List[int], m: Dict[int, int], minv: Dict[int, int]) -> bool:
        if i == len(ours):
            if rem:
                if best[0] < i:
                    best[0], best[1] = i, f"reference gate {ref[rem[0]].label} has no counterpart in ours"
                return False
            return True
        e = ours[i]
        tried = set()
        for pos, j in enumerate(rem):
            r = ref[j]
            pair = _same(e, r, m, minv)
            if pair is None or pair in tried:
                continue
            tried.add(pair)
            if any(ref[k].support & r.support for k in rem[:pos]):
                continue
            m2, minv2 = m, minv
            if pair != (-1, -1) and pair[0] not in m:
                m2 = dict(m); m2[pair[0]] = pair[1]
                minv2 = dict(minv); minv2[pair[1]] = pair[0]
            if dfs(i + 1, rem[:pos] + rem[pos + 1:], m2, minv2):
                return True
        if best[0] < i:
            best[0], best[1] = i, (f"our gate #{i} {e.label} (predicate {_fn(e.pred)}) matches no reference gate "
                                   f"movable to this position")
        return False

    if dfs(0, list(range(len(ref))), {}, {}):
        return None
    return best[1]


def _fn(t: Sequence[Any]) -> str:
    s = "".join(str(x) for x in t[:32])
    return s + ("…" if len(t) > 32 else "")


# ---------------------------------------------------------------- rotation list, oracle (b)

@dataclass
class _Site:
    key: Tuple                       # (fn, site, kind, occurrence)
    kind: str                        # theta | phi
    pred: Tuple[int, ...]
    afn: Tuple
    rfn: Tuple
    order: Dict[int, int]            # sample -> position in that sample's hits


def _c_sites(runs: List[RunResult], nan_eq: bool) -> List[_Site]:
    sites: Dict[Tuple, _Site] = {}
    nS = len(runs)
    for s, rr in enumerate(runs):
        occ: Dict[Tuple, int] = {}
        for pos, rec in enumerate(rr.rotations or []):
            if rec.get("ev") != "site" or rec.get("kind") not in ("theta", "phi"):
                raise CompareError(f"cq: unimplemented: chk-compare: C-oracle rotation {rec!r}")
            base = (rec["fn"], rec["site"], rec["kind"])
            k = occ.get(base, 0)
            occ[base] = k + 1
            ang = _int(rec["angle"]) & ((1 << 64) - 1)
            if _angle_identity(ang, nonfinite_is_identity=(rec["kind"] == "theta")):
                continue
            key = base + (k,)
            st = sites.get(key)
            if st is None:
                st = sites[key] = _Site(key, rec["kind"], [0] * nS, [None] * nS, [None] * nS, {})
            st.pred[s] = 1
            st.afn[s] = _fpv(ang, "f64", nan_eq)
            st.rfn[s] = _int(rec.get("reg")) if rec["kind"] == "theta" else None
            st.order[s] = pos
    for st in sites.values():
        st.pred, st.afn, st.rfn = tuple(st.pred), tuple(st.afn), tuple(st.rfn)
    return list(sites.values())


def _match_c(ours: List[_Ev], glob: List[_Ev], sites: List[_Site], nan_eq: bool) -> List[str]:
    reasons: List[str] = []

    def lsig(e: _Ev) -> Tuple:
        kind = "theta" if e.kind in ("ry", "ryq") else "phi"
        if e.afn is not None:
            afn = tuple(_fpv(a, "f64", nan_eq) for a in e.afn)
        else:
            afn = tuple(_fpv(e.theta, "f64", nan_eq) if p else None for p in e.pred)
        w = e.tclass[0] if e.target is not None else None
        if e.target is not None:
            rfn = tuple(_fpv(v, w, nan_eq) if p else None for v, p in zip(e.tclass[1], e.pred))
        else:
            rfn = tuple(None for _ in e.pred)
        return (kind, e.pred, afn, rfn, w)

    # a C register value is compared at the lowered target's width
    by_sig: Dict[Tuple, List[_Ev]] = {}
    for e in ours:
        by_sig.setdefault(lsig(e), []).append(e)
    widths = {sig[4] for sig in by_sig}
    pairs: Dict[Tuple, _Ev] = {}
    groups: Dict[Tuple, List[_Site]] = {}
    for st in sites:
        optional = (st.kind == "phi" and all(st.pred) and len(set(st.afn)) == 1)
        matched = False
        for w in sorted(widths, key=lambda x: (x is None, str(x))):
            rfn = tuple(_fpv(v, w, nan_eq) if p and v is not None else None for v, p in zip(st.rfn, st.pred))
            sig = (st.kind, st.pred, st.afn, rfn, w if st.kind == "theta" else None)
            if sig in by_sig:
                groups.setdefault(sig, []).append(st)
                matched = True
                break
        if not matched and not optional:
            reasons.append(f"C site {st.key[0]}:{st.key[1]} ({st.kind}, occurrence {st.key[3]}, reached "
                           f"{_fn(st.pred)}) has no lowered gate with that predicate, angle and register")
    for sig, evs in by_sig.items():
        sts = groups.get(sig, [])
        sts.sort(key=lambda st: st.order[next(s for s, p in enumerate(st.pred) if p)])
        mandatory = [st for st in sts if not (st.kind == "phi" and all(st.pred) and len(set(st.afn)) == 1)]
        if len(mandatory) > len(evs):
            for st in mandatory[len(evs):]:
                reasons.append(f"C site {st.key[0]}:{st.key[1]} occurrence {st.key[3]} has no lowered gate left")
            sts = mandatory[:len(evs)]
        elif len(sts) > len(evs):
            sts = mandatory + [st for st in sts if st not in mandatory][:len(evs) - len(mandatory)]
            sts.sort(key=lambda st: st.order[next(s for s, p in enumerate(st.pred) if p)])
        for e in evs[len(sts):]:
            reasons.append(f"lowered gate #{e.idx} {e.label} (predicate {_fn(e.pred)}) corresponds to no C site")
        for st, e in zip(sts, evs):
            pairs[st.key] = e
    if reasons:
        return reasons
    # order: every sample's hit order agrees with the lowered order on dependent gates
    by_key = {st.key: st for st in sites}
    nS = len(ours[0].pred) if ours else 0
    for s in range(nS):
        seq = sorted((by_key[k].order[s], e) for k, e in pairs.items() if s in by_key[k].order)
        evs_s = [e for _, e in seq]
        for a in range(len(evs_s)):
            for b in range(a + 1, len(evs_s)):
                x, y = evs_s[a], evs_s[b]
                if x.idx > y.idx and (x.support & y.support):
                    reasons.append(f"sample {s}: C order puts {x.label} before {y.label}, the lowered order "
                                   f"reverses them and their supports overlap")
                    return reasons
    return reasons


# ---------------------------------------------------------------- driver

def _call_key(sample: Any) -> Hashable:
    return _skey(sample.get("call")) if isinstance(sample, dict) else ""


def compare(ours: Sequence[RunResult], other: Sequence[RunResult], against: str,
            classical_key: Optional[Callable[[Any], Hashable]] = None) -> List[str]:
    """§6 equality of `ours` and `other` over all samples; the reasons, empty when equal.

    `against` is "ref" (other = the reference lowered.ll in the evaluator) or "c" (other = the C
    oracle). `classical_key` (optional, e.g. classical_key_from_driver(spec)) gives the classical
    arguments of a sample; without it the classical group is the call, refined as always by the
    circuit structure of each side (see the module docstring)."""
    if against not in ("ref", "c"):
        raise CompareError(f"cq: unimplemented: chk-compare: against {against!r}")
    oracle = against
    nan_eq = against == "c"          # CR §2 NaN row: the C oracle is NaN-insensitive, the reference bit-exact
    ref = list(other)
    ours = list(ours)
    exact_classical = classical_key is not None
    if classical_key is None:
        classical_key = _call_key
    reasons: List[str] = []
    o_by = {_skey(r.sample): r for r in ours}
    r_by = {_skey(r.sample): r for r in ref}
    if len(o_by) != len(ours) or len(r_by) != len(ref):
        raise CompareError("cq: unimplemented: chk-compare: duplicate sample")
    for k in sorted(set(r_by) - set(o_by)):
        reasons.append(f"sample {k}: no run on our side")
    for k in sorted(set(o_by) - set(r_by)):
        reasons.append(f"sample {k}: no run on the oracle side")
    keys = [k for k in (_skey(r.sample) for r in ref) if k in o_by]
    if not keys and not reasons:
        reasons.append("no samples")

    # per sample: violations, outputs, measured values, frees
    for k in keys:
        o, r = o_by[k], r_by[k]
        if o.violations:
            reasons.append(f"sample {k}: violations on our side: {o.violations}")
        if r.violations:
            reasons.append(f"sample {k}: violations on the oracle side (a spec issue if it is the reference): "
                           f"{r.violations}")
        if _norm(o.outputs, nan_eq) != _norm(r.outputs, nan_eq):
            reasons.append(f"sample {k}: outputs {o.outputs} != {r.outputs}")
        mo, mr = list(o.measured or []), list(r.measured or [])
        if len(mo) != len(mr):
            reasons.append(f"sample {k}: {len(mo)} measurements != {len(mr)}")
        else:
            for i, (a, b) in enumerate(zip(mo, mr)):
                wa, wb = a.get("w"), b.get("w")
                if wa and wb and wa != wb:
                    reasons.append(f"sample {k}: measurement {i} of {wa} != {wb}")
                w = wa or wb or _kept_type(o, a.get("h")) or _kept_type(r, b.get("h"))
                if _fpv(_int(a.get("v")), w, nan_eq) != _fpv(_int(b.get("v")), w, nan_eq):
                    reasons.append(f"sample {k}: measurement {i} reads {a.get('v')} != {b.get('v')}")
        for side, rr in (("our", o), ("oracle", r)) if oracle == "ref" else (("our", o),):
            for c in rr.clean or []:
                known = c.get("known")
                if (known is not None and not _int(known)) or (known is None and _int(c.get("v")) != 0):
                    reasons.append(f"sample {k}: {side} side frees rail {c.get('h')} = {c.get('v')} "
                                   f"not in a known basis state")

    # groups: classical arguments, then the structure of each side
    by_class: Dict[Hashable, List[str]] = {}
    for k in keys:
        by_class.setdefault(classical_key(r_by[k].sample), []).append(k)
    groups: Dict[Tuple, List[str]] = {}
    for ck, ks in by_class.items():
        sides = (("our", o_by),) + ((("reference", r_by),) if oracle == "ref" else ())
        for name, by in sides:
            shapes = {_shape(by[k]) for k in ks}
            if exact_classical and len(shapes) > 1 and not any(by[k].measured for k in ks):
                reasons.append(f"classical arguments {ck}: the {name} circuit's structure varies with the quantum "
                               f"inputs and nothing is measured")
        for k in ks:
            gk = (ck, _shape(o_by[k]), _shape(r_by[k]) if oracle == "ref" else None)
            groups.setdefault(gk, []).append(k)
    if reasons:
        return reasons

    for gk, ks in groups.items():
        tag = f"classical arguments {gk[0]} ({len(ks)} samples)"
        o_runs = [o_by[k] for k in ks]
        r_runs = [r_by[k] for k in ks]
        o_evs, o_glob = _lowered_events(o_runs)
        if oracle == "ref":
            r_evs, _ = _lowered_events(r_runs)
            kept_o = _kept_multiset(o_runs)
            kept_r = _kept_multiset(r_runs)
            if kept_o != kept_r:
                for cls in sorted(set(kept_o) | set(kept_r), key=repr):
                    d = kept_o.get(cls, 0) - kept_r.get(cls, 0)
                    if d > 0:
                        reasons.append(f"{tag}: {d} rail(s) {cls[0]} with values {_fn(cls[1])} kept on our side "
                                       f"that the reference does not keep (it cleans them or never makes them)")
                    elif d < 0:
                        reasons.append(f"{tag}: {-d} rail(s) {cls[0]} with values {_fn(cls[1])} the reference "
                                       f"keeps are not kept on our side")
            why = _match_lists(o_evs, r_evs)
            if why:
                reasons.append(f"{tag}: rotation list differs: {why}")
        else:
            sites = _c_sites(r_runs, nan_eq)
            for why in _match_c(o_evs, o_glob, sites, nan_eq):
                reasons.append(f"{tag}: {why}")
    return reasons


def _kept_type(rr: RunResult, h: Any) -> Optional[str]:
    """The type of handle h in rr's kept list (a measured rail stays live), or None."""
    if h is None:
        return None
    for k in rr.kept or []:
        if k.get("h") == h and k.get("w"):
            return k["w"]
    return None


def _kept_multiset(runs: List[RunResult]) -> Dict[Tuple, int]:
    hs = [k["h"] for k in runs[0].kept or []]
    out: Dict[Tuple, int] = {}
    for h in hs:
        w = None
        vals = []
        for rr in runs:
            ent = next(k for k in rr.kept if k["h"] == h)
            w = w or ent.get("w")
            vals.append(_int(ent.get("v")))
        cls = (w, tuple(_masked(v, w) for v in vals))
        out[cls] = out.get(cls, 0) + 1
    return out
