#!/usr/bin/env python3
import argparse
import math
import struct
import subprocess
import tempfile
from pathlib import Path


def run_openscad(openscad_path: Path, output_path: Path, source_path: Path, defs: list[str]) -> None:
    command = [
        str(openscad_path),
        "-o",
        str(output_path),
        "--backend",
        "CGAL",
        "--export-format",
        "binstl",
        "--enable",
        "textmetrics",
    ]
    for define in defs:
        command.extend(["-D", define])
    command.append(str(source_path))

    result = subprocess.run(command, capture_output=True, text=True)
    stderr = result.stderr.strip()
    if result.returncode != 0 or "error:" in stderr.lower() or "warning:" in stderr.lower():
        raise RuntimeError(
            f"OpenSCAD command failed for {source_path.name}\n"
            f"Command: {' '.join(command)}\n"
            f"ExitCode: {result.returncode}\n"
            f"stderr:\n{stderr}"
        )


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def load_binary_stl(path: Path):
    data = path.read_bytes()
    if len(data) < 84:
        raise AssertionError(f"{path.name} is too small to be a binary STL")
    triangle_count = struct.unpack_from("<I", data, 80)[0]
    expected_len = 84 + triangle_count * 50
    if len(data) != expected_len:
        raise AssertionError(
            f"{path.name} malformed binary STL length. expected={expected_len} actual={len(data)}"
        )
    if triangle_count == 0:
        raise AssertionError(f"{path.name} has zero triangles")

    min_v = [math.inf, math.inf, math.inf]
    max_v = [-math.inf, -math.inf, -math.inf]
    volume = 0.0
    offset = 84
    for _ in range(triangle_count):
        values = struct.unpack_from("<12f", data, offset)
        v1 = (values[3], values[4], values[5])
        v2 = (values[6], values[7], values[8])
        v3 = (values[9], values[10], values[11])
        for v in (v1, v2, v3):
            min_v[0] = min(min_v[0], v[0])
            min_v[1] = min(min_v[1], v[1])
            min_v[2] = min(min_v[2], v[2])
            max_v[0] = max(max_v[0], v[0])
            max_v[1] = max(max_v[1], v[1])
            max_v[2] = max(max_v[2], v[2])
        volume += _dot(v1, _cross(v2, v3)) / 6.0
        offset += 50

    return {
        "triangle_count": triangle_count,
        "bounds_min": min_v,
        "bounds_max": max_v,
        "extents": [max_v[i] - min_v[i] for i in range(3)],
        "volume": abs(volume),
    }


def assert_close_vector(name: str, actual, expected, tolerance: float = 0.02) -> None:
    for index, (a, b) in enumerate(zip(actual, expected)):
        if abs(float(a) - float(b)) > tolerance:
            raise AssertionError(f"{name}[{index}] differs: {a} vs {b} (tol {tolerance})")


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare app SlowClamp CGAL mesh with standalone demo mesh")
    parser.add_argument("--openscad-path", required=True)
    parser.add_argument("--repository-root", required=True)
    args = parser.parse_args()

    repository_root = Path(args.repository_root).resolve()
    openscad_path = Path(args.openscad_path).resolve()
    temporary = tempfile.TemporaryDirectory(prefix="slowclamp-output-mesh-")
    artifact_dir = Path(temporary.name)

    app_default_output = artifact_dir / "app-slowclamp-end1-default.stl"
    app_extension_output = artifact_dir / "app-slowclamp-end1-extension160.stl"
    standalone_output = artifact_dir / "standalone-slowclamp.stl"

    try:
        run_openscad(
            openscad_path=openscad_path,
            output_path=app_default_output,
            source_path=repository_root / "vacuum-hose-adapter.scad",
            defs=[
                'Output_Mode="slowclamp"',
                'Output_End="end1"',
                'End1_Style="hose"',
                'End1_Specialised_Style="oneida"',
                'End1_Oneida_Size=5',
                'End1_Oneida_Fit_Adjustment=0',
                'Transition_Bend_Pipe_Diameter="custom"',
                "Transition_Custom_Bend_Pipe_Diameter=0",
                'End2_Style="not_a_real_style"',
            ],
        )

        run_openscad(
            openscad_path=openscad_path,
            output_path=app_extension_output,
            source_path=repository_root / "vacuum-hose-adapter.scad",
            defs=[
                'Output_Mode="slowclamp"',
                'Output_End="end1"',
                'End1_Style="hose"',
                'End1_Specialised_Style="oneida"',
                'End1_Oneida_Size=5',
                'End1_Oneida_Fit_Adjustment=0',
                "End1_Extension_Exit_Diameter=160",
                'Transition_Bend_Pipe_Diameter="custom"',
                "Transition_Custom_Bend_Pipe_Diameter=0",
                'End2_Style="not_a_real_style"',
            ],
        )

        run_openscad(
            openscad_path=openscad_path,
            output_path=standalone_output,
            source_path=repository_root / "demos" / "oneida_slow_clamp.scad",
            defs=[
                'Part="clamp"',
                "Nominal_Size=5",
                "Fit_Adjustment=0",
                "Band_Width=14",
                "Edge_Support=3",
                "Band_Wall=5",
                "Groove_Clearance=0.35",
                "Groove_Draft_Angle=45",
                "Groove_Flat_Width=6",
                "Joint_Gap=0",
                "Split_Gap=12",
                "Screw_Diameter=5",
                "Screw_Clearance=0.5",
                "Nut_Across_Flats=8",
                "Nut_Thickness=4",
                "Hardware_Clearance=0.3",
                "Ear_Thickness=8",
                "Ear_Projection=14",
                "Ear_Root_Chamfer=3",
            ],
        )

        app_default_mesh = load_binary_stl(app_default_output)
        app_extension_mesh = load_binary_stl(app_extension_output)
        standalone_mesh = load_binary_stl(standalone_output)

        assert_close_vector("app-default bounds.min", app_default_mesh["bounds_min"], standalone_mesh["bounds_min"], tolerance=0.02)
        assert_close_vector("app-default bounds.max", app_default_mesh["bounds_max"], standalone_mesh["bounds_max"], tolerance=0.02)
        assert_close_vector("app-extension bounds.min", app_extension_mesh["bounds_min"], standalone_mesh["bounds_min"], tolerance=0.02)
        assert_close_vector("app-extension bounds.max", app_extension_mesh["bounds_max"], standalone_mesh["bounds_max"], tolerance=0.02)

        expected_extents = [162.591, 148.591, 20.0]
        assert_close_vector("default extents", app_default_mesh["extents"], expected_extents, tolerance=0.03)
        assert_close_vector("extension extents", app_extension_mesh["extents"], expected_extents, tolerance=0.03)

        if abs(float(app_default_mesh["volume"]) - float(standalone_mesh["volume"])) > 2.0:
            raise AssertionError(
                f"default volume differs: {app_default_mesh['volume']:.3f} vs {standalone_mesh['volume']:.3f}"
            )
        if abs(float(app_extension_mesh["volume"]) - float(standalone_mesh["volume"])) > 2.0:
            raise AssertionError(
                f"extension volume differs: {app_extension_mesh['volume']:.3f} vs {standalone_mesh['volume']:.3f}"
            )

        print("SlowClamp mesh compare passed.")
        print(f"Default extents: {app_default_mesh['extents']}")
        print(f"Extension extents: {app_extension_mesh['extents']}")
        print(f"Standalone extents: {standalone_mesh['extents']}")
        print(
            "Volumes default/extension/standalone: "
            f"{app_default_mesh['volume']:.3f} / {app_extension_mesh['volume']:.3f} / {standalone_mesh['volume']:.3f}"
        )
        return 0
    finally:
        temporary.cleanup()


if __name__ == "__main__":
    raise SystemExit(main())
