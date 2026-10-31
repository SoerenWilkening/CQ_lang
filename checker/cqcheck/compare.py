"""§6 comparison (module chk-compare, bead cq-w0-chk-compare).

`compare(ours, other, against) -> List[str]` (frozen by cq-zew) decides CR §6 equality of two
sides, each a sequence of RunResults with one entry per sample, and returns the reasons they differ
(empty = §6-equal):

- against="ref": `other` is the reference lowered.ll run in the evaluator (§6 oracle (a)).
- against="c":   `other` is the C program run under the oracle (§6 oracle (b)).

What is compared (CR §6, CLAUDE.md "The §6 checker"):

- per sample: violations (none allowed on either side), named outputs, measured values, host
  output (below);
- every `cqrt_free` on our side sees a rail in a known classical basis state (CR §0);
- oracle "ref" only: kept rails (live at exit, every role, A4's kept_entangled included) as a
  multiset of (type, value function over the group's samples);
- the rotation list: (gate, target, angle or angle-rail value, control predicate per input), up to
  reordering of commuting gates (below) and renaming of rails. Rails are matched by (type,
  value function over the group's samples). A phase P(θ) on a flag is e^{iθ·f}: its predicate is the
  flag's value, whichever rail carries it. Global phases are dropped on both sides: a classical-angle
  phase whose predicate is constant over the group (never an Ry, never an angle-rail phase). Against
  the C oracle rotations are matched by site (bead cq-yonm): each lowered gate belongs to one
  (function, site) of `cq_theta`/`cq_phi`, and at every sample the gates of a site that fire there,
  in lowered order, are that site's reaches in that sample, each with the same angle (and register
  value, for theta). A site inside a loop is one gate per trip on the lowered side, and a trip that
  skips the call leaves no reach, so a site's k-th reach is not one gate across samples: a gate
  firing at a sample takes the site's earliest reach there not yet taken that agrees with it. Every
  reach must be taken, except phi reaches forming the same multiset of angles at every sample (a
  global phase). A dropped global phase may take its site's earliest reach not yet taken, or none
  (it keeps its place among the gates of its site). The pairs must be in an order consistent with
  every sample's hit order. One gate
  takes no C reach (bead cq-9gi3): CR rule 10's un-prep, by which a second prep of a rail nothing
  read since undoes the first by its adjoint under the conjunction flag. A lowered Ry (or
  angle-rail Ry) i reads as the un-prep of the earlier gate j when j takes a C reach, at every
  sample where i fires the latest gate on the target before i is j, i's angle is j's negated and
  the target holds its value at j, and i's predicate is exactly the overwrite predicate: j fires,
  no gate on the target fires between j and i, and a later gate on the target fires (the
  overwriting prep), each such first later gate taking a C reach. Anything else is unmatched. A
  `cq_invert` region (the
  sites between an invert_begin and its matching invert_end, nesting by depth) is read under CR rule
  17: its sites are taken in reverse order with their angles negated (a region inside a region is so
  inverted twice), both for matching and for the per-sample order. A marker without its partner in
  a sample is a difference, never skipped, except an invert_begin still open where an open-ended
  sample stops (it ended in noreturn/raise, or its cut lies inside the region; bead cq-088c): rule
  17 emits the whole region reversed, so the sites the sample reached in it are the region's last
  gates, reversed and negated, and the gates of the sites it did not reach come before them, unknown
  as past the end. Each open region is closed where the sample stops, innermost first.

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

Commutation (CR §6 item 2 as amended by the owner ruling on cq-vrwm, 2026-10-29). Two phases always
commute (both diagonal). Otherwise an Ry is ordered against every gate that acts on its target rail
or is non-diagonal on one of its controls: gates x and y are ordered when the target of one lies in
the support of the other (an Ry on the same rail, a phase or a controlled Ry whose predicate or
angle reads the target, an Ry on a rail the other's predicate reads). A phase whose predicate does
not read the Ry's target, and an Ry sharing only controls with another, commute with it (a
controlled Ry is block-diagonal in its controls' basis, as is e^{iθ·g} with g independent of the
target). Support being conservative on sampled groups, a classical-angle phase is also known not to
read the Ry's target when its flag rail is one of the Ry's control rails on the same side and its
predicate is a function of that control's value at the Ry over the group's samples (_diag_on_controls:
125's and 133's prep against the sibling arm's phase on the same flag).

RunResult contents consumed here (the frozen trace events of cq-arch, plus fields that make a
record self-contained; values are hex bit patterns or ints):

- rotations (lowered side): trace events in emission order,
    {"ev":"ry","h","theta","ctl":[h],"ctlv":[b]}, {"ev":"ry_qangle","h","a","aval","ctl","ctlv"},
    {"ev":"phase","f","fv","theta"}, {"ev":"phase_qangle","a","aval","ctl","ctlv"};
  an Ry record may carry "w" and "v" (the target's type and its value at the gate); missing, they
  are read from the target's entry in `kept` (a rotated rail is never written in place again).
- rotations (C oracle side, cq-arch T1): {"ev":"site","fn","site","kind","angle","reg"} per reached
  site of kind theta, phi, invert_begin or invert_end (the markers' angle and reg null), in
  execution order.
- kept: the exit event's live list, [{"h","w","v","role"}].
- clean: the free events, [{"h","v","known"}]. From run.py's compact trace (cq-8m6v): the setup's
  free events, the sample's dirty ones (tagged "shot"), then one summary {"freed": n, "fdig": hex}
  of all the sample's frees (count, FNV-1a-64 of the handles in order), which stands for them in the
  run's structure.
- measured: the measure events, [{"h","v"}] (a "w" is compared when both sides give one); the C
  side's records have "h" null.
- kept, clean: None on the C side (T1); read only on the lowered sides.
- outputs: any JSON (a dict of named outputs); hex strings compare as integers. A leaf that is a
  dict with a rail type "w" and a value "v" ({"w":"f32","v":"0x7fc00000"}) is a typed scalar: its
  value is compared at that width, and an fp one under the fp equality mode below. An untyped
  value carries no fp-ness and is compared bit for bit in both modes. Against the C oracle only
  outputs["ret"] and the host output are compared (T1 as amended by cq-e4jk: the C side's "end"
  and our "exit" are diagnostics); a missing "ret" reads as []. Against the reference
  outputs["stdout"] and outputs["effects"] are compared as host output and every other key as above.
- violations: a list; any entry fails the comparison.
- outputs["loops"] (C oracle side only; the cutoff records of the a_K rule below, bead cq-9rt): a
  list, missing = []. One record per activation of a quantum-exit loop or quantum-depth recursion
  that the C program begins:
    {"loop": id, "act": int, "n": int, "capped": bool, "cut": int, "mcut": int}
  loop is the T1 loop id "<fn>:<header>" (a recursion is "<fn>:recursion", cq-arch T2; compare reads
  it as an opaque string). act is the 0-based ordinal of this activation among the activations of
  the same loop in the sample, in execution order (a loop nested in a K-loop is entered once per
  outer trip, so act is the outer trip index when the inner loop is entered on every trip). n is
  the trips begun, as T1's trip event counts them. capped is true when the C program would run more
  than K trips (K as the circuit resolves it) and the oracle stopped it after trip K, i.e. the exit
  test after the K-th body (a_K) read 1. cut and mcut are required when capped and ignored
  otherwise: the length of `rotations` and of `measured` at the point of that test, i.e. the
  number of entries recorded through trip K. A loop the C program never enters gets no record. A
  capped run is not a violation: "violations" stays [], and "end" is the oracle's diagnostic (e.g.
  "cap:<loop>"). Whether the oracle stops the whole program at the cap or goes on is its choice;
  compare reads nothing past the earliest cut either way.

Host output (cq-e4jk; CR rule 16 and §1.3). outputs["stdout"] (str, missing = "") and
outputs["effects"] (missing = []) on every side: what the run printed and the host-effect calls it
made, each effect {"name", "args": [{"s": str} | {"w": "i<N>", "v": hex}]}. On ours and the
reference (run.py) stdout is the process's output followed by the tape's end-of-shot text, and
effects the module's direct host-effect calls followed by the effect entries the tape performed; on
the C side (oracle.py) they are the C program's stdout and its calls of the host-effect functions
(HOST_EFFECTS), in order. Both are compared exactly, args as typed scalars, against either oracle;
against the C oracle on a capped or ended sample (below) the C side's stdout and effects must be a
prefix of ours (the circuit runs on past the cut or the end). Against the C oracle an effect name of
ours outside HOST_EFFECTS is a CompareError (the C oracle logs no such call, so the comparison
could not be decided). A program that interleaves direct and taped output is compared in the
circuit's order (direct first, the tape at the end of the shot, CR §1.3).

The a_K rule (CR §6, ruling 2026-10-27, cq-1di; against="c" only). A sample is capped when one of
its loop records has capped true; its cut is that of the capped record with the smallest cut. On a
capped sample:
- outputs["ret"] is not compared (the compared outputs are the circuit's; the C program did not
  complete the trips);
- the C side's measured and rotations are truncated at the cut (the rotation list is compared
  through trip K); our first len(C measured) measurements are compared with them, ours may have
  more;
- a C site the truncated sample does not reach is unknown there, not "not reached": a lowered gate
  may fire there with any angle, except that a lowered gate that matches no C site and fires on a
  capped sample is still a difference when it precedes, in our order, a gate whose C site that
  sample reached and that it does not commute with (or, both phases, whose support it overlaps) (it
  would lie before the cut);
- a_K must read 1.
On a sample with no capped record everything is compared, and every a_K must read 0.
a_K is located on our side by value function, like every rail (CLAUDE.md): within each comparison
group, each (loop, act) capped on at least one sample of the group must be matched to its own kept
i1 rail of ours (role not measured, abort, tape, qram, qram_cell, qram_slot) that reads 1 on every
sample where it is capped, 0 on every uncapped sample and on every sample whose record of it says
capped false, and anything on a sample capped by another activation that has no record of it (it
lay past the cut). An activation never capped in a group cannot be told from other 0 rails there,
so its "a_K reads 0" is checked only in groups where it is capped somewhere. On an ended sample
(below) an activation with no record is unknown as well (the circuit runs on past the end).

The abort rule (CR rule 16 and §1.3, bead cq-ouml; against="c" only). A C sample ends early when
its outputs["end"] is "noreturn:<callee>" (abort, exit, __builtin_trap, any noreturn callee) or
"raise:<sig>" (a fatal signal with no handler). The circuit does not end there: rule 16 lowers the
call to abort_i1(pred), a kept flag the backend measures at the end of the shot, and the shot runs
on. On an ended sample:
- outputs["ret"] is not compared (the C program never returned);
- the C side's measured and rotations are complete up to the end and compared with ours as on a
  capped sample at its cut: our first len(C measured) measurements are compared with them, ours may
  have more, and a lowered gate may fire after the end with any angle (the same "precedes a
  reached gate" exception applies);
- ours must keep an i1 rail of role "abort" that reads 1.
On a sample that returns (neither ended nor capped) every kept abort-role i1 rail of ours reads 0.
A capped sample says nothing about abort flags (an abort past the cut is unknown). The abort
rails are read by role, which the evaluator sets on the operand of abort_i1 (BACKEND_ABI §1.2),
since an abort site that never fires in a group is otherwise indistinguishable from other 0 rails.

Floating-point equality (CR §2 NaN row, ruling 2026-10-27, bead cq-8dy). Against the reference
every value is compared bit for bit. Against the C oracle a floating-point value is compared
NaN-insensitively: any NaN equals any NaN (sign and payload ignored), a NaN never equals a
non-NaN. A value is floating point when its type is known: a typed output, a measured rail (its
"w", or the type of the same handle in `kept`), an Ry target's register (the target's type, at
which the C register value is read) and every classical angle (f64). An Ry with a non-finite
angle and an angle-rail gate with a non-finite angle are no gate in either mode (CR §1.3), so a
NaN angle survives only on a classical-angle phase (P(θ), C `cq_phi`), where the mode applies.
Measurements against the C oracle (CR rule 2, bead cq-tnrb). A cq_measure inside a quantum arm runs
unconditionally at its program point, so on a sample where the C program does not take the arm our
side measures once more. Within each comparison group each sample's C measurements are matched, in
order, to our measurements reading the same value (and type). One of ours left unmatched on a
sample must be identified on another sample: matched in every embedding of some sample of the same
call whose measured rails of ours are the same handles (the hoisted arm measurement of a register
the C program measures on another path; its value where C did not reach it is unconstrained), or
lie past the cut or the end of an open-ended sample. A measurement whose value never tells it from
another of ours is not identified (conservative). Every C measurement is matched. Against the
reference measurements are compared by position.

x87 f80: a NaN is exponent 0x7FFF with a nonzero fraction (bits 0..62), the explicit integer bit
ignored, so a pseudo-NaN is a NaN and a pseudo-infinity is not.
"""
from __future__ import annotations

import dataclasses
import functools
import json
import os
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, FrozenSet, Hashable, List, Optional, Sequence, Tuple

from .contracts import DriverSpec, RunResult


class CompareError(Exception):
    """A RunResult this module cannot read: an internal error of the checker, never a verdict."""


# The host-effect functions whose calls both sides log (cq-e4jk): run.py renames a lowered module's
# direct calls to checker/rt/host_fx.c's wrappers, the C oracle logs them at the call
# (OracleInstr.cpp, effects). Tape effect entries of these names are compared with them.
HOST_EFFECTS = ("remove", "unlink", "rename", "raise")


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


@functools.lru_cache(maxsize=None)
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


_PLAIN = re.compile(r'[ !#-\[\]-~]*')   # printable ASCII but '"' and '\\': json.dumps quotes it unchanged


def _skey(sample: Any) -> str:
    # fast paths with json.dumps's exact output (performance, cq-e2i9)
    if isinstance(sample, str) and _PLAIN.fullmatch(sample):
        return '"' + sample + '"'
    if type(sample) is int:
        return str(sample)
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


def _shape_of(rr: RunResult) -> Tuple:
    """The structure of one lowered run: everything but data values."""
    rots = []
    for rec in rr.rotations or []:
        ev = rec.get("ev")
        if ev not in _KIND:
            raise CompareError(f"cq: unimplemented: chk-compare: rotation event {rec!r}")
        theta = _int(rec.get("theta")) if ev in ("ry", "phase") else None
        rots.append((ev, rec.get("h"), rec.get("a"), rec.get("f"), tuple(rec.get("ctl", []) or []), theta))
    kept = tuple(sorted((k["h"], k.get("w")) for k in rr.kept or []))
    # every free in order: the setup's free events, then the sample's summary (run.py's compact trace,
    # cq-8m6v: the count and a digest of the handles), or the sample's free events when there is none
    clean = rr.clean or []
    summed = any("freed" in c for c in clean)
    freed = tuple((c["freed"], c["fdig"]) if "freed" in c else c["h"] for c in clean
                  if not (summed and c.get("shot")))
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
    flag: Optional[int] = None       # the flag rail of a classical-angle phase (ph)
    ctlfn: Dict[int, Tuple] = field(default_factory=dict)  # Ry: control rail -> its value per sample


def _kept_by_h(rr: RunResult, memo: Optional[Dict[int, Dict[Any, List[Dict[str, Any]]]]] = None
               ) -> Dict[Any, List[Dict[str, Any]]]:
    """The run's kept entries by handle, each handle's in kept order (performance, cq-8m6v)."""
    if memo is not None and id(rr) in memo:
        return memo[id(rr)]
    by: Dict[Any, List[Dict[str, Any]]] = {}
    for k in rr.kept or []:
        by.setdefault(k["h"], []).append(k)
    if memo is not None:
        memo[id(rr)] = by
    return by


def _target_value(rr: RunResult, rec: Dict[str, Any], kept_by: Optional[Dict[Any, List[Dict[str, Any]]]] = None
                  ) -> Tuple[Optional[str], int]:
    h = rec["h"]
    w = rec.get("w")
    v = rec.get("v")
    for k in (kept_by.get(h, ()) if kept_by is not None else rr.kept or []):
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
    if not varying:
        return frozenset(regs)       # varies with nothing we can name: depend on everything
    # Registers with the same values over the group (two versions of a rail no substitution
    # rewrote, a rail and its copy; cq-k19b) are one column: a function of one is a function of
    # the other, so a dependence on the column is one on each of them (conservative). Without
    # this the duplicate columns never form a full grid and the support falls back to every
    # varying register.
    same: Dict[Tuple, List[Any]] = {}
    for h in sorted(varying):
        same.setdefault(varying[h], []).append(h)
    names = [hs[0] for hs in same.values()]
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
        return frozenset(varying)
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
    return frozenset(m for h in dep for m in same[varying[h]])


def _lowered_events(runs: List[RunResult]) -> Tuple[List[_Ev], List[_Ev]]:
    """Gate events of one side over one group: (kept events, dropped global phases)."""
    n = len(runs[0].rotations or [])
    recs = [rr.rotations for rr in runs]
    S = range(len(runs))
    evs: List[_Ev] = []
    # One register version per Ry (owner note on cq-lvkq): with every cq_theta substituted, a rail
    # rotated again is a new value; each version's value function is that Ry's record. Versions are
    # named (rail, n); a support names the rail.
    regs: Dict[Tuple[int, int], Tuple] = {}
    nver: Dict[int, int] = {}
    kept_by = [_kept_by_h(rr) for rr in runs] if n else []
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
            # CR §2: ry/rz/phase with a non-finite angle (literal or angle rail) is the identity
            if theta is not None and _angle_identity(theta, nonfinite_is_identity=True):
                on = 0
            aval = None
            if kind in ("ryq", "phq"):
                aval = _int(rec["aval"]) & ((1 << 64) - 1)
                if _angle_identity(aval, nonfinite_is_identity=True):
                    on = 0
            fired.append(on)
            afn.append(aval if on else None)
            if kind in ("ry", "ryq"):
                w, v = _target_value(runs[s], rec, kept_by[s])
                tvals.append(v)
        target = r0.get("h") if kind in ("ry", "ryq") else None
        if target is not None:
            regs[(target, nver.get(target, 0))] = tuple(tvals)
            nver[target] = nver.get(target, 0) + 1
        ctlfn: Dict[int, Tuple] = {}
        if kind in ("ry", "ryq"):
            for k, c in enumerate(r0.get("ctl", []) or []):
                ctlfn[c] = tuple(int(bool(_int((recs[s][i].get("ctlv") or [])[k]))) for s in S)
        evs.append(_Ev(idx=i, kind=kind, target=target,
                       tclass=(w, tuple(tvals)) if target is not None else None,
                       theta=theta, afn=tuple(afn) if kind in ("ryq", "phq") else None,
                       pred=tuple(fired), label=_describe(r0),
                       flag=r0.get("f") if kind == "ph" else None, ctlfn=ctlfn))
    live, glob = [], []
    for e in evs:
        if not any(e.pred):
            continue
        if e.kind == "ph" and all(e.pred):
            glob.append(e)
            continue
        sup = {r for r, _ in _dep(e.pred, regs)}
        if e.target is not None:
            sup.add(e.target)
        if e.afn is not None:
            sup |= {r for r, _ in _dep(e.afn, regs)}
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


def _phase(e: _Ev) -> bool:
    """A diagonal gate: two phases commute whatever their supports (CR §6 at CQ_spec 744da1b)."""
    return e.kind in ("ph", "phq")


def _diag_on_controls(p: _Ev, y: _Ev) -> bool:
    """The phase p acts only through one of the Ry y's control rails: its flag rail is a control of
    y (on the same side) and its predicate is a function of that control's value at y over the
    group's samples. Then p is diagonal on y's controls and does not read y's target, so they
    commute (owner ruling cq-vrwm), whatever the conservative support says."""
    if p.kind != "ph" or y.kind not in ("ry", "ryq") or p.flag is None or p.flag == y.target:
        return False
    cv = y.ctlfn.get(p.flag)
    if cv is None:
        return False
    table: Dict[int, int] = {}
    return all(table.setdefault(c, f) == f for c, f in zip(cv, p.pred))


def _ordered(x: _Ev, y: _Ev) -> bool:
    """x and y do not commute (module docstring, Commutation; owner ruling cq-vrwm)."""
    if _phase(x) and _phase(y):
        return False
    if _diag_on_controls(x, y) or _diag_on_controls(y, x):
        return False
    return ((x.target is not None and x.target in y.support)
            or (y.target is not None and y.target in x.support))


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
            if any(_ordered(ref[k], r) for k in rem[:pos]):
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
    key: Tuple                       # (fn, site, kind): one C call site
    kind: str                        # theta | phi
    # per sample: the site's reaches in emission order, (position in that sample's hits, angle, raw register)
    occ: List[List[Tuple[int, Any, Optional[int]]]]


_MARKERS = ("invert_begin", "invert_end")


def _c_order(rr: RunResult, s: int, open_end: bool = False
             ) -> Tuple[List[Tuple[int, Dict[str, Any], bool]], List[str]]:
    """One C sample's theta/phi sites in emission order under CR rule 17: [(original position,
    record, negated)], and the reasons its markers do not pair up. `open_end`: the sample stops
    early (ended or cut), so a region still open there is closed at its end (module docstring)."""
    reasons: List[str] = []
    stack: List[List[Tuple[int, Dict[str, Any], bool]]] = [[]]
    for pos, rec in enumerate(rr.rotations or []):
        kind = rec.get("kind")
        if rec.get("ev") != "site" or kind not in ("theta", "phi") + _MARKERS:
            raise CompareError(f"cq: unimplemented: chk-compare: C-oracle rotation {rec!r}")
        if kind == "invert_begin":
            stack.append([])
        elif kind == "invert_end":
            if len(stack) == 1:
                reasons.append(f"sample {s}: C invert_end {rec.get('fn')}:{rec.get('site')} has no matching "
                               f"invert_begin")
                continue
            region = stack.pop()
            stack[-1].extend((p, r, not neg) for p, r, neg in reversed(region))
        else:
            stack[-1].append((pos, rec, False))
    if len(stack) > 1 and not open_end:
        reasons.append(f"sample {s}: {len(stack) - 1} C invert_begin(s) without a matching invert_end")
        return [], reasons
    while len(stack) > 1:
        region = stack.pop()
        stack[-1].extend((p, r, not neg) for p, r, neg in reversed(region))
    return stack[0], reasons


def _c_sites(runs: List[RunResult], nan_eq: bool, open_end: Sequence[bool] = ()
             ) -> Tuple[List[_Site], List[str]]:
    sites: Dict[Tuple, _Site] = {}
    reasons: List[str] = []
    nS = len(runs)
    for s, rr in enumerate(runs):
        seq, why = _c_order(rr, s, bool(open_end) and open_end[s])
        reasons += why
        for epos, (pos, rec, neg) in enumerate(seq):
            key = (rec["fn"], rec["site"], rec["kind"])
            ang = _int(rec["angle"]) & ((1 << 64) - 1)
            if neg:
                ang ^= 1 << 63
            if _angle_identity(ang, nonfinite_is_identity=True):     # CR §2: phase too
                continue
            st = sites.get(key)
            if st is None:
                st = sites[key] = _Site(key, rec["kind"], [[] for _ in range(nS)])
            st.occ[s].append((epos, _fpv(ang, "f64", nan_eq),
                              _int(rec.get("reg")) if rec["kind"] == "theta" else None))
    return [sites[k] for k in sorted(sites, key=repr)], reasons


def _unprep_partners(ours: List[_Ev]) -> List[Optional[Tuple[int, FrozenSet[int]]]]:
    """Per gate, its rule-10 un-prep reading (bead cq-9gi3), or None: (j, ks) when gate i is the
    adjoint of the earlier gate j and its predicate is exactly the overwrite predicate that rule 10
    implies. Lowered side only; _match_c additionally requires j and every k to take C reaches.

    Gate i (Ry or angle-rail Ry) reads as j's un-prep when, at every sample s where i fires, the
    latest gate on i's target before i that fires at s is j (one j for all such s, of i's kind),
    i's angle is j's negated, and the target holds the value it held at j; and i's predicate is,
    at every sample, exactly: j fires, no gate on the target between j and i fires, and a gate on
    the target after i fires (the overwriting prep k; ks collects the first such k per sample)."""
    out: List[Optional[Tuple[int, FrozenSet[int]]]] = [None] * len(ours)
    if not ours:
        return out
    nS = len(ours[0].pred)
    sign = 1 << 63

    def angle(e: _Ev, s: int) -> Optional[int]:
        return e.theta if e.kind == "ry" else e.afn[s]

    for i, e in enumerate(ours):
        if e.kind not in ("ry", "ryq") or e.target is None:
            continue
        on_t = [g for g, x in enumerate(ours) if x.target == e.target]
        before = [g for g in on_t if g < i]
        after = [g for g in on_t if g > i]
        j: Optional[int] = None
        ok = True
        for s in range(nS):
            if not e.pred[s]:
                continue
            last = next((g for g in reversed(before) if ours[g].pred[s]), None)
            if last is None or (j is not None and last != j):
                ok = False
                break
            j = last
        if not ok or j is None:
            continue
        p = ours[j]
        if p.kind != e.kind or p.tclass[0] != e.tclass[0]:
            continue
        for s in range(nS):
            if e.pred[s]:
                a, b = angle(e, s), angle(p, s)
                if a is None or b is None or a != (b ^ sign) or e.tclass[1][s] != p.tclass[1][s]:
                    ok = False
                    break
        if not ok:
            continue
        ks = set()
        for s in range(nS):
            between = any(ours[g].pred[s] for g in before if g > j)
            k = next((g for g in after if ours[g].pred[s]), None)
            implied = bool(p.pred[s]) and not between and k is not None
            if implied != bool(e.pred[s]):
                ok = False
                break
            if implied:
                ks.add(k)
        if ok:
            out[i] = (j, frozenset(ks))
    return out


MATCH_BUDGET = 20_000


class _OutOfBudget(Exception):
    pass


def _match_input(ours: List[_Ev], sites: List[_Site], nS: int, capped: List[bool], cands: List[List[int]],
                 ckind: List[str], free_ok: List[bool], partner, comm: List[set], full: List[Tuple],
                 nan_eq: bool) -> List[int]:
    """_match_c's search problem as native/match_c.cpp reads it: every value it compares interned to
    an id (equal values, equal ids), each gate's register comparisons per target width class."""
    ids: Dict[Any, int] = {}

    def iid(v: Any) -> int:
        k = (type(v) is str, v)
        got = ids.get(k)
        if got is None:
            got = ids[k] = len(ids)
        return got

    widths: Dict[Any, int] = {}
    for afn, rfn, w in full:
        widths.setdefault(w, len(widths))
    wlist = list(widths) or [None]   # at least one width class: the reader takes one id per class
    n = len(ours)
    need_ord = any(comm)
    data = [n, nS, len(sites), len(wlist), MATCH_BUDGET] + [1 if c else 0 for c in capped]
    for i, e in enumerate(ours):
        afn, rfn, w = full[i]
        sup = sorted(e.support)
        data += [1 if ckind[i] == "theta" else 0, 0, 1 if free_ok[i] else 0,
                 0 if e.target is None else 1, 0 if e.target is None else int(e.target), len(sup)]
        data += [int(r) for r in sup]
        data += [1 if e.pred[s] else 0 for s in range(nS)]
        data += [iid(afn[s]) for s in range(nS)]
        data += [iid(_fpv(rfn[s], w, nan_eq)) for s in range(nS)]
        data += [widths[w], len(cands[i])] + list(cands[i])
        if partner[i] is None:
            data += [-1, 0]
        else:
            data += [partner[i][0], len(partner[i][1])] + sorted(partner[i][1])
        data += [len(comm[i])] + sorted(comm[i])
        data += [1 if need_ord and k != i and _ordered(e, ours[k]) else 0 for k in range(n)]
    for st in sites:
        data.append(1 if st.kind == "theta" else 0)
        for s in range(nS):
            occ = st.occ[s]
            data.append(len(occ))
            for epos, a, r in occ:
                data += [epos, iid(a)] + [iid(_fpv(r, w, nan_eq)) for w in wlist]
    return data


def _match_c(ours: List[_Ev], glob: List[_Ev], sites: List[_Site], nan_eq: bool,
             capped: Sequence[bool] = ()) -> List[str]:
    """Match the C sites to our gates (module docstring). A site inside a loop is one gate per trip
    on our side, and a trip that skips the call leaves no C reach: so each lowered gate belongs to
    one site, and at each sample the gate, where it fires, takes the site's earliest reach not yet
    taken that agrees with it in angle (and register, for theta). Every reach must be taken, except
    a constant multiset of classical-angle phi reaches (a global phase). capped[s] marks a sample
    truncated at its cut (the a_K rule) or ended early (the abort rule): a gate firing there with no
    reach left lies past the cut or the end. A dropped global phase (`glob`) is not compared, but it
    stays in lowered order between the live gates, as its C reaches stay between theirs: it may take
    the site's earliest reach not yet taken, or none (bead cq-7bvs; without it a live gate of the
    same site would take that reach, out of order)."""
    reasons: List[str] = []
    capped = list(capped)
    opt_ids = {e.idx for e in glob}
    ours = sorted(list(ours) + list(glob), key=lambda e: e.idx)
    opt = [e.idx in opt_ids for e in ours]
    nS = len(capped) if capped else len(ours[0].pred) if ours else len(sites[0].occ) if sites else 0
    capped = capped or [False] * nS
    P = [s for s in range(nS) if not capped[s]]
    C = [s for s in range(nS) if capped[s]]

    def lfull(e: _Ev) -> Tuple:
        if e.afn is not None:
            afn = tuple(_fpv(a, "f64", nan_eq) for a in e.afn)
        else:
            afn = tuple(_fpv(e.theta, "f64", nan_eq) if p else None for p in e.pred)
        w = e.tclass[0] if e.target is not None else None
        rfn = e.tclass[1] if e.target is not None else tuple(None for _ in e.pred)
        return afn, rfn, w

    full = [lfull(e) for e in ours]
    ckind = ["theta" if e.kind in ("ry", "ryq") else "phi" for e in ours]
    cands = [[j for j, st in enumerate(sites) if st.kind == ckind[i]] for i in range(len(ours))]
    free_ok = [opt[i] or (not any(e.pred[s] for s in P) and bool(C))      # fires only on capped samples
               for i, e in enumerate(ours)]
    Used = Tuple[int, ...]           # per (site, sample) a bitmask of the reaches taken

    def take(i: int, j: int, used: Used, hits: Optional[List[List[Tuple[int, _Ev]]]] = None
             ) -> Optional[Used]:
        """Gate i taken by site j: the new state, or None (it disagrees, or takes no reach)."""
        e, st = ours[i], sites[j]
        afn, rfn, w = full[i]
        new: Optional[List[int]] = None
        for s in range(nS):
            if not e.pred[s]:
                continue
            m = used[j * nS + s]
            hit = None
            for t, (epos, a, r) in enumerate(st.occ[s]):
                if not (m >> t) & 1 and a == afn[s] and (st.kind != "theta" or _fpv(r, w, nan_eq) == _fpv(rfn[s], w, nan_eq)):
                    hit = t
                    break
            if hit is None:
                if capped[s]:
                    continue         # past the cut: unknown
                return None
            if new is None:
                new = list(used)
            new[j * nS + s] = m | (1 << hit)
            if hits is not None:
                hits[s].append((st.occ[s][hit][0], e))
        return tuple(new) if new is not None else None

    def leftover(used: Used) -> List[str]:
        """Reaches not taken that are not a global phase."""
        why: List[str] = []
        for j, st in enumerate(sites):
            left = [[(t, o) for t, o in enumerate(st.occ[s]) if not (used[j * nS + s] >> t) & 1]
                    for s in range(nS)]
            bad: List[Tuple[int, int]] = []
            if st.kind == "theta":
                bad = [(s, l[0][0]) for s, l in enumerate(left) if l]
            elif P:
                # a global phase: the same multiset at every uncapped sample, a part of it on a capped one
                cnt = [Counter(o[1] for _, o in l) for l in left]
                L = cnt[P[0]]
                for s in range(nS):
                    if (cnt[s] != L) if s in P else bool(cnt[s] - L):
                        diff = (cnt[s] - L) or (L - cnt[s])
                        t = next((t for t, o in left[s] if o[1] in diff), None)
                        if t is None:          # a reach this sample lacks: name it where it is left
                            s = P[0]
                            t = next(t for t, o in left[s] if o[1] in diff)
                        bad.append((s, t))
                        break
            else:
                if len({o[1] for l in left for _, o in l}) > 1:
                    bad = [(s, l[0][0]) for s, l in enumerate(left) if l]
            if bad:
                s, t = bad[0]
                reach = _fn([len(o) for o in st.occ])
                why.append(f"C site {st.key[0]}:{st.key[1]} ({st.kind}, reach {t} at sample {s}; reaches per "
                           f"sample {reach}) has no lowered gate with that predicate, angle and register")
        return why

    start: Used = tuple(0 for _ in range(len(sites) * nS))
    assign: List[Optional[int]] = [None] * len(ours)
    partner = _unprep_partners(ours)
    failed: set = set()
    limit = max(1000, 4 * len(ours) + 100)
    if sys.getrecursionlimit() < limit:
        sys.setrecursionlimit(limit)

    # unp: the gates read as rule-10 un-preps (no C reach of their own); free: the gates left
    # unmatched on capped samples. An un-prep's j and every k must take C reaches: j is checked
    # when i is chosen, the ks at the leaf. Both sets are part of the memo key.
    # Order (owner note): gates are taken in lowered order, so a gate's C reach must come after the
    # C reach of every earlier-taken gate it does not commute with at that sample (_ordered: the
    # target of one in the support of the other). ordst: per (rail, sample) the latest C position of
    # a taken gate whose support holds the rail, and of a taken gate targeting the rail. It is part
    # of the memo key.
    # A gate in some _diag_on_controls pair (comm) is recorded per gate in exc, keyed (rail, sample,
    # gate), so that its partners can skip it; every other gate only as the per-rail maximum.
    comm: List[set] = [set() for _ in ours]
    for a in range(len(ours)):
        for b in range(len(ours)):
            if a != b and _diag_on_controls(ours[a], ours[b]):
                comm[a].add(b)
                comm[b].add(a)

    def order_ok(i: int, picks: List[Tuple[int, int]], ordst: Tuple) -> Optional[Tuple]:
        e = ours[i]
        any_, tgt, exc = dict(ordst[0]), dict(ordst[1]), dict(ordst[2])
        for s, p in picks:
            lim = max((tgt.get((r, s), -1) for r in e.support), default=-1)
            if e.target is not None:
                lim = max(lim, any_.get((e.target, s), -1))
            for (r, s2, k), q in exc.items():
                if s2 == s and k not in comm[i] and q > lim and _ordered(e, ours[k]):
                    lim = q
            if p < lim:
                return None
            if comm[i]:
                for r in e.support:
                    if p > exc.get((r, s, i), -1):
                        exc[(r, s, i)] = p
                continue
            for r in e.support:
                if p > any_.get((r, s), -1):
                    any_[(r, s)] = p
            if e.target is not None and p > tgt.get((e.target, s), -1):
                tgt[(e.target, s)] = p
        return (tuple(sorted(any_.items())), tuple(sorted(tgt.items())), tuple(sorted(exc.items())))

    check_order = [True]
    # A node budget (narrow review): with the order state in the memo key, interchangeable gates make a
    # failing search factorial. Out of budget is a failure with that reason, never a pass.
    budget = [MATCH_BUDGET]

    def dfs(i: int, used: Used, unp: FrozenSet[int], free: FrozenSet[int], ordst: Tuple = ((), (), ())) -> bool:
        if i == len(ours):
            return not leftover(used) and not any(partner[u][1] & (unp | free) for u in unp)
        if (i, used, unp, free, ordst) in failed:
            return False
        budget[0] -= 1
        if budget[0] < 0:
            raise _OutOfBudget()
        for j in cands[i]:
            hl: List[List[Tuple[int, _Ev]]] = [[] for _ in range(nS)]
            nxt = take(i, j, used, hl)
            if nxt is not None:
                o2 = order_ok(i, [(s, p) for s in range(nS) for p, _ in hl[s]], ordst) if check_order[0] else ordst
                if o2 is None:
                    continue
                assign[i] = j
                if dfs(i + 1, nxt, unp, free, o2):
                    return True
        assign[i] = None
        if partner[i] is not None and partner[i][0] not in unp | free:
            if dfs(i + 1, used, unp | {i}, free, ordst):
                unprep.add(i)
                return True
        if free_ok[i]:
            if dfs(i + 1, used, unp, free | {i}, ordst):
                return True
        failed.add((i, used, unp, free, ordst))
        return False

    unprep: set = set()

    def search_py() -> Tuple[int, bool, bool, List[Optional[int]], set]:
        # First without the order (the memo then needs no order state, so the search stays small): if
        # no matching exists at all, the order cannot help. Then with the order, from scratch.
        check_order[0] = False
        budget[0] = float("inf")     # the order-free search keeps its old, unbudgeted memoized form
        found_any = dfs(0, start, frozenset(), frozenset())
        found = False
        if found_any:
            any_assign, any_unprep = list(assign), set(unprep)
            check_order[0] = True
            failed.clear()
            unprep.clear()
            budget[0] = MATCH_BUDGET
            try:
                found = dfs(0, start, frozenset(), frozenset())
            except _OutOfBudget:
                return 2, found_any, False, list(assign), set(unprep)
            if not found:
                assign[:] = any_assign
                unprep.clear()
                unprep.update(any_unprep)
        return 0, found_any, found, list(assign), set(unprep)

    # cq-8m6v: the same two searches in C++ (checker/native/match_c.cpp), node for node; the Python
    # search stays the reference: $CQ_MATCH=py runs it alone, $CQ_MATCH=check runs both and fails on
    # any difference
    mode = os.environ.get("CQ_MATCH", "native")
    if mode == "py":
        got = search_py()
    else:
        from cqcheck import native
        data = _match_input(ours, sites, nS, capped, cands, ckind, free_ok, partner, comm, full, nan_eq)
        got = native.match_c(data, len(ours))
        if mode == "check":
            want = search_py()
            if want != got:
                raise CompareError(f"cq: chk-compare: native matcher {got} != Python {want}")
    status, found_any, found, assign_, unprep_ = got
    assign[:] = assign_
    unprep.clear()
    unprep.update(unprep_)
    if status == 2:
        return [f"the matching of {len(ours)} lowered gates to the C sites exceeded {MATCH_BUDGET} search "
                f"nodes without an order-consistent matching"]
    if not found:
        if found_any:
            hits0: List[List[Tuple[int, _Ev]]] = [[] for _ in range(nS)]
            used0 = start
            for i in range(len(ours)):
                if assign[i] is not None:
                    used0 = take(i, assign[i], used0, hits0)
            for s in range(nS):
                evs_s = [e for _, e in sorted(hits0[s], key=lambda t: t[0])]
                for a in range(len(evs_s)):
                    for b in range(a + 1, len(evs_s)):
                        x, y = evs_s[a], evs_s[b]
                        if x.idx > y.idx and _ordered(x, y):
                            return [f"sample {s}: C order puts {x.label} before {y.label}, the lowered order "
                                    f"reverses them and they do not commute (no matching keeps the C order)"]
        check_order[0] = True
        # diagnose with the greedy assignment
        used = start
        for i, e in enumerate(ours):
            for j in cands[i]:
                nxt = take(i, j, used)
                if nxt is not None:
                    used = nxt
                    break
            else:
                if not free_ok[i] and partner[i] is None:
                    reasons.append(f"lowered gate #{e.idx} {e.label} (predicate {_fn(e.pred)}) corresponds to "
                                   f"no C site")
        reasons += leftover(used)
        return reasons or ["the lowered gates and the C sites admit no matching"]

    hits: List[List[Tuple[int, _Ev]]] = [[] for _ in range(nS)]
    used = start
    for i in range(len(ours)):
        if assign[i] is not None:
            used = take(i, assign[i], used, hits)
    # an unmatched gate on a capped sample must not precede a dependent gate that sample reached
    for i, x in enumerate(ours):
        if assign[i] is not None or i in unprep or opt[i]:
            continue
        for s in C:
            if not x.pred[s]:
                continue
            for _, e in hits[s]:
                if e.idx > x.idx and (_ordered(x, e) or (_phase(x) and _phase(e) and x.support & e.support)):
                    reasons.append(f"sample {s}: lowered gate #{x.idx} {x.label} corresponds to no C site and "
                                   f"precedes {e.label}, which the C program reached before the cut")
                    return reasons
    # order: every sample's hit order agrees with the lowered order on dependent gates
    for s in range(nS):
        evs_s = [e for _, e in sorted(hits[s], key=lambda t: t[0])]
        for a in range(len(evs_s)):
            for b in range(a + 1, len(evs_s)):
                x, y = evs_s[a], evs_s[b]
                if x.idx > y.idx and _ordered(x, y):
                    reasons.append(f"sample {s}: C order puts {x.label} before {y.label}, the lowered order "
                                   f"reverses them and they do not commute")
                    return reasons
    return reasons


# ---------------------------------------------------------------- the a_K rule (against "c")

_NOT_AK_ROLES = ("measured", "abort", "tape", "qram", "qram_cell", "qram_slot")


def _loops(rr: RunResult) -> List[Dict[str, Any]]:
    """outputs["loops"] of a side 'c' RunResult, validated (module docstring)."""
    out = rr.outputs.get("loops", []) if isinstance(rr.outputs, dict) else []
    if not isinstance(out, list):
        raise CompareError(f"cq: unimplemented: chk-compare: C-oracle loops {out!r}")
    for rec in out:
        ok = (isinstance(rec, dict) and isinstance(rec.get("loop"), str) and isinstance(rec.get("act"), int)
              and isinstance(rec.get("n"), int) and isinstance(rec.get("capped"), bool))
        if ok and rec["capped"]:
            ok = all(isinstance(rec.get(f), int) and not isinstance(rec.get(f), bool) and rec[f] >= 0
                     for f in ("cut", "mcut"))
        if not ok:
            raise CompareError(f"cq: unimplemented: chk-compare: C-oracle loop record {rec!r}")
    return out


def _cap(rr: RunResult) -> Optional[Dict[str, Any]]:
    """The capped record with the smallest cut, or None for a sample with at most K trips."""
    caps = [r for r in _loops(rr) if r["capped"]]
    return min(caps, key=lambda r: (r["cut"], r["mcut"])) if caps else None


def _truncate(rr: RunResult, cap: Dict[str, Any]) -> RunResult:
    rots, meas = list(rr.rotations or []), list(rr.measured or [])
    if cap["cut"] > len(rots) or cap["mcut"] > len(meas):
        raise CompareError(f"cq: unimplemented: chk-compare: C-oracle cut {cap!r} past the recorded "
                           f"{len(rots)} rotations / {len(meas)} measurements")
    return dataclasses.replace(rr, rotations=rots[:cap["cut"]], measured=meas[:cap["mcut"]])


def _check_ak(o_runs: List[RunResult], c_runs: List[RunResult], ended: Sequence[bool] = ()) -> List[str]:
    """Each (loop, act) capped somewhere in the group has its own kept i1 rail of ours reading
    1 where capped, 0 where it is known to have at most K trips (module docstring)."""
    caps = [_cap(rr) for rr in c_runs]
    recs = [{(r["loop"], r["act"]): r["capped"] for r in _loops(rr)} for rr in c_runs]
    keys = sorted({k for rec in recs for k, c in rec.items() if c})
    if not keys:
        return []
    want: Dict[Tuple, List[Optional[int]]] = {}
    for k in keys:
        f: List[Optional[int]] = []
        for s, rec in enumerate(recs):
            if k in rec:
                f.append(int(rec[k]))
            elif caps[s] is None and not (ended and ended[s]):
                f.append(0)
            else:
                f.append(None)       # past another activation's cut: unknown
        want[k] = f
    cands: Dict[Any, Tuple] = {}
    for ent in o_runs[0].kept or []:
        if ent.get("w") != "i1" or ent.get("role") in _NOT_AK_ROLES:
            continue
        h = ent["h"]
        vals = []
        for rr in o_runs:
            e2 = next((e for e in rr.kept or [] if e["h"] == h), None)
            if e2 is None:
                break
            vals.append(_masked(_int(e2.get("v")), "i1"))
        else:
            cands[h] = tuple(vals)
    fits = {k: [h for h, v in cands.items() if all(x is None or x == y for x, y in zip(want[k], v))]
            for k in keys}
    owner: Dict[Any, Tuple] = {}

    def augment(k: Tuple, seen: set) -> bool:
        for h in fits[k]:
            if h in seen:
                continue
            seen.add(h)
            if h not in owner or augment(owner[h], seen):
                owner[h] = k
                return True
        return False

    reasons = []
    for k in keys:
        if not augment(k, set()):
            f = "".join("-" if x is None else str(x) for x in want[k])
            reasons.append(f"a_K of loop {k[0]} activation {k[1]}: no kept i1 rail of ours (of its own) reads "
                           f"{f} (1 where the C oracle capped it after K trips, 0 where it ran at most K trips)")
    return reasons


# ---------------------------------------------------------------- the abort rule (against "c")

_ENDS = ("noreturn:", "raise:")


def _ended(rr: RunResult) -> bool:
    """A C sample that ended in a noreturn call or a fatal raise (module docstring)."""
    end = rr.outputs.get("end") if isinstance(rr.outputs, dict) else None
    return isinstance(end, str) and end.startswith(_ENDS)


def _check_abort(o_runs: List[RunResult], ended: Sequence[bool], capped: Sequence[bool]) -> List[str]:
    """Some kept abort-role i1 rail of ours reads 1 on every ended sample; every one reads 0 on
    every sample that returns (module docstring)."""
    flags: Dict[Any, List[int]] = {}
    for s, rr in enumerate(o_runs):
        for ent in rr.kept or []:
            if ent.get("w") == "i1" and ent.get("role") == "abort":
                flags.setdefault(ent["h"], [0] * len(o_runs))[s] = _masked(_int(ent.get("v")), "i1")
    reasons = []
    for s in range(len(o_runs)):
        on = [h for h, v in flags.items() if v[s]]
        if ended[s] and not on:
            reasons.append(f"sample {_skey(o_runs[s].sample)}: the C program ends early (noreturn or fatal raise) "
                           f"and no kept abort flag of ours reads 1")
        elif not ended[s] and not capped[s] and on:
            reasons.append(f"sample {_skey(o_runs[s].sample)}: the C program returns and our abort flag(s) "
                           f"{on} read 1")
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
    # the a_K rule: a capped C sample is read through its cut (module docstring)
    capped: Dict[str, bool] = {}
    ended: Dict[str, bool] = {}          # the abort rule: a C sample that ended in noreturn/raise
    if oracle == "c":
        for k in keys:
            ended[k] = _ended(r_by[k])
            cap = _cap(r_by[k])
            capped[k] = cap is not None
            if cap is not None:
                r_by[k] = _truncate(r_by[k], cap)      # a cut inside a cq_invert region closes it (cq-088c)

    # per sample: violations, outputs, measured values, frees
    meas_opts: Dict[str, List[Tuple[FrozenSet[int], FrozenSet[int]]]] = {}
    for k in keys:
        o, r = o_by[k], r_by[k]
        if o.violations:
            reasons.append(f"sample {k}: violations on our side: {o.violations}")
        if r.violations:
            reasons.append(f"sample {k}: violations on the oracle side (a spec issue if it is the reference): "
                           f"{r.violations}")
        if oracle == "c":
            oo, ro = _ret(o.outputs, "our"), _ret(r.outputs, "C-oracle")
            if not (capped[k] or ended[k]) and _norm(oo, nan_eq) != _norm(ro, nan_eq):
                reasons.append(f"sample {k}: returns {oo} != {ro} (ours {o.outputs}, C {r.outputs})")
        elif _norm(_rest(o.outputs, "our"), nan_eq) != _norm(_rest(r.outputs, "reference"), nan_eq):
            reasons.append(f"sample {k}: outputs {o.outputs} != {r.outputs}")
        reasons += _host_output(k, o.outputs, r.outputs, oracle,
                                oracle == "c" and (capped[k] or ended[k]))
        if oracle == "ref":
            reasons += _measured_positional(k, o, r, False, nan_eq)
        else:
            meas_opts[k], why = _meas_options(k, o, r, capped[k] or ended[k], nan_eq)
            reasons += why
        for side, rr in (("our", o), ("oracle", r)) if oracle == "ref" else (("our", o),):
            for c in rr.clean or []:
                if "freed" in c:
                    continue           # the compact trace's summary of the sample's frees (run.py)
                known = c.get("known")
                if (known is not None and not _int(known)) or (known is None and _int(c.get("v")) != 0):
                    reasons.append(f"sample {k}: {side} side frees rail {c.get('h')} = {c.get('v')} "
                                   f"not in a known basis state")

    # groups: classical arguments, then the structure of each side
    shape_of: Dict[int, Tuple] = {}

    def _shape(rr: RunResult) -> Tuple:          # each run's shape once (performance, cq-e2i9)
        sh = shape_of.get(id(rr))
        if sh is None:
            sh = shape_of[id(rr)] = _shape_of(rr)
        return sh

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

    # CR rule 2 against C (bead cq-tnrb): one of our measurements may go unmatched on a sample only
    # when it is identified elsewhere: matched in every embedding of some sample of the same call
    # with the same measured rails of ours (the C program measures that register on another path)
    ident: Dict[Tuple, set] = {}

    def _pool(k: str) -> Tuple:
        return (_call_key(r_by[k].sample), tuple(m.get("h") for m in o_by[k].measured or []))

    for k, opts in meas_opts.items():
        ident.setdefault(_pool(k), set()).update(frozenset.intersection(*(img for img, _ in opts)))

    def _meas_extra(k: str) -> List[str]:
        n = len(o_by[k].measured or [])
        known = ident[_pool(k)]
        opts = meas_opts[k]
        if any(all(i in img or i in past or i in known for i in range(n)) for img, past in opts):
            return []
        img, past = opts[0]
        bad = [i for i in range(n) if i not in img and i not in past and i not in known]
        hs = [o_by[k].measured[i].get("h") for i in bad]
        return [f"sample {k}: our measurement(s) {bad} (rails {hs}) match no C measurement here, and no sample "
                f"of the call identifies them with one the C program reaches (only CR rule 2's hoisted arm "
                f"measurement may be extra)"]

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
            sites, why_c = _c_sites(r_runs, nan_eq, [capped[k] or ended[k] for k in ks])
            if why_c:
                reasons += [f"{tag}: {why}" for why in why_c]
                continue
            for why in _match_c(o_evs, o_glob, sites, nan_eq, [capped[k] or ended[k] for k in ks]):
                reasons.append(f"{tag}: {why}")
            for why in _check_ak(o_runs, r_runs, [ended[k] for k in ks]):
                reasons.append(f"{tag}: {why}")
            for why in _check_abort(o_runs, [ended[k] for k in ks], [capped[k] for k in ks]):
                reasons.append(f"{tag}: {why}")
            for k in ks:
                for why in _meas_extra(k):
                    reasons.append(f"{tag}: {why}")
    return reasons


def _meas_eq(o: RunResult, r: RunResult, a: Dict[str, Any], b: Dict[str, Any], nan_eq: bool) -> List[str]:
    """Why our measurement record a differs from the oracle's b ([] when equal)."""
    wa, wb = a.get("w"), b.get("w")
    if wa and wb and wa != wb:
        return [f"of {wa} != {wb}"]
    w = wa or wb or _kept_type(o, a.get("h")) or _kept_type(r, b.get("h"))
    if _fpv(_int(a.get("v")), w, nan_eq) != _fpv(_int(b.get("v")), w, nan_eq):
        return [f"reads {a.get('v')} != {b.get('v')}"]
    return []


def _measured_positional(k: str, o: RunResult, r: RunResult, open_end: bool, nan_eq: bool) -> List[str]:
    """Measurements compared by position (against the reference; and the diagnostic against C). On an
    open-ended sample (capped or ended) ours may measure past the cut or the end."""
    mo, mr = list(o.measured or []), list(r.measured or [])
    if open_end and len(mo) >= len(mr):
        mo = mo[:len(mr)]
    if len(mo) != len(mr):
        return [f"sample {k}: {len(mo)} measurements != {len(mr)}"]
    return [f"sample {k}: measurement {i} {why}"
            for i, (a, b) in enumerate(zip(mo, mr)) for why in _meas_eq(o, r, a, b, nan_eq)]


_MEAS_OPTIONS = 256                  # embeddings of one sample's C measurements kept at most


def _meas_options(k: str, o: RunResult, r: RunResult, open_end: bool, nan_eq: bool
                  ) -> Tuple[List[Tuple[FrozenSet[int], FrozenSet[int]]], List[str]]:
    """CR rule 2 (bead cq-tnrb): the ways one sample's C measurements embed, in order, into ours,
    each one reading the same value (and type): [(our indices matched, our indices past the end)],
    the latter non-empty only on an open-ended sample (capped or ended: ours past the last matched
    one lie past the cut or the end). No way at all: the reasons."""
    mo, mr = list(o.measured or []), list(r.measured or [])
    n = len(mo)
    ok = [[not _meas_eq(o, r, a, b, nan_eq) for b in mr] for a in mo]
    opts: Dict[FrozenSet[int], FrozenSet[int]] = {}

    def emb(j: int, i0: int, img: Tuple[int, ...]) -> None:
        if len(opts) > _MEAS_OPTIONS:
            raise CompareError(f"cq: unimplemented: chk-compare: sample {k}: more than {_MEAS_OPTIONS} ways to "
                               f"match the C measurements to ours")
        if j == len(mr):
            last = img[-1] if img else -1
            opts[frozenset(img)] = frozenset(range(last + 1, n)) if open_end else frozenset()
            return
        for i in range(i0, n - (len(mr) - j) + 1):
            if ok[i][j]:
                emb(j + 1, i + 1, img + (i,))

    emb(0, 0, ())
    if opts:
        return list(opts.items()), []
    why = _measured_positional(k, o, r, open_end, nan_eq)
    if not why or (len(mo) > len(mr) and not open_end):
        why = [f"sample {k}: the C measurements {[b.get('v') for b in mr]} are no in-order subsequence of ours "
               f"{[a.get('v') for a in mo]}"]
    return [], why


def _ret(outputs: Any, side: str) -> Any:
    """outputs["ret"] of one side (against the C oracle, T1); a missing "ret" is []."""
    if outputs is None:
        return []
    if not isinstance(outputs, dict):
        raise CompareError(f"cq: unimplemented: chk-compare: {side} outputs {outputs!r} are not a dict")
    return outputs.get("ret", [])


_HOST_KEYS = ("stdout", "effects")


def _rest(outputs: Any, side: str) -> Any:
    """outputs without the host output (compared by _host_output)."""
    if isinstance(outputs, dict):
        return {k: v for k, v in outputs.items() if k not in _HOST_KEYS}
    return outputs


def _host(outputs: Any, side: str) -> Tuple[str, List[Any]]:
    """(stdout, effects) of one side's outputs (module docstring, Host output)."""
    if outputs is None:
        return "", []
    if not isinstance(outputs, dict):
        raise CompareError(f"cq: unimplemented: chk-compare: {side} outputs {outputs!r} are not a dict")
    out, fx = outputs.get("stdout", ""), outputs.get("effects", [])
    if not isinstance(out, str) or not isinstance(fx, list) or not all(
            isinstance(e, dict) and isinstance(e.get("name"), str) and isinstance(e.get("args"), list) for e in fx):
        raise CompareError(f"cq: unimplemented: chk-compare: {side} host output {out!r} {fx!r} is malformed")
    return out, fx


def _host_output(k: str, o_out: Any, r_out: Any, oracle: str, open_end: bool) -> List[str]:
    """The host-output reasons of one sample (module docstring, Host output)."""
    other = "C" if oracle == "c" else "reference"
    (os_, ofx), (rs, rfx) = _host(o_out, "our"), _host(r_out, other)
    if oracle == "c":
        bad = sorted({e["name"] for e in ofx} - set(HOST_EFFECTS))
        if bad:
            raise CompareError(f"cq: unimplemented: chk-compare: sample {k}: host effect(s) {bad} of ours have no "
                               f"C-oracle log (HOST_EFFECTS {list(HOST_EFFECTS)})")
    why = []
    if os_ != rs and not (open_end and os_.startswith(rs)):
        why.append(f"sample {k}: host stdout differs: ours {os_!r} != {other} {rs!r}"
                   + (" (the C output must be a prefix of ours on a capped or ended sample)" if open_end else ""))
    nf, nr = _norm(ofx), _norm(rfx)
    if nf != nr and not (open_end and nf[:len(nr)] == nr):
        why.append(f"sample {k}: host effects differ: ours {ofx} != {other} {rfx}"
                   + (" (the C effects must be a prefix of ours on a capped or ended sample)" if open_end else ""))
    return why


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
    by = [_kept_by_h(rr) for rr in runs]
    for h in hs:
        w = None
        vals = []
        for rr, b in zip(runs, by):
            if h not in b:
                raise StopIteration          # as next() over no entry raised it
            ent = b[h][0]
            w = w or ent.get("w")
            vals.append(_int(ent.get("v")))
        cls = (w, tuple(_masked(v, w) for v in vals))
        out[cls] = out.get(cls, 0) + 1
    return out
