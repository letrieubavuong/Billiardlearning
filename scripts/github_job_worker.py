import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from git_change_guard import (
    create_snapshot,
    validate_job_changes,
)

from git_job_manager import (
    GitJobError,
    create_job_branch,
    stage_job_changes,
    commit_job,
    verify_job_commit,
    push_job_branch,
    return_to_main,
    get_current_branch,
)


# ============================================================
# Configuration
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

GH_EXE = Path(
    r"C:\Program Files\GitHub CLI\gh.exe"
)

CONTROL_REPO = (
    "letrieubavuong/"
    "Billiardlearning-AI-Control"
)

CODE_REPO = "letrieubavuong/Billiardlearning"
CI_WORKFLOW = "Billiardlearning CI"
CI_DISCOVERY_TIMEOUT_SECONDS = 120
CI_DISCOVERY_POLL_SECONDS = 5

TRUSTED_GITHUB_USER = "letrieubavuong"

EXPECTED_PROTOCOL = "AGBRIDGE/1.0"
EXPECTED_PROJECT = "Billiardlearning"

CURRENT_TASK_FILE = (
    PROJECT_ROOT
    / "automation"
    / "CURRENT_TASK.md"
)

EXECUTOR_BRIDGE = (
    PROJECT_ROOT
    / "scripts"
    / "executor_bridge.py"
)

WORKER_STATE_FILE = (
    PROJECT_ROOT
    / "automation"
    / "github_worker_state.json"
)

INFRASTRUCTURE_PATHS = {
    "automation/events.jsonl",
    "automation/github_worker_state.json",
}

TERMINAL_STATUSES = {
    "SUCCESS",
    "BLOCKED",
    "FAILED",
    "CI_SUCCESS",
    "CI_FAILED",
}


# ============================================================
# Exceptions
# ============================================================

class ChangeGuardBlockedError(RuntimeError):
    def __init__(
        self,
        message,
        violations=None,
    ):
        super().__init__(message)

        self.violations = (
            violations or []
        )


# ============================================================
# Utilities
# ============================================================

def utc_now():
    return datetime.now(
        timezone.utc
    ).isoformat()


def run_gh(args):
    result = subprocess.run(
        [str(GH_EXE)] + args,
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
        shell=False,
        timeout=60,
    )

    if result.returncode != 0:
        raise RuntimeError(
            "GitHub CLI failed.\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    return result.stdout


def clean_issue_body(body):
    if body is None:
        return ""

    if not isinstance(body, str):
        body = str(body)

    # Remove leading whitespace and BOM artifacts before JSON parsing.
    body = body.lstrip()

    while body.startswith("\ufeff"):
        body = body[1:].lstrip()

    for bad_bom in (
        "Ã¯Â»Â¿",
        "ÃƒÂ¯Ã‚Â»Ã‚Â¿",
        "ï»¿",
    ):
        while body.startswith(bad_bom):
            body = body[len(bad_bom):].lstrip()

    return body.strip()


# ============================================================
# Worker state
# ============================================================

def default_state():
    return {
        "jobs": {}
    }


def migrate_old_state(state):
    if not isinstance(
        state,
        dict,
    ):
        return default_state()

    jobs = state.get("jobs")

    if not isinstance(
        jobs,
        dict,
    ):
        jobs = {}

    old_processed = state.get(
        "processed_issues",
        [],
    )

    if isinstance(
        old_processed,
        list,
    ):
        for issue_number in old_processed:
            key = str(
                issue_number
            )

            if key not in jobs:
                jobs[key] = {
                    "status": "SUCCESS",
                    "updated_at": utc_now(),
                    "note": (
                        "Migrated from "
                        "processed_issues."
                    ),
                }

    return {
        "jobs": jobs
    }


def load_state():
    if not WORKER_STATE_FILE.exists():
        return default_state()

    try:
        raw_state = json.loads(
            WORKER_STATE_FILE.read_text(
                encoding="utf-8-sig"
            )
        )

    except Exception as exc:
        raise RuntimeError(
            "github_worker_state.json "
            f"is invalid: {exc}"
        )

    return migrate_old_state(
        raw_state
    )


def save_state(state):
    WORKER_STATE_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    WORKER_STATE_FILE.write_text(
        json.dumps(
            state,
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )


def get_issue_status(
    state,
    issue_number,
):
    record = state[
        "jobs"
    ].get(
        str(issue_number)
    )

    if not isinstance(
        record,
        dict,
    ):
        return None

    return record.get(
        "status"
    )


def set_issue_status(
    state,
    issue_number,
    status,
    job_id=None,
    message=None,
    branch=None,
    commit_sha=None,
    baseline_sha=None,
    ci_run_id=None,
    ci_status=None,
    ci_conclusion=None,
):
    record = {
        "status": status,
        "updated_at": utc_now(),
    }

    if job_id:
        record[
            "job_id"
        ] = job_id

    if message:
        record[
            "message"
        ] = message

    if branch:
        record[
            "branch"
        ] = branch

    if commit_sha:
        record[
            "commit_sha"
        ] = commit_sha

    if baseline_sha:
        record[
            "baseline_sha"
        ] = baseline_sha

    if ci_run_id is not None:
        record["ci_run_id"] = ci_run_id

    if ci_status:
        record["ci_status"] = ci_status

    if ci_conclusion:
        record["ci_conclusion"] = ci_conclusion

    state["jobs"][
        str(issue_number)
    ] = record

    save_state(state)


def is_terminal(
    state,
    issue_number,
):
    return (
        get_issue_status(
            state,
            issue_number,
        )
        in TERMINAL_STATUSES
    )


# ============================================================
# GitHub comments
# ============================================================

def comment_issue(
    issue_number,
    message,
):
    run_gh([
        "issue",
        "comment",
        str(issue_number),
        "--repo",
        CONTROL_REPO,
        "--body",
        message,
    ])


# ============================================================
# Job validation
# ============================================================

def validate_job(job):
    if not isinstance(
        job,
        dict,
    ):
        raise ValueError(
            "Job body must be "
            "a JSON object."
        )

    if (
        job.get("protocol")
        != EXPECTED_PROTOCOL
    ):
        raise ValueError(
            "Invalid protocol."
        )

    if (
        job.get("project")
        != EXPECTED_PROJECT
    ):
        raise ValueError(
            "Invalid project."
        )

    job_id = job.get(
        "job_id"
    )

    action = job.get(
        "action"
    )

    prompt = job.get(
        "prompt"
    )

    execute_antigravity = (
        job.get(
            "execute_antigravity"
        )
    )

    if (
        not isinstance(
            job_id,
            str,
        )
        or not job_id.strip()
    ):
        raise ValueError(
            "job_id is required."
        )

    if action not in (
        "PING",
        "EXECUTE",
    ):
        raise ValueError(
            "action must be "
            "PING or EXECUTE."
        )

    if (
        not isinstance(
            prompt,
            str,
        )
        or not prompt.strip()
    ):
        raise ValueError(
            "prompt is required."
        )

    if not isinstance(
        execute_antigravity,
        bool,
    ):
        raise ValueError(
            "execute_antigravity "
            "must be boolean."
        )

    if (
        action == "PING"
        and execute_antigravity
    ):
        raise ValueError(
            "PING cannot execute "
            "Antigravity."
        )

    if (
        action == "EXECUTE"
        and not execute_antigravity
    ):
        raise ValueError(
            "EXECUTE requires "
            "execute_antigravity=true."
        )

    if action == "EXECUTE":
        allowed_paths = (
            job.get(
                "allowed_paths"
            )
        )

        if not isinstance(
            allowed_paths,
            list,
        ):
            raise ValueError(
                "EXECUTE requires "
                "allowed_paths."
            )

        if not allowed_paths:
            raise ValueError(
                "allowed_paths "
                "cannot be empty."
            )

        for path in allowed_paths:
            if (
                not isinstance(
                    path,
                    str,
                )
                or not path.strip()
            ):
                raise ValueError(
                    "Every allowed_paths "
                    "entry must be a "
                    "non-empty string."
                )


# ============================================================
# Executor
# ============================================================

def execute_antigravity_job(
    issue_number,
    job_id,
    prompt,
):
    print(
        "[*] Preparing "
        "Antigravity task..."
    )

    original_task = None

    task_existed = (
        CURRENT_TASK_FILE.exists()
    )

    if task_existed:
        original_task = (
            CURRENT_TASK_FILE.read_bytes()
        )

    task_content = (
        "# AI-BRIDGE TASK\n"
        f"- JOB_ID: {job_id}\n"
        f"- SOURCE: GitHub Issue "
        f"#{issue_number}\n"
        "- STATUS: READY\n"
        "\n"
        "## TASK\n"
        f"{prompt.strip()}\n"
    )

    try:
        CURRENT_TASK_FILE.write_text(
            task_content,
            encoding="utf-8",
        )

        print(
            "[+] CURRENT_TASK.md "
            f"prepared for {job_id}."
        )

        print(
            "[*] Calling "
            "executor_bridge.py..."
        )

        result = subprocess.run(
            [
                sys.executable,
                str(EXECUTOR_BRIDGE),
            ],
            cwd=str(PROJECT_ROOT),
            capture_output=True,
            text=True,
            shell=False,
            timeout=1800,
        )

        if result.stdout:
            print(
                "\n=== EXECUTOR OUTPUT ==="
            )

            print(
                result.stdout
            )

        if result.stderr:
            print(
                "\n=== EXECUTOR STDERR ==="
            )

            print(
                result.stderr
            )

        if result.returncode != 0:
            raise RuntimeError(
                "Executor Bridge failed "
                "with return code "
                f"{result.returncode}."
            )

        return result.stdout

    finally:
        print(
            "[*] Restoring previous "
            "CURRENT_TASK.md..."
        )

        if (
            task_existed
            and original_task is not None
        ):
            CURRENT_TASK_FILE.write_bytes(
                original_task
            )

        elif CURRENT_TASK_FILE.exists():
            CURRENT_TASK_FILE.unlink()

        print(
            "[+] CURRENT_TASK.md "
            "restored."
        )


# ============================================================
# Change Guard
# ============================================================

def inspect_job_changes(
    before_snapshot,
    after_snapshot,
    allowed_paths,
):
    job_changes, violations = (
        validate_job_changes(
            before_snapshot,
            after_snapshot,
            allowed_paths,
        )
    )

    infrastructure_changes = [
        path
        for path in job_changes
        if path in INFRASTRUCTURE_PATHS
    ]

    actual_job_changes = [
        path
        for path in job_changes
        if path not in INFRASTRUCTURE_PATHS
    ]

    real_violations = [
        path
        for path in violations
        if path not in INFRASTRUCTURE_PATHS
    ]

    print()
    print(
        "=== CHANGE GUARD ==="
    )

    if actual_job_changes:
        print(
            "[+] Job changed:"
        )

        for path in actual_job_changes:
            print(
                f"    {path}"
            )

    else:
        print(
            "[*] No job file "
            "changes detected."
        )

    if infrastructure_changes:
        print(
            "[*] Infrastructure "
            "side-effects:"
        )

        for path in infrastructure_changes:
            print(
                f"    {path}"
            )

    if real_violations:
        print(
            "[-] SECURITY: "
            "Unauthorized changes:"
        )

        for path in real_violations:
            print(
                f"    {path}"
            )

        raise ChangeGuardBlockedError(
            (
                "Change Guard blocked "
                "the job because files "
                "outside allowed_paths "
                "were modified."
            ),
            violations=real_violations,
        )

    print(
        "[+] Change Guard PASSED."
    )

    return actual_job_changes


# ============================================================
# GitHub Actions CI
# ============================================================

def find_ci_run_for_commit(commit_sha):
    raw = run_gh([
        "run", "list",
        "--repo", CODE_REPO,
        "--workflow", CI_WORKFLOW,
        "--limit", "50",
        "--json", "databaseId,headSha,status,conclusion,url",
    ])
    runs = json.loads(raw)
    for run in runs:
        if run.get("headSha") == commit_sha:
            return run
    return None


def wait_for_ci_run_discovery(commit_sha):
    deadline = time.monotonic() + CI_DISCOVERY_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        run = find_ci_run_for_commit(commit_sha)
        if run is not None:
            return run
        time.sleep(CI_DISCOVERY_POLL_SECONDS)
    return None


def report_ci_pending(issue_number, job_id, branch, commit_sha, ci_run_id=None):
    lines = [
        "GitHub Actions CI is pending.", "",
        f"- Job: `{job_id}`",
        "- Status: `CI_PENDING`",
        f"- Branch: `{branch}`",
        f"- Commit: `{commit_sha}`",
    ]
    if ci_run_id is not None:
        lines.append(f"- CI Run: `{ci_run_id}`")
    lines.append(f"- Checked: `{utc_now()}`")
    comment_issue(issue_number, "\n".join(lines))


def report_ci_terminal(issue_number, job_id, branch, commit_sha, run, success):
    status = "CI_SUCCESS" if success else "CI_FAILED"
    conclusion = run.get("conclusion") or "unknown"
    lines = [
        "GitHub Actions CI completed.", "",
        f"- Job: `{job_id}`",
        f"- Status: `{status}`",
        f"- Branch: `{branch}`",
        f"- Commit: `{commit_sha}`",
        f"- CI Run: `{run.get('databaseId')}`",
        f"- Conclusion: `{conclusion}`",
        f"- Completed: `{utc_now()}`",
    ]
    if not success:
        lines.extend(["", "No automatic retry will be performed."])
    comment_issue(issue_number, "\n".join(lines))


def poll_ci_for_issue(state, issue_number):
    record = state["jobs"].get(str(issue_number)) or {}
    job_id = record.get("job_id") or "UNKNOWN"
    branch = record.get("branch")
    commit_sha = record.get("commit_sha")
    baseline_sha = record.get("baseline_sha")

    if not commit_sha or not branch:
        message = "CI_PENDING record is missing branch or commit_sha."
        set_issue_status(state, issue_number, "FAILED", job_id=job_id,
                         message=message, branch=branch, commit_sha=commit_sha,
                         baseline_sha=baseline_sha)
        try:
            report_failed(issue_number, job_id, message, branch=branch)
        except Exception as exc:
            print(f"[-] Could not post FAILED comment: {exc}")
        return

    print(f"[*] Checking CI for {job_id}...")
    print(f"[+] Commit: {commit_sha}")
    run = find_ci_run_for_commit(commit_sha)
    if run is None:
        print("[*] CI run has not appeared yet. Keeping CI_PENDING.")
        return

    run_id = run.get("databaseId")
    ci_status = run.get("status")
    conclusion = run.get("conclusion")
    print(f"[+] CI Run: {run_id}")
    print(f"[+] CI Status: {ci_status}")
    print(f"[+] CI Conclusion: {conclusion}")

    if ci_status != "completed":
        set_issue_status(state, issue_number, "CI_PENDING", job_id=job_id,
                         message="GitHub Actions CI is still running.", branch=branch,
                         commit_sha=commit_sha, baseline_sha=baseline_sha,
                         ci_run_id=run_id, ci_status=ci_status,
                         ci_conclusion=conclusion)
        return

    success = conclusion == "success"
    terminal = "CI_SUCCESS" if success else "CI_FAILED"
    set_issue_status(state, issue_number, terminal, job_id=job_id,
                     message=f"GitHub Actions completed with conclusion: {conclusion}.",
                     branch=branch, commit_sha=commit_sha,
                     baseline_sha=baseline_sha, ci_run_id=run_id,
                     ci_status=ci_status, ci_conclusion=conclusion)
    try:
        report_ci_terminal(issue_number, job_id, branch, commit_sha, run, success)
    except Exception as exc:
        print(f"[-] Could not post {terminal} comment: {exc}")
    print(f"[+] {terminal}")


# ============================================================
# Reporting
# ============================================================

def report_ping_success(
    issue_number,
    job_id,
):
    comment_issue(
        issue_number,
        (
            "AI-Bridge received this "
            "job successfully.\n\n"
            f"- Job: `{job_id}`\n"
            "- Result: "
            "`GITHUB_BRIDGE_OK`\n"
            f"- Time: `{utc_now()}`"
        ),
    )


def report_running(
    issue_number,
    job_id,
    branch,
    baseline_sha,
):
    comment_issue(
        issue_number,
        (
            "AI-Bridge accepted this job "
            "and created an isolated "
            "Git branch.\n\n"
            f"- Job: `{job_id}`\n"
            "- Status: `RUNNING`\n"
            f"- Branch: `{branch}`\n"
            f"- Baseline: "
            f"`{baseline_sha}`\n"
            f"- Started: `{utc_now()}`"
        ),
    )


def report_git_pushed(
    issue_number,
    job_id,
    branch,
    commit_sha,
    changed_paths,
):
    changed_text = "\n".join(
        f"- `{path}`"
        for path in changed_paths
    )

    comment_issue(
        issue_number,
        (
            "Antigravity execution, "
            "Change Guard, commit and "
            "push completed.\n\n"
            f"- Job: `{job_id}`\n"
            "- Status: `GIT_PUSHED`\n"
            f"- Branch: `{branch}`\n"
            f"- Commit: `{commit_sha}`\n"
            f"- Completed: `{utc_now()}`"
            "\n\n"
            "Committed job changes:\n"
            f"{changed_text}"
        ),
    )


def report_blocked(
    issue_number,
    job_id,
    message,
    violations=None,
    branch=None,
):
    lines = [
        "AI-Bridge blocked this job.",
        "",
        f"- Job: `{job_id}`",
        "- Status: `BLOCKED`",
    ]

    if branch:
        lines.append(
            f"- Branch: `{branch}`"
        )

    lines.extend([
        f"- Reason: `{message}`",
        f"- Time: `{utc_now()}`",
    ])

    if violations:
        lines.extend([
            "",
            "Unauthorized changes:",
        ])

        for path in violations:
            lines.append(
                f"- `{path}`"
            )

    lines.extend([
        "",
        "No automatic retry will "
        "be performed.",
    ])

    comment_issue(
        issue_number,
        "\n".join(lines),
    )


def report_failed(
    issue_number,
    job_id,
    message,
    branch=None,
):
    lines = [
        "AI-Bridge execution failed.",
        "",
        f"- Job: `{job_id}`",
        "- Status: `FAILED`",
    ]

    if branch:
        lines.append(
            f"- Branch: `{branch}`"
        )

    lines.extend([
        f"- Error: `{message}`",
        f"- Time: `{utc_now()}`",
        "",
        "No automatic retry will "
        "be performed.",
    ])

    comment_issue(
        issue_number,
        "\n".join(lines),
    )


# ============================================================
# EXECUTE pipeline
# ============================================================

def run_execute_pipeline(
    state,
    issue_number,
    job_id,
    prompt,
    allowed_paths,
):
    branch_name = None
    baseline_sha = None

    # --------------------------------------------------------
    # 1. Create isolated Git branch
    # --------------------------------------------------------

    print(
        "[*] Verifying clean main "
        "and creating job branch..."
    )

    branch_info = create_job_branch(
        job_id
    )

    branch_name = branch_info[
        "branch"
    ]

    baseline_sha = branch_info[
        "baseline_sha"
    ]

    print(
        f"[+] Job branch: "
        f"{branch_name}"
    )

    print(
        f"[+] Baseline: "
        f"{baseline_sha}"
    )

    set_issue_status(
        state,
        issue_number,
        "RUNNING",
        job_id=job_id,
        message=(
            "Isolated branch created."
        ),
        branch=branch_name,
        baseline_sha=baseline_sha,
    )

    try:
        report_running(
            issue_number,
            job_id,
            branch_name,
            baseline_sha,
        )

    except Exception as exc:
        print(
            "[-] Could not post "
            "RUNNING comment: "
            f"{exc}"
        )

    # --------------------------------------------------------
    # 2. Snapshot AFTER infrastructure bookkeeping
    # --------------------------------------------------------

    print(
        "[*] Capturing BEFORE "
        "snapshot..."
    )

    before_snapshot = (
        create_snapshot()
    )

    print(
        f"[+] BEFORE snapshot: "
        f"{len(before_snapshot)} "
        "dirty paths."
    )

    # --------------------------------------------------------
    # 3. Antigravity
    # --------------------------------------------------------

    execute_antigravity_job(
        issue_number,
        job_id,
        prompt,
    )

    # --------------------------------------------------------
    # 4. Change Guard
    # --------------------------------------------------------

    print(
        "[*] Capturing AFTER "
        "snapshot..."
    )

    after_snapshot = (
        create_snapshot()
    )

    print(
        f"[+] AFTER snapshot: "
        f"{len(after_snapshot)} "
        "dirty paths."
    )

    actual_job_changes = (
        inspect_job_changes(
            before_snapshot,
            after_snapshot,
            allowed_paths,
        )
    )

    if not actual_job_changes:
        raise GitJobError(
            "Antigravity produced no "
            "committable job changes."
        )

    # --------------------------------------------------------
    # 5. Stage ONLY approved paths
    # --------------------------------------------------------

    print()
    print(
        "=== GIT STAGING ==="
    )

    staged_paths = (
        stage_job_changes(
            actual_job_changes
        )
    )

    print(
        "[+] Staged approved paths:"
    )

    for path in staged_paths:
        print(
            f"    {path}"
        )

    # --------------------------------------------------------
    # 6. Commit
    # --------------------------------------------------------

    print(
        "[*] Creating job commit..."
    )

    commit_sha = commit_job(
        job_id,
        issue_number,
    )

    print(
        f"[+] Commit: {commit_sha}"
    )

    # --------------------------------------------------------
    # 7. Verify exact commit
    # --------------------------------------------------------

    print(
        "[*] Verifying committed "
        "change-set..."
    )

    committed_paths = (
        verify_job_commit(
            branch_name,
            baseline_sha,
            actual_job_changes,
        )
    )

    print(
        "[+] Commit verification "
        "PASSED."
    )

    # --------------------------------------------------------
    # 8. Ensure no leftovers
    # --------------------------------------------------------

    from git_job_manager import (
        get_dirty_paths,
    )

    leftovers = get_dirty_paths()

    # events.jsonl is tracked and may be changed
    # by executor_bridge. It must not silently
    # travel with the job.
    non_infra_leftovers = [
        path
        for path in leftovers
        if path not in INFRASTRUCTURE_PATHS
    ]

    if non_infra_leftovers:
        raise GitJobError(
            "Unexpected uncommitted "
            "changes remain after commit:\n"
            + "\n".join(
                f"- {path}"
                for path
                in non_infra_leftovers
            )
        )

    # events.jsonl is a tracked runtime log.
    # Restore only this known infrastructure file
    # before push/return-to-main.
    if (
        "automation/events.jsonl"
        in leftovers
    ):
        print(
            "[*] Restoring tracked "
            "runtime event log..."
        )

        result = subprocess.run(
            [
                "git",
                "restore",
                "--",
                "automation/events.jsonl",
            ],
            cwd=str(PROJECT_ROOT),
            capture_output=True,
            text=True,
            shell=False,
            timeout=60,
        )

        if result.returncode != 0:
            raise GitJobError(
                "Could not restore "
                "automation/events.jsonl.\n"
                f"{result.stderr}"
            )

    # --------------------------------------------------------
    # 9. Push isolated branch
    # --------------------------------------------------------

    print(
        "[*] Pushing job branch..."
    )

    pushed_sha = (
        push_job_branch(
            branch_name
        )
    )

    if pushed_sha != commit_sha:
        raise GitJobError(
            "Pushed SHA does not match "
            "job commit SHA."
        )

    print(
        f"[+] Branch pushed: "
        f"{branch_name}"
    )

    # --------------------------------------------------------
    # 10. Return to main
    # --------------------------------------------------------

    print(
        "[*] Returning worker "
        "to main..."
    )

    returned_branch = (
        return_to_main()
    )

    if returned_branch != "main":
        raise GitJobError(
            "Worker did not return "
            "to main."
        )

    print(
        "[+] Worker returned to main."
    )

    # --------------------------------------------------------
    # 11. Terminal state
    # --------------------------------------------------------

    set_issue_status(
        state,
        issue_number,
        "GIT_PUSHED",
        job_id=job_id,
        message=(
            "Job committed and pushed "
            "to isolated branch."
        ),
        branch=branch_name,
        commit_sha=commit_sha,
        baseline_sha=baseline_sha,
        ci_status="awaiting_discovery",
    )

    try:
        report_git_pushed(
            issue_number,
            job_id,
            branch_name,
            commit_sha,
            committed_paths,
        )

    except Exception as exc:
        print(
            "[-] Could not post "
            "GIT_PUSHED comment: "
            f"{exc}"
        )

    print("[*] Looking for GitHub Actions CI run...")
    ci_run = wait_for_ci_run_discovery(commit_sha)
    ci_run_id = ci_run.get("databaseId") if ci_run else None
    ci_status = ci_run.get("status") if ci_run else "not_found_yet"
    ci_conclusion = ci_run.get("conclusion") if ci_run else None

    set_issue_status(
        state, issue_number, "CI_PENDING", job_id=job_id,
        message="Waiting for GitHub Actions CI result.",
        branch=branch_name, commit_sha=commit_sha, baseline_sha=baseline_sha,
        ci_run_id=ci_run_id, ci_status=ci_status, ci_conclusion=ci_conclusion,
    )

    try:
        report_ci_pending(issue_number, job_id, branch_name, commit_sha, ci_run_id)
    except Exception as exc:
        print(f"[-] Could not post CI_PENDING comment: {exc}")

    if ci_run:
        print(f"[+] CI Run discovered: {ci_run_id} ({ci_status})")
    else:
        print("[*] CI run not visible yet; a later worker poll will continue.")

    print()
    print(
        "[+] JOB PIPELINE SUCCESS."
    )

    print(
        f"[+] Branch : {branch_name}"
    )

    print(
        f"[+] Commit : {commit_sha}"
    )

    return {
        "branch": branch_name,
        "commit_sha": commit_sha,
        "baseline_sha": baseline_sha,
        "changed_paths": committed_paths,
    }


# ============================================================
# Job processor
# ============================================================

def process_issue(
    issue,
    state,
):
    number = issue["number"]
    title = issue["title"]

    author = (
        issue.get("author")
        or {}
    )

    login = author.get(
        "login"
    )

    print(
        f"[+] Found issue "
        f"#{number}"
    )

    print(
        f"[+] Title : {title}"
    )

    print(
        f"[+] Author: {login}"
    )

    if login != TRUSTED_GITHUB_USER:
        message = (
            "Untrusted issue author."
        )

        print(
            f"[-] SECURITY: {message}"
        )

        set_issue_status(
            state,
            number,
            "BLOCKED",
            message=message,
        )

        return

    if is_terminal(
        state,
        number,
    ):
        status = get_issue_status(
            state,
            number,
        )

        print(
            f"[*] Issue #{number} "
            "already has terminal "
            f"status: {status}"
        )

        return

    raw = run_gh([
        "issue",
        "view",
        str(number),
        "--repo",
        CONTROL_REPO,
        "--json",
        "number,title,body,author",
    ])

    data = json.loads(
        raw
    )

    body = clean_issue_body(
        data.get("body") or ""
    )

    if not body:
        message = (
            "Issue body is empty."
        )

        set_issue_status(
            state,
            number,
            "FAILED",
            message=message,
        )

        print(
            f"[-] {message}"
        )

        return

    try:
        job = json.loads(
            body
        )

    except json.JSONDecodeError as exc:
        message = (
            f"Invalid job JSON: "
            f"{exc}"
        )

        print(
            f"[-] {message}"
        )

        set_issue_status(
            state,
            number,
            "FAILED",
            message=message,
        )

        return

    try:
        validate_job(
            job
        )

    except Exception as exc:
        message = str(
            exc
        )

        job_id = job.get(
            "job_id"
        )

        print(
            "[-] Job validation "
            f"failed: {message}"
        )

        set_issue_status(
            state,
            number,
            "FAILED",
            job_id=job_id,
            message=message,
        )

        try:
            report_failed(
                number,
                job_id or "UNKNOWN",
                message,
            )

        except Exception as comment_exc:
            print(
                "[-] Could not post "
                "FAILED comment: "
                f"{comment_exc}"
            )

        return

    job_id = job[
        "job_id"
    ]

    action = job[
        "action"
    ]

    prompt = job[
        "prompt"
    ]

    execute_flag = job[
        "execute_antigravity"
    ]

    allowed_paths = job.get(
        "allowed_paths",
        [],
    )

    print(
        f"[+] Job ID : {job_id}"
    )

    print(
        f"[+] Action : {action}"
    )

    print(
        "[+] Execute Antigravity: "
        f"{execute_flag}"
    )

    # --------------------------------------------------------
    # PING
    # --------------------------------------------------------

    if action == "PING":
        print()
        print(
            "GITHUB_BRIDGE_OK"
        )
        print()

        try:
            report_ping_success(
                number,
                job_id,
            )

        except Exception as exc:
            print(
                "[-] Could not post "
                "PING comment: "
                f"{exc}"
            )

        set_issue_status(
            state,
            number,
            "SUCCESS",
            job_id=job_id,
            message="GITHUB_BRIDGE_OK",
        )

        print(
            "[+] GitHub job transport "
            "test PASSED."
        )

        return

    # --------------------------------------------------------
    # EXECUTE
    # --------------------------------------------------------

    branch_name = None

    try:
        result = (
            run_execute_pipeline(
                state,
                number,
                job_id,
                prompt,
                allowed_paths,
            )
        )

        branch_name = result[
            "branch"
        ]

    except ChangeGuardBlockedError as exc:
        branch_name = (
            get_current_branch()
        )

        message = str(
            exc
        )

        print(
            f"[-] JOB BLOCKED: "
            f"{message}"
        )

        set_issue_status(
            state,
            number,
            "BLOCKED",
            job_id=job_id,
            message=message,
            branch=branch_name,
        )

        try:
            report_blocked(
                number,
                job_id,
                message,
                violations=(
                    exc.violations
                ),
                branch=branch_name,
            )

        except Exception as comment_exc:
            print(
                "[-] Could not post "
                "BLOCKED comment: "
                f"{comment_exc}"
            )

        print(
            "[!] Dirty job branch "
            "has been preserved for "
            "inspection."
        )

        return

    except Exception as exc:
        current_branch = (
            get_current_branch()
        )

        if (
            current_branch
            and current_branch != "main"
        ):
            branch_name = (
                current_branch
            )

        message = str(
            exc
        )

        print(
            "[-] EXECUTION FAILED: "
            f"{message}"
        )

        set_issue_status(
            state,
            number,
            "FAILED",
            job_id=job_id,
            message=message,
            branch=branch_name,
        )

        try:
            report_failed(
                number,
                job_id,
                message,
                branch=branch_name,
            )

        except Exception as comment_exc:
            print(
                "[-] Could not post "
                "FAILED comment: "
                f"{comment_exc}"
            )

        print(
            "[!] Automatic destructive "
            "cleanup was not performed."
        )

        return


# ============================================================
# Main
# ============================================================

def main():
    print(
        "=== GITHUB JOB WORKER ==="
    )

    if not GH_EXE.exists():
        print(
            "[-] ERROR: GitHub CLI "
            f"not found: {GH_EXE}"
        )

        sys.exit(1)

    if not EXECUTOR_BRIDGE.exists():
        print(
            "[-] ERROR: Executor Bridge "
            f"not found: "
            f"{EXECUTOR_BRIDGE}"
        )

        sys.exit(1)

    try:
        state = load_state()

        save_state(
            state
        )

    except Exception as exc:
        print(
            "[-] ERROR loading "
            "worker state: "
            f"{exc}"
        )

        sys.exit(1)

    try:
        raw = run_gh([
            "issue",
            "list",
            "--repo",
            CONTROL_REPO,
            "--state",
            "open",
            "--search",
            "[AI-JOB] in:title",
            "--json",
            "number,title,author",
            "--limit",
            "50",
        ])

        issues = json.loads(
            raw
        )

    except Exception as exc:
        print(
            "[-] ERROR reading "
            "GitHub jobs: "
            f"{exc}"
        )

        sys.exit(1)

    # Resume CI monitoring before accepting a new execution job.
    for issue_key, record in sorted(
        state["jobs"].items(),
        key=lambda item: int(item[0]) if str(item[0]).isdigit() else 10**18,
    ):
        if not isinstance(record, dict):
            continue
        status = record.get("status")

        if status == "CI_PENDING":
            poll_ci_for_issue(state, int(issue_key))
            return

        if (
            status == "GIT_PUSHED"
            and record.get("ci_status") == "awaiting_discovery"
        ):
            poll_ci_for_issue(state, int(issue_key))
            return

    if not issues:
        print(
            "[*] No pending AI jobs."
        )

        return

    issues = sorted(
        issues,
        key=lambda item: (
            item["number"]
        ),
    )

    pending_issue = None

    for issue in issues:
        number = issue[
            "number"
        ]

        if is_terminal(
            state,
            number,
        ):
            continue

        status = (
            get_issue_status(
                state,
                number,
            )
        )

        if status == "RUNNING":
            print(
                f"[!] Issue #{number} "
                "is already RUNNING."
            )

            print(
                "[!] Automatic retry "
                "is disabled."
            )

            continue

        # Legacy jobs may have GIT_PUSHED from before CI tracking existed.
        # They have no CI marker and must never be executed again.
        record = state["jobs"].get(str(number)) or {}
        if (
            status == "GIT_PUSHED"
            and record.get("ci_status") != "awaiting_discovery"
        ):
            print(
                f"[*] Skipping legacy "
                f"GIT_PUSHED issue #{number}."
            )
            continue

        pending_issue = issue
        break

    if pending_issue is None:
        print(
            "[*] No unprocessed "
            "AI jobs."
        )

        return

    try:
        process_issue(
            pending_issue,
            state,
        )

    except Exception as exc:
        print(
            "[-] Unexpected worker "
            f"error: {exc}"
        )


if __name__ == "__main__":
    main()