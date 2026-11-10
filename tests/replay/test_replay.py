#!/usr/bin/env python3
"""tests/replay (cq-kcn5i): exact clone replay in the evaluator (checker/rt/rt_replay.c, run.py replay_module).

Probes (probes/<name>.c, clang -O1 into <name>.O1.ll) call one eligible clone four times with the same key, so a sample
replays three calls. rp_rec's clone recurses to a quantum depth (the activation counter, its twin called inside the
window), rp_arg's stores under its predicate argument itself (the argument becomes store_kept) and calls a pure helper
of the module. For each:
  same       `cqcheck user` (full samples) with CQE_REPLAY=0 and =1 gives the same verdict (PASS) and the same
             evaluator traces (run without ASLR: noaslr.c, so that addresses agree), and the replay run hit: every event
             byte-identical but the exit event, whose kept list is compared expanded (one (h, w, v, role, known) per
             rail) with its other fields: a replayed call is written as a use of its record's rows, a different cut of
             the same list (Fable ruling 2026-11-09);
  mutants    an in-body mutant of the clone (DESIGN §6: a wrong store address, a dropped kept store, a store under the
             wrong control, a wrong result select) is still rejected with replay on, and the run replayed the mutant;
  tampered   CQE_REPLAY_TAMPER=1 (the first record's first live rail flipped) with every hit spot-checked
             (CQE_REPLAY_CHECK=1) fails with summary_mismatch;
  dirty      a clone body that writes one of its argument rails (an XOR of 0: its value stays) never records and never
             replays, and the verdict is unchanged.
The stale-hash self-check of DESIGN §6 does not apply under owner option (a): there is no verification record, and a
record lives in one sample of one process, whose module cannot change.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
LLVM = Path("/usr/local/opt/llvm@19/bin")


def trace_view(data):
    """A trace as its events: each line but an exit event as its bytes, each exit event as its fields with the kept
    list expanded and sorted (cqcheck.kept)."""
    sys.path.insert(0, str(ROOT / "checker"))
    import io
    from cqcheck import kept as kept_mod, run as run_mod
    out = []
    for line, ev in run_mod._trace_events(io.StringIO(data.decode())):
        if ev is None and line.startswith(run_mod._EXIT_HEAD):   # a short exit line comes whole
            ev = json.loads(line)
            ev["kept"] = kept_mod.build(ev.pop("live"))
        if ev is None:
            out.append(line)
            continue
        kept = sorted((e["h"], e["w"], e["v"], e["role"], e.get("known")) for e in kept_mod.expand(ev.pop("kept")))
        out.append((sorted(ev.items()), kept))
    return out


def fn_edit(text, name, old, new):
    m = re.search(rf"(?ms)^define [^\n]*@{re.escape(name)}\(.*?^}}\n", text)
    assert m, f"no function {name}"
    body = m.group(0)
    assert body.count(old) == 1, f"{name}: {old!r} occurs {body.count(old)} times"
    return text[:m.start()] + body.replace(old, new) + text[m.end():]


class Ctx:
    def __init__(self, plugin, opt, work):
        self.plugin, self.opt, self.work = plugin, opt, work
        self.noaslr = work / "noaslr"
        subprocess.run([str(LLVM / "clang"), "-O1", "-o", str(self.noaslr), str(Path(__file__).parent / "noaslr.c")],
                       check=True)

    def lower(self, probe):
        out = self.work / f"{probe}.lowered.ll"
        subprocess.run([self.opt, f"-load-pass-plugin={self.plugin}", "-passes=cq-lower", "-S",
                        str(PROBES / f"{probe}.O1.ll"), "-o", str(out)], check=True)
        return out

    def user(self, probe, lowered, tag, **env):
        """cqcheck user, full samples; (exit status, output, the run's traces by name, its replay stats summed)."""
        d = self.work / tag
        d.mkdir(parents=True, exist_ok=True)
        e = dict(os.environ, CQCHECK_KEEP_TRACES=str(d / "traces"), CQE_REPLAY_STATS=str(d / "stats.jsonl"),
                 CQCHECK_RUN_WRAPPER=str(self.noaslr), **{k: str(v) for k, v in env.items()})
        r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(PROBES / f"{probe}.O1.ll"), "--lowered",
                            str(lowered), "--entry", probe], cwd=ROOT / "checker", env=e, capture_output=True, text=True)
        traces = {p.name: p.read_bytes() for p in sorted((d / "traces").glob("ours.*"))}
        stats = {}
        if (d / "stats.jsonl").exists():
            for line in (d / "stats.jsonl").read_text().splitlines():
                s = json.loads(line)
                if s["when"] == "exit":
                    for k in ("calls", "hits", "records", "dirty", "checks", "mismatch"):
                        stats[k] = stats.get(k, 0) + s[k]
        return r.returncode, r.stdout + r.stderr, traces, stats


PROBE_NAMES = ["rp_pure", "rp_bus", "rp_sel", "rp_rec", "rp_arg"]

# (id, probe, clone, old text, new text, what the run must say besides FAIL)
MUTANTS = [
    ("store_other_address", "rp_bus", "__cq_q_put_0_ctl", "%8 = getelementptr inbounds i8, ptr %1, i64 2",
     "%8 = getelementptr inbounds i8, ptr %1, i64 1", None),
    ("dropped_kept_store", "rp_bus", "__cq_q_put_0_ctl",
     "  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %3, i64 %9, i32 %7)\n", "", None),
    ("store_wrong_control", "rp_bus", "__cq_q_put_0_ctl",
     "  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %3, i64 %9, i32 %7)\n",
     "  %cqm = call i32 @cqrt_alloc_i1(i1 true)\n  call void @cqrt_qram_store_i8_hl_controlled(i32 %cqm, i32 %3, i64 %9, i32 %7)\n",
     None),
    ("wrong_result_select", "rp_sel", "__cq_q_pick_10", "%6 = call i32 @cq_template_select_i32(i32 %3, i32 %4, i32 %5)",
     "%6 = call i32 @cq_template_select_i32(i32 %3, i32 %5, i32 %4)", None),
    # the extensions: counters and twins inside a window (rp_rec), a store-kept argument and a pure helper (rp_arg)
    ("rec_counter_not_restored", "rp_rec", "__cq_q_chain_10_ctl",
     "  store i32 %18, ptr @__cq_act_chain, align 4\n  ret i32 %16", "  ret i32 %16", None),
    ("rec_wrong_classical_argument", "rp_rec", "__cq_q_chain_10_ctl", "%10 = add nsw i32 %2, 1", "%10 = add nsw i32 %2, 2", None),
    ("arg_store_other_address", "rp_arg", "__cq_q_put_00_ctl", "%16 = ptrtoint ptr %11 to i64", "%16 = ptrtoint ptr %12 to i64", None),
    ("arg_store_wrong_control", "rp_arg", "__cq_q_put_00_ctl",
     "  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %16, i32 %15)\n",
     "  %cqm = call i32 @cqrt_alloc_i1(i1 true)\n  call void @cqrt_qram_store_i8_hl_controlled(i32 %cqm, i32 %8, i64 %16, i32 %15)\n",
     None),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", default=str(LLVM / "opt"))
    ap.add_argument("--only", help="one case: same, mutants, tampered, dirty")
    ap.add_argument("--probe", help="same and mutants: this probe only")
    ap.add_argument("--mutant", help="mutants: this one only")
    a = ap.parse_args()
    bad = []
    with tempfile.TemporaryDirectory(prefix="cq-replay.") as t:
        c = Ctx(a.plugin, a.opt, Path(t))
        low = {p: c.lower(p) for p in PROBE_NAMES}
        if a.only in (None, "same"):
            for p in [p for p in PROBE_NAMES if a.probe in (None, p)]:
                c0, o0, t0, _ = c.user(p, low[p], f"{p}.0", CQE_REPLAY=0)
                c1, o1, t1, s1 = c.user(p, low[p], f"{p}.1", CQE_REPLAY=1)
                same = t0.keys() == t1.keys() and all(trace_view(t0[k]) == trace_view(t1[k]) for k in t0)
                ok = c0 == 0 and c1 == 0 and t0 and same and s1.get("hits", 0) > 0
                print(f"{'ok  ' if ok else 'FAIL'} same {p}: exit {c0}/{c1}, traces {'identical' if same else 'DIFFER'}"
                      f" ({len(t0)} file(s)), replay {s1}", flush=True)
                if not ok:
                    bad.append(f"same {p}")
                    print(o0[-1500:], o1[-1500:])
        if a.only in (None, "mutants"):
            for mid, p, fn, old, new, _ in [m for m in MUTANTS if a.probe in (None, m[1]) and a.mutant in (None, m[0])]:
                m = c.work / f"{mid}.lowered.ll"
                m.write_text(fn_edit(low[p].read_text(), fn, old, new))
                code, out, _, s = c.user(p, m, f"m.{mid}", CQE_REPLAY=1)
                ok = code == 1 and "FAIL" in out and s.get("hits", 0) > 0
                print(f"{'ok  ' if ok else 'FAIL'} mutant {mid}: exit {code}, replay {s}", flush=True)
                if not ok:
                    bad.append(f"mutant {mid}")
                    print(out[-1500:])
        if a.only in (None, "tampered"):
            code, out, _, s = c.user("rp_pure", low["rp_pure"], "tampered", CQE_REPLAY=1, CQE_REPLAY_CHECK=1,
                                     CQE_REPLAY_TAMPER=1)
            ok = code == 1 and "summary_mismatch" in out and s.get("mismatch", 0) > 0
            print(f"{'ok  ' if ok else 'FAIL'} tampered record: exit {code}, replay {s}", flush=True)
            if not ok:
                bad.append("tampered")
                print(out[-1500:])
        if a.only in (None, "dirty"):
            m = c.work / "dirty.lowered.ll"
            text = low["rp_pure"].read_text()
            m.write_text(fn_edit(text, "__cq_q_f_10", "  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)\n",
                                 "  call void @cqrt_xorc_i32(i32 %0, i32 0)\n"
                                 "  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)\n")
                     + "declare void @cqrt_xorc_i32(i32, i32)\n")
            code, out, _, s = c.user("rp_pure", m, "dirty", CQE_REPLAY=1)
            ok = code == 0 and s.get("records", 1) == 0 and s.get("hits", 1) == 0 and s.get("dirty", 0) == s.get("calls", -1) > 0
            print(f"{'ok  ' if ok else 'FAIL'} dirty record: exit {code}, replay {s}", flush=True)
            if not ok:
                bad.append("dirty")
                print(out[-1500:])
    print("tests/replay:", "PASS" if not bad else f"FAIL {bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
