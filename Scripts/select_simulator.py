#!/usr/bin/env python3
import argparse
import json
import re
import shlex
from pathlib import Path


def runtime_version(identifier: str):
    match = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+(?:-\d+)*)", identifier)
    return tuple(map(int, match.group(1).split("-"))) if match else None


def main():
    parser = argparse.ArgumentParser(description="Select a deterministic iOS simulator for LINART CI.")
    parser.add_argument("--devices-json", type=Path, required=True)
    parser.add_argument("--family", choices=["iPhone", "iPad"], required=True)
    parser.add_argument("--preferred-name")
    parser.add_argument("--runtime-major", type=int, default=26)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    payload = json.loads(args.devices_json.read_text())
    candidates = []
    for runtime, devices in payload["devices"].items():
        version = runtime_version(runtime)
        if not version or version[0] != args.runtime_major:
            continue
        for device in devices:
            if not device.get("isAvailable") or not device["name"].startswith(args.family):
                continue
            candidates.append((version, device["name"], device["udid"], runtime))

    if not candidates:
        raise SystemExit(f"No available {args.family} simulator on iOS {args.runtime_major}.x")

    preferred = [item for item in candidates if args.preferred_name and item[1] == args.preferred_name]
    if args.preferred_name and not preferred:
        names = sorted({item[1] for item in candidates})
        raise SystemExit(
            f"Preferred simulator {args.preferred_name!r} is unavailable. "
            f"Available {args.family} devices: {', '.join(names)}"
        )

    pool = preferred or candidates
    selected = sorted(pool, key=lambda item: (item[0], item[1]), reverse=True)[0]
    version, name, udid, runtime = selected
    args.output.parent.mkdir(parents=True, exist_ok=True)
    values = {
        "LINART_SIMULATOR_FAMILY": args.family,
        "LINART_SIMULATOR_NAME": name,
        "LINART_SIMULATOR_ID": udid,
        "LINART_SIMULATOR_RUNTIME": runtime,
        "LINART_SIMULATOR_VERSION": ".".join(map(str, version)),
    }
    args.output.write_text("".join(f"{key}={shlex.quote(value)}\n" for key, value in values.items()))
    print(f"Selected {name} on iOS {values['LINART_SIMULATOR_VERSION']} ({udid})")


if __name__ == "__main__":
    main()
