import re
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
REMOTE_NAME = "origin"
BASE_BRANCH = "main"


class GitJobError(RuntimeError):
    pass


def run_git(args, check=True):
    result = subprocess.run(
        ["git"] + args,
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
        shell=False,
        timeout=120,
    )

    if check and result.returncode != 0:
        raise GitJobError(
            f"Git command failed: git {' '.join(args)}\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    return result


def get_current_branch():
    return run_git(
        ["branch", "--show-current"]
    ).stdout.strip()


def get_head_sha():
    return run_git(
        ["rev-parse", "HEAD"]
    ).stdout.strip()


def get_remote_main_sha():
    output = run_git([
        "ls-remote",
        REMOTE_NAME,
        f"refs/heads/{BASE_BRANCH}",
    ]).stdout.strip()

    if not output:
        raise GitJobError(
            "Could not resolve origin/main."
        )

    return output.split()[0]


def get_dirty_paths():
    output = run_git([
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
    ]).stdout

    paths = []

    for line in output.splitlines():
        if not line:
            continue

        path = line[3:].strip()

        if " -> " in path:
            path = path.split(
                " -> ",
                1,
            )[1]

        path = path.replace("\\", "/")

        if path:
            paths.append(path)

    return sorted(set(paths))


def ensure_clean_main():
    branch = get_current_branch()

    if branch != BASE_BRANCH:
        raise GitJobError(
            f"Expected branch '{BASE_BRANCH}', "
            f"but current branch is '{branch}'."
        )

    dirty_paths = get_dirty_paths()

    if dirty_paths:
        formatted = "\n".join(
            f"- {path}"
            for path in dirty_paths
        )

        raise GitJobError(
            "Working tree is not clean:\n"
            f"{formatted}"
        )

    local_sha = get_head_sha()
    remote_sha = get_remote_main_sha()

    if local_sha != remote_sha:
        raise GitJobError(
            "Local main is not synchronized "
            "with origin/main.\n"
            f"Local : {local_sha}\n"
            f"Remote: {remote_sha}"
        )

    return local_sha


def sanitize_job_id(job_id):
    value = job_id.strip().lower()

    value = re.sub(
        r"[^a-z0-9._-]+",
        "-",
        value,
    )

    value = value.strip("-.")

    if not value:
        raise GitJobError(
            "Invalid job_id for branch name."
        )

    return value


def branch_name_for_job(job_id):
    safe_job_id = sanitize_job_id(job_id)

    return f"ai/{safe_job_id}"


def local_branch_exists(branch_name):
    result = run_git(
        [
            "show-ref",
            "--verify",
            "--quiet",
            f"refs/heads/{branch_name}",
        ],
        check=False,
    )

    return result.returncode == 0


def remote_branch_exists(branch_name):
    output = run_git([
        "ls-remote",
        "--heads",
        REMOTE_NAME,
        branch_name,
    ]).stdout.strip()

    return bool(output)


def create_job_branch(job_id):
    ensure_clean_main()

    branch_name = branch_name_for_job(
        job_id
    )

    if local_branch_exists(branch_name):
        raise GitJobError(
            "Local job branch already exists: "
            f"{branch_name}"
        )

    if remote_branch_exists(branch_name):
        raise GitJobError(
            "Remote job branch already exists: "
            f"{branch_name}"
        )

    run_git([
        "switch",
        "-c",
        branch_name,
    ])

    current = get_current_branch()

    if current != branch_name:
        raise GitJobError(
            "Failed to switch to job branch."
        )

    return branch_name


def normalize_paths(paths):
    normalized = []

    for path in paths:
        if not isinstance(path, str):
            raise GitJobError(
                "Changed path must be a string."
            )

        value = (
            path
            .replace("\\", "/")
            .strip("/")
        )

        if not value:
            raise GitJobError(
                "Empty changed path."
            )

        if value.startswith("../"):
            raise GitJobError(
                f"Unsafe path: {value}"
            )

        normalized.append(value)

    return sorted(set(normalized))


def stage_job_changes(paths):
    paths = normalize_paths(paths)

    if not paths:
        raise GitJobError(
            "Job produced no files to stage."
        )

    # Stage only paths explicitly returned
    # by the Change Guard.
    run_git(
        ["add", "--"] + paths
    )

    staged = get_staged_paths()

    unexpected = [
        path
        for path in staged
        if path not in paths
    ]

    missing = [
        path
        for path in paths
        if path not in staged
    ]

    if unexpected:
        raise GitJobError(
            "Unexpected staged paths:\n"
            + "\n".join(
                f"- {path}"
                for path in unexpected
            )
        )

    if missing:
        raise GitJobError(
            "Expected job paths were not staged:\n"
            + "\n".join(
                f"- {path}"
                for path in missing
            )
        )

    return staged


def get_staged_paths():
    output = run_git([
        "diff",
        "--cached",
        "--name-only",
        "--diff-filter=ACDMRTUXB",
    ]).stdout

    return sorted(
        path.strip().replace("\\", "/")
        for path in output.splitlines()
        if path.strip()
    )


def commit_job(job_id, issue_number):
    staged = get_staged_paths()

    if not staged:
        raise GitJobError(
            "Nothing is staged for commit."
        )

    message = (
        f"chore(ai): execute {job_id} "
        f"from control issue #{issue_number}"
    )

    run_git([
        "commit",
        "-m",
        message,
    ])

    return get_head_sha()


def push_job_branch(branch_name):
    if get_current_branch() != branch_name:
        raise GitJobError(
            "Refusing to push: current branch "
            "does not match job branch."
        )

    run_git([
        "push",
        "-u",
        REMOTE_NAME,
        branch_name,
    ])

    return get_head_sha()


def return_to_main():
    dirty_paths = get_dirty_paths()

    if dirty_paths:
        formatted = "\n".join(
            f"- {path}"
            for path in dirty_paths
        )

        raise GitJobError(
            "Cannot return to main because "
            "working tree is dirty:\n"
            f"{formatted}"
        )

    run_git([
        "switch",
        BASE_BRANCH,
    ])

    return get_current_branch()


def main():
    print("=== GIT JOB MANAGER SELF-CHECK ===")

    print(
        f"[+] Branch: {get_current_branch()}"
    )

    print(
        f"[+] HEAD: {get_head_sha()}"
    )

    dirty = get_dirty_paths()

    if dirty:
        print("[-] Working tree is dirty:")

        for path in dirty:
            print(f"    {path}")

    else:
        print("[+] Working tree is clean.")

    try:
        baseline = ensure_clean_main()

        print(
            "[+] main matches origin/main."
        )

        print(
            f"[+] Baseline: {baseline}"
        )

    except GitJobError as exc:
        print(
            f"[-] Self-check blocked: {exc}"
        )


if __name__ == "__main__":
    main()