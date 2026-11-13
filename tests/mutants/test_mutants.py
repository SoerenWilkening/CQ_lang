#!/usr/bin/env python3
"""Permanent tests of module chk-selftest (bead cq-w0-chk-selftest): the self-test mutants.

    python3 tests/mutants/test_mutants.py                 static checks (seconds; ctest runs these)
    python3 tests/mutants/test_mutants.py --run [ID ...]  evaluate the mutants (all, or these ids)
                                                          with their controls; no empty outputs
    python3 -m cqcheck selftest                           (from checker/) the whole self-test

Static checks: every mutant in mutants.json applies to the pinned reference, changes it, parses,
and has a known class; every class has a mutant; the judging rules reject what they must (ERROR is
never a rejection, a FAIL with the wrong reason is not the predicted one). The mutants are written
under a temporary CQ_BUILD_DIR, never into CQ_spec.
"""
import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))
if "--run" not in sys.argv:
    os.environ["CQ_BUILD_DIR"] = tempfile.mkdtemp(prefix="cq-mutants-")

from cqcheck import mutants, report  # noqa: E402
from cqcheck.contracts import Verdict  # noqa: E402


def V(s6, c, reasons, verifier="pass"):
    return Verdict("x", s6, c, verifier, 1, reasons)


class Static(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ms = mutants.load_mutants()
        cls.ex = {e.name: e for e in report.all_examples()}

    def test_every_class_has_a_mutant(self):
        self.assertEqual(set(mutants.CLASSES) - {m.cls for m in self.ms}, set())

    def test_spread(self):
        # a class is witnessed on more than one reference wherever the corpus allows; overall the
        # mutants are cut from several references
        self.assertGreaterEqual(len({m.example for m in self.ms}), 8)

    def test_mutants_apply_change_and_parse(self):
        spec = report.spec_dir().resolve()
        for m in self.ms:
            with self.subTest(m.id):
                ex = self.ex[m.example]
                p = mutants.materialize(m, ex)
                self.assertNotEqual(p.read_text(), ex.reference.read_text())
                self.assertFalse(str(p.resolve()).startswith(str(spec)), "mutant written into CQ_spec")
                self.assertEqual(list(p.parent.glob("*.O1.ll")), [])

    def test_edit_must_apply_exactly_once(self):
        with self.assertRaises(mutants.MutantError):
            mutants.apply_edits("a a", [{"old": "a", "new": "b"}])
        with self.assertRaises(mutants.MutantError):
            mutants.apply_edits("a", [{"old": "c", "new": "b"}])
        with self.assertRaises(mutants.MutantError):
            mutants.apply_edits("a", [{"old": "c", "new": "b", "all": True}])
        self.assertEqual(mutants.apply_edits("a a", [{"old": "a", "new": "b", "all": True}]), "b b")

    def test_empty_output_is_empty(self):
        p = mutants.empty_output(self.ex["01_add_classical_const"])
        self.assertEqual(p.stat().st_size, 0)


class Judge(unittest.TestCase):
    ROT = mutants.CLASSES["added_rotation"]  # rotation list only
    KEPT = mutants.CLASSES["dropped_free"]

    def test_predicted_rejection(self):
        v = V("fail", "fail", ["ref: classical arguments () (4 samples): rotation list differs: x",
                               "c: classical arguments () (4 samples): C site f:0 (theta, occurrence 0, "
                               "reached on 4 samples) has no lowered gate left"])
        self.assertEqual(mutants._judge(v, self.ROT[1], self.ROT[2]), [])

    def test_error_is_not_a_rejection(self):
        v = V("error", "fail", ["s6: RuntimeError: boom"])
        self.assertTrue(mutants._judge(v, self.ROT[1], self.ROT[2]))
        v = V("fail", "error", ["ref: x: rotation list differs: y", "c_oracle: boom"])
        self.assertTrue(mutants._judge(v, self.ROT[1], self.ROT[2]))
        v = V("fail", "error", ["ref: t: 1 rail(s) i1 with values (0) kept on our side that the reference "
                                "does not keep (it cleans them or never makes them)"])
        self.assertTrue(mutants._judge(v, self.KEPT[1], self.KEPT[2]))

    def test_wrong_reason_is_not_the_prediction(self):
        v = V("fail", "fail", ["ref: sample 1: measurement 0 reads 0x1 != 0x2", "c: sample 1: measurement 0 "
                               "reads 0x1 != 0x2"])
        self.assertTrue(mutants._judge(v, self.ROT[1], self.ROT[2]))

    def test_a_pass_is_not_a_rejection(self):
        self.assertTrue(mutants._judge(V("pass", "pass", []), self.ROT[1], self.ROT[2]))
        self.assertTrue(mutants._judge(V("pass", "fail", ["c: x"]), self.KEPT[1], self.KEPT[2]))

    def test_class_invisible_to_c(self):
        r = ["ref: t: 1 rail(s) i1 with values (0) kept on our side that the reference does not keep (x)"]
        self.assertEqual(mutants._judge(V("fail", "pass", r), self.KEPT[1], self.KEPT[2]), [])

    def test_rotation_only_needs_the_rotation_list_with_substitution_off(self):
        # cq-lkth: with substitution the output difference comes first (125-change-control:
        # measurement 1 reads 0x3 != 0x0); the run with substitution off must fail on the rotation list
        full = V("fail", "fail", ["ref: sample 1: measurement 1 reads 0x3 != 0x0",
                                  "c: sample 1: measurement 1 reads 0x3 != 0x0"])
        rot = V("fail", "fail", ["ref: classical arguments () (4 samples): rotation list differs: x",
                                 "c: classical arguments () (4 samples): lowered gate #2 ry(r) corresponds to "
                                 "no C site"])
        # cq-425g: changed_angle too (39-change-angle: a Ry at another angle takes no substitution)
        for cls in ("flipped_predicate", "changed_control", "dropped_rotation", "changed_angle"):
            with self.subTest(cls):
                self.assertIn(cls, mutants.ROTATION_ONLY)
                self.assertEqual(mutants.judge_mutant(cls, full, rot), [])
                self.assertTrue(mutants.judge_mutant(cls, full, None))
                # an output difference with substitution off does not prove the comparator
                self.assertTrue(mutants.judge_mutant(cls, full, full))
                self.assertTrue(mutants.judge_mutant(cls, full, V("pass", "pass", [])))
                self.assertTrue(mutants.judge_mutant(cls, V("pass", "pass", []), rot))
                # caught on the rotation list with substitution (59: q's bits read 0 without it)
                self.assertFalse(mutants.needs_subst_off(cls, rot))
                self.assertEqual(mutants.judge_mutant(cls, rot, None), [])
                self.assertTrue(mutants.needs_subst_off(cls, full))
        # a class outside ROTATION_ONLY ignores the run with substitution off
        self.assertFalse(mutants.needs_subst_off("added_rotation", full))
        self.assertEqual(mutants.judge_mutant("added_rotation", rot, None), [])

    def test_empty_pattern(self):
        r = ("sample {}: violations on our side: [{'what': 'build', 'h': None, 'msg': 'clang failed (1): "
             "Undefined symbols for architecture x86_64:\\n  \"_f\", referenced from:'}]")
        v = V("fail", "fail", ["ref: " + r, "c: " + r])
        self.assertEqual(mutants._judge(v, mutants.EMPTY_PATTERN, mutants.EMPTY_PATTERN), [])
        v = V("fail", "fail", ["ref: sample {}: outputs {} != {}", "c: sample {}: returns [] != [1]"])
        self.assertTrue(mutants._judge(v, mutants.EMPTY_PATTERN, mutants.EMPTY_PATTERN))


class Release(unittest.TestCase):
    """cq-p9pty: the self-test's parent holds no verdict after recording it (213 empty-output verdicts, every
    sample's reasons, exceeded 6 GB), and an outcome as predicted is recorded with its first reasons and their
    count; one not as predicted with all of them."""

    def test_verdicts_released_and_record_capped(self):
        import json
        n = mutants.REASONS_RECORDED + 50
        seen = []

        def fake_job(ex, ms, empty, emit):
            good = mutants.Outcome("empty", ex.name, ex.name, "empty_output", True, [],
                                   V("fail", "fail", [f"ref: r{i}" for i in range(n)]))
            bad = mutants.Outcome("empty", ex.name + "/bad", ex.name, "empty_output", False, ["x"],
                                  V("pass", "fail", [f"c: r{i}" for i in range(n)]))
            for o in (good, bad):
                emit(o)
                seen.append(o)
            return [good, bad]

        saved = mutants._spec_lock, mutants._example_job
        mutants._spec_lock, mutants._example_job = (lambda: 0), fake_job
        try:
            rc = mutants.selftest(only=[], empty=["01_add_classical_const"])
        finally:
            mutants._spec_lock, mutants._example_job = saved
        self.assertEqual(rc, 1)                      # the bad outcome fails the run
        self.assertEqual([o.verdict for o in seen], [None, None])
        recs = [json.loads(line) for line in (report.out_dir() / "selftest" / "outcomes.jsonl").read_text().splitlines()]
        self.assertEqual([r["ok"] for r in recs], [True, False])
        self.assertEqual(len(recs[0]["verdict"]["reasons"]), mutants.REASONS_RECORDED)
        self.assertEqual(recs[0]["verdict"]["reasons_total"], n)
        self.assertEqual(recs[0]["verdict"]["s6"], "fail")
        self.assertEqual(len(recs[1]["verdict"]["reasons"]), n)
        self.assertNotIn("reasons_total", recs[1]["verdict"])


if __name__ == "__main__":
    if "--run" in sys.argv:
        ids = sys.argv[sys.argv.index("--run") + 1:]
        sys.exit(mutants.selftest(only=ids or None, empty=[]))
    unittest.main()
