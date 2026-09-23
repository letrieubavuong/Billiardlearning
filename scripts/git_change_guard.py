import hashlib
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def run_git(args):
    result = subprocess.run(
        ["git"] + args,
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
        shell=False,
        timeout=60,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"Git failed: {' '.join(args)}\n"
            f"{result.stderr}"
        )

    return result.stdout


def get_changed_files():
    raw = run_git([
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
    ])

    paths = set()

    for line in raw.splitlines():
        if not line:
            continue

        path = line[3:].strip()

        if " -> " in path:
            path = path.split(" -> ", 1)[1]

        path = path.replace("\\", "/")

        if path:
            paths.add(path)

    return paths


def file_fingerprint(relative_path):
    path = PROJECT_ROOT / relative_path

    if not path.exists():
        return "__DELETED__"

    if not path.is_file():
        return "__NOT_FILE__"

    digest = hashlib.sha256()

    with path.open("rb") as f:
        while True:
            chunk = f.read(1024 * 1024)

            if not chunk:
                break

            digest.update(chunk)

    return digest.hexdigest()


def create_snapshot():
    changed = get_changed_files()

    return {
        path: file_fingerprint(path)
        for path in changed
    }


def normalize_allowed_paths(values):
    result = []

    for value in values:
        if not isinstance(value, str):
            continue

        value = value.strip()
        value = value.replace("\\", "/")
        value = value.strip("/")

        if value:
            result.append(value)

    return result


def path_is_allowed(path, allowed_paths):
    path = path.replace("\\", "/").strip("/")

    for allowed in allowed_paths:
        if path == allowed:
            return True

        if path.startswith(allowed + "/"):
            return True

    return False


def compare_snapshots(before, after):
    """
    Detect:
    - newly dirty files
    - dirty files whose contents changed during the job
    - dirty files removed/restored during the job
    """

    all_paths = set(before) | set(after)

    changed_during_job = []

    for path in sorted(all_paths):
        before_value = before.get(path, "__CLEAN__")
        after_value = after.get(path, "__CLEAN__")

        if before_value != after_value:
            changed_during_job.append(path)

    return changed_during_job


def validate_job_changes(before, after, allowed_paths):
    allowed_paths = normalize_allowed_paths(
        allowed_paths
    )

    job_changes = compare_snapshots(
        before,
        after,
    )

    violations = [
        path
        for path in job_changes
        if not path_is_allowed(
            path,
            allowed_paths,
        )
    ]

    return job_changes, violations


def main():
    print("=== GIT CHANGE GUARD ===")

    snapshot = create_snapshot()

    if not snapshot:
        print("[+] Working tree is clean.")
        return

    print("[+] Current dirty paths:")

    for path in sorted(snapshot):
        fingerprint = snapshot[path]

        if len(fingerprint) == 64:
            short_hash = fingerprint[:12]
        else:
            short_hash = fingerprint

        print(
            f"    {path}  [{short_hash}]"
        )

    print()
    print(f"[+] Total: {len(snapshot)}")
    print(
        "[+] Content fingerprints captured."
    )


if __name__ == "__main__":
    main()