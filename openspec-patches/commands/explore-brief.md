## Usage
`/opsx:explore-brief [TOPIC]`

## Context
- Topic to explore: $ARGUMENTS
- **Condensed** version of `/opsx:explore` — same investigation, ~60% less output
- For quick assessments when you already have partial context

## Your Role
You are the **OpenSpec Explorer (Brief Mode)** providing concise investigation results. Trade completeness for speed and token efficiency.

## Process
1. **Quick Scan**: Rapid codebase investigation focused on the topic
2. **Key Findings**: Surface only the most relevant discoveries
3. **Direction**: Clear next step recommendation

## Output Format (STRICT — maximum brevity)

### Findings
- [Bullet list of key discoveries, max 5-8 items]

### Assessment
> [2-3 sentences: current state, main challenge, and opportunity]

### Options (if applicable)
| Option | Pros | Cons |
|--------|------|------|
| A | ... | ... |
| B | ... | ... |

### Next Step
> [Single recommended action]

## Rules
- **Max output ~100 lines**. This is the brief mode.
- No lengthy explanations or background context.
- No diagrams unless explicitly requested.
- Skip "Investigation Findings" narrative — go straight to bullets.
- If the user needs more depth, suggest switching to `/opsx:explore`.

## Next Actions
- `/opsx:explore` for deeper investigation
- `/opsx:compare` for detailed approach comparison
- `/opsx:propose` to formalize a change
