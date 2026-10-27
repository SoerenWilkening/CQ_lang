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
        # a classical-angle phase is not made identity by a NaN angle (CR §1.3 says so only for Ry
        # and angle rails), so the mode applies to its angle
        nan_a, nan_b = 0x7FF8000000000000, 0xFFF8000000000123
        ours = side("o", lambda a, b, s: dict(rots=[{"ev": "phase", "f": 7, "fv": a & b, "theta": hex(nan_a)}],
                                              kept=[]))
        c = side("c", lambda a, b, s: dict(rots=[self.csite("f", 3, "phi", nan_b)] if a & b else [], kept=[]))
        self.assertTrue(self.eq(ours, c, "c").equal, self.eq(ours, c, "c").reasons)
        c_num = side("c", lambda a, b, s: dict(rots=[self.csite("f", 3, "phi", 0.5)] if a & b else [], kept=[]))
        self.assertFalse(self.eq(ours, c_num, "c").equal)
        ref = side("r", lambda a, b, s: dict(rots=[{"ev": "phase", "f": 7, "fv": a & b, "theta": hex(nan_b)}],
                                             kept=[]))
        self.assertFalse(self.eq(ours, ref, "ref").equal)

    def test_ry_nan_angle_is_no_gate_in_both_modes(self):
        # CR §1.3: non-finite θ = identity, before any fp equality applies
        nan = 0xFFF8000000000000
        ours = side("o", lambda a, b, s: dict(rots=[{"ev": "ry", "h": 1, "theta": hex(nan), "ctl": [], "ctlv": []}],
                                              kept=[keep(1, a)]))
        ref = side("r", lambda a, b, s: dict(rots=[], kept=[keep(1, a)]))
        self.assertTrue(self.eq(ours, ref, "ref").equal, self.eq(ours, ref, "ref").reasons)
        c = side("c", lambda a, b, s: dict(rots=[self.csite("f", 1, "theta", 0x7FF8000000000001, a)], kept=[]))
        self.assertTrue(self.eq(ours, c, "c").equal, self.eq(ours, c, "c").reasons)


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
        self.check(ours, self.region_c(), False, "supports overlap")

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

    # -- (ii) outputs["ret"] only
    @staticmethod
    def ret(v):
        return [{"call": 0, "fn": "f", "v": {"w": "i32", "v": hex(v)}}]

    def test_ret_only_compared(self):
        ours = side("o", lambda a, b, s: dict(rots=[], kept=[],
                                              outputs={"ret": self.ret(a + b), "stdout": "hi\n", "exit": 0}))
        c = self.c_side(lambda a, b, s: dict(rots=[], outputs={"ret": self.ret(a + b), "end": "ret"}))
        self.check(ours, c, True)
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


if __name__ == "__main__":
    unittest.main()
