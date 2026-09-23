import os
import sys
import subprocess
import json
from pathlib import Path

def run_audit():
    print("=== BẮT ĐẦU AUDIT REPOSITORY & MÔI TRƯỜNG (GEMINI PIPELINE) ===")

    repo_root = Path.cwd()
    print(f"[+] Thư mục làm việc: {repo_root}")

    git_check = subprocess.run(["git", "status"], capture_output=True, text=True)
    if git_check.returncode != 0:
        print("[-] CẢNH BÁO: Thư mục chưa được khởi tạo Git hoặc lỗi Git.")
    else:
        print("[+] Git repository: OK")

    print(f"[+] Phiên bản Python: {sys.version.split()[0]}")

    try:
        import google.genai
        print("[+] Thư viện google-genai: Đã cài đặt")
    except ImportError:
        print("[-] LỖI: Thư viện google-genai chưa được cài đặt.")

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("[-] CẢNH BÁO: Chưa cấu hình biến môi trường GEMINI_API_KEY.")
    else:
        print("[+] GEMINI_API_KEY: Đã được thiết lập.")

    dirs = [
        Path("automation/reviews/requests"),
        Path("automation/reviews/results"),
        Path("reports/automation")
    ]
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
    print("[+] Đã khởi tạo cấu trúc thư mục automation thành công.")

    state_file = Path("automation/state.json")
    if not state_file.exists():
        initial_state = {
            "current_phase": "PHASE_0",
            "status": "AUDITED",
            "reviewer_provider": "GOOGLE_AI_STUDIO",
            "model": os.environ.get("GEMINI_REVIEW_MODEL", "gemini-2.5-flash")
        }
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump(initial_state, f, indent=2)
        print("[+] Đã tạo automation/state.json ban đầu.")

    print("=== HOÀN TẤT PHASE 0 AUDIT ===")

if __name__ == "__main__":
    run_audit()
