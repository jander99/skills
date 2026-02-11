# GitHub Project Manager - Detailed Workflows

Comprehensive workflows for GitHub Projects v2 management.

## Core Workflows

### 1. Create an Issue

```markdown
TASK: Create a new issue in owner/repo

STEPS:
1. Use github_create_issue with:
   - owner: Repository owner (user or org)
   - repo: Repository name
   - title: Clear, concise issue title
   - body: Detailed description (supports Markdown)
   - labels: Array of label names (optional)
   - assignees: Array of usernames (optional)
   - milestone: Milestone number (optional)
   - type: Issue type if custom types are configured (optional)

2. Capture the returned issue number and ID for subsequent operations

EXAMPLE:
github_create_issue(
  owner="myorg",
  repo="myrepo",
  title="Add user authentication feature",
  body="Implement OAuth2 login with Google and GitHub providers...",
  labels=["enhancement", "backend"],
  assignees=["username"],
  type="Feature"
)
```

**Key Points:**
- Issue ID (returned field) is needed for project operations, NOT issue number
- Labels must exist in the repository beforehand
- Assignees must have repository access
- Type field only works if repository has custom issue types configured

### 2. Find Projects for a User or Organization

```markdown
TASK: List all projects for a user or organization

STEPS:
1. Use github_list_projects with:
   - owner_type: "user" or "org"
   - owner: GitHub username or organization name
   - per_page: Number of results (default 30, max 100)
   - query: Optional search query to filter by title/description

2. Review returned projects array for:
   - number: Project number (used in subsequent calls)
   - title: Project name
   - shortDescription: Project description
   - id: Internal project ID

EXAMPLE:
github_list_projects(
  owner_type="org",
  owner="myorg",
  query="roadmap"
)

Returns projects matching "roadmap" in title or description
```

**Key Points:**
- Projects are GitHub Projects v2 (modern project boards)
- User-owned projects use `owner_type="user"`
- Organization projects use `owner_type="org"`
- Project **number** is visible in URL: `github.com/orgs/myorg/projects/5` → number is `5`

### 3. Add an Issue to a Project

```markdown
TASK: Add an existing issue to a project board

STEPS:
1. Get the issue ID from github_create_issue or github_get_issue
   (ID is different from issue number!)

2. Use github_add_project_item with:
   - owner_type: "user" or "org"
   - owner: Project owner
   - project_number: Project number from URL or list_projects
   - item_type: "issue" or "pull_request"
   - item_id: Numeric issue ID (NOT issue number)

3. Capture the returned project item ID for status updates

EXAMPLE:
# First get issue details to obtain ID
issue = github_get_issue(owner="myorg", repo="myrepo", issue_number=42)
issue_id = issue.node_id  # Extract numeric ID from node_id

# Then add to project
github_add_project_item(
  owner_type="org",
  owner="myorg",
  project_number=5,
  item_type="issue",
  item_id=issue_id
)
```

**Critical Distinction:**
- **Issue Number**: Visible in UI (#42) - used for github_get_issue, github_update_issue
- **Issue ID**: Internal identifier - used for github_add_project_item

### 4. Get Project Structure and Fields

```markdown
TASK: Understand project board structure before updating items

STEPS:
1. Use github_get_project to see project metadata:
   github_get_project(owner_type="org", owner="myorg", project_number=5)

2. Use github_list_project_fields to see available fields:
   github_list_project_fields(owner_type="org", owner="myorg", project_number=5)
   
   Returns fields like:
   - Status (single_select with options: Backlog, Ready, In Progress, Done)
   - Priority (single_select with options: High, Medium, Low)
   - Custom fields specific to your project

3. Note the field IDs and option IDs for update operations
```

**Key Information:**
- Status field typically has options: Backlog, Ready, In Progress, Done, Closed
- Field IDs are required for update operations
- Option IDs specify which value to set (e.g., "Ready" vs "In Progress")

### 5. Update Issue Status in Project (Move Between Columns)

```markdown
TASK: Move an issue from Backlog to Ready (or any status transition)

STEPS:
1. Get project fields to find Status field ID and option IDs:
   fields = github_list_project_fields(owner_type="org", owner="myorg", project_number=5)
   status_field = find field where name="Status"
   ready_option_id = find option where name="Ready"

2. Get the project item ID (different from issue ID!):
   items = github_list_project_items(owner_type="org", owner="myorg", project_number=5)
   project_item_id = find item matching your issue

3. Update the project item field:
   github_update_project_item(
     owner_type="org",
     owner="myorg",
     project_number=5,
     item_id=project_item_id,
     field_id=status_field.id,
     value=ready_option_id
   )
```

**Important Notes:**
- Three different IDs in play: Issue ID, Project Item ID, Field/Option IDs
- Project Item ID is returned when you add an issue to a project
- Use github_get_project_item to retrieve current state before updating

## Complete End-to-End Workflow

```markdown
SCENARIO: Create issue, add to project board, set to "Ready" status

STEP 1: Create the issue
issue = github_create_issue(
  owner="myorg",
  repo="backend-api",
  title="Implement rate limiting middleware",
  body="Add Express middleware for API rate limiting...",
  labels=["enhancement", "security"],
  assignees=["backend-dev"]
)
→ Returns: issue_number=42, issue_id=123456

STEP 2: Find the project
projects = github_list_projects(owner_type="org", owner="myorg")
→ Find project: "Q1 Roadmap" has project_number=5

STEP 3: Add issue to project
project_item = github_add_project_item(
  owner_type="org",
  owner="myorg",
  project_number=5,
  item_type="issue",
  item_id=123456  # Use issue_id from Step 1
)
→ Returns: project_item_id=789

STEP 4: Get project fields
fields = github_list_project_fields(owner_type="org", owner="myorg", project_number=5)
→ Status field: id=field_abc, options=[{id: opt_1, name: "Backlog"}, {id: opt_2, name: "Ready"}]

STEP 5: Move to "Ready" status
github_update_project_item(
  owner_type="org",
  owner="myorg",
  project_number=5,
  item_id=789,  # project_item_id from Step 3
  field_id="field_abc",
  value="opt_2"  # Ready option ID
)
→ Issue now shows in "Ready" column on project board
```

## Batch Operations Pattern

```markdown
TASK: Add multiple issues to a project and set status

FOR EACH issue_number IN [42, 43, 44, 45]:
  1. issue = github_get_issue(owner, repo, issue_number)
  2. project_item = github_add_project_item(owner_type, owner, project_number, "issue", issue.id)
  3. github_update_project_item(owner_type, owner, project_number, project_item.id, status_field_id, ready_option_id)

OPTIMIZATION:
- Retrieve field IDs once before loop
- Handle errors per-issue to continue batch
- Log successful additions and failures
```

## ID Reference Guide

GitHub has multiple identifier types - use the correct one:

| ID Type | Example | Used For | Obtained From |
|---------|---------|----------|---------------|
| Issue Number | `42` | UI display, get/update issue | Visible in URL/UI |
| Issue ID (node_id) | `I_kwDOAbc123` | Adding to projects | `github_get_issue` response |
| Project Number | `5` | All project operations | Project URL or `list_projects` |
| Project Item ID | `789` | Updating item fields | `add_project_item` response |
| Field ID | `field_abc` | Updating field values | `list_project_fields` |
| Option ID | `opt_1` | Setting field value | Field options in `list_project_fields` |

## Best Practices

1. **Always retrieve IDs before operations**: Issue ID ≠ Issue Number, Project Item ID ≠ Issue ID
2. **Cache field mappings**: Project fields don't change frequently - retrieve once per session
3. **Error handling**: Check if item already exists in project before adding
4. **Status workflow**: Respect project workflow (Backlog → Ready → In Progress → Done)
5. **Batch updates**: When updating multiple items, get field IDs once
6. **Validation**: Verify project and field existence before attempting updates
