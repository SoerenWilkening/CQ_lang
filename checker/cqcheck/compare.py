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
- oracle "c" only: the leak rule (CR §6 item 1, cq-tt2j): every rail of ours live at exit is a
  frozen register, a measured value, an effect entry's result, a result or a rule-kept rail (_leaks
  below);
- per sample against both oracles: the named outputs in memory (below, "Memory");
- the rotation list: (gate, target, angle or angle-rail value, control predicate per input), up to
  reordering of commuting gates (below) and renaming of rails. Rails are matched by (type,
  value function over the group's samples). Each Ry acts on a rail whose basis value just before
  the gate (the record's "pre", where it fires) is part of the gate (owner ruling 2026-11-02 on
  cq-3o3v): against the reference both sides' pre-values must agree per sample, against the C
  oracle the pre-value must equal the C register's value at the matching cq_theta site before the C
  side substituted it (the site event's "pre"). The value after the gate is the substituted reach's
  on both sides, so without this a wrong value under an Ry would be invisible. A phase P(θ) on a flag is e^{iθ·f}: its predicate is the
  flag's value, whichever rail carries it. Global phases are dropped on both sides: a classical-angle
  phase whose predicate is constant over the group, or a function of the outcomes measured before it
  (owner ruling 2026-11-02 on cq-459d: after the collapse it is global within each outcome branch;
  the classical arguments are the group's) (never an Ry, never an angle-rail phase). Against
  the reference phases are compared as a TOTAL, never one gate at a time (CR §6 item 2, ruling
  2026-11-01 on cq-u2mw): the Ry gates are matched one to one, and between them the running
  difference Δ = Σ θ_k·f_k (ours) − Σ θ_k·f_k (reference) per sample (an angle-rail phase adds its
  rail's value where it fires), summed exactly over the f64 angles and read mod 2π (a nonzero multiple
  of 2π within 2^-44 of the terms' magnitude; 0 exactly otherwise), must commute with every Ry paired
  (constant, or not reading its target, aside from phases on its own controls as below) and be 0 on
  every sample at the end, or constant there when the angle rails contribute 0 to it (a global phase
  of classical-angle phases). So one phase on a disjunction of pairwise-disjoint predicates equals the
  per-edge phases of the same angle (117); see _match_lists. Against
  the C oracle the phases are compared as a total too (bead cq-3q60, _phase_total_c: the running
  difference of our phases and the C program's cq_phi reaches must commute with each matched Ry and
  be 0, or a global constant, at the end; a capped sample through its cut), and the Ry gates are
  matched by site (bead cq-yonm; the site rules below were written for phases too, which no longer
  take sites): each lowered gate belongs to one
  (function, site) of `cq_theta`/`cq_phi`, and at every sample the gates of a site that fire there,
  in lowered order, are that site's reaches in that sample, each with the same angle (and register
  value, for theta). A site inside a loop is one gate per trip on the lowered side, and a trip that
  skips the call leaves no reach, so a site's k-th reach is not one gate across samples: a gate
  firing at a sample takes the site's earliest reach there not yet taken that agrees with it. Every
  reach must be taken, except phi reaches forming the same multiset of angles at every sample (a
  global phase), the multiset keyed by the outcomes measured before each reach and compared over the
  samples whose outcomes begin so (cq-459d). A dropped global phase may take its site's earliest reach not yet taken, or none
  (it keeps its place among the gates of its site). The pairs must be in an order consistent with
  every sample's hit order. One gate
  takes no C reach (bead cq-9gi3): CR rule 10's un-prep, by which a second prep of a rail nothing
  read since undoes the first by its adjoint under the conjunction flag. A lowered Ry (or
  angle-rail Ry) i reads as the un-prep of the earlier gate j when j takes a C reach, at every
  sample where i fires the latest gate on the target before i is j, i's angle is j's negated and
  the target holds its value at j, and i's predicate is exactly the overwrite predicate: j fires,
  no gate on the target fires between j and i, and a later gate on the target fires (the
  overwriting prep), each such first later gate taking a C reach. An Ry whose angle is the identity
  where its control fires (CR §1.3) is no gate and takes no reach, but still counts as a gate on its
  target there for this reading (bead cq-mopw). Every k, idle or not, stands only where the C
  program overwrites j's reach by a reach of k's angle and register value: the next reach after
  j's of a site of the same register (one SSA web of the .O1.ll, `registers`) that seeds it afresh
  (not an in-place cq_theta of j's value), at one site over the samples, each such reach backing one
  k (beads cq-q15r, cq-ia96, cq-yzuc). Anything else is unmatched. A
  `cq_invert` region (the
  sites between an invert_begin and its matching invert_end, nesting by depth) is read under CR rule
  17: its sites are taken in reverse order with their angles negated (a region inside a region is so
  inverted twice), both for matching and for the per-sample order; a C measurement while a region is
  open emits the sites reached so far forward first (BACKEND_ABI 1.13 flush, region_emission). A marker without its partner in
  a sample is read by CR rule 17 (2026-11-02, cq-asfn: a marker inside a quantum arm whose match is outside
  the arm): an invert_end with no open region closes nothing, and an invert_begin still open where the
  sample stops (its end in the other arm; or the sample ended in noreturn/raise, or its cut lies inside the
  region, bead cq-088c) holds the rest of the sample: rule 17 emits the whole region reversed, so the sites
  the sample reached in it are the region's last gates, reversed and negated. Each open region is closed
  where the sample stops, innermost first.

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
  are read from the target's entry in `kept` (a rotated rail is never written in place again); a
  firing Ry's record carries "pre", the target's value just before the gate (cq-3o3v; missing
  reads as None, which equals only a missing one on the other side).
- rotations (C oracle side, cq-arch T1): {"ev":"site","fn","site","kind","angle","reg"[,"pre"]} per
  reached site of kind theta, phi, invert_begin or invert_end (the markers' angle and reg null; a
  theta site's "pre" its register before the substitution, cq-3o3v), in
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
  list, missing = []. One record per activation (act: its identity over the samples, the call sites leading
  to it and the how-many-th there, cqo_rt.c next_act; no order) of a quantum-exit loop or quantum-depth recursion
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

Memory (CR §6 item 1, flat memory). outputs["mem"] on every side: the driver's named outputs read
after the call (drivers.py "Driver objects"), each {"name", "addr", "w", "v"[, "off"]}, "w" the width
of little-endian value "v" in bits (i8, i32, i<8n>; an f<N> or bf16 token its storage bytes) and "off"
its offset in the object (default 0). They are compared per (name, byte offset), byte for byte
(fp NaN-insensitivity has no place here: nothing types the bytes). A name one side lacks differs.
Against the C oracle a capped or ended sample has no outputs to compare, as for "ret". Which order a
copy wrote its bytes in (CR rule 22) cannot show. An uninitialized cell of a host-resident local is
in no output.

Pointers (CR §6: compared only relationally; host addresses differ per run). A value of an i64 rail
or an aligned word in a named output that lies in a known object of its own run reads as
("name", offset): outputs["objects"] (globals and functions, {"name", "addr", "size"}) and the
outputs["mem"] entries themselves. One in a run's outputs["regions"] ({"name", "lo", "hi"}; the
allocation arena "heap" and the "stack") reads as ("heap", offset from lo) against the reference,
and as the one class "<mem>" against the C oracle, where a local lives on the stack that lives in the
arena on our side. Every other value is itself. So a kept rail or a cell holding the address of
another object than the reference's differs, and so does one holding a data word.

Host output (cq-e4jk; CR rule 16 and §1.3). outputs["stdout"] (str, missing = "") and
outputs["effects"] (missing = []) on every side: what the run printed and the host-effect calls it
made, each effect {"name", "args": [{"s": str} | {"w": "i<N>", "v": hex}]}. On ours and the
reference (run.py) stdout is the process's output followed by the tape's end-of-shot text, and
effects the module's direct host-effect calls followed by the effect entries the tape performed; on
the C side (oracle.py) they are the C program's stdout and its direct host calls (raise and the
stand-ins, drivers.effect_callees), in order; ours hold only entries whose predicate read 1 with no
earlier abort reading 1 (rt_tape.c). Both are compared exactly, args as typed scalars with the bytes
captured ("cap") and pointer-valued ones relationally (above), against either oracle (rulings Q8).
Against the reference outputs["tape"], the shot's whole event sequence (name or format, predicate,
fields, order, performed, text, result; never the evaluator's class), is compared too. A sample
with outputs["deviation"] true (a deferred entry whose result the program reads: rt_tape.c) is rule 16's
stated deviation: excluded from the C-oracle comparison on that input (rulings Q8), the reference
comparison stands;
against the C oracle on a capped sample (below) the C side's stdout and effects must be a prefix of
ours (the circuit runs on past the cut). On an ended sample they are compared exactly (owner ruling
2026-11-02, cq-64lv): every host effect after an abort under a quantum predicate is a tape entry, and
the backend performs no entry after an abort flag reading 1 (CR §1.3). A program that interleaves direct and taped output is compared in the
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
i1 rail of ours (role not measured, abort, tape, tape_slot, overtaken) that reads 1 on every
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
- ours must keep an i1 rail of role "abort" that reads 1; or, on a "raise:<sig>" sample, have an effect
  entry raise performed (rule 16's signal table: the complement branch, 102, 212), past which the
  stand-in's shot runs on, so the C side's effects are a prefix of ours there; or have itself ended in
  the host call (outputs["host_end"]): a noreturn callee with classical arguments and no quantum
  predicate is rule 16's ordinary host call, made as it stands, so the circuit does end there.
On a sample that returns (neither ended nor capped) every kept abort-role i1 rail of ours reads 0, and
ours has not ended in a host call.
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
another of ours is not identified (conservative). The identification holds only on a sample that
enters the function the measurement lies in: rule 2's hoist is for an arm of that function, and a callee
under a predicate measures rule 19's controlled copy, so a plain measurement in a function the input never
enters is wrong (cq-ggr3p). Every C measurement is matched. Against the reference measurements are
compared by position.

x87 f80: a NaN is exponent 0x7FFF with a nonzero fraction (bits 0..62), the explicit integer bit
ignored, so a pseudo-NaN is a NaN and a pseudo-infinity is not.
"""
from __future__ import annotations

import dataclasses
import functools
import json
import os
import re
import struct
import sys
from collections import Counter
from dataclasses import dataclass, field
from fractions import Fraction
from typing import Any, Callable, Dict, FrozenSet, Hashable, List, Optional, Sequence, Set, Tuple

from .contracts import DriverSpec, RunResult


class CompareError(Exception):
    """A RunResult this module cannot read: an internal error of the checker, never a verdict."""


# The host-effect functions with a logging stand-in in checker/rt/host_fx.c: run.py renames a lowered
# module's direct calls to them. Every other direct host call goes to a generated wrapper on both sides
# (drivers.effect_callees, rulings Q8); on the C side these do too, but for raise, which the C oracle
# logs and makes (OracleInstr.cpp, effects): it ends the sample or runs the handler.
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


def _kept_rows(rr: RunResult):
    """The live rails of a run, each row of a run (run._compact_kept) as its rails."""
    for k in rr.kept or []:
        n = k.get("n")
        if n is None:
            yield k
        else:
            for i in range(n):
                yield {"h": k["h"] + i * k["step"], "w": k.get("w"), "v": k.get("v"), "role": k.get("role")}


def _shape_of(rr: RunResult) -> Tuple:
    """The structure of one lowered run: everything but data values."""
    rots = []
    for rec in rr.rotations or []:
        ev = rec.get("ev")
        if ev not in _KIND:
            raise CompareError(f"cq: unimplemented: chk-compare: rotation event {rec!r}")
        theta = _int(rec.get("theta")) if ev in ("ry", "phase") else None
        rots.append((ev, rec.get("h"), rec.get("a"), rec.get("f"), tuple(rec.get("ctl", []) or []), theta))
    kept = hash(tuple(sorted((k["h"], k.get("w")) for k in _kept_rows(rr))))
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
    cpred: Optional[Tuple[int, ...]] = None  # Ry: control on per sample, an identity angle included
    rawang: Optional[Tuple] = None   # Ry: the angle bits where the control is on (identity included)
    pre: Optional[Tuple] = None      # Ry: the target's value just before the gate where it fires (cq-3o3v)


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


def _mprefix(rr: RunResult, n: Optional[int], nan_eq: bool = False) -> Tuple:
    """The run's first n measured outcomes (all of them when n is None), as (type, value) (cq-459d)."""
    ms = rr.measured or []
    return tuple((m.get("w"), _fpv(_int(m.get("v")), m.get("w"), nan_eq)) for m in (ms if n is None else ms[:n]))


def _of_outcomes(pred: Sequence[Any], keys: Sequence[Tuple]) -> bool:
    """pred is a function of the per-sample measurement prefixes `keys` (cq-459d)."""
    table: Dict[Tuple, Any] = {}
    return all(table.setdefault(k, p) == p for k, p in zip(keys, pred))


def _lowered_events(runs: List[RunResult], regs_out: Optional[Dict[Tuple[int, int], Tuple]] = None
                    ) -> Tuple[List[_Ev], List[_Ev], List[_Ev]]:
    """Gate events of one side over one group: (kept events, dropped global phases, idle Ry: an Ry
    whose control fires somewhere but whose angle is the identity wherever it does, CR §1.3; no
    gate, but still the prep that overwrites its target for rule 10's un-prep, bead cq-mopw).
    `regs_out`, when given, receives the side's register versions ((rail, n) -> values per sample)."""
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
        ctl_on: List[int] = []
        rawang: List[Optional[int]] = []
        afn: List[Optional[int]] = []
        tvals: List[int] = []
        pvals: List[Optional[int]] = []
        w = None
        theta = _int(r0.get("theta")) if kind in ("ry", "ph") else None
        for s in S:
            rec = recs[s][i]
            if kind == "ph":
                on = int(bool(_int(rec["fv"])))
            else:
                on = _ctl_on(rec)
            ctl_on.append(on)
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
            rawang.append((theta if kind == "ry" else aval) if ctl_on[-1] else None)
            if kind in ("ry", "ryq"):
                w, v = _target_value(runs[s], rec, kept_by[s])
                tvals.append(v)
                pvals.append(_masked(_int(rec.get("pre")), w) if on else None)
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
                       flag=r0.get("f") if kind == "ph" else None, ctlfn=ctlfn,
                       cpred=tuple(ctl_on) if kind in ("ry", "ryq") else None,
                       rawang=tuple(rawang) if kind in ("ry", "ryq") else None,
                       pre=tuple(pvals) if kind in ("ry", "ryq") else None))
    live, glob, idle = [], [], []
    for e in evs:
        if not any(e.pred):
            if e.cpred is not None and any(e.cpred):
                idle.append(e)
            continue
        # a global phase: a classical-angle phase whose predicate is constant over the group, or a
        # function of the outcomes measured before it (owner ruling 2026-11-02 on cq-459d: after the
        # collapse it is global within each outcome branch); the classical arguments are the group's
        if e.kind == "ph" and (all(e.pred) or _of_outcomes(
                e.pred, [_mprefix(runs[s], _int(recs[s][e.idx].get("nmeas")) or 0) for s in S])):
            glob.append(e)
            continue
        sup = {r for r, _ in _dep(e.pred, regs)}
        if e.target is not None:
            sup.add(e.target)
        if e.afn is not None:
            sup |= {r for r, _ in _dep(e.afn, regs)}
        e.support = frozenset(sup)
        live.append(e)
    if regs_out is not None:
        regs_out.update(regs)
    return live, glob, idle


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
    if a.kind != b.kind or a.pred != b.pred or a.theta != b.theta or a.afn != b.afn or a.pre != b.pre:
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


# 2π past f64 precision: phase totals are summed exactly (each f64 angle is a rational) and reduced mod 2π
_TWO_PI = Fraction("6.283185307179586476925286766559005768394338798750211641949889184615632812572418")
# A total that is a nonzero multiple of 2π only up to the rounding of its f64 terms (π + π) reads as 0
# within this relative bound; a total that is 0 itself must be 0 exactly (no tolerance at k = 0).
_TWO_PI_TOL = 2.0 ** -44


def _f64(bits: int) -> float:
    return struct.unpack("<d", struct.pack("<Q", bits & ((1 << 64) - 1)))[0]


def _zero_mod_2pi(x: Fraction, mag: float) -> bool:
    """x ≡ 0 (mod 2π): exactly 0, or a nonzero multiple of 2π within the rounding of its terms
    (`mag`: the sum of their magnitudes)."""
    if x == 0:
        return True
    k = round(x / _TWO_PI)
    return k != 0 and abs(float(x - k * _TWO_PI)) <= _TWO_PI_TOL * max(1.0, mag)


def _phase_terms(e: _Ev) -> List[Fraction]:
    """θ·f per group sample of a phase (ph: its classical angle where it fires; phq: its angle rail's
    value where it fires). A non-finite angle never fires (_lowered_events)."""
    if e.kind == "ph":
        th = Fraction(_f64(e.theta))
        return [th if on else Fraction(0) for on in e.pred]
    return [Fraction(_f64(a)) if a is not None else Fraction(0) for a in e.afn]


def _match_lists(ours: List[_Ev], ref: List[_Ev], regs_o: Optional[Dict[Tuple[int, int], Tuple]] = None,
                 regs_r: Optional[Dict[Tuple[int, int], Tuple]] = None) -> Optional[str]:
    """Trace equivalence under partial commutation with a rail bijection, phases compared as a total
    (CR §6 item 2, ruling cq-u2mw); None when equal.

    The non-diagonal gates (Ry, angle-rail Ry) are matched one to one, as before. Phases are never
    matched one at a time: the search carries Δ, the phase total of ours so far minus that of the
    reference gates consumed so far, per group sample (exact, mod 2π), with the invariant
    ours[:i] = e^{iΔ}·(consumed reference gates). An our phase adds to Δ. A reference phase is consumed
    (subtracted) only when it must be: when it precedes, and does not commute with, the reference Ry
    paired next (it is then movable to the front: no Ry still pending before it is ordered with it),
    or at the end. Pairing our Ry y with a reference Ry needs e^{iΔ} to commute with y: Δ constant
    over the group (a global phase), or not reading y's target (its support over both sides'
    registers, _dep), or a function of y's control values (diagonal on its controls; as
    _diag_on_controls). At the end every reference gate is consumed and Δ must be constant over the
    group: one total agreeing on every basis input mod 2π, up to a global phase (CR §6). Consuming a
    reference phase as late as possible loses nothing: a phase that commutes with y does not change
    whether Δ reads y's target."""
    best = [-1, ""]
    limit = max(1000, 4 * (len(ours) + len(ref)) + 100)
    if sys.getrecursionlimit() < limit:
        sys.setrecursionlimit(limit)
    nS = len((ours or ref)[0].pred) if (ours or ref) else 0
    regs: Dict[Tuple, Tuple] = {}
    for side, rg in (("o", regs_o or {}), ("r", regs_r or {})):
        for (h, n), v in rg.items():
            regs[((side, h), n)] = v
    terms: Dict[int, List[Fraction]] = {}
    mags: Dict[int, List[float]] = {}

    def term(e: _Ev) -> Tuple[List[Fraction], List[float]]:
        if id(e) not in terms:
            terms[id(e)] = _phase_terms(e)
            mags[id(e)] = [abs(float(t)) for t in terms[id(e)]]
        return terms[id(e)], mags[id(e)]

    # Δ: (total per sample, magnitudes per sample, the angle-rail part of the total per sample, the
    # phases summed into it since it was last constant: (event, sign, side))
    Delta = Tuple[Tuple[Fraction, ...], Tuple[float, ...], Tuple[Fraction, ...], Tuple]
    zero: Delta = (tuple(Fraction(0) for _ in range(nS)), tuple(0.0 for _ in range(nS)),
                   tuple(Fraction(0) for _ in range(nS)), ())

    def add(d: Delta, e: _Ev, sign: int, side: str) -> Delta:
        t, mg = term(e)
        q = tuple(x + sign * y for x, y in zip(d[2], t)) if e.kind == "phq" else d[2]
        return (tuple(x + sign * y for x, y in zip(d[0], t)), tuple(x + y for x, y in zip(d[1], mg)), q,
                d[3] + ((e, sign, side),))

    def classes(vals: Sequence[Fraction], mg: Sequence[float]) -> Optional[Tuple[int, ...]]:
        """Values per sample as classes of equality mod 2π; None when constant (a global phase)."""
        reps: List[int] = []
        ids: List[int] = []
        for s in range(nS):
            for c, t in enumerate(reps):
                if _zero_mod_2pi(vals[s] - vals[t], mg[s] + mg[t]):
                    ids.append(c)
                    break
            else:
                reps.append(s)
                ids.append(len(reps) - 1)
        return None if len(reps) <= 1 else tuple(ids)

    def settle(d: Delta) -> Delta:
        """A constant Δ commutes with every gate: forget the phases summed into it."""
        if not d[3]:
            return d
        v0, m0 = d[0][0], d[1][0]
        if all(_zero_mod_2pi(v - v0, mg + m0) for v, mg in zip(d[0], d[1])):
            return (d[0], d[1], d[2], ())
        return d

    def crosses(d: Delta, e: _Ev, r: _Ev) -> bool:
        """e^{iΔ} commutes with the pair (e, r): the phases summed into Δ that each commute with it by
        _diag_on_controls (their flag a control of the Ry on their side, their predicate a function of
        it) aside, the rest is constant or does not read the Ry's target."""
        vals, mg = list(d[0]), d[1]
        for ev, sign, side in d[3]:
            if _diag_on_controls(ev, e if side == "o" else r):
                for s, t in enumerate(term(ev)[0]):
                    vals[s] -= sign * t
        cl = classes(vals, mg)
        if cl is None:
            return True
        rails = {k[0] for k in _dep(cl, regs)}
        return ("o", e.target) not in rails and ("r", r.target) not in rails

    def note(i: int, why: str) -> None:
        if best[0] < i:
            best[0], best[1] = i, why

    def dfs(i: int, rem: List[int], m: Dict[int, int], minv: Dict[int, int], d: Delta) -> bool:
        if i == len(ours):
            left = [j for j in rem if not _phase(ref[j])]
            if left:
                note(i, f"reference gate {ref[left[0]].label} has no counterpart in ours")
                return False
            for j in rem:
                d = add(d, ref[j], -1, "r")
            cl = classes(d[0], d[1])
            if all(_zero_mod_2pi(x, mg) for x, mg in zip(d[0], d[1])):
                return True
            if cl is None and all(_zero_mod_2pi(x, mg) for x, mg in zip(d[2], d[1])):
                return True          # a global phase, of classical-angle phases only (CR §6)
            note(i, "the phase totals differ: ours minus the reference's is not 0 mod 2π on every sample "
                    + (f"(classes {_fn(cl)})" if cl is not None else "(a constant the angle rails contribute to: "
                       "never a global phase)"))
            return False
        e = ours[i]
        if _phase(e):
            return dfs(i + 1, rem, m, minv, settle(add(d, e, +1, "o")))
        tried = set()
        crossed = False
        for pos, j in enumerate(rem):
            r = ref[j]
            if _phase(r):
                continue
            pair = _same(e, r, m, minv)
            if pair is None or pair in tried:
                continue
            tried.add(pair)
            block = [k for k in rem[:pos] if _ordered(ref[k], r)]
            if any(not _phase(ref[k]) for k in block):
                continue
            if any(not _phase(ref[k2]) and _ordered(ref[k2], ref[k])
                   for k in block for k2 in rem[:rem.index(k)]):
                continue         # a forced phase is itself behind a pending Ry: r cannot reach the front
            d2 = d
            for k in block:
                d2 = add(d2, ref[k], -1, "r")
            d2 = settle(d2)
            if not crosses(d2, e, r):
                crossed = True
                continue
            m2, minv2 = m, minv
            if pair != (-1, -1) and pair[0] not in m:
                m2 = dict(m); m2[pair[0]] = pair[1]
                minv2 = dict(minv); minv2[pair[1]] = pair[0]
            drop = set(block) | {j}
            if dfs(i + 1, [x for x in rem if x not in drop], m2, minv2, d2):
                return True
        if crossed:
            note(i, f"our gate #{i} {e.label} (predicate {_fn(e.pred)}): the phase total before it (ours minus "
                    f"the reference's) reads its target, so the phases do not agree on its either side")
        note(i, f"our gate #{i} {e.label} (predicate {_fn(e.pred)}) matches no reference gate "
                f"movable to this position")
        return False

    if dfs(0, list(range(len(ref))), {}, {}, zero):
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
    # per sample, parallel to occ: a theta reach's register before the C side substituted it (the
    # site event's "pre", cq-3o3v; None when the event has none)
    pre: List[List[Optional[int]]] = field(default_factory=list)
    # per sample, parallel to occ: the C program's measured outcomes before the reach (cq-459d)
    mkey: List[List[Tuple]] = field(default_factory=list)


_MARKERS = ("invert_begin", "invert_end")


def region_emission(entries: Sequence[Tuple[str, int]], final_nmeas: Optional[int] = None,
                    open_end: bool = False) -> Tuple[List[Tuple[int, bool]], List[int], int]:
    """CR rule 17 / BACKEND_ABI 1.13 on the C program's events: `entries` is [(kind, nmeas)] in execution
    order (kind theta, phi, invert_begin or invert_end; nmeas the measurements before it). Returns the
    gate entries in the circuit's emission order as [(index, negated)], the indices of invert_ends with
    no open region, and the number of regions left open (closed at the end only with `open_end`, else
    left out of the order). A region's gates are emitted reversed and negated at its end, a nested
    region's into the enclosing one; a measurement while a region is open first emits every open
    region's gates so far forward, outermost first (the backend's flush; cq-4593), and only the later
    ones are reversed."""
    stack: List[List[Tuple[int, bool]]] = [[]]
    unmatched: List[int] = []
    last: Optional[int] = None

    def flush(m: Optional[int]) -> None:
        nonlocal last
        if m is not None and last is not None and m > last and len(stack) > 1:
            for lvl in stack[1:]:
                stack[0].extend(lvl)
                lvl.clear()
        if m is not None:
            last = m if last is None else max(last, m)

    for i, (kind, nmeas) in enumerate(entries):
        flush(nmeas)
        if kind == "invert_begin":
            stack.append([])
        elif kind == "invert_end":
            if len(stack) == 1:
                unmatched.append(i)
                continue
            region = stack.pop()
            stack[-1].extend((p, not neg) for p, neg in reversed(region))
        else:
            stack[-1].append((i, False))
    flush(final_nmeas)
    left = len(stack) - 1
    if open_end:
        while len(stack) > 1:
            region = stack.pop()
            stack[-1].extend((p, not neg) for p, neg in reversed(region))
    return stack[0], unmatched, left


def _c_order(rr: RunResult, s: int, open_end: bool = False
             ) -> Tuple[List[Tuple[int, Dict[str, Any], bool]], List[str]]:
    """One C sample's theta/phi sites in emission order under CR rule 17: [(original position,
    record, negated)], and the reasons its markers do not pair up. `open_end`: the sample stops
    early (ended or cut), so a region still open there is closed at its end (module docstring).
    A measurement inside a region flushes the gates before it forward (region_emission)."""
    reasons: List[str] = []
    recs = list(rr.rotations or [])
    for rec in recs:
        if rec.get("ev") != "site" or rec.get("kind") not in ("theta", "phi") + _MARKERS:
            raise CompareError(f"cq: unimplemented: chk-compare: C-oracle rotation {rec!r}")
    # CR rule 17 (2026-11-02, cq-asfn): a marker inside a quantum arm whose match is outside it. On a path
    # that reaches an end with no open region (a begin in the other arm, its end after the join) that end
    # closes nothing: the tail on this path lies outside the bracket. On a path that leaves a region open
    # (an end in the other arm, its begin before the branch) the region holds everything after its begin on
    # this path: it is closed where the sample stops.
    order, _unmatched, _left = region_emission([(r["kind"], _int(r.get("nmeas")) or 0) for r in recs],
                                               len(rr.measured or []), True)
    return [(i, recs[i], neg) for i, neg in order], reasons


def _c_sites(runs: List[RunResult], nan_eq: bool, open_end: Sequence[bool] = (),
             ident: Optional[Dict[Tuple, List[List[Tuple[int, Any, Optional[int]]]]]] = None
             ) -> Tuple[List[_Site], List[str]]:
    """The C sites of a group (identity reaches dropped, CR §1.3) and the reasons its markers do not
    pair up. `ident`, when given, receives the dropped theta reaches: site key -> per sample
    [(emission position, angle class, register)] (beads cq-q15r, cq-ia96: an idle lowered Ry
    stands as a rule-10 overwrite only on such a reach, _c_backing)."""
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
                if ident is not None and rec["kind"] == "theta":
                    ident.setdefault(key, [[] for _ in range(nS)])[s].append(
                        (epos, _fpv(ang, "f64", nan_eq), _int(rec.get("reg"))))
                continue
            st = sites.get(key)
            if st is None:
                st = sites[key] = _Site(key, rec["kind"], [[] for _ in range(nS)], [[] for _ in range(nS)],
                                        [[] for _ in range(nS)])
            st.occ[s].append((epos, _fpv(ang, "f64", nan_eq),
                              _int(rec.get("reg")) if rec["kind"] == "theta" else None))
            st.pre[s].append(_int(rec.get("pre")) if rec["kind"] == "theta" else None)
            st.mkey[s].append(_mprefix(rr, _int(rec.get("nmeas")) or 0, nan_eq))
    return [sites[k] for k in sorted(sites, key=repr)], reasons


_Back = Callable[[_Ev, _Ev, int], Optional[Tuple[Any, Tuple[int, int]]]]


def _unprep_partners(ours: List[_Ev], idle: Sequence[_Ev] = (), back: Optional[_Back] = None,
                     capped: Sequence[bool] = ()) -> List[Optional[Tuple[int, FrozenSet[int]]]]:
    """Per gate, its rule-10 un-prep reading (bead cq-9gi3), or None: (j, ks) when gate i is the
    adjoint of the earlier gate j and its predicate is exactly the overwrite predicate that rule 10
    implies. Lowered side only; _match_c additionally requires j and every k to take C reaches.

    Gate i (Ry or angle-rail Ry) reads as j's un-prep when, at every sample s where i fires, the
    latest gate on i's target before i that fires at s is j (one j for all such s, of i's kind),
    i's angle is j's negated, and the target holds the value it held at j; and i's predicate is,
    at every sample, exactly: j fires, no gate on the target between j and i fires, and a gate on
    the target after i fires (the overwriting prep k; ks collects the first such k per sample).

    `idle` (bead cq-mopw): the Ry gates whose angle is the identity wherever their control fires
    (CR §1.3, dropped from `ours`, as the C side drops its identity reaches). An Ry's position among
    the gates on its target is its control (cpred), its angle aside, so an idle Ry counts for j's
    choice and for between. An idle prep can be the overwrite of rule 10 (`r = 0; cq_theta(&r, NaN)`
    undoes the earlier prep).

    The overwrite must be the C program's (beads cq-q15r, cq-ia96, cq-yzuc): `back(j, k, s)` gives,
    at an uncapped sample s, the C program's overwrite of j's reach there by a reach of k's angle
    and register value that seeds j's register afresh ((its site, (s, its position)), or None;
    _match_c's _c_backing); an in-place second cq_theta of the register is no overwrite. k, live or
    idle, stands only when back finds it at every uncapped sample where i fires, all at one C site,
    and no C reach backs two ks; without `back` no un-prep stands. A live k also takes its own C
    reach in the matching (ks); an idle k takes none."""
    out: List[Optional[Tuple[int, FrozenSet[int]]]] = [None] * len(ours)
    if not ours:
        return out
    nS = len(ours[0].pred)
    sign = 1 << 63

    def angle(e: _Ev, s: int) -> Optional[int]:
        return e.theta if e.kind == "ry" else e.afn[s]

    # every gate on a target, idle ones included, in emission order: ("o", index into ours) or
    # ("i", index into idle)
    allg = sorted([(e.idx, "o", g) for g, e in enumerate(ours)] + [(e.idx, "i", g) for g, e in enumerate(idle)])

    def ev(t: Tuple[str, int]) -> _Ev:
        return ours[t[1]] if t[0] == "o" else idle[t[1]]

    def on(t: Tuple[str, int], s: int) -> int:
        x = ev(t)
        return (x.cpred if x.cpred is not None else x.pred)[s]

    used_reach: set = set()          # the C identity reaches backing an idle k, each at most once
    for i, e in enumerate(ours):
        if e.kind not in ("ry", "ryq") or e.target is None:
            continue
        on_t = [(kd, g) for idx, kd, g in allg if ev((kd, g)).target == e.target]
        me = on_t.index(("o", i))
        before = on_t[:me]
        after = on_t[me + 1:]
        j: Optional[Tuple[str, int]] = None
        ok = True
        for s in range(nS):
            if not e.pred[s]:
                continue
            last = next((g for g in reversed(before) if on(g, s)), None)
            if last is None or (j is not None and last != j):
                ok = False
                break
            j = last
        if not ok or j is None or j[0] != "o":
            continue
        p = ours[j[1]]
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
        ksites, kreach = set(), []
        for s in range(nS):
            between = any(on(g, s) for g in before[before.index(j) + 1:])
            k = next((g for g in after if on(g, s)), None)
            implied = bool(p.pred[s]) and not between and k is not None
            if implied != bool(e.pred[s]):
                ok = False
                break
            if implied and k[0] == "o":
                ks.add(k[1])
            if implied and not (capped and capped[s]):
                got = back(p, ev(k), s) if back is not None else None
                if got is None:
                    ok = False
                    break
                ksites.add(got[0])
                kreach.append(got[1])
        if ok and len(ksites) <= 1 and not (set(kreach) & used_reach):
            used_reach.update(kreach)
            out[i] = (j[1], frozenset(ks))
    return out


def _c_backing(sites: List[_Site], ident: Dict[Tuple, List[List[Tuple[int, Any, Optional[int]]]]],
               registers: Dict[str, Any], nan_eq: bool) -> _Back:
    """back(j, k, s) for _unprep_partners (beads cq-ia96, cq-yzuc): CR rule 10's overwrite in the C
    program at sample s. j's reach is a reach of a theta site J with j's angle and register value
    there; the overwrite is the next reach after it, in the C program's (rule-17) order, of a site K
    of the same register (`registers`, drivers.theta_registers: one SSA web) that seeds the register
    afresh (J is not among K's seed sources: an in-place cq_theta of J's value is a second Ry on the
    register, CQ.h, never an overwrite), with k's angle class and register value, and an identity
    reach exactly where k's angle is the identity. Returns (its site, (s, its position)), or None."""
    def entry(key: Tuple) -> Any:
        return registers.get(f"{key[0]}:{key[1]}")

    def reg(key: Tuple) -> Any:
        e = entry(key)
        return e[0] if e is not None else None

    def fresh(jkey: Tuple, kkey: Tuple) -> bool:
        e = entry(kkey)
        return e is not None and f"{jkey[0]}:{jkey[1]}" not in e[1]

    by_reg: Dict[Any, List[Tuple[Tuple, bool, List[List[Tuple[int, Any, Optional[int]]]]]]] = {}
    for st in sites:
        if st.kind == "theta" and reg(st.key) is not None:
            by_reg.setdefault(reg(st.key), []).append((st.key, False, st.occ))
    for key, occ in ident.items():
        if reg(key) is not None:
            by_reg.setdefault(reg(key), []).append((key, True, occ))

    def back(j: _Ev, k: _Ev, s: int) -> Optional[Tuple[Any, Tuple[int, int]]]:
        w = j.tclass[0] if j.tclass else None
        ja = _fpv(j.theta if j.kind == "ry" else j.afn[s], "f64", nan_eq)
        jv = _fpv(j.tclass[1][s], w, nan_eq)
        ka = _fpv(k.rawang[s], "f64", nan_eq) if k.rawang and k.rawang[s] is not None else None
        kv = _fpv(k.tclass[1][s], k.tclass[0], nan_eq) if k.tclass else None
        kid = not k.pred[s]                          # k's angle is the identity at s
        found = None
        for chain in by_reg.values():
            reaches = sorted((ep, a, r, key, isid) for key, isid, occ in chain for ep, a, r in occ[s])
            for n, (ep, a, r, key, isid) in enumerate(reaches):
                if isid or a != ja or _fpv(r, w, nan_eq) != jv or n + 1 == len(reaches):
                    continue
                ep2, a2, r2, key2, isid2 = reaches[n + 1]
                if isid2 == kid and a2 == ka and fresh(key, key2) \
                        and _fpv(r2, k.tclass[0] if k.tclass else None, nan_eq) == kv:
                    if found is not None and found != (key2, (s, ep2)):
                        return None                  # ambiguous: two C overwrites fit
                    found = (key2, (s, ep2))
        return found

    return back


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
    for afn, rfn, w, pfn in full:
        widths.setdefault(w, len(widths))
    wlist = list(widths) or [None]   # at least one width class: the reader takes one id per class
    n = len(ours)
    need_ord = any(comm)
    data = [n, nS, len(sites), len(wlist), MATCH_BUDGET] + [1 if c else 0 for c in capped]
    for i, e in enumerate(ours):
        afn, rfn, w, pfn = full[i]
        sup = sorted(e.support)
        data += [1 if ckind[i] == "theta" else 0, 0, 1 if free_ok[i] else 0,
                 0 if e.target is None else 1, 0 if e.target is None else int(e.target), len(sup)]
        data += [int(r) for r in sup]
        data += [1 if e.pred[s] else 0 for s in range(nS)]
        data += [iid(afn[s]) for s in range(nS)]
        data += [iid((_fpv(rfn[s], w, nan_eq), _fpv(pfn[s], w, nan_eq))) for s in range(nS)]
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
            for t, (epos, a, r) in enumerate(occ):
                p = st.pre[s][t] if st.pre else None
                data += [epos, iid(a)] + [iid((_fpv(r, w, nan_eq), _fpv(p, w, nan_eq))) for w in wlist]
    return data


def _match_c_ry(ours: List[_Ev], glob: List[_Ev], sites: List[_Site], nan_eq: bool,
                capped: Sequence[bool] = (), idle: Sequence[_Ev] = (),
                ident: Optional[Dict[Tuple, List[List[Tuple[int, Any, Optional[int]]]]]] = None,
                registers: Optional[Dict[str, Any]] = None, cmeas: Optional[Sequence[Tuple]] = None,
                hits_out: Optional[List[List[Tuple[int, _Ev]]]] = None, unprep_out: Optional[set] = None
                ) -> List[str]:
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
    Pset = set(P)
    cm = list(cmeas) if cmeas is not None else [() for _ in range(nS)]   # each sample's C outcomes

    def lfull(e: _Ev) -> Tuple:
        if e.afn is not None:
            afn = tuple(_fpv(a, "f64", nan_eq) for a in e.afn)
        else:
            afn = tuple(_fpv(e.theta, "f64", nan_eq) if p else None for p in e.pred)
        w = e.tclass[0] if e.target is not None else None
        rfn = e.tclass[1] if e.target is not None else tuple(None for _ in e.pred)
        pfn = e.pre if e.pre is not None else tuple(None for _ in e.pred)
        return afn, rfn, w, pfn

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
        afn, rfn, w, pfn = full[i]
        new: Optional[List[int]] = None
        for s in range(nS):
            if not e.pred[s]:
                continue
            m = used[j * nS + s]
            hit = None
            for t, (epos, a, r) in enumerate(st.occ[s]):
                # theta: the register after (the chosen value) and before the C side substituted it,
                # the latter the Ry target's value just before the gate (owner ruling on cq-3o3v)
                if not (m >> t) & 1 and a == afn[s] and (st.kind != "theta" or (
                        _fpv(r, w, nan_eq) == _fpv(rfn[s], w, nan_eq)
                        and _fpv(st.pre[s][t] if st.pre else None, w, nan_eq) == _fpv(pfn[s], w, nan_eq))):
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

    def leftover(used: Used, only: Optional[Sequence[int]] = None) -> List[str]:
        """Reaches not taken that are not a global phase (of the sites `only`, default all)."""
        why: List[str] = []
        for j in range(len(sites)) if only is None else only:
            st = sites[j]
            left = [[(t, o) for t, o in enumerate(st.occ[s]) if not (used[j * nS + s] >> t) & 1]
                    for s in range(nS)]
            bad: List[Tuple[int, int]] = []
            if st.kind == "theta":
                bad = [(s, l[0][0]) for s, l in enumerate(left) if l]
            elif P:
                # a global phase (cq-459d): each (angle, outcomes measured before the reach) reached
                # equally often at every uncapped sample whose outcomes begin so, at most as often at a
                # capped one; with nothing measured, the same multiset at every uncapped sample
                mk = st.mkey or [[() for _ in o] for o in st.occ]
                cnt = [Counter((o[1], mk[s][t]) for t, o in l) for s, l in enumerate(left)]
                for key in sorted({k for c in cnt for k in c}, key=repr):
                    M = key[1]
                    ext = [s for s in range(nS) if cm[s][:len(M)] == M]
                    up = [s for s in ext if s in Pset]
                    if not up:
                        continue
                    c0 = cnt[up[0]][key]
                    s = next((s for s in ext if (cnt[s][key] != c0 if s in Pset else cnt[s][key] > c0)), None)
                    if s is None:
                        continue
                    if not cnt[s][key]:        # a reach this sample lacks: name it where it is left
                        s = next(x for x in up if cnt[x][key])
                    t = next(t for t, o in left[s] if (o[1], mk[s][t]) == key)
                    bad.append((s, t))
                    break
            else:
                if len({o[1] for l in left for _, o in l}) > 1:
                    bad = [(s, l[0][0]) for s, l in enumerate(left) if l]
            if bad:
                s, t = bad[0]
                reach = _fn([len(o) for o in st.occ])
                why.append(f"C site {st.key[0]}:{st.key[1]} ({st.kind}, reach {t} at sample {s}; reaches per "
                           f"sample {reach}) has no lowered gate with that predicate, angle and register "
                           f"(value before and after)")
        return why

    start: Used = tuple(0 for _ in range(len(sites) * nS))
    # a site a gate can never take (take refuses it from the start, so from every state) is no candidate
    cands = [[j for j in cands[i] if take(i, j, start) is not None] for i in range(len(ours))]
    assign: List[Optional[int]] = [None] * len(ours)
    partner = _unprep_partners(ours, idle, _c_backing(sites, ident or {}, registers, nan_eq) if registers else None,
                               capped)
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

    comp: List[List[int]] = [list(range(len(ours))), list(range(len(sites)))]   # the component searched

    def dfs(p: int, used: Used, unp: FrozenSet[int], free: FrozenSet[int], ordst: Tuple = ((), (), ())) -> bool:
        G = comp[0]
        if p == len(G):
            return not leftover(used, comp[1]) and not any(partner[u][1] & (unp | free) for u in unp)
        i = G[p]
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
                if dfs(p + 1, nxt, unp, free, o2):
                    return True
        assign[i] = None
        if partner[i] is not None and partner[i][0] not in unp | free:
            if dfs(p + 1, used, unp | {i}, free, ordst):
                unprep.add(i)
                return True
        if free_ok[i]:
            if dfs(p + 1, used, unp, free | {i}, ordst):
                return True
        failed.add((i, used, unp, free, ordst))
        return False

    unprep: set = set()

    def search_py() -> Tuple[int, bool, bool, List[Optional[int]], set]:
        # First without the order (the memo then needs no order state, so the search stays small): if
        # no matching exists at all, the order cannot help. Then with the order, from scratch.
        failed.clear()
        unprep.clear()
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

    def search_native(G: List[int], J: List[int]) -> Tuple[int, bool, bool, List[Optional[int]], set]:
        """The component's search in native/match_c.cpp, its gates and sites renumbered from 0."""
        from cqcheck import native
        gi = {i: n for n, i in enumerate(G)}
        si = {j: n for n, j in enumerate(J)}
        part = [None if partner[i] is None else (gi[partner[i][0]], frozenset(gi[k] for k in partner[i][1]))
                for i in G]
        data = _match_input([ours[i] for i in G], [sites[j] for j in J], nS, capped,
                            [[si[j] for j in cands[i]] for i in G], [ckind[i] for i in G],
                            [free_ok[i] for i in G], part, [{gi[k] for k in comm[i]} for i in G],
                            [full[i] for i in G], nan_eq)
        st, fa, fd, asg, unp = native.match_c(data, len(G))
        out: List[Optional[int]] = [None] * len(ours)
        for n, i in enumerate(G):
            out[i] = None if asg[n] is None else J[asg[n]]
        return st, fa, fd, out, {G[n] for n in unp}

    # Independent parts (cq-holz): a gate is linked to every site it can take, to every gate whose
    # target lies in its support or whose support holds its target (order_ok reads and writes order
    # state only at those rails), and to its rule-10 un-prep's j and ks. A part's choices change only
    # its own sites' reaches and only order state its own gates read, so the whole matching exists
    # (order-consistent or not) exactly when each part's does, and the parts are searched one by one;
    # a site no gate can take must have no reach left. Searched together, a part whose matching fails
    # late made the search retry every combination of another part's choices: 117 with one sample,
    # 101 Ry gates on theta sites and 25 dropped global phases on phi sites, ran past the budget.
    # Each part's order-consistent search has the node budget.
    up = list(range(len(ours) + len(sites)))

    def root(x: int) -> int:
        while up[x] != x:
            up[x] = up[up[x]]
            x = up[x]
        return x

    def link(a: int, b: int) -> None:
        up[root(a)] = root(b)

    by_target: Dict[int, List[int]] = {}
    for i, e in enumerate(ours):
        for j in cands[i]:
            link(i, len(ours) + j)
        if partner[i] is not None:
            for k in {partner[i][0]} | set(partner[i][1]):
                link(i, k)
        if e.target is not None:
            by_target.setdefault(e.target, []).append(i)
    for i, e in enumerate(ours):
        for r in e.support:
            for k in by_target.get(r, ()):
                link(i, k)
    parts: Dict[int, List[List[int]]] = {}
    for i in range(len(ours)):
        parts.setdefault(root(i), [[], []])[0].append(i)
    # A _diag_on_controls pair of gates in two parts may share a control rail (p.flag, read by both),
    # but neither targets a rail of the other's support (that would link their parts), so no order
    # between them is constrained and the pair relaxes nothing: dropped (cq-kr9h review note). A gate left with no such pair records its order state per rail (any_, tgt) instead of
    # per gate (exc); a reader e in its part saw the per-gate record of y exactly when _ordered(e, y),
    # and sees the per-rail one exactly when the rails link them: the same, as y is an Ry (only Rys
    # write per rail at a target) or a phase (phases read no per-rail entry: they have no target), and
    # a _diag_on_controls pair within the part keeps its per-gate records.
    for i in range(len(ours)):
        comm[i] = {k for k in comm[i] if root(k) == root(i)}
    unclaimed = []
    for j in range(len(sites)):
        if root(len(ours) + j) in parts:
            parts[root(len(ours) + j)][1].append(j)
        else:
            unclaimed.append(j)

    # cq-8m6v: the same two searches in C++ (checker/native/match_c.cpp), node for node; the Python
    # search stays the reference: $CQ_MATCH=py runs it alone, $CQ_MATCH=check runs both and fails on
    # any difference
    mode = os.environ.get("CQ_MATCH", "native")
    status, found_any, found = 0, not leftover(start, unclaimed), True
    results = []
    for G, J in (parts.values() if found_any else ()):
        comp[0], comp[1] = G, J
        if mode == "py":
            got = search_py()
        else:
            got = search_native(G, J)
            if mode == "check":
                assign[:] = [None] * len(ours)
                want = search_py()
                if want != got:
                    raise CompareError(f"cq: chk-compare: native matcher {got} != Python {want}")
        results.append((G, got))
        if not got[1]:
            found_any = False
            break
    assign[:] = [None] * len(ours)
    unprep.clear()
    for G, (st, fa, fd, asg, unp) in results:
        if st == 2:
            status = 2
        found = found and fd
        for i in G:
            assign[i] = asg[i]
        unprep.update(unp)
    if not found_any:
        status = 0               # no matching at all: the order-free search decides, as for the whole
    found = found and found_any and status == 0
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
    if hits_out is not None:
        hits_out[:] = hits
    if unprep_out is not None:
        unprep_out.update(ours[i].idx for i in unprep)
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


def _match_c(ours: List[_Ev], glob: List[_Ev], sites: List[_Site], nan_eq: bool,
             capped: Sequence[bool] = (), idle: Sequence[_Ev] = (),
             ident: Optional[Dict[Tuple, List[List[Tuple[int, Any, Optional[int]]]]]] = None,
             registers: Optional[Dict[str, Any]] = None, cmeas: Optional[Sequence[Tuple]] = None,
             regs: Optional[Dict[Tuple[int, int], Tuple]] = None) -> List[str]:
    """Our gates against the C sites (module docstring; bead cq-3q60). Equal when the gates, phases
    included, match the sites one by one (_match_c_ry over everything, the matching before cq-3q60),
    or else when the Ry gates match the cq_theta sites and the phases agree with the cq_phi reaches as
    a total (_phase_total_c; CR §6 item 2, as against the reference): one phase may stand for several
    reaches or several for one. Either matching is a §6 equality; the reasons are both's."""
    nS = len(capped) if capped else len(ours[0].pred) if ours else len(sites[0].occ) if sites else 0
    capped = list(capped) or [False] * nS
    # gate by gate first (phases taking cq_phi sites, as before cq-3q60): a matching there is a
    # matching of the circuits; then, phases as a total
    why_sites = _match_c_ry(ours, glob, sites, nan_eq, capped, idle, ident, registers, cmeas)
    if not why_sites:
        return []
    hits: List[List[Tuple[int, _Ev]]] = []
    unp: set = set()
    why = _match_c_ry([e for e in ours if not _phase(e)], [], [st for st in sites if st.kind == "theta"],
                      nan_eq, capped, idle, ident, registers, hits_out=hits, unprep_out=unp)
    if not why:
        why = _phase_total_c(ours, [st for st in sites if st.kind == "phi"], hits, capped, cmeas, regs or {},
                             frozenset(unp))
        if not why:
            return []
    return why_sites + [f"(phases as a total, cq-3q60) {w}" for w in why if w not in why_sites]


def _phase_total_c(ours: List[_Ev], phi: List[_Site], hits: List[List[Tuple[int, _Ev]]], capped: List[bool],
                   cmeas: Optional[Sequence[Tuple]], regs: Dict[Tuple[int, int], Tuple],
                   unprep: FrozenSet[int] = frozenset()) -> List[str]:
    """CR §6 item 2 against the C oracle (bead cq-3q60, as _match_lists against the reference): the
    phases are a total. Δ(s) = Σ θ·f of our phases − Σ angles of the C program's cq_phi reaches, per
    sample, exact over the f64 angles and read mod 2π (_zero_mod_2pi).

    Global C reaches after a measurement are left out first (cq-459d): the reaches of one site with
    one angle after one nonempty sequence of measured outcomes M, reached equally often at every
    uncapped sample whose outcomes begin with M (at most as often at a capped one): a phase global
    within each outcome branch. Every other reach is in the total (a global one adds a constant). Our global phases are not in
    `ours` (_lowered_events).

    At each Ry y of ours that took a C reach (hits: per sample the C positions of the matched gates),
    Δ_y = our phases before y in lowered order − the C reaches before y's C position must commute with
    y over the samples where y fires (where its control reads 0 it is the identity): constant there,
    or not reading y's target (_dep over our registers on those samples), with or without our phases
    on y's controls (_diag_on_controls). At the end Δ must be 0 mod 2π at every uncapped
    sample, or constant over them with our angle-rail phases contributing 0 (a global phase of
    classical-angle phases), as _match_lists decides against the reference.

    A capped or ended sample s is read through its cut: its C reaches all lie before the cut, and the
    cut lies somewhere in our gate order. Our phases firing at s that follow, without commuting
    (_ordered), an Ry of ours firing at s that takes no C reach there (past the cut; a rule-10
    un-prep aside) lie past the cut too; some prefix, in lowered order, of the others must total the
    C reaches (Δ 0 mod 2π, or the uncapped samples' global constant)."""
    nS = len(capped)
    cm = list(cmeas) if cmeas is not None else [() for _ in range(nS)]
    P = [s for s in range(nS) if not capped[s]]
    Pset = set(P)
    reach: List[List[Tuple[int, Fraction, Tuple, Tuple]]] = [[] for _ in range(nS)]
    for st in phi:
        mk = st.mkey or [[() for _ in o] for o in st.occ]
        for s in range(nS):
            for t, (epos, a, _r) in enumerate(st.occ[s]):
                reach[s].append((epos, Fraction(_f64(a)), mk[s][t], st.key))
    cnt = [Counter((a, M, k) for _, a, M, k in reach[s]) for s in range(nS)]
    glob_keys = set()
    for key in {k for c in cnt for k in c}:
        M = key[1]
        if not M:
            continue                 # nothing measured before: in the total (a constant one is global there)
        ext = [s for s in range(nS) if cm[s][:len(M)] == M]
        up = [s for s in ext if s in Pset]
        if not up:
            continue
        c0 = cnt[up[0]][key]
        if all((cnt[s][key] == c0) if s in Pset else (cnt[s][key] <= c0) for s in ext):
            glob_keys.add(key)
    creach = [[(epos, a) for epos, a, M, k in reach[s] if (a, M, k) not in glob_keys] for s in range(nS)]
    phs = sorted((e for e in ours if _phase(e)), key=lambda e: e.idx)
    terms = {id(e): _phase_terms(e) for e in phs}
    pos = [{e.idx: p for p, e in hits[s]} for s in range(nS)] if hits else [{} for _ in range(nS)]
    ys = sorted({e.idx: e for s in range(nS) for _, e in (hits[s] if hits else [])}.values(), key=lambda e: e.idx)
    for y in ys:
        # only where y fires: there e^{iΔ} must commute with it; where its control reads 0 it is the
        # identity, and a constant Δ on the control-on samples commutes with it
        known = [s for s in range(nS) if y.idx in pos[s]]
        bad = None
        for skip_diag in (False, True):
            vals: List[Fraction] = []
            mags: List[float] = []
            for s in known:
                c = pos[s][y.idx]
                d, mg = Fraction(0), 0.0
                for p in phs:
                    if p.idx < y.idx and not (skip_diag and _diag_on_controls(p, y)):
                        d += terms[id(p)][s]
                        mg += abs(float(terms[id(p)][s]))
                for epos, a in creach[s]:
                    if epos < c:
                        d -= a
                        mg += abs(float(a))
                vals.append(d)
                mags.append(mg)
            cl = _classes_mod_2pi(vals, mags)
            if cl is None:
                bad = None
                break
            sub = {k: tuple(v[s] for s in known) for k, v in regs.items()}
            if y.target not in {r for r, _ in _dep(cl, sub)}:
                bad = None
                break
            bad = bad or cl
        if bad is not None:
            return [f"the phase totals differ before lowered gate #{y.idx} {y.label}: ours minus the C program's "
                    f"(classes {_fn(bad)} over the samples where it fires) reads its target, so the phases do "
                    f"not agree on its either side"]
    vals, mags, rail = [], [], []
    for s in P:
        d, mg, q = Fraction(0), 0.0, Fraction(0)
        for p in phs:
            t = terms[id(p)][s]
            d += t
            mg += abs(float(t))
            if p.kind == "phq":
                q += t
        for _, a in creach[s]:
            d -= a
            mg += abs(float(a))
        vals.append(d)
        mags.append(mg)
        rail.append(q)
    cl = _classes_mod_2pi(vals, mags)
    const: Optional[Tuple[Fraction, float]] = None
    if all(_zero_mod_2pi(v, m) for v, m in zip(vals, mags)):
        pass
    elif cl is None and all(_zero_mod_2pi(q, m) for q, m in zip(rail, mags)):
        const = (vals[0], mags[0])   # a global phase of classical-angle phases (CR §6)
    else:
        return [f"the phase totals differ: ours minus the C program's is not 0 mod 2π on every sample "
                + (f"(classes {_fn(cl)} over the uncapped samples)" if cl is not None else
                   "(a constant the angle rails contribute to: never a global phase)")]
    rys = [e for e in ours if not _phase(e) and e.idx not in unprep]
    for s in range(nS):
        if not capped[s]:
            continue
        took = set(pos[s])
        past = [x for x in rys if x.pred[s] and x.idx not in took]
        ctot = sum((a for _, a in creach[s]), Fraction(0))
        cmag = sum(abs(float(a)) for _, a in creach[s])
        d, mg = -ctot, cmag
        ok = False
        for p in [None] + [p for p in phs if p.pred[s] if not any(x.idx < p.idx and _ordered(x, p) for x in past)]:
            if p is not None:
                t = terms[id(p)][s]
                d += t
                mg += abs(float(t))
            if _zero_mod_2pi(d, mg) or (const is not None and _zero_mod_2pi(d - const[0], mg + const[1])):
                ok = True
                break
        if not ok:
            return [f"the phase totals differ before the cut on capped or ended sample {s}: no prefix of our "
                    f"phases that can lie before the cut totals the C program's cq_phi reaches"]
    return []


def _classes_mod_2pi(vals: Sequence[Fraction], mg: Sequence[float]) -> Optional[Tuple[int, ...]]:
    """Values as classes of equality mod 2π; None when constant (or empty)."""
    reps: List[int] = []
    ids: List[int] = []
    for s in range(len(vals)):
        for c, t in enumerate(reps):
            if _zero_mod_2pi(vals[s] - vals[t], mg[s] + mg[t]):
                ids.append(c)
                break
        else:
            reps.append(s)
            ids.append(len(reps) - 1)
    return None if len(reps) <= 1 else tuple(ids)


# ---------------------------------------------------------------- the a_K rule (against "c")

_NOT_AK_ROLES = ("measured", "abort", "tape", "tape_slot", "store_kept", "overtaken")


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


# ---------------------------------------------------------------- the leak rule (against "c")

# CR §6 item 1 (cq-tt2j, CQ_spec bff98cb): a rail still allocated at exit is a frozen register (rule 10),
# a measured value, an effect entry's result rail, or a kept rail a rule names (5, 6, 14, 16, 18, 19; the
# overflow predicates a_K and n > K2 among them); any other
# live rail is a leak and FAILS, with or without a reference. Against the reference the kept multiset
# already decides it; against the C oracle (the C-oracle verdict; cqcheck user, which has no
# clean-list) each live rail of ours is read by the role the evaluator gives it at exit (rt/core.c
# exit_role) and what the run says of it:
#   kept      measured, frozen (rotated, or a rule-6 image carrying a rotated register's content: rule 19's
#             FROZEN result a caller keeps, rt/core.c cqe__carry; cq-qhow), abort and tape rails (rule 16),
#             a bus store's tape slot, its value rail and control rail (tape_slot, store_kept: rule 5
#             sentence 3), an overtaken load copy (overtaken: rule 5), kept_entangled (a source received
#             a non-diagonal gate or a measurement after the rail was written: no _unc can clean it;
#             rules 5 and 6), rule6_image (an operand a rule-6 clean's inverse read and whose producer's _unc can no
#             longer clean it, frozen or not: rule 5 sentence 1 names a rule-6 image as never uncomputed; rt/core.c
#             cqe__r6_unc, cq-o9mx, cq-cuu82), a result (the handle a handle-returning function returns,
#             run.resolve_handle_rets: "result"), a seed that received an Ry (a register whose Ry was
#             the identity);
#   rule 23   at most one fenv_flags rail (the final flags rail is an output) and one fenv_mode rail. The first rail of a
#             feraiseexcept under a quantum predicate is the flags rail while it is empty (81) and carries no _exc lineage, so
#             a program that touches the environment and has no such rail may keep one "garbage" i32 rail that reads the
#             C program's final flags (_final_flags, cq-f8m9n);
#   known     a rail in a known classical basis state (owner ruling 2026-11-01 on cq-tt2j: not a
#             leak; LIVE_KNOWN_IS_LEAK below flips it);
#   a_K, n>K2 a "garbage" i1 rail, at most one per activation the C oracle recorded on the sample whose
#             (loop, act) it capped after K trips on some sample of the comparison (rule 14's output
#             predicate, kept only when the bound B exceeds K: an activation never capped has B <= K
#             as far as the samples show, which include a K+1-trip search per loop), and at most one
#             per rail-sized block the C program allocated on the sample (outputs["k2"]; rule 20's kept n > K2
#             of a rail-sized allocation), any number on a capped or ended sample (activations past
#             the cut are not recorded). Rule 14 keeps one a_K per cut activation of a quantum-depth recursion, and every
#             recursion that ran reaches its cut on every branch, a forward clone a twin calls to recompute included, so such
#             rails are not one per record: where the C oracle recorded a recursion activation on an uncapped sample any
#             number of them may stay, each reading 0 as §6 demands there (cq-rdsdj);
#   leak      anything else: a rail its sources could still clean, left live.
LIVE_KNOWN_IS_LEAK = False   # owner ruling 2026-11-01 (cq-tt2j): a live rail in a known basis state is no leak
_KEPT_ROLES = frozenset(("measured", "frozen", "abort", "tape", "tape_slot", "store_kept", "overtaken",
                         "kept_entangled", "rule6_image"))
_FENV_ROLES = ("fenv_flags", "fenv_mode")


_ALL_FLAGS = 0x3d    # the five IEEE bits of x86-64: INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32


def _final_flags(ent: Dict[str, Any], o: RunResult, c: RunResult, cut: bool) -> bool:
    """Whether a live i32 rail can be rule 23's final flags rail: exception bits only, and together with the host part (the
    host environment at our exit, which only ever adds bits) exactly the C program's final flags. A sample that stops
    early has no final flags to read."""
    want = c.outputs.get("fenv_flags") if isinstance(c.outputs, dict) else None
    v = _int(ent.get("v"))
    if want is None or v is None or v & ~_ALL_FLAGS:
        return False
    if cut:
        return True
    host = (o.outputs or {}).get("host_flags") or 0
    return not v & ~want and not want & ~(v | host)


def _leaks(k: str, o: RunResult, c: RunResult, cut: bool, capkeys: Set[Tuple[str, int]] = frozenset()) -> List[str]:
    rotated = {e.get("h") for e in o.rotations or [] if isinstance(e, dict) and e.get("ev") in ("ry", "ry_qangle")}
    acts = len({(r["loop"], r["act"]) for r in _loops(c)} & set(capkeys))
    rec = any(r["loop"].endswith(":recursion") for r in _loops(c))
    flagged = any(e.get("role") == "fenv_flags" for e in o.kept or [])
    allocs = len(c.outputs.get("k2", [])) if isinstance(c.outputs, dict) else 0
    i1 = 0
    fenv: Dict[str, int] = {}
    bad = []
    for ent in o.kept or []:
        role = ent.get("role")
        if role in _KEPT_ROLES or ent.get("result") or (role == "seed" and ent.get("h") in rotated):
            continue
        if not LIVE_KNOWN_IS_LEAK and (ent.get("known") is True or role == "seed"):
            continue
        if role in _FENV_ROLES:
            fenv[role] = fenv.get(role, 0) + 1
            if fenv[role] == 1:
                continue
        elif role == "garbage" and ent.get("w") == "i1":
            i1 += 1
            if cut or i1 <= acts + allocs or (rec and not _int(ent.get("v"))):
                continue
        elif role == "garbage" and ent.get("w") == "i32" and not flagged and _final_flags(ent, o, c, cut):
            flagged = True
            continue
        bad.append(f"{ent.get('h')} ({ent.get('w')} = {ent.get('v')}, {role})")
    if not bad:
        return []
    return [f"sample {k}: our side leaves {len(bad)} rail(s) live at exit that are no frozen register, "
            f"measured value, result or rule-kept rail (CR §6 item 1, a leak; cq-tt2j): {', '.join(bad)}"
            + (f"; {acts} K-cut loop activation(s) allow as many a_K rails" if acts else "")
            + (f"; {allocs} allocation(s) allow as many n > K2 rails" if allocs else "")]


# ---------------------------------------------------------------- the abort rule (against "c")

_ENDS = ("noreturn:", "raise:")


def _ended(rr: RunResult) -> bool:
    """A C sample that ended in a noreturn call or a fatal raise (module docstring)."""
    end = rr.outputs.get("end") if isinstance(rr.outputs, dict) else None
    return isinstance(end, str) and end.startswith(_ENDS)


def _check_k2(o_runs: List[RunResult], c_runs: List[RunResult], open_end: Sequence[bool]) -> List[str]:
    """CR §6: the kept rail n > K2 of a rail-sized allocation must read n > K2 on every input. The k-th
    rail-sized block the C program made (outputs["k2"]: [n, K2]) must have its own kept i1 rail of ours
    reading exactly that over the group, once the group tells it from a constant (else any 0 rail would)."""
    maxk = max((len((c.outputs or {}).get("k2", [])) for c in c_runs), default=0)
    if not maxk:
        return []
    rails: Dict[Any, Tuple[int, ...]] = {}
    for h in {e["h"] for rr in o_runs for e in rr.kept or [] if e.get("w") == "i1" and e.get("role") == "garbage"}:
        vals = []
        for rr in o_runs:
            ent = next((e for e in rr.kept or [] if e["h"] == h), None)
            vals.append(_masked(_int(ent["v"]), "i1") if ent else None)
        rails[h] = tuple(vals)
    reasons = []
    taken: Set[Any] = set()
    for k in range(maxk):
        want = [None if len(c.outputs.get("k2", [])) <= k else int(c.outputs["k2"][k][0] > c.outputs["k2"][k][1]) for c in c_runs]
        seen = {w for w, e in zip(want, open_end) if w is not None and not e}
        if len(seen) < 2:
            continue
        h = next((h for h, v in rails.items() if h not in taken and all(
            w is None or e or x == w for x, w, e in zip(v, want, open_end))), None)
        if h is None:
            reasons.append(f"rail-sized allocation {k}: no kept i1 rail of ours reads n > K2 (CR §6): want {_fn(tuple(want))}")
        else:
            taken.add(h)
    return reasons


def _raised(c: RunResult) -> bool:
    end = c.outputs.get("end") if isinstance(c.outputs, dict) else None
    return isinstance(end, str) and end.startswith("raise:")


def _check_abort(o_runs: List[RunResult], ended: Sequence[bool], capped: Sequence[bool],
                 c_runs: Sequence[RunResult] = ()) -> List[str]:
    """Some kept abort-role i1 rail of ours reads 1, or ours itself ended in the host call, on every
    ended sample; every flag reads 0 and ours did not end on every sample that returns (module docstring)."""
    flags: Dict[Any, List[int]] = {}
    for s, rr in enumerate(o_runs):
        for ent in rr.kept or []:
            if ent.get("w") == "i1" and ent.get("role") == "abort":
                flags.setdefault(ent["h"], [0] * len(o_runs))[s] = _masked(_int(ent.get("v")), "i1")
    reasons = []
    for s in range(len(o_runs)):
        on = [h for h, v in flags.items() if v[s]]
        if ended[s] and not on and c_runs and _raised(c_runs[s]) and any(
                e.get("name") == "raise" for e in (o_runs[s].outputs or {}).get("effects", [])):
            continue
        host_end = (o_runs[s].outputs or {}).get("host_end")
        if ended[s] and not on and host_end is not None and not (c_runs and _raised(c_runs[s])):
            continue
        if not ended[s] and not capped[s] and host_end is not None:
            reasons.append(f"sample {_skey(o_runs[s].sample)}: the C program returns and ours ended in a host "
                           f"call with status {host_end}")
        if ended[s] and not on:
            reasons.append(f"sample {_skey(o_runs[s].sample)}: the C program ends early (noreturn or fatal raise) "
                           f"and no kept abort flag of ours reads 1")
        elif not ended[s] and not capped[s] and on:
            reasons.append(f"sample {_skey(o_runs[s].sample)}: the C program returns and our abort flag(s) "
                           f"{on} read 1")
    return reasons


# ---------------------------------------------------------------- pointers and memory (module docstring)

def _addr_table(rr: RunResult) -> Tuple[List[Tuple[int, int, str]], List[Tuple[int, int, str]]]:
    """(objects, regions) of one run: (lo, hi inclusive of one past the end, name)."""
    out = rr.outputs if isinstance(rr.outputs, dict) else {}
    objs = [(_int(o["addr"]), _int(o["addr"]) + int(o.get("size", 0)), o["name"]) for o in out.get("objects", [])]
    objs += [(_int(m["addr"]), _int(m["addr"]) + _mem_bytes(m), m["name"]) for m in out.get("mem", []) if "addr" in m]
    objs.sort(key=lambda t: t[1] - t[0])
    regs = [(_int(g["lo"]), _int(g["hi"]), g["name"]) for g in out.get("regions", [])]
    return objs, regs


def _addr_token(v: int, table: Tuple[list, list], against: str) -> Any:
    """What a 64-bit value reads as relationally (module docstring): v itself unless it lies in a known
    object or region of its run. An object's own bytes come first: one past the end of an object is the
    first byte of the next where the linker placed them adjacent (cq-l1fc8), and that differs per link."""
    for lo, hi, name in table[0]:
        if lo <= v < hi:
            return (name, v - lo)
    for lo, hi, name in table[0]:
        if v == hi:
            return (name, v - lo)
    for lo, hi, name in table[1]:
        if lo <= v < hi:
            return "<mem>" if against == "c" else (name, v - lo) if name == "heap" else name
    return v


def _mem_bytes(m: Dict[str, Any]) -> int:
    w = m.get("w")
    if w == "f80":
        return 10
    b = _bits(w)
    if b is None:
        raise CompareError(f"cq: unimplemented: chk-compare: a memory output with no width {m!r}")
    return (b + 7) // 8


def _memory(rr: RunResult, against: str) -> Dict[Tuple[str, int], Any]:
    """The named outputs of one run: (name, byte offset) -> the byte, or, at an aligned word that holds a
    pointer of this run (module docstring), its relational token at the word's offset and None at the
    other seven bytes."""
    out = rr.outputs if isinstance(rr.outputs, dict) else {}
    table = _addr_table(rr)
    addr_of = {o["name"]: _int(o["addr"]) for o in out.get("objects", [])}
    cells: Dict[Tuple[str, int], Any] = {}
    for m in out.get("mem", []):
        name, off, n = m["name"], int(m.get("off", 0)), _mem_bytes(m)
        val = _int(m["v"]) or 0
        base = _int(m["addr"]) if "addr" in m else addr_of.get(name)
        if base is not None:
            base += int(m.get("off", 0))
        i = 0
        while i < n:
            if base is not None and (base + i) % 8 == 0 and i + 8 <= n:
                word = (val >> (8 * i)) & ((1 << 64) - 1)
                tok = _addr_token(word, table, against)
                if tok != word:
                    cells[(name, off + i)] = tok
                    for j in range(1, 8):
                        cells[(name, off + i + j)] = None
                    i += 8
                    continue
            cells[(name, off + i)] = (val >> (8 * i)) & 0xFF
            i += 1
    return cells


def _memory_reasons(k: str, o: RunResult, r: RunResult, against: str) -> List[str]:
    co, cr = _memory(o, against), _memory(r, against)
    if co == cr:
        return []
    names = sorted({n for n, _ in co} | {n for n, _ in cr})
    why = []
    for name in names:
        po = {i: v for (n, i), v in co.items() if n == name}
        pr = {i: v for (n, i), v in cr.items() if n == name}
        if not po or not pr:
            why.append(f"sample {k}: memory output {name} exists only on the "
                       f"{'our' if po else 'other'} side (CR §6 item 1)")
        elif po != pr:
            i = min(j for j in set(po) | set(pr) if po.get(j) != pr.get(j))
            why.append(f"sample {k}: memory output {name} differs at byte {i}: ours {po.get(i)} != {pr.get(i)} "
                       f"(CR §6 item 1)")
    return why


def _rel_value(rr: RunResult, v: Optional[int], w: Optional[str], against: str, memo: Dict[int, Any]) -> Any:
    """A rail's value as compared: masked to its type, and an i64 relationally."""
    v = _masked(v, w)
    if w != "i64" or v is None:
        return v
    t = memo.get(id(rr))
    if t is None:
        t = memo[id(rr)] = _addr_table(rr)
    return _addr_token(v, t, against)


# ---------------------------------------------------------------- driver

def _call_key(sample: Any) -> Hashable:
    return _skey(sample.get("call")) if isinstance(sample, dict) else ""


def compare(ours: Sequence[RunResult], other: Sequence[RunResult], against: str,
            classical_key: Optional[Callable[[Any], Hashable]] = None,
            registers: Optional[Dict[str, Any]] = None) -> List[str]:
    """§6 equality of `ours` and `other` over all samples; the reasons, empty when equal.

    `registers` (optional, against "c"; drivers.theta_registers of the C program's .O1.ll, beads
    cq-ia96, cq-yzuc): the register web and seed sources of each cq_theta site, which tell CR rule
    10's overwrite from an in-place rotation. Without it no rule-10 un-prep stands (it is then an
    unmatched gate).

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
    capkeys: Set[Tuple[str, int]] = set()   # the leak rule's a_K: (loop, act) the C oracle capped on some sample
    if oracle == "c":
        for k in keys:
            capkeys.update((r["loop"], r["act"]) for r in _loops(r_by[k]) if r["capped"])
            ended[k] = _ended(r_by[k])
            cap = _cap(r_by[k])
            capped[k] = cap is not None
            if cap is not None:
                r_by[k] = _truncate(r_by[k], cap)      # a cut inside a cq_invert region closes it (cq-088c)

    # rulings Q8: rule 16's stated deviation is excluded from the C-oracle comparison on that input
    if oracle == "c":
        keys = [k for k in keys if not _deviated(o_by[k])]

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
            reasons.append(f"sample {k}: outputs {_rest(o.outputs, 'our')} != {_rest(r.outputs, 'reference')}")
        if not (oracle == "c" and (capped[k] or ended[k])):
            reasons += _memory_reasons(k, o, r, oracle)
        reasons += _host_output(k, o, r, oracle, oracle == "c" and (capped[k] or _raised(r)))
        if oracle == "ref":
            reasons += _measured_positional(k, o, r, False, nan_eq)
        else:
            meas_opts[k], why = _meas_options(k, o, r, capped[k] or ended[k], nan_eq)
            reasons += why
        for side, rr in (("our", o), ("oracle", r)) if oracle == "ref" else (("our", o),):
            for c in rr.clean or []:
                if "freed" in c:
                    continue           # the compact trace's summary of the sample's frees (run.py)
                # rulings ("Every _unc must leave 0"): legal iff the rail is classical-valued or reads 0
                # (never non-zero across the samples: each sample is checked here)
                known = c.get("known")
                if not (known is not None and _int(known)) and _int(c.get("v")) != 0:
                    reasons.append(f"sample {k}: {side} side frees rail {c.get('h')} = {c.get('v')} "
                                   f"not in a known basis state")
        if oracle == "c":
            reasons += _leaks(k, o, r_by[k], capped[k] or ended[k], capkeys)

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

    # CR rules 2, 19: the functions some input of the call enters, which the C oracle reports entries of
    entered_any: Dict[Hashable, set] = {}
    for k in meas_opts:
        entered_any.setdefault(_call_key(r_by[k].sample), set()).update((r_by[k].outputs or {}).get("entered", []))

    def _meas_extra(k: str) -> List[str]:
        ms = o_by[k].measured or []
        n = len(ms)
        here = (r_by[k].outputs or {}).get("entered", [])
        anywhere = entered_any[_call_key(r_by[k].sample)]
        known = {i for i in ident[_pool(k)]
                 if i >= n or ms[i].get("fn") not in anywhere or ms[i].get("fn") in here}
        opts = meas_opts[k]
        if any(all(i in img or i in past or i in known for i in range(n)) for img, past in opts):
            return []
        img, past = opts[0]
        bad = [i for i in range(n) if i not in img and i not in past and i not in known]
        hs = [o_by[k].measured[i].get("h") for i in bad]
        return [f"sample {k}: our measurement(s) {bad} (rails {hs}) match no C measurement here, and no sample "
                f"of the call identifies them with one the C program reaches in a function this input enters (only "
                f"CR rule 2's hoisted arm measurement may be extra)"]

    for gk, ks in groups.items():
        tag = f"classical arguments {gk[0]} ({len(ks)} samples)"
        o_runs = [o_by[k] for k in ks]
        r_runs = [r_by[k] for k in ks]
        o_regs: Dict[Tuple[int, int], Tuple] = {}
        o_evs, o_glob, o_idle = _lowered_events(o_runs, o_regs)
        if oracle == "ref":
            r_regs: Dict[Tuple[int, int], Tuple] = {}
            r_evs, _, _ = _lowered_events(r_runs, r_regs)
            kept_o = _kept_multiset(o_runs, oracle)
            kept_r = _kept_multiset(r_runs, oracle)
            if kept_o != kept_r:
                for cls in sorted(set(kept_o) | set(kept_r), key=repr):
                    d = kept_o.get(cls, 0) - kept_r.get(cls, 0)
                    if d > 0:
                        reasons.append(f"{tag}: {d} rail(s) {cls[0]} with values {_fn(cls[1])} kept on our side "
                                       f"that the reference does not keep (it cleans them or never makes them)")
                    elif d < 0:
                        reasons.append(f"{tag}: {-d} rail(s) {cls[0]} with values {_fn(cls[1])} the reference "
                                       f"keeps are not kept on our side")
            why = _match_lists(o_evs, r_evs, o_regs, r_regs)
            if why:
                reasons.append(f"{tag}: rotation list differs: {why}")
        else:
            c_ident: Dict[Tuple, List[List[Tuple[int, Any, Optional[int]]]]] = {}
            sites, why_c = _c_sites(r_runs, nan_eq, [capped[k] or ended[k] for k in ks], c_ident)
            if why_c:
                reasons += [f"{tag}: {why}" for why in why_c]
                continue
            for why in _match_c(o_evs, o_glob, sites, nan_eq, [capped[k] or ended[k] for k in ks], o_idle,
                                c_ident, registers, [_mprefix(r, None, nan_eq) for r in r_runs], o_regs):
                reasons.append(f"{tag}: {why}")
            for why in _check_ak(o_runs, r_runs, [ended[k] for k in ks]):
                reasons.append(f"{tag}: {why}")
            for why in _check_abort(o_runs, [ended[k] for k in ks], [capped[k] for k in ks], r_runs):
                reasons.append(f"{tag}: {why}")
            for why in _check_k2(o_runs, r_runs, [capped[k] or ended[k] for k in ks]):
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
        # a measurement of ours left over that reads what the C program read classically (its "read"
        # sites, outputs["reads"]): the circuit measured a load copy of it, which is no difference
        # Rule 19: so is one of a _ctl clone's controlled copies reading 0, its predicate 0 on this input
        reads = (r.outputs or {}).get("reads", []) if isinstance(r.outputs, dict) else []
        ctl = set((o.outputs or {}).get("ctl_measured", [])) if isinstance(o.outputs, dict) else set()
        if reads or ctl:
            for img in list(opts):
                left = list(reads)
                extra = set()
                for i in range(n):
                    if i not in img:
                        if mo[i].get("h") in ctl and _int(mo[i].get("v")) == 0:
                            extra.add(i)
                            continue
                        for b in left:
                            if not _meas_eq(o, r, mo[i], b, nan_eq):
                                left.remove(b)
                                extra.add(i)
                                break
                opts[img] = opts[img] | frozenset(extra)
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


_HOST_KEYS = ("stdout", "effects", "tape", "deviation", "mem", "objects", "regions", "ctl_measured", "entered", "host_flags")


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


def _field_read(a: Dict[str, Any], table: Tuple[list, list], oracle: str) -> Dict[str, Any]:
    if "s" in a:
        return {"s": a["s"]}
    v = _masked(_int(a.get("v")), a.get("w"))
    if a.get("w") == "i64" and v is not None:
        v = _addr_token(v, table, oracle)
    return dict({"w": a.get("w"), "v": v}, **({"cap": a["cap"]} if "cap" in a else {}), **({"p": 1} if a.get("p") else {}))


def _effects_read(rr: RunResult, fx: List[Any], oracle: str) -> List[Any]:
    """The effect sequence of one side as compared (module docstring, rulings Q8): the name and the fields,
    every pointer-valued one read relationally."""
    table = _addr_table(rr)
    return [{"name": e["name"], "args": [_field_read(a, table, oracle) for a in e["args"]]} for e in fx]


def _tape_read(rr: RunResult) -> List[Any]:
    """The shot's event sequence as compared against the reference."""
    table = _addr_table(rr)
    out = []
    for e in (rr.outputs or {}).get("tape", []):
        ent = dict(e)
        if "fields" in e:
            ent["fields"] = [_field_read(a, table, "ref") for a in e["fields"]]
        if "r" in e:
            ent["r"] = _field_read(e["r"], table, "ref")
        out.append(ent)
    return out


def _fields_match(ours: List[Any], other: List[Any]) -> bool:
    """Effect sequences against the C oracle: a value neither run could place in an object or region
    (a libc stream, say) passed as a pointer by the C program is equal when both are non-null or both
    null (CR §6: pointers compare relationally). A capture is compared where both sides made one."""
    if len(ours) != len(other):
        return False
    for a, b in zip(ours, other):
        if a["name"] != b["name"] or len(a["args"]) != len(b["args"]):
            return False
        for x, y in zip(a["args"], b["args"]):
            if "cap" in x and "cap" in y and x["cap"] != y["cap"]:
                return False
            if x.get("v") == y.get("v") and x.get("w") == y.get("w") and x.get("s") == y.get("s"):
                continue
            if y.get("p") and isinstance(x.get("v"), int) and isinstance(y.get("v"), int) and bool(x["v"]) == bool(y["v"]):
                continue
            return False
    return True


def _deviated(o: RunResult) -> bool:
    """Rule 16's stated deviation (module docstring)."""
    return bool((o.outputs or {}).get("deviation"))


def _split_gap(k: str, ofx: List[Any], rfx: List[Any]) -> None:
    """Rulings 2 C (cq-kzfv): a printf's excess arguments are its format entry's fields and ignored (CR rule 16), but for
    a callee of no known arity the ABI gives no boundary between them and the effect entry's fields, so rt_tape.c gives
    the effect all of them. The C call having fewer arguments shows such an excess. The comparison cannot be decided,
    and neither side is wrong: an internal error, never a FAIL."""
    for a, b in zip(ofx, rfx):
        if a.get("split_open") and a.get("name") == b.get("name") and len(a["args"]) > len(b["args"]):
            raise CompareError(f"cq: unimplemented: sample {k}: effect {a.get('name')!r} takes {len(a['args'])} fields, "
                               f"its C call {len(b['args'])}: a format entry's excess fields with no boundary before an "
                               f"effect of unknown arity (SPEC_ISSUES: ABI 1.11 vs rule 16, cq-kzfv)")


def _host_output(k: str, o: RunResult, r: RunResult, oracle: str, open_end: bool) -> List[str]:
    """The host-output reasons of one sample (module docstring, Host output)."""
    other = "C" if oracle == "c" else "reference"
    (os_, ofx), (rs, rfx) = _host(o.outputs, "our"), _host(r.outputs, other)
    if oracle == "c":
        _split_gap(k, ofx, rfx)
    why = []
    if os_ != rs and not (open_end and os_.startswith(rs)):
        why.append(f"sample {k}: host stdout differs: ours {os_!r} != {other} {rs!r}"
                   + (" (the C output must be a prefix of ours on a capped sample)" if open_end else ""))
    nf, nr = _effects_read(o, ofx, oracle), _effects_read(r, rfx, oracle)
    same = _fields_match(nf, nr) if oracle == "c" else nf == nr
    pre = open_end and (_fields_match(nf[:len(nr)], nr) if oracle == "c" else nf[:len(nr)] == nr)
    if not same and not pre:
        why.append(f"sample {k}: host effects differ: ours {ofx} != {other} {rfx}"
                   + (" (the C effects must be a prefix of ours on a capped sample)" if open_end else ""))
    if oracle == "ref":
        to, tr = _tape_read(o), _tape_read(r)
        if to != tr:
            i = next((j for j, (x, y) in enumerate(zip(to, tr)) if x != y), min(len(to), len(tr)))
            why.append(f"sample {k}: the event sequence differs at entry {i}: ours {to[i:i + 1]} != reference {tr[i:i + 1]} "
                       f"({len(to)} and {len(tr)} entries; rulings Q8)")
    return why


def _kept_type(rr: RunResult, h: Any) -> Optional[str]:
    """The type of handle h in rr's kept list (a measured rail stays live), or None."""
    if h is None:
        return None
    for k in rr.kept or []:
        if k.get("h") == h and k.get("w"):
            return k["w"]
    return None


def _kept_multiset(runs: List[RunResult], against: str = "ref") -> Dict[Tuple, int]:
    hs = [k["h"] for k in _kept_rows(runs[0])]
    pos = {h: i for i, h in enumerate(hs)}
    ws: List[Optional[str]] = [None] * len(hs)
    cols: List[List[Any]] = [[] for _ in hs]
    memo: Dict[int, Any] = {}
    for rr in runs:
        seen = 0
        for ent in _kept_rows(rr):
            i = pos.get(ent["h"])
            if i is None:
                continue
            ws[i] = ws[i] or ent.get("w")
            cols[i].append(_rel_value(rr, _int(ent.get("v")), ws[i], against, memo))
            seen += 1
        if seen != len(hs):
            raise StopIteration          # the group's runs keep the same rails (their shapes are equal)
    out: Dict[Tuple, int] = {}
    for w, col in zip(ws, cols):
        cls = (w, tuple(col))
        out[cls] = out.get(cls, 0) + 1
    return out
