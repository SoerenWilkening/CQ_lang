"""The kept list of a run (RunResult.kept): the exit event's live rails, never one entry per rail (cq-pckdl).

An entry is one of
  - a row: {"h", "w", "v", "role", "known"} for one rail, or with "n" and "step" for the n rails h, h + step, ...,
    h + (n - 1) * step, all of one width, value, role and known flag;
  - a pattern: {"pat": [rows], "at": [uses]} or {"pat": [rows], "at": [uses], "skip": [[b, [rel, ...]], ...]}: a use
    is a base b or a run [b, n, step] of the bases b, b + step, ..., b + (n - 1) * step (ascending by b); for each
    base the pattern's rows with every handle moved by it, less the rails at the relative handles that "skip" lists
    for the use that starts at b (each base of a run alike). rt/core.c at_exit_handler writes a stretch of rails that
    recurs once in full and then by reference, and a replayed call as a use of its record's rows (a replayed
    snprintf left 145M live rails at exit, cq-kcn5i); a skipped rail is one the caller touched, written as a row of
    its own or not at all.
No handle is in two places. A reader goes through leaves(): (row, uses) pairs, uses None for a row of its own and
a Uses for a pattern's row; the pair stands for count(row, uses) rails that share the row's width, value, role and
known flag (a pattern row none of whose rails is left is not a leaf). A reader that
needs one rail at a time asks KeptIndex for it, or expands only the pairs it selects first (rails); nothing but
the reference's kept multiset (compare._kept_rows, CQ_spec examples) expands every entry of a run.

run.py builds the list from the exit event's entries (build): rows, {"def": id, "rows": [...]} (a pattern's rows,
handles relative to its first rail) and {"use": id, "h": b} or {"use": id, "h": b, "n": n, "step": s} (the pattern
at b, b + s, ...), either with "skip": [rel, ...] (those rails of the pattern left out at each of its bases).
"""
from __future__ import annotations

import bisect
from typing import Any, Dict, Iterable, Iterator, List, Optional, Sequence, Tuple

Row = Dict[str, Any]


class Builder:
    """The kept list of one exit event, from its entries one at a time."""

    def __init__(self) -> None:
        self.rows: List[Row] = []
        self.pats: Dict[Any, Row] = {}
        self.order: List[Row] = []
        self.strs: Dict[str, str] = {}

    def _own(self, e: Row) -> Row:
        """e with its width, value and role strings shared with every other entry's (a run keeps 10^5 rows)."""
        for f in ("w", "v", "role"):
            x = e.get(f)
            if isinstance(x, str):
                e[f] = self.strs.setdefault(x, x)
        return e

    def add(self, e: Row) -> None:
        if "pat" in e:                       # a pattern entry of a list built before (a cached run)
            p = {"pat": e["pat"], "at": list(e["at"])}
            if e.get("skip"):
                p["skip"] = list(e["skip"])
            self.order.append(p)
        elif "def" in e:
            p = {"pat": [self._own(r) for r in e["rows"]], "at": []}
            self.pats[e["def"]] = p
            self.order.append(p)
        elif "use" in e:
            p = self.pats[e["use"]]
            n = e.get("n", 1)
            p["at"].append([e["h"], n, e["step"]] if n > 1 else e["h"])   # a run stays a run, never its bases
            if e.get("skip"):
                p.setdefault("skip", []).append([e["h"], sorted(e["skip"])])
        else:
            self.rows.append(self._own(e))

    def kept(self) -> List[Row]:
        for p in self.order:
            p["at"].sort(key=_start)
            if "skip" in p:
                p["skip"].sort(key=lambda t: t[0])
        return sorted(self.rows, key=lambda e: e["h"]) + [p for p in self.order if p["at"]]


def build(entries: Iterable[Row]) -> List[Row]:
    b = Builder()
    for e in entries:
        b.add(e)
    return b.kept()


def _start(u: Any) -> int:
    return u if isinstance(u, int) else u[0]


def _run(u: Any) -> Tuple[int, int, int]:
    """A use as (first base, number of bases, step)."""
    return (u, 1, 1) if isinstance(u, int) else (u[0], u[1], u[2])


class Uses:
    """The bases of one pattern (its "at" and "skip"), as leaves() hands them to count, handles and rails."""

    __slots__ = ("at", "skip", "n", "skipped")

    def __init__(self, at: Sequence[Any], skip: Optional[Sequence[Any]] = None):
        self.at = at
        self.skip: Dict[int, frozenset] = {b: frozenset(rels) for b, rels in (skip or [])}
        self.n = sum(_run(u)[1] for u in at)
        self.skipped: Dict[int, int] = {}     # relative handle -> how many bases leave it out
        for u in at:
            rels = self.skip.get(_start(u))
            if rels:
                for o in rels:
                    self.skipped[o] = self.skipped.get(o, 0) + _run(u)[1]

    def __len__(self) -> int:
        return self.n

    def __iter__(self) -> Iterator[int]:
        for u in self.at:
            b, n, st = _run(u)
            yield from range(b, b + n * st, st)

    def runs(self) -> Iterator[Tuple[int, int, int, frozenset]]:
        """Each use as (first base, number of bases, step, the relative handles it leaves out)."""
        for u in self.at:
            b, n, st = _run(u)
            yield b, n, st, self.skip.get(b, frozenset())


def uses_of(e: Row) -> Uses:
    return Uses(e["at"], e.get("skip"))


def _uses(at: Any) -> Uses:
    return at if isinstance(at, Uses) else Uses(at)


def leaves(kept: Optional[Sequence[Row]]) -> Iterator[Tuple[Row, Optional[Uses]]]:
    for e in kept or []:
        if not isinstance(e, dict):
            continue
        if "pat" in e:
            u = uses_of(e)
            for r in e["pat"]:
                if not u.skipped or count(r, u):
                    yield r, u
        else:
            yield e, None


def count(row: Row, at: Optional[Any] = None) -> int:
    if at is None:
        return row.get("n", 1)
    u = _uses(at)
    n = row.get("n", 1) * len(u)
    if u.skipped:
        offs = _offsets(row)
        n -= sum(m for o, m in u.skipped.items() if o in offs)
    return n


def _offsets(row: Row) -> range:
    n = row.get("n", 1)
    st = row.get("step", 0) if n > 1 else 1
    return range(row["h"], row["h"] + n * st, st)


def handles(row: Row, at: Optional[Any] = None) -> Iterator[int]:
    if at is None:
        yield from _offsets(row)
        return
    offs = _offsets(row)
    for b0, n, st, sk in _uses(at).runs():
        for b in range(b0, b0 + n * st, st):
            for o in offs:
                if o not in sk:
                    yield b + o


def rail(row: Row, h: int) -> Row:
    """The entry of rail h of `row`, as a row of one rail."""
    if "n" not in row and row["h"] == h:
        return row
    one = {k: v for k, v in row.items() if k not in ("n", "step")}
    one["h"] = h
    return one


def rails(row: Row, at: Optional[Any] = None) -> Iterator[Row]:
    """The rails of one leaf, one entry each."""
    if at is None and "n" not in row:
        yield row
        return
    for h in handles(row, at):
        yield rail(row, h)


def holds(row: Row, h: int) -> bool:
    n = row.get("n", 1)
    if n <= 1:
        return row["h"] == h
    d = h - row["h"]
    st = row["step"]
    return d >= 0 and d % st == 0 and d // st < n


def split(row: Row, picks: Dict[int, Row]) -> List[Row]:
    """A row (no pattern) with each rail h of `picks` (handle -> its own entry) cut out as that entry: the rows before,
    between and after keep their run form."""
    hs = sorted(h for h in picks if holds(row, h))   # a pick of None: the rail is left out
    if not hs:
        return [row]
    st = row.get("step", 0)
    base = {k: v for k, v in row.items() if k not in ("h", "n", "step")}
    out: List[Row] = []
    lo = row["h"]
    end = row["h"] + row.get("n", 1) * st if row.get("n", 1) > 1 else row["h"] + 1

    def piece(a: int, b: int) -> None:      # rails a, a + st, ... below b
        m = (b - a) // st if st else (1 if a < b else 0)
        if m == 1:
            out.append(dict(base, h=a))
        elif m > 1:
            out.append(dict(base, h=a, n=m, step=st))

    for h in hs:
        piece(lo, h)
        if picks[h] is not None:
            out.append(picks[h])
        lo = h + (st or 1)
    piece(lo, end)
    return out


def split_from(row: Row, k: int) -> Row:
    """The rails of a row (no pattern) after its first k, as a row (k < its count)."""
    if k == 0:
        return row
    n, st = row.get("n", 1), row["step"]
    out = {f: v for f, v in row.items() if f not in ("h", "n", "step")}
    out["h"] = row["h"] + k * st
    if n - k > 1:
        out["n"], out["step"] = n - k, st
    return out


class KeptIndex:
    """Handle -> the entry of that rail in one run's kept list, without expanding its rows or patterns."""

    def __init__(self, kept: Optional[Sequence[Row]]):
        self.one: Dict[int, Row] = {}
        runs: Dict[Tuple[int, int], List[Tuple[int, int, Row]]] = {}
        self.pats: List[Tuple[Dict[int, Row], Uses, int]] = []
        for e in kept or []:
            if not isinstance(e, dict):
                continue
            if "pat" in e:
                offs: Dict[int, Row] = {}
                for r in e["pat"]:
                    for o in _offsets(r):
                        offs.setdefault(o, r)
                self.pats.append((offs, uses_of(e), max(offs, default=0)))
            elif e.get("n", 1) <= 1:
                self.one.setdefault(e["h"], e)     # first match wins, as a scan of the list
            else:
                st = e["step"]
                runs.setdefault((st, e["h"] % st), []).append((e["h"], e["h"] + (e["n"] - 1) * st, e))
        self.runs: Dict[Tuple[int, int], Tuple[List[int], List[Tuple[int, int, Row]]]] = {}
        for k, lst in runs.items():
            lst.sort(key=lambda t: t[0])
            self.runs[k] = ([t[0] for t in lst], lst)
        self.steps = sorted({k[0] for k in self.runs})
        self._starts: Optional[Tuple[List[int], List[Tuple[int, int, int, frozenset]], List[int],
                                     List[Tuple[int, int, int, frozenset]], List[int]]] = None

    def _uses(self):
        """Every use of every pattern: the single bases ascending (with their pattern index and skip), and the runs
        by first base with the furthest handle any run up to each reaches (a run's hull may hold other uses)."""
        if self._starts is None:
            one, many = [], []
            for i, (_, u, span) in enumerate(self.pats):
                for b, n, st, sk in u.runs():
                    if n == 1:
                        one.append((b, i, 0, sk))
                    else:
                        many.append((b, i, n, st, sk, b + (n - 1) * st + span))
            one.sort(key=lambda t: t[0])
            many.sort(key=lambda t: t[0])
            reach, m = [], -1
            for t in many:
                m = max(m, t[5])
                reach.append(m)
            self._starts = ([t[0] for t in one], one, [t[0] for t in many], many, reach)
        return self._starts

    def get(self, h: Any) -> Optional[Row]:
        if not isinstance(h, int):
            return None
        e = self.one.get(h)
        if e is not None:
            return e
        for st in self.steps:
            r = self.runs.get((st, h % st))
            if r is None:
                continue
            i = bisect.bisect_right(r[0], h) - 1
            if i >= 0 and r[1][i][1] >= h:
                return rail(r[1][i][2], h)
        if self.pats:
            bases, one, starts, many, reach = self._uses()
            i = bisect.bisect_right(bases, h) - 1
            # single uses do not overlap (each covers one stretch of consecutive live rails, and none spans a
            # replayed call's), so only the last base at or below h can hold it; rows of their own lie between uses
            if i >= 0:
                b, p, _, sk = one[i]
                if h - b not in sk:
                    r = self.pats[p][0].get(h - b)
                    if r is not None:
                        return rail(r, h)
            j = bisect.bisect_right(starts, h) - 1
            while j >= 0 and reach[j] >= h:   # every run whose hull may hold h
                b, p, n, st, sk, end = many[j]
                j -= 1
                if end < h:
                    continue
                k = min((h - b) // st, n - 1)
                o = h - (b + k * st)
                if o not in sk:
                    r = self.pats[p][0].get(o)
                    if r is not None:
                        return rail(r, h)
        return None


def expand(kept: Optional[Sequence[Row]]) -> Iterator[Row]:
    """Every rail of the list, one entry each (only for a reader that needs every rail by its handle)."""
    for row, at in leaves(kept):
        yield from rails(row, at)


def mark_results(kept: Optional[Sequence[Row]], results: Iterable[int]) -> List[Row]:
    """The list with each rail of `results` its own entry with "result": true (run.resolve_handle_rets): a pattern's
    use that holds one becomes rows of its own."""
    res = set(results)
    out: List[Row] = []
    for e in kept or []:
        if not isinstance(e, dict):
            out.append(e)
            continue
        if "pat" in e:
            offs = {o for r in e["pat"] for o in _offsets(r)}
            u = uses_of(e)
            hit: Dict[int, frozenset] = {}                 # base -> the rails it leaves out
            rest: List[Any] = []
            skip: List[Any] = []
            for b0, n, st, sk in u.runs():
                hs = set()
                for h in res:                              # the one base of the run at or below h a step away
                    if h >= b0:
                        b = b0 + min((h - b0) // st, n - 1) * st
                        if h - b in offs and h - b not in sk:
                            hs.add(b)
                lo = b0
                for b in sorted(hs) + [b0 + n * st]:       # the run's bases between two hits stay a run
                    m = (b - lo) // st
                    if m:
                        rest.append(lo if m == 1 else [lo, m, st])
                        if sk:
                            skip.append([lo, sorted(sk)])
                    if b in hs:
                        hit[b] = sk
                    lo = b + st
            if not hit:
                out.append(e)
                continue
            if rest:
                out.append(dict({"pat": e["pat"], "at": rest}, **({"skip": skip} if skip else {})))
            for b in sorted(hit):
                for r in e["pat"]:
                    moved = dict(r, h=r["h"] + b)
                    picks: Dict[int, Optional[Row]] = {b + o: None for o in hit[b] if holds(moved, b + o)}
                    picks.update({h: dict(rail(moved, h), result=True) for h in res if holds(moved, h) and h not in picks})
                    out.extend(split(moved, picks))
            continue
        picks = {h: dict(rail(e, h), result=True) for h in res if holds(e, h)}
        out.extend(split(e, picks) if picks else [e])
    return out


_P = (1 << 61) - 1
_BASES = (0x5DEECE66D, 0x2545F4914F6CDD1D % _P)


def _geo(r: int, h: int, n: int, st: int) -> int:
    """sum of r^(h + i st) for i < n, mod _P."""
    first = pow(r, h, _P)
    if n == 1:
        return first
    q = pow(r, st, _P)
    if q == 1:
        return first * n % _P
    return first * (pow(q, n, _P) - 1) % _P * pow(q - 1, _P - 2, _P) % _P


def handle_digest(kept: Optional[Sequence[Row]]) -> Tuple:
    """The set of (handle, width) of the kept rails as a value that does not depend on how the rails are cut into
    rows and patterns (compare._shape_of hashed the sorted rails before): per width the count and two polynomial
    hashes, the sum of r^h mod the prime 2^61 - 1 at two fixed points r, each row and pattern in closed form. Equal
    sets give equal digests; two different sets collide only where both difference polynomials vanish at those
    points."""
    acc: Dict[Any, List[int]] = {}
    for e in kept or []:
        if not isinstance(e, dict):
            continue
        if "pat" in e:
            u = uses_of(e)
            sums = [sum(_geo(r, b, n, st) for b, n, st, _ in u.runs()) % _P for r in _BASES]
            for row in e["pat"]:
                a = acc.setdefault(row.get("w"), [0, 0, 0])
                a[0] += row.get("n", 1) * len(u)
                for j, r in enumerate(_BASES):
                    a[1 + j] = (a[1 + j] + sums[j] * _geo(r, row["h"], row.get("n", 1), row.get("step", 0))) % _P
            if u.skip:                               # less the (handle, width) of each rail a use leaves out
                width = {}
                for row in e["pat"]:
                    for o in _offsets(row):
                        width.setdefault(o, row.get("w"))
                for b, n, st, sk in u.runs():
                    for o in sk:
                        a = acc.setdefault(width.get(o), [0, 0, 0])
                        a[0] -= n
                        for j, r in enumerate(_BASES):
                            a[1 + j] = (a[1 + j] - _geo(r, b + o, n, st)) % _P
            continue
        a = acc.setdefault(e.get("w"), [0, 0, 0])
        a[0] += e.get("n", 1)
        for j, r in enumerate(_BASES):
            a[1 + j] = (a[1 + j] + _geo(r, e["h"], e.get("n", 1), e.get("step", 0))) % _P
    return tuple(sorted(((w, *a) for w, a in acc.items() if a[0]), key=lambda t: (str(t[0]), t[1:])))
