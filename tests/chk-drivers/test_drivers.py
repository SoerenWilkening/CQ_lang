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


class TripDomainProof(unittest.TestCase):
    """cq-oou2: a trip target the search left empty is filled by a constructed input inside the
    domain, proved impossible by constructed inputs that reach it only outside the domain, or stays
    missing (a count reached only with the K cutoff off included). Synthetic oracle runs; no example
    is run."""

    class Run:
        def __init__(self, n=None, loop="f:%8", notes=(), outcome="ret", failed=False, capped=None, reason=""):
            self.events = [] if n is None else [{"ev": "trip", "loop": loop, "n": n}]
            self.loops = [] if capped is None else [{"loop": capped, "n": S.K, "capped": True}]
            self.notes, self.outcome, self.failed, self.reason = list(notes), outcome, failed, reason

    def obs(self, end="exit", oob=(), cap_ok=False):
        o = S.Obs()
        o.end, o.oob, o.cap_ok = end, set(oob), cap_ok
        return o

    def proof(self, t, kruns, obs=None):
        n = len(kruns)
        cands = [(0, (hex(i),)) for i in range(n)]
        return S.trip_proof("f:%8", t, cands, kruns, obs or [self.obs() for _ in range(n)],
                            lambda o: S._valid(o, {}), {})

    def test_reached_only_past_an_object_is_out_of_domain(self):
        k = [self.Run(3), self.Run(5, notes=["oob-load"]), self.Run(5, notes=["oob-store"])]
        kind, i, why = self.proof(5, k, obs=[self.obs(), self.obs("oob", {2}), self.obs("oob", {2})])
        self.assertEqual((kind, i), ("ub", 1))
        self.assertIn("outside the domain", why)
        self.assertIn("oob-load", why)
        from cqcheck import gaps
        self.assertEqual(gaps.classify_reason(why), gaps.IMPOSSIBLE)

    def test_a_clean_reach_is_a_sample_never_a_proof(self):
        k = [self.Run(5, notes=["oob-load"]), self.Run(5)]
        self.assertEqual(self.proof(5, k)[:2], ("found", 1))

    def test_crash_after_the_count_is_undefined(self):
        # a crash note (the trap of a division by zero) is undefined; the oracle reached the count first
        k = [self.Run(0, notes=["crash 8 addr=0x0"], failed=True, reason="crash 8")]
        self.assertEqual(self.proof(0, k)[0], "ub")

    def test_nothing_reaches_it_stays_missing(self):
        kind, i, why = self.proof(5, [self.Run(3), self.Run(4, notes=["oob-load"])])
        self.assertEqual((kind, i), ("missing", None))
        self.assertIn("none of 2 constructed inputs", why)
        from cqcheck import gaps
        self.assertEqual(gaps.classify_reason("no input found: x; " + why), gaps.MISSING)

    def test_a_nonterminating_reach_blocks_the_proof(self):
        k = [self.Run(5, notes=["oob-load"]), self.Run(5, notes=["tripcap"], failed=True, reason="nonterminating")]
        kind, _, why = self.proof(5, k)
        self.assertEqual(kind, "missing")
        self.assertIn("neither inside the domain nor undefined", why)

    def test_an_access_past_the_cutoff_is_inside_the_domain(self):
        # cq-b19i: the probe left the object, the oracle cut at K first (cap_ok): in the domain, so a
        # sample, never a witness
        k = [self.Run(None, outcome="cap:f:%8", capped="f:%8")]
        kind, i, _ = self.proof(5, k, obs=[self.obs("oob", {1}, cap_ok=True)])
        self.assertEqual((kind, i), ("found", 0))

    def test_cut_first_is_no_proof(self):
        # 68's shape: at K the inner loop f:%9 is cut before f:%8 runs 5 trips. That the constructed
        # inputs end there is evidence, not a proof (orchestrator decision on cq-oou2): MISSING
        k = [self.Run(None, outcome="cap:f:%9", capped="f:%9"), self.Run(2)]
        kind, i, why = self.proof(5, k)
        self.assertEqual((kind, i), ("missing", None))
        from cqcheck import gaps
        self.assertEqual(gaps.classify_reason("no input found: x; " + why), gaps.MISSING)

    def test_an_undefined_access_before_the_budget_is_a_witness(self):
        # a classical loop over a large bound runs past the construction's step budget, after the
        # access past the object the oracle noted
        k = [self.Run(5, notes=["oob-load", "tripcap"], failed=True, reason="tripcap")]
        self.assertEqual(self.proof(5, k)[0], "ub")
        # past the budget with no such note: no witness either way
        k = [self.Run(5, notes=["tripcap"], failed=True, reason="tripcap")]
        self.assertEqual(self.proof(5, k)[0], "missing")

    def test_exhaustive_inputs(self):
        # cq-oou2: 87's call takes an 8-bit quantum char and an angle: 256 inputs enumerate it
        from cqcheck import drivers as D2
        ex_dir = D2.example_dir("87_pointer_induction")
        spec = D2.driver_spec("87_pointer_induction", ex_dir)
        g = S.Gen(spec, [["0x00", "0x3fe0000000000000"]])
        o1 = sorted(ex_dir.glob("*.O1.ll"))[0].read_text()
        ins = S.exhaustive_inputs(g, o1)
        self.assertEqual(len(ins), 256)
        self.assertEqual(ins[5], (0, ("0x05", "0x3fe0000000000000")))
        # an angle read as data, or a wider quantum input: no enumeration
        self.assertIn("  ret i32", o1)
        self.assertIsNone(S.exhaustive_inputs(g, o1.replace("  ret i32", "  %99 = fadd double %1, %1\n  ret i32", 1)))
        ex_dir = D2.example_dir("152_phase_in_kloop")
        spec = D2.driver_spec("152_phase_in_kloop", ex_dir)
        g = S.Gen(spec, [["0x00000000", "0x3fe0000000000000", "0x00000001", "0x3fd3333333333333", "0x3fe6666666666666"]])
        self.assertIsNone(S.exhaustive_inputs(g, sorted(ex_dir.glob("*.O1.ll"))[0].read_text()))

    def test_construct_values(self):
        ct = D.parse_ctype("int")
        v = S.trip_construct_values(ct, 3)
        for x in (0, 1, 4, 5, 6, 0x10000, 0xffffffff, 0x80000000, 0x7fffffff):
            self.assertIn(x, v)


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

    def test_dropped_entries_name_their_reason(self):
        """cq-krfj: an entry emptied by drop_out_of_domain names why its samples left the domain: an
        LLVM-undefined operation is not an access outside an object."""
        from types import SimpleNamespace as NS
        from unittest import mock
        oob = S.Obs(ran=True, end="oob", oob={3})
        ub = S.Obs(ran=True, end="exit")
        ok = S.Obs(ran=True, end="exit")
        is_ub = lambda o, rows: o is ub      # noqa: E731
        with mock.patch.object(S, "_ub", side_effect=is_ub):
            self.assertEqual(S.domain_reason(oob, {}), S.OOB_REASON)
            self.assertEqual(S.domain_reason(ub, {}), S.UB_REASON)
            self.assertIsNone(S.domain_reason(ok, {}))
            obs = [ok, ub, ub, oob, ok]
            g = NS(spec=NS(calls=[{}]), samples=[{"call": 0, "args": [str(i)]} for i in range(5)])
            se = NS(rows_by_site={}, observe=lambda cands: obs)
            pc = {"edge": {"0": {"samples": [1, 2]}}, "specials": {"0": {"samples": [1, 3]}},
                  "rq": {"0": {"samples": [3, 4]}}}
            S.drop_out_of_domain(g, pc, se)
        self.assertEqual(len(g.samples), 2)
        self.assertEqual(pc["edge"]["0"]["out_of_domain"], 2)
        self.assertIn("2 " + S.UB_REASON, pc["edge"]["0"]["empty"])
        self.assertNotIn("outside an object", pc["edge"]["0"]["empty"])
        self.assertIn("1 " + S.UB_REASON, pc["specials"]["0"]["empty"])
        self.assertIn("1 " + S.OOB_REASON, pc["specials"]["0"]["empty"])
        self.assertEqual(pc["rq"]["0"], {"samples": [1], "out_of_domain": 1})

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


# cq-z8gj: uninitialized stack and heap reads (observed by the division's operands), and the C
# library's string and memory functions
SYNTH2_C = r"""
#define _FORTIFY_SOURCE 0
#include <string.h>
/* deep below the caller's frame, past what the probe runtime's own calls write in the sample */
__attribute__((noinline)) static int stk(int w) { volatile int u[8192]; if (w) u[0] = 41; return u[0]; }
int ustack(int n0, double th) {
    int n = n0;
    cq_theta(&n, th);
    int v = stk(n & 1);
    return cq_measure(100 / (v + 1));
}
int scpy(int n0, double th) {
    int n = n0;
    cq_theta(&n, th);
    char s[16];
    memset(s, 'a', 15);
    s[15] = 0;
    s[n & 15] = 0;
    char d[4];
    strcpy(d, s);
    return cq_measure(((volatile char *)d)[0]);
}
int mcmp(int n0, double th) {
    int n = n0;
    cq_theta(&n, th);
    char a[4] = {1, 2, 3, 4};
    char b[16] = {0};
    return cq_measure(memcmp(a, b, (unsigned)n & 15));
}
"""
SYNTH2_LINE = ("901_probe_synth2|int ustack(int,double);int scpy(int,double);int mcmp(int,double);"
               "|ustack(1,.5);scpy(2,.5);mcmp(3,.5)")
SYNTH3_C = r"""
#include <stdlib.h>
int uheap(int n0, double th) {
    int n = n0;
    cq_theta(&n, th);
    volatile int *p = malloc(256);       /* p[40]: past what the allocator writes into a free block */
    if (n & 1) p[40] = 41;
    int v = p[40];
    free((void *)p);
    return cq_measure(100 / (v + 1));
}
"""
SYNTH3_LINE = "902_probe_synth3|int uheap(int,double);|uheap(1,.5)"


def synth_example(t, name, c_text, line):
    """A synthetic example under t (its own examples/ and _tools/drivers.txt): its directory."""
    ex = t / "examples" / name
    ex.mkdir(parents=True)
    (t / "_tools").mkdir()
    (t / "_tools" / "drivers.txt").write_text(line + "\n")
    (t / "s.c").write_text(c_text)
    subprocess.run([CLANG, "-w", "-O1", "-S", "-emit-llvm", "-target", "x86_64-apple-macosx",
                    "-include", str(D.spec_dir() / "CQ.h"), str(t / "s.c"),
                    "-o", str(ex / (name.split("_", 1)[1] + ".O1.ll"))], check=True)
    return ex


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


_LIST_LL = """target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

define i32 @f(i32 %0, i32 %1) {
  %3 = call noalias ptr @malloc(i64 16)
  %4 = call noalias ptr @malloc(i64 16)
  %5 = call noalias ptr @malloc(i64 16)
  store i32 %0, ptr %5
  %6 = getelementptr inbounds i8, ptr %5, i64 8
  store ptr %4, ptr %6
  store i32 3, ptr %4
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  store ptr %3, ptr %7
  store i32 7, ptr %3
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store ptr null, ptr %8
  br label %9

9:
  %10 = phi ptr [ %5, %2 ], [ %17, %14 ]
  %11 = phi i32 [ 0, %2 ], [ %15, %14 ]
  %12 = load i32, ptr %10
  %13 = icmp eq i32 %12, %1
  br i1 %13, label %19, label %14

14:
  %15 = add i32 %11, 1
  %16 = getelementptr inbounds i8, ptr %10, i64 8
  %17 = load ptr, ptr %16
  %18 = icmp eq ptr %17, null
  br i1 %18, label %19, label %9

19:
  %20 = phi i32 [ -1, %14 ], [ %11, %9 ]
  ret i32 %20
}

declare noalias ptr @malloc(i64)
"""


class StructureProof(unittest.TestCase):
    """cq-97oj kind 3 (cq-fhoc, cq-w2a-chk-trips): TripFacts.cpp's finite-structure proof. A loop that
    follows a next pointer loaded from its loop-carried pointer, writes no memory and leaves on null
    runs at most n header executions when the last stores before it chain the entry pointer through n
    distinct pointers to null. Each mutant breaks one premise and must prove nothing (a wrong proof
    would turn a reachable trip target into IMPOSSIBLE)."""

    def facts(self, text):
        from cqcheck import gaps
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        f = Path(d.name) / "m.O1.ll"
        f.write_text(text)
        r = subprocess.run([str(S.LLVM_BIN / "opt"), "-passes=verify", "-disable-output", str(f)],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        return {t: why for t, why in gaps.trip_facts(f, S.LLVM_BIN, S.K + 1).get("f:%9", {}).items()
                if "finite-structure" in why}

    @staticmethod
    def mutate(old, new):
        assert _LIST_LL.count(old) == 1, old
        return _LIST_LL.replace(old, new)

    def test_three_nodes(self):
        g = self.facts(_LIST_LL)
        self.assertEqual(sorted(g), [4, 5])
        self.assertIn("%5 -> %4", g[4])
        self.assertIn("3 pointers, then null", g[4])

    def test_189(self):
        from cqcheck import gaps
        o1 = sorted(D.example_dir("189_heap_linked_list").glob("*.O1.ll"))[0]
        g = gaps.trip_facts(o1, S.LLVM_BIN, S.K + 1).get("list_search:%14", {})
        self.assertEqual(sorted(g), [4, 5])
        self.assertTrue(all("finite-structure" in w for w in g.values()))

    def test_four_nodes_bound_four(self):
        text = self.mutate("  store ptr null, ptr %8\n",
                           "  store ptr %n4, ptr %8\n  store i32 9, ptr %n4\n"
                           "  %n4n = getelementptr inbounds i8, ptr %n4, i64 8\n  store ptr null, ptr %n4n\n")
        g = self.facts(text.replace("  store i32 %0, ptr %5\n",
                                    "  %n4 = call noalias ptr @malloc(i64 16)\n  store i32 %0, ptr %5\n"))
        self.assertEqual(sorted(g), [5])

    def test_cycle_proves_nothing(self):
        self.assertEqual(self.facts(self.mutate("  store ptr null, ptr %8\n", "  store ptr %5, ptr %8\n")), {})

    def test_input_dependent_next_proves_nothing(self):
        self.assertEqual(self.facts(self.mutate(
            "  store ptr %4, ptr %6\n",
            "  %c = icmp eq i32 %0, 0\n  %s = select i1 %c, ptr %4, ptr %5\n  store ptr %s, ptr %6\n")), {})

    def test_store_in_the_loop_proves_nothing(self):
        self.assertEqual(self.facts(self.mutate("  %15 = add i32 %11, 1\n",
                                                "  %15 = add i32 %11, 1\n  store ptr %10, ptr %8\n")), {})

    def test_conditional_next_store_proves_nothing(self):
        # c->next = a on one path only: the last write before the loop is a MemoryPhi
        self.assertEqual(self.facts(self.mutate(
            "  store ptr null, ptr %8\n  br label %9\n",
            "  store ptr null, ptr %8\n  %c = icmp eq i32 %0, 0\n  br i1 %c, label %cy, label %jn\n\n"
            "cy:\n  store ptr %5, ptr %8\n  br label %jn\n\njn:\n  br label %9\n").replace("[ %5, %2 ]", "[ %5, %jn ]").replace("[ 0, %2 ]", "[ 0, %jn ]")), {})


# cq-s8cf, cq-x9cz: zero-size allocas, natively (count 0 or a zero-size element type)
ZSYNTH_C = r"""
#include <string.h>
/* a zero-byte alloca per iteration, no stack restore (991) */
int loopalloca(int n, int m) {
    int s = 0;
    for (int i = 0; i < m; i++) {
        volatile char *p = __builtin_alloca(n);
        if (n > 0) { p[0] = (char)i; s += p[0]; }
    }
    return s + m;
}
/* 9 MB of rows when n > 0; with n = 0 they take no stack, and fill's 1 MB frame fits (993) */
__attribute__((noinline)) static int fill(int k) {
    char buf[1 << 20];
    memset(buf, k, sizeof buf);
    return buf[k & 1023];
}
int big0f(int n, int k) {
    volatile char a[n][3 << 20];
    volatile char b[n][3 << 20];
    volatile char c[n][3 << 20];
    if (n > 0) { a[0][0] = k; b[0][0] = k; c[0][0] = k; return a[0][0] + b[0][0] + c[0][0]; }
    return fill(k);
}
/* x[0] lies at c's base when nq = 0 (994) */
__attribute__((noinline)) static int rd(volatile char *p, int i) { return p[i]; }
int z(int t, int nq, int mode) {
    volatile char c[t], x[nq];
    memset((char *)c, 0, t);
    if (mode == 1) x[0] = 1;
    if (mode == 2) return rd(x, 0);
    if (mode == 3) return rd(c, t);
    if (mode == 4) return rd(x, -1);
    if (mode == 5) return rd(c, 0);
    return c[0] + t;
}
"""
ZSYNTH_LINE = ("903_probe_zero|int loopalloca(int,int);int big0f(int,int);int z(int,int,int);"
               "|loopalloca(0,4);big0f(0,1);z(4,0,0)")
# a dynamic alloca of a zero-size element type (995, cq-x9cz; IR only: clang makes C's char e[n][0] a
# static [0 x i8]) after a VLA
ZE_LL = """target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

define i32 @ze(i32 %0, i32 %1, i32 %2) {
  %4 = zext i32 %0 to i64
  %5 = alloca i8, i64 %4, align 16
  %6 = zext i32 %1 to i64
  %7 = alloca [0 x i8], i64 %6, align 16
  %8 = sext i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr align 16 %5, i8 0, i64 %8, i1 false)
  %9 = icmp eq i32 %2, 1
  br i1 %9, label %10, label %12

10:
  %11 = getelementptr inbounds i8, ptr %7, i64 0
  store volatile i8 1, ptr %11, align 1
  br label %12

12:
  %13 = load volatile i8, ptr %5, align 16
  %14 = sext i8 %13 to i32
  ret i32 %14
}

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
"""
ZE_LINE = "904_probe_ze|int ze(int,int,int);|ze(4,1,0)"


class ZeroByteAlloca(unittest.TestCase):
    """cq-w2a-chk-trips, cq-s8cf, cq-x9cz: a zero-size alloca takes no stack, so it lies at the base
    of the object allocated before it (117 with nq = 0: bool x[0] after c[t]). The probe's object
    table once let it replace that object (117 ended as oob at the memset of c); then the probe gave
    it one element, which moved the stack (9 MB for 993's rows) and grew the table without bound in
    a loop (991: the hang guard). Now the native allocation is unchanged and the zero-size object
    coexists with the one at its address; an access names its object by its root's alloca, else
    the object registered last there. An access to the zero-size object still leaves it."""

    @staticmethod
    def synth(name, line, samples, c_text=None, ll_text=None):
        """The probe observations of `samples` on a synthetic example from C or from IR."""
        with tempfile.TemporaryDirectory() as d:
            t = Path(d)
            if c_text is not None:
                ex = synth_example(t, name, c_text, line)
            else:
                ex = t / "examples" / name
                ex.mkdir(parents=True)
                (t / "_tools").mkdir()
                (t / "_tools" / "drivers.txt").write_text(line + "\n")
                (ex / (name.split("_", 1)[1] + ".O1.ll")).write_text(ll_text)
            with S.ProbeBuild(D.driver_spec(name, ex), ex, t / "work") as pb:
                return pb.run(samples)

    @staticmethod
    def smp(call, *xs):
        return {"call": call, "args": [f"0x{x & 0xffffffff:08x}" for x in xs]}

    def test_zero_size_allocas(self):
        """991: 100000 zero-byte allocas in one activation (the one-element probe build filled the
        object table and hit the hang guard). 993: with n = 0 the 9 MB of rows take no stack, so
        fill's 1 MB frame fits the 8 MB sample stack (one element per row moved the stack 9 MB).
        994 (x[0] at c's base when nq = 0): c is c, through its own alloca and through a callee;
        x[0] is past x, through x's alloca and through a callee; so are c[t] and x[-1]."""
        smp = self.smp
        cases = [(smp(0, 0, 100000), "exit"), (smp(0, 2, 16), "exit"), (smp(1, 0, 1), "exit"),
                 (smp(2, 4, 0, 0), "exit"), (smp(2, 4, 0, 5), "exit"), (smp(2, 4, 2, 2), "exit"),
                 (smp(2, 4, 0, 1), "oob"), (smp(2, 4, 0, 2), "oob"), (smp(2, 4, 0, 3), "oob"),
                 (smp(2, 4, 0, 4), "oob")]
        obs = self.synth("903_probe_zero", ZSYNTH_LINE, [c for c, _ in cases], c_text=ZSYNTH_C)
        for (c, end), o in zip(cases, obs):
            self.assertTrue(o.ran, c)
            self.assertEqual(o.end, end, c)
            if end == "exit":
                self.assertEqual(o.oob, set(), c)
                self.assertTrue(S._in_domain(o), c)

    def test_zero_size_element_type(self):
        """cq-x9cz (995): [0 x i8] x n after c[t] is a zero-size object at c's base: the memset of
        c stays inside c; a store to its byte 0 (c[0]'s address) leaves the zero-size object."""
        smp = self.smp
        obs = self.synth("904_probe_ze", ZE_LINE, [smp(0, 4, 1, 0), smp(0, 4, 0, 0), smp(0, 4, 3, 1)],
                         ll_text=ZE_LL)
        self.assertEqual([(o.end, o.oob) for o in obs[:2]], [("exit", set())] * 2)
        self.assertEqual(obs[2].end, "oob")

    def probe(self, o1_text, samples):
        n = "117_qpe_counting"
        spec = D.driver_spec(n, D.example_dir(n))
        with tempfile.TemporaryDirectory() as t:
            ex = Path(t) / "examples" / n
            ex.mkdir(parents=True)
            (Path(t) / "_tools").mkdir()
            o1 = sorted(D.example_dir(n).glob("*.O1.ll"))[0]
            (Path(t) / "_tools" / "drivers.txt").symlink_to(o1.resolve().parents[2] / "_tools" / "drivers.txt")
            (ex / o1.name).write_text(o1_text or o1.read_text())
            with S.ProbeBuild(spec, ex, Path(t) / "work") as pb:
                return pb.run(samples)

    def test_zero_byte_vla_beside_another(self):
        smp = [{"call": 0, "args": ["0x00000000", "0x00000004", "mk1", "0x00000002"]}]
        (o,) = self.probe(None, smp)
        self.assertEqual((o.end, o.oob), ("exit", set()))

    def test_access_to_the_zero_byte_vla_still_leaves_it(self):
        # mutant: the memset of x runs for nq = 0 too, one byte: x[0] of bool x[0], outside its object
        o1 = sorted(D.example_dir("117_qpe_counting").glob("*.O1.ll"))[0].read_text()
        for old, new in (("  %13 = icmp sgt i32 %0, 0\n", "  %13 = icmp sgt i32 %0, -1\n"),
                         ("  %15 = zext nneg i32 %0 to i64\n", "  %15 = add i64 %7, 1\n")):
            self.assertEqual(o1.count(old), 1, old)
            o1 = o1.replace(old, new)
        smp = [{"call": 0, "args": ["0x00000000", "0x00000004", "mk1", "0x00000002"]}]
        (o,) = self.probe(o1, smp)
        self.assertEqual(o.end, "oob")


BYVAL_LL = """target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@g = global [4 x i8] zeroinitializer, align 1

define internal x86_fp80 @rd(ptr byval({ x86_fp80, x86_fp80 }) align 16 %0, i32 %1) noinline {
  %3 = sext i32 %1 to i64
  %4 = getelementptr x86_fp80, ptr %0, i64 %3
  %5 = load x86_fp80, ptr %4, align 16
  ret x86_fp80 %5
}

define x86_fp80 @bv(x86_fp80 %0, x86_fp80 %1, i32 %2) {
  %4 = alloca { x86_fp80, x86_fp80 }, align 16
  store x86_fp80 %0, ptr %4, align 16
  %5 = getelementptr inbounds i8, ptr %4, i64 16
  store x86_fp80 %1, ptr %5, align 16
  store i8 1, ptr @g, align 1
  %6 = call x86_fp80 @rd(ptr byval({ x86_fp80, x86_fp80 }) align 16 %4, i32 %2)
  ret x86_fp80 %6
}
"""
BYVAL_LINE = "906_probe_byval|long double bv(long double,long double,int);|bv(1,2,0)"


class ByvalCopy(unittest.TestCase):
    """cq-0jq1: a byval parameter points at the callee's own copy of the argument (long double
    _Complex, the libc sweep's cabsl and the other *l complex functions), at an address no object of
    the caller has. The probe once read it through the caller's provenance and found the object
    below it (a global), so every sample was outside the domain; it is an object of the callee's
    frame, checked like an alloca: inside it the access is in the domain, past it is not."""

    def test_byval_copy_is_an_object(self):
        one, two = "0x3fff8000000000000000", "0x40008000000000000000"
        smp = [{"call": 0, "args": [one, two, f"0x{i & 0xffffffff:08x}"]} for i in (0, 1, 2, -1)]
        obs = ZeroByteAlloca.synth("906_probe_byval", BYVAL_LINE, smp, ll_text=BYVAL_LL)
        self.assertEqual([(o.ran, o.end, o.oob) for o in obs[:2]], [(True, "exit", set())] * 2)
        for o in obs[:2]:
            self.assertTrue(S._in_domain(o))
        self.assertEqual([o.end for o in obs[2:]], ["oob", "oob"])
        for o in obs[2:]:
            self.assertFalse(S._in_domain(o))

    def test_byval_type(self):
        self.assertEqual(S.Instrumenter.byval_type(
            "ptr nocapture noundef readonly byval({ x86_fp80, x86_fp80 }) align 16 %0"), "{ x86_fp80, x86_fp80 }")
        self.assertEqual(S.Instrumenter.byval_type("ptr noundef byval(%struct.S) align 8 %1"), "%struct.S")
        self.assertIsNone(S.Instrumenter.byval_type("ptr noundef %0"))


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

    def test_residue_and_library_ranges(self):
        """cq-z8gj: an uninitialized stack read sees the same bytes whatever sample ran before it in
        the worker (a fresh sample stack); so does an uninitialized heap read (a module that
        allocates runs each sample in a worker of its own); strcpy and memcmp past their objects end
        the sample before the call as "oob" (site -1), as a memory intrinsic does."""
        odd, even = ["0x00000001", HALF], ["0x00000002", HALF]
        with tempfile.TemporaryDirectory() as t:
            ex = synth_example(Path(t), "901_probe_synth2", SYNTH2_C, SYNTH2_LINE)
            spec = D.driver_spec("901_probe_synth2", ex)
            both = probe_obs(spec, ex, [{"call": 0, "args": odd}, {"call": 0, "args": even}], 1)
            alone = probe_obs(spec, ex, [{"call": 0, "args": even}], 1)
            lib = probe_obs(spec, ex, [{"call": 1, "args": ["0x00000002", HALF]},
                                       {"call": 1, "args": ["0x00000009", HALF]},
                                       {"call": 2, "args": ["0x00000003", HALF]},
                                       {"call": 2, "args": ["0x00000008", HALF]}], 1)
            ex3 = synth_example(Path(t) / "h", "902_probe_synth3", SYNTH3_C, SYNTH3_LINE)
            spec3 = D.driver_spec("902_probe_synth3", ex3)
            hboth = probe_obs(spec3, ex3, [{"call": 0, "args": odd}, {"call": 0, "args": even}], 1)
            halone = probe_obs(spec3, ex3, [{"call": 0, "args": even}], 1)
        self.assertEqual(obs_key(both[1]), obs_key(alone[0]))
        self.assertEqual(obs_key(hboth[1]), obs_key(halone[0]))
        self.assertNotEqual(obs_key(both[0]), obs_key(both[1]))       # the odd sample did write 41
        self.assertEqual([o.end for o in lib], ["exit", "oob", "exit", "oob"])
        self.assertEqual((lib[1].oob, lib[3].oob), ({-1}, {-1}))

    def test_no_wall_clock_outcome(self):
        """The runtime has no per-sample wall-clock timer; the CPU-time hang guard and the server's
        no-output guard raise ProbeError, never a sample outcome."""
        self.assertNotIn("ITIMER_REAL", S.RUNTIME_C)
        self.assertIn("ITIMER_PROF", S.RUNTIME_C)
        self.assertFalse(hasattr(S, "PER_SAMPLE_MS"))
        self.assertTrue(issubclass(S.ProbeError, RuntimeError))



# cq-kr9h: an access through a pointer chosen at run time (select, an indirect call, a pointer stored
# and loaded again, a direct call of a select) at the address c[t] and the zero-size x[0] share
PROV_C = r"""
#include <string.h>
__attribute__((noinline)) static int rd(volatile char *p, int i) { return p[i]; }
static int (*volatile fp)(volatile char *, int) = rd;
static volatile char *volatile gp;
int zs(int t, int nq, int mode, int sel) {
    volatile char c[t], x[nq];
    memset((char *)c, 0, t);
    if (mode == 1) { volatile char *p = sel ? c : x; return p[0]; }
    if (mode == 2) return fp(sel ? c : x, 0);
    if (mode == 3) { gp = sel ? c : x; return gp[0]; }
    if (mode == 4) return rd(sel ? c : x, 0);
    if (mode == 5) { volatile char *p = sel ? c : x; __asm__("" : "+r"(p)); return p[0]; }
    return c[0];
}
"""
PROV_LINE = "905_probe_zs|int zs(int,int,int,int);|zs(4,0,0,0)"


class Provenance(unittest.TestCase):
    """cq-kr9h: where a zero-size object lies at another's base (x[0] at c's base when nq = 0), the
    probe decides which object an access means by the pointer's run-time provenance (the object's
    serial, carried through select, phi, memory, call arguments and results), never by preference:
    c[0] through any of them is inside c, x[0] through any of them leaves x (a mutant of each path:
    the preference for the object of positive size would keep it), and a pointer whose provenance the
    probe does not carry (laundered through inline asm) at that address stops with an internal error."""

    @staticmethod
    def smp(*xs):
        return {"call": 0, "args": [f"0x{x & 0xffffffff:08x}" for x in xs]}

    def test_provenance_decides_the_shared_address(self):
        smp = self.smp
        cases = [smp(4, 0, m, 1) for m in (1, 2, 3, 4)] + [smp(4, 0, m, 0) for m in (1, 2, 3, 4)] + \
                [smp(4, 1, m, 0) for m in (1, 2, 3, 4, 5)] + [smp(4, 0, 0, 0)]
        with tempfile.TemporaryDirectory() as d:
            t = Path(d)
            ex = synth_example(t, "905_probe_zs", PROV_C, PROV_LINE)
            spec = D.driver_spec("905_probe_zs", ex)
            with S.ProbeBuild(spec, ex, t / "work") as pb:
                obs = pb.run(cases)
                with self.assertRaisesRegex(RuntimeError, "cq: unimplemented: .*provenance"):
                    pb.run([smp(4, 0, 5, 1)])
        for c, o in zip(cases[:4], obs[:4]):
            self.assertEqual((o.end, o.oob), ("exit", set()), c)
        for c, o in zip(cases[4:8], obs[4:8]):
            self.assertEqual(o.end, "oob", c)
        for c, o in zip(cases[8:], obs[8:]):
            self.assertEqual((o.end, o.oob), ("exit", set()), c)


# cq-g8md: a trip target reached only after more loop-header executions than the cost budget. The inner
# loop's guard skips it at j == 12 only, after 12 * 1000 inner trips; with UB, every input reaching that
# skip first shifts by 32 at j == 12.
COST_C = r"""
int f(int t) {
    volatile int s = 0;
    for (int j = 0; j < t; j++) {
        int m = j == 12 ? 0 : 1000;
        for (int k = 0; k < m; k++) s += k;
    }
    return s;
}
"""
# t > 20 returns at once, so the search past the budget decides every input the budget stopped
# (t = 5..20, each under the cap): only then is a target reached only through UB dead (cq-3nla)
COST_UB_C = r"""
int f(int t) {
    volatile int s = 0, b = 20;
    if (t > 20) return 0;
    for (int j = 0; j < t; j++) {
        s += 1 << (j + b);
        int m = j == 12 ? 0 : 1000;
        for (int k = 0; k < m; k++) s += k;
    }
    return s;
}
"""
# cq-3nla (../wt/rev/w2a-chk3-n1/dead_probe_mut.py): trip 0 of the inner loop needs t >= 15; t = 15
# reads a[4] (outside a), t = 16 is clean; t = 1600 alone runs 10^6 extra header executions
COST_WORK_C = r"""
int f(int t) {
    volatile int s = 0;
    volatile int a[4] = {0, 0, 0, 0};
    if (t == 1600) { for (volatile int w = 0; w < 1000000; w++) s += w; }
    for (int j = 0; j < t; j++) {
        int m = (j == t - 3 && j >= 12) ? 0 : 1000;
        for (int k = 0; k < m; k++) s += k;
    }
    volatile int idx = t - 11;
    if (t == 15) s += a[idx];
    return s;
}
"""
COST_LINE = "906_probe_cost|int f(int);|f(3)"


class CostBudget(unittest.TestCase):
    """cq-g8md, cq-hsan, cq-3nla (owner rulings 2026-11-01): within the budget the target is a sample;
    nothing runs past the budget; a target no input reaches within it while it stopped constructed
    inputs is uncovered with those inputs and cost "> budget", never a sample and never dead; reached
    only through an undefined shift with no input stopped, it is dead."""

    def target(self, c_text, env):
        saved = {k: os.environ.get(k) for k in env}
        os.environ.update(env)
        try:
            with tempfile.TemporaryDirectory() as d:
                t = Path(d)
                ex = synth_example(t, "906_probe_cost", c_text, COST_LINE)
                spec = D.driver_spec("906_probe_cost", ex)
                g = S.Gen(spec, [["0x00000003"]])
                g.add(0, ["0x00000003"])
                with S.ProbeBuild(spec, ex, t / "work") as pb:
                    rows = {s_.id: S.rows_for(s_) for s_ in pb.ins.sites}
                    searcher = S.Searcher(g, pb, rows, __import__("random").Random(1))
                    (inner,) = [lp for lp in pb.ins.loops if lp.parent is not None]
                    from cqcheck import gaps
                    fn = pb.mod.functions[inner.fn]
                    zero = gaps.zero_meaning(fn, inner.header, inner.blocks)
                    out = [{"loop": inner.key(), "parent": None, "zero": zero,
                            "trips": {"0": {"empty": "no input found: the test's own search"}}}]
                    S.construct_trip_targets(spec, ex, g, searcher, out)
                    return out[0], zero, g
        finally:
            for k, v in saved.items():
                if v is None:
                    os.environ.pop(k, None)
                else:
                    os.environ[k] = v

    def test_uncovered_past_the_budget(self):
        e, zero, _ = self.target(COST_C, {"CQ_COST_BUDGET": "4096"})
        self.assertIn("guard branch", zero)
        t0 = e["trips"]["0"]
        self.assertNotIn("sample", t0)
        self.assertNotIn("proof", t0)
        u = t0["uncovered"]
        # the stopped inputs, nearest the drivers.txt call f(3) first: t = 5 is the first past 4096
        self.assertEqual(u["stopped"][0]["args"], ["0x00000005"])
        self.assertGreater(u["n_stopped"], len(u["stopped"]) - 1)
        self.assertEqual((u["cost"], u["budget"]), ("> 4096", 4096))
        self.assertTrue(t0["empty"].startswith("uncovered: "))
        self.assertIn(zero, t0["empty"])

    def test_nothing_runs_past_the_budget(self):
        # owner override 2026-11-01: no oracle or probe run past the budget anywhere (was: reruns up
        # to a witness cap of 2^32 header executions)
        from cqcheck import oracle
        caps = []
        orig_or, orig_pb = oracle.run_samples, S.ProbeBuild.run

        def rs(o1, spec, smp, *a, **k):
            caps.append(("oracle", k.get("tripcap")))
            return orig_or(o1, spec, smp, *a, **k)

        def pr(pb, samples, hdrcap=None, hang_s=None):
            caps.append(("probe", hdrcap))
            return orig_pb(pb, samples, hdrcap, hang_s)
        oracle.run_samples, S.ProbeBuild.run = rs, pr
        try:
            self.target(COST_C, {"CQ_COST_BUDGET": "4096"})
        finally:
            oracle.run_samples, S.ProbeBuild.run = orig_or, orig_pb
        self.assertTrue(caps)
        self.assertEqual([c for c in caps if c[1] is not None and c[1] > 4096], [])

    def test_within_the_budget_it_is_a_sample(self):
        # mutant of the budget: the same target with a budget of 2^20 is a sample, never uncovered
        e, _, g = self.target(COST_C, {"CQ_COST_BUDGET": str(1 << 20)})
        self.assertIn("sample", e["trips"]["0"])
        self.assertNotIn("uncovered", e["trips"]["0"])

    def test_reached_only_through_poison_is_dead(self):
        # every constructed input runs to its end within 2^20 (t > 20 returns at once): every reach
        # of trip 0 (t >= 13) shifts by 32 or more, so the target is dead (cq-oou2's proof)
        from cqcheck import gaps
        e, _, _ = self.target(COST_UB_C, {"CQ_COST_BUDGET": str(1 << 20)})
        t0 = e["trips"]["0"]
        self.assertNotIn("uncovered", t0)
        self.assertEqual(t0.get("proof"), "ub")
        self.assertEqual(gaps.classify_reason(t0["empty"]), gaps.IMPOSSIBLE)

    def test_ub_reach_with_stopped_inputs_is_uncovered(self):
        # cq-hsan, CR §6 (afef520): the same program at 15500: every in-budget reach (t = 15, 16) is
        # undefined, but the budget stopped constructed inputs (t = 17, any of which might reach
        # it cleanly as far as the checker knows): no proof, uncovered (the old proof made it dead)
        e, _, _ = self.target(COST_UB_C, {"CQ_COST_BUDGET": "15500"})
        t0 = e["trips"]["0"]
        self.assertNotIn("proof", t0)
        self.assertIn("uncovered", t0)
        self.assertIn("(cq-hsan)", t0["empty"])

    def test_oob_reach_with_stopped_inputs_is_never_dead(self):
        # cq-3nla (review w2a-chk3-n1 finding 1): t = 15 reaches trip 0 only through an access outside
        # an object, t = 16 cleanly; at 14500 header executions t = 15 runs within the budget, t = 16
        # is stopped after reaching it (at 13014 header executions, too costly to compare): the oob
        # reach is no proof, the target is uncovered with t = 16 the nearest stopped input
        e, _, _ = self.target(COST_WORK_C, {"CQ_COST_BUDGET": "14500"})
        t0 = e["trips"]["0"]
        self.assertNotIn("proof", t0)
        self.assertEqual(t0["uncovered"]["stopped"][0]["args"], ["0x00000010"])

    def test_gaps_and_report(self):
        from cqcheck import gaps, report
        from cqcheck.contracts import Verdict
        why = "uncovered: no input within the cost budget ..."
        ss = SampleSet("x", [{"call": 0, "args": ["0x0"]}], {
            "trips": {"loops": [{"loop": "f:%8", "trips": {"0": {"empty": why, "uncovered": {"witness": {}}},
                                                          "3": {"sample": 0}, "4": {"sample": 0},
                                                          "5": {"sample": 0}}}]}})
        found = [g_ for g_ in gaps.sample_gaps(D.driver_spec("117_qpe_counting", D.example_dir("117_qpe_counting")),
                                               ss, Path("."), S.LLVM_BIN) if g_.where.startswith("trips")]
        self.assertEqual([(g_.kind, g_.where) for g_ in found], [(gaps.UNCOVERED, "trips: f:%8 trip 0")])
        v = Verdict("x", report.PASS, report.PASS, report.PASS, None, ["sampling: " + why])
        # accepted by the gate, never green (owner ruling 2026-11-01): its state is UNCOVERED
        self.assertTrue(report.accepted(v))
        self.assertFalse(report.green(v))
        self.assertEqual(report.state(v), report.UNCOVERED)
        self.assertTrue(report.requested_accepted(v))
        self.assertFalse(report.requested_green(v))
        self.assertEqual(report.uncovered(v), ["sampling: " + why])
        table = report.format_table([v])
        self.assertIn("green 0, uncovered 1", table)
        # the progress table counts it failing, never passing (not green)
        from cqcheck import progress
        cr = "## 3. Rules\n1. **A rule.** text — 117\n## 4. Next\n"
        rows, _ = progress.build_table(cr, {"117_qpe_counting": v}, {"117": "117_qpe_counting"})
        self.assertEqual(rows, [("1 A rule", "117", "", "117")])
        self.assertIn("sampling: uncovered:", table.splitlines()[1])


# cq-r7-trips: every reach of the target is undefined (a[4] past the object), and the inputs the
# budget of 4096 stops cannot reach it after the stop. STOP_UB_C: t >= 4097 reads a[4] at j = 4 before
# the stop (noted: decided). STOP_COUNT_C: n >= 4097 stops in the first loop, before the j-loop, whose
# exact backedge-taken count t - 1 (ScalarEvolution) gives t = 3 trips, never 5. STOP_PAST_C: trip 0
# needs n <= 0, which reads a[4]; n >= 4097 stops inside the loop's only activation, past 1 header run.
STOP_UB_C = r"""
int f(int t) {
    volatile int s = 0;
    volatile int a[4] = {0, 0, 0, 0};
    for (int j = 0; j < t; j++) s += a[j];
    return s;
}
"""
STOP_COUNT_C = r"""
int f(int t, int n) {
    volatile int s = 0;
    volatile int a[4] = {0, 0, 0, 0};
    for (int i = 0; i < n; i++) s += i;
    for (int j = 0; j < t; j++) s += a[j];
    return s;
}
"""
STOP_BOUND_C = r"""
static volatile int a[2] = {0, 0};
__attribute__((noinline)) static int find(int n, int v) {
    for (int k = 0; k < n; k++)
        if (a[k] == v) return k;
    return -1;
}
int f(int t, int n) {
    volatile int s = 0;
    for (int i = 0; i < t; i++) s += i;
    return s + find(n, 7);
}
"""
STOP_PAST_C = r"""
int f(int n) {
    volatile int s = 0;
    volatile int a[4] = {0, 0, 0, 0};
    for (int i = 0; i < n; i++) s += i;
    volatile int k = n > 0 ? 0 : 4;
    return s + a[k];
}
"""


class StoppedInputs(unittest.TestCase):
    """cq-r7-trips: a constructed input the cost budget stopped keeps a target uncovered only when it
    may reach it after the stop: one that executed an undefined operation before the stop is outside
    the domain (budget_undecided), and StoppedReach decides the loop's count from ScalarEvolution's
    exact count over the arguments ("count") or from the probe's view of the loop's only activation
    ("past it"). Mutants: each decision off leaves the target uncovered (cq-hsan's rule)."""

    def target(self, c_text, line, base, loop_index, t, mutate=None):
        saved = os.environ.get("CQ_COST_BUDGET")
        os.environ["CQ_COST_BUDGET"] = "4096"
        try:
            with tempfile.TemporaryDirectory() as d:
                tdir = Path(d)
                ex = synth_example(tdir, "907_stop", c_text, line)
                spec = D.driver_spec("907_stop", ex)
                g = S.Gen(spec, [base])
                g.add(0, list(base))
                with S.ProbeBuild(spec, ex, tdir / "work") as pb:
                    rows = {s_.id: S.rows_for(s_) for s_ in pb.ins.sites}
                    searcher = S.Searcher(g, pb, rows, __import__("random").Random(1))
                    lp = (pb.ins.loops[loop_index] if isinstance(loop_index, int) else
                          next(l for l in pb.ins.loops if l.key().startswith(loop_index + ":")))
                    from cqcheck import gaps
                    out = [{"loop": lp.key(), "parent": None,
                            "zero": gaps.zero_meaning(pb.mod.functions[lp.fn], lp.header, lp.blocks),
                            "trips": {str(t): {"empty": "no input found: the test's own search"}}}]
                    if mutate:
                        with mutate():
                            S.construct_trip_targets(spec, ex, g, searcher, out)
                    else:
                        S.construct_trip_targets(spec, ex, g, searcher, out)
                    return out[0]["trips"][str(t)]
        finally:
            if saved is None:
                os.environ.pop("CQ_COST_BUDGET", None)
            else:
                os.environ["CQ_COST_BUDGET"] = saved

    @staticmethod
    def patched(obj, name, value):
        import contextlib

        @contextlib.contextmanager
        def cm():
            old = getattr(obj, name)
            setattr(obj, name, value)
            try:
                yield
            finally:
                setattr(obj, name, old)
        return cm

    def assert_dead(self, e):
        from cqcheck import gaps
        self.assertEqual(e.get("proof"), "ub", e)
        self.assertNotIn("uncovered", e)
        self.assertIn("cq-r7-trips", e["empty"])
        self.assertEqual(gaps.classify_reason(e["empty"]), gaps.IMPOSSIBLE)

    def test_scev_eval(self):
        from cqcheck import gaps
        p = {"%0": (32, 0x7ff), "%4": (32, 2), "%2": (32, 0)}
        self.assertEqual(gaps.scev_eval("(-1 + (zext i32 %4 to i64))<nsw>", p), 1)
        self.assertEqual(gaps.scev_eval("(-1 + (zext i32 %2 to i64))", p), (1 << 64) - 1)
        self.assertEqual(gaps.scev_eval("((zext i32 %0 to i64) /u 3)", p), 682)
        self.assertEqual(gaps.scev_eval("(-2 + (-1 smax (sext i32 %4 to i64)))", p), 0)
        self.assertEqual(gaps.scev_eval("(-1 + (1 smax %4))<nsw>", p), 1)
        self.assertEqual(gaps.scev_eval("(-1 + (umin %4 %0))", p), None)       # not a form it knows
        self.assertEqual(gaps.scev_eval("{0,+,1}<nuw><%5>", p), None)          # an AddRec
        self.assertEqual(gaps.scev_eval("(-1 + (zext i32 %9 to i64))", p), None)   # not a parameter
        self.assertEqual(gaps.scev_eval("(%4 + (zext i32 %0 to i64))", p), None)   # widths differ

    def test_undefined_before_the_stop(self):
        e = self.target(STOP_UB_C, "907_stop|int f(int);|f(3)", ["0x00000003"], 0, 5)
        self.assert_dead(e)
        # mutant: every stopped input counts (cq-hsan before cq-r7-trips): uncovered
        old = S.budget_undecided
        e = self.target(STOP_UB_C, "907_stop|int f(int);|f(3)", ["0x00000003"], 0, 5,
                        self.patched(S, "budget_undecided",
                                     lambda kr: kr is not None and kr.failed and "tripcap" in kr.notes))
        self.assertIs(S.budget_undecided, old)
        self.assertIn("uncovered", e)
        self.assertNotIn("proof", e)

    def test_count_from_scalar_evolution(self):
        line = "907_stop|int f(int,int);|f(3,2)"
        e = self.target(STOP_COUNT_C, line, ["0x00000003", "0x00000002"], 1, 5)
        self.assert_dead(e)
        # mutant: no ScalarEvolution count: the n-stopped inputs stay open, uncovered
        e = self.target(STOP_COUNT_C, line, ["0x00000003", "0x00000002"], 1, 5,
                        self.patched(S.StoppedReach, "why_not", lambda self, smp, o, loop, t: None))
        self.assertIn("uncovered", e)
        self.assertTrue(e["uncovered"]["n_stopped"] > 0)

    def test_bound_from_symbolic_max_in_a_callee(self):
        # cq-824x (117's is_marked loop in grover): find's loop has two exits, so no exact count; its
        # symbolic maximum n - 1 bounds every activation by n header executions, and find is called
        # only by f with f's own n. A t-stopped input keeps n = 2: no 3 trips of find's loop after
        # the stop; every in-budget reach of 3 trips (n >= 3) reads a[2], outside a: dead
        line = "907_stop|int f(int,int);|f(3,2)"
        e = self.target(STOP_BOUND_C, line, ["0x00000003", "0x00000002"], "find", 3)
        self.assert_dead(e)
        # mutant: no symbolic maximum: the t-stopped inputs stay open, uncovered
        from cqcheck import gaps
        real = gaps.scev_symbolic_counts
        e = self.target(STOP_BOUND_C, line, ["0x00000003", "0x00000002"], "find", 3,
                        self.patched(gaps, "scev_symbolic_counts",
                                     lambda o1, b, symbolic_max=False: {} if symbolic_max else real(o1, b)))
        self.assertIn("uncovered", e)
        self.assertTrue(e["uncovered"]["n_stopped"] > 0)
        # mutant: find also called through a pointer (not fed by f's direct calls only): uncovered
        e = self.target(STOP_BOUND_C.replace("return s + find(n, 7);",
                                             "int (*volatile p)(int, int) = find; return s + find(n, 7) + p(1, 7);"),
                        line, ["0x00000003", "0x00000002"], "find", 3)
        self.assertIn("uncovered", e)

    def test_past_the_only_activation(self):
        line = "907_stop|int f(int);|f(3)"
        e = self.target(STOP_PAST_C, line, ["0x00000003"], 0, 0)
        self.assert_dead(e)
        # mutant: the loop may be entered again after it (single entry off): uncovered
        e = self.target(STOP_PAST_C, line, ["0x00000003"], 0, 0,
                        self.patched(S.StoppedReach, "_single_entry", lambda self, lp: False))
        self.assertIn("uncovered", e)

    def test_addr_root_constexpr_gep_base(self):
        # cq-06bi (musl sweep, __exp_data): a GEP whose base is a constant-expression GEP roots at
        # the global it names, never at the text "112)"
        ll = ("@t = global [300 x i64] zeroinitializer\n"
              "define i64 @f(i64 %i) {\n"
              "  %p = getelementptr inbounds [256 x i64], ptr getelementptr inbounds (i8, ptr @t, i64 112), "
              "i64 0, i64 %i\n  %v = load i64, ptr %p, align 8\n  ret i64 %v\n}\n")
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "m.ll"
            p.write_text(ll)
            mod = D.read_module(p)
            ins = S.Instrumenter(mod, None)
            self.assertEqual(ins.addr_root(mod.functions["@f"] if "@f" in mod.functions else mod.functions["f"], "%p"),
                             ("@t", True))

    def test_single_entry(self):
        # a nested loop is entered once per outer trip; a top-level loop once per call
        with tempfile.TemporaryDirectory() as d:
            tdir = Path(d)
            ex = synth_example(tdir, "906_probe_cost", COST_C, COST_LINE)
            spec = D.driver_spec("906_probe_cost", ex)
            o1 = sorted(ex.glob("*.O1.ll"))[0]
            mod = D.read_module(o1)
            ins = S.Instrumenter(mod, None)
            loops = [lp for f in mod.functions.values() for lp in ins.find_loops(f)]
            r = S.StoppedReach(spec, S.Gen(spec, [["0x00000003"]]), mod, o1, loops)
            by_parent = {lp.parent is None: r._single_entry(lp) for lp in loops}
            self.assertEqual(by_parent, {True: True, False: False})
            # a call of f elsewhere in the module, or in the setup: f's loops are not run by the driver only
            spec2 = DriverSpec(spec.example, spec.protos, "int z = f(1);", spec.calls)
            r2 = S.StoppedReach(spec2, S.Gen(spec2, [["0x00000003"]]), mod, o1, loops)
            self.assertNotIn("@f", r2.unused)
            self.assertIsNone(r2.why_not({"call": 0, "args": ["0x00000003"]}, None, loops[0].key(), 5))


class TripMode(unittest.TestCase):
    """cq-g8md: the oracle's trip mode gives the full run's outcome and trip counts, each distinct trip
    event once with the header executions at which it was reached, the sample's header executions,
    and no site event; trip 0 of 117's inner k-loop is its guard at %46 skipping it."""

    def test_trip_mode_agrees(self):
        from cqcheck import oracle
        n = "117_qpe_counting"
        ex = D.example_dir(n)
        spec = D.driver_spec(n, ex)
        o1 = sorted(ex.glob("*.O1.ll"))[0]
        smp = [{"call": 0, "args": ["0x00000003", "0x00000004", "mk1", "0x00000002"]}]
        (full,) = oracle.run_samples(o1, spec, smp)
        (trip,) = oracle.run_samples(o1, spec, smp, trips_only=True)
        self.assertEqual((full.outcome, full.failed), (trip.outcome, trip.failed))
        ft = {(e["loop"], e["n"]) for e in full.events if e.get("ev") == "trip"}
        tt = [(e["loop"], e["n"]) for e in trip.events if e.get("ev") == "trip"]
        self.assertEqual(set(tt), ft)
        self.assertEqual(len(tt), len(set(tt)))
        self.assertFalse(any(e.get("ev") == "site" for e in trip.events))
        self.assertTrue(any(e.get("ev") == "site" for e in full.events))
        ticks = [e["n"] for e in trip.events if e.get("ev") == "ticks"]
        self.assertEqual(len(ticks), 1)
        self.assertTrue(all(0 < e["h"] <= ticks[0] for e in trip.events if e.get("ev") == "trip" and e["n"]))

    def test_zero_meaning(self):
        from cqcheck import gaps
        mod = D.read_module(sorted(D.example_dir("117_qpe_counting").glob("*.O1.ll"))[0])
        f = mod.functions["@qpe_counting"]
        (lp,) = [x for x in S.Instrumenter(mod).find_loops(f) if x.header == "%65"]
        self.assertEqual(gaps.zero_meaning(f, lp.header, lp.blocks),
                         "trip 0 means the guard branch in %46 goes to %62, skipping the loop")


class SearchMemory(unittest.TestCase):
    """cq-hfj9: the probe's records stay packed per observation (SiteRecs) and read back as the
    tuples they stand for; the search's grouped elite finds a target and keeps every observation's
    validity and per-site support once."""

    def test_parse_reads_back_records(self):
        w = lambda *v: " ".join("%016x" % x for x in v)    # noqa: E731 - the probe's %016llx words
        text = "\n".join([
            "S 0", "p 7 " + w(1, 0, 2, 0, 3, 0, 4, 0), "p 7 " + w((1 << 64) - 1, 1, 0, 0, 0, 0, 0, 0),
            "p 9 " + w(0, 0, 0, 0, 0, 0, 0, 0),
            "m 3 -8 16 4", "m 3 0 16 4", "t 2 5", "E exit 0 6",
            "S 1", "E exit 0 0", ""])
        obs = [S.Obs(), S.Obs()]
        S.ProbeBuild._parse(text, obs)
        o = obs[0]
        self.assertEqual(o.p.get(7), [(1, 2, 3, 4), ((1 << 64) | ((1 << 64) - 1), 0, 0, 0)])
        self.assertEqual(sorted(o.p.items()), [(7, o.p.get(7)), (9, [(0, 0, 0, 0)])])
        self.assertEqual(sorted(o.p), [7, 9])
        self.assertIn(9, o.p)
        self.assertNotIn(8, o.p)
        self.assertEqual(o.p.get(8, []), [])
        self.assertEqual(o.m.get(3), [(-8, 16), (0, 16)])
        self.assertEqual(o.oob, {3})
        self.assertEqual((o.t, o.end, o.hdrs), ({2: [5]}, "exit", 6))
        self.assertFalse(obs[1].p)
        self.assertEqual(len(obs[1].m), 0)

    def test_grouped_search_finds_the_target(self):
        from types import SimpleNamespace as NS
        import random

        class FakePB:
            runs = 0

            def run(self, samples):
                out = []
                for smp in samples:
                    v = int(smp["args"][0], 16)
                    o = S.Obs(ran=True, end="exit")
                    o.p = {1: [(v, 0, 0, 0)]}
                    out.append(o)
                return out

        ct = D.parse_ctype("int")
        g = NS(cts=[[ct]], quantum_slots=lambda c: [0], classical_slots=lambda c: [], cell_slots=lambda c: [],
               spec=NS(calls=[{"args": [{"quantum": True}]}]),
               random_quantum=lambda rng, ct: rng.randrange(1 << 32))
        se = S.Searcher(g, FakePB(), {}, random.Random(1))
        pool = [(0, [S.hexw(ct, 1000)]), (0, [S.hexw(ct, 5000)])]
        dist = lambda o: min((abs(r[0] - 990) for r in S._records(o, NS(kind="int", id=1))), default=1e308)  # noqa: E731
        found = se.search(pool, dist, budget=20000, support=("p", 1, 1e308))
        self.assertIsNotNone(found)
        self.assertEqual(int(found[1][0], 16), 990)
        self.assertEqual(len(se.valid_keys), len(se.cache))


if __name__ == "__main__":
    unittest.main(verbosity=2)
