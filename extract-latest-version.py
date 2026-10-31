#!/usr/bin/env python3
"""Extract latest upstream version from package.yml."""
import sys
from pathlib import Path
import yaml


def get_version(pkg_yml_path: Path) -> str:
    with open(pkg_yml_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    changelog = data.get("changelog", [])
    if changelog and "version" in changelog[0]:
        return str(changelog[0]["version"])

    sys.stderr.write(f"Error: Could not find version in changelog of {pkg_yml_path}\n")
    sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.stderr.write(f"Usage: {sys.argv[0]} <path_to_package.yml>\n")
        sys.exit(1)

    print(get_version(Path(sys.argv[1])))
