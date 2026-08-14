---
name: github-project-manager
description: Manage, configure, generate, validate, and set up GitHub Projects (v2) with issue creation, project discovery, adding items to projects, and updating issue status across project boards. Capabilities include creating issues with metadata (labels, assignees, milestones), listing projects for users/orgs, adding issues/PRs to projects, updating project item fields (status, priority), and managing project workflows (Backlog, Ready, In Progress, Done). Use GraphQL fallback, node IDs, MCP server tools, and batch operations for project item automation. Use when creating GitHub issues, managing project boards, moving issues between project columns, organizing repository work items, tracking project progress, automating GitHub project workflows, or integrating project boards with CI/CD pipelines.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: project-management
---

# GitHub Project Manager

Automate GitHub project management workflows using the GitHub MCP server to create issues, manage project boards, and track work items across repositories.

## What I Do

- Create issues with full metadata (title, body, labels, assignees, milestones, type)
- List and discover Projects (v2) for users and organizations
- Add issues and pull requests to project boards
- Update project item fields (status, priority, custom fields)
- Move issues across project workflow states (Backlog → Ready → In Progress → Done)
- Query project items and filter by criteria
- Link related issues and manage project board organization

## When to Use Me

- Create, generate, or open a new GitHub issue
- Add an issue or pull request to a project board
- Move an issue from Backlog to Ready (or any status transition)
- Set up a new project board with initial issues
- Update issue status, priority, or custom fields in a project
- Query project board items or check project structure
- Automate project management workflows
- Organize repository work items across multiple projects

## Prerequisites

The GitHub MCP server must be configured with the following toolsets enabled:
- `issues` - For creating and managing issues
- `projects` - For project board operations
- `repos` - For repository context

Authentication via `GITHUB_PERSONAL_ACCESS_TOKEN` with scopes:
- `repo` - Full repository access
- `project` - Full project access

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

## Complete Example: End-to-End Workflow

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

## Quick Decision Matrix

| Need | GitHub MCP Tool |
|------|-----------------|
| Create a new issue | `github_create_issue` |
| Get issue details (to obtain ID) | `github_get_issue` |
| List user/org projects | `github_list_projects` |
| Get project details | `github_get_project` |
| See project fields (Status, Priority) | `github_list_project_fields` |
| Get specific field details | `github_get_project_field` |
| List items in project | `github_list_project_items` |
| Get specific project item | `github_get_project_item` |
| Add issue/PR to project | `github_add_project_item` |
| Update issue status/fields | `github_update_project_item` |
| Remove item from project | `github_delete_project_item` |

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Resource not accessible by integration" | Missing `project` scope in PAT | Regenerate token with `project` scope enabled |
| "Could not resolve to a node with the global id" | Using issue number instead of issue ID | Use `github_get_issue` to obtain node_id/ID |
| "Field not found on ProjectV2" | Invalid field_id | Run `github_list_project_fields` to get current field IDs |
| "Project not found" | Wrong project_number or owner | Verify project number from URL or `list_projects` |
| "Item already exists in project" | Issue already added | Check `github_list_project_items` before adding |

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

## GraphQL Fallback

If GitHub MCP server project tools are unavailable, use the GitHub GraphQL API v4 directly. See [references/graphql-fallback.md](references/graphql-fallback.md) for complete query patterns, prerequisites, the full end-to-end workflow, MCP-to-GraphQL mapping, and debugging tips.

## Integration with Other Skills

| Skill | Integration Point |
|-------|-------------------|
| github-actions | Create issues from workflow failures; update project status in CI |
| markdown-editor | Format issue bodies with proper Markdown templates |

## Related GitHub MCP Tools

| Tool Category | Tools |
|---------------|-------|
| Issue Management | `github_create_issue`, `github_update_issue`, `github_get_issue`, `github_list_issues` |
| Project Discovery | `github_list_projects`, `github_get_project` |
| Project Fields | `github_list_project_fields`, `github_get_project_field` |
| Project Items | `github_add_project_item`, `github_update_project_item`, `github_delete_project_item`, `github_list_project_items`, `github_get_project_item` |

## Context7 Integration

For current GitHub Projects API documentation:
```
1. context7_resolve-library-id with query="github projects api"
2. context7_query-docs with:
   - libraryId="/github/docs" or resolved library
   - query="projects v2 graphql" or "managing project items"
```

## Best Practices

1. **Always retrieve IDs before operations**: Issue ID ≠ Issue Number, Project Item ID ≠ Issue ID
2. **Cache field mappings**: Project fields don't change frequently - retrieve once per session
3. **Error handling**: Check if item already exists in project before adding
4. **Status workflow**: Respect project workflow (Backlog → Ready → In Progress → Done)
5. **Batch updates**: When updating multiple items, get field IDs once
6. **Validation**: Verify project and field existence before attempting updates

## References

| Reference | Description |
|-----------|-------------|
| [GitHub Projects API](https://docs.github.com/en/issues/planning-and-tracking-with-projects) | Official documentation |
| [GraphQL API for Projects](https://docs.github.com/en/graphql/reference/objects#projectv2) | Project v2 schema |
| [GraphQL Fallback](references/graphql-fallback.md) | Local: complete GraphQL patterns, full workflow, and MCP-to-GraphQL mapping |
