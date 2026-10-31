#!/usr/bin/env python3
"""Generate dkms.conf from dkms_modules in upstream tuxedo-drivers package.yml."""
import sys
from pathlib import Path
import yaml


def generate_dkms_conf(pkg_yml_path: Path, output_path: Path):
    with open(pkg_yml_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    modules = data.get("dkms_modules", [])
    if not modules:
        sys.stderr.write(f"Error: No dkms_modules found in {pkg_yml_path}\n")
        sys.exit(1)

    lines = [
        'PACKAGE_NAME="clevo-drivers"',
        'PACKAGE_VERSION="#MODULE_VERSION#"',
        'AUTOINSTALL="yes"',
        ''
    ]
    for i, mod in enumerate(modules):
        name = mod[0]
        dest = mod[1]
        lines.append(f'DEST_MODULE_LOCATION[{i}]="{dest}"')
        lines.append(f'BUILT_MODULE_NAME[{i}]="{name}"')
        if len(mod) > 2 and mod[2]:
            lines.append(f'BUILT_MODULE_LOCATION[{i}]="{mod[2]}"')
        lines.append('')

    output_path.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
    print(f"Generated {output_path} with {len(modules)} modules from {pkg_yml_path}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.stderr.write(f"Usage: {sys.argv[0]} <path_to_package.yml> <path_to_output_dkms.conf>\n")
        sys.exit(1)

    generate_dkms_conf(Path(sys.argv[1]), Path(sys.argv[2]))
