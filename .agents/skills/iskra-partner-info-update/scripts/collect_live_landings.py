#!/usr/bin/env python3
"""Delegate the landing collector to the shell implementation."""

import os
import sys


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    shell_script = os.path.join(script_dir, "collect_live_landings.sh")
    if not os.path.exists(shell_script):
        raise SystemExit(f"missing helper script: {shell_script}")
    os.execvp("bash", ["bash", shell_script, *sys.argv[1:]])


if __name__ == "__main__":
    main()
