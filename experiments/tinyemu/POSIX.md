# POSIX calls and syscalls in lowered programs (notes, 2026-11-22)

Draft from the TinyEMU experiment. No follow-up is planned; this records what we found and discussed.

## How a call with no body is lowered today

The lowered C library covers ISO C only (`bundle/roots/*.roots`). A call to any other function with no body
(a POSIX function or a syscall wrapper) with a quantum argument or under a quantum predicate is an **effect
entry** (CR rule 16): its arguments are written to the tape and the backend performs the host call
classically. The pass needs no body and lowering never fails on such a call. TinyEMU's `slirp_send`, a
wrapper around `send`, with all arguments quantum:

```llvm
%10 = call i32 @cqrt_qram_load_i32(i32 %8, i32 %9)          ; s->fd, a quantum load
%12 = call i32 @cqrt_tape_write_i32(i32 %7, i32 %10)        ; field 1: fd
%13 = call i32 @cqrt_tape_write_i64(i32 %7, i32 %1)         ; field 2: buf
%14 = call i32 @cqrt_tape_write_i64(i32 %7, i32 %2)         ; field 3: len
%15 = call i32 @cqrt_tape_write_i32(i32 %7, i32 %3)         ; field 4: flags
%16 = call i32 @cqrt_tape_effect_i64_controlled(i32 %11, i32 %7, ptr @"send", i32 4)
```

`printf` uses the same tape (a format entry instead of an effect entry). Pure POSIX functions such as
`strdup` are treated the same way today: a classical host call, not quantum computation.

## What comes back (BACKEND_ABI.md, the host-boundary table)

| case | the program gets |
|---|---|
| every argument classical, earlier events resolved | the host call at once; its result as a rail |
| a known INPUT call (`read`, `pread`, `fread`, `fgets`, `getline`, `scanf`, ...), also with a quantum buffer address, length or descriptor | the call at once; its result and the bytes it writes enter quantum memory (one host call per value the quantum argument can take) |
| any other callee with a quantum argument or predicate | deferred to the end of the shot; **its result is `\|0⟩`** and buffers it would fill stay unwritten |

The third row is a stated limit of the ABI, not a bug. It matters only on paths where quantum data reaches
such a call's arguments; it never affects whether a program lowers or links.

## TinyEMU's external callees (94)

| group | count | examples |
|---|---|---|
| in the lowered C library (circuits) | 16 | `strlen`, `strcmp`, `snprintf`, `sscanf`, `memcmp` |
| named in the ABI's host table | 23 | `read`, `write`, `fopen`, `fprintf`, `malloc`, `exit` |
| neither: row 3 when an argument is quantum | 58 | below |

Of the 58:

- 7 come from compiling against macOS headers (`__memcpy_chk`, `__maskrune`, `__error`, `__assert_rtn`, ...);
  with musl's headers they would be `memcpy`, `isdigit`, `errno`, `assert`.
- about 6 are pure computation that musl implements and that could be lowered like ISO C: `strdup`,
  `strerror`, `gmtime_r`, `localtime_r`, `inet_aton`, `getopt_long_only`.
- about 45 are syscalls. Those that return data would read 0 when deferred: `recv`, `recvfrom`, `stat`,
  `lstat`, `readdir`, `readlink`, `select` (the POSIX call, not the LLVM instruction), `ioctl`, `tcgetattr`,
  `clock_gettime`, `getsockname`, `accept`. The rest are side effects only: `send`, `mkdir`, `chmod`, `bind`,
  `setsockopt`, ...

## Conclusions

- **Pure POSIX functions belong in the lowered C library.** musl has their bodies; a POSIX root list on the
  existing bundle would make e.g. `strdup` on a quantum string a quantum copy instead of a deferred call
  returning NULL. Agreed in principle, not started.
- **Syscalls are never circuits.** Lowering musl's wrapper only reaches the `syscall` instruction. They stay
  effect entries at the classical boundary; `exit`, `abort` and the like act on the lowered program only
  through flags (rule 16), and the same holds for every other syscall.
- **Linux has 384 syscall numbers on x86-64; our musl uses 341.** Writing a circuit per syscall is the
  wrong frame: most of them touch devices, files or other processes.
- **A quantum kernel** (a lowered program's syscalls calling a lowered kernel instead of the host) is the same
  mechanism as a lowered library and is close to NORTHSTAR goal 4's kernel tiers. It moves the classical
  boundary down to the device drivers; it disappears only when the devices are software too. A fully lowered
  TinyEMU booting a guest kernel is exactly that closed machine. A demonstration for the far future, not a
  practical computation (circuit size, and no reversible meaning for interrupts and scheduling).
