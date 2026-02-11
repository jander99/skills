# Personal Agent Skills

A collection of reusable skills for AI coding agents. Install these skills to extend your agent's capabilities with domain-specific expertise and procedural knowledge.

## Installation

Install any skill from this collection with:

```bash
npx skills add jeff/skills
```

Or install individual skills by specifying the skill name:

```bash
npx skills add jeff/skills/skill-name
```

**Note:** Replace `jeff` with your actual GitHub username if different.

## Available Skills

Browse available skills in the [`skills/`](./skills/) directory. Each skill is self-contained and documented in its own `SKILL.md` file.

## Skill Structure

Each skill in this repository follows a standard structure:

```
skills/
├── skill-name/
│   ├── SKILL.md           # Required: Agent instructions & usage guide
│   ├── scripts/           # Optional: Helper scripts for automation
│   └── references/        # Optional: Supporting documentation
```

### SKILL.md Format

The `SKILL.md` file contains:

- **Title**: Skill name
- **Description**: What the skill does
- **Use Cases**: When agents should apply this skill
- **Key Concepts**: Important context for the agent
- **Examples**: Concrete usage examples
- **Best Practices**: Do's and don'ts
- **Implementation Details**: Technical specifics (if applicable)

Example header structure:

```markdown
# Skill Name

**Purpose:** Brief description of what this skill enables

**Use when:** Common triggering scenarios

**Key expertise:**
- Specific knowledge area 1
- Specific knowledge area 2
```

## How Skills Work

1. **Installation**: Users run `npx skills add jeff/skills` to install all skills in this repo
2. **Discovery**: The skills CLI automatically detects skills in the `skills/` directory
3. **Usage**: AI agents use the skills when they detect relevant tasks
4. **Telemetry**: Aggregate installation counts are tracked anonymously to rank skills on the leaderboard (opt-out with `DISABLE_TELEMETRY=1`)

## Creating a New Skill

To add a new skill:

1. Create a new directory in `skills/` with a kebab-case name: `skills/my-new-skill/`
2. Add a `SKILL.md` file with clear instructions
3. Optionally add `scripts/` and `references/` subdirectories
4. Update this README with a brief description

## Using These Skills

Skills are automatically available to your AI agent once installed. Agents will invoke them when:

- The task matches the skill's purpose
- You mention relevant keywords or ask for specific expertise
- You explicitly request the skill in your prompt

**Examples:**

- "Use the react-best-practices skill to review this component"
- "Apply my authorization skill to this API endpoint"
- "Review this code against my deployment guidelines"

## Leaderboard

Skills appear on [skills.sh](https://skills.sh/) automatically once they're installed by users. Ranking is based on:

- **Aggregate installation count**: Total installs across all users
- **Recency**: More recent installs weighted higher
- **Quality**: Community adoption as a proxy for usefulness

## Configuration

### Disable Telemetry

To opt out of anonymous telemetry while installing skills:

```bash
DISABLE_TELEMETRY=1 npx skills add jeff/skills
```

No personal information is ever collected—only aggregate skill installation metrics.

## Support

For issues or questions:

1. Check the individual `SKILL.md` files in the `skills/` directory
2. Open an issue on this repository
3. See [skills.sh/docs](https://skills.sh/docs) for general skills documentation

## License

MIT

---

**Last updated:** February 2025  
**Skills.sh docs:** https://skills.sh/docs
