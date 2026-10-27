#!/usr/bin/env python3
"""Generate the native side of the tmpl-int differential test (cq-w0-tmpl-int).

Writes two files:
  native.ll   one function per (op, width[, to]) doing the LLVM IR operation itself, compiled by
              clang-19 -O1 for x86_64-apple-macosx and run on the host;
  cases.inc   the C table the harness iterates over.

Every native function has the signature void(const uint64_t *a, const uint64_t *b, uint64_t *o).
Integers live in memory zero-extended to whole 64-bit words; fp values are loaded and stored as
their own IR type (the harness zero-fills o first).

The CR §2 rows where native LLVM is undefined (udiv/urem/sdiv/srem by 0, sdiv/srem INT_MIN by -1)
are written into the native function as explicit selects, so the native side computes the §2 table
on those inputs and plain LLVM everywhere else. The harness additionally checks those rows against
literal table values.
"""
import argparse

# Every corpus integer width (BACKEND_ABI §0: i1 i7 i8 i16 i32 i64 i80 i100 i128) plus odd widths
# around word boundaries and two wider than the corpus, to exercise the generic code.
WIDTHS = [1, 2, 3, 7, 8, 16, 31, 32, 33, 63, 64, 65, 80, 100, 127, 128, 129, 192, 256]
# and/or/xor belong to tmpl-bits (owner ruling, bead cq-f69); tests/tmpl-bits covers them.
BINOPS = ["add", "sub", "mul", "udiv", "sdiv", "urem", "srem"]
FPTY = {16: "half", 32: "float", 64: "double", 80: "x86_fp80"}


def cont(bits):
    return 64 * ((bits + 63) // 64)


def load_int(name, ptr, n, out):
    c = cont(n)
    out.append(f"  %{name}.c = load i{c}, ptr %{ptr}, align 8")
    if c == n:
        return f"%{name}.c"
    out.append(f"  %{name} = trunc i{c} %{name}.c to i{n}")
    return f"%{name}"


def store_int(val, n, out):
    c = cont(n)
    if c != n:
        out.append(f"  %r.c = zext i{n} {val} to i{c}")
        val = "%r.c"
    out.append(f"  store i{c} {val}, ptr %po, align 8")


def binop_fn(op, n):
    t = f"i{n}"
    mn = -(1 << (n - 1))
    body = []
    a = load_int("a", "pa", n, body)
    b = load_int("b", "pb", n, body)
    if op in ("add", "sub", "mul"):
        body.append(f"  %r = {op} {t} {a}, {b}")
    elif op in ("udiv", "urem"):
        body += [
            f"  %z = icmp eq {t} {b}, 0",
            f"  %bs = select i1 %z, {t} 1, {t} {b}",
            f"  %q = {op} {t} {a}, %bs",
            # udiv(a,0) = 2^W-1, urem(a,0) = a
            f"  %r = select i1 %z, {t} {'-1' if op == 'udiv' else a}, {t} %q",
        ]
    else:  # sdiv, srem
        body += [
            f"  %z = icmp eq {t} {b}, 0",
            f"  %amin = icmp eq {t} {a}, {mn}",
            f"  %bm1 = icmp eq {t} {b}, -1",
            "  %ovf = and i1 %amin, %bm1",
            "  %bad = or i1 %z, %ovf",
            f"  %as = select i1 %bad, {t} 0, {t} {a}",
            f"  %bs = select i1 %bad, {t} 1, {t} {b}",
            f"  %q = {op} {t} %as, %bs",
        ]
        if op == "sdiv":
            body += [
                f"  %neg = icmp slt {t} {a}, 0",
                f"  %zv = select i1 %neg, {t} 1, {t} -1",  # sdiv(a,0) = a>=0 ? -1 : +1
                f"  %t = select i1 %ovf, {t} {mn}, {t} %q",  # INT_MIN/-1 = INT_MIN
                f"  %r = select i1 %z, {t} %zv, {t} %t",
            ]
        else:
            body += [
                f"  %t = select i1 %ovf, {t} 0, {t} %q",  # INT_MIN rem -1 = 0
                f"  %r = select i1 %z, {t} {a}, {t} %t",  # srem(a,0) = a
            ]
    store_int("%r", n, body)
    name = f"n_{op}_i{n}"
    return name, (f"define void @{name}(ptr %pa, ptr %pb, ptr %po) {{\n"
                  + "\n".join(body) + "\n  ret void\n}\n")


def cast_fn(op, fk, fb, tk, tb):
    body = []
    if fk == "i":
        a = load_int("a", "pa", fb, body)
        fty = f"i{fb}"
    else:
        fty = FPTY[fb]
        body.append(f"  %a = load {fty}, ptr %pa, align 8")
        a = "%a"
    tty = f"i{tb}" if tk == "i" else FPTY[tb]
    body.append(f"  %r = {op} {fty} {a} to {tty}")
    if tk == "i":
        store_int("%r", tb, body)
    else:
        body.append(f"  store {tty} %r, ptr %po, align 8")
    name = f"n_{op}_{fk}{fb}_to_{tk}{tb}"
    return name, (f"define void @{name}(ptr %pa, ptr %pb, ptr %po) {{\n"
                  + "\n".join(body) + "\n  ret void\n}\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ll", required=True)
    ap.add_argument("--inc", required=True)
    args = ap.parse_args()

    fns, rows = [], []
    shapes = ["", "hl", "lh", "hh"]  # semantics never depend on the shape letters
    for i, n in enumerate(WIDTHS):
        for j, op in enumerate(BINOPS):
            name, text = binop_fn(op, n)
            fns.append(text)
            rows.append((op, f"i{n}", "", shapes[(i + j) % len(shapes)], 2, "i", n, "i", n, name))
    for op in ("zext", "sext"):
        for fb in WIDTHS:
            for tb in WIDTHS:
                if tb > fb:
                    name, text = cast_fn(op, "i", fb, "i", tb)
                    fns.append(text)
                    rows.append((op, f"i{fb}", f"i{tb}", "", 1, "i", fb, "i", tb, name))
    for fb in WIDTHS:
        for tb in WIDTHS:
            if tb < fb:
                name, text = cast_fn("trunc", "i", fb, "i", tb)
                fns.append(text)
                rows.append(("trunc", f"i{fb}", f"i{tb}", "", 1, "i", fb, "i", tb, name))
    bitcasts = [("i", n, "i", n) for n in WIDTHS]
    for fb in FPTY:
        bitcasts += [("f", fb, "i", fb), ("i", fb, "f", fb), ("f", fb, "f", fb)]
    for fk, fb, tk, tb in bitcasts:
        name, text = cast_fn("bitcast", fk, fb, tk, tb)
        fns.append(text)
        rows.append(("bitcast", f"{fk}{fb}", f"{tk}{tb}", "", 1, fk, fb, tk, tb, name))

    with open(args.ll, "w") as f:
        f.write("; generated by tests/tmpl-int/gen_native.py; do not edit\n")
        f.write("\n".join(fns))
    with open(args.inc, "w") as f:
        f.write("/* generated by tests/tmpl-int/gen_native.py; do not edit */\n")
        for r in rows:
            f.write(f"void {r[9]}(const uint64_t *, const uint64_t *, uint64_t *);\n")
        f.write("static const case_t CASES[] = {\n")
        for op, w, to, shape, ar, fk, fb, tk, tb, name in rows:
            f.write(f'  {{"{op}", "{w}", "{to}", "{shape}", {ar}, \'{fk}\', {fb}, \'{tk}\', {tb}, {name}}},\n')
        f.write("};\n")


if __name__ == "__main__":
    main()
