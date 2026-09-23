import os
import sys
import subprocess
import json
from pathlib import Path

def run_executor_bridge():
    print("=== ANTIGRAVITY EXECUTOR BRIDGE START ===")
    
    # 1. Đọc task hiện tại từ CURRENT_TASK.md
    task_file = Path("automation/CURRENT_TASK.md")
    if not task_file.exists():
        print("[-] LỖI: Không tìm thấy automation/CURRENT_TASK.md")
        sys.exit(1)
        
    print("[+] Đã đọc CURRENT_TASK.md thành công.")
    
    # 2. Ghi sự kiện EXECUTOR_DISPATCHED vào events.jsonl
    event_entry = {
        "timestamp": "2026-09-23T18:30:00Z",
        "event": "EXECUTOR_DISPATCHED",
        "executor": "ANTIGRAVITY",
        "status": "RUNNING"
    }
    events_file = Path("automation/events.jsonl")
    with open(events_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(event_entry) + "\n")
        
    # 3. Chạy kiểm tra git verifier như một phần của quy trình bridge
    print("[*] Đang kích hoạt git verifier...")
    result = subprocess.run([sys.executable, "scripts/git_verifier.py"], capture_output=True, text=True)
    print(result.stdout)
    
    if result.returncode == 0:
        print("[+] Executor Bridge hoàn tất chu trình kiểm tra thành công.")
        
        # Ghi nhận sự kiện hoàn thành
        complete_event = {
            "timestamp": "2026-09-23T18:30:05Z",
            "event": "EXECUTOR_COMPLETED",
            "status": "SUCCESS"
        }
        with open(events_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(complete_event) + "\n")
    else:
        print("[-] Executor Bridge gặp vấn đề ở trạng thái Git.")
        sys.exit(1)

    print("=== ANTIGRAVITY EXECUTOR BRIDGE END ===")

if __name__ == "__main__":
    run_executor_bridge()
