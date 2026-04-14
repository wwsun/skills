import os
import sys
import json
import urllib.request
import urllib.parse
from datetime import datetime, timedelta, timezone

# Configuration from environment variables
GITLAB_URL = os.getenv("GITLAB_URL", "https://g.hz.netease.com").rstrip("/")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN")
PROJECT_PATH = os.getenv("GITLAB_PROJECT_ID", "tango/ai-agents/some-repo")
DRY_RUN = os.getenv("DRY_RUN", "false").lower() == "true"
PROJECT_ID = urllib.parse.quote(PROJECT_PATH, safe='')

if not GITLAB_TOKEN and not DRY_RUN:
    print("Error: GITLAB_TOKEN environment variable is not set and DRY_RUN is false.")
    sys.exit(1)

def api_request(path, method="GET", params=None, data=None):
    url = f"{GITLAB_URL}/api/v4/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    headers = {"Private-Token": GITLAB_TOKEN or "mock"}
    body = None
    if data:
        body = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req) as f:
        return json.loads(f.read().decode("utf-8"))

def get_user_id(username):
    if DRY_RUN: return 999 if username == "sunweiwei01" else 888
    try:
        users = api_request(f"users", params={"username": username})
        return users[0]['id'] if users else None
    except: return None

def list_issues(state="opened", labels=None, created_after=None):
    if DRY_RUN:
        return [
            {"iid": 101, "title": "Add agent support", "description": "logic for studio", "state": "opened", "created_at": "2026-04-14T10:00:00Z", "updated_at": "2026-04-14T10:00:00Z", "labels": [], "assignees": []},
            {"iid": 102, "title": "Critical bug", "description": "error in publish", "state": "opened", "created_at": "2026-04-14T11:00:00Z", "updated_at": "2026-04-14T11:00:00Z", "labels": [], "assignees": []},
            {"iid": 103, "title": "Old feature", "description": "", "state": "opened", "created_at": "2026-01-01T10:00:00Z", "updated_at": "2026-01-01T10:00:00Z", "labels": ["P2"], "assignees": [{"username": "sunweiwei01"}]}
        ]
    params = {"state": state, "per_page": 100}
    if labels: params["labels"] = labels
    if created_after: params["created_after"] = created_after
    return api_request(f"projects/{PROJECT_ID}/issues", params=params)

def update_issue(issue_iid, labels=None, assignee_ids=None):
    if DRY_RUN:
        print(f"[DRY RUN] Updating issue {issue_iid} labels={labels} assignees={assignee_ids}")
        return {"iid": issue_iid, "labels": labels, "assignee_ids": assignee_ids}
    data = {}
    if labels is not None: data["labels"] = ",".join(labels)
    if assignee_ids is not None: data["assignee_ids"] = assignee_ids
    return api_request(f"projects/{PROJECT_ID}/issues/{issue_iid}", method="PUT", data=data)

def load_config(config_path="rules.json"):
    if not os.path.exists(config_path):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(os.path.dirname(script_dir), "rules.json")
    if os.path.exists(config_path):
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def process_workflow(config):
    issues = list_issues(state="opened")
    assignees_map = config.get("assignees", {})
    rules = config.get("assignment_rules", [])
    default_labels = config.get("default_labels", ["feature"])
    
    updated_count = 0
    for i in issues:
        # Check if unorganized (no labels or no assignees)
        if not i.get("labels") or not i.get("assignees"):
            target_labels = set()
            target_assignee_id = None
            
            text = (i.get("title", "") + " " + i.get("description", "")).lower()
            for rule in rules:
                if any(kw.lower() in text for kw in rule["keywords"]):
                    if "labels" in rule: target_labels.update(rule["labels"])
                    if "assignee" in rule and not target_assignee_id:
                        target_assignee_id = assignees_map.get(rule["assignee"]) or get_user_id(rule["assignee"])
            
            if not target_labels: target_labels.update(default_labels)
            
            # Combine with existing labels if any
            final_labels = list(set(i.get("labels", [])).union(target_labels))
            final_assignees = [target_assignee_id] if target_assignee_id else []
            
            update_issue(i['iid'], labels=final_labels, assignee_ids=final_assignees)
            updated_count += 1
    return updated_count

def generate_report():
    all_issues = list_issues(state="all")
    now = datetime.now(timezone.utc)
    one_day_ago = now - timedelta(days=1)
    
    def parse_dt(s): return datetime.fromisoformat(s.replace('Z', '+00:00'))

    new_issues = [i for i in all_issues if parse_dt(i['created_at']) > one_day_ago]
    high_priority = [i for i in all_issues if i['state'] == 'opened' and any(l in ['P0', 'P1', 'bugfix'] for l in i.get('labels', []))]
    
    categories = {}
    for i in all_issues:
        if i['state'] == 'opened':
            for label in i.get('labels', []):
                categories[label] = categories.get(label, 0) + 1

    return {
        "new_issues": [{"iid": i['iid'], "title": i['title'], "created_at": i['created_at']} for i in new_issues],
        "priority_focus": [{"iid": i['iid'], "title": i['title'], "labels": i['labels']} for i in high_priority],
        "categories": categories
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python gitlab_api.py [workflow|report|update|user] ...")
        sys.exit(1)
    
    config = load_config()
    cmd = sys.argv[1]
    
    if cmd == "workflow":
        count = process_workflow(config)
        report = generate_report()
        print(json.dumps({"updated_issues": count, "report": report}, indent=2, ensure_ascii=False))
    elif cmd == "report":
        print(json.dumps(generate_report(), indent=2, ensure_ascii=False))
    elif cmd == "update":
        iid, labels = sys.argv[2], sys.argv[3].split(",") if sys.argv[3] else None
        assignees = [int(x) for x in sys.argv[4].split(",")] if len(sys.argv) > 4 and sys.argv[4] else None
        print(json.dumps(update_issue(iid, labels, assignees), indent=2, ensure_ascii=False))
    elif cmd == "user":
        print(get_user_id(sys.argv[2]))
