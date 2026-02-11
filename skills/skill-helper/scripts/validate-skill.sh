#!/bin/bash
# Agent Skill Validator + Grader v2.0
# Validates Agent Skills against 34 checks and calculates grade

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
SUGGESTIONS=0
SCORE=0

# Arrays to store messages
declare -a ERROR_MESSAGES
declare -a WARNING_MESSAGES
declare -a SUGGESTION_MESSAGES

# Grade component scores
DESC_QUALITY_SCORE=0
STRUCTURE_SCORE=0
CONTENT_SCORE=0
TECH_IMPL_SCORE=0
SPEC_COMPLIANCE_SCORE=0

# Skill metadata
SKILL_PATH=""
SKILL_NAME=""
SKILL_DESC=""
SKILL_DIR=""
HAS_LICENSE=""
HAS_VERSION=""
TOKEN_COUNT=0
LINE_COUNT=0

usage() {
    echo "Usage: $0 <path-to-skill>"
    echo ""
    echo "Validates Agent Skills against 34 checks and calculates grade."
    echo ""
    echo "Example:"
    echo "  $0 .opencode/skill/my-skill"
    echo "  $0 /path/to/skill-directory"
    exit 1
}

# Check arguments
if [ $# -eq 0 ]; then
    usage
fi

SKILL_PATH="$1"

# Sanitize and validate the path to prevent command injection
if [[ "$SKILL_PATH" =~ [\;\&\|\`\$\(\)] ]]; then
    echo -e "${RED}Error: Invalid characters in path${NC}"
    exit 1
fi

# Safely resolve the path
if [ ! -d "$SKILL_PATH" ]; then
    echo -e "${RED}Error: Skill directory not found: $SKILL_PATH${NC}"
    exit 1
fi

SKILL_DIR="$(cd "$SKILL_PATH" && pwd)"

SKILL_MD="$SKILL_DIR/SKILL.md"

# === FRONTMATTER PARSING ===
parse_frontmatter() {
    if [ ! -f "$SKILL_MD" ]; then
        ERROR_MESSAGES+=("SKILL.md file not found")
        ((ERRORS++))
        return 1
    fi

    # Extract frontmatter between --- markers
    local in_frontmatter=0
    local frontmatter=""
    
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if [[ $in_frontmatter -eq 0 ]]; then
                in_frontmatter=1
            else
                break
            fi
        elif [[ $in_frontmatter -eq 1 ]]; then
            frontmatter+="$line"$'\n'
        fi
    done < "$SKILL_MD"

    # Parse name
    SKILL_NAME=$(echo "$frontmatter" | grep -E "^name:" | sed 's/name:[[:space:]]*//')
    
    # Parse description (may span multiple lines)
    # Only stop on known frontmatter keys to avoid early termination
    SKILL_DESC=$(echo "$frontmatter" | awk '/^description:/{flag=1; sub(/^description:[[:space:]]*/, ""); print; next} flag{if(/^(name|version|license|author|tags|commands):/){exit} print}' | tr '\n' ' ' | sed 's/  */ /g')
    
    # Check for license
    HAS_LICENSE=$(echo "$frontmatter" | grep -E "^license:" | wc -l)
    
    # Check for version in metadata
    HAS_VERSION=$(echo "$frontmatter" | grep -E "version:" | wc -l)
    
    # Count tokens (rough estimate: 4 chars = 1 token)
    local body_text=$(tail -n +$(grep -n "^---$" "$SKILL_MD" | tail -1 | cut -d: -f1) "$SKILL_MD")
    local char_count=$(echo "$body_text" | wc -c)
    TOKEN_COUNT=$((char_count / 4))
    LINE_COUNT=$(wc -l < "$SKILL_MD")
}

# === ERROR CHECKS (9) ===

check_name_exists() {
    if [ -z "$SKILL_NAME" ]; then
        ERROR_MESSAGES+=("Name field missing in frontmatter")
        ((ERRORS++))
        return 1
    fi
    SPEC_COMPLIANCE_SCORE=$((SPEC_COMPLIANCE_SCORE + 1))
    return 0
}

check_name_format() {
    if ! [[ "$SKILL_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        ERROR_MESSAGES+=("Invalid name format: '$SKILL_NAME' (must be lowercase, hyphens only, ^[a-z0-9-]+\$)")
        ((ERRORS++))
        return 1
    fi
    
    if [ ${#SKILL_NAME} -gt 64 ]; then
        ERROR_MESSAGES+=("Name too long: ${#SKILL_NAME} chars (max 64)")
        ((ERRORS++))
        return 1
    fi
    
    SPEC_COMPLIANCE_SCORE=$((SPEC_COMPLIANCE_SCORE + 1))
    return 0
}

check_name_reserved() {
    if [[ "$SKILL_NAME" == *"anthropic"* || "$SKILL_NAME" == *"claude"* ]]; then
        ERROR_MESSAGES+=("Name contains reserved word (anthropic or claude)")
        ((ERRORS++))
        return 1
    fi
    return 0
}

check_description_exists() {
    if [ -z "$SKILL_DESC" ]; then
        ERROR_MESSAGES+=("Description field missing in frontmatter")
        ((ERRORS++))
        return 1
    fi
    SPEC_COMPLIANCE_SCORE=$((SPEC_COMPLIANCE_SCORE + 1))
    return 0
}

check_description_length() {
    local desc_len=${#SKILL_DESC}
    if [ $desc_len -lt 50 ]; then
        ERROR_MESSAGES+=("Description too short: $desc_len chars (min 50)")
        ((ERRORS++))
        return 1
    fi
    
    if [ $desc_len -gt 1024 ]; then
        ERROR_MESSAGES+=("Description too long: $desc_len chars (max 1024)")
        ((ERRORS++))
        return 1
    fi
    
    SPEC_COMPLIANCE_SCORE=$((SPEC_COMPLIANCE_SCORE + 1))
    return 0
}

check_no_xml_in_frontmatter() {
    if [[ "$SKILL_NAME" == *"<"* || "$SKILL_NAME" == *">"* ]]; then
        ERROR_MESSAGES+=("Name contains XML tags")
        ((ERRORS++))
        return 1
    fi
    
    if [[ "$SKILL_DESC" == *"<"* || "$SKILL_DESC" == *">"* ]]; then
        ERROR_MESSAGES+=("Description contains XML tags")
        ((ERRORS++))
        return 1
    fi
    
    return 0
}

check_skill_md_exists() {
    if [ ! -f "$SKILL_MD" ]; then
        ERROR_MESSAGES+=("SKILL.md file does not exist")
        ((ERRORS++))
        return 1
    fi
    SPEC_COMPLIANCE_SCORE=$((SPEC_COMPLIANCE_SCORE + 1))
    return 0
}

check_context7_format() {
    if grep -q "context7" "$SKILL_MD" 2>/dev/null; then
        if ! grep -qE "context7_(resolve-library-id|query-docs)\(.*\)" "$SKILL_MD"; then
            ERROR_MESSAGES+=("Invalid Context7 format (should be: context7_resolve-library-id(...) or context7_query-docs(...))")
            ((ERRORS++))
            return 1
        fi
    fi
    return 0
}

check_no_placeholders() {
    local placeholders=$(grep -iE "(TODO:|FIXME:|XXX:|TBD:|\[PLACEHOLDER\])" "$SKILL_MD" | head -5)
    if [ -n "$placeholders" ]; then
        ERROR_MESSAGES+=("Placeholder content found (TODO, FIXME, XXX, TBD, [PLACEHOLDER])")
        ((ERRORS++))
        return 1
    fi
    return 0
}

# === WARNING CHECKS (17) ===

check_description_has_when() {
    if ! grep -qiE "Use when|Use for|Use this" <<< "$SKILL_DESC"; then
        WARNING_MESSAGES+=("Description missing 'Use when' trigger phrase")
        ((WARNINGS++))
        DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE - 3))
        return 1
    fi
    DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE + 3))
    return 0
}

check_description_action_verbs() {
    local verbs="Create|Write|Generate|Edit|Update|Build|Validate|Audit|Review|Optimize|Refactor|Debug|Fix|Deploy|Install|Configure|Implement|Design|Test|Analyze|Process|Handle|Manage|Monitor"
    local verb_count=$(grep -oiE "$verbs" <<< "$SKILL_DESC" | wc -l)
    
    if [ $verb_count -lt 5 ]; then
        WARNING_MESSAGES+=("Description has only $verb_count action verbs (recommend 5+)")
        ((WARNINGS++))
        DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE - 2))
        return 1
    fi
    DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE + 5))
    return 0
}

check_keyword_density() {
    # Count technology keywords (rough heuristic: capitalized words, tech terms)
    # Deduplicate matches to avoid double-counting
    local keywords=$(grep -oE "[A-Z][a-zA-Z0-9]+" <<< "$SKILL_DESC" | tr '[:upper:]' '[:lower:]' | sort -u | wc -l)
    local tech_terms=$(grep -oiE "(test|api|database|server|client|http|json|yaml|xml|typescript|javascript|python|java|react|angular|docker|kubernetes)" <<< "$SKILL_DESC" | tr '[:upper:]' '[:lower:]' | sort -u | wc -l)
    local total_keywords=$((keywords + tech_terms))
    
    if [ $total_keywords -lt 10 ]; then
        WARNING_MESSAGES+=("Low keyword density: ~$total_keywords keywords (recommend 10+)")
        ((WARNINGS++))
        DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE - 2))
        return 1
    fi
    DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE + 3))
    return 0
}

check_has_examples() {
    if ! grep -qiE "^##+ Examples?|^###+ Example" "$SKILL_MD"; then
        WARNING_MESSAGES+=("No examples section found")
        ((WARNINGS++))
        CONTENT_SCORE=$((CONTENT_SCORE - 2))
        return 1
    fi
    CONTENT_SCORE=$((CONTENT_SCORE + 3))
    return 0
}

check_token_limit() {
    if [ $TOKEN_COUNT -lt 500 ]; then
        WARNING_MESSAGES+=("SKILL.md too small: ~$TOKEN_COUNT tokens (recommend >500)")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 4))
        return 1
    elif [ $TOKEN_COUNT -lt 1000 ]; then
        WARNING_MESSAGES+=("SKILL.md small: ~$TOKEN_COUNT tokens (recommend 1000-2000)")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 2))
        return 1
    elif [ $TOKEN_COUNT -ge 1000 ] && [ $TOKEN_COUNT -le 2000 ]; then
        # Sweet spot!
        STRUCTURE_SCORE=$((STRUCTURE_SCORE + 5))
        return 0
    elif [ $TOKEN_COUNT -gt 2000 ] && [ $TOKEN_COUNT -le 3500 ]; then
        WARNING_MESSAGES+=("SKILL.md large: ~$TOKEN_COUNT tokens (recommend 1000-2000, consider refactoring)")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 1))
        return 1
    elif [ $TOKEN_COUNT -gt 3500 ]; then
        WARNING_MESSAGES+=("SKILL.md too large: ~$TOKEN_COUNT tokens (recommend 1000-2000, strongly consider refactoring)")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 3))
        return 1
    fi
    return 0
}

check_referenced_files() {
    local broken_links=0
    while IFS= read -r link; do
        local file_path=$(echo "$link" | sed -n 's/.*(\([^)]*\)).*/\1/p')
        # Skip external links
        if [[ "$file_path" =~ ^https?:// ]]; then
            continue
        fi
        
        local full_path="$SKILL_DIR/$file_path"
        if [ ! -f "$full_path" ]; then
            if [ $broken_links -eq 0 ]; then
                WARNING_MESSAGES+=("Broken links found:")
            fi
            WARNING_MESSAGES+=("  - $file_path")
            ((broken_links++))
        fi
    done < <(grep -oE "\[([^\]]+)\]\(([^)]+)\)" "$SKILL_MD")
    
    if [ $broken_links -gt 0 ]; then
        ((WARNINGS++))
        return 1
    fi
    return 0
}

check_has_purpose() {
    if ! grep -qiE "^##+ (What I Do|Purpose|Overview)" "$SKILL_MD"; then
        WARNING_MESSAGES+=("No 'What I Do' or purpose section found")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 1))
        return 1
    fi
    STRUCTURE_SCORE=$((STRUCTURE_SCORE + 2))
    return 0
}

check_slash_command() {
    # Determine command location based on skill path
    local cmd_path=""
    if [[ "$SKILL_DIR" == *"/content/skills/"* ]]; then
        # agent-kit skill - command should use ak- prefix
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        cmd_path="$base_path/commands/ak-$SKILL_NAME.md"
    elif [[ "$SKILL_DIR" == *"/.opencode/skill/"* ]]; then
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        cmd_path="$base_path/commands/$SKILL_NAME.md"
    elif [[ "$SKILL_DIR" == *"/.claude/skills/"* ]]; then
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        cmd_path="$base_path/commands/$SKILL_NAME.md"
    fi
    
    if [ -n "$cmd_path" ] && [ ! -f "$cmd_path" ]; then
        WARNING_MESSAGES+=("No slash command found at $cmd_path")
        ((WARNINGS++))
        TECH_IMPL_SCORE=$((TECH_IMPL_SCORE - 1))
        return 1
    fi
    
    if [ -f "$cmd_path" ]; then
        TECH_IMPL_SCORE=$((TECH_IMPL_SCORE + 2))
    fi
    return 0
}

check_command_references_skill() {
    local cmd_path=""
    if [[ "$SKILL_DIR" == *"/content/skills/"* ]]; then
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        cmd_path="$base_path/commands/ak-$SKILL_NAME.md"
    elif [[ "$SKILL_DIR" == *"/.opencode/skill/"* ]]; then
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        cmd_path="$base_path/commands/$SKILL_NAME.md"
    elif [[ "$SKILL_DIR" == *"/.claude/skills/"* ]]; then
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        cmd_path="$base_path/commands/$SKILL_NAME.md"
    fi
    
    if [ -f "$cmd_path" ]; then
        if ! grep -q "@skills/$SKILL_NAME/SKILL.md" "$cmd_path"; then
            WARNING_MESSAGES+=("Command does not reference skill (@skills/$SKILL_NAME/SKILL.md)")
            ((WARNINGS++))
            TECH_IMPL_SCORE=$((TECH_IMPL_SCORE - 1))
            return 1
        fi
        TECH_IMPL_SCORE=$((TECH_IMPL_SCORE + 1))
    fi
    return 0
}

check_agent_kit_prefix() {
    if [[ "$SKILL_DIR" == *"/content/skills/"* ]]; then
        local base_path=$(dirname "$(dirname "$SKILL_DIR")")
        local cmd_without_prefix="$base_path/commands/$SKILL_NAME.md"
        if [ -f "$cmd_without_prefix" ]; then
            WARNING_MESSAGES+=("agent-kit command must use ak- prefix (found commands/$SKILL_NAME.md, should be commands/ak-$SKILL_NAME.md)")
            ((WARNINGS++))
            return 1
        fi
    fi
    return 0
}

check_no_name_conflicts() {
    # NOTE: This check is not currently implemented
    # Would require scanning all installed skills for naming conflicts
    # Future enhancement: check against ~/.opencode/skill/* or .opencode/skill/*
    SUGGESTION_MESSAGES+=("Name conflict check not implemented - manually verify skill name is unique")
    ((SUGGESTIONS++))
    return 0
}

check_quick_start() {
    local quick_start_line=$(grep -n -iE "^##+ Quick Start" "$SKILL_MD" | head -1 | cut -d: -f1)
    if [ -z "$quick_start_line" ]; then
        WARNING_MESSAGES+=("No Quick Start section found")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 1))
        return 1
    fi
    
    if [ "$quick_start_line" -gt 50 ]; then
        WARNING_MESSAGES+=("Quick Start section not within first 50 lines (found at line $quick_start_line)")
        ((WARNINGS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 1))
        return 1
    fi
    
    STRUCTURE_SCORE=$((STRUCTURE_SCORE + 2))
    return 0
}

check_tool_expectations() {
    if ! grep -qiE "Tools? (Used|Required|Needed):" "$SKILL_MD"; then
        WARNING_MESSAGES+=("Tool expectations not documented")
        ((WARNINGS++))
        TECH_IMPL_SCORE=$((TECH_IMPL_SCORE - 1))
        return 1
    fi
    TECH_IMPL_SCORE=$((TECH_IMPL_SCORE + 2))
    return 0
}

check_parenthetical_grouping() {
    if ! grep -qE "\([^)]+,\s*[^)]+\)" <<< "$SKILL_DESC"; then
        WARNING_MESSAGES+=("Description lacks parenthetical grouping (e.g., 'frameworks (React, Angular, Vue)')")
        ((WARNINGS++))
        DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE - 1))
        return 1
    fi
    DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE + 2))
    return 0
}

check_reference_navigation() {
    if [ -d "$SKILL_DIR/references" ]; then
        if ! grep -qiE "^##+ References?" "$SKILL_MD"; then
            WARNING_MESSAGES+=("references/ directory exists but no navigation section found")
            ((WARNINGS++))
            STRUCTURE_SCORE=$((STRUCTURE_SCORE - 1))
            return 1
        fi
        STRUCTURE_SCORE=$((STRUCTURE_SCORE + 1))
    fi
    return 0
}

check_error_handling() {
    # Check for complex skills (>1500 tokens)
    if [ $TOKEN_COUNT -gt 1500 ]; then
        if ! grep -qiE "^##+ (Common )?Errors?" "$SKILL_MD"; then
            WARNING_MESSAGES+=("Complex skill should document common errors")
            ((WARNINGS++))
            CONTENT_SCORE=$((CONTENT_SCORE - 1))
            return 1
        fi
        CONTENT_SCORE=$((CONTENT_SCORE + 2))
    fi
    return 0
}

check_prerequisites() {
    if ! grep -qiE "Prerequisites?:" "$SKILL_MD"; then
        WARNING_MESSAGES+=("Prerequisites not documented")
        ((WARNINGS++))
        CONTENT_SCORE=$((CONTENT_SCORE - 1))
        return 1
    fi
    CONTENT_SCORE=$((CONTENT_SCORE + 2))
    return 0
}

# === SUGGESTION CHECKS (8) ===

check_has_related_skills() {
    if ! grep -qiE "^##+ Related Skills?" "$SKILL_MD"; then
        SUGGESTION_MESSAGES+=("Consider adding 'Related Skills' section")
        ((SUGGESTIONS++))
        return 1
    fi
    TECH_IMPL_SCORE=$((TECH_IMPL_SCORE + 1))
    return 0
}

check_consistent_formatting() {
    # Basic check for markdown formatting issues
    local formatting_issues=0
    
    # Check for unbalanced code fences
    local fence_count=$(grep -cE "^\`\`\`" "$SKILL_MD" || true)
    if [ $((fence_count % 2)) -ne 0 ]; then
        ((formatting_issues++))
    fi
    
    if [ $formatting_issues -gt 0 ]; then
        SUGGESTION_MESSAGES+=("Potential formatting issues detected (unbalanced code fences)")
        ((SUGGESTIONS++))
        return 1
    fi
    return 0
}

check_has_version() {
    if [ $HAS_VERSION -eq 0 ]; then
        SUGGESTION_MESSAGES+=("Consider adding 'version' to metadata")
        ((SUGGESTIONS++))
        return 1
    fi
    return 0
}

check_has_license() {
    if [ $HAS_LICENSE -eq 0 ]; then
        SUGGESTION_MESSAGES+=("Consider adding 'license' field")
        ((SUGGESTIONS++))
        return 1
    fi
    return 0
}

check_decision_matrix() {
    if ! grep -qE "\|.*\|.*\|.*\|" "$SKILL_MD" || ! grep -qiE "(Quick Reference|Decision)" "$SKILL_MD"; then
        SUGGESTION_MESSAGES+=("Consider adding decision matrix or quick reference table")
        ((SUGGESTIONS++))
        STRUCTURE_SCORE=$((STRUCTURE_SCORE - 1))
        return 1
    fi
    STRUCTURE_SCORE=$((STRUCTURE_SCORE + 1))
    return 0
}

check_cross_skill_integration() {
    if ! grep -qE "\`[a-z0-9-]+\`" "$SKILL_MD"; then
        SUGGESTION_MESSAGES+=("Consider referencing related skills")
        ((SUGGESTIONS++))
        TECH_IMPL_SCORE=$((TECH_IMPL_SCORE - 1))
        return 1
    fi
    TECH_IMPL_SCORE=$((TECH_IMPL_SCORE + 1))
    return 0
}

check_concrete_examples() {
    # Check if examples contain actual commands vs placeholders
    if grep -qiE "^##+ Examples?" "$SKILL_MD"; then
        if grep -qE "\[(placeholder|example|args?|options?|flags?)\]" "$SKILL_MD"; then
            SUGGESTION_MESSAGES+=("Examples contain placeholders - make them copy-paste ready")
            ((SUGGESTIONS++))
            CONTENT_SCORE=$((CONTENT_SCORE - 1))
            return 1
        fi
        CONTENT_SCORE=$((CONTENT_SCORE + 2))
    fi
    return 0
}

check_task_centric_framing() {
    # Heuristic: check for tool-centric language
    if grep -qiE "(this (tool|skill) (uses|wraps|utilizes)|uses? the .* (API|library|tool))" <<< "$SKILL_DESC"; then
        SUGGESTION_MESSAGES+=("Description appears tool-centric - consider task-centric framing")
        ((SUGGESTIONS++))
        DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE - 2))
        return 1
    fi
    DESC_QUALITY_SCORE=$((DESC_QUALITY_SCORE + 2))
    return 0
}

# === GRADING CALCULATION ===

calculate_grade() {
    # Cap scores at max values
    [ $DESC_QUALITY_SCORE -gt 35 ] && DESC_QUALITY_SCORE=35
    [ $STRUCTURE_SCORE -gt 25 ] && STRUCTURE_SCORE=25
    [ $CONTENT_SCORE -gt 20 ] && CONTENT_SCORE=20
    [ $TECH_IMPL_SCORE -gt 15 ] && TECH_IMPL_SCORE=15
    [ $SPEC_COMPLIANCE_SCORE -gt 5 ] && SPEC_COMPLIANCE_SCORE=5
    
    # Ensure non-negative
    [ $DESC_QUALITY_SCORE -lt 0 ] && DESC_QUALITY_SCORE=0
    [ $STRUCTURE_SCORE -lt 0 ] && STRUCTURE_SCORE=0
    [ $CONTENT_SCORE -lt 0 ] && CONTENT_SCORE=0
    [ $TECH_IMPL_SCORE -lt 0 ] && TECH_IMPL_SCORE=0
    [ $SPEC_COMPLIANCE_SCORE -lt 0 ] && SPEC_COMPLIANCE_SCORE=0
    
    SCORE=$((DESC_QUALITY_SCORE + STRUCTURE_SCORE + CONTENT_SCORE + TECH_IMPL_SCORE + SPEC_COMPLIANCE_SCORE))
    
    # Add warning if grade is D or F
    if [ $SCORE -lt 70 ]; then
        WARNING_MESSAGES+=("Low grade detected (D/F) - Skill needs significant improvements before publishing")
        ((WARNINGS++))
    fi
}

get_letter_grade() {
    if [ $SCORE -ge 90 ]; then
        echo "A"
    elif [ $SCORE -ge 80 ]; then
        echo "B"
    elif [ $SCORE -ge 70 ]; then
        echo "C"
    elif [ $SCORE -ge 60 ]; then
        echo "D"
    else
        echo "F"
    fi
}

get_grade_description() {
    local grade=$1
    case $grade in
        A) echo "Excellent" ;;
        B) echo "Good" ;;
        C) echo "Adequate" ;;
        D) echo "Poor" ;;
        F) echo "Failing" ;;
    esac
}

# === OUTPUT FORMATTING ===

print_report() {
    local letter_grade=$(get_letter_grade)
    local grade_desc=$(get_grade_description $letter_grade)
    
    echo ""
    echo "╭─────────────────────────────────────────╮"
    echo "│  Skill Validation: $SKILL_NAME"
    echo "╰─────────────────────────────────────────╯"
    echo ""
    echo -e "${RED}🔴 Errors:      $ERRORS${NC}"
    echo -e "${YELLOW}🟡 Warnings:    $WARNINGS${NC}"
    echo -e "${GREEN}🟢 Suggestions: $SUGGESTIONS${NC}"
    echo ""
    
    if [ $ERRORS -gt 0 ]; then
        echo -e "${RED}🔴 Errors:${NC}"
        for msg in "${ERROR_MESSAGES[@]}"; do
            echo -e "   ${RED}•${NC} $msg"
        done
        echo ""
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}🟡 Warnings:${NC}"
        for msg in "${WARNING_MESSAGES[@]}"; do
            echo -e "   ${YELLOW}•${NC} $msg"
        done
        echo ""
    fi
    
    if [ $SUGGESTIONS -gt 0 ]; then
        echo -e "${GREEN}🟢 Suggestions:${NC}"
        for msg in "${SUGGESTION_MESSAGES[@]}"; do
            echo -e "   ${GREEN}•${NC} $msg"
        done
        echo ""
    fi
    
    # File info
    echo "Files checked:"
    echo -e "   ${GREEN}✓${NC} SKILL.md ($LINE_COUNT lines, ~$TOKEN_COUNT tokens)"
    
    if [ -d "$SKILL_DIR/references" ]; then
        for ref in "$SKILL_DIR/references"/*.md; do
            if [ -f "$ref" ]; then
                echo -e "   ${GREEN}✓${NC} references/$(basename "$ref")"
            fi
        done
    fi
    
    if [ -d "$SKILL_DIR/assets" ]; then
        for asset in "$SKILL_DIR/assets"/*; do
            if [ -f "$asset" ]; then
                echo -e "   ${GREEN}✓${NC} assets/$(basename "$asset")"
            fi
        done
    fi
    
    if [ -d "$SKILL_DIR/scripts" ]; then
        for script in "$SKILL_DIR/scripts"/*; do
            if [ -f "$script" ]; then
                echo -e "   ${GREEN}✓${NC} scripts/$(basename "$script")"
            fi
        done
    fi
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "GRADE BREAKDOWN:"
    echo ""
    printf "Description Quality        %2d/35  (%d%%)\n" $DESC_QUALITY_SCORE $((DESC_QUALITY_SCORE * 100 / 35))
    printf "Structure & Organization  %2d/25  (%d%%)\n" $STRUCTURE_SCORE $((STRUCTURE_SCORE * 100 / 25))
    printf "Content Quality           %2d/20  (%d%%)\n" $CONTENT_SCORE $((CONTENT_SCORE * 100 / 20))
    printf "Technical Implementation  %2d/15  (%d%%)\n" $TECH_IMPL_SCORE $((TECH_IMPL_SCORE * 100 / 15))
    printf "Specification Compliance   %d/5   (%d%%)\n" $SPEC_COMPLIANCE_SCORE $((SPEC_COMPLIANCE_SCORE * 100 / 5))
    echo ""
    echo "═══════════════════════════════════════════"
    echo -e "TOTAL SCORE: ${BLUE}$SCORE/100${NC}"
    echo ""
    
    if [ "$letter_grade" = "A" ]; then
        echo -e "Grade: ${GREEN}$letter_grade ($grade_desc)${NC}"
    elif [ "$letter_grade" = "B" ]; then
        echo -e "Grade: ${BLUE}$letter_grade ($grade_desc)${NC}"
    elif [ "$letter_grade" = "C" ]; then
        echo -e "Grade: ${YELLOW}$letter_grade ($grade_desc)${NC}"
    else
        echo -e "Grade: ${RED}$letter_grade ($grade_desc)${NC}"
    fi
    echo ""
    
    if [ $ERRORS -gt 0 ]; then
        echo -e "Status: ${RED}❌ FAILED${NC} (has errors)"
    else
        echo -e "Status: ${GREEN}✅ PASSED${NC}"
    fi
    echo ""
}

# === MAIN ===

main() {
    echo "Validating Agent Skill..."
    
    # Parse frontmatter
    parse_frontmatter
    
    # Run error checks (9)
    # Note: || true prevents set -e from exiting on return 1
    check_name_exists || true
    check_name_format || true
    check_name_reserved || true
    check_description_exists || true
    check_description_length || true
    check_no_xml_in_frontmatter || true
    check_skill_md_exists || true
    check_context7_format || true
    check_no_placeholders || true
    
    # Run warning checks (17)
    check_description_has_when || true
    check_description_action_verbs || true
    check_keyword_density || true
    check_has_examples || true
    check_token_limit || true
    check_referenced_files || true
    check_has_purpose || true
    check_slash_command || true
    check_command_references_skill || true
    check_agent_kit_prefix || true
    check_no_name_conflicts || true
    check_quick_start || true
    check_tool_expectations || true
    check_parenthetical_grouping || true
    check_reference_navigation || true
    check_error_handling || true
    check_prerequisites || true
    
    # Run suggestion checks (8)
    check_has_related_skills || true
    check_consistent_formatting || true
    check_has_version || true
    check_has_license || true
    check_decision_matrix || true
    check_cross_skill_integration || true
    check_concrete_examples || true
    check_task_centric_framing || true
    
    # Calculate grade
    calculate_grade
    
    # Print report
    print_report
    
    # Exit with appropriate code
    if [ $ERRORS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main
