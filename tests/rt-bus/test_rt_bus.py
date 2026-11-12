#!/usr/bin/env python3
"""tests/rt-bus: the evaluator's memory bus and the injection-bundle host file (harness.c), and the flat-memory
references run under the evaluator through a hand driver (drivers.txt's calls, nothing of cqcheck)."""
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
RT = ROOT / "checker" / "rt"
HOST = ROOT / "bundle" / "host" / "cq_host.c"
LLVM = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
CLANG = str(LLVM / "clang")
SPEC = Path(os.environ.get("CQ_SPEC_DIR", ROOT.parent / "CQ_spec")).resolve()
TRIPLE = "x86_64-apple-macosx"
WORK = None
OBJS = []


def setUpModule():
    global WORK, OBJS
    WORK = tempfile.TemporaryDirectory(prefix="rt-bus.")
    jobs = []
    for s in [*sorted(RT.glob("*.c")), HOST]:
        o = Path(WORK.name) / (s.stem + ".o")
        jobs.append(subprocess.Popen([CLANG, "-std=c17", "-O1", "-w", "-target", TRIPLE, "-I", str(RT), "-c", str(s), "-o", str(o)]))
        OBJS.append(str(o))
        if len(jobs) == 4:
            for j in jobs:
                assert j.wait() == 0
            jobs = []
    for j in jobs:
        assert j.wait() == 0


def tearDownModule():
    WORK.cleanup()


def run_exe(exe, args=(), expect_code=0):
    t = Path(WORK.name) / "t.jsonl"
    p = subprocess.run([exe, *args], env=dict(os.environ, CQE_TRACE=str(t)), capture_output=True, text=True, timeout=120)
    ev = [json.loads(l) for l in t.read_text().splitlines() if l.strip()] if t.exists() else []
    return p, ev


class Harness:
    exe = None

    @classmethod
    def get(cls):
        if not cls.exe:
            cls.exe = str(Path(WORK.name) / "harness")
            subprocess.run([CLANG, "-std=c17", "-O0", "-w", "-target", TRIPLE, "-I", str(RT), str(HERE / "harness.c"), *OBJS, "-o", cls.exe],
                           check=True)
        return cls.exe


def sc(name):
    p, ev = run_exe(Harness.get(), [name])
    return p, ev


def viol(ev):
    return [e["what"] for e in ev if e["ev"] == "violation"]


def live(ev):
    return next(e for e in ev if e["ev"] == "exit")["live"]


def roles(ev):
    return sorted(r["role"] for r in live(ev))


def cells(ev):
    return next(e for e in ev if e["ev"] == "cells")["q"]


def bus(ev, op=None):
    return [e for e in ev if e["ev"] == "bus" and (op is None or e["op"] == op)]


class Scenarios(unittest.TestCase):
    def ok(self, name):
        p, ev = sc(name)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(viol(ev), [], [e for e in ev if e["ev"] == "violation"])
        return ev

    def test_host_ops(self):
        ev = self.ok("host_ops")
        self.assertEqual(cells(ev), [])
        self.assertTrue(all(e["host"] == 1 for e in bus(ev)), bus(ev))
        self.assertEqual([r["v"] for r in live(ev) if r["role"] == "tape_slot"], ["0x11223344", "0xaabbccdd"])
        self.assertTrue(all(r["known"] for r in live(ev)))
        self.assertEqual({e["op"] for e in bus(ev)}, {"load", "store", "swap"})
        e = bus(ev, "load")[0]
        self.assertEqual({"ev", "op", "w", "addr", "c", "host", "h", "v"} <= set(e), True)
        self.assertEqual((e["w"], e["c"], e["v"]), ("i32", -1, "0x11223344"))
        self.assertIsInstance(e["addr"], int)
        self.assertIn("t", bus(ev, "store")[0])
        self.assertEqual(bus(ev, "load")[1].get("unc"), 1)

    def test_quantum_ops(self):
        ev = self.ok("quantum_ops")
        self.assertEqual(len(cells(ev)), 4)                 # g2 only
        self.assertEqual([c[1] for c in cells(ev)], [7, 0, 0, 0])
        self.assertEqual(next(e for e in ev if e["ev"] == "out_mem")["v"], "0x7")
        slots = [r for r in live(ev) if r["role"] == "tape_slot"]
        self.assertEqual([r["known"] for r in slots], [True, False, True])   # displaced host, quantum, host
        self.assertEqual([r["v"] for r in slots], ["0x11223344", "0x7", "0x55667788"])
        self.assertEqual(bus(ev, "store")[0]["host"], 0)
        self.assertEqual(bus(ev, "store")[1]["host"], 1)     # back to HOST
        self.assertEqual([e["host"] for e in bus(ev, "swap")], [1, 0])

    def test_controlled_zero_touches_nothing(self):
        ev = self.ok("controlled")
        self.assertEqual(cells(ev), [])
        self.assertEqual([e["c"] for e in bus(ev, "store")], [0, 0, 1])
        slots = [r for r in live(ev) if r["role"] == "tape_slot"]
        self.assertEqual([r["v"] for r in slots], ["0x0", "0x0", "0x11223344"])
        self.assertTrue(all(r["known"] for r in slots))

    def test_controlled_not_classical(self):
        ev = self.ok("controlled_quantum")
        # g's four cells went QUANTUM with their content, and g2's under the swap pair
        self.assertEqual(sorted(c[1] for c in cells(ev)), sorted([0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55]))
        self.assertEqual([r["known"] for r in live(ev) if r["role"] == "tape_slot"], [False])

    def test_unreadable_reads_zero(self):
        ev = self.ok("unreadable")
        self.assertEqual(len(cells(ev)), 4)
        self.assertEqual([(c[0] & 0xFF, c[1]) for c in cells(ev)], [(0, 3), (1, 4), (0xFE, 1), (0xFF, 2)])

    def test_store_to_unwritable_is_quantum(self):
        ev = self.ok("unwritable")
        self.assertEqual([c[1] for c in cells(ev)], [0x66, 0x66])
        self.assertEqual([r["v"] for r in live(ev) if r["role"] == "tape_slot"], ["0x5a", "0x0"])

    def test_classical_unc_host_change_free_legal(self):
        ev = self.ok("classical_unc")
        self.assertEqual(next(e for e in ev if e["ev"] == "free")["v"], "0x1")

    def test_overtaken_role(self):
        ev = self.ok("overtaken")
        self.assertEqual([r["v"] for r in live(ev) if r["role"] == "overtaken"], ["0xf"])

    def test_overtaken_freed_is_dirty(self):
        _, ev = sc("overtaken_freed")
        self.assertEqual(viol(ev), ["dirty_free"])

    def test_roles(self):
        ev = self.ok("roles")
        self.assertEqual(roles(ev), sorted(["frozen", "store_kept", "store_kept", "store_kept", "tape_slot", "tape_slot"]))

    def test_violations(self):
        for name, want in (("v_rotated_copy_unc", ["unc_after_nondiagonal"]), ("v_measured_copy_unc", ["unc_after_measure"]),
                           ("v_unc_address", ["load_unc_args"]), ("v_dirty_load_free", ["dirty_free"]),
                           ("v_second_bus", ["bad_bus"]), ("v_bad_bus", ["bad_bus"]), ("v_no_bus", ["bad_bus"]),
                           ("v_sized_bus", ["bad_bus"]), ("v_other_width_bus", ["bad_bus"]), ("v_addr_width", ["width_mismatch"]),
                           ("v_value_width", ["width_mismatch"]), ("v_store_unc", ["unknown_symbol"]),
                           ("v_swap_alias", ["target_aliases_operand"]), ("v_retired", ["unknown_symbol", "unknown_symbol",
                            "unknown_symbol", "bad_template", "unknown_symbol"])):
            with self.subTest(name):
                _, ev = sc(name)
                self.assertEqual(viol(ev), want, [e for e in ev if e["ev"] == "violation"])

    def test_widths(self):
        ev = self.ok("widths")
        slots = [r for r in live(ev) if r["role"] == "tape_slot"]
        self.assertEqual([(r["w"], r["v"]) for r in slots], [("i8", "0xf0"), ("f80", "0xeeeeeeeeeeeeeeeeeeee"),
                                                             ("i104", "0xeeeeeeeeeeeeeeeeeeeeeeeeee")])

    def test_alloc(self):
        self.ok("alloc")

    def test_clone_rows(self):
        self.ok("clones")
        p, _ = sc("clone_bad_kind")
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("__cq_clone_resolve: kind 4", p.stderr)

    def test_shots_start_from_the_setup(self):
        p, ev = sc("shots")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(viol(ev), [])
        out = [e for e in ev if e["ev"] == "out_mem"]
        self.assertEqual(len(out), 15)
        names = [e["name"] for e in out]
        for i in range(3):
            s = out[5 * i:5 * i + 5]
            self.assertEqual([e["v"] for e in s], ["0x0", "0x4242424242424242", "0x0", "0x7", "0x11223344"], s)
            self.assertEqual(s[3]["name"], names[3], "the __cq_alloc address is the same in every sample")
        self.assertEqual([len(e["q"]) for e in ev if e["ev"] == "cells"], [4, 4, 4])

    def test_effect_stores_through_the_bus(self):
        ev = self.ok("effect_qstore_1")
        n = len(cells(ev))
        self.assertGreaterEqual(n, 1)
        slots = [r for r in live(ev) if r["role"] == "tape_slot"]
        self.assertEqual(len(slots), n)
        self.assertEqual(slots[0]["v"], "0xa0")       # the displaced content
        self.assertTrue(all(not r["known"] for r in slots))
        ev0 = self.ok("effect_qstore_0")
        self.assertEqual(len(cells(ev0)), n)          # the cells it can reach
        self.assertEqual(next(e for e in ev0 if e["ev"] == "out_mem")["v"], "0xa3a2a1a0")   # kept
        self.assertEqual({r["v"] for r in live(ev0) if r["role"] == "tape_slot"}, {"0x0"})

    def test_classical_input_over_quantum_cells(self):
        # rulings 2 D (cq-ytux): an all-classical fgets overwrites QUANTUM cells: they read the input, HOST again
        ev = self.ok("effect_cstore")
        self.assertEqual(cells(ev), [])
        out = int(next(e for e in ev if e["ev"] == "out_mem")["v"], 16)
        self.assertEqual(out >> 24, 0)                # the NUL
        # the input stream's first three bytes (ruling Q5, fx_standin.h CQ_FX_STDIN_DEFAULT)
        hdr = (Path(__file__).resolve().parents[2] / "checker" / "rt" / "fx_standin.h").read_text()
        lit = re.search(r'#define CQ_FX_STDIN_DEFAULT "((?:[^"\\]|\\.)*)"', hdr).group(1)
        first = lit.encode().decode("unicode_escape").encode("latin-1")[:3]
        self.assertEqual(out & 0xffffff, int.from_bytes(first, "little"), hex(out))
        slots = [r for r in live(ev) if r["role"] == "tape_slot"]
        # the store's (the host bytes it displaced), then one per byte fgets stored, holding the quantum bytes
        self.assertEqual([r["v"] for r in slots], ["0xb3b2b1b0", "0x88", "0x77", "0x66", "0x55"])
        self.assertTrue(all(not r["known"] for r in slots[1:]), slots)

    def test_invert_region(self):
        ev = self.ok("invert")
        self.assertEqual([e["op"] for e in bus(ev)][:2], ["swap", "swap"])


# ---- the references, under a hand driver ------------------------------------------------------------------------------

REFS = [195, 196, 198, 199, 201, 202, 205, 206, 207, 213]
# 206's third call (&cell, &cell, ...) is C UB: two noalias pointers to one object, both written (rulings Q10)
C_OUT_OF_DOMAIN = {206: {2}}
SHIM = """#include <stdint.h>
#include <stdbool.h>
#define T(n, ty) ty cq_theta_##n(ty x, double t) { return x; } ty cq_measure_##n(ty x) { return x; }
T(si32, int32_t) T(ui32, uint32_t) T(ul, uint64_t) T(i1, bool)
void cq_phi(double t) {}
"""


def drivers_row(n):
    for line in (SPEC / "_tools" / "drivers.txt").read_text().splitlines():
        if line.startswith(f"{n}_"):
            return line.split("|")
    raise KeyError(n)


def build_ref(n):
    row = drivers_row(n)
    d = SPEC / "examples" / row[0]
    low, o1 = next(d.glob("*.lowered.ll")), next(d.glob("*.O1.ll"))
    w = Path(WORK.name) / str(n)
    w.mkdir(exist_ok=True)
    stubs = w / "stubs.ll"
    subprocess.run([sys.executable, str(RT / "stubgen.py"), str(low), "--c-module", str(o1), "-o", str(stubs)], check=True)
    # every driver call of drivers.txt, its return value printed: what the own symbol returns
    calls = "".join(f'printf("%lld\\n", (long long)({c}));\n' for c in row[2].split(";") if c.strip())
    (w / "driver.c").write_text(f"#include <stdio.h>\n{row[1]}\nint main(void) {{\n{calls}return 0; }}\n")
    exe = str(w / "prog")
    subprocess.run([CLANG, "-w", "-O1", "-target", TRIPLE, str(w / "driver.c"), str(low), str(stubs), *OBJS, "-o", exe], check=True)
    # the C program on the same calls: cq_theta and cq_measure the identity (the checker's oracle (b), by hand)
    (w / "shim.c").write_text(SHIM)
    cexe = str(w / "cprog")
    subprocess.run([CLANG, "-w", "-O1", "-target", TRIPLE, str(w / "driver.c"), str(o1), str(w / "shim.c"), "-o", cexe], check=True)
    return exe, cexe


class References(unittest.TestCase):
    pass


def _add(n):
    def test(self):
        exe, cexe = build_ref(n)
        p, ev = run_exe(exe)
        c = subprocess.run([cexe], capture_output=True, text=True, timeout=120)
        print(f"{n}: exit {p.returncode}, bus events {len(bus(ev))}, QUANTUM cells {len(cells(ev))}, live {roles_count(ev)}")
        self.assertEqual(p.returncode, 0, p.stderr[-2000:])
        self.assertEqual([e for e in ev if e["ev"] == "violation"], [])
        self.assertEqual(next(e for e in ev if e["ev"] == "exit")["violations"], 0)
        ours, theirs = p.stdout.split(), c.stdout.split()
        print(f"{n}: returns {ours}, C program {theirs}")
        self.assertEqual(c.returncode, 0, c.stderr[-2000:])
        self.assertEqual(len(ours), len(theirs))
        skip = C_OUT_OF_DOMAIN.get(n, ())
        self.assertEqual([v for i, v in enumerate(ours) if i not in skip], [v for i, v in enumerate(theirs) if i not in skip])
    setattr(References, f"test_{n}", test)


def roles_count(ev):
    c = {}
    for r in live(ev):
        c[r["role"]] = c.get(r["role"], 0) + 1
    return c


for _n in REFS:
    _add(_n)

if __name__ == "__main__":
    unittest.main()
