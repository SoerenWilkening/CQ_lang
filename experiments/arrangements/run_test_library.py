# Runs check_driver.py's test_library alone. usage: python3 run_test_library.py <worktree> <build dir>
import os, sys, tempfile
from pathlib import Path
W, B = Path(sys.argv[1]), Path(sys.argv[2])
sys.path.insert(0, str(W / "tests" / "driver"))
os.environ["CQ_BUILD_DIR"] = str(B)
import check_driver as d
d.ENV = dict(os.environ, CQ_PLUGIN=str(B / "pass" / "libCQLower.so"), CQ_SPEC_DIR=str(W / "spec"))
with tempfile.TemporaryDirectory(prefix="cq-lib-test.") as t:
    d.test_library(Path(t))
print(f"{len(d.failures)} failure(s)")
