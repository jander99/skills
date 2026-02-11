<!-- 
⚠️ TEMPLATE FILE - REPLACE ALL PLACEHOLDERS BEFORE USE
- Replace {skill-name} with actual skill name (appears 5 times)
- Replace [bracketed text] with actual content
- Remove this warning block after customization
-->
---
description: [One-line description of what this command does]
arguments:
  - name: arg-name
    description: What this argument is for
    required: false
  - name: another-arg
    description: What this argument is for
    required: false
---

Use the {skill-name} skill to help the user {accomplish specific task}.

Follow the {skill-name} skill instructions in @skills/{skill-name}/SKILL.md exactly.

## Key Steps

1. {Step from skill process}
2. {Step from skill process}
3. {Step from skill process}
4. {Step from skill process}

## Additional Context

- {Important consideration from skill}
- {Important consideration from skill}
- {Important consideration from skill}

## Expected Output

{What the user should expect after running this command}

---

## Notes for Command Authors

**Command Naming Rules:**

1. **Project commands:** Match skill name exactly
   - Skill: `.opencode/skill/api-validator/`
   - Command: `.opencode/commands/api-validator.md`

2. **agent-kit commands:** Use `ak-` prefix
   - Skill: `content/skills/create-plan/`
   - Command: `content/commands/ak-create-plan.md`

3. **No conflicts:** Command name cannot conflict with existing skill names

**Command-Skill Relationship:**

- Commands provide direct invocation: `/skill-name` or `/ak-skill-name`
- Commands should reference the skill: `@skills/{skill-name}/SKILL.md`
- Commands can provide additional context or specific workflows
- Skills activate automatically; commands activate explicitly

**Good Command Descriptions:**

✅ "Create a new implementation plan with architecture diagram"
✅ "Validate Agent Skills against 34 checks and grade them"
✅ "Generate API documentation from TypeScript code"

❌ "Plan things" (too vague)
❌ "Uses the planning skill" (describes mechanism, not outcome)

**Validation:**

Commands are validated as part of skill validation:
- Check 17: Slash command exists
- Check 18: Command references skill (@skills/{name}/SKILL.md)
- Check 19: agent-kit commands use ak- prefix
- Check 20: No name conflicts with skills

**Template Usage:**

1. Copy this template to appropriate location
2. Replace `{skill-name}` with actual skill name
3. Write clear, one-line description
4. List key steps from skill process
5. Add any additional context
6. Test command invocation: `/{command-name}` in agent

**Example: API Validator Command**

```markdown
---
description: Validate REST API endpoints against OpenAPI specification
arguments:
  - name: spec-file
    description: Path to OpenAPI spec file
    required: false
---

Use the api-validator skill to help the user validate API endpoints.

Follow the api-validator skill instructions in @skills/api-validator/SKILL.md exactly.

## Key Steps

1. Read OpenAPI specification file
2. Analyze API endpoint definitions
3. Validate request/response schemas
4. Check authentication requirements
5. Generate validation report

## Additional Context

- Supports OpenAPI 3.0 and 3.1
- Validates against common REST API best practices
- Can check for breaking changes between spec versions

## Expected Output

Validation report showing:
- Valid endpoints (✓)
- Invalid endpoints with specific issues (✗)
- Recommendations for improvements
```
