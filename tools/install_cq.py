#!/usr/bin/env python3
"""Build and install CQ with an explicitly selected static backend."""

from __future__ import annotations

import argparse
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

from llvm_discovery import discover_llvm_dir

CQOPS_REPOSITORY = "https://github.com/SoerenWilkening/opcode_quantum_operations.git"
CQOPS_REVISION = "c9707a3058db132f67b45164e26bdab8628dbafb"
QEC_REPOSITORY = "https://github.com/SoerenWilkening/C_quantum_error_correction.git"
QEC_REVISION = "c4a2adc3ae674bbd786028a54519f4668933c5f1"


def source_root() -> Path:
    return Path(__file__).resolve().parent.parent


def run(command: list[str], dry_run: bool) -> None:
    print("+", " ".join(command))
    if not dry_run:
        subprocess.run(command, check=True)


def build_command(build_dir: Path, build_type: str, parallel: str | None) -> list[str]:
    command = ["cmake", "--build", str(build_dir), "--config", build_type]
    if parallel is not None:
        command.append("--parallel")
        if parallel != "native":
            command.append(parallel)
    return command


def checkout_dependency(
    source: Path | None,
    destination: Path,
    repository: str,
    revision: str,
    dry_run: bool,
) -> Path:
    if source:
        return source.resolve()
    if not dry_run:
        if not (destination / ".git").is_dir():
            destination.parent.mkdir(parents=True, exist_ok=True)
            run(["git", "clone", "--depth", "1", repository, str(destination)], False)
        run(["git", "-C", str(destination), "fetch", "--depth", "1", "origin", revision], False)
        run(["git", "-C", str(destination), "checkout", "--detach", revision], False)
    else:
        run(["git", "clone", "--depth", "1", repository, str(destination)], True)
        run(["git", "-C", str(destination), "fetch", "--depth", "1", "origin", revision], True)
        run(["git", "-C", str(destination), "checkout", "--detach", revision], True)
    return destination.resolve()


def cmake_quote(value: str) -> str:
    return value.replace("\\", "/").replace(";", "\\;").replace('"', '\\"')


def validate_external(args: argparse.Namespace, root: Path) -> None:
    if not args.backend_library:
        raise RuntimeError("an external backend requires --backend-library")
    if not args.backend_manifest:
        raise RuntimeError("an external backend requires --backend-manifest")
    command = [
        sys.executable,
        str(root / "tools/backend_contract.py"),
        "--root",
        str(root),
        "check",
    ]
    for archive in args.backend_library:
        command.extend(("--archive", str(archive.resolve())))
    command.extend(("--manifest", str(args.backend_manifest.resolve())))
    run(command, args.dry_run)


def prepare_cqops(args: argparse.Namespace, root: Path) -> None:
    source_root = args.dependency_source_dir.resolve()
    cqops_checkout = checkout_dependency(
        args.cqops_dir, source_root / "opcode_quantum_operations",
        CQOPS_REPOSITORY, args.cqops_ref, args.dry_run,
    )
    qec_checkout = checkout_dependency(
        args.qec_dir, source_root / "C_quantum_error_correction",
        QEC_REPOSITORY, args.qec_ref, args.dry_run,
    )
    cqops_dir = cqops_checkout
    qec_dir = qec_checkout / "qec"
    qec_build = qec_dir / args.qec_build
    cqops_build = args.cqops_build_dir.resolve()
    required = [
        cqops_dir / "CMakeLists.txt",
        qec_dir / "CMakeLists.txt",
        cqops_dir / "backend-manifest.json",
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing and not args.dry_run:
        raise RuntimeError("cqops production inputs missing: " + ", ".join(missing))

    run(
        [
            "cmake", "-S", str(qec_dir), "-B", str(qec_build),
            f"-DCMAKE_BUILD_TYPE={args.build_type}",
        ],
        args.dry_run,
    )
    qec_build_command = build_command(qec_build, args.build_type, args.parallel)
    qec_build_command.extend(("--target", "qec"))
    run(qec_build_command, args.dry_run)
    run(
        [
            "cmake", "-S", str(cqops_dir), "-B", str(cqops_build),
            f"-DCMAKE_BUILD_TYPE={args.build_type}",
            f"-DCQOPS_QEC_DIR={qec_dir}",
            f"-DCQOPS_QEC_BUILD={args.qec_build}",
            f"-DCQOPS_CQLANG_DIR={root}",
        ],
        args.dry_run,
    )
    cqops_build_command = build_command(cqops_build, args.build_type, args.parallel)
    cqops_build_command.extend(("--target", "cqops"))
    run(cqops_build_command, args.dry_run)
    args.backend_library = [cqops_build / "libcqops.a"]
    args.backend_manifest = cqops_dir / "backend-manifest.json"
    args.cqops_dir = cqops_checkout
    args.qec_dir = qec_checkout
    args.backend_dependency = [
        qec_build / "libqec.a",
        qec_build / "libtommath.a",
        qec_build / "libcjson.a",
    ]
    args.backend_link_item = ["m"]


def selection_for_trace() -> str:
    return """# Generated by tools/install_cq.py.\n\
add_library(CQ::backend INTERFACE IMPORTED)\n\
set_property(TARGET CQ::backend PROPERTY\n\
             INTERFACE_LINK_LIBRARIES CQ::trace_backend)\n\
set(CQ_BACKEND_NAME \"trace\")\n"""


def selection_for_external(
    name: str, archives: list[Path], link_items: list[str], manifest: Path
) -> str:
    items = [cmake_quote(str(path)) for path in archives]
    items.extend(cmake_quote(item) for item in link_items)
    joined = ";".join(items)
    return (
        "# Generated by tools/install_cq.py.\n"
        "add_library(CQ::backend INTERFACE IMPORTED)\n"
        "set_property(TARGET CQ::backend PROPERTY\n"
        f'             INTERFACE_LINK_LIBRARIES "{joined}")\n'
        f'set(CQ_BACKEND_NAME "{cmake_quote(name)}")\n'
        f'set(CQ_BACKEND_PROVIDER_MANIFEST "{cmake_quote(str(manifest))}")\n'
    )


def driver_selection(name: str, link_items: list[str], llvm_bin: Path | None) -> str:
    quoted = "\n".join(f"  {shlex.quote(item)}" for item in link_items)
    llvm_line = ""
    if llvm_bin:
        llvm_line = f"CQ_LLVM_BIN={shlex.quote(str(llvm_bin))}\n"
    return (
        "# Generated by tools/install_cq.py.\n"
        f"CQ_BACKEND_NAME={shlex.quote(name)}\n"
        f"{llvm_line}"
        "CQ_BACKEND_LINK_ITEMS=(\n"
        f"{quoted}\n"
        ")\n"
    )


def driver_link_item(item: str) -> str:
    if item.startswith("-") or "/" in item or "\\" in item:
        return item
    return f"-l{item}"


def uninstall_manifest_path(args: argparse.Namespace) -> Path:
    return args.prefix.resolve() / args.libdir / "cq" / "CQInstallManifest.txt"


def validate_owned_path(path: Path, prefix: Path) -> Path:
    absolute = path.resolve(strict=False)
    if absolute == prefix or prefix not in absolute.parents:
        raise RuntimeError(f"installed path escapes prefix {prefix}: {path}")
    return absolute


def write_uninstall_manifest(
    args: argparse.Namespace, generated_paths: list[Path]
) -> Path:
    prefix = args.prefix.resolve()
    destination = uninstall_manifest_path(args)
    print(f"+ write {destination}")
    if args.dry_run:
        return destination

    cmake_manifest = args.build_dir.resolve() / "install_manifest.txt"
    try:
        cmake_paths = [
            Path(line)
            for line in cmake_manifest.read_text(encoding="utf-8").splitlines()
            if line
        ]
    except OSError as exc:
        raise RuntimeError(f"cannot read CMake install manifest {cmake_manifest}: {exc}")

    paths = cmake_paths + generated_paths
    if destination.exists():
        lines = destination.read_text(encoding="utf-8").splitlines()
        if not lines or lines[0] != "# CQ install manifest v1":
            raise RuntimeError(f"invalid existing CQ install manifest: {destination}")
        paths.extend(Path(line) for line in lines[1:] if line)
    paths.append(destination)

    owned = sorted({validate_owned_path(path, prefix) for path in paths}, key=str)
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(".txt.tmp")
    temporary.write_text(
        "# CQ install manifest v1\n"
        + "".join(f"{path}\n" for path in owned),
        encoding="utf-8",
    )
    temporary.replace(destination)
    return destination


def install_selection(args: argparse.Namespace) -> list[Path]:
    prefix = args.prefix.resolve()
    package_dir = prefix / args.libdir / "cmake" / "CQ"
    generated_paths: list[Path] = []
    if args.backend == "trace":
        selection = selection_for_trace()
        driver_items = [
            str(prefix / args.libdir / "libcq_templates.a"),
            str(prefix / args.libdir / "libcq_runtime.a"),
        ]
    else:
        backend_dir = prefix / args.libdir / "cq" / "backends" / args.backend
        manifest_dir = prefix / args.datadir / "cq" / "backends" / args.backend
        dependencies = getattr(args, "backend_dependency", [])
        all_archives = args.backend_library + dependencies
        installed_archives = [backend_dir / path.name for path in all_archives]
        provider_archives = installed_archives[: len(args.backend_library)]
        installed_manifest = manifest_dir / "backend-manifest.json"
        selection = selection_for_external(
            args.backend, provider_archives,
            [str(path) for path in installed_archives[len(args.backend_library):]]
            + args.backend_link_item,
            installed_manifest,
        )
        driver_items = [str(path) for path in installed_archives]
        driver_items.extend(driver_link_item(item) for item in args.backend_link_item)
        if not args.dry_run:
            backend_dir.mkdir(parents=True, exist_ok=True)
            manifest_dir.mkdir(parents=True, exist_ok=True)
            for source, destination in zip(all_archives, installed_archives):
                shutil.copy2(source.resolve(), destination)
            shutil.copy2(args.backend_manifest.resolve(), installed_manifest)
        generated_paths.extend(installed_archives)
        generated_paths.append(installed_manifest)

    destination = package_dir / "CQBackendSelection.cmake"
    print(f"+ write {destination}")
    if not args.dry_run:
        package_dir.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_suffix(".cmake.tmp")
        temporary.write_text(selection, encoding="utf-8")
        temporary.replace(destination)
    generated_paths.append(destination)

    driver_destination = prefix / args.libdir / "cq" / "CQBackendSelection.sh"
    print(f"+ write {driver_destination}")
    if not args.dry_run:
        driver_destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = driver_destination.with_suffix(".sh.tmp")
        llvm_bin = args.llvm_dir.resolve().parents[2] / "bin" if args.llvm_dir else None
        temporary.write_text(
            driver_selection(args.backend, driver_items, llvm_bin), encoding="utf-8"
        )
        temporary.replace(driver_destination)
    generated_paths.append(driver_destination)
    return generated_paths


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--prefix", type=Path, default=Path.home() / ".local",
        help="installation prefix (default: ~/.local)",
    )
    parser.add_argument(
        "--backend",
        required=True,
        help="backend name; use 'trace' for tests or 'cqops' for the production stack",
    )
    parser.add_argument("--backend-library", type=Path, action="append", default=[])
    parser.add_argument("--backend-dependency", type=Path, action="append", default=[])
    parser.add_argument("--backend-manifest", type=Path)
    parser.add_argument(
        "--backend-link-item",
        action="append",
        default=[],
        help="transitive link item such as m or /path/libqec.a; repeat as needed",
    )
    parser.add_argument("--build-dir", type=Path, default=Path("build-install"))
    parser.add_argument("--build-type", default="Release")
    parser.add_argument(
        "--parallel",
        "-j",
        nargs="?",
        const="native",
        metavar="N",
        help="parallel build jobs; omit N to use CMake's native default",
    )
    parser.add_argument("--llvm-dir", type=Path)
    parser.add_argument("--cqops-dir", type=Path,
                        help="existing checkout; otherwise cloned at the pinned revision")
    parser.add_argument("--cqops-ref", default=CQOPS_REVISION)
    parser.add_argument("--cqops-build-dir", type=Path, default=Path("build-cqops-install"))
    parser.add_argument("--qec-dir", type=Path,
                        help="existing QEC checkout; otherwise cloned at the pinned revision")
    parser.add_argument("--qec-ref", default=QEC_REVISION)
    parser.add_argument("--qec-build", default="build-cq-install")
    parser.add_argument(
        "--dependency-source-dir", type=Path,
        default=Path.home() / ".cache" / "cq" / "sources",
        help="where automatic production-backend checkouts are stored",
    )
    parser.add_argument("--cmake-arg", action="append", default=[])
    parser.add_argument("--libdir", default="lib")
    parser.add_argument("--datadir", default="share")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.llvm_dir is None:
        args.llvm_dir = discover_llvm_dir()
    root = source_root()
    try:
        if not re.fullmatch(r"[A-Za-z0-9_.+-]+", args.backend):
            raise RuntimeError(
                "--backend must contain only letters, digits, '.', '_', '+', or '-'"
            )
        if args.backend == "trace":
            if args.backend_library or args.backend_manifest or args.backend_link_item:
                raise RuntimeError("the trace backend takes no external backend options")
        elif args.backend == "cqops":
            if args.backend_library or args.backend_manifest or args.backend_link_item:
                raise RuntimeError("--backend cqops selects its own archives and dependencies")
            prepare_cqops(args, root)
            validate_external(args, root)
        else:
            basenames = [path.name for path in args.backend_library]
            if len(basenames) != len(set(basenames)):
                raise RuntimeError("backend archives must have distinct basenames")
            validate_external(args, root)

        configure = [
            "cmake",
            "-S",
            str(root),
            "-B",
            str(args.build_dir),
            f"-DCMAKE_BUILD_TYPE={args.build_type}",
            f"-DCMAKE_INSTALL_PREFIX={args.prefix.resolve()}",
            f"-DCMAKE_INSTALL_LIBDIR={args.libdir}",
            f"-DCMAKE_INSTALL_DATADIR={args.datadir}",
        ]
        if args.llvm_dir:
            configure.append(f"-DLLVM_DIR={args.llvm_dir.resolve()}")
        configure.extend(args.cmake_arg)
        run(configure, args.dry_run)
        build = build_command(args.build_dir, args.build_type, args.parallel)
        run(build, args.dry_run)
        run(
            ["cmake", "--install", str(args.build_dir), "--config", args.build_type],
            args.dry_run,
        )
        generated_paths = install_selection(args)
        write_uninstall_manifest(args, generated_paths)
        print(f"CQ installed with explicit default backend: {args.backend}")
        return 0
    except (RuntimeError, subprocess.CalledProcessError, OSError) as exc:
        print(f"install_cq: ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
