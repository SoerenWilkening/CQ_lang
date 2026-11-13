#!/usr/bin/env python3
"""cq-jp8qu: the hand-made mutant of a lowered printf("...%n...") module. In every lowered printf_core (each clone, each
of rule 14's K copies) musl's `case 'n'` BARE store `*(int *)arg.p = cnt` is the first i32 bus store after the
conversion test against 'n' (110); the mutant stores cnt + 1 there (a template, its uncomputation and the free, so the
mutant is clean and only the stored count changes). Usage: percent_n_mutant.py <lowered.ll> <mutant.ll>; prints the
number of stores changed (exit 1 when none)."""
import re
import sys

STORE = re.compile(r"^  call void @cqrt_qram_store_i32(_hl)?(_controlled)?\((.*), i32 (%[\w.]+)\)$")
FN = re.compile(r"^define [^@]*@([\w.$]+)\(")


def mutate(lines):
    out, fn, armed, n = [], None, 0, 0
    for s in lines:
        m = FN.match(s)
        if m:
            fn, armed = m.group(1), 0
        if fn and "printf_core" in fn and re.search(r"@cq_template_icmp_eq_i32_hl(_unc)?\(.*, i32 110\)$", s):
            armed = 16
        elif armed:
            armed -= 1
            st = STORE.match(s)
            if st:
                v, t = st.group(4), f"%cq_mut{n}"
                out += [f"  {t} = call i32 @cq_template_add_i32_hl(i32 {v}, i32 1)",
                        s[: s.rindex(v)] + t + ")",
                        f"  call void @cq_template_add_i32_hl_unc(i32 {t}, i32 {v}, i32 1)",
                        f"  call void @cqrt_free(i32 {t})"]
                n, armed = n + 1, 0
                continue
        out.append(s)
    text = "\n".join(out)
    for d in ("declare i32 @cq_template_add_i32_hl(i32, i32)", "declare void @cq_template_add_i32_hl_unc(i32, i32, i32)",
              "declare void @cqrt_free(i32)"):
        if d not in text:
            text += "\n" + d + "\n"
    return text, n


if __name__ == "__main__":
    text, n = mutate(open(sys.argv[1]).read().split("\n"))
    open(sys.argv[2], "w").write(text)
    print(n)
    sys.exit(0 if n else 1)
