"""Unit tests of checker/cqcheck/compare.py on synthetic RunResults (bead cq-w0-chk-compare).

Two i1 registers a, b (handles of the side's choosing) seeded exhaustively: samples s = 0..3 with
a = s & 1, b = s >> 1. Every case states which §6 clause decides it.
"""
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

    def test_order_against_dependent_gate(self):
        # the C program puts the phase on a&b before the Ry on b; the lowered order reverses them
        c_first = side("c", lambda a, b, s: dict(
            rots=[self.csite("f", 1, "theta", 1.0, a)] + ([self.csite("f", 3, "phi", 0.5)] if a & b else [])
            + [self.csite("f", 2, "theta", 2.0, b)], kept=[]))
        c = compare(side("o", ref_ab()), c_first, QKEY, "c")
        self.assertFalse(c.equal)
        self.assertTrue(any("supports overlap" in r for r in c.reasons), c.reasons)


if __name__ == "__main__":
    unittest.main()
