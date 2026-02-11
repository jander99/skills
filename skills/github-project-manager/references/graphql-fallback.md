# GitHub GraphQL API Fallback

Use the GitHub GraphQL API v4 directly when MCP server project tools are unavailable.

## Why GraphQL is Required for Projects v2

GitHub Projects v2 **only** supports GraphQL - there is no REST API. The MCP server tools are wrappers around these GraphQL mutations and queries.

## Prerequisites

```bash
# Install GitHub CLI
brew install gh  # or: apt install gh

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

## GraphQL Query Patterns

### 1. Get Organization Project ID

**Task:** Find project by number to get its node ID

```bash
gh api graphql -f query='
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
      title
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}' -f org='myorg' -F number=5
```

**Returns:**
```json
{
  "data": {
    "organization": {
      "projectV2": {
        "id": "PVT_kwDOAbc123",
        "title": "Q1 Roadmap",
        "fields": {
          "nodes": [
            {
              "id": "PVTF_field123",
              "name": "Status",
              "options": [
                {"id": "opt_backlog", "name": "Backlog"},
                {"id": "opt_ready", "name": "Ready"}
              ]
            }
          ]
        }
      }
    }
  }
}
```

### 2. Add Issue to Project

**Task:** Link an existing issue to a project board

```bash
gh api graphql -f query='
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {
    projectId: $projectId
    contentId: $contentId
  }) {
    item {
      id
    }
  }
}' -f projectId='PVT_kwDOAbc123' -f contentId='I_kwDOAbc456'
```

### 3. Update Project Item Field (Status)

**Task:** Move issue from Backlog to Ready

```bash
gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: {
      singleSelectOptionId: $value
    }
  }) {
    projectV2Item {
      id
    }
  }
}' -f projectId='PVT_kwDOAbc123' \
   -f itemId='PVTI_item789' \
   -f fieldId='PVTF_field123' \
   -f value='opt_ready'
```

### 4. Get Issue Node ID from Issue Number

**Task:** Convert issue #42 to node ID for project operations

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      id
      title
      number
    }
  }
}' -f owner='myorg' -f repo='myrepo' -F number=42
```

## Complete GraphQL Workflow Example

```bash
# STEP 1: Get project ID and Status field metadata
PROJECT_DATA=$(gh api graphql -f query='
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options { id name }
          }
        }
      }
    }
  }
}' -f org='myorg' -F number=5)

PROJECT_ID=$(echo $PROJECT_DATA | jq -r '.data.organization.projectV2.id')
STATUS_FIELD_ID=$(echo $PROJECT_DATA | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name=="Status") | .id')
READY_OPTION_ID=$(echo $PROJECT_DATA | jq -r '.data.organization.projectV2.fields.nodes[] | select(.name=="Status") | .options[] | select(.name=="Ready") | .id')

# STEP 2: Get issue node ID
ISSUE_DATA=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) { id }
  }
}' -f owner='myorg' -f repo='myrepo' -F number=42)

ISSUE_ID=$(echo $ISSUE_DATA | jq -r '.data.repository.issue.id')

# STEP 3: Add issue to project
ITEM_DATA=$(gh api graphql -f query='
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {
    projectId: $projectId
    contentId: $contentId
  }) {
    item { id }
  }
}' -f projectId="$PROJECT_ID" -f contentId="$ISSUE_ID")

ITEM_ID=$(echo $ITEM_DATA | jq -r '.data.addProjectV2ItemById.item.id')

# STEP 4: Update status to Ready
gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $value }
  }) {
    projectV2Item { id }
  }
}' -f projectId="$PROJECT_ID" \
   -f itemId="$ITEM_ID" \
   -f fieldId="$STATUS_FIELD_ID" \
   -f value="$READY_OPTION_ID"
```

## GraphQL vs MCP Tool Mapping

| Operation | MCP Tool | GraphQL Mutation/Query |
|-----------|----------|------------------------|
| Create issue | `github_create_issue` | REST: `POST /repos/{owner}/{repo}/issues` |
| Get issue node ID | `github_get_issue` | `query { repository { issue { id } } }` |
| List projects | `github_list_projects` | `query { organization { projectsV2 { nodes } } }` |
| Get project fields | `github_list_project_fields` | `query { organization { projectV2 { fields } } }` |
| Add to project | `github_add_project_item` | `mutation { addProjectV2ItemById }` |
| Update status | `github_update_project_item` | `mutation { updateProjectV2ItemFieldValue }` |

## When to Use GraphQL Fallback

**Use GraphQL directly when:**
- GitHub MCP server `projects` toolset is disabled
- MCP server doesn't expose specific project operations
- Need to query project items with complex filters
- Debugging MCP tool issues by comparing raw API results
- Batch operations requiring custom GraphQL fragments

**Prefer MCP tools when:**
- Tools are available and working
- Standard operations (create, add, update, list)
- Simpler code without manual ID extraction
- Better error messages from MCP layer

## Debugging Tips

```bash
# Enable verbose output
gh api graphql --verbose -f query='...'

# Pretty print with jq
gh api graphql -f query='...' | jq .

# Save query to file for reuse
cat > query.graphql << 'EOF'
query($org: String!) {
  organization(login: $org) {
    projectsV2(first: 10) {
      nodes { number title }
    }
  }
}
EOF

gh api graphql -F org='myorg' -f query=@query.graphql
```
