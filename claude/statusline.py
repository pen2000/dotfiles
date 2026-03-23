#!/usr/bin/env python3
"""Claude Code ステータスライン（Python実装）"""

import json
import os
import subprocess
import sys

def get_git_branch(cwd: str) -> str:
    """カレントディレクトリのgitブランチ名を取得"""
    try:
        result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=3,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return ""

def main():
    data = json.load(sys.stdin)

    # 基本情報
    user = os.environ.get("USER", "?")
    hostname = os.uname().nodename.split(".")[0]
    cwd = data.get("cwd", os.getcwd())
    dirname = os.path.basename(cwd)
    model = data.get("model", {}).get("display_name", "?")
    pct = data.get("context_window", {}).get("used_percentage", 0)
    ctx = f" {round(pct)}%" if pct else ""

    # Gitブランチ
    branch = get_git_branch(cwd)
    git_part = f"🌿 {branch}" if branch else ""

    # 絵文字アイコン
    print(f"👤 {user} @ 💻 {hostname} 📁 {dirname} {git_part} | 🤖 {model}{ctx}")

if __name__ == "__main__":
    main()
