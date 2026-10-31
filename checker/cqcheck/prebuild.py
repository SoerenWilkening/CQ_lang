"""Fill the checker's tool cache ahead of any run (cq-8m6v): `python3 -m cqcheck.prebuild`, run by
`cmake --build` (target cqcheck_tools). It builds what every example shares and nothing an example
owns: the evaluator runtime objects (run.runtime_objects) for the corpus triple, the probe runtime
object (sampling._rt_object) and the C oracle's instrumentation plugin and runtime
(oracle.toolchain). Every one of them is content-keyed, so a run after a source change rebuilds what
changed by itself; this only takes that cost out of the first example's wall time."""
from __future__ import annotations

import sys

CORPUS_TRIPLE = "x86_64-apple-macosx16.0.0"


def main() -> int:
    from cqcheck import native, oracle, run, sampling
    native.lib()
    run.runtime_objects(CORPUS_TRIPLE)
    sampling._rt_object()
    oracle.toolchain()
    return 0


if __name__ == "__main__":
    sys.exit(main())
