#!/usr/bin/env python3
"""Delegate the landing collector to the shell implementation."""

import os
import sys


def main() -> int:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    shell_script = os.path.join(script_dir, "collect_live_landings.sh")
    if not os.path.exists(shell_script):
        raise SystemExit(f"missing helper script: {shell_script}")
    os.execv("/bin/bash", ["/bin/bash", shell_script, *sys.argv[1:]])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
