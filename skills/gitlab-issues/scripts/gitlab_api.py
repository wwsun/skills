import os
import sys
import json
import urllib.request
import urllib.parse
from datetime import datetime, timedelta, timezone

# Configuration from environment variables
GITLAB_URL = os.getenv("GITLAB_URL", "https://g.hz.netease.com").rstrip("/")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN")
PROJECT_PATH = os.getenv("GITLAB_PROJECT_ID", "tango/ai-agents/campaign-ai-studio")
DRY_RUN = os.getenv("DRY_RUN", "false").lower() == "true"
# URL encode the project path
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
    elif method == "PUT" and data is None:
        # For updates without JSON body, use form-encoded if needed, 
        # but here we'll assume JSON for simplicity if refactoring
        pass

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req) as f:
        return json.loads(f.read().decode("utf-8"))

def get_user_id(username):
    if DRY_RUN:
        return 999 if username == "sunweiwei01" else 888
    try:
        users = api_request(f"users", params={"username": username})
        if users:
            return users[0]['id']
    except Exception as e:
        print(f"Error fetching user: {e}")
    return None

def list_issues(state="opened", labels=None, created_after=None):
    if DRY_RUN:
        return [
            {"iid": 101, "title": "Add agent support", "state": "opened", "created_at": "2026-04-14T10:00:00Z", "updated_at": "2026-04-14T10:00:00Z", "labels": ["bugfix"]},
            {"iid": 102, "title": "Stale issue", "state": "opened", "created_at": "2026-01-01T10:00:00Z", "updated_at": "2026-01-01T10:00:00Z", "labels": ["P0"]},
            {"iid": 103, "title": "Closed issue", "state": "closed", "created_at": "2026-04-13T10:00:00Z", "updated_at": "2026-04-13T12:00:00Z", "closed_at": "2026-04-13T12:00:00Z", "labels": ["feature"]}
        ]
    params = {"state": state, "per_page": 100}
    if labels:
        params["labels"] = labels
    if created_after:
        params["created_after"] = created_after
    return api_request(f"projects/{PROJECT_ID}/issues", params=params)

def update_issue(issue_iid, labels=None, assignee_ids=None):
    if DRY_RUN:
        print(f"[DRY RUN] Updating issue {issue_iid} labels={labels} assignees={assignee_ids}")
        return {"iid": issue_iid, "labels": labels, "assignee_ids": assignee_ids}
    data = {}
    if labels is not None:
        data["labels"] = ",".join(labels)
    if assignee_ids is not None:
        data["assignee_ids"] = assignee_ids
    return api_request(f"projects/{PROJECT_ID}/issues/{issue_iid}", method="PUT", data=data)

def generate_report():
    all_issues = list_issues(state="all")
    now = datetime.now(timezone.utc)
    one_day_ago = now - timedelta(days=1)
    fourteen_days_ago = now - timedelta(days=14)
    
    def parse_dt(s):
        return datetime.fromisoformat(s.replace('Z', '+00:00'))

    new_issues = [i for i in all_issues if parse_dt(i['created_at']) > one_day_ago]
    closed_issues = [i for i in all_issues if i['state'] == 'closed' and i['closed_at'] and parse_dt(i['closed_at']) > one_day_ago]
    high_priority = [i for i in all_issues if i['state'] == 'opened' and any(l in ['P0', 'P1'] for l in i['labels'])]
    stale_issues = [i for i in all_issues if i['state'] == 'opened' and parse_dt(i['updated_at']) < fourteen_days_ago]
    
    categories = {}
    for i in all_issues:
        if i['state'] == 'opened':
            for label in i['labels']:
                categories[label] = categories.get(label, 0) + 1

    return {
        "new_count": len(new_issues),
        "closed_count": len(closed_issues),
        "high_priority_count": len(high_priority),
        "stale_count": len(stale_issues),
        "categories": categories,
        "high_priority_list": [{"iid": i['iid'], "title": i['title'], "labels": i['labels']} for i in high_priority],
        "stale_list": [{"iid": i['iid'], "title": i['title'], "last_update": i['updated_at']} for i in stale_issues]
    }

def load_config(config_path="rules.json"):
    if not os.path.exists(config_path):
        # Try relative to the script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(os.path.dirname(script_dir), "rules.json")
    
    if os.path.exists(config_path):
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def auto_assign(issues, config):
    results = []
    assignees_ids = config.get("assignees", {})
    rules = config.get("assignment_rules", [])
    
    for issue in issues:
        title = issue.get("title", "").lower()
        description = issue.get("description", "").lower()
        match_found = False
        
        for rule in rules:
            if any(kw.lower() in title or kw.lower() in description for kw in rule["keywords"]):
                target_user = rule["assignee"]
                uid = assignees_ids.get(target_user)
                if not uid:
                    # Fallback to API if ID not in config
                    uid = get_user_id(target_user)
                
                if uid:
                    res = update_issue(issue['iid'], assignee_ids=[uid])
                    results.append({"iid": issue['iid'], "assignee": target_user, "status": "updated"})
                    match_found = True
                    break
        if not match_found:
            results.append({"iid": issue['iid'], "status": "no_match"})
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python gitlab_api.py [report|update|user|auto-assign] ...")
        sys.exit(1)
    
    config = load_config()
    cmd = sys.argv[1]
    
    if cmd == "report":
        print(json.dumps(generate_report(), indent=2, ensure_ascii=False))
    elif cmd == "update":
        iid = sys.argv[2]
        labels = sys.argv[3].split(",") if sys.argv[3] else None
        assignees = [int(x) for x in sys.argv[4].split(",")] if len(sys.argv) > 4 and sys.argv[4] else None
        print(json.dumps(update_issue(iid, labels, assignees), indent=2, ensure_ascii=False))
    elif cmd == "user":
        print(get_user_id(sys.argv[2]))
    elif cmd == "auto-assign":
        # Expecting JSON string of issues or - (stdin)
        issues_input = sys.argv[2]
        if issues_input == "-":
            issues = json.load(sys.stdin)
        else:
            issues = json.loads(issues_input)
        print(json.dumps(auto_assign(issues, config), indent=2, ensure_ascii=False))
