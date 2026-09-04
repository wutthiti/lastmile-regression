"""
รันหลัง Robot Framework จบ เพื่อ mark ผล PASS/FAIL กลับเข้า Jira issue

Usage:
    robot Automate/automate.robot
    python Automate/report_to_jira.py Automate/output.xml
"""
import json
import os
import re
import sys

import requests
from dotenv import load_dotenv
from robot.api import ExecutionResult, ResultVisitor

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

JIRA_BASE_URL = os.getenv("JIRA_BASE_URL", "").rstrip("/")
JIRA_EMAIL = os.getenv("JIRA_EMAIL")
JIRA_API_TOKEN = os.getenv("JIRA_API_TOKEN")
JIRA_TRANSITION_ON_PASS = os.getenv("JIRA_TRANSITION_ON_PASS", "Done")
JIRA_TRANSITION_ON_FAIL = os.getenv("JIRA_TRANSITION_ON_FAIL", "Fail")

MAPPING_FILE = os.path.join(os.path.dirname(__file__), "jira_mapping.json")
TC_ID_PATTERN = re.compile(r"(TC_REG_\d+)")


def load_mapping():
    with open(MAPPING_FILE, encoding="utf-8") as f:
        return json.load(f)


def jira_auth():
    return (JIRA_EMAIL, JIRA_API_TOKEN)


def add_comment(issue_key, status, message):
    url = f"{JIRA_BASE_URL}/rest/api/3/issue/{issue_key}/comment"
    text = f"Robot Framework result: {status}"
    if message:
        text += f"\n\n{message}"

    body = {
        "body": {
            "type": "doc",
            "version": 1,
            "content": [{"type": "paragraph", "content": [{"type": "text", "text": text}]}],
        }
    }
    resp = requests.post(url, json=body, auth=jira_auth())
    resp.raise_for_status()


def transition_issue(issue_key, target_transition_name):
    url = f"{JIRA_BASE_URL}/rest/api/3/issue/{issue_key}/transitions"

    resp = requests.get(url, auth=jira_auth())
    resp.raise_for_status()
    transitions = resp.json().get("transitions", [])

    match = next(
        (t for t in transitions if t["name"].lower() == target_transition_name.lower()), None
    )
    if not match:
        available = [t["name"] for t in transitions]
        print(
            f"  [WARN] Transition '{target_transition_name}' not available for {issue_key}. "
            f"Available: {available}"
        )
        return

    resp2 = requests.post(url, json={"transition": {"id": match["id"]}}, auth=jira_auth())
    resp2.raise_for_status()


class JiraReporter(ResultVisitor):
    def __init__(self, mapping):
        self.mapping = mapping

    def visit_test(self, test):
        tc_match = TC_ID_PATTERN.match(test.name)
        if not tc_match:
            return
        tc_id = tc_match.group(1)

        issue_key = self.mapping.get(tc_id)
        if not issue_key or issue_key == "CHANGE_ME":
            print(f"[SKIP] {tc_id}: no Jira mapping set in jira_mapping.json")
            return

        status = test.status
        print(f"[{tc_id} -> {issue_key}] {status}")

        try:
            add_comment(issue_key, status, test.message)
        except requests.HTTPError as e:
            print(f"  [ERROR] Failed to comment on {issue_key}: {e}")

        target_transition = JIRA_TRANSITION_ON_PASS if status == "PASS" else JIRA_TRANSITION_ON_FAIL
        try:
            transition_issue(issue_key, target_transition)
        except requests.HTTPError as e:
            print(f"  [ERROR] Failed to transition {issue_key}: {e}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python report_to_jira.py <output.xml>")
        sys.exit(1)

    if not JIRA_BASE_URL or not JIRA_EMAIL or not JIRA_API_TOKEN:
        print("[ERROR] JIRA_BASE_URL / JIRA_EMAIL / JIRA_API_TOKEN ยังไม่ได้ตั้งค่าใน .env")
        sys.exit(1)

    result = ExecutionResult(sys.argv[1])
    result.visit(JiraReporter(load_mapping()))


if __name__ == "__main__":
    main()
