import subprocess
import json
from pathlib import Path

def verify_git_status():
    print("[*] Kiểm tra trạng thái Git repository...")
    
    # 1. Kiểm tra xem có thay đổi nào chưa commit không (working tree sạch)
    status_result = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True, check=True)
    clean_working_tree = len(status_result.stdout.strip()) == 0
    
    # 2. Lấy commit SHA hiện tại
    commit_sha = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True, check=True).stdout.strip()
    
    # Chấp nhận trạng thái clean working tree và có commit là PASS để phục vụ pipeline local
    report = {
        "commit_sha": commit_sha,
        "clean_working_tree": clean_working_tree,
        "status": "VERIFIED" if clean_working_tree else "UNCOMMITTED_CHANGES"
    }
    
    print(f"[+] Git Commit SHA: {commit_sha}")
    print(f"[+] Working tree sạch: {clean_working_tree}")
    return report

if __name__ == "__main__":
    res = verify_git_status()
    if not res["clean_working_tree"]:
        exit(1)
