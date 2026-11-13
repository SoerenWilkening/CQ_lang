#!/usr/bin/env python3
"""cq-p9pty task B: cachegc.prune removes the cache entries not used for $CQCHECK_CACHE_DAYS days, keeps the rest,
and a cache hit marks its entry used. Every cache is a temporary directory: never the checkout's build/."""
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "checker"))

DAY = 86400.0


def age(p: Path, seconds: float) -> None:
    t = time.time() - seconds
    os.utime(p, (t, t))


class Prune(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="cq-cachegc-")
        t = Path(self.tmp.name)
        self.env = {"CQE_CACHE": str(t / "cache"), "CQ_SAMPLES_CACHE": str(t / "samples"),
                    "CQ_BUILD_DIR": str(t / "build"), "CQCHECK_CACHE_DAYS": None}
        self.saved = {k: os.environ.get(k) for k in self.env}
        for k, v in self.env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        self.root = t

    def tearDown(self):
        for k, v in self.saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        self.tmp.cleanup()

    def entry(self, rel: str, days: float, is_dir: bool = True) -> Path:
        p = self.root / rel
        if is_dir:
            (p / "sub").mkdir(parents=True)
            (p / "sub" / "f").write_text("x")
            (p / "prog").write_text("x")
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("x")
        age(p, days * DAY)
        return p

    def test_prune(self):
        from cqcheck import cachegc
        old = [self.entry("cache/prog/aaa", 3), self.entry("cache/drv/a.ll", 3, False),
               self.entry("cache/verify/v1", 5), self.entry("cache/runs/eval/ab/ab12.jsonl.z", 3, False),
               self.entry("samples/x.123.json", 3, False), self.entry("samples/probe/p1", 3, False),
               self.entry("build/oracle/exe/e-1", 3), self.entry("build/oracle/prog/p-1", 3),
               self.entry("build/oracle/tool-old", 3)]
        keep = [self.entry("cache/prog/bbb", 1), self.entry("cache/drv/b.ll", 0.5, False),
                self.entry("cache/runs/oracle/cd/cd34.jsonl.z", 1.9, False), self.entry("samples/y.1.json", 0, False),
                self.entry("build/oracle/exe/e-2", 1), self.entry("build/oracle/tool-new", 0)]
        # an old entry below an entry is the entry's own content: only the entry's mtime counts
        inner = self.root / "cache/prog/bbb/sub/f"
        age(inner, 30 * DAY)
        # a directory of the build root that is not a cache
        other = self.entry("build/oracle/other", 30)
        # dead tombstone (a killed pruner): removed whatever its age; a live pruner's young one: kept
        dead = subprocess.Popen(["true"])
        dead.wait()
        tomb_dead = self.entry(f"cache/prog/.cqgc.{dead.pid}.zzz", 0)
        tomb_live = self.entry(f"cache/prog/.cqgc.{os.getpid()}.yyy", 0)
        gone = cachegc.prune(force=True)
        self.assertEqual(sorted(gone), sorted(old + [tomb_dead]))
        for p in old + [tomb_dead]:
            self.assertFalse(p.exists(), p)
        for p in keep + [inner, other, tomb_live]:
            self.assertTrue(p.exists(), p)
        self.assertFalse([p for p in (self.root / "cache/prog").iterdir() if p.name.startswith(".cqgc.") and
                          p != tomb_live])

        # once per process; the stamp keeps another process from pruning within the hour
        self.entry("cache/prog/ccc", 3)
        self.assertEqual(cachegc.prune(), [])
        self.assertTrue((self.root / "cache" / cachegc.STAMP).exists())

    def test_days_and_min_age(self):
        from cqcheck import cachegc
        os.environ["CQCHECK_CACHE_DAYS"] = "off"
        self.assertIsNone(cachegc.max_age())
        os.environ["CQCHECK_CACHE_DAYS"] = "0"
        self.assertIsNone(cachegc.max_age())
        p = self.entry("cache/prog/old", 100)
        self.assertEqual(cachegc.prune(force=True), [])
        self.assertTrue(p.exists())
        os.environ["CQCHECK_CACHE_DAYS"] = "0.001"            # below MIN_AGE: MIN_AGE holds
        self.assertEqual(cachegc.max_age(), cachegc.MIN_AGE)
        young = self.entry("cache/prog/young", 1 / 24)
        os.environ["CQCHECK_CACHE_DAYS"] = "10"
        self.assertEqual(cachegc.prune(force=True), [p])
        os.environ["CQCHECK_CACHE_DAYS"] = "0.001"
        self.assertEqual(cachegc.prune(force=True), [])
        self.assertTrue(young.exists())

    def test_hit_marks_used(self):
        from cqcheck import cachegc, run
        p = self.entry("cache/runs/eval/ab/k.jsonl.z", 3, False)
        key = ["k"]
        p2 = run._runs_path("eval", key)
        run.save_runs("eval", key, [{"a": 1}])
        age(p2, 3 * DAY)
        self.assertEqual(run.load_runs("eval", key), [{"a": 1}])     # a hit: used now
        gone = cachegc.prune(force=True)
        self.assertIn(p, gone)
        self.assertNotIn(p2, gone)
        self.assertTrue(p2.exists())


if __name__ == "__main__":
    unittest.main()
