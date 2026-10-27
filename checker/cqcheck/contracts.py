"""Frozen checker contracts (cq-arch). Changes only under cq-arch's freeze rule.

Frozen dataclasses, serialized as JSON. Field names are the contract; nested records (driver
calls and their arguments, samples, sample classes) are plain JSON objects with the keys given in
each field's comment.
"""
from __future__ import annotations

import dataclasses
import json
from dataclasses import dataclass
from typing import Any, Dict, List, Type, TypeVar


@dataclass(frozen=True)
class DriverSpec:
    example: str
    protos: List[str]
    setup: str
    calls: List[Dict[str, Any]]      # [{fn, args: [{ctype, quantum}]}]


@dataclass(frozen=True)
class SampleSet:
    example: str
    samples: List[Dict[str, Any]]    # [{call, args}]
    classes: Dict[str, Any]          # {edge, specials, totalization, trips, random_seed, exhaustive}


@dataclass(frozen=True)
class RunResult:
    side: str
    sample: Any
    outputs: Any
    measured: Any
    rotations: Any
    kept: Any
    clean: Any
    violations: Any


@dataclass(frozen=True)
class Verdict:
    example: str
    s6: Any
    c_oracle: Any
    verifier: Any
    diff_lines: Any
    reasons: List[str]


T = TypeVar("T")


def to_json(obj: Any) -> str:
    """One contract record as a JSON object (one line)."""
    return json.dumps(dataclasses.asdict(obj), sort_keys=True, separators=(",", ":"))


def from_json(cls: Type[T], text: str) -> T:
    """The inverse of to_json; an unknown or missing field is an error."""
    data = json.loads(text)
    names = {f.name for f in dataclasses.fields(cls)}
    if set(data) != names:
        raise ValueError(f"{cls.__name__}: fields {sorted(data)} != {sorted(names)}")
    return cls(**data)
