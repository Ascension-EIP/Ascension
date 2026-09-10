#!/usr/bin/env python3
# @date 2026-09-10
# @file update_moon.py
# @brief Script to update moon on the local machine and sync versions across the repository.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
import re
import shutil
import subprocess
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def upgrade_moon():
    print("🚀 Upgrading moon...")
    if shutil.which("proto"):
        print("Detected proto, running 'proto install moon --pin'...")
        try:
            subprocess.run(["proto", "install", "moon", "--pin"], check=True)
            return
        except subprocess.CalledProcessError as e:
            print(f"⚠️  proto install moon failed: {e}, falling back to moon upgrade")

    print("Running 'moon upgrade'...")
    res = subprocess.run(["moon", "upgrade"], capture_output=True, text=True)
    if res.stdout:
        print(res.stdout.strip())
    if res.stderr and res.returncode != 0:
        if "daemon::client::connect_failed" in res.stderr:
            print("Notice: Daemon socket connection skipped during upgrade.")
        else:
            print(f"Warning: moon upgrade output: {res.stderr.strip()}")


def get_moon_version():
    try:
        res = subprocess.run(["moon", "--version"], capture_output=True, text=True, check=True)
        return res.stdout.strip().split()[-1]
    except Exception as e:
        print(f"❌ Failed to get moon version: {e}")
        sys.exit(1)


def update_repo_files(version):
    print(f"🔄 Synchronizing moon version ({version}) across repository files...")
    updated_files = []
    seen_realpaths = set()

    # 1. .prototools
    prototools_path = os.path.join(REPO_ROOT, ".prototools")
    if os.path.exists(prototools_path):
        with open(prototools_path, "r", encoding="utf-8") as f:
            content = f.read()
        new_content = re.sub(r'moon\s*=\s*"[^"]*"', f'moon = "{version}"', content)
        if new_content != content:
            with open(prototools_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            updated_files.append(".prototools")
        seen_realpaths.add(os.path.realpath(prototools_path))

    # 2. Documentation and AI prompt files
    doc_files = [
        "docs/20-engineering/ai/instructions.md",
        "docs/20-engineering/ai/pre-prompt-en.md",
        "docs/20-engineering/ai/pre-prompt-fr.md",
    ]
    for rel_path in doc_files:
        full_path = os.path.join(REPO_ROOT, rel_path)
        real_path = os.path.realpath(full_path)
        if os.path.exists(full_path) and real_path not in seen_realpaths:
            with open(full_path, "r", encoding="utf-8") as f:
                content = f.read()
            new_content = re.sub(r"moonrepo `[^`]+`", f"moonrepo `{version}`", content)
            if new_content != content:
                with open(full_path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                updated_files.append(rel_path)
            seen_realpaths.add(real_path)

    if updated_files:
        print(f"✔ Updated {len(updated_files)} file(s):")
        for f in updated_files:
            print(f"  - {f}")
    else:
        print("✔ All repository files are already up to date.")


def main():
    os.chdir(REPO_ROOT)
    upgrade_moon()
    version = get_moon_version()
    update_repo_files(version)
    print(f"✨ Successfully updated moon to v{version}!")


if __name__ == "__main__":
    main()
