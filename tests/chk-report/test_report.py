#!/usr/bin/env python3
"""Unit tests of module chk-report (bead cq-w0-chk-report): report.py, progress.py, cli.py.

    python3 tests/chk-report/test_report.py        (from the repository root, or via ctest)

Uses the pinned CQ_spec (CQ_SPEC_DIR or ../CQ_spec) read-only and LLVM 19. Writes only to a
temporary directory (CQ_BUILD_DIR is redirected there).
"""
import importlib
import os
import re
import sys
import tempfile
import types
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))
TMP = tempfile.mkdtemp(prefix="cq-chk-report-")
os.environ["CQ_BUILD_DIR"] = TMP
REAL_PLUGIN = ROOT / "build" / "pass" / "libCQLower.so"
os.environ.setdefault("CQ_PLUGIN", str(REAL_PLUGIN))

from cqcheck import cli, progress, report  # noqa: E402
from cqcheck.contracts import RunResult, SampleSet, DriverSpec, Verdict  # noqa: E402

SPEC = report.spec_dir()
CR = (SPEC / "CONSTRUCTION_RULES.md").read_text()
EX04 = report.resolve_examples(["04"])[0]


def rows_by_rule():
    return {r.rule: r.witnesses for r in progress.parse_rules(CR)}


class Witnesses(unittest.TestCase):
    def test_every_rule_listed(self):
        nums = sorted({int(r.split()[0]) for r in rows_by_rule()})
        self.assertEqual(nums, list(range(1, 28)))

    def test_rule_text_lists(self):
        rows = rows_by_rule()
        self.assertEqual(rows["1 Handle ABI"], ("01", "46", "64", "93", "103", "110", "111"))
        self.assertEqual(rows["6 Bijective update of a dead value"], ("125", "127"))
        self.assertEqual(rows["12 Phase deletion"], ("41",))
        self.assertEqual(rows["13 switch"], ("22", "49", "123", "131", "142"))
        # rule 16: the "; 91 (…); 186 (…)" items count, their remarks do not
        self.assertEqual(rows["16 Noreturn arms and host effects"],
                         ("45", "47", "99", "102", "108", "138", "91", "186"))
        # rule 18: the parenthesized "(36, 51, … to be rewritten)" remark is stripped
        self.assertEqual(rows["18 Function lifting"], ("06", "07", "33", "34", "64", "119", "136"))
        # rule 20: the clause after the bullets is the whole rule's; "(102, 106, 129)" inside is not
        r20 = rows["20 Memory classification"]
        self.assertEqual(r20[0], "29")
        self.assertEqual(r20[-1], "168")
        self.assertNotIn("102", r20)
        self.assertEqual(rows["27 Callees without a body: declared clones"], ())

    def test_rule14_cases(self):
        rows = {k: v for k, v in rows_by_rule().items() if k.startswith("14 ")}
        self.assertEqual(len(rows), 6)
        self.assertEqual(rows["14 Loops: Classical bound, quantum body"],
                         ("25", "27", "28", "57", "62", "131", "187", "188"))
        self.assertEqual(rows["14 Loops: Quantum-dependent exit, cutoff K"][0], "05")
        self.assertEqual(rows["14 Loops: Quantum-dependent exit, cutoff K"][-1], "189")
        self.assertEqual(rows["14 Loops: Classical bound with a quantum exit"], ("26", "121", "130", "139"))
        self.assertEqual(rows["14 Loops: Recursion with quantum depth"], ("98",))
        self.assertEqual(rows["14 Loops: Irreducible control flow"], ())

    def test_every_witness_is_an_example(self):
        table, problems = progress.build_table(CR, {}, progress.example_numbers())
        self.assertEqual(problems, [])
        # no verdicts: everything failing, nothing passing
        self.assertTrue(all(p == "" for _, _, p, _ in table))

    def test_clause_parsing(self):
        self.assertEqual(progress.witness_clause("x. — 01, 02 (a, 03), 04; new example required (§8)."),
                         ("01", "02", "04"))
        self.assertEqual(progress.witness_clause("no clause — here"), ())

    def test_table_passing(self):
        ex = progress.example_numbers()
        good = Verdict(ex["46"], "pass", "pass", "pass", 0, [])
        half = Verdict(ex["64"], "pass", "not-run", "pass", 0, [])
        table, _ = progress.build_table(CR, {good.example: good, half.example: half}, ex)
        row = next(r for r in table if r[0] == "1 Handle ABI")
        self.assertEqual(row[2], "46")
        self.assertIn("64", row[3].split(", "))
        self.assertTrue(progress.tsv(table).startswith("rule\twitnesses\tpassing\tfailing\n"))


class Diff(unittest.TestCase):
    def test_reference_matches_itself(self):
        n, d = report.textual_diff(EX04.reference, EX04.reference)
        self.assertEqual((n, d), (0, ""))

    def write(self, text):
        p = Path(tempfile.mkstemp(suffix=".ll", dir=TMP)[1])
        p.write_text(text)
        return p

    def test_comments_names_and_declare_order_ignored(self):
        text = EX04.reference.read_text()
        text = re.sub(r";[^\n]*", "", text)                         # every comment gone
        text = text.replace("%10", "%sel").replace("%11", "%m")       # named locals
        lines = text.split("\n")
        decls = [l for l in lines if l.startswith("declare ")]
        rest = [l for l in lines if not l.startswith("declare ")]
        p = self.write("\n".join(rest + list(reversed(decls))))
        self.assertEqual(report.textual_diff(p, EX04.reference)[0], 0)

    def test_mutation_differs(self):
        text = EX04.reference.read_text().replace(
            "call void @cqrt_ry_i32(i32 %6, double %1)", "call void @cqrt_ry_i32(i32 %6, double 1.0)")
        n, d = report.textual_diff(self.write(text), EX04.reference)
        self.assertEqual(n, 2)
        self.assertIn("double 1.0", d)

    def test_unparsable_is_an_error(self):
        with self.assertRaises(report.NormalizeError):
            report.normalize(self.write("define i32 @f( {"))


class FakeSiblings:
    """Installs fake sibling functions for the duration of a test; the real modules are restored."""

    def __init__(self, compare_reasons=(), samples=({"call": 0, "args": [0]},), drop=()):
        self.calls = []
        self.compare_reasons = list(compare_reasons)
        self.samples = list(samples)
        self.drop = set(drop)

    def __enter__(self):
        self.saved = {}
        spec = DriverSpec("x", [], "", [])

        def rr(side):
            return RunResult(side, None, {}, {}, [], [], [], [])

        fns = {
            ("drivers", "driver_spec"): lambda name, d: spec,
            ("sampling", "sample_set"): lambda s, d: SampleSet("x", self.samples, {}),
            ("run", "run_sample"): lambda p, s, smp, side: (self.calls.append(("run", side)), rr(side))[1],
            ("oracle", "run_sample"): lambda p, s, smp: (self.calls.append(("oracle",)), rr("c"))[1],
            ("compare", "compare"): lambda a, b, against: (self.calls.append(("compare", against)),
                                                           self.compare_reasons)[1],
        }
        for (mod, name), fn in fns.items():
            m = importlib.import_module(f"cqcheck.{mod}")
            self.saved[(mod, name)] = getattr(m, name, None)
            if (mod, name) in self.drop:
                if hasattr(m, name):
                    delattr(m, name)
            else:
                setattr(m, name, fn)
        self.verify = report.verify
        report.verify = lambda p: (report.PASS, "")
        return self

    def __exit__(self, *exc):
        for (mod, name), fn in self.saved.items():
            m = importlib.import_module(f"cqcheck.{mod}")
            if fn is None:
                if hasattr(m, name):
                    delattr(m, name)
            else:
                setattr(m, name, fn)
        report.verify = self.verify


class Evaluate(unittest.TestCase):
    def mutant(self):
        p = Path(tempfile.mkstemp(suffix=".ll", dir=TMP)[1])
        p.write_text(EX04.reference.read_text().replace("double %1)", "double 1.0)", 1))
        return p

    def test_textual_match_short_circuits_ref_only(self):
        with FakeSiblings() as f:
            v = report.evaluate(EX04, EX04.reference, "both")
        self.assertEqual((v.s6, v.c_oracle, v.verifier, v.diff_lines), ("pass", "pass", "pass", 0))
        self.assertNotIn(("run", "ref"), f.calls)          # §6 vs reference short-circuited
        self.assertIn(("compare", "c"), f.calls)            # the C oracle still runs
        self.assertTrue(report.green(v))

    def test_no_short_circuit(self):
        with FakeSiblings() as f:
            report.evaluate(EX04, EX04.reference, "ref", short_circuit=False)
        self.assertIn(("compare", "ref"), f.calls)

    def test_mismatch_runs_s6_and_fails_on_reasons(self):
        with FakeSiblings(compare_reasons=["rotation list differs"]) as f:
            v = report.evaluate(EX04, self.mutant(), "both")
        self.assertEqual((v.s6, v.c_oracle), ("fail", "fail"))
        self.assertIn(("compare", "ref"), f.calls)
        self.assertEqual(v.diff_lines, 2)
        self.assertIn("ref: rotation list differs", v.reasons)
        self.assertFalse(report.green(v))

    def test_mismatch_equal_passes(self):
        with FakeSiblings():
            v = report.evaluate(EX04, self.mutant(), "ref")
        self.assertEqual((v.s6, v.c_oracle), ("pass", "not-run"))
        self.assertFalse(report.green(v))
        self.assertTrue(report.requested_green(v))

    def test_missing_sibling_is_error_never_pass(self):
        with FakeSiblings(drop={("compare", "compare")}):
            v = report.evaluate(EX04, self.mutant(), "both")
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertTrue(any("cq: unimplemented: chk-compare: compare.compare" in r for r in v.reasons))

    def test_empty_sample_set_is_error(self):
        with FakeSiblings(samples=()):
            v = report.evaluate(EX04, self.mutant(), "both")
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))

    def test_sibling_exception_is_error(self):
        def boom(*a):
            raise RuntimeError("evaluator crashed")
        with FakeSiblings():
            importlib.import_module("cqcheck.oracle").run_sample = boom
            v = report.evaluate(EX04, self.mutant(), "both")
        self.assertEqual(v.c_oracle, "error")
        self.assertTrue(any("evaluator crashed" in r for r in v.reasons))

    def test_no_lowered_module(self):
        v = report.evaluate(EX04, None, "both", lower_error="cq-lower exited 1: cq: unimplemented: x")
        self.assertEqual((v.s6, v.c_oracle, v.verifier, v.diff_lines), ("error", "error", "error", None))

    def test_unbuilt_verifier_is_error(self):
        self.assertTrue(Path(os.environ["CQ_PLUGIN"]).exists(), "build the plugin first")
        st, why = report.verify(EX04.reference)
        if "unimplemented" in why:
            self.assertEqual(st, "error")
        else:
            self.assertIn(st, ("pass", "fail"))


class Cli(unittest.TestCase):
    def test_names_or_all(self):
        self.assertEqual(cli.main(["run"]), 2)
        self.assertEqual(cli.main(["run", "04", "--all"]), 2)

    def test_unknown_example_is_an_error(self):
        self.assertEqual(cli.main(["run", "999"]), 2)

    def test_ours_without_file_is_an_error_verdict(self):
        empty = tempfile.mkdtemp(dir=TMP)
        out = Path(TMP) / "v.jsonl"
        rc = cli.main(["run", "04", "--ours", empty, "--json", str(out)])
        self.assertEqual(rc, 1)
        line = out.read_text().strip()
        self.assertIn('"s6":"error"', line)
        self.assertIn("no lowered module for 04_value_arm_ifelse", line)
        self.assertIn("04_value_arm_ifelse", report.load_verdicts())

    def test_resolve(self):
        self.assertEqual(report.resolve_examples(["4"])[0].name, "04_value_arm_ifelse")
        self.assertEqual(report.resolve_examples(["04_value"])[0].name, "04_value_arm_ifelse")
        with self.assertRaises(ValueError):
            report.resolve_examples(["0"])

    def test_examples_counted_from_directory(self):
        names = [e.name for e in report.all_examples()]
        on_disk = sorted(d.name for d in (SPEC / "examples").iterdir() if d.is_dir())
        self.assertEqual(sorted(names), on_disk)
        nums = [int(n.split("_")[0]) for n in names]
        self.assertEqual(nums, sorted(nums))


if __name__ == "__main__":
    unittest.main()
