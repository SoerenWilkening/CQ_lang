"""The kept list of a run (RunResult.kept): the exit event's live rails, never one entry per rail (cq-pckdl).

An entry is one of
  - a row: {"h", "w", "v", "role", "known"} for one rail, or with "n" and "step" for the n rails h, h + step, ...,
    h + (n - 1) * step, all of one width, value, role and known flag;
  - a pattern: {"pat": [rows], "at": [bases]}: for each base b (ascending) the pattern's rows with every handle
    moved by b (rt/core.c at_exit_handler writes a stretch of rails that recurs once in full and then by reference;
    a replayed snprintf left 145M live rails at exit, cq-kcn5i).
No handle is in two places. A reader goes through leaves(): (row, bases) pairs, bases None for a row of its own;
the pair stands for count(row, bases) rails that share the row's width, value, role and known flag. A reader that
needs one rail at a time asks KeptIndex for it, or expands only the pairs it selects first (rails); nothing but
the reference's kept multiset (compare._kept_rows, CQ_spec examples) expands every entry of a run.

run.py builds the list from the exit event's entries (build): rows, {"def": id, "rows": [...]} (a pattern's rows,
handles relative to its first rail) and {"use": id, "h": b} or {"use": id, "h": b, "n": n, "step": s} (the pattern
at b, b + s, ...).
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

    def add(self, e: Row) -> None:
        if "pat" in e:                       # a pattern entry of a list built before (a cached run)
            self.order.append({"pat": e["pat"], "at": list(e["at"])})
        elif "def" in e:
            p = {"pat": e["rows"], "at": []}
            self.pats[e["def"]] = p
            self.order.append(p)
        elif "use" in e:
            p = self.pats[e["use"]]
            n = e.get("n", 1)
            if n > 1:
                p["at"].extend(range(e["h"], e["h"] + n * e["step"], e["step"]))
            else:
                p["at"].append(e["h"])
        else:
            self.rows.append(e)

    def kept(self) -> List[Row]:
        for p in self.order:
            p["at"].sort()
        return sorted(self.rows, key=lambda e: e["h"]) + [p for p in self.order if p["at"]]


def build(entries: Iterable[Row]) -> List[Row]:
    b = Builder()
    for e in entries:
        b.add(e)
    return b.kept()


def leaves(kept: Optional[Sequence[Row]]) -> Iterator[Tuple[Row, Optional[List[int]]]]:
    for e in kept or []:
        if not isinstance(e, dict):
            continue
        if "pat" in e:
            for r in e["pat"]:
                yield r, e["at"]
        else:
            yield e, None


def count(row: Row, at: Optional[List[int]] = None) -> int:
    return row.get("n", 1) * (len(at) if at is not None else 1)


def _offsets(row: Row) -> range:
    n = row.get("n", 1)
    st = row.get("step", 0) if n > 1 else 1
    return range(row["h"], row["h"] + n * st, st)


def handles(row: Row, at: Optional[List[int]] = None) -> Iterator[int]:
    if at is None:
        yield from _offsets(row)
        return
    offs = _offsets(row)
    for b in at:
        for o in offs:
            yield b + o


def rail(row: Row, h: int) -> Row:
    """The entry of rail h of `row`, as a row of one rail."""
    if "n" not in row and row["h"] == h:
        return row
    one = {k: v for k, v in row.items() if k not in ("n", "step")}
    one["h"] = h
    return one


def rails(row: Row, at: Optional[List[int]] = None) -> Iterator[Row]:
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
    hs = sorted(h for h in picks if holds(row, h))
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
        self.pats: List[Tuple[Dict[int, Row], List[int]]] = []
        for e in kept or []:
            if not isinstance(e, dict):
                continue
            if "pat" in e:
                offs: Dict[int, Row] = {}
                for r in e["pat"]:
                    for o in _offsets(r):
                        offs.setdefault(o, r)
                self.pats.append((offs, e["at"]))
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
        self._starts: Optional[Tuple[List[int], List[int]]] = None

    def _uses(self) -> Tuple[List[int], List[int]]:
        """Every use of every pattern, by its base: (bases ascending, pattern index of each)."""
        if self._starts is None:
            pairs = sorted((b, i) for i, (_, at) in enumerate(self.pats) for b in at)
            self._starts = ([b for b, _ in pairs], [i for _, i in pairs])
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
            bases, which = self._uses()
            i = bisect.bisect_right(bases, h) - 1
            # uses do not overlap (each covers one stretch of consecutive live rails), so only the last base at or
            # below h can hold it; rows of their own lie between uses
            if i >= 0:
                r = self.pats[which[i]][0].get(h - bases[i])
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
            hit = {b for b in e["at"] if any(h - b in offs for h in res)}
            if not hit:
                out.append(e)
                continue
            rest = [b for b in e["at"] if b not in hit]
            if rest:
                out.append({"pat": e["pat"], "at": rest})
            for b in sorted(hit):
                for r in e["pat"]:
                    moved = dict(r, h=r["h"] + b)
                    out.extend(split(moved, {h: dict(rail(moved, h), result=True) for h in res if holds(moved, h)}))
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
            at = e["at"]
            sums = [sum(pow(r, b, _P) for b in at) % _P for r in _BASES]
            for row in e["pat"]:
                a = acc.setdefault(row.get("w"), [0, 0, 0])
                a[0] += row.get("n", 1) * len(at)
                for j, r in enumerate(_BASES):
                    a[1 + j] = (a[1 + j] + sums[j] * _geo(r, row["h"], row.get("n", 1), row.get("step", 0))) % _P
            continue
        a = acc.setdefault(e.get("w"), [0, 0, 0])
        a[0] += e.get("n", 1)
        for j, r in enumerate(_BASES):
            a[1 + j] = (a[1 + j] + _geo(r, e["h"], e.get("n", 1), e.get("step", 0))) % _P
    return tuple(sorted(((w, *a) for w, a in acc.items()), key=lambda t: (str(t[0]), t[1:])))
