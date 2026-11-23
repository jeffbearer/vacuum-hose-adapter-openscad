#!/usr/bin/env python3
import argparse
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import trimesh


def run_openscad(openscad: str, scad: Path, output: Path, defines: dict[str, str]) -> None:
    cmd = [openscad]
    for key, value in defines.items():
        cmd.extend(["-D", f"{key}={value}"])
    cmd.extend([
        "-o", str(output),
        "--export-format", "binstl",
        "--backend", "CGAL",
        str(scad),
    ])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"OpenSCAD failed for {scad}:\n{proc.stderr}")
    if "WARNING:" in proc.stderr or "ERROR:" in proc.stderr:
        raise RuntimeError(f"OpenSCAD reported warnings/errors for {scad}:\n{proc.stderr}")


def mesh_stats(mesh_path: Path) -> tuple[np.ndarray, float]:
    mesh = trimesh.load_mesh(mesh_path, force="mesh")
    if not isinstance(mesh, trimesh.Trimesh):
        raise AssertionError(f"Expected Trimesh for {mesh_path}")
    if not mesh.is_watertight:
        raise AssertionError(f"Mesh is not watertight: {mesh_path}")
    components = mesh.split(only_watertight=False)
    if len(components) != 1:
        raise AssertionError(f"Mesh is not one connected solid: {mesh_path} (components={len(components)})")
    bounds = mesh.bounds
    extents = bounds[1] - bounds[0]
    return extents, float(mesh.volume)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--openscad", required=True)
    parser.add_argument("--repo", required=True)
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    temporary = tempfile.TemporaryDirectory(prefix="iztwist-gasket-mesh-")
    output_dir = Path(temporary.name)

    app_scad = repo / "vacuum-hose-adapter.scad"
    demo_scad = repo / "demos" / "iztwist_demo.scad"

    nominals = [2.5, 4, 6]
    styles = ["iztwist_screw", "iztwist_hook"]
    ends = ["end1", "end2", "end3"]

    try:
        standalone_stats = {}
        for nominal in nominals:
            stl = output_dir / f"standalone_{nominal}.stl"
            run_openscad(
                args.openscad,
                demo_scad,
                stl,
                {
                    "Support_Part": '"gasket"',
                    "UserNominal_Size": str(nominal),
                },
            )
            standalone_stats[nominal] = mesh_stats(stl)

        for nominal in nominals:
            base_extents, base_volume = standalone_stats[nominal]
            for style in styles:
                for output_end in ends:
                    stl = output_dir / f"app_{output_end}_{style}_{nominal}.stl"
                    defines = {
                        "Output_Mode": '"iztwist_gasket"',
                        "Output_End": f'"{output_end}"',
                        "fn": "180",
                    }
                    for end in ends:
                        idx = end[-1]
                        if end == output_end:
                            defines[f"End{idx}_Style"] = '"specialised"'
                            defines[f"End{idx}_Specialised_Style"] = f'"{style}"'
                            defines[f"End{idx}_IzTwist_Size"] = str(nominal)
                            defines[f"End{idx}_Length"] = "[1,0]"
                        else:
                            defines[f"End{idx}_Style"] = '"hose"'
                    run_openscad(args.openscad, app_scad, stl, defines)
                    extents, volume = mesh_stats(stl)
                    if not np.allclose(extents, base_extents, atol=1e-3, rtol=1e-6):
                        raise AssertionError(
                            f"Bounds mismatch for {output_end}/{style}/{nominal}: {extents} vs {base_extents}"
                        )
                    if not np.isclose(volume, base_volume, atol=1e-2, rtol=1e-6):
                        raise AssertionError(
                            f"Volume mismatch for {output_end}/{style}/{nominal}: {volume} vs {base_volume}"
                        )
    finally:
        temporary.cleanup()

    print("IzTwist gasket mesh comparison passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
