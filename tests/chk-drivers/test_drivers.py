"""Unit tests of cqcheck.drivers and cqcheck.sampling (cq-w0-chk-drivers). Run from checker/."""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "checker"))

from cqcheck import drivers as D          # noqa: E402
from cqcheck import sampling as S         # noqa: E402
from cqcheck.contracts import DriverSpec, SampleSet, from_json, to_json   # noqa: E402

CLANG = str(S.LLVM_BIN / "clang")
# subprocesses a test runs at once: $CQCHECK_JOBS (the machine-wide cap), else 2
JOBS = max(1, min(4, int(os.environ.get("CQCHECK_JOBS") or 2)))


def q(spec, call=0):
    return [a["quantum"] for a in spec.calls[call]["args"]]


class DriverSpecs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.specs = {n: D.driver_spec(n, D.example_dir(n)) for n in D.all_examples()}

    def test_every_example_has_a_line_and_a_spec(self):
        lines = D.read_drivers_txt()
        self.assertEqual(sorted(lines), sorted(D.all_examples()))
        for n, s in self.specs.items():
            self.assertEqual(s.example, n)
            self.assertTrue(s.calls)
            self.assertEqual(from_json(DriverSpec, to_json(s)), s)

    def test_seven_setup_snippets(self):
        with_setup = [n for n, l in D.read_drivers_txt().items() if l.setup]
        self.assertEqual(len(with_setup), 7)
        for n in with_setup:
            self.assertIn(D.read_drivers_txt()[n].setup, self.specs[n].setup)

    def test_implicit_objects(self):
        self.assertIn("static const double coef[4]", self.specs["28_horner_accumulator"].setup)
        self.assertIn("static const int icoef[4]", self.specs["36_callee_with_loop"].setup)
        self.assertEqual(self.specs["01_add_classical_const"].setup, "")

    def test_quantum_arguments(self):
        s = self.specs
        self.assertEqual(q(s["01_add_classical_const"]), [True, False, False])
        self.assertEqual(q(s["02_add_quantum_quantum"]), [True, True, False, False])
        # the angle of a second rotation is not a register (38)
        self.assertEqual(q(s["38_second_rotation"]), [True, False, False])
        # a register reached through local memory and a callee (61 invert_call: x via &x into prep)
        self.assertEqual(q(s["61_invert_theta_and_call"], 1), [True, True, False, False, False, False])
        # sizes that also seed registers are classical (114: q[i] = (i >= n - k))
        self.assertEqual(q(s["114_dicke_n"]), [False, False])
        # a compare that picks the register value is classical (144: if (x > k) y += 1)
        self.assertEqual(q(s["144_value_arm_then_rotate"]), [True, False, True, False, False, False])
        # registers computed inside the program: no quantum argument (58, 113)
        self.assertEqual(q(s["58_register_array"]), [False, False])
        self.assertEqual(s["113_dicke4"].calls[0]["args"], [])
        # a pointer to the caller's registers (60): handle cells, each a quantum input (cq-rbe6)
        self.assertEqual(q(s["60_qft"]), [True, False, False])
        self.assertEqual(s["60_qft"].calls[0]["args"][0].get("cells"), {"w": 1, "n": 4})


class Loops(unittest.TestCase):
    def test_loops_equal_llvm_loopinfo(self):
        """The probe's natural loops are LLVM's LoopInfo loops, spelled per T1 (<fn>:<header>)."""
        import re
        from concurrent.futures import ThreadPoolExecutor

        def loopinfo(n):
            return subprocess.run([str(S.LLVM_BIN / "opt"), "-passes=print<loops>", "-disable-output",
                                   str(D.o1_path(n))], capture_output=True, text=True).stderr

        names = D.all_examples()
        # one opt process per example, at most $CQCHECK_JOBS at once (cq-wx6s)
        with ThreadPoolExecutor(max_workers=JOBS) as ex:
            outs = ex.map(loopinfo, names)
            for n, out in zip(names, outs):
                m = D.read_module(D.o1_path(n))
                ins = S.Instrumenter(m)
                mine = sorted(lp.key() for f in m.functions.values() for lp in ins.find_loops(f))
                ref, fn = [], None
                for line in out.splitlines():
                    mm = re.match(r"Loop info for function '(.*)'", line)
                    if mm:
                        fn = mm.group(1)
                    mm = re.search(r"(%[^<, ]+)<header>", line)
                    if mm:
                        ref.append(f"{fn}:{mm.group(1)}")
                self.assertEqual(mine, sorted(ref), n)


class Encoding(unittest.TestCase):
    def test_literals(self):
        ct = D.parse_ctype
        self.assertEqual(S.encode_c_literal(ct("int"), "-1"), "0xffffffff")
        self.assertEqual(S.encode_c_literal(ct("long long"), "-9223372036854775807-1"), "0x8000000000000000")
        self.assertEqual(S.encode_c_literal(ct("unsigned"), "0xc9"), "0x000000c9")
        self.assertEqual(S.encode_c_literal(ct("double"), ".5"), "0x3fe0000000000000")
        self.assertEqual(S.encode_c_literal(ct("float"), "3"), "0x40400000")
        self.assertEqual(S.encode_c_literal(ct("long double"), "1"), "0x3fff8000000000000000")
        self.assertEqual(S.encode_c_literal(ct("_Bool"), "1"), "0x1")

    def test_fp_kinds(self):
        self.assertEqual(S.fp_kind(0x7ff8000000000000, 64)[0], "nan")
        self.assertEqual(S.fp_kind(1, 64)[0], "sub")
        self.assertEqual(S.fp_kind(0x3fff8000000000000000, 80), ("norm", 1))
        for nc in S.f80_noncanonical():
            self.assertEqual(S.fp_kind(nc, 80)[0], "noncanon")

    def test_driver_source_is_bit_exact(self):
        """driver_source renders every scalar width with its exact bit pattern."""
        spec = DriverSpec("t", ["int f(_Bool,signed char,unsigned long long,float,double,long double);"], "",
                          [{"fn": "f", "args": [{"ctype": c, "quantum": True} for c in
                                                ("_Bool", "signed char", "unsigned long long", "float",
                                                 "double", "long double")]}])
        vals = ["0x1", "0x80", "0xfedcba9876543210", "0x7fc12345", "0xfff8000000012345", "0x7fffc000000000000001"]
        src = D.driver_source(spec, [{"call": 0, "args": vals}])
        callee = r"""
#include <stdio.h>
#include <string.h>
int f(_Bool a, signed char b, unsigned long long c, float d, double e, long double g) {
    unsigned u; unsigned long long v, m; unsigned short x;
    memcpy(&u, &d, 4); memcpy(&v, &e, 8); memcpy(&m, &g, 8); memcpy(&x, (char *)&g + 8, 2);
    printf("%d %x %llx %x %llx %04x%016llx\n", a, (unsigned char)b, c, u, v, x, m); return 0; }
"""
        with tempfile.TemporaryDirectory() as t:
            Path(t, "d.c").write_text(src)
            Path(t, "f.c").write_text(callee)
            Path(t, "s").write_text(D.sample_file(spec, [{"call": 0, "args": vals}]))
            subprocess.run([CLANG, "-w", "-O0", str(Path(t, "d.c")), str(Path(t, "f.c")), "-o", str(Path(t, "a"))],
                           check=True)
            out = subprocess.run([str(Path(t, "a"))], capture_output=True, text=True, check=True,
                                 env=dict(os.environ, CQD_SAMPLES=str(Path(t, "s")))).stdout.split()
        self.assertEqual(out, ["1", "80", "fedcba9876543210", "7fc12345", "fff8000000012345", "7fffc000000000000001"])

    def test_sample_file_shape(self):
        """cq-arch Z2: one line per sample, `<call> <arg>...`, scalars 0x<hex>, pointers p<hex of the
        expression>; the driver source does not depend on scalar values."""
        spec = DriverSpec("t", ["int f(int,const double*);", "int g(long double);"], "",
                          [{"fn": "f", "args": [{"ctype": "int", "quantum": True},
                                                {"ctype": "const double*", "quantum": False}]},
                           {"fn": "g", "args": [{"ctype": "long double", "quantum": True}]}])
        a = [{"call": 0, "args": ["0x00ff", "coef"]}, {"call": 1, "args": ["0x3fff8000000000000000"]}]
        b = [{"call": 0, "args": ["0x7", "coef"]}, {"call": 1, "args": ["0x0"]}]
        self.assertEqual(D.sample_file(spec, a), "0 0xff p636f6566\n1 0x3fff8000000000000000\n")
        self.assertEqual(D.driver_source(spec, a), D.driver_source(spec, b))
        for bad in ({"call": 0, "args": ["7", "coef"]}, {"call": 2, "args": []}, {"call": 1, "args": []},
                    {"call": 1, "args": ["0x1" + "0" * 32]}):
            with self.assertRaises(RuntimeError, msg=bad):
                D.sample_file(spec, [bad])


# The driver shape before cq-7lrz (values baked into the source), kept here as the reference the
# run-time driver must equal bit for bit.
def baked_c_value(ct, v):
    if ct.kind == "p":
        return v
    if ct.kind == "i":
        n = int(v, 16)
        if ct.bits == 1:
            return "(_Bool)" + str(n & 1)
        return f"(({ct.spelling})0x{n:x}ULL)"
    if ct.bits == 32:
        return f"cqd_f32(0x{int(v, 16):08x}u)"
    if ct.bits == 64:
        return f"cqd_f64(0x{int(v, 16):016x}ULL)"
    n = int(v, 16)
    return f"cqd_f80(0x{n & ((1 << 64) - 1):016x}ULL, 0x{n >> 64:04x}u)"


def baked_driver_source(spec, samples):
    out = [D.DRIVER_PRELUDE] + list(spec.protos) + ["int main(void) {", "    " + spec.setup]
    for i, s in enumerate(samples):
        call = spec.calls[s["call"]]
        cts = [D.parse_ctype(a["ctype"]) for a in call["args"]]
        writes, vals = [], []
        for a, ct, v in zip(call["args"], cts, s["args"]):
            if ct.kind == "p":
                v, cv = D.split_ptr(v)
                cells = a.get("cells")
                if cells:    # the C side's view of the handle cells (cq-rbe6): element k = value k
                    nb = max(1, cells["w"] // 8)
                    for k, x in enumerate(cv or ["0x0"] * cells["n"]):
                        writes.append(f"{{ unsigned long long x = {int(x, 16) & ((1 << cells['w']) - 1)}ULL; "
                                      f"memcpy((char *)({v}) + {k * nb}, &x, {nb}); }}")
            vals.append(baked_c_value(ct, v))
        out.append(f"    {{ {' '.join(writes)} (void){call['fn']}({', '.join(vals)}); }}")
    out.append("    return 0;\n}")
    return "\n".join(out) + "\n"


def dump_callees(spec):
    """Definitions of every prototype that print the callee name and each argument's value bytes
    (a pointer: the first 4 bytes it points to)."""
    out = ["#include <stdio.h>", "#include <stdbool.h>",
           "static void cqd_dump(const void *p, int n) { const unsigned char *b = p; "
           "for (int i = n - 1; i >= 0; --i) printf(\"%02x\", b[i]); putchar(' '); }"]
    for t in spec.protos:
        pr = D.parse_proto(t)
        params, body = [], [f'printf("{pr.name} ");']
        for j, ct in enumerate(pr.params):
            params.append(f"{ct.spelling} x{j}")
            if ct.kind == "p":
                body.append(f"cqd_dump((const void *)x{j}, 4);")
            else:
                body.append(f"cqd_dump(&x{j}, {1 if ct.bits == 1 else 10 if ct.bits == 80 else ct.bits // 8});")
        body.append("putchar('\\n');")
        ret = " ".join(pr.ret.split())
        if ret != "void":
            body.append("return 0;")
        out.append(f"{ret} {pr.name}({', '.join(params) or 'void'}) {{ {' '.join(body)} }}")
    return "\n".join(out) + "\n"


# Every scalar width of drivers.txt (_Bool, char, short, int, long, long long, float, double,
# long double, signed and unsigned), pointers and setup snippets, and the fp specials of the sample
# sets (each set's specials class: +-0, +-Inf, NaNs, the smallest subnormal).
RUNTIME_EXAMPLES = ["03_phase_arm_eq", "12_int_widths", "17_casts", "19_fp_widths", "60_qft",
                    "78_array_of_structs", "83_fmod_frem", "90_quantum_length_memcpy", "93_i128",
                    "104_fpclass", "110_bitint", "156_qq_width_matrix", "163_sret_return", "186_free_qram"]
BAKED_CHUNK = 4096


class RuntimeSamples(unittest.TestCase):
    """cq-7lrz acceptance: the run-time driver (cq-arch Z2) passes every argument bit-identical to the
    baked driver, over the drivers' full sample sets of RUNTIME_EXAMPLES."""

    def test_bit_identical_to_baked(self):
        from concurrent.futures import ThreadPoolExecutor
        widths, specials, total = set(), 0, 0
        for n in RUNTIME_EXAMPLES:
            with self.subTest(example=n):
                spec = D.driver_spec(n, D.example_dir(n))
                samples = S.sample_set(spec, D.example_dir(n)).samples
                total += len(samples)
                for s in samples:
                    for a in spec.calls[s["call"]]["args"]:
                        ct = D.parse_ctype(a["ctype"])
                        widths.add((ct.kind, ct.bits, ct.signed) if ct.kind != "p" else ("p",))
                specials += sum(1 for s in samples for a, v in zip(spec.calls[s["call"]]["args"], s["args"])
                                if D.parse_ctype(a["ctype"]).kind == "f"
                                and S.fp_kind(int(v, 16), D.parse_ctype(a["ctype"]).bits)[0] in ("nan", "inf", "sub"))
                with tempfile.TemporaryDirectory() as t:
                    t = Path(t)
                    (t / "callee.c").write_text(dump_callees(spec))
                    (t / "rt.c").write_text(D.driver_source(spec, samples))
                    subprocess.run([CLANG, "-w", "-O0", "-c", str(t / "callee.c"), "-o", str(t / "callee.o")], check=True)
                    subprocess.run([CLANG, "-w", "-O1", str(t / "rt.c"), str(t / "callee.o"), "-o", str(t / "rt")],
                                   check=True)
                    chunks = [samples[k:k + BAKED_CHUNK] for k in range(0, len(samples), BAKED_CHUNK)]

                    def one(k):
                        c = t / f"b{k}.c"
                        c.write_text(baked_driver_source(spec, chunks[k]))
                        subprocess.run([CLANG, "-w", "-O0", str(c), str(t / "callee.o"), "-o", str(t / f"b{k}")],
                                       check=True)
                        baked = subprocess.run([str(t / f"b{k}")], capture_output=True, text=True, check=True).stdout
                        (t / f"s{k}").write_text(D.sample_file(spec, chunks[k]))
                        rt = subprocess.run([str(t / "rt")], capture_output=True, text=True, check=True,
                                            env=dict(os.environ, CQD_SAMPLES=str(t / f"s{k}"))).stdout
                        return baked, rt

                    with ThreadPoolExecutor(max_workers=JOBS) as ex:
                        for k, (baked, rt) in enumerate(ex.map(one, range(len(chunks)))):
                            self.assertGreaterEqual(baked.count("\n"), len(chunks[k]))
                            self.assertEqual(rt, baked, f"{n} chunk {k}")
        print(f"\nruntime driver: {total} samples of {len(RUNTIME_EXAMPLES)} examples bit-identical to the "
              f"baked driver; {specials} fp special arguments; widths {sorted(widths, key=str)}", file=sys.stderr)
        self.assertGreaterEqual(len(RUNTIME_EXAMPLES), 10)
        for w in [("i", 1, False), ("i", 8, True), ("i", 8, False), ("i", 16, True), ("i", 16, False),
                  ("i", 32, True), ("i", 32, False), ("i", 64, True), ("i", 64, False), ("f", 32, True),
                  ("f", 64, True), ("f", 80, True), ("p",)]:
            self.assertIn(w, widths)
        self.assertGreater(specials, 0)


class Sampling(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["CQ_SAMPLES_CACHE"] = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def sample(self, n):
        spec = D.driver_spec(n, D.example_dir(n))
        ss = S.sample_set(spec, D.example_dir(n))
        self.assertEqual(S.check_sample_set(spec, ss), [])
        self.assertEqual(from_json(SampleSet, to_json(ss)), ss)
        return spec, ss

    def rows(self, ss):
        return {(r["site"].split(":")[0], r["row"]): r for r in ss.classes["totalization"]["rows"]}

    def test_divrem_rows(self):
        """cq-f075 (owner ruling, CLAUDE.md Domain): division by zero and INT_MIN / -1 are undefined
        in LLVM, so their rows are empty with that reason and no kept sample divides that way."""
        spec, ss = self.sample("11_int_divrem")
        rows = self.rows(ss)
        for fn, row in (("@sdiv_qc", "sdiv(a, 0)"), ("@sdiv_qc", "sdiv(INT_MIN, -1)"), ("@udiv_qc", "udiv(a, 0)"),
                        ("@srem_qc", "srem(INT_MIN, -1)"), ("@urem_qq", "urem(a, 0)")):
            self.assertIn("outside the domain", rows[(fn, row)].get("empty", ""), (fn, row))
        calls = {c["fn"]: i for i, c in enumerate(spec.calls)}
        for i, smp in enumerate(ss.samples):
            if i < len(spec.calls):
                continue
            a = smp["args"]
            if smp["call"] == calls.get("sdiv_qc", -1):
                self.assertNotEqual(a[2], "0x00000000", smp)
                self.assertFalse(a[0] == "0x80000000" and a[2] == "0xffffffff", smp)
        self.assertEqual(ss.classes["trips"]["loops"], [])
        self.assertIn("empty", ss.classes["trips"])
        # baselines first
        self.assertEqual(ss.samples[0], {"call": 0, "args": ["0x00000000", "0x3fe0000000000000", "0x00000003"]})

    def test_urem_by_zero_out_of_domain(self):
        """cq-f075, cq-hw1a: 76 param_bounded(x, th, t, n) reads t[x % n]; n = 0 is undefined in
        LLVM, so no kept sample of that call has n = 0 (the drivers.txt call has n = 4)."""
        spec, ss = self.sample("76_param_quantum_index")
        for i, smp in enumerate(ss.samples):
            if smp["call"] == 0 and i >= len(spec.calls):
                self.assertNotEqual(int(smp["args"][3], 16) & 0xffffffff, 0, smp)

    def test_exhaustive_and_edges(self):
        spec, ss = self.sample("12_int_widths")
        ex = ss.classes["exhaustive"]
        self.assertEqual(ex["0"]["bits"], 8)
        self.assertEqual(len(ex["0"]["samples"]), 256)
        # and_i1: two _Bool registers, each also substituted at its cq_theta (cq-lvkq): 2 + 2 bits
        self.assertEqual(len(ex["3"]["samples"]), 16)
        self.assertIn("empty", ex["1"])                       # 16 bits: past the 8-bit bound (cq-l1wi)
        self.assertIn("empty", ex["2"])                       # add_i64: 64 bits
        edge = {tuple(ss.samples[i]["args"][:1]) for i in ss.classes["edge"]["2"]["samples"]}
        self.assertTrue({("0x8000000000000000",), ("0x7fffffffffffffff",), ("0xffffffffffffffff",)} <= edge)
        self.assertIn("empty", ss.classes["specials"]["0"])

    def test_handle_cells_are_quantum_inputs(self):
        """cq-rbe6: 60's register array (int q[4] of cqrt_alloc_i1(0) handles) is a quantum input:
        exhaustive (with the cq_theta reaches) and edge over its 4 cells, and classical tuples crossed with random cell values."""
        spec, ss = self.sample("60_qft")
        cells = lambda i: tuple(D.split_ptr(ss.samples[i]["args"][0])[1] or ["0x0"] * 4)
        ex = ss.classes["exhaustive"]["0"]
        self.assertEqual(ex["bits"], 4 + 3)                  # the cells crossed with qft:0's 3 reaches
        self.assertEqual({cells(i) for i in ex["samples"]},
                         {tuple(f"0x{(n >> k) & 1:x}" for k in range(4)) for n in range(16)})
        self.assertEqual(len({cells(i) for i in ss.classes["edge"]["0"]["samples"]}), 16)
        rc = ss.classes["random_seed"]["classical"]["0"]["samples"]
        self.assertGreater(len({(ss.samples[i]["args"][1], cells(i)) for i in rc}),
                           len({ss.samples[i]["args"][1] for i in rc}))
        self.assertEqual(D.sample_record(spec, {"call": 0, "args": ["q@cells:0x1,0x0,0x1,0x1", "0x3", "0x0"]}),
                         "0 p71 0x1 0x0 0x1 0x1 0x3 0x0")

    def test_exhaustive_bound_is_8_bits(self):
        """cq-l1wi (owner decision): 8 quantum bits are exhaustive, 9 are not."""
        self.assertEqual(S.EXHAUSTIVE_BITS, 8)
        self.assertTrue(S.exhaustive_ok(8))
        self.assertFalse(S.exhaustive_ok(9))

    def test_bounds_and_full_mode_switch(self):
        """cq-kjja (owner ruling): 2048 random quantum and 64 classical samples per call by default;
        the full mode (16 bits, 16384 random) only under its own explicit switch, never CQ_FULL=1.
        Only the bounds are read here; nothing runs the full mode."""
        self.assertEqual((S.N_RANDOM_QUANTUM, S.N_RANDOM_CLASSICAL), (2048, 64))
        saved = {k: os.environ.pop(k, None) for k in ("CQ_FULL", S.FULL_MODE_ENV)}
        try:
            for env in ({}, {"CQ_FULL": "1"}, {S.FULL_MODE_ENV: "0"}, {S.FULL_MODE_ENV: "yes"}):
                os.environ.update(env)
                self.assertFalse(S.full_mode(), env)
                self.assertEqual((S.exhaustive_bits(), S.n_random_quantum()), (8, 2048), env)
                self.assertFalse(S.exhaustive_ok(9), env)
                for k in env:
                    del os.environ[k]
            os.environ[S.FULL_MODE_ENV] = "1"
            self.assertEqual((S.exhaustive_bits(), S.n_random_quantum()), (16, 16384))
            self.assertTrue(S.exhaustive_ok(16))
            self.assertFalse(S.exhaustive_ok(17))
        finally:
            os.environ.pop(S.FULL_MODE_ENV, None)
            os.environ.update({k: v for k, v in saved.items() if v is not None})

    def test_trips(self):
        spec, ss = self.sample("05_while_quantum_cond")
        (lp,) = ss.classes["trips"]["loops"]
        self.assertEqual(lp["loop"], "while_quantum_cond:%8")
        for t in ("0", "3", "4", "5"):
            self.assertIn("sample", lp["trips"][t], t)

    def test_trip_hit_reads_capped_records(self):
        """cq-ldo7: a quantum-exit loop the C oracle cuts at K has a capped T2 record and no trip
        event; it is the hit for every target above K, never for K or below."""
        rec = [{"loop": "f:%8", "act": 0, "n": 4, "capped": True, "cut": 3, "mcut": 0}]
        self.assertTrue(S.trip_hit([], rec, "f:%8", 5))
        self.assertTrue(S.trip_hit([], rec, "f:%8", 9))
        self.assertFalse(S.trip_hit([], rec, "f:%8", 4))
        self.assertFalse(S.trip_hit([], rec, "g:%8", 5))
        self.assertFalse(S.trip_hit([], [dict(rec[0], capped=False)], "f:%8", 5))
        self.assertTrue(S.trip_hit([{"ev": "trip", "loop": "f:%8", "n": 3}], [], "f:%8", 3))

    def test_quantum_bound_store_inside_cutoff(self):
        """cq-b19i: 55 stores a[i] for i <= m (m quantum) into int a[4]. Uncut, m >= 4 stores past
        a[3]; the C oracle cuts the quantum-exit loop at K = 4 (i = 0..3) and stops there, so every
        sample is in the domain, and the K+1 trip class is a capped sample."""
        n = "55_array_in_quantum_loop"
        spec, ss = self.sample(n)
        self.assertEqual(S.domain_problems(spec, D.example_dir(n), ss), [])
        (lp,) = ss.classes["trips"]["loops"]
        self.assertIn("sample", lp["trips"]["5"])

    def test_nonarg_registers(self):
        """cq-6m2 (cq-arch Z4): 113's registers are computed inside the program, so its quantum
        classes are cq_theta substitutions at the drivers.txt arguments."""
        spec, ss = self.sample("113_dicke4")
        for cls in ("edge",):
            e = ss.classes[cls]["0"]
            self.assertTrue(e["subst_sites"], e)
            self.assertTrue(all("subst" in ss.samples[i] for i in e["samples"]))
            self.assertTrue(all(ss.samples[i]["args"] == ss.samples[0]["args"] for i in e["samples"]))
        rq = ss.classes["random_seed"]["quantum"]["0"]
        self.assertGreater(len(rq["samples"]), 1)
        self.assertNotIn("subst", ss.samples[0])
        # every substituted value is a bit pattern of its site's width
        widths = D.theta_site_widths(D.o1_path("113_dicke4"))
        for smp in ss.samples:
            for k, v in (smp.get("subst") or {}).items():
                for x in (v if isinstance(v, list) else [v]):
                    self.assertLess(int(x, 16), 1 << {"i1": 1}.get(widths[k], 128), (k, x))

    def test_substitution_exhaustive_per_reach(self):
        """59: controlled_ry_two's three registers (one reach each) are exhaustive (8 samples);
        the chain's registers are listed per reach."""
        spec, ss = self.sample("59_controlled_ry_bits")
        ex = ss.classes["exhaustive"]["2"]
        self.assertEqual(ex["bits"], 3)
        subs = [ss.samples[i]["subst"] for i in ex["samples"]]
        self.assertEqual(len({json.dumps(x, sort_keys=True) for x in subs}), 8)
        self.assertEqual(sorted(subs[0]), ["controlled_ry_two:0", "controlled_ry_two:1", "controlled_ry_two:2"])
        ex1 = ss.classes["exhaustive"]["1"]
        self.assertEqual(ex1["reaches"]["controlled_ry_chain:0"], 4)      # n = 4
        self.assertEqual(len(ex1["samples"]), 1 << ex1["bits"])

    def test_substitution_where_the_baseline_misses_a_site(self):
        """cq-15cu: 125's cq_theta(&r, t) under x > k is not reached by the drivers.txt call (x0 = 0,
        k = 2); it is substituted on samples that reach it (an edge value beside x > k), and no
        site is reported unreached."""
        from cqcheck import oracle
        spec, ss = self.sample("125_mixed_phase_value_arm")
        site = "mixed_phase_value_arm:3"
        self.assertNotIn("unreached_sites", ss.classes["edge"]["0"])
        edge = [ss.samples[i] for i in ss.classes["edge"]["0"]["samples"]
                if site in ss.samples[i].get("subst", {})]
        o1 = sorted(D.example_dir("125_mixed_phase_value_arm").glob("*.O1.ll"))[0]
        reached = [any(e.get("ev") == "site" and f"{e['fn']}:{e['site']}" == site for e in r.events)
                   for r in oracle.run_samples(o1, spec, edge)]
        self.assertTrue(any(reached))

    def test_constant_offset_into_vla_is_checked(self):
        """cq-faa5: 59_controlled_ry_bits reads q[0] (a constant offset, no GEP) and q[n-1] of a
        VLA of n cells. Both are mem sites, classical, with no §2 rows, and n = 0 leaves the object
        at both, so no sample of the chain calls has n <= 0."""
        n = "59_controlled_ry_bits"
        spec = D.driver_spec(n, D.example_dir(n))
        ins = S.Instrumenter(D.read_module(D.o1_path(n)), spec)
        ins.rewrite()
        mem = {s.inst.split(" =")[0]: s for s in ins.sites if s.kind == "mem"}
        for v in ("%30", "%37"):
            self.assertIn(v, mem)
            self.assertTrue(mem[v].classical)
            self.assertFalse(S.rows_for(mem[v]))
        spec, ss = self.sample(n)
        for smp in ss.samples:
            if smp["call"] in (0, 1):
                v = int(smp["args"][1], 16)
                self.assertTrue(0 < v < 1 << 31, smp)

    def test_classical_access_past_object_is_out_of_domain(self):
        """cq-q9hd: 115_qaoa_ring reads x[eu[e]] at a classical index from a VLA of n cells. A
        sample with n below a vertex an edge names reads past the VLA: undefined in C, no CR §2
        row (that row is QROM/QRAM's), so the sampler must drop it (the reference then read a
        handle cell past its slot array and fed garbage to cq_template_icmp_eq_i1)."""
        n = "115_qaoa_ring"
        spec = D.driver_spec(n, D.example_dir(n))
        ins = S.Instrumenter(D.read_module(D.o1_path(n)), spec)
        ins.rewrite()
        mem = [s for s in ins.sites if s.kind == "mem"]
        self.assertTrue(mem and all(s.classical for s in mem))
        self.assertFalse(any(S.rows_for(s) for s in mem))
        # a quantum offset keeps its rows: 29's table load at a quantum index
        n29 = "29_table_quantum_index"
        ins29 = S.Instrumenter(D.read_module(D.o1_path(n29)), D.driver_spec(n29, D.example_dir(n29)))
        ins29.rewrite()
        (m29,) = [s for s in ins29.sites if s.kind == "mem"]
        self.assertFalse(m29.classical)
        self.assertEqual([r.row for r in S.rows_for(m29)], ["load index = n", "load index > n"])

        spec, ss = self.sample(n)
        edges = {"eu4": [0, 1, 2, 3], "ev4": [1, 2, 3, 0], "eu5": [0, 1, 2, 3], "ev5": [1, 2, 3, 4]}
        def s32(h):
            v = int(h, 16)
            return v - (1 << 32) if v >> 31 else v
        for smp in ss.samples:
            a = smp["args"]
            nv, ne, layers = s32(a[0]), s32(a[1]), s32(a[4])
            if ne <= 0 or layers <= 0:
                continue
            top = max(edges[a[2]][:ne] + edges[a[3]][:ne])
            self.assertLess(top, nv, smp)


_CALLEE_LL = """%struct.pair = type { i32, i32 }

define i32 @entry(i32 %0, double %1, i32 %2) {
  %4 = alloca [2 x %struct.pair], align 4
  %5 = tail call i32 @cq_theta_ui32(i32 %0, double %1)
  %6 = call i32 @leaf(ptr %4, i32 %2)
  %7 = call i32 @leaf2(ptr %4, i32 %5)
  %8 = call i32 @leaf2(ptr %4, i32 %2)
  %9 = getelementptr inbounds [2 x %struct.pair], ptr %4, i64 0, i64 1, i32 1
  %10 = load i32, ptr %9, align 4
  ret i32 %10
}

define internal i32 @leaf(ptr %0, i32 %1) {
  %3 = sext i32 %1 to i64
  %4 = getelementptr inbounds i32, ptr %0, i64 %3
  %5 = load i32, ptr %4, align 4
  ret i32 %5
}

define internal i32 @leaf2(ptr %0, i32 %1) {
  %3 = call i32 @leaf(ptr %0, i32 %1)
  ret i32 %3
}

declare i32 @cq_theta_ui32(i32, double)
"""


class ClassicalAddresses(unittest.TestCase):
    """cq-y10d: the out-of-object filter needs every classical address to be seen as classical."""

    def module(self, text):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        f = Path(d.name) / "m.ll"
        f.write_text(text)
        return D.read_module(f)

    @staticmethod
    def spec():
        return DriverSpec("t", [], "", [{"fn": "entry", "args": [
            {"ctype": "unsigned", "quantum": True}, {"ctype": "double", "quantum": False},
            {"ctype": "int", "quantum": False}]}])

    def test_type_names_are_not_operands(self):
        """Cause 1: a GEP over %struct.pair read the type name as an SSA operand with no def, so
        the address counted as quantum (129's guarded_field_store %28)."""
        m = self.module(_CALLEE_LL)
        self.assertEqual(m.types, {"%struct.pair"})
        f = m.functions["@entry"]
        self.assertEqual(f.defs["%9"].refs(), ["%4"])
        self.assertTrue(S.ClassicalValues(m, self.spec()).classical(f, "%9"))
        m129 = D.read_module(D.o1_path("129_quantum_ptr_select_store"))
        g = m129.functions["@guarded_field_store"]
        self.assertEqual(g.defs["%28"].refs(), ["%8", "%27"])

    def test_callee_pointer_param_fed_classical_addresses(self):
        """Cause 2: a parameter of a function the drivers do not call is classical when every call
        site passes a classical value (a greatest fixpoint: @leaf2 forwards to @leaf). A quantum
        value at one call site makes it quantum."""
        m = self.module(_CALLEE_LL)
        cv = S.ClassicalValues(m, self.spec())
        self.assertIn(("@leaf", 0), cv.cparams)            # ptr %4 at every site, also via @leaf2
        self.assertIn(("@leaf2", 0), cv.cparams)
        self.assertNotIn(("@leaf2", 1), cv.cparams)        # %5 = cq_theta at one site
        self.assertNotIn(("@leaf", 1), cv.cparams)         # through @leaf2's quantum %1
        self.assertNotIn(("@entry", 0), cv.cparams)        # a quantum driver argument
        self.assertTrue(cv.classical(m.functions["@leaf"], "%0"))
        self.assertFalse(cv.classical(m.functions["@leaf"], "%4"))
        # the pointee of such a parameter is not driver data: a load through it stays quantum
        self.assertFalse(cv.classical(m.functions["@leaf"], "%5"))
        # 52: @reduce(const double *in, ...) gets the caller's alloca; in[i] is a classical site
        n = "52_array_out_param"
        ins = S.Instrumenter(D.read_module(D.o1_path(n)), D.driver_spec(n, D.example_dir(n)))
        ins.rewrite()
        mem = {s.inst.split(" =")[0]: s for s in ins.sites if s.kind == "mem" and s.fn == "@reduce"}
        self.assertTrue(mem["%18"].classical)

    def test_address_through_integer_arithmetic(self):
        """cq-nqna: 107 reads *(int *)((uintptr_t)p + 4) with p = select(a, b + 1): the access is
        a mem site rooted at p, so b + 2 (one past b) is seen leaving b."""
        n = "107_pointer_int_union"
        ins = S.Instrumenter(D.read_module(D.o1_path(n)), D.driver_spec(n, D.example_dir(n)))
        f = ins.mod.functions["@union_ptr_to_int"]
        self.assertEqual(ins.addr_root(f, "%13"), ("%10", True))


class OutOfObject(unittest.TestCase):
    """cq-nqna (orchestrator decision): no sample of any class accesses outside an object."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        os.environ["CQ_SAMPLES_CACHE"] = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def test_quantum_index_past_object_dropped(self):
        """76 param_unbounded reads t[x] for an 8-bit quantum x from icoef[4]: x >= 4 is past the
        object. The exhaustive class keeps x in 0..3 and counts the other 252; the mem site's
        index >= n rows carry the domain reason."""
        n = "76_param_quantum_index"
        spec = D.driver_spec(n, D.example_dir(n))
        ss = S.sample_set(spec, D.example_dir(n))
        self.assertEqual(S.check_sample_set(spec, ss), [])
        ex = ss.classes["exhaustive"]["1"]
        self.assertEqual(ex["bits"], 8)
        self.assertEqual(ex["out_of_domain"], 252)
        self.assertEqual(sorted(int(ss.samples[i]["args"][0], 16) for i in ex["samples"]), [0, 1, 2, 3])
        for i, smp in enumerate(ss.samples):
            if smp["call"] == 1 and i >= len(spec.calls):
                self.assertLess(int(smp["args"][0], 16), 4, smp)
        mem_rows = [r for r in ss.classes["totalization"]["rows"] if "index" in r["row"]]
        self.assertTrue(mem_rows)
        for r in mem_rows:
            self.assertEqual(r["empty"], "cannot be hit: " + S.OUT_OF_OBJECT)
        # classical sites keep the cq-q9hd check (cq-y10d): 52 reads in[i] for i < n from tx[3]
        # (n <= 3, or n <= 0 and no read); 129 reads s[i].g from s[2] (0 <= i < 2)
        for n2, call, j, top, neg in (("52_array_out_param", 0, 4, 4, True),
                                      ("129_quantum_ptr_select_store", 1, 6, 2, False)):
            spec2 = D.driver_spec(n2, D.example_dir(n2))
            self.assertEqual(spec2.calls[call]["args"][j]["quantum"], False)
            ss2 = S.sample_set(spec2, D.example_dir(n2))
            for i, smp in enumerate(ss2.samples):
                if smp["call"] == call and i >= len(spec2.calls):
                    v = int(smp["args"][j], 16)
                    self.assertTrue(v < top or (neg and v >= 1 << 31), (n2, smp))

class ThetaSites(unittest.TestCase):
    """cq-6m2 (cq-arch Z4): the cq_theta site table that "subst" keys name."""

    def test_keys_and_widths_agree_with_the_oracle(self):
        from cqcheck import oracle
        for n in ("59_controlled_ry_bits", "60_qft", "12_int_widths", "185_qpe_quantum_angle", "116_shor15"):
            o1 = D.o1_path(n)
            want = {f"{fn}:{k}": oracle._SITE_RAIL[c[len("cq_theta_"):]]
                    for (fn, k), c in oracle.site_callees(o1).items() if c.startswith("cq_theta_")}
            self.assertEqual(D.theta_site_widths(o1), want, n)

    def test_substituted_sites(self):
        def subs(n):
            spec = D.driver_spec(n, D.example_dir(n))
            mod = D.read_module(D.o1_path(n))
            return [[st.key() for st in D.substituted_sites(mod, spec, ci)] for ci in range(len(spec.calls))]
        self.assertEqual(subs("59_controlled_ry_bits")[2],
                         ["controlled_ry_two:0", "controlled_ry_two:1", "controlled_ry_two:2"])
        self.assertEqual(subs("60_qft"), [["qft:0"]])        # the register array behind the q argument
        # cq-lvkq: a site fed by a varied argument is substituted too (CR §6 item 1, every cq_theta)
        self.assertTrue(all(len(s) >= 1 for s in subs("12_int_widths")))

    def test_reached_once_is_judged_over_the_plain_samples(self):
        """cq-obrq: a site fed by a varied argument, in a loop with one trip at the drivers.txt
        values, is reached more often by other plain samples: its reach count is the most over them
        too, so the caller's reached-once filter drops it. Its bases stay those of the probes (none)."""
        from types import SimpleNamespace as NS
        from unittest import mock
        from cqcheck import oracle
        spec = DriverSpec(example="t", protos=[], setup="",
                          calls=[{"fn": "f", "args": [{"ctype": "int", "quantum": True}]}])
        st = D.ThetaSite("f", 0, "i32", {("@f", 0)})
        fixed = D.ThetaSite("f", 1, "i32", set())

        def run(o1, spec, samples):
            out = []
            for sm in samples:
                n = int(sm["args"][0], 0)
                out.append(NS(failed=False, events=[{"ev": "site", "kind": "theta", "fn": "f", "site": 0}] * n
                              + [{"ev": "site", "kind": "theta", "fn": "f", "site": 1}] * n))
            return out
        g = NS(samples=[{"call": 0, "args": ["1"]}, {"call": 0, "args": ["3"]},
                        {"call": 0, "args": ["2"], "subst": {"f:0": "0x5"}}])
        with tempfile.TemporaryDirectory() as t:
            ex = Path(t) / "examples" / "t"
            ex.mkdir(parents=True)
            (ex / "t.O1.ll").write_text("")
            with mock.patch.object(D, "read_drivers_txt", return_value={"t": None}), \
                    mock.patch.object(D, "baseline_values", return_value=[["1"]]), \
                    mock.patch.object(oracle, "run_samples", side_effect=run):
                reaches, bases = S.theta_reaches(spec, ex, {0: [st, fixed]}, g)
                self.assertEqual(reaches[0]["f:0"], 3)
                self.assertEqual(reaches[0]["f:1"], 1)      # no varied argument: the probes decide
                self.assertEqual(bases[0], {})
                reaches, _ = S.theta_reaches(spec, ex, {0: [st, fixed]})   # no plain samples given
                self.assertEqual(reaches[0]["f:0"], 1)


# cq-ir5z: a synthetic example (its own examples/ and _tools/drivers.txt) for the probe's own stops
SYNTH_C = r"""
#define _FORTIFY_SOURCE 0
#include <string.h>
volatile int cqd_sink;
int fill(int n0, double th) {
    int n = n0;
    cq_theta(&n, th);
    unsigned char d[4] = {1, 2, 3, 4};
    memset(d, 7, (unsigned)n & 0xff);
    return cq_measure(d[0] + d[3]);
}
int spin(int n0, double th) {
    int n = n0;
    cq_theta(&n, th);
    while (n != 0) { n -= 2; cqd_sink = n; }
    return cq_measure(n);
}
"""
SYNTH_LINE = "900_probe_synth|int fill(int,double);int spin(int,double);|fill(1,.5);spin(2,.5)"
HALF = "0x3fe0000000000000"


def probe_obs(spec, example_dir, samples, env_pad):
    """The probe build's observations of `samples`, its server started with an environment of
    `env_pad` extra bytes (a different initial stack layout)."""
    saved = os.environ.get("CQD_PAD")
    os.environ["CQD_PAD"] = "x" * env_pad
    try:
        with tempfile.TemporaryDirectory() as t, S.ProbeBuild(spec, example_dir, Path(t)) as pb:
            return pb.run(samples)
    finally:
        if saved is None:
            os.environ.pop("CQD_PAD", None)
        else:
            os.environ["CQD_PAD"] = saved


def obs_key(o):
    return (o.ran, o.end, o.code, o.hdrs, sorted(o.oob), sorted(o.t.items()), sorted(o.m.items()),
            sorted(o.p.items()))


class ProbeDeterminism(unittest.TestCase):
    """cq-ir5z: every probe observation is a function of the input only. An access outside its
    object ends the sample at the access (end "oob", the header count there), before it lands;
    nontermination is the header budget; no wall-clock limit decides a sample."""

    def test_threads_collapse(self):
        """cq-nfv3: 106 creates two threads. The probe collapses them as the C oracle does (CR rule
        24: pthread_create runs the routine to completion), so the same batch observed twice gives
        the same observations; with real threads they raced on the probe's buffer and counters."""
        n = "106_fork_join"
        spec = D.driver_spec(n, D.example_dir(n))
        keys = [{"call": 0, "args": [f"0x{x:08x}", "0x3fe0000000000000", "0x00000003"]}
                for x in (0, 1, 2, 5, 7, 100, 0x7fff)]
        def observe():
            with tempfile.TemporaryDirectory() as t, S.ProbeBuild(spec, D.example_dir(n), Path(t)) as pb:
                return [(o.end, o.returned, sorted(o.p.items()), sorted(o.m.items())) for o in pb.run(keys)]
        self.assertEqual(observe(), observe())

    def test_store_past_object_stops_at_the_access(self):
        """55 stores a[i] for i <= m into int a[4]. Before cq-ir5z the probe performed the stores up
        its sample stack: the run ended at whatever page lay above it (signal 11 after 3109 trips) or
        overwrote the probe's own state (a lost sample), depending on the memory layout. Now every
        m >= 4 ends at the a[4] store after 5 header executions, whatever the environment size."""
        n = "55_array_in_quantum_loop"
        spec = D.driver_spec(n, D.example_dir(n))
        ms = [3, 4, 5, 6, 0xc, 0xf, 100, 3109, 0x7fffffff]
        smp = [{"call": 0, "args": [f"0x{m:08x}", HALF, f"0x{c:08x}"]} for m in ms for c in (0, 1, 3, 0x7fffffff)]
        runs = [[obs_key(o) for o in probe_obs(spec, D.example_dir(n), smp, pad)] for pad in (1, 4093, 250000)]
        self.assertEqual(runs[0], runs[1])
        self.assertEqual(runs[0], runs[2])
        obs = probe_obs(spec, D.example_dir(n), smp, 1)
        store = set()
        for s, o in zip(smp, obs):
            m = int(s["args"][0], 16)
            self.assertTrue(o.ran, s)
            if m == 3:
                self.assertEqual((o.end, o.oob), ("exit", set()), s)
                continue
            self.assertEqual(o.end, "oob", s)
            self.assertEqual(o.hdrs, 5, s)
            self.assertEqual(len(o.oob), 1, s)
            store |= o.oob
        self.assertEqual(len(store), 1)
        self.assertEqual(obs[-1].code, next(iter(store)))

    def test_intrinsic_past_object_and_budget(self):
        """A memset past its destination ends the sample before it writes (end "oob", site -1); a
        loop that does not end runs HDR_CAP header executions and ends as "timeout"."""
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            ex = t / "examples" / "900_probe_synth"
            ex.mkdir(parents=True)
            (t / "_tools").mkdir()
            (t / "_tools" / "drivers.txt").write_text(SYNTH_LINE + "\n")
            (t / "s.c").write_text(SYNTH_C)
            subprocess.run([CLANG, "-w", "-O1", "-S", "-emit-llvm", "-target", "x86_64-apple-macosx",
                            "-include", str(D.spec_dir() / "CQ.h"), str(t / "s.c"),
                            "-o", str(ex / "probe_synth.O1.ll")], check=True)
            spec = D.driver_spec("900_probe_synth", ex)
            smp = [{"call": 0, "args": ["0x00000004", HALF]}, {"call": 0, "args": ["0x00000005", HALF]},
                   {"call": 0, "args": ["0x000000c8", HALF]}, {"call": 1, "args": ["0x00000006", HALF]},
                   {"call": 1, "args": ["0x00000007", HALF]}]
            a = probe_obs(spec, ex, smp, 1)
            b = probe_obs(spec, ex, smp, 250000)
        self.assertEqual([obs_key(o) for o in a], [obs_key(o) for o in b])
        self.assertEqual([o.end for o in a], ["exit", "oob", "oob", "exit", "timeout"])
        self.assertEqual(a[1].oob, {-1})
        self.assertEqual(a[1].hdrs, 0)
        self.assertEqual(a[4].hdrs, S.HDR_CAP + 1)

    def test_no_wall_clock_outcome(self):
        """The runtime has no per-sample wall-clock timer; the CPU-time hang guard and the server's
        no-output guard raise ProbeError, never a sample outcome."""
        self.assertNotIn("ITIMER_REAL", S.RUNTIME_C)
        self.assertIn("ITIMER_PROF", S.RUNTIME_C)
        self.assertFalse(hasattr(S, "PER_SAMPLE_MS"))
        self.assertTrue(issubclass(S.ProbeError, RuntimeError))


if __name__ == "__main__":
    unittest.main(verbosity=2)
