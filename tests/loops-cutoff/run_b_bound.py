#!/usr/bin/env python3
"""tests/loops-cutoff cq-zge7: a clone's _b bound below SCEV's constant maximum trip count (CR §1.4, rule 14).

For probes/b_bound_i32.O1.ll it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - the _b3 clone of f runs min(K, 3) = 3 trips with no received K (@__cq_k all ones) and frees every rail it defines
    but the one it returns (its a_3 included: B = 3 < K keeps no a_K), a freed phi freeing what it merges and a freed
    pop the value its push saved; only a_K's copy on a received-K cut path is kept (cq-9kcq, cq-dav);
  - the _b7 clone runs K = 4 trips.
  A trip count is read from the lowered CFG, the same in both forms of a K-loop (cq-9kcq): a forward mul template
  outside any cycle is one trip; one inside a cycle runs once per trip of that cycle's classical counter
  (`j' = j + 1; br (j' < N)`), N evaluated with @__cq_k all ones.
  - bb_i32 is §6-equal to its own C program (`python3 -m cqcheck user`, the C oracle).
Outputs go to build/tests/loops-cutoff/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBE = Path(__file__).parent / "probes" / "b_bound_i32.O1.ll"


def body(module: str, fn: str) -> str:
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", module, re.S | re.M)
    return m.group(0) if m else ""


def blocks(fn_body: str):
    """{label: (instruction lines, successor labels)} of one lowered function, and the labels in text order."""
    out, order = {}, []
    for line in fn_body.splitlines()[1:]:
        m = re.match(r"^([-\w.$]+):", line)
        if m or not order:
            order.append(m.group(1) if m else "<entry>")
            out[order[-1]] = ([], [])
            if m:
                continue
        if line.startswith("}"):
            break
        if line.strip():
            out[order[-1]][0].append(line)
            out[order[-1]][1].extend(re.findall(r"label %([-\w.$]+)", line))
    return out, order


def reach(bl, frm):
    seen, todo = set(), list(bl[frm][1])
    while todo:
        x = todo.pop()
        if x not in seen and x in bl:
            seen.add(x)
            todo.extend(bl[x][1])
    return seen


def defs(fn_body: str):
    return {m.group(1): m.group(2) for m in re.finditer(r"^\s*(%[-\w.$]+) = (.*)$", fn_body, re.M)}


def value(d, v: str, depth=0):
    """The integer v holds with no received K (@__cq_k = -1, owner ruling Q2: -1 is "none"), or None."""
    if re.fullmatch(r"-?\d+", v):
        return int(v)
    rhs = d.get(v)
    if rhs is None or depth > 32:
        return None
    if re.fullmatch(r"load i32, ptr @__cq_k(?:, align \d+)?", rhs):
        return -1
    m = re.fullmatch(r"icmp (eq|ne|ult|slt) i32 (\S+), (\S+)", rhs)
    if m:
        a, b = value(d, m.group(2), depth + 1), value(d, m.group(3), depth + 1)
        if a is None or b is None:
            return None
        u = lambda x: x & 0xFFFFFFFF
        return int({"eq": a == b, "ne": a != b, "ult": u(a) < u(b), "slt": a < b}[m.group(1)])
    m = re.fullmatch(r"select i1 (\S+), i32 (\S+), i32 (\S+)", rhs)
    if m:
        c = value(d, m.group(1), depth + 1)
        return None if c is None else value(d, m.group(2) if c else m.group(3), depth + 1)
    m = re.fullmatch(r"(?:tail )?call i32 @llvm\.umin\.i32\(i32 (\S+), i32 (\S+)\)", rhs)
    if m:
        a, b = value(d, m.group(1), depth + 1), value(d, m.group(2), depth + 1)
        return None if a is None or b is None else min(a & 0xFFFFFFFF, b & 0xFFFFFFFF)
    return None


def trips(fn_body: str, site: str):
    """How many times the forward calls matching site run with no received K, from the CFG: a call outside every cycle
    once; a call in a cycle once per trip of the cycle's classical counter (`%j1 = add i32 %j, 1`, `%j` a phi starting
    at 0, `br i1 (icmp ult i32 %j1, N)` back into the cycle). None where a cycle has no such counter or N is unknown."""
    bl, order = blocks(fn_body)
    d = defs(fn_body)
    n = 0
    for lab in order:
        k = sum(len(re.findall(site, l)) for l in bl[lab][0])
        if not k:
            continue
        r = reach(bl, lab)
        if lab not in r:
            n += k
            continue
        cyc = {x for x in r if lab in reach(bl, x)} | {lab}
        bound = None
        for x in cyc:
            for l in bl[x][0]:
                m = re.match(r"^\s*br i1 (%[-\w.$]+), label %([-\w.$]+), label %([-\w.$]+)", l)
                if not m or m.group(2) not in cyc or m.group(3) in cyc:
                    continue
                c = re.fullmatch(r"icmp ult i32 (%[-\w.$]+), (\S+)", d.get(m.group(1), ""))
                j = c and re.fullmatch(r"add (?:nuw )?(?:nsw )?i32 (%[-\w.$]+), 1", d.get(c.group(1), ""))
                if j and re.fullmatch(r"phi i32 .*\[ 0, %[-\w.$]+ \].*", d.get(j.group(1), "")):
                    bound = value(d, c.group(2))
        if bound is None:
            return None
        n += k * bound
    return n


def received_k_cut(fn_body: str, lab: str) -> bool:
    """Whether block lab is entered only from a conditional br whose condition reads the received K (a load of @__cq_k,
    or a table clone's K parameter, the last one): the received-K cut's path."""
    bl, order = blocks(fn_body)
    d = defs(fn_body)
    params = re.findall(r"i32 (%[-\w.$]+)", fn_body.splitlines()[0])
    tableK = params[-1] if "_t" in fn_body.splitlines()[0].split("(")[0] and params else None
    preds = [x for x in order if lab in bl[x][1]]

    def reads_k(v, depth=0):
        if v == tableK:
            return True
        rhs = d.get(v)
        if rhs is None or depth > 32:
            return False
        return "@__cq_k" in rhs or any(reads_k(o, depth + 1) for o in re.findall(r"%[-\w.$]+", rhs))
    if not preds:
        return False
    for x in preds:
        m = re.match(r"^\s*br i1 (%[-\w.$]+),", bl[x][0][-1])
        if not m or not reads_k(m.group(1)):
            return False
    return True


def kept_rails(c3: str):
    """The rails a clone defines and keeps: not freed, not returned, not a_K's copy on a received-K cut path."""
    ret = re.search(r"^\s*ret i32 (%\d+)", c3, re.M)
    defined = re.findall(r"^\s*(%\d+) = call i32 @(?:cqrt_alloc|cq_template)\w*\(", c3, re.M)
    freed = set(re.findall(r"@cqrt_free\(i32 (%\d+)\)", c3))
    # A freed (or returned) phi frees each rail it merges (the received-K cut's joins, cq-9kcq).
    phis = {m.group(1): re.findall(r"\[ (%\d+), %[\w.]+ \]", m.group(2))
            for m in re.finditer(r"^\s*(%\d+) = phi i32 (.*)$", c3, re.M)}
    # A freed pop frees what its push saved: a cycle's pushes are popped in reverse order by the reverse loop
    # (cq-9kcq, the rolled form; the copy form has no push in a K-loop).
    pushes = re.findall(r"@cqrt_push\(i32 (%[-\w.$]+)\)", c3)
    pops = re.findall(r"^\s*(%[-\w.$]+) = call i32 @cqrt_pop\(\)", c3, re.M)
    if len(pushes) == len(pops):
        for po, pu in zip(pops, reversed(pushes)):
            phis.setdefault(po, []).append(pu)
    grew = True
    while grew:
        grew = False
        for p, ins in phis.items():
            if p in freed or (ret and p == ret.group(1)):
                for i in ins:
                    if i not in freed:
                        freed.add(i)
                        grew = True
    # cq-9kcq, cq-dav (CR rule 27 "Cutoff"): a_K's copy made on a received-K cut path (fresh |0>, copy_i1, the cut's
    # branch to its join, in a block entered only by a branch on the received K) is kept there, where the received K
    # is below 3; nothing else is (B = 3 <= K).
    cut = {m.group(2) for m in re.finditer(r"^([-\w.$]+):[^\n]*\n\s*(%\d+) = call i32 @cqrt_alloc_i1\(i1 false\)\n"
                                           r"\s*call void @cqrt_copy_i1\(i32 %\d+, i32 \2\)\n\s*br label", c3, re.M)
           if received_k_cut(c3, m.group(1))}
    kept = [d for d in defined if d not in freed and d not in cut and (not ret or d != ret.group(1))]
    return kept


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    a = ap.parse_args()
    out = ROOT / "build" / "tests" / "loops-cutoff" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / "b_bound_i32.lowered.ll"
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(PROBE), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print("FAIL cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
        return 1
    mod = lowered.read_text()
    why = []
    b3 = re.search(r"^define [^\n]*@(__cq_q_f_[01]+_b3_\d+)\(", mod, re.M)
    b7 = re.search(r"^define [^\n]*@(__cq_q_f_[01]+_b7_\d+)\(", mod, re.M)
    if not b3 or not b7:
        why.append("no _b3 or _b7 clone of f")
    else:
        c3, c7 = body(mod, b3.group(1)), body(mod, b7.group(1))
        n3 = trips(c3, r"@cq_template_mul_i32_hl\(")
        n7 = trips(c7, r"@cq_template_mul_i32_hl\(")
        if n3 != 3:
            why.append(f"the _b3 clone runs {n3} trips, not 3")
        if n7 != 4:
            why.append(f"the _b7 clone runs {n7} trips, not K = 4")
        kept = kept_rails(c3)
        if kept:
            why.append("the _b3 clone keeps " + ", ".join(kept))
    c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(PROBE), "--lowered", str(lowered),
                        "--entry", "bb_i32"], capture_output=True, text=True, cwd=ROOT / "checker")
    if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
        why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
    print(("FAIL " if why else "ok   ") + "bb_i32" + ("" if not why else ": " + "; ".join(why)))
    return 1 if why else 0


if __name__ == "__main__":
    sys.exit(main())
