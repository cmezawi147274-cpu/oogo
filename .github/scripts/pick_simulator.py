"""Print the UDID of the best available iPhone simulator on this runner.

Prefers the newest iOS runtime, then a plain "iPhone NN Pro" over other models.
"""

import json
import re
import subprocess
import sys


def runtime_version(key: str) -> tuple:
    # e.g. com.apple.CoreSimulator.SimRuntime.iOS-26-2
    match = re.search(r"iOS-(\d+)-(\d+)", key)
    return (int(match.group(1)), int(match.group(2))) if match else (0, 0)


def model_rank(name: str) -> tuple:
    match = re.match(r"iPhone (\d+)( Pro)?$", name)
    if not match:
        return (0, 0)
    return (int(match.group(1)), 1 if match.group(2) else 0)


def main() -> None:
    data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
    best = None
    for runtime, devices in data["devices"].items():
        if ".iOS-" not in runtime:
            continue
        for device in devices:
            if not device["name"].startswith("iPhone"):
                continue
            score = (runtime_version(runtime), model_rank(device["name"]))
            if best is None or score > best[0]:
                best = (score, device["udid"], device["name"], runtime)
    if best is None:
        sys.exit("No iPhone simulator available")
    print(f"{best[2]} on {best[3]}", file=sys.stderr)
    print(best[1])


if __name__ == "__main__":
    main()
