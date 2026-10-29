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


def cr_witness_oracle(cr):
    """{rule number: witnesses} straight from CR §3's text (see test_rule_text_lists)."""
    sec = re.search(r"^## 3\..*?(?=^## \d)", cr, re.M | re.S).group(0)
    heads = list(re.finditer(r"^(\d+)\.\s+\*\*", sec, re.M))
    out = {}
    for i, h in enumerate(heads):
        block = sec[h.start():heads[i + 1].start() if i + 1 < len(heads) else len(sec)]
        block = " ".join(block.split())
        cuts = [m.end() for m in re.finditer(r"— (?=\d)", block)]
        clause = block[cuts[-1]:] if cuts else ""
        while True:
            c2 = re.sub(r"\([^()]*\)", "", clause)
            if c2 == clause:
                break
            clause = c2
        out[int(h.group(1))] = tuple(re.findall(r"(?<![\d.§])\b\d{2,3}\b(?!\d|\.\d)", clause))
    return out


class Witnesses(unittest.TestCase):
    def test_every_rule_listed(self):
        nums = sorted({int(r.split()[0]) for r in rows_by_rule()})
        self.assertEqual(nums, list(range(1, 28)))

    def test_rule_text_lists(self):
        # Expected witnesses are derived from the pinned CR text at test time, by a mechanism
        # independent of progress.py: slice §3 at the numbered rule heads, take the text after the
        # rule's last "— <digit>", delete parenthesized remarks innermost-first, and collect the
        # bare 2-3 digit numbers. Rule 14 (split into sub-cases) is test_rule14_cases.
        rows = rows_by_rule()
        oracle = cr_witness_oracle(CR)
        self.assertEqual(sorted(oracle), list(range(1, 28)))
        checked = 0
        for rule, ws in rows.items():
            n = int(rule.split()[0])
            if n == 14:
                continue
            with self.subTest(rule=rule):
                self.assertEqual(ws, oracle[n])
            checked += 1
        self.assertEqual(checked, 26)
        # not vacuous: most rules carry witnesses, and each is an example directory
        self.assertGreater(sum(1 for n, w in oracle.items() if w), 20)
        ex = progress.example_numbers()
        for n, w in oracle.items():
            for e in w:
                self.assertIn(str(int(e)), ex, f"rule {n}: {e}")

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

    def __init__(self, compare_reasons=(), samples=({"call": 0, "args": [0]},), drop=(), classes=None,
                 domain=(), trip_runs=None):
        self.calls = []
        self.compare_reasons = list(compare_reasons)
        self.samples = list(samples)
        self.drop = set(drop)
        # a complete sample set by default: every class present, nothing applicable left out
        self.classes = complete_classes() if classes is None else classes
        self.domain = list(domain)
        self.trip_runs = trip_runs or {}    # sample index -> (events, loops) of the C oracle

    def __enter__(self):
        self.saved = {}
        spec = DriverSpec("x", [], "", [{"fn": "f", "args": [{"ctype": "int", "quantum": True}]}])

        def rr(side):
            return RunResult(side, None, {}, {}, [], [], [], [])

        fns = {
            ("drivers", "driver_spec"): lambda name, d: spec,
            ("sampling", "sample_set"): lambda s, d: SampleSet("x", self.samples, self.classes),
            ("run", "run_sample"): lambda p, s, smp, side: (self.calls.append(("run", side)), rr(side))[1],
            ("oracle", "run_sample"): lambda p, s, smp: (self.calls.append(("oracle",)), rr("c"))[1],
            # report.evaluate runs each side as a batch (cq-3ebz)
            ("run", "run_samples"): lambda p, s, smps, side: [
                (self.calls.append(("run", side)), rr(side))[1] for _ in smps],
            ("oracle", "run_samples"): lambda p, s, smps: [
                (self.calls.append(("oracle",)), self.oracle_run(smp))[1] for smp in smps],
            ("oracle", "run_result"): lambda sr, s, o1: rr("c"),
            ("compare", "compare"): lambda a, b, against, classical_key=None: (
                self.calls.append(("compare", against, classical_key)), self.compare_reasons)[1],
            ("compare", "classical_key_from_driver"): lambda d: (self.calls.append(("key", d)),
                                                                 self.key)[1],
        }
        self.key = lambda sample: ("classical", repr(sample))
        for (mod, name), fn in fns.items():
            m = importlib.import_module(f"cqcheck.{mod}")
            self.saved[(mod, name)] = getattr(m, name, None)
            if (mod, name) in self.drop:
                if hasattr(m, name):
                    delattr(m, name)
            else:
                setattr(m, name, fn)
        from cqcheck import gaps
        self.gaps_domain = gaps.domain_check
        gaps.domain_check = lambda spec, d, ss: list(self.domain)
        self.verify = report.verify
        report.verify = lambda p, reference=False: (self.calls.append(("verify", reference)),
                                                    (report.PASS, ""))[1]
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
        importlib.import_module("cqcheck.gaps").domain_check = self.gaps_domain

    def oracle_run(self, smp):
        i = self.samples.index(smp)
        evs, loops = self.trip_runs.get(i, ([], []))
        return types.SimpleNamespace(failed=False, reason="", events=evs, loops=loops)


def complete_classes(trips=None):
    """A sample set's classes for FakeSiblings' one call with one int quantum argument."""
    return {"edge": {"0": {"samples": [0]}}, "specials": {"0": {"empty": "no floating-point quantum input in this call"}},
            "exhaustive": {"0": {"empty": "the quantum inputs of this call total 32 bits > 8"}},
            "random_seed": {"seed": 1, "quantum": {"0": {"samples": [0]}},
                            "classical": {"0": {"empty": "no classical scalar argument in this call"}}},
            "totalization": {"rows": [], "empty": "no instruction of the example is named by a CR §2 row"},
            "trips": trips or {"K": 4, "loops": [], "empty": "the example has no loop"}}


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
        self.assertIn(("compare", "c", f.key), f.calls)     # the C oracle still runs
        self.assertTrue(report.green(v))

    def test_no_short_circuit(self):
        with FakeSiblings() as f:
            report.evaluate(EX04, EX04.reference, "ref", short_circuit=False)
        self.assertIn(("compare", "ref", f.key), f.calls)
        self.assertIn(("verify", False), f.calls)

    def test_reference_mode_verifier(self):
        # Z1 (cq-zew): the baseline verifies a reference with cq-verify<reference> (S1).
        with FakeSiblings() as f:
            report.evaluate(EX04, EX04.reference, "ref", short_circuit=False, reference_mode=True)
        self.assertIn(("verify", True), f.calls)

    def test_classical_key_from_the_driver_spec(self):
        # Z1 (cq-zew): compare gets classical_key_from_driver(spec) of the example's DriverSpec.
        with FakeSiblings() as f:
            report.evaluate(EX04, self.mutant(), "both")
        keys = [c[1] for c in f.calls if c[0] == "key"]
        self.assertEqual([k.example for k in keys], ["x", "x"])
        self.assertIn(("compare", "ref", f.key), f.calls)
        self.assertIn(("compare", "c", f.key), f.calls)

    def test_missing_classical_key_is_error_never_pass(self):
        with FakeSiblings(drop={("compare", "classical_key_from_driver")}):
            v = report.evaluate(EX04, self.mutant(), "both")
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertTrue(any("cq: unimplemented: chk-compare: compare.classical_key_from_driver" in r
                            for r in v.reasons))

    def test_mismatch_runs_s6_and_fails_on_reasons(self):
        with FakeSiblings(compare_reasons=["rotation list differs"]) as f:
            v = report.evaluate(EX04, self.mutant(), "both")
        self.assertEqual((v.s6, v.c_oracle), ("fail", "fail"))
        self.assertIn(("compare", "ref", f.key), f.calls)
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
            importlib.import_module("cqcheck.oracle").run_samples = boom
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


class SampleGaps(unittest.TestCase):
    """cq-h4pn: a class the sampler left empty reaches the verdict (MISSING: not green) or a report
    line (IMPOSSIBLE, NOTE); sampling's own checks (check_sample_set, confirm_trips,
    domain_problems) do too."""

    def mutant(self):
        p = Path(tempfile.mkstemp(suffix=".ll", dir=TMP)[1])
        p.write_text(EX04.reference.read_text().replace("double %1)", "double 1.0)", 1))
        return p

    def run_with(self, oracle="both", compare_reasons=(), **kw):
        with FakeSiblings(compare_reasons=compare_reasons, **kw):
            return report.evaluate(EX04, self.mutant(), oracle)

    @staticmethod
    def loop(trips):
        return {"K": 4, "loops": [{"loop": "f:%7", "parent": None, "trips": trips}]}

    def test_complete_set_is_green_and_quiet(self):
        v = self.run_with()
        self.assertEqual((v.s6, v.c_oracle), ("pass", "pass"))
        self.assertFalse([r for r in v.reasons if r.startswith("sampling")])

    def test_missing_trip_target_is_not_green(self):
        found = {"0": {"sample": 0}, "3": {"sample": 0}, "4": {"sample": 0}}
        trips = dict(found, **{"5": {"empty": "no input found: the C oracle's trip counts on 9 candidates "
                                             "are [0, 3, 4]; 10 probe runs searched"}})
        runs = {0: ([{"ev": "trip", "loop": "f:%7", "n": n} for n in (0, 3, 4)], [])}
        v = self.run_with(classes=complete_classes(self.loop(trips)), trip_runs=runs)
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertFalse(report.green(v))
        self.assertTrue(any(r.startswith("sampling: missing: trips: f:%7 trip 5: no input found") for r in v.reasons),
                        v.reasons)
        # oracle=ref alone: the trip samples still go through the C oracle's trip counters
        v = self.run_with(oracle="ref", classes=complete_classes(self.loop(trips)), trip_runs=runs)
        self.assertEqual((v.s6, v.c_oracle), ("error", "not-run"))

    def test_missing_trip_target_with_a_failing_compare_stays_fail(self):
        trips = {t: {"empty": "no input found: nothing"} for t in ("0", "3", "4", "5")}
        v = self.run_with(compare_reasons=["rotation list differs"], classes=complete_classes(self.loop(trips)))
        self.assertEqual((v.s6, v.c_oracle), ("fail", "fail"))
        self.assertIn("sampling: missing: trips: f:%7 trip 3: no input found: nothing", v.reasons)

    def test_trip_sample_the_oracle_disagrees_with(self):
        trips = {t: {"sample": 0} for t in ("0", "3", "4", "5")}
        runs = {0: ([{"ev": "trip", "loop": "f:%7", "n": 2}], [])}
        v = self.run_with(classes=complete_classes(self.loop(trips)), trip_runs=runs)
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertTrue(any(r.startswith("sampling: trip sample disagrees:") and "gives trips [2]" in r
                            for r in v.reasons), v.reasons)

    def test_empty_class_the_sampler_gave_up_on(self):
        c = complete_classes()
        c["random_seed"]["classical"]["0"] = {"empty": "none of 64 seeded classical candidates ran to "
                                                       "completion in the C program (outcomes: ['timeout'])"}
        v = self.run_with(classes=c)
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertTrue(any(r.startswith("sampling: missing: random_seed.classical: call 0:") for r in v.reasons))

    def test_unknown_reason_is_missing(self):
        c = complete_classes()
        c["edge"]["0"] = {"empty": "something new"}
        v = self.run_with(classes=c)
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertIn("sampling: missing: edge: call 0: something new", v.reasons)

    def test_class_absent_is_missing(self):
        c = complete_classes()
        del c["specials"]
        v = self.run_with(classes=c)
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertTrue(any(r.startswith("sampling: missing: sample set: ") for r in v.reasons), v.reasons)

    def test_out_of_domain_sample_is_not_green(self):
        v = self.run_with(domain=["x: sample 3 accesses outside its object"])
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertIn("sampling: outside the domain: x: sample 3 accesses outside its object", v.reasons)

    def test_impossible_class_is_reported_and_green(self):
        c = complete_classes()
        c["edge"]["0"] = {"empty": "every one of its 9 samples accesses outside an object in the C program: "
                                   "outside its domain (cq-nqna)", "out_of_domain": 9}
        c["totalization"] = {"rows": [
            {"site": "f: %3 = sdiv i32 %1, %2", "row": "sdiv by 0",
             "empty": "outside the domain: undefined in LLVM (owner ruling 2026-10-28, CLAUDE.md Domain; cq-f075)"},
            {"site": "f: %4 = fadd double %1, %2", "row": "overflow",
             "empty": "unreachable by search: the site ran in 3 of 9 pool samples"},
            {"site": "f: %5 = fadd double %1, %2", "row": "normal", "samples": [0]}]}
        v = self.run_with(classes=c)
        self.assertEqual((v.s6, v.c_oracle), ("pass", "pass"))
        self.assertTrue(report.green(v))
        self.assertTrue(any(r.startswith("sampling: impossible: edge: call 0: every one of its 9") for r in v.reasons))
        self.assertTrue(any(r.startswith("sampling: impossible: totalization: 1 of 3") for r in v.reasons))
        self.assertTrue(any(r.startswith("sampling: note: totalization: 1 of 3") for r in v.reasons))

    def test_gap_check_crash_is_error(self):
        from cqcheck import gaps

        def boom(*a):
            raise RuntimeError("gap check crashed")
        saved = gaps.sample_gaps
        gaps.sample_gaps = boom
        try:
            v = self.run_with()
        finally:
            gaps.sample_gaps = saved
        self.assertEqual((v.s6, v.c_oracle), ("error", "error"))
        self.assertTrue(any("gap check crashed" in r for r in v.reasons))

    def test_classify_reason(self):
        from cqcheck import gaps
        self.assertIsNone(gaps.classify_reason("the quantum inputs of this call total 32 bits > 8"))
        self.assertEqual(gaps.classify_reason("the quantum inputs of this call total 6 bits > 4"), gaps.MISSING)
        self.assertIsNone(gaps.classify_reason(
            "no scalar argument of this call flows into a cq_theta_* register; every cq_theta_* register is "
            "computed inside the program; substituted cq_theta sites: no floating-point register among the "
            "substituted cq_theta sites"))
        self.assertEqual(gaps.classify_reason("the loop is never reached from the drivers.txt calls"), gaps.MISSING)
        self.assertEqual(gaps.classify_reason(""), gaps.MISSING)


class TripProofs(unittest.TestCase):
    """cq-h4pn: a trip count is IMPOSSIBLE only with a proof (ScalarEvolution, or a header every
    call reaches); the search's evidence alone keeps it MISSING."""

    def gaps_of(self, name, loop, targets):
        from cqcheck import drivers as D, gaps
        ex = report.resolve_examples([name])[0]
        spec = D.driver_spec(ex.name, ex.dir)
        trips = {t: {"empty": "no input found: the C oracle's trip counts on 9 candidates are [1]"}
                 for t in targets}
        c = complete_classes({"K": 4, "loops": [{"loop": loop, "parent": None, "trips": trips}]})
        ss = SampleSet(ex.name, [{"call": i, "args": []} for i in range(len(spec.calls))], c)
        return {g.where.rsplit(" ", 1)[1]: g for g in gaps.sample_gaps(spec, ss, ex.dir, report.LLVM_BIN)
                if g.where.startswith("trips")}

    def test_do_while_never_runs_zero_trips(self):
        g = self.gaps_of("150", "do_while_quantum:%7", ("0", "5"))
        self.assertEqual(g["0"].kind, "impossible")
        self.assertIn("never reports 0", g["0"].why)
        self.assertEqual(g["5"].kind, "missing")          # a quantum exit: any count may occur

    def test_constant_trip_count(self):
        # 120 register_grid:%19 runs exactly 2 trips (ScalarEvolution: backedge-taken count 1)
        g = self.gaps_of("120", "register_grid:%19", ("0", "3", "4", "5"))
        for t in ("3", "4", "5"):
            self.assertEqual(g[t].kind, "impossible", g[t])
            self.assertIn("always 1", g[t].why)
        # cq-oou2: nested, but no guard skips it and its header is a latch: the oracle never reports 0
        self.assertEqual(g["0"].kind, "impossible", g["0"])
        self.assertIn("never reports 0", g["0"].why)

    def test_nested_zero_trips(self):
        # cq-oou2: 68's inner loop is entered unguarded on every outer trip (j = 0 < i holds)
        g = self.gaps_of("68", "nested_quantum_loops:%15", ("0",))
        self.assertEqual(g["0"].kind, "impossible", g["0"])
        # 60's inner loop (j = i + 1; j < n) has a guard that skips it: 0 stays unproved
        g = self.gaps_of("60", "qft:%23", ("0",))
        self.assertEqual(g["0"].kind, "missing", g["0"])

    def test_bound_by_an_argument_is_not_proved(self):
        g = self.gaps_of("25", "for_classical_bound:%10", ("0", "3", "4", "5"))
        self.assertTrue(all(x.kind == "missing" for x in g.values()), g)


class Bundle(unittest.TestCase):
    """cq-b041: lower() links the injection bundle (--only-needed) only into a module that declares
    without a body a symbol the bundle defines; cq-sl4s: the keys carry the files actually linked."""

    HEAD = ('target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"\n'
            'target triple = "x86_64-apple-macosx"\n')   # Mach-O mangling, as the corpus and the bundle
    USER_NEEDS = HEAD + ("declare i32 @bfoo(i32)\n"
                         "define i32 @user(i32 %x) {\n  %r = call i32 @bfoo(i32 %x)\n  ret i32 %r\n}\n")
    USER_NOT = HEAD + ("declare i32 @other(i32)\n"
                       "define i32 @user(i32 %x) {\n  %r = call i32 @other(i32 %x)\n  ret i32 %r\n}\n")
    LIB = HEAD + ("define i32 @bfoo(i32 %x) {\n  %r = call i32 @bbar(i32 %x)\n  ret i32 %r\n}\n"
                  "define i32 @bbar(i32 %x) {\n  %r = add i32 %x, 1\n  ret i32 %r\n}\n"
                  "define i32 @bunused(i32 %x) {\n  ret i32 %x\n}\n")

    def setUp(self):
        from cqcheck import oracle
        self.oracle = oracle
        self.d = Path(tempfile.mkdtemp(dir=TMP))
        (self.d / "lib.ll").write_text(self.LIB)
        self.bc = self.d / "lib.bc"
        r = report._run([str(report.LLVM_BIN / "llvm-as"), str(self.d / "lib.ll"), "-o", str(self.bc)])
        self.assertEqual(r.returncode, 0, r.stderr)
        self.saved = oracle._bundle_files
        oracle._bundle_files = lambda: [self.bc]

    def tearDown(self):
        self.oracle._bundle_files = self.saved

    def example(self, name, text):
        d = self.d / name
        d.mkdir()
        ex = report.Example(name, d)
        ex.o1.write_text(text)
        return ex

    def test_bundle_for(self):
        self.assertEqual(self.oracle.bundle_for(self.USER_NEEDS), [self.bc])
        self.assertEqual(self.oracle.bundle_for(self.USER_NOT), [])
        # a symbol the module defines itself is not a need
        self.assertEqual(self.oracle.bundle_for(self.HEAD + "define i32 @bfoo(i32 %x) {\n  ret i32 %x\n}\n"), [])
        self.assertEqual(self.oracle.bundle_for(self.HEAD + "@bfoo = external global i32\n"), [self.bc])
        self.oracle._bundle_files = lambda: []
        self.assertEqual(self.oracle.bundle_for(self.USER_NEEDS), [])

    def test_lower_links_only_needed(self):
        ex = self.example("900_needs", self.USER_NEEDS)
        out, err = report.lower(ex, self.d / "ours" / ex.name / f"{ex.base}.lowered.ll")
        self.assertEqual(err, "")
        text = out.read_text()
        self.assertIn("define i32 @bfoo(", text)
        self.assertIn("define i32 @bbar(", text)       # the bundle's own callee comes along
        self.assertNotIn("@bunused", text)
        self.assertNotIn("declare i32 @bfoo", text)
        self.assertTrue((out.parent / f"{ex.base}.linked.ll").exists())

    def test_lower_without_need_is_unchanged(self):
        ex = self.example("901_not", self.USER_NOT)
        out, err = report.lower(ex, self.d / "ours" / ex.name / f"{ex.base}.lowered.ll")
        self.assertEqual(err, "")
        self.assertFalse((out.parent / f"{ex.base}.linked.ll").exists())
        plain = report._run([str(report.LLVM_BIN / "opt"), "-S", str(ex.o1)]).stdout.decode()
        self.assertEqual(out.read_text(), plain)

    def test_keys_carry_linked_files(self):
        k1 = self.oracle.bundle_key([self.bc])
        self.assertIn(str(self.bc), k1)
        (self.d / "lib2.ll").write_text(self.LIB.replace("add i32 %x, 1", "add i32 %x, 2"))
        r = report._run([str(report.LLVM_BIN / "llvm-as"), str(self.d / "lib2.ll"), "-o", str(self.bc)])
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotEqual(self.oracle.bundle_key([self.bc]), k1)   # content, not only the path
        self.assertEqual(self.oracle.bundle_key([]), "")


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
        # cq-8dr6: a run with --ours is not our pass; it never reaches the progress store
        self.assertNotIn("04_value_arm_ifelse", report.load_verdicts())

    def test_progress_needs_the_pinned_toolchain(self):
        # cq-lum1: a run with a non-default CQ_LLVM_BIN lowers and runs with another LLVM; its
        # verdicts never reach the progress store
        from unittest import mock
        env = {k: v for k, v in os.environ.items() if k not in ("CQ_PLUGIN", "CQ_LLVM_BIN", "CQ_SPEC_DIR")}
        with mock.patch.dict(os.environ, env, clear=True):
            self.assertTrue(cli.stores_progress(None, "both"))
            self.assertFalse(cli.stores_progress(None, "ref"))
            self.assertFalse(cli.stores_progress(Path(TMP), "both"))
            with mock.patch.dict(os.environ, {"CQ_LLVM_BIN": "/usr/local/opt/llvm@18/bin"}):
                self.assertFalse(cli.stores_progress(None, "both"))
            with mock.patch.dict(os.environ, {"CQ_LLVM_BIN": str(report.DEFAULT_LLVM_BIN)}):
                self.assertTrue(cli.stores_progress(None, "both"))
            with mock.patch.object(report, "LLVM_BIN", Path("/usr/local/opt/llvm@18/bin")):
                self.assertFalse(cli.stores_progress(None, "both"))
            with mock.patch.dict(os.environ, {"CQ_PLUGIN": str(REAL_PLUGIN)}):
                self.assertFalse(cli.stores_progress(None, "both"))

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
