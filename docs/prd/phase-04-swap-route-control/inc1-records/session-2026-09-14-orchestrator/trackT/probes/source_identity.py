#!/usr/bin/env python3
"""bd uq96 — PROVE, do not assert, that the `_Bool` axis changed no existing cell.

The file's own discipline for every axis added since the record one: "ALL THREE
default to the pre-C-1 behaviour and every one of the 274 (then 284) older cells
takes it — PROVEN by hashing all generated sources before and after each edit,
not asserted."

Loads the OLD module (from `git show HEAD:tools/loop_twin_matrix.py`, written to
/tmp by the caller) and the NEW one side by side, generates every OLD cell's
rolled and unrolled source on BOTH `cq_phi` surfaces, and compares the bytes.

Usage:  python3 source_identity.py <old.py> <new.py>
"""
import hashlib
import importlib.util
import sys


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    sys.modules[name] = m
    spec.loader.exec_module(m)
    return m


def main(argv):
    old = load(argv[1], "ltm_old")
    new = load(argv[2], "ltm_new")
    ocells = old.cells_of_matrix()
    ncells = new.cells_of_matrix()
    oname = {old.cell_name(c): c for c in ocells}
    nname = {new.cell_name(c): c for c in ncells}
    print("OLD cells %d   NEW cells %d   added %d"
          % (len(ocells), len(ncells), len(ncells) - len(ocells)))
    missing = sorted(set(oname) - set(nname))
    if missing:
        print("FAIL: %d OLD cell(s) missing from NEW: %s"
              % (len(missing), ", ".join(missing[:10])))
        return 1
    bad = []
    for surface in ("register", "void"):
        for n, c in sorted(oname.items()):
            o = old.sources(*c, surface=surface)
            w = new.sources(*nname[n], surface=surface)
            if o != w:
                bad.append((surface, n))
    if bad:
        print("FAIL: %d (surface, cell) source pairs CHANGED:" % len(bad))
        for s, n in bad[:20]:
            print("   %-8s %s" % (s, n))
        return 1
    # One digest over everything, so the record can quote a number.
    h = hashlib.sha256()
    for surface in ("register", "void"):
        for n in sorted(oname):
            for t in new.sources(*nname[n], surface=surface):
                h.update(t.encode())
    print("PASS: all %d OLD cells x 2 surfaces x 2 sides are BYTE-IDENTICAL"
          % len(oname))
    print("      sha256 over the %d old-cell texts: %s"
          % (len(oname) * 4, h.hexdigest()[:32]))
    added = sorted(set(nname) - set(oname))
    print("      %d NEW cell name(s): %s" % (len(added), ", ".join(added)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
