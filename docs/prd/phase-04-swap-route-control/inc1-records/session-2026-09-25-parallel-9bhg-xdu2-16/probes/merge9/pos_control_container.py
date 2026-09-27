#!/usr/bin/env python3
"""Positive control for spec_accept_fp_rebuilt_site_second_clone.ll's three-mode pin:
disable `Set::Core::keyDeleted`'s dead-mark in ScrubOnDelete.h (a deleted key then
SURVIVES in every Set table, the pre-8e5r behaviour), rebuild cq-opt AND
cq-opt-debugalloc, run the fixture through lit 3 times, report, restore, rebuild,
and print the restored hashes (must equal the pre-mutation ones)."""
import hashlib
import pathlib
import re
import shutil
import subprocess

W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
H = W / "ir-pass/include/ScrubOnDelete.h"
SAVE = pathlib.Path(__file__).with_name("ScrubOnDelete.h.pristine")
OLD = ("      if (S.count(toStore(static_cast<KeyArg>(V))))\n"
       "        Dead.insert(V);\n"
       "    }\n"
       "    bool dead(const llvm::Value *V) const { return !Dead.empty() && Dead.count(V); }\n"
       "  };\n"
       "  std::unique_ptr<Core> C;\n\n"
       "  static PtrT toStore(KeyArg V) { return const_cast<PtrT>(V); }")
NEW = OLD.replace("        Dead.insert(V);\n", "        (void)V;  // MUTANT: no dead-mark\n")


def h(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


def build():
    r = subprocess.run(["cmake", "--build", str(W / "build"), "--target", "cq-opt",
                        "cq-opt-debugalloc", "-j8"], capture_output=True, text=True)
    return r.returncode == 0


bins = [W / "build/ir-pass/cq-opt", W / "build/ir-pass/cq-opt-debugalloc"]
before = [h(b) for b in bins]
src = H.read_text()
assert src.count(OLD) == 1, f"pattern count {src.count(OLD)}"
shutil.copyfile(H, SAVE)
try:
    H.write_text(src.replace(OLD, NEW))
    assert build(), "mutant build failed"
    print("mutant hashes:", [h(b) for b in bins])
    for i in range(3):
        r = subprocess.run(["lit", "-s", "ir-pass/test", "--filter",
                            "fp_rebuilt_site_second_clone"], cwd=W / "build",
                           capture_output=True, text=True)
        m = re.search(r"(Passed|Failed)\s*:\s*(\d+)", r.stdout)
        print(f"  mutant lit run {i + 1}: {m.group(0) if m else r.stdout[-300:]}")
finally:
    shutil.copyfile(SAVE, H)
    ok = build()
    after = [h(b) for b in bins]
    print("restored; rebuild", "ok" if ok else "FAILED", "hashes", after,
          "IDENTICAL to before" if after == before else f"DIFFER from before {before}")
