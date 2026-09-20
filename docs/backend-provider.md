# Providing a static backend for CQ

CQ lowers programs to a C ABI. A production backend is a precompiled static
library that implements that ABI; it is linked into each lowered application
and is not recompiled with the application. CQ's own `cq_trace_backend` is the
test implementation: it prints the calls and does not emit a real circuit.

Exactly one implementation may be present on an application link line. Never
link a production backend together with `libcq_templates.a` or
`libcq_runtime.a`: all three define overlapping symbols, and archive order can
silently select the trace body instead of the production body.

## Required backend surface

A backend must:

1. Be a C11-compatible static archive.
2. Define every emit-capable `cqrt_*` declaration from `cq_runtime.h` and every
   `cq_template_*` declaration from the three generated template headers.
3. Use the declarations verbatim. A C linker checks symbol names, not function
   signatures, so compiling the backend shim against these headers is required.
4. Return all internal scratch qubits to `|0>` at each ABI boundary. Correct
   classical results alone do not establish a correct reversible circuit.
5. Carry a provider manifest naming the exact CQ backend ABI it implements.
6. Export its transitive static-link dependencies rather than relying on link
   order guessed by the application.

`cqrt_h` and `cqrt_h_controlled` remain declared but cannot be emitted by the
current pass. They are recorded as declared-but-unemitted and are not required
of a backend. All other current declarations are required.

Generate the provider manifest from the CQ revision whose headers the backend
uses:

```bash
python3 /path/to/CQ_lang/tools/backend_contract.py \
  provider-manifest --name mybackend --output backend-manifest.json
```

Validate the completed archive before publishing it:

```bash
python3 /path/to/CQ_lang/tools/backend_contract.py check \
  --archive build/libmybackend.a \
  --manifest backend-manifest.json
```

The check compares the manifest's ABI identity and verifies every required
symbol with `nm`. It deliberately allows additional backend-specific public
symbols. It cannot recover C parameter types from a native archive; compiling
the shim against CQ's installed ABI headers remains mandatory.

## CMake package contract

Backend packages should export the canonical target `CQBackend::backend`. That
target must carry the archive and all transitive libraries needed to link it.
A minimal backend project has this shape:

```cmake
add_library(mybackend STATIC ${backend_sources})
target_include_directories(mybackend PRIVATE /path/to/CQ/include/cq/backend)
target_link_libraries(mybackend PUBLIC m) # and any real dependencies

set_target_properties(mybackend PROPERTIES EXPORT_NAME backend)
install(TARGETS mybackend EXPORT CQBackendTargets ARCHIVE DESTINATION lib)
install(EXPORT CQBackendTargets
        FILE CQBackendTargets.cmake
        NAMESPACE CQBackend::
        DESTINATION lib/cmake/CQBackend)
```

The package should also install `CQBackendConfig.cmake`, its version file, and
`backend-manifest.json`. A consumer can then select it without knowing archive
names or dependency order:

```cmake
find_package(CQ CONFIG REQUIRED)
find_package(CQBackend CONFIG REQUIRED)
target_link_libraries(application PRIVATE CQBackend::backend)
```

CQ's installer also supports an archive directly. This is an escape hatch for
backends that do not yet export a CMake package:

```bash
python3 tools/install_cq.py \
  --prefix "$HOME/.local" \
  --backend mybackend \
  --backend-library /absolute/path/libmybackend.a \
  --backend-manifest /absolute/path/backend-manifest.json \
  --backend-link-item m
```

The installer validates and copies the archive, installs CQ, and creates the
imported target `CQ::backend`. The selected backend must always be named.
Choose `--backend trace` explicitly when installing only the test backend;
there is no silent production-to-trace fallback.

## Backend CI requirements

A backend's CI should include:

- its own reversible-circuit and clean-ancilla tests;
- `backend_contract.py check` against its installed archive and manifest;
- a link-map assertion that no CQ trace archive supplied any symbol;
- at least one CQ program lowered by `libCQPass` and linked only to the backend;
- a Release build, because Debug-only invariant checks are not the shipped
  execution mode.
