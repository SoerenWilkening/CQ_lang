"""Unit tests of checker/cqcheck/compare.py on synthetic RunResults (bead cq-w0-chk-compare).

Two i1 registers a, b (handles of the side's choosing) seeded exhaustively: samples s = 0..3 with
a = s & 1, b = s >> 1. Every case states which §6 clause decides it.
"""
import dataclasses
import os
import struct
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "checker"))

from cqcheck.contracts import DriverSpec, RunResult  # noqa: E402
from cqcheck.compare import classical_key_from_driver  # noqa: E402
from cqcheck.compare import compare as _compare  # noqa: E402


class _C:
    def __init__(self, reasons):
        self.reasons = reasons
        self.equal = not reasons


def compare(ours, other, key, against):
    """The frozen compare(ours, other, against) -> List[str], with the optional classical key."""
    reasons = _compare(ours, other, against, classical_key=key)
    assert isinstance(reasons, list)
    return _C(reasons)

PI = 3.141592653589793


def ang(x):
    return hex(struct.unpack("<Q", struct.pack("<d", x))[0])


def ry(h, theta, ctl=(), ctlv=()):
    return {"ev": "ry", "h": h, "theta": ang(theta), "ctl": list(ctl), "ctlv": list(ctlv)}


def ryq(h, a, aval, ctl=(), ctlv=()):
    return {"ev": "ry_qangle", "h": h, "a": a, "aval": ang(aval), "ctl": list(ctl), "ctlv": list(ctlv)}


def ph(f, fv, theta):
    return {"ev": "phase", "f": f, "fv": int(fv), "theta": ang(theta)}


def phq(a, aval, ctl=(), ctlv=()):
    return {"ev": "phase_qangle", "a": a, "aval": ang(aval), "ctl": list(ctl), "ctlv": list(ctlv)}


def keep(h, v, w="i1", role="frozen"):
    return {"h": h, "w": w, "v": hex(v), "role": role}


def run(side, s, rots, kept, clean=(), outputs=None, measured=(), violations=()):
    return RunResult(side=side, sample={"call": 0, "args": [s & 1, s >> 1]}, outputs=outputs or {},
                     measured=list(measured), rotations=list(rots), kept=list(kept), clean=list(clean),
                     violations=list(violations))


def side(name, build, samples=range(4)):
    """build(a, b, s) -> dict(rots=…, kept=…, …) for one sample."""
    return [run(name, s, **build(s & 1, s >> 1, s)) for s in samples]


DRIVER = DriverSpec(example="t", protos=[], setup="",
                    calls=[{"fn": "f", "args": [{"ctype": "bool", "quantum": True},
                                                {"ctype": "bool", "quantum": True}]}])
QKEY = classical_key_from_driver(DRIVER)
# the same samples where b is a classical argument
CDRIVER = DriverSpec(example="t", protos=[], setup="",
                     calls=[{"fn": "f", "args": [{"ctype": "bool", "quantum": True},
                                                 {"ctype": "bool", "quantum": False}]}])
CKEY = classical_key_from_driver(CDRIVER)


def ref_ab(extra=()):
    """Reference: Ry(1.0) on a (h=1), Ry(2.0) on b (h=2), then a phase on the flag a&b."""
    return lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a & b, 0.5)] + list(extra),
                                kept=[keep(1, a), keep(2, b)], clean=[{"h": 7, "v": "0x0", "known": 1}])


class Equalities(unittest.TestCase):
    def ok(self, ours, ref, key=QKEY, oracle="ref"):
        c = compare(ours, ref, key, oracle)
        self.assertTrue(c.equal, c.reasons)

    def bad(self, ours, ref, needle, key=QKEY, oracle="ref"):
        c = compare(ours, ref, key, oracle)
        self.assertFalse(c.equal)
        self.assertTrue(any(needle in r for r in c.reasons), c.reasons)

    def test_identical(self):
        self.ok(side("o", ref_ab()), side("r", ref_ab()))

    # -- reordering
    def test_disjoint_reordering_accepted(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(2, 2.0), ry(1, 1.0), ph(7, a & b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.ok(ours, side("r", ref_ab()))

    def test_phase_moves_past_independent_ry(self):
        # P on flag a commutes with Ry on b: its predicate does not depend on b
        ref = side("r", lambda a, b, s: dict(rots=[ry(1, 1.0), ph(7, a, 0.5), ry(2, 2.0)],
                                             kept=[keep(1, a), keep(2, b)]))
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(9, a, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.ok(ours, ref)

    def test_overlapping_reordering_rejected(self):
        # P(a&b) depends on b, so it does not commute with the Ry on b
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ph(7, a & b, 0.5), ry(2, 2.0)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    def test_same_target_reordering_rejected(self):
        ref = side("r", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(1, 2.0)], kept=[keep(1, a)]))
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 2.0), ry(1, 1.0)], kept=[keep(1, a)]))
        self.bad(ours, ref, "rotation list differs")

    def test_controlled_ry_does_not_pass_its_control(self):
        # Ry(b) controlled by a, Ry on a: the controlled gate reads a, the order is fixed
        ref = side("r", lambda a, b, s: dict(rots=[ry(2, 1.0, [1], [a]), ry(1, 2.0)], kept=[keep(1, a), keep(2, b)]))
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 2.0), ry(2, 1.0, [1], [a])], kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, ref, "rotation list differs")

    # -- commutation, owner ruling cq-vrwm (CR §6 item 2 amended): an Ry is ordered against a gate
    # acting on its target or non-diagonal on one of its controls; a phase not reading its target
    # commutes with it
    def test_ry_commutes_with_phase_on_its_control(self):
        # (each test rotates a first: a predicate is read over registers, the Ry targets)
        # 125/133: Ry(b) controlled by a, and a phase on a: both diagonal on a, either order
        def mk(first):
            return lambda a, b, s: dict(rots=[ry(1, 3.0)] + [ry(2, 1.0, [1], [a]), ph(7, a, 0.5)][::1 if first else -1],
                                        kept=[keep(1, a), keep(2, b)])
        self.ok(side("o", mk(True)), side("r", mk(False)))
        self.ok(side("o", mk(False)), side("r", mk(True)))

    def test_ry_ordered_against_phase_reading_its_target(self):
        # the phase's predicate a&b reads b, the Ry's target: the order is fixed
        def mk(first):
            return lambda a, b, s: dict(rots=[ry(1, 3.0)] + [ry(2, 1.0, [1], [a]), ph(7, a & b, 0.5)][::1 if first else -1],
                                        kept=[keep(1, a), keep(2, b)])
        self.bad(side("o", mk(True)), side("r", mk(False)), "rotation list differs")
        self.bad(side("o", mk(False)), side("r", mk(True)), "rotation list differs")

    def test_ry_ordered_against_nondiagonal_gate_on_its_control(self):
        # Ry(b) controlled by a, and an (uncontrolled) Ry on a: non-diagonal on the control
        def mk(first):
            return lambda a, b, s: dict(rots=[ry(1, 3.0)] + [ry(2, 1.0, [1], [a]), ry(1, 2.0)][::1 if first else -1],
                                        kept=[keep(1, a), keep(2, b)])
        self.bad(side("o", mk(True)), side("r", mk(False)), "rotation list differs")
        self.bad(side("o", mk(False)), side("r", mk(True)), "rotation list differs")

    def test_ry_commutes_with_phase_on_its_control_rail_sampled(self):
        # sampled group (not a full grid over a, b, c): support is conservative, so the phase reads
        # every varying register; a phase on the Ry's own control rail (handle 9) that
        # is a function of that control (here its negation, 125's else-arm phase) still commutes
        smp = [0, 1, 2, 3, 5, 6]          # c = s >> 2 does not cross a, b fully

        def mk(first, f):
            return lambda a, b, s: dict(
                rots=[ry(1, 3.0), ry(3, 0.5)] + [ry(2, 1.0, [9], [a]), ph(f, 1 - a, 0.5)][::1 if first else -1],
                kept=[keep(1, a), keep(2, (s >> 1) & 1), keep(3, s >> 2)])
        self.ok(side("o", mk(True, 9), smp), side("r", mk(False, 9), smp))
        self.ok(side("o", mk(False, 9), smp), side("r", mk(True, 9), smp))
        # the same predicate on another rail: nothing shows it does not read b, the order is fixed
        self.bad(side("o", mk(True, 8), smp), side("r", mk(False, 8), smp), "rotation list differs")

    def test_rys_sharing_only_a_control_commute(self):
        # two Ry on distinct targets b, c under the same control a: block-diagonal in a, commute
        def mk(first):
            return lambda a, b, s: dict(rots=[ry(1, 3.0)] + [ry(2, 1.0, [1], [a]), ry(3, 2.0, [1], [a])][::1 if first else -1],
                                        kept=[keep(1, a), keep(2, b), keep(3, 0)])
        self.ok(side("o", mk(True)), side("r", mk(False)))

    # -- rails
    def test_rail_renaming_accepted(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(41, 1.0), ry(40, 2.0), ph(3, a & b, 0.5)],
                                              kept=[keep(40, b), keep(41, a)]))
        self.ok(ours, side("r", ref_ab()))

    def test_renaming_is_a_bijection(self):
        # two Ry on one |0> rail are not one Ry on each of two |0> rails (same kept multiset)
        ref = side("r", lambda a, b, s: dict(rots=[ry(5, 1.0), ry(6, 1.0)], kept=[keep(5, 0), keep(6, 0)]))
        ours = side("o", lambda a, b, s: dict(rots=[ry(5, 1.0), ry(5, 1.0)], kept=[keep(5, 0), keep(6, 0)]))
        self.bad(ours, ref, "rotation list differs")

    def test_target_matched_by_value_function(self):
        # rotating b where the reference rotates a: same type, different value function
        ours = side("o", lambda a, b, s: dict(rots=[ry(2, 1.0), ry(1, 2.0), ph(7, a & b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    def test_angle_differs_rejected(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.5), ph(7, a & b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    def test_zero_angle_is_no_gate(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"] + [ry(1, 0.0), ph(3, a, -0.0)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.ok(ours, side("r", ref_ab()))

    # -- phases (CR §6.2)
    def test_ccp_bracket_equals_flag_phase(self):
        # reference: and_i1(a, b, t) · rz_i1(t, θ) · and_i1 (t = rail 7, a fresh |0> flag, freed);
        # ours: the conjunction as a template result on rail 12, uncomputed and freed. Same e^{iθ·(a&b)}.
        ref = side("r", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a & b, 0.5)],
                                             kept=[keep(1, a), keep(2, b)], clean=[{"h": 7, "v": 0, "known": 1}]))
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(12, a & b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)],
                                              clean=[{"h": 12, "v": 0, "known": 1}, {"h": 11, "v": 0, "known": 1}]))
        self.ok(ours, ref)

    def test_controlled_rz_vs_p_rejected(self):
        # CRz(θ) on (a, t=b) = P(θ) on a&b times P(-θ/2) on a: a relative phase, never equal to CP
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a & b, 0.5), ph(1, a, -0.25)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    def test_phase_predicate_differs_rejected(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a | b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    # -- phases compared as a total (CR §6 item 2, ruling 2026-11-01 on cq-u2mw, 117)
    @staticmethod
    def edges(extra=(), angles=(PI, PI, PI), mid=()):
        """Reference: per-edge phases on the pairwise-disjoint predicates a&b, a&!b, !a&b (117's
        per-exit-edge kickback), each after both Ry; `mid` goes between the first edge and the rest."""
        def build(a, b, s):
            ps = [ph(21, a & b, angles[0]), ph(22, a & (1 - b), angles[1]), ph(23, (1 - a) & b, angles[2])]
            return dict(rots=[ry(1, 1.0), ry(2, 2.0)] + ps[:1] + list(mid) + ps[1:] + list(extra),
                        kept=[keep(1, a), keep(2, b)])
        return build

    @staticmethod
    def or_phase(theta=PI, name="o"):
        """One phase on the OR of the edges (a conforming pass's rz_i1 on the block predicate)."""
        return side(name, lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(30, a | b, theta)],
                                               kept=[keep(1, a), keep(2, b)]))

    def test_phase_total_disjoint_or_accepted(self):
        # one phase on the OR of disjoint predicates = the per-edge phases of the same angle, either side
        self.ok(self.or_phase(), side("r", self.edges()))
        self.ok(side("o", self.edges()), self.or_phase(name="r"))
        self.ok(self.or_phase(0.5), side("r", self.edges(angles=(0.5, 0.5, 0.5))))

    def test_phase_total_split_differently_accepted(self):
        # P(a)·P(b) = P(a&b)^2 · P(a&!b) · P(!a&b) in total: 0.5·a + 0.5·b
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(5, a, 0.5), ph(6, b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.ok(ours, side("r", self.edges(angles=(1.0, 0.5, 0.5))))

    def test_phase_total_multiple_of_two_pi(self):
        # π + π on a&b is the identity there: the total agrees mod 2π
        ours = self.or_phase()
        ref = side("r", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(21, a & b, PI), ph(24, a & b, PI),
                                                   ph(22, a & (1 - b), PI), ph(23, (1 - a) & b, PI)],
                                             kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, ref, "phase totals differ")
        ours2 = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(30, a ^ b, PI)],
                                               kept=[keep(1, a), keep(2, b)]))
        self.ok(ours2, ref)

    def test_phase_total_dropped_edge_rejected(self):
        # mutant: one edge's phase dropped from the reference (or ours)
        def dropped(a, b, s):
            r = self.edges()(a, b, s)
            r["rots"] = [g for g in r["rots"] if g.get("f") != 22]
            return r
        self.bad(self.or_phase(), side("r", dropped), "phase totals differ")
        self.bad(side("o", dropped), side("r", self.edges()), "phase totals differ")

    def test_phase_total_changed_angle_rejected(self):
        # mutant: one edge's angle changed, by a lot or by one ulp (a total that is 0 is 0 exactly)
        ulp = struct.unpack("<d", struct.pack("<Q", struct.unpack("<Q", struct.pack("<d", PI))[0] + 1))[0]
        for bad_angle in (PI / 2, ulp):
            self.bad(self.or_phase(), side("r", self.edges(angles=(PI, bad_angle, PI))), "phase totals differ")
        self.bad(self.or_phase(0.5), side("r", self.edges()), "phase totals differ")

    def test_phase_total_not_across_an_ry_it_reads(self):
        # an Ry on b between the reference's first edge and the rest: the edges read b, so the total
        # cannot be gathered on either side of it; with the Ry on a rail no edge reads, it can
        def ours(rail):
            return side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ry(rail, 0.7), ph(30, a | b, PI)],
                                                  kept=[keep(1, a), keep(2, b), keep(3, 0)]))

        def ref(rail):
            return side("r", lambda a, b, s: dict(
                rots=self.edges(mid=[ry(rail, 0.7)])(a, b, s)["rots"], kept=[keep(1, a), keep(2, b), keep(3, 0)]))
        self.ok(ours(3), ref(3))
        self.bad(ours(2), ref(2), "rotation list differs")

    def test_phase_total_angle_rail(self):
        # an angle-rail phase contributes its rail's value: rz_qangle on a|b with the rail reading π
        # equals the per-edge classical phases; a constant total of an angle rail is never global
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), phq(8, PI, [30], [a | b])],
                                              kept=[keep(1, a), keep(2, b)]))
        self.ok(ours, side("r", self.edges()))
        ours2 = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), phq(8, PI if a | b else 0.25, [], [])],
                                               kept=[keep(1, a), keep(2, b)]))
        self.bad(ours2, side("r", self.edges()), "phase totals differ")

    # -- global phases (CR §6, last paragraph)
    def test_global_phase_dropped_either_side(self):
        ours = side("o", ref_ab([ph(9, 1, 0.75)]))           # uncontrolled Rz = P up to this
        self.ok(ours, side("r", ref_ab()))
        self.ok(side("o", ref_ab()), side("r", ref_ab([ph(9, 1, 0.75)])))

    def test_global_phase_needs_constant_predicate(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"] + [ph(9, b, 0.75)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    def test_global_phase_constant_once_classical_args_fixed(self):
        # predicate b: constant within each classical group when b is a classical argument ...
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"] + [ph(9, b, 0.75)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.ok(ours, side("r", ref_ab()), key=CKEY)
        # ... and compared when b is quantum
        self.bad(ours, side("r", ref_ab()), "rotation list differs", key=QKEY)

    def test_global_phase_never_an_angle_rail(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"] + [phq(8, 0.75)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "rotation list differs")

    def test_global_phase_never_an_ry(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"] + [ry(9, 0.75)],
                                              kept=[keep(1, a), keep(2, b), keep(9, 0)]))
        ref = side("r", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"],
                                             kept=[keep(1, a), keep(2, b), keep(9, 0)]))
        self.bad(ours, ref, "rotation list differs")

    def test_angle_rail_compared_by_value(self):
        mk = lambda d: side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ryq(1, 5, 0.25 + d * a, [2], [b])],
                                                      kept=[keep(1, a), keep(2, b)]))
        self.ok(mk(1.0), mk(1.0))
        self.bad(mk(1.0), mk(2.0), "rotation list differs")

    # -- permutation part
    def test_kept_multiset_extra_rejected(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"],
                                              kept=[keep(1, a), keep(2, b), keep(9, (a + b) & 3, "i2", "garbage")]))
        self.bad(ours, side("r", ref_ab()), "kept on our side")

    def test_kept_multiset_missing_rejected(self):
        ref = side("r", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"],
                                             kept=[keep(1, a), keep(2, b), keep(9, a ^ b, "i1", "kept_entangled")]))
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"], kept=[keep(1, a), keep(2, b)],
                                              clean=[{"h": 9, "v": 0, "known": 1}]))
        self.bad(ours, ref, "not kept on our side")

    def test_kept_multiset_order_and_role_free(self):
        ref = side("r", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"],
                                             kept=[keep(1, a), keep(2, b), keep(9, a ^ b, "i1", "kept_entangled")]))
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"],
                                              kept=[keep(30, a ^ b, "i1", "garbage"), keep(2, b), keep(1, a)]))
        self.ok(ours, ref)

    def test_dirty_free_rejected(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"], kept=[keep(1, a), keep(2, b)],
                                              clean=[{"h": 7, "v": hex(a & b), "known": 0}]))
        self.bad(ours, side("r", ref_ab()), "not in a known basis state")

    def test_known_seed_free_accepted(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"], kept=[keep(1, a), keep(2, b)],
                                              clean=[{"h": 13, "v": "0x1", "known": 1}]))
        self.ok(ours, side("r", ref_ab()))

    def test_outputs_and_measurements(self):
        base = lambda out, m: side("x", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"], kept=[keep(1, a), keep(2, b)],
                                                             outputs={"ret": hex(out(a, b))},
                                                             measured=[{"h": 1, "w": "i1", "v": m(a, b)}]))
        good = base(lambda a, b: a + b, lambda a, b: a)
        self.ok(base(lambda a, b: a + b, lambda a, b: a), good)
        self.bad(base(lambda a, b: a ^ b, lambda a, b: a), good, "outputs")
        self.bad(base(lambda a, b: a + b, lambda a, b: b), good, "measurement 0 reads")

    def test_violation_rejected(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"], kept=[keep(1, a), keep(2, b)],
                                              violations=[{"what": "unc residue", "h": 4}] if s == 3 else []))
        self.bad(ours, side("r", ref_ab()), "violations on our side")

    def test_empty_output_rejected(self):
        self.bad([], side("r", ref_ab()), "no run on our side")
        empty = side("o", lambda a, b, s: dict(rots=[], kept=[]))
        self.bad(empty, side("r", ref_ab()), "not kept on our side")

    def test_frozen_signature_without_classical_key(self):
        self.assertEqual(_compare(side("o", ref_ab()), side("r", ref_ab()), "ref"), [])
        self.assertEqual(_compare(side("o", ref_ab([ph(9, 1, 0.75)])), side("r", ref_ab()), "ref"), [])
        bad = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ph(7, a & b, 0.5), ry(2, 2.0)],
                                             kept=[keep(1, a), keep(2, b)]))
        self.assertTrue(_compare(bad, side("r", ref_ab()), "ref"))
        self.assertTrue(_compare([], side("r", ref_ab()), "c"))

    def test_structure_varying_with_quantum_input_rejected(self):
        ours = side("o", lambda a, b, s: dict(rots=ref_ab()(a, b, s)["rots"] if a else ref_ab()(a, b, s)["rots"][:2],
                                              kept=[keep(1, a), keep(2, b)]))
        self.bad(ours, side("r", ref_ab()), "structure varies")


class COracle(unittest.TestCase):
    """oracle "c": rotations matched by site (§6.2 point by point)."""

    @staticmethod
    def csite(fn, site, kind, angle, reg=None):
        return {"ev": "site", "fn": fn, "site": site, "kind": kind, "angle": ang(angle),
                "reg": None if reg is None else hex(reg)}

    def c_side(self, extra=lambda a, b: []):
        return side("c", lambda a, b, s: dict(
            rots=[self.csite("f", 1, "theta", 1.0, a), self.csite("f", 2, "theta", 2.0, b)]
            + ([self.csite("f", 3, "phi", 0.5)] if a & b else []) + extra(a, b), kept=[]))

    def test_equal(self):
        c = compare(side("o", ref_ab()), self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)

    def test_wrong_predicate(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a | b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        c = compare(ours, self.c_side(), QKEY, "c")
        self.assertFalse(c.equal)

    def test_missing_gate(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ph(7, a & b, 0.5)], kept=[keep(1, a), keep(2, b)]))
        c = compare(ours, self.c_side(), QKEY, "c")
        self.assertFalse(c.equal)
        self.assertTrue(any("C site f:2" in r for r in c.reasons), c.reasons)

    def test_wrong_register(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(2, 1.0), ry(1, 2.0), ph(7, a & b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)]))
        self.assertFalse(compare(ours, self.c_side(), QKEY, "c").equal)

    def test_global_phi_either_side(self):
        c = compare(side("o", ref_ab()), self.c_side(lambda a, b: [self.csite("f", 4, "phi", 0.3)]), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)
        c = compare(side("o", ref_ab([ph(9, 1, 0.3)])), self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)

    def loop_c(self, a1=0.5, a2=0.5):
        """152's shape (bead cq-yonm): a two-trip loop whose body calls cq_phi (site f:5) on trip 1
        when a, on trip 2 when b. A skipped trip leaves no C reach, so on a=0, b=1 the site's first
        reach is trip 2's."""
        return side("c", lambda a, b, s: dict(
            rots=([self.csite("f", 5, "phi", a1)] if a else []) + ([self.csite("f", 5, "phi", a2)] if b else []),
            kept=[]))

    @staticmethod
    def loop_ours(p1, p2, a1=0.5, a2=0.5):
        return side("o", lambda a, b, s: dict(rots=[ph(21, p1(a, b), a1), ph(22, p2(a, b), a2)],
                                              kept=[keep(1, a), keep(2, b)]))

    def test_loop_site_matched_per_trip(self):
        c = compare(self.loop_ours(lambda a, b: a, lambda a, b: b), self.loop_c(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)
        c = compare(self.loop_ours(lambda a, b: a, lambda a, b: b, 0.5, 0.25), self.loop_c(0.5, 0.25), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)

    def test_loop_site_wrong_trip_predicate_rejected(self):
        for p2 in (lambda a, b: a & b, lambda a, b: a | b, lambda a, b: 0):
            c = compare(self.loop_ours(lambda a, b: a, p2), self.loop_c(), QKEY, "c")
            self.assertFalse(c.equal)
        # each trip's angle stays with its trip
        c = compare(self.loop_ours(lambda a, b: a, lambda a, b: b, 0.25, 0.5), self.loop_c(0.5, 0.25), QKEY, "c")
        self.assertFalse(c.equal)
        self.assertTrue(any("f:5" in r for r in c.reasons), c.reasons)

    def test_dropped_global_phase_keeps_its_reach(self):
        # 152 (bead cq-7bvs): a loop's cq_phi site reached on every trip where its predicate holds; on
        # this group trip 1's phase fires at every sample, so it is a dropped global phase. Trip 2's
        # phase (on a) must take trip 2's reach, after the theta between them that reads a, not trip
        # 1's reach (the earliest), which would put it before that theta.
        c_side = side("c", lambda a, b, s: dict(
            rots=[self.csite("f", 1, "theta", 1.0, a), self.csite("f", 5, "phi", 0.5),
                  self.csite("f", 2, "theta", 2.0, a)] + ([self.csite("f", 5, "phi", 0.5)] if a else []),
            kept=[]))
        ours = side("o", lambda a, b, s: dict(
            rots=[ry(1, 1.0), ph(21, 1, 0.5), ry(1, 2.0), ph(22, a, 0.5)], kept=[keep(1, a), keep(2, b)]))
        c = compare(ours, c_side, QKEY, "c")
        self.assertTrue(c.equal, c.reasons)
        # the global phase taking a reach hides no difference: trip 2's phase missing, or on b
        for rots in ([ry(1, 1.0), ph(21, 1, 0.5), ry(1, 2.0)],
                     [ry(1, 1.0), ph(21, 1, 0.5), ry(1, 2.0), ph(22, 2, 0.5)]):
            ours = side("o", lambda a, b, s: dict(
                rots=[dict(r, fv=b) if r.get("fv") == 2 else r for r in rots], kept=[keep(1, a), keep(2, b)]))
            self.assertFalse(compare(ours, c_side, QKEY, "c").equal)

    def test_order_against_dependent_gate(self):
        # the C program puts the phase on a&b before the Ry on b; the lowered order reverses them
        c_first = side("c", lambda a, b, s: dict(
            rots=[self.csite("f", 1, "theta", 1.0, a)] + ([self.csite("f", 3, "phi", 0.5)] if a & b else [])
            + [self.csite("f", 2, "theta", 2.0, b)], kept=[]))
        c = compare(side("o", ref_ab()), c_first, QKEY, "c")
        self.assertFalse(c.equal)
        self.assertTrue(any("do not commute" in r for r in c.reasons), c.reasons)

    def test_order_ry_commutes_with_phase_on_its_control(self):
        # owner ruling cq-vrwm: C reaches phi(a) then theta(b) under a; lowered emits the controlled
        # Ry first. Diagonal on a, the phase does not read b: either order. A phase reading b: ordered.
        for reads_b, equal in ((False, True), (True, False)):
            c_side = side("c", lambda a, b, s: dict(
                rots=[self.csite("f", 1, "theta", 1.0, a)] + ([self.csite("f", 3, "phi", 0.5)] if (a & b if reads_b else a) else [])
                + ([self.csite("f", 2, "theta", 2.0, b)] if a else []), kept=[]))
            ours = side("o", lambda a, b, s: dict(
                rots=[ry(1, 1.0), ry(2, 2.0, [1], [a]), ph(7, a & b if reads_b else a, 0.5)], kept=[keep(1, a), keep(2, b)]))
            c = compare(ours, c_side, QKEY, "c")
            self.assertEqual(c.equal, equal, c.reasons)

    # cq-holz: 117's shape at a small size. Ry(pi/2) on four counting rails (site q:0), A on three
    # search rails (q:1), four blocks A^dag (a:1), a phase (a:2), A (a:3) on the search rails, then
    # per counting rail a phase (q:3) and Ry(pi/2) (q:4). Every phase is a dropped global phase (its
    # flag is 1 at every sample), and every Ry(pi/2) agrees with four theta sites in angle and
    # register. Searched together, each late failure of the Ry choices retried every combination of
    # the phases' optional reaches: past the node budget on an equal pair. The Ry gates and the
    # phases share no site and no rail, so they are matched apart.
    def counting(self, mutant=""):
        h, xs, nt, nb = PI / 2, [50, 51, 52], 4, 4

        def c_side(a, b, s):
            r = [self.csite("q", 0, "theta", h, 0) for _ in range(nt)] + [self.csite("q", 1, "theta", h, 0) for _ in xs]
            if mutant == "extra":        # a C reach no lowered gate can take
                r.append(self.csite("q", 9, "theta", 0.7, 0))
            for _ in range(nb):
                r += ([self.csite("a", 1, "theta", -h, 0) for _ in xs] + [self.csite("a", 2, "phi", PI)]
                      + [self.csite("a", 3, "theta", h, 0) for _ in xs])
            for _ in range(nt):
                r += [self.csite("q", 3, "phi", PI), self.csite("q", 4, "theta", h, 0)]
            return dict(rots=r, kept=[])

        def o_side(a, b, s):
            r = [ry(1 + t, h) for t in range(nt)] + [ry(x, h) for x in xs]
            for k in range(nb):
                r += [ry(x, -h) for x in xs] + [ph(100 + k, 1, PI)] + [ry(x, h) for x in xs]
            if mutant == "angle":        # the last block's A on the third search rail negated
                r[-1] = ry(xs[2], -h)
            if mutant == "order":        # the last block's A^dag on the first search rail after its A
                i = len(r) - 7
                r[i], r[i + 4] = r[i + 4], r[i]
            for t in range(nt):
                r += [ph(200 + t, 1, PI), ry(1 + t, h)]
            return dict(rots=r, kept=[keep(x, 0) for x in list(range(1, nt + 1)) + xs])

        return compare(side("o", o_side), side("c", c_side), QKEY, "c")

    def test_independent_parts_matched_apart(self):
        c = self.counting()
        self.assertTrue(c.equal, c.reasons)

    def test_independent_parts_mutants_rejected(self):
        for mutant, why in (("angle", "corresponds to no C site"), ("extra", "C site q:9"), ("order", "")):
            c = self.counting(mutant)
            self.assertFalse(c.equal, mutant)
            self.assertTrue(any(why in r for r in c.reasons), (mutant, c.reasons))


class LeakRule(unittest.TestCase):
    """CR §6 item 1 (47b0a38, ruling 2026-11-01 on cq-nyto; cq-tt2j), against "c": a rail live at exit
    is a frozen register, a measured value, an output, a result or a rule-kept rail; anything else
    FAILS. A rail in a known basis state is no leak (owner ruling 2026-11-01 on cq-tt2j)."""

    def c_side(self, loops=None):
        cs = COracle().c_side()
        if loops is not None:
            cs = [dataclasses.replace(r, outputs=dict(r.outputs, loops=loops)) for r in cs]
        return cs

    def ours(self, extra):
        return side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a & b, 0.5)],
                                              kept=[keep(1, a), keep(2, b)] + extra(a, b)))

    @staticmethod
    def leak(h, v, w, role, known=False):
        return dict(keep(h, v, w, role), known=known)

    def test_kept_roles_pass(self):
        for role in ("measured", "abort", "tape", "qram_cell", "kept_entangled", "output"):
            c = compare(self.ours(lambda a, b: [self.leak(9, a ^ b, "i8", role)]), self.c_side(), QKEY, "c")
            self.assertTrue(c.equal, (role, c.reasons))

    def test_output_in_memory_passes(self):
        # the handle of the rail sits in an out-parameter's cell at exit (rt/core.c mark_outputs)
        c = compare(self.ours(lambda a, b: [self.leak(9, a ^ b, "i32", "output")]), self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)

    def test_garbage_fails(self):
        # an entangled garbage rail its sources could still clean, left live (c8, c7)
        c = compare(self.ours(lambda a, b: [self.leak(9, a ^ b, "i64", "garbage")]), self.c_side(), QKEY, "c")
        self.assertFalse(c.equal)
        self.assertTrue(any("a leak; cq-tt2j" in r and "9 (i64" in r for r in c.reasons), c.reasons)

    def test_result_passes(self):
        c = compare(self.ours(lambda a, b: [dict(self.leak(9, a ^ b, "i64", "garbage"), result=True)]),
                    self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)

    def test_known_basis_rail_passes(self):
        # owner ruling 2026-11-01: a seed never rotated, a rail only written from known values
        for ent in (self.leak(9, 5, "i32", "seed", known=True), self.leak(9, 5, "i32", "garbage", known=True)):
            c = compare(self.ours(lambda a, b: [ent]), self.c_side(), QKEY, "c")
            self.assertTrue(c.equal, (ent, c.reasons))

    def test_known_basis_switch(self):
        import cqcheck.compare as cmp
        old = cmp.LIVE_KNOWN_IS_LEAK
        cmp.LIVE_KNOWN_IS_LEAK = True
        try:
            c = compare(self.ours(lambda a, b: [self.leak(9, 5, "i32", "seed", known=True)]), self.c_side(), QKEY, "c")
            self.assertFalse(c.equal)
        finally:
            cmp.LIVE_KNOWN_IS_LEAK = old

    def test_rotated_seed_passes(self):
        c = compare(side("o", lambda a, b, s: dict(rots=[ry(1, 1.0), ry(2, 2.0), ph(7, a & b, 0.5)],
                                                   kept=[keep(1, a, role="seed"), keep(2, b)])),
                    self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)

    def test_rule23_one_flags_rail(self):
        # the final flags rail is an output (rule 23); a second flags-lineage rail is a leak
        one = [self.leak(9, 0, "i32", "fenv_flags")]
        c = compare(self.ours(lambda a, b: one), self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)
        c = compare(self.ours(lambda a, b: one + [self.leak(10, a, "i32", "fenv_mode")]), self.c_side(), QKEY, "c")
        self.assertTrue(c.equal, c.reasons)
        c = compare(self.ours(lambda a, b: one + [self.leak(10, a & b, "i32", "fenv_flags")]), self.c_side(), QKEY, "c")
        self.assertFalse(c.equal)
        self.assertTrue(any("a leak; cq-tt2j" in r and "fenv_flags" in r for r in c.reasons), c.reasons)

    def test_a_k_per_capped_activation(self):
        # one garbage i1 per recorded activation whose (loop, act) the C oracle capped on some sample
        from cqcheck.compare import _leaks
        rec = [{"loop": "f:%7", "act": 0, "n": 2, "capped": False}]
        c = self.c_side(rec)[0]
        o = self.ours(lambda a, b: [self.leak(9, 0, "i1", "garbage")])[0]
        self.assertEqual(_leaks("s", o, c, False, {("f:%7", 0)}), [])
        o2 = self.ours(lambda a, b: [self.leak(9, 0, "i1", "garbage"), self.leak(10, 0, "i1", "garbage")])[0]
        self.assertTrue(_leaks("s", o2, c, False, {("f:%7", 0)}))
        # never capped anywhere (bound B <= K, rule 14: no a_K is kept; the cutoff-h2 t3 review finding)
        self.assertTrue(_leaks("s", o, c, False, set()))
        self.assertTrue(_leaks("s", o, c, False, {("f:%7", 1)}))
        # through compare: no sample caps the loop, so the kept i1 is a leak
        r = compare(self.ours(lambda a, b: [self.leak(9, 0, "i1", "garbage")]), self.c_side(rec), QKEY, "c")
        self.assertFalse(r.equal)
        r = compare(self.ours(lambda a, b: [self.leak(9, 0, "i1", "garbage")]), self.c_side(), QKEY, "c")
        self.assertFalse(r.equal)


class FpModes(unittest.TestCase):
    """CR §2 NaN row (ruling 2026-10-27, bead cq-8dy): against "c" any NaN equals any NaN; against
    "ref" fp values are compared bit for bit. A NaN never equals a non-NaN in either mode."""

    def eq(self, ours, other, oracle):
        return compare(ours, other, QKEY, oracle)

    def modes(self, ours, other, c_equal, ref_equal):
        for oracle, want in (("c", c_equal), ("ref", ref_equal)):
            c = self.eq(ours, other, oracle)
            self.assertEqual(c.equal, want, (oracle, c.reasons))

    def out_sides(self, w, v_ours, v_other):
        o = side("o", lambda a, b, s: dict(rots=[], kept=[], outputs={"ret": {"w": w, "v": hex(v_ours)}}))
        r = side("x", lambda a, b, s: dict(rots=[], kept=[], outputs={"ret": {"w": w, "v": hex(v_other)}}))
        return o, r

    # -- named outputs
    def test_output_nan_payload_and_sign(self):
        for w, x, y in (("f64", 0x7FF8000000000000, 0xFFF8000000000000),
                        ("f64", 0x7FF8000000000000, 0x7FF0000000000001),   # quiet vs signalling payload
                        ("f32", 0x7FC00000, 0xFFC00000),
                        ("f32", 0x7FC00000, 0x7F800123),
                        ("f16", 0x7E00, 0xFE00),
                        ("bf16", 0x7FC0, 0xFFC1),
                        ("f80", 0x7FFFC000000000000000, 0xFFFFC000000000000001),
                        ("f80", 0x7FFFC000000000000000, 0x7FFF4000000000000000)):  # pseudo-NaN is a NaN
            with self.subTest(w=w, x=hex(x), y=hex(y)):
                self.modes(*self.out_sides(w, x, y), c_equal=True, ref_equal=False)

    def test_output_nan_vs_non_nan(self):
        for w, x, y in (("f64", 0x7FF8000000000000, 0x7FF0000000000000),   # NaN vs +Inf
                        ("f64", 0xFFF8000000000000, 0x0000000000000000),
                        ("f32", 0x7FC00000, 0x3F800000),
                        ("f16", 0x7E00, 0x7C00),
                        ("bf16", 0x7FC0, 0x7F80),
                        ("f80", 0x7FFFC000000000000000, 0x7FFF0000000000000000)):  # pseudo-Inf is no NaN
            with self.subTest(w=w, x=hex(x), y=hex(y)):
                self.modes(*self.out_sides(w, x, y), c_equal=False, ref_equal=False)
                self.modes(*self.out_sides(w, y, x), c_equal=False, ref_equal=False)

    def test_output_same_nan_bits_equal_in_both(self):
        self.modes(*self.out_sides("f32", 0xFFC00000, 0xFFC00000), c_equal=True, ref_equal=True)

    def test_output_signed_zero_is_not_nan_insensitive(self):
        self.modes(*self.out_sides("f64", 0, 1 << 63), c_equal=False, ref_equal=False)

    def test_untyped_output_is_bit_exact(self):
        # a bare hex value carries no fp-ness
        o = side("o", lambda a, b, s: dict(rots=[], kept=[], outputs={"ret": "0x7fc00000"}))
        r = side("x", lambda a, b, s: dict(rots=[], kept=[], outputs={"ret": "0xffc00000"}))
        self.modes(o, r, c_equal=False, ref_equal=False)

    def test_integer_typed_output_is_bit_exact(self):
        self.modes(*self.out_sides("i32", 0x7FC00000, 0xFFC00000), c_equal=False, ref_equal=False)

    # -- measured values (type from the record or from the rail's kept entry)
    def test_measured_nan(self):
        def mk(name, v, w_on_record):
            m = {"h": 3, "v": hex(v)}
            if w_on_record:
                m["w"] = "f32"
            return side(name, lambda a, b, s: dict(rots=[], kept=[keep(3, v, "f32", "measured")],
                                                   measured=[m]))
        for rec in (True, False):
            with self.subTest(w_on_record=rec):
                self.modes(mk("o", 0x7FC00000, rec), mk("x", 0xFFC00001, rec), c_equal=True, ref_equal=False)
                self.modes(mk("o", 0x7FC00000, rec), mk("x", 0x7F800000, rec), c_equal=False, ref_equal=False)

    # -- rotation list: register values and angles
    def csite(self, fn, site, kind, angle, reg=None):
        rec = {"ev": "site", "fn": fn, "site": site, "kind": kind,
               "angle": hex(angle) if isinstance(angle, int) else ang(angle)}
        if reg is not None:
            rec["reg"] = hex(reg)
        return rec

    def test_ry_on_fp_register_nan(self):
        # Ry(1.0) on an f32 rail holding NaN (a = 1) or 1.0f (a = 0)
        def val(a, nan):
            return nan if a else 0x3F800000
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0)], kept=[keep(1, val(a, 0x7FC00000), "f32")]))
        c = side("c", lambda a, b, s: dict(rots=[self.csite("f", 1, "theta", 1.0, val(a, 0xFFC00001))], kept=[]))
        self.assertTrue(self.eq(ours, c, "c").equal, self.eq(ours, c, "c").reasons)
        c_inf = side("c", lambda a, b, s: dict(rots=[self.csite("f", 1, "theta", 1.0, val(a, 0x7F800000))],
                                               kept=[]))
        self.assertFalse(self.eq(ours, c_inf, "c").equal)
        ref = side("r", lambda a, b, s: dict(rots=[ry(1, 1.0)], kept=[keep(1, val(a, 0xFFC00001), "f32")]))
        self.assertFalse(self.eq(ours, ref, "ref").equal)
        same = side("r", lambda a, b, s: dict(rots=[ry(9, 1.0)], kept=[keep(9, val(a, 0x7FC00000), "f32")]))
        self.assertTrue(self.eq(ours, same, "ref").equal, self.eq(ours, same, "ref").reasons)

    def test_phase_nan_angle(self):
        # CR §2 (at 744da1b): ry/rz/phase with a non-finite angle is the identity, so a NaN-angle
        # phase is no gate in both modes, whatever the payload; a finite C phase is still a difference
        nan_a, nan_b = 0x7FF8000000000000, 0xFFF8000000000123
        ours = side("o", lambda a, b, s: dict(rots=[{"ev": "phase", "f": 7, "fv": a & b, "theta": hex(nan_a)}],
                                              kept=[]))
        c = side("c", lambda a, b, s: dict(rots=[self.csite("f", 3, "phi", nan_b)] if a & b else [], kept=[]))
        self.assertTrue(self.eq(ours, c, "c").equal, self.eq(ours, c, "c").reasons)
        c_num = side("c", lambda a, b, s: dict(rots=[self.csite("f", 3, "phi", 0.5)] if a & b else [], kept=[]))
        self.assertFalse(self.eq(ours, c_num, "c").equal)
        ref = side("r", lambda a, b, s: dict(rots=[{"ev": "phase", "f": 7, "fv": a & b, "theta": hex(nan_b)}],
                                             kept=[]))
        self.assertTrue(self.eq(ours, ref, "ref").equal)

    def test_ry_nan_angle_is_no_gate_in_both_modes(self):
        # CR §1.3: non-finite θ = identity, before any fp equality applies
        nan = 0xFFF8000000000000
        ours = side("o", lambda a, b, s: dict(rots=[{"ev": "ry", "h": 1, "theta": hex(nan), "ctl": [], "ctlv": []}],
                                              kept=[keep(1, a)]))
        ref = side("r", lambda a, b, s: dict(rots=[], kept=[keep(1, a)]))
        self.assertTrue(self.eq(ours, ref, "ref").equal, self.eq(ours, ref, "ref").reasons)
        c = side("c", lambda a, b, s: dict(rots=[self.csite("f", 1, "theta", 0x7FF8000000000001, a)], kept=[]))
        self.assertTrue(self.eq(ours, c, "c").equal, self.eq(ours, c, "c").reasons)


class RegisterVersions(unittest.TestCase):
    """cq-k19b: one register version per Ry (cq-lvkq) makes a rail rotated twice two _dep columns
    with the same values; they never formed a full grid, so every support fell back to every varying
    register and commuting gates were ordered."""

    def test_equal_columns_are_one(self):
        from cqcheck.compare import _dep
        a = (0, 1, 0, 1)
        b = (0, 0, 1, 1)
        regs = {(1, 0): a, (1, 1): a, (2, 0): b}
        self.assertEqual(_dep(b, regs), frozenset({(2, 0)}))
        self.assertEqual(_dep(a, regs), frozenset({(1, 0), (1, 1)}))
        self.assertEqual(_dep(tuple(x & y for x, y in zip(a, b)), regs), frozenset(regs))
        # not determined by the registers: every varying one, as before
        self.assertEqual(_dep((0, 1, 1, 0, 1), {(1, 0): (0, 1, 1, 0, 0), (2, 0): (0, 0, 0, 0, 0)}),
                         frozenset({(1, 0)}))

    def test_phase_commutes_with_a_twice_rotated_rail(self):
        def rots(order):
            return side("o", lambda a, b, s: dict(rots=order(b), kept=[keep(1, a, "i8"), keep(2, b, "i8"),
                                                                         keep(7, b)]))
        ref = rots(lambda b: [ry(2, 0.7), ry(1, 1.0), ry(1, 2.0), ph(7, b, 0.5)])
        ours = rots(lambda b: [ry(2, 0.7), ph(7, b, 0.5), ry(1, 1.0), ry(1, 2.0)])
        r = compare(ours, ref, QKEY, "ref")
        self.assertTrue(r.equal, r.reasons)
        # the phase on rail 1's value still does not commute with its Ry
        ref2 = side("o", lambda a, b, s: dict(rots=[ry(2, 0.7), ry(1, 1.0), ry(1, 2.0), ph(7, a, 0.5)],
                                              kept=[keep(1, a, "i8"), keep(2, b, "i8"), keep(7, a)]))
        ours2 = side("o", lambda a, b, s: dict(rots=[ry(2, 0.7), ph(7, a, 0.5), ry(1, 1.0), ry(1, 2.0)],
                                               kept=[keep(1, a, "i8"), keep(2, b, "i8"), keep(7, a)]))
        self.assertFalse(compare(ours2, ref2, QKEY, "ref").equal)


class COracleT1(unittest.TestCase):
    """oracle "c" reads cq-arch T1's side 'c' RunResult (bead cq-b0c): invert markers under CR rule
    17, outputs["ret"] only, measured records with h null, kept and clean None."""

    @staticmethod
    def site(fn, site, kind, angle=None, reg=None):
        return {"ev": "site", "fn": fn, "site": site, "kind": kind,
                "angle": None if angle is None else ang(angle), "reg": None if reg is None else hex(reg)}

    def beg(self, site=10):
        return self.site("f", site, "invert_begin")

    def end(self, site=11):
        return self.site("f", site, "invert_end")

    @staticmethod
    def c_run(s, rots, outputs=None, measured=(), violations=()):
        """A side 'c' RunResult exactly as T1 shapes it."""
        return RunResult(side="c", sample={"call": 0, "args": [s & 1, s >> 1]},
                         outputs=outputs if outputs is not None else {"ret": [], "end": "ret"},
                         measured=list(measured), rotations=list(rots), kept=None, clean=None,
                         violations=list(violations))

    def c_side(self, build):
        return [self.c_run(s, **build(s & 1, s >> 1, s)) for s in range(4)]

    def check(self, ours, c, equal, needle=None):
        r = compare(ours, c, QKEY, "c")
        self.assertEqual(r.equal, equal, r.reasons)
        if needle:
            self.assertTrue(any(needle in x for x in r.reasons), r.reasons)

    # -- (i) invert markers, CR rule 17
    def region_c(self):
        """Ry(1.0) on a, then inverted: Ry(2.0) on a, Ry(3.0) on a, P(0.5) on a&b."""
        return self.c_side(lambda a, b, s: dict(rots=[
            self.site("f", 0, "theta", 1.0, a), self.beg(),
            self.site("f", 1, "theta", 2.0, a), self.site("f", 2, "theta", 3.0, a)]
            + ([self.site("f", 3, "phi", 0.5)] if a & b else []) + [self.end()]))

    def lowered(self, rots):
        return side("o", lambda a, b, s: dict(rots=rots(a, b), kept=[keep(1, a)]))

    def test_invert_region_adjoint_equal(self):
        ours = self.lowered(lambda a, b: [ry(1, 1.0), ph(7, a & b, -0.5), ry(1, -3.0), ry(1, -2.0)])
        self.check(ours, self.region_c(), True)

    def test_invert_region_forward_angles_rejected(self):
        # what ignoring the markers would accept: the region emitted forward
        ours = self.lowered(lambda a, b: [ry(1, 1.0), ry(1, 2.0), ry(1, 3.0), ph(7, a & b, 0.5)])
        self.check(ours, self.region_c(), False, "no lowered gate")

    def test_invert_region_negated_not_reversed_rejected(self):
        ours = self.lowered(lambda a, b: [ry(1, 1.0), ry(1, -2.0), ry(1, -3.0), ph(7, a & b, -0.5)])
        self.check(ours, self.region_c(), False, "do not commute")

    def test_invert_region_reversed_not_negated_rejected(self):
        ours = self.lowered(lambda a, b: [ry(1, 1.0), ph(7, a & b, 0.5), ry(1, 3.0), ry(1, 2.0)])
        self.check(ours, self.region_c(), False)

    def test_gate_outside_region_not_negated(self):
        ours = self.lowered(lambda a, b: [ry(1, -1.0), ph(7, a & b, -0.5), ry(1, -3.0), ry(1, -2.0)])
        self.check(ours, self.region_c(), False, "C site f:0")

    def test_nested_regions_invert_twice(self):
        # begin [ Ry 2 ; begin [ Ry 3 ; Ry 4 ] end ] end -> emitted: Ry 3, Ry 4 (forward), then Ry -2
        c = self.c_side(lambda a, b, s: dict(rots=[
            self.beg(), self.site("f", 1, "theta", 2.0, a), self.beg(12),
            self.site("f", 2, "theta", 3.0, a), self.site("f", 3, "theta", 4.0, a), self.end(13), self.end()]))
        self.check(self.lowered(lambda a, b: [ry(1, 3.0), ry(1, 4.0), ry(1, -2.0)]), c, True)
        self.check(self.lowered(lambda a, b: [ry(1, -4.0), ry(1, -3.0), ry(1, -2.0)]), c, False)
        self.check(self.lowered(lambda a, b: [ry(1, -2.0), ry(1, 3.0), ry(1, 4.0)]), c, False)

    def test_repeated_site_inside_and_outside_region(self):
        # 61: the same call site reached forward, then inside the region (occurrence 1, negated)
        c = self.c_side(lambda a, b, s: dict(rots=[
            self.site("p", 0, "theta", 1.0, a), self.beg(), self.site("p", 0, "theta", 1.0, a), self.end()]))
        self.check(self.lowered(lambda a, b: [ry(1, 1.0), ry(1, -1.0)]), c, True)
        self.check(self.lowered(lambda a, b: [ry(1, 1.0), ry(1, 1.0)]), c, False)

    def test_unbalanced_markers_are_a_difference(self):
        ours = self.lowered(lambda a, b: [ry(1, -2.0)])
        for rots in ([self.beg(), self.site("f", 1, "theta", 2.0, 0)],
                     [self.site("f", 1, "theta", 2.0, 0), self.end()]):
            c = self.c_side(lambda a, b, s, rots=rots: dict(
                rots=[dict(r, reg=hex(a)) if r["kind"] == "theta" else r for r in rots]))
            self.check(ours, c, False, "matching")

    # -- (ii) outputs["ret"] and the host output only (T1 as amended by cq-e4jk)
    @staticmethod
    def ret(v):
        return [{"call": 0, "fn": "f", "v": {"w": "i32", "v": hex(v)}}]

    def test_ret_only_compared(self):
        ours = side("o", lambda a, b, s: dict(rots=[], kept=[],
                                              outputs={"ret": self.ret(a + b), "stdout": "hi\n", "exit": 0}))
        c = self.c_side(lambda a, b, s: dict(rots=[], outputs={"ret": self.ret(a + b), "end": "ret",
                                                                 "stdout": "hi\n"}))
        self.check(ours, c, True)
        c_out = self.c_side(lambda a, b, s: dict(rots=[], outputs={"ret": self.ret(a + b), "end": "ret"}))
        self.check(ours, c_out, False, "host stdout differs")
        c_bad = self.c_side(lambda a, b, s: dict(rots=[], outputs={"ret": self.ret(a | b), "end": "ret"}))
        self.check(ours, c_bad, False, "returns")

    def test_ret_still_compared_against_ref(self):
        o = side("o", lambda a, b, s: dict(rots=[], kept=[], outputs={"ret": self.ret(a), "stdout": "", "exit": 0}))
        r = side("r", lambda a, b, s: dict(rots=[], kept=[], outputs={"ret": self.ret(a), "stdout": "", "exit": 1}))
        self.assertFalse(compare(o, r, QKEY, "ref").equal)

    # -- (iii) measured records with h null, kept/clean None
    def test_measured_h_null_and_kept_clean_none(self):
        ours = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0)], kept=[keep(1, a, "i1", "measured")],
                                              measured=[{"h": 1, "v": hex(a)}]))
        c = self.c_side(lambda a, b, s: dict(rots=[self.site("f", 0, "theta", 1.0, a)],
                                             measured=[{"h": None, "w": "i1", "v": hex(a)}]))
        self.check(ours, c, True)
        c_bad = self.c_side(lambda a, b, s: dict(rots=[self.site("f", 0, "theta", 1.0, a)],
                                                 measured=[{"h": None, "w": "i1", "v": hex(b)}]))
        self.check(ours, c_bad, False, "measurement 0")
        c_w = self.c_side(lambda a, b, s: dict(rots=[self.site("f", 0, "theta", 1.0, a)],
                                               measured=[{"h": None, "w": "i8", "v": hex(a)}]))
        ours_w = side("o", lambda a, b, s: dict(rots=[ry(1, 1.0)], kept=[keep(1, a, "i1", "measured")],
                                                measured=[{"h": 1, "w": "i1", "v": hex(a)}]))
        self.check(ours_w, c_w, False, "of i1 != i8")


class AKRule(unittest.TestCase):
    """CR §6 a_K rule (ruling 2026-10-27, cq-1di; bead cq-9rt), against "c". A K-loop f:%7 with
    K = 4: before it Ry(1.0) on register x (h=1, x = s); each trip j a phase P(0.5) on trip j's
    predicate (C site f:1); after it Ry(2.0) on x (C site f:2). C trip counts T[s]; a sample with
    T[s] > 4 is capped, its C program stopped after trip 4 (cut = 1 + 4 rotations). Ours runs 4
    trips and keeps a_K on h=9."""

    K = 4
    LOOP = "f:%7"

    @staticmethod
    def site(fn, site, kind, angle, reg=None):
        return {"ev": "site", "fn": fn, "site": site, "kind": kind, "angle": ang(angle),
                "reg": None if reg is None else hex(reg)}

    @staticmethod
    def ret(v):
        return [{"call": 0, "fn": "f", "v": {"w": "i32", "v": hex(v)}}]

    def c_side(self, T, past_cut=False, measure=False):
        out = []
        for s in range(4):
            capped = T[s] > self.K
            trips = min(T[s], self.K) if capped and not past_cut else T[s]
            rots = [self.site("f", 0, "theta", 1.0, s)] + [self.site("f", 1, "phi", 0.5)] * trips
            meas = []
            if not capped or past_cut:
                rots.append(self.site("f", 2, "theta", 2.0, s))
                if measure:
                    meas = [{"h": None, "w": "i8", "v": hex(s)}]
            rec = {"loop": self.LOOP, "act": 0, "n": min(T[s], self.K), "capped": capped}
            if capped:
                rec.update(cut=1 + self.K, mcut=0)
            outputs = {"loops": [rec], "end": "cap:" + self.LOOP if capped else "ret"}
            outputs["ret"] = self.ret(min(T[s], self.K)) if not capped or past_cut else []
            out.append(RunResult(side="c", sample={"call": 0, "args": [s & 1, s >> 1]}, outputs=outputs,
                                 measured=meas, rotations=rots, kept=None, clean=None, violations=[]))
        return out

    def ours(self, T, ak=None, fire=None, extra=None, ret=None, measure=False, with_ak=True):
        """ak[s]: a_K's value (default T[s] > K); fire(j, s): trip j's phase fires (default j <= T[s]);
        with_ak False: no a_K rail is kept (a loop no sample caps, cq-tt2j)."""
        out = []
        for s in range(4):
            a_k = (T[s] > self.K) if ak is None else ak[s]
            rots = [ry(1, 1.0)] + (extra(s) if extra else [])
            for j in range(1, self.K + 1):
                on = (j <= T[s]) if fire is None else fire(j, s)
                rots.append(ph(20 + j, on, 0.5))
            rots.append(ry(1, 2.0))
            kept = [keep(1, s, "i8"), keep(9, int(a_k), "i1", "garbage")][:2 if with_ak else 1]
            meas = []
            if measure:
                kept[0] = keep(1, s, "i8", "measured")
                meas = [{"h": 1, "w": "i8", "v": hex(s)}]
            r = min(T[s], self.K) if ret is None else ret(s)
            out.append(run("o", s, rots, kept, outputs={"ret": self.ret(r), "stdout": "", "exit": 0},
                           measured=meas))
        return out

    def check(self, ours, c, equal, needle=None):
        r = compare(ours, c, QKEY, "c")
        self.assertEqual(r.equal, equal, r.reasons)
        if needle:
            self.assertTrue(any(needle in x for x in r.reasons), r.reasons)

    def test_cut_inside_invert_region(self):
        # cq-088c: the K-loop inside a cq_invert region (begin before f:1's trips, end after them);
        # a capped sample's cut lies inside the region, which then closes at the cut. Before:
        # CompareError "the cut ... lies inside a cq_invert region"
        beg = {"ev": "site", "fn": "f", "site": 10, "kind": "invert_begin", "angle": None, "reg": None}
        end = {"ev": "site", "fn": "f", "site": 11, "kind": "invert_end", "angle": None, "reg": None}
        T = self.CAP
        c = []
        for r in self.c_side(T):
            rots = list(r.rotations)
            capped = T[r.sample["args"][0] | r.sample["args"][1] << 1] > self.K
            rots.insert(1, beg)
            if not capped:
                rots.insert(len(rots) - 1, end)
            outputs = dict(r.outputs, loops=[dict(l, cut=l["cut"] + 1) if l["capped"] else l
                                             for l in r.outputs["loops"]])
            c.append(dataclasses.replace(r, rotations=rots, outputs=outputs))

        def ours(angle):
            out = []
            for s in range(4):
                rots = [ry(1, 1.0)] + [ph(20 + j, j <= T[s], angle) for j in range(self.K, 0, -1)] + [ry(1, 2.0)]
                out.append(run("o", s, rots, [keep(1, s, "i8"), keep(9, int(T[s] > self.K), "i1", "garbage")],
                               outputs={"ret": self.ret(min(T[s], self.K)), "stdout": "", "exit": 0}))
            return out
        self.check(ours(-0.5), c, True)
        self.check(ours(0.5), c, False)

    CAP = (0, 2, 9, 7)        # samples 2 and 3 capped
    LEQ = (0, 2, 3, 4)        # none capped; sample 3 exits after exactly K trips

    def test_capped_ak_one_passes(self):
        self.check(self.ours(self.CAP), self.c_side(self.CAP), True)

    def test_capped_ak_zero_fails(self):
        self.check(self.ours(self.CAP, ak=(0, 0, 0, 0)), self.c_side(self.CAP), False, "a_K of loop f:%7")
        self.check(self.ours(self.CAP, ak=(0, 0, 1, 0)), self.c_side(self.CAP), False, "a_K of loop f:%7")

    def test_ak_one_on_sample_with_at_most_K_trips_fails(self):
        self.check(self.ours(self.CAP, ak=(0, 1, 1, 1)), self.c_side(self.CAP), False, "a_K of loop f:%7")

    def test_ak_not_a_measured_rail(self):
        ours = self.ours(self.CAP)
        for rr in ours:
            rr.kept[1]["role"] = "measured"
        self.check(ours, self.c_side(self.CAP), False, "a_K of loop f:%7")

    def test_uncapped_compared_fully(self):
        self.check(self.ours(self.LEQ, with_ak=False), self.c_side(self.LEQ), True)
        # an a_K kept for a loop no sample caps: rule 14 keeps none when B <= K (cq-tt2j, the t3 finding)
        self.check(self.ours(self.LEQ), self.c_side(self.LEQ), False, "a leak; cq-tt2j")
        # every clause still decides: the return, a trip's rotation, the post-loop rotation
        self.check(self.ours(self.LEQ, ret=lambda s: 7, with_ak=False), self.c_side(self.LEQ), False, "returns")
        self.check(self.ours(self.LEQ, fire=lambda j, s: j <= min(self.LEQ[s], 2), with_ak=False),
                   self.c_side(self.LEQ), False, "f:1")
        c = self.c_side(self.LEQ)
        c[1] = dataclasses.replace(c[1], rotations=c[1].rotations[:-1])
        self.check(self.ours(self.LEQ, with_ak=False), c, False)

    def test_capped_ret_not_compared(self):
        # the C program stopped at the cap: its "ret" is absent (or anything); ours stands
        self.check(self.ours(self.CAP, ret=lambda s: 99 if s >= 2 else min(self.CAP[s], 4)),
                   self.c_side(self.CAP), True)
        self.check(self.ours(self.CAP, ret=lambda s: 99), self.c_side(self.CAP), False, "returns")

    def test_rotation_list_truncated_at_trip_K(self):
        # the C side recorded trips 5.. and the code after the loop past the cut: compared through trip K
        self.check(self.ours(self.CAP), self.c_side(self.CAP, past_cut=True), True)

    def test_trips_through_K_still_compared_on_capped_sample(self):
        # sample 2 is capped, yet its trip 3 is before the cut: ours must fire it
        fire = lambda j, s: (j <= self.CAP[s]) and not (s == 2 and j == 3)  # noqa: E731
        self.check(self.ours(self.CAP, fire=fire), self.c_side(self.CAP), False, "f:1")

    def test_extra_gate_before_the_cut_on_capped_sample(self):
        # a gate firing only on capped sample 2, before a gate of trip 1 on the same register
        extra = lambda s: [ry(1, 3.0, ctl=[30], ctlv=[int(s == 2)])]  # noqa: E731
        self.check(self.ours(self.CAP, extra=extra), self.c_side(self.CAP), False, "before the cut")

    def test_measured_prefix_on_capped_sample(self):
        self.check(self.ours(self.CAP, measure=True), self.c_side(self.CAP, measure=True), True)
        c = self.c_side(self.CAP, measure=True)
        c[0] = dataclasses.replace(c[0], measured=[{"h": None, "w": "i8", "v": "0x5"}])
        self.check(self.ours(self.CAP, measure=True), c, False, "measurement 0")

    def test_malformed_loop_record_is_an_internal_error(self):
        from cqcheck.compare import CompareError
        c = self.c_side(self.CAP)
        bad = dict(c[2].outputs, loops=[{"loop": self.LOOP, "act": 0, "n": 4, "capped": True}])
        c[2] = dataclasses.replace(c[2], outputs=bad)
        with self.assertRaises(CompareError):
            compare(self.ours(self.CAP), c, QKEY, "c")


class AbortRule(unittest.TestCase):
    """CR rule 16 / §1.3 abort rule against "c" (bead cq-ouml), shaped like 45: register x (h=1, i8,
    x = s); Ry(1.0) on x (C site f:0); on x == 3 abort(), else Ry(2.0) on x (C site f:1) and return
    x. Ours keeps abort_i1's flag (h=9, role abort, x == 3) and runs on: Ry(2.0) fires on every
    sample, x is measured and returned on every sample."""

    END = 3

    @staticmethod
    def site(site, angle, reg):
        return {"ev": "site", "fn": "f", "site": site, "kind": "theta", "angle": ang(angle), "reg": hex(reg)}

    def c(self, end="noreturn:abort"):
        out = []
        for s in range(4):
            rots = [self.site(0, 1.0, s)]
            if s == self.END:
                outputs = {"ret": [], "end": end, "loops": []}
                meas = []
            else:
                rots.append(self.site(1, 2.0, s))
                outputs = {"ret": [{"call": 0, "fn": "f", "v": {"w": "i8", "v": hex(s)}}], "end": "ret", "loops": []}
                meas = [{"h": None, "w": "i8", "v": hex(s)}]
            out.append(RunResult(side="c", sample={"call": 0, "args": [s & 1, s >> 1]}, outputs=outputs,
                                 measured=meas, rotations=rots, kept=None, clean=None, violations=[]))
        return out

    def ours(self, flag=lambda s: int(s == 3), role="abort", first=lambda s: 1, ret=lambda s: s, drop=False):
        out = []
        for s in range(4):
            rots = [ry(1, 1.0, [8], [first(s)]), ry(1, 2.0)]
            kept = [keep(1, s, "i8", "measured")]
            if not drop:
                kept.append(keep(9, flag(s), "i1", role))
            out.append(run("o", s, rots, kept, measured=[{"h": 1, "w": "i8", "v": hex(s)}],
                           outputs={"ret": [{"call": 0, "fn": "f", "v": {"w": "i8", "v": hex(ret(s))}}]}))
        return out

    def check(self, ours, c, equal, needle=None):
        r = compare(ours, c, QKEY, "c")
        self.assertEqual(r.equal, equal, r.reasons)
        if needle:
            self.assertTrue(any(needle in x for x in r.reasons), r.reasons)

    def test_abort_flag_one_passes(self):
        # fails before cq-ouml: "returns [...] != []" and "1 measurements != 0" on sample 3
        self.check(self.ours(), self.c(), True)
        self.check(self.ours(), self.c("raise:6"), True)
        self.check(self.ours(), self.c("noreturn:llvm.trap"), True)

    def test_dropped_abort_flag_rejected(self):
        self.check(self.ours(drop=True), self.c(), False, "no kept abort flag")

    def test_zero_abort_flag_rejected(self):
        self.check(self.ours(flag=lambda s: 0), self.c(), False, "no kept abort flag")

    def test_abort_flag_needs_abort_role(self):
        for role in ("frozen", "measured", "tape"):
            self.check(self.ours(role=role), self.c(), False, "no kept abort flag")
        # a garbage i1 flag live on a returning sample is a leak first (cq-tt2j)
        self.check(self.ours(role="garbage"), self.c(), False, "a leak; cq-tt2j")

    def test_abort_flag_one_on_returning_sample_rejected(self):
        self.check(self.ours(flag=lambda s: int(s >= 2)), self.c(), False, "returns and our abort flag")

    def test_before_the_end_still_compared(self):
        # the gate of site f:0 must fire on the ended sample too: it precedes the abort
        self.check(self.ours(first=lambda s: int(s != 3)), self.c(), False, "f:0")

    def test_ret_compared_on_returning_samples(self):
        self.check(self.ours(ret=lambda s: 7 if s == 3 else s), self.c(), True)
        self.check(self.ours(ret=lambda s: 7), self.c(), False, "returns")

    def test_extra_c_measurement_before_the_end_still_compared(self):
        c = self.c()
        c[3] = dataclasses.replace(c[3], measured=[{"h": None, "w": "i8", "v": "0x5"}])
        self.check(self.ours(), c, False, "measurement 0")

    def test_ordinary_end_is_not_an_abort(self):
        self.check(self.ours(), self.c("ret"), False, "returns")

    # -- cq-088c: a sample that ends inside a cq_invert region
    def region_c(self):
        """f:0 Ry(1.0); invert_begin; f:1 Ry(2.0); on x == 3 abort() (the region never closes), else
        f:2 Ry(3.0); invert_end."""
        out = []
        for s in range(4):
            rots = [self.site(0, 1.0, s), {"ev": "site", "fn": "f", "site": 10, "kind": "invert_begin",
                                           "angle": None, "reg": None},
                    self.site(1, 2.0, s)]
            if s != self.END:
                rots += [self.site(2, 3.0, s), {"ev": "site", "fn": "f", "site": 11, "kind": "invert_end",
                                                "angle": None, "reg": None}]
            out.append(RunResult(side="c", sample={"call": 0, "args": [s & 1, s >> 1]},
                                 outputs={"end": "noreturn:abort" if s == self.END else "ret", "loops": []},
                                 measured=[], rotations=rots, kept=None, clean=None, violations=[]))
        return out

    def region_ours(self, rots):
        return [run("o", s, rots(s), [keep(1, s, "i8"), keep(9, int(s == self.END), "i1", "abort")])
                for s in range(4)]

    def test_end_inside_invert_region(self):
        # fails before cq-088c: "1 C invert_begin(s) without a matching invert_end" on sample 3. Rule 17
        # emits the region reversed: the reached f:1 is the region's last gate, f:2 (unknown past the
        # end) comes before it
        c = self.region_c()
        self.check(self.region_ours(lambda s: [ry(1, 1.0), ry(1, -3.0), ry(1, -2.0)]), c, True)
        # the region forward, or not negated, is still a difference
        self.check(self.region_ours(lambda s: [ry(1, 1.0), ry(1, 2.0), ry(1, 3.0)]), c, False)
        self.check(self.region_ours(lambda s: [ry(1, 1.0), ry(1, 3.0), ry(1, 2.0)]), c, False)
        # the reached f:1 must fire on the ended sample too
        self.check(self.region_ours(lambda s: [ry(1, 1.0), ry(1, -3.0), ry(1, -2.0, [8], [int(s != 3)])]),
                   c, False, "f:1")

    def test_unclosed_region_on_a_returning_sample_still_a_difference(self):
        c = self.region_c()
        c[0] = dataclasses.replace(c[0], rotations=c[0].rotations[:3])
        self.check(self.region_ours(lambda s: [ry(1, 1.0), ry(1, -3.0), ry(1, -2.0)]), c, False,
                   "without a matching invert_end")


class Rule2Measure(unittest.TestCase):
    """CR rule 2 against "c" (bead cq-tnrb), shaped like 155: registers x (h=1, x = a) and y (h=2,
    y = b), i8. C: if (x > 0) measure y; then measure x. Ours measures y unconditionally, then x."""

    def c(self, build=None):
        def meas(a, b):
            return ([{"h": None, "w": "i8", "v": hex(b)}] if a else []) + [{"h": None, "w": "i8", "v": hex(a)}]
        build = build or meas
        return [RunResult(side="c", sample={"call": 0, "args": [s & 1, s >> 1]},
                          outputs={"ret": [], "end": "ret", "loops": []}, measured=build(s & 1, s >> 1),
                          rotations=[], kept=None, clean=None, violations=[]) for s in range(4)]

    def ours(self, meas=None):
        """meas(a, b) -> [(h, value)] in order; default [(2, b), (1, a)]."""
        meas = meas or (lambda a, b: [(2, b), (1, a)])
        out = []
        for s in range(4):
            a, b = s & 1, s >> 1
            ms = meas(a, b)
            kept = [keep(h, v, "i8", "measured") for h, v in ms]
            out.append(run("o", s, [], kept, measured=[{"h": h, "w": "i8", "v": hex(v)} for h, v in ms]))
        return out

    def check(self, ours, c, equal, needle=None):
        r = compare(ours, c, QKEY, "c")
        self.assertEqual(r.equal, equal, r.reasons)
        if needle:
            self.assertTrue(any(needle in x for x in r.reasons), r.reasons)

    def test_hoisted_arm_measurement_accepted(self):
        # fails before cq-tnrb: "2 measurements != 1" on the samples with a = 0
        self.check(self.ours(), self.c(), True)

    def test_unconditional_measurement_outside_any_arm_rejected(self):
        # a register the C program measures on no path: z (h=3) reads 7
        self.check(self.ours(lambda a, b: [(3, 7), (2, b), (1, a)]), self.c(), False, "match no C measurement here")
        # y measured although the C program never measures it
        self.check(self.ours(), self.c(lambda a, b: [{"h": None, "w": "i8", "v": hex(a)}]), False,
                   "match no C measurement here")

    def test_c_measurement_still_needed(self):
        self.check(self.ours(lambda a, b: [(1, a)]), self.c(), False, "measurements")

    def test_value_still_compared(self):
        self.check(self.ours(lambda a, b: [(2, 1 - b), (1, a)]), self.c(), False)
        self.check(self.ours(lambda a, b: [(2, b), (1, 1 - a)]), self.c(), False)

    def test_order_still_compared(self):
        self.check(self.ours(lambda a, b: [(1, a + 4), (2, b)]),
                   self.c(lambda a, b: [{"h": None, "w": "i8", "v": hex(v)} for v in ([b] if a else []) + [a + 4]]),
                   False)

    def test_type_still_compared(self):
        c = self.c(lambda a, b: ([{"h": None, "w": "i16", "v": hex(b)}] if a else [])
                   + [{"h": None, "w": "i8", "v": hex(a)}])
        self.check(self.ours(), c, False)


class UnPrep(unittest.TestCase):
    """CR rule 10 un-prep against "c" (bead cq-9gi3), shaped like 133's prep_twice: a register r
    (h=3, i32, seed R0) prepared Ry(T1) under a (C site f:0), then overwritten: undone by Ry(-T1)
    under a & b (the conjunction flag, no C reach of its own), reset, and prepared Ry(T2) under b
    (C site f:1)."""

    T1, T2, R0 = -3.7, 0.6, 8

    @staticmethod
    def site(fn, site, angle, reg):
        return {"ev": "site", "fn": fn, "site": site, "kind": "theta", "angle": ang(angle), "reg": hex(reg)}

    @staticmethod
    def ryv(h, theta, flag, on, v):
        return dict(ry(h, theta, [flag], [on]), w="i32", v=hex(v))

    def c(self, first=True, second=True):
        def build(s):
            a, b = s & 1, s >> 1
            rots = ([self.site("f", 0, self.T1, 0)] if first and a else []) + \
                   ([self.site("f", 1, self.T2, 0)] if second and b else [])
            return RunResult(side="c", sample={"call": 0, "args": [a, b]}, outputs={"ret": [], "end": "ret"},
                             measured=[], rotations=rots, kept=None, clean=None, violations=[])
        return [build(s) for s in range(4)]

    def ours(self, unprep=None, first=True, second=True):
        """unprep(a, b, r) -> list of extra records at the un-prep's position (r: the value there)."""
        if unprep is None:
            unprep = lambda a, b, r: [self.ryv(3, -self.T1, 6, a & b, r)]  # noqa: E731
        R0 = self.R0

        def build(a, b, s):
            r = 0 if a and first else R0
            rots = [self.ryv(3, self.T1, 5, a, r)] if first else []
            rots += unprep(a, b, r)
            if a and b:
                r = R0
            if b:
                r = 0
            if second:
                rots.append(self.ryv(3, self.T2, 7, b, r))
            return dict(rots=rots, kept=[keep(3, r, "i32"), keep(4, 0, "i32")])
        return side("o", build)

    # cq-ia96, cq-yzuc: f:0 and f:1 are one register, f:1 seeding it afresh (r = 0 before it)
    REGS = {"f:0": (("@f", 0), frozenset()), "f:1": (("@f", 0), frozenset())}

    def check(self, ours, c, equal, needle=None, registers=REGS):
        reasons = _compare(ours, c, "c", classical_key=QKEY, registers=registers)
        self.assertEqual(not reasons, equal, reasons)
        if needle:
            self.assertTrue(any(needle in x for x in reasons), reasons)

    def test_unprep_accepted(self):
        # fails before cq-9gi3: "corresponds to no C site"
        self.check(self.ours(), self.c(), True)

    def test_unprep_without_registers_rejected(self):
        # cq-yzuc: without the C program's register webs no overwrite is known
        self.check(self.ours(), self.c(), False, "no C site", registers=None)

    def test_unprep_before_in_place_rotation_rejected(self):
        # cq-yzuc: f:1 rotates f:0's value in place (CQ.h): a second Ry on r, no overwrite
        regs = {"f:0": (("@f", 0), frozenset()), "f:1": (("@f", 0), frozenset({"f:0"}))}
        self.check(self.ours(), self.c(), False, "no C site", registers=regs)

    def test_unprep_before_other_register_rejected(self):
        # cq-yzuc: f:1 prepares another register
        regs = {"f:0": (("@f", 0), frozenset()), "f:1": (("@f", 9), frozenset())}
        self.check(self.ours(), self.c(), False, "no C site", registers=regs)

    def test_unprep_wrong_angle_rejected(self):
        for th in (self.T1, -self.T1 + 0.25, -self.T2):
            self.check(self.ours(lambda a, b, r, th=th: [self.ryv(3, th, 6, a & b, r)]), self.c(), False,
                       "no C site")

    def test_unprep_wrong_target_rejected(self):
        self.check(self.ours(lambda a, b, r: [self.ryv(4, -self.T1, 6, a & b, 0)]), self.c(), False)

    def test_unprep_without_earlier_prep_rejected(self):
        self.check(self.ours(first=False), self.c(first=False), False, "no C site")

    def test_unprep_without_later_prep_rejected(self):
        self.check(self.ours(second=False), self.c(second=False), False, "no C site")

    def test_unprep_wrong_predicate_rejected(self):
        for p in (lambda a, b: a, lambda a, b: b, lambda a, b: 1, lambda a, b: a & (1 - b)):
            self.check(self.ours(lambda a, b, r, p=p: [self.ryv(3, -self.T1, 6, p(a, b), r)]), self.c(), False)

    def test_unprep_twice_rejected(self):
        # the earlier prep is undone once: a second adjoint finds the first un-prep as the latest gate
        twice = lambda a, b, r: [self.ryv(3, -self.T1, 6, a & b, r)] * 2  # noqa: E731
        self.check(self.ours(twice), self.c(), False)

    def test_unprep_of_unmatched_gate_rejected(self):
        # the "earlier prep" has no C reach (C lacks f:0): its adjoint is no un-prep
        self.check(self.ours(), self.c(first=False), False)


class HostOutput(unittest.TestCase):
    """Host output (cq-e4jk): outputs["stdout"] and outputs["effects"] are compared against both
    oracles; against "c" the C side's are a prefix of ours on an ended sample; an effect name of
    ours outside HOST_EFFECTS is a CompareError against "c". Shaped like AbortRule's 45: x = s,
    abort on x == 3."""

    RM = {"name": "remove", "args": [{"s": "/tmp/cq_x"}]}

    def ours(self, out=lambda s: f"x={s}\n", fx=lambda s: [], side="o"):
        a = AbortRule().ours()
        return [dataclasses.replace(r, side=side, outputs=dict(r.outputs, stdout=out(s), effects=fx(s), exit=0))
                for s, r in enumerate(a)]

    def c(self, out=lambda s: f"x={s}\n", fx=lambda s: []):
        return [dataclasses.replace(r, outputs=dict(r.outputs, stdout=out(s), effects=fx(s)))
                for s, r in enumerate(AbortRule().c())]

    def check(self, ours, other, against, equal, needle=None):
        r = compare(ours, other, QKEY, against)
        self.assertEqual(r.equal, equal, r.reasons)
        if needle:
            self.assertTrue(any(needle in x for x in r.reasons), r.reasons)

    def test_equal_passes(self):
        self.check(self.ours(), self.ours(side="r"), "ref", True)
        self.check(self.ours(), self.c(), "c", True)

    def test_stdout_differs(self):
        # m5/47: printf of a literal instead of the register
        bad = self.ours(out=lambda s: "x=7\n")
        self.check(bad, self.ours(side="r"), "ref", False, "host stdout differs")
        self.check(bad, self.c(), "c", False, "host stdout differs")

    def test_effect_dropped(self):
        # m4/102: the remove() entry deleted
        want = lambda s: [self.RM] if s & 1 else []
        self.check(self.ours(), self.ours(side="r", fx=want), "ref", False, "host effects differ")
        self.check(self.ours(), self.c(fx=want), "c", False, "host effects differ")
        self.check(self.ours(fx=want), self.c(fx=want), "c", True)

    def test_effect_argument_compared(self):
        other = lambda s: [{"name": "remove", "args": [{"s": "/tmp/cq_y"}]}]
        self.check(self.ours(fx=lambda s: [self.RM]), self.c(fx=other), "c", False, "host effects differ")
        r6 = lambda w: (lambda s: [{"name": "raise", "args": [{"w": w, "v": "0x6"}]}])
        self.check(self.ours(fx=r6("i32")), self.c(fx=r6("i32")), "c", True)

    def test_prefix_on_ended_sample_only(self):
        # sample 3 ends (abort): the circuit may print and act on past the end
        more = lambda s: f"x={s}\n" + ("after\n" if s == 3 else "")
        self.check(self.ours(out=more), self.c(), "c", True)
        self.check(self.ours(out=more), self.ours(side="r"), "ref", False, "host stdout differs")
        less = lambda s: "" if s == 3 else f"x={s}\n"
        self.check(self.ours(out=less), self.c(), "c", False, "host stdout differs")
        early = lambda s: f"x={s}\nmore\n" if s == 1 else f"x={s}\n"
        self.check(self.ours(out=early), self.c(), "c", False, "host stdout differs")

    def test_unknown_effect_against_c_is_an_error(self):
        from cqcheck.compare import CompareError
        fx = lambda s: [{"name": "kill", "args": []}]
        with self.assertRaises(CompareError):
            compare(self.ours(fx=fx), self.c(fx=fx), QKEY, "c")
        self.check(self.ours(fx=fx), self.ours(side="r", fx=fx), "ref", True)


if __name__ == "__main__":
    unittest.main()
