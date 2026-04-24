---
name: swarm
description: Orchestrate agent team execution of a prompts directory. Use when the user wants to run multiple prompt files in tiered parallel/sequential execution.
---

Orchestrate agent team execution of a prompts directory. Argument: path to a prompts directory (e.g., `docs/test-harness/prompts`).

## Overview

Read the given prompts directory's `README.md`, parse its tier structure, present an execution plan, then run all prompts using Claude Code agent teams — executing tiers sequentially and prompts within a tier either in parallel or sequentially as specified.

## Steps

### 1. Validate input

If no argument was provided, print this usage message and stop:

```
Usage: /swarm <prompts-dir>

Examples:
  /swarm docs/test-harness/prompts
  /swarm docs/sans-juce/prompts
  /swarm docs/e2e-testing/prompts

The prompts directory must contain a README.md and at least one
numbered prompt file (e.g., 01-name.md).
```

Resolve the argument relative to the current working directory. Verify:
- The directory exists
- It contains a `README.md`
- It contains at least one `*.md` file matching the pattern `[0-9][0-9]-*.md`

If any check fails, report the specific error and stop.

### 2. Parse README.md

Read `README.md` from the prompts directory and extract the tier execution plan.

**Tier detection** — scan for tier headers using these patterns (in order of precedence):

1. **Markdown headers with tier number**: lines matching `### Tier N` (case-insensitive) where N is a digit. The parenthetical after the tier number contains the execution mode and description, e.g., `### Tier 1 (Sequential — Must Complete First)` or `### Tier 2 (Parallel — After Tier 1)`.

2. **No tier headers found**: treat all prompts as a single parallel tier (Tier 1).

**Execution mode per tier** — examine the parenthetical text after `### Tier N`:
- If it contains "sequential" (case-insensitive) → sequential execution
- Otherwise → parallel execution (the default)

**Prompt extraction per tier** — for each tier header, find the prompt filenames by scanning the content between this tier header and the next tier header (or end of relevant section):

1. **From markdown tables**: look for rows containing links or filenames matching `[0-9][0-9]-*.md`. Extract the filename from markdown links like `[name](filename.md)` or bare filenames.

2. **From bash code blocks**: look for lines containing `claude` commands referencing `.md` files. Extract the prompt filename from the path (last path component).

3. **Fallback**: if neither method finds prompts for a tier, collect any remaining `[0-9][0-9]-*.md` filenames mentioned anywhere in that tier's section.

**Cross-check**: after parsing, verify every discovered prompt filename exists in the prompts directory. For any prompt files in the directory that were NOT assigned to a tier, add them to the last tier (as parallel).

**Fallback if README is unparseable**: if tier parsing fails entirely, collect all `[0-9][0-9]-*.md` files in the directory sorted by number and place them all in a single parallel tier.

### 3. Present execution plan

Display the parsed plan to the user in this format:

```
## Swarm Execution Plan

**Directory**: <prompts-dir>
**Prompts**: <N> total across <M> tiers

### Tier 1 (<mode>) — <N> prompts
  1. <filename> — <first heading from file or filename>
  2. <filename> — <first heading from file or filename>

### Tier 2 (<mode>) — <N> prompts
  1. <filename> — <first heading from file or filename>
  ...

### Between tiers
  Build verification: cmake --build --preset release

### Final verification
  scripts/verify.sh (if present)
```

To get the prompt description, read the first `# ` heading from each prompt file. If there's no heading, use the filename.

If any prompt files listed in the README were not found on disk, show a warning:
```
WARNING: Missing prompt files (will be skipped):
  - <filename>
```

Use AskUserQuestion to confirm execution. Options:
- **Execute all** — run the full plan
- **Execute from tier N** — skip earlier tiers (useful for resuming)
- **Dry run** — just show the plan, don't execute

If the user picks "Dry run" or declines, stop here.

### 4. Create team

Create an agent team for this swarm run:

```
TeamCreate:
  team_name: "swarm-<directory-slug>"
  description: "Swarm execution of <prompts-dir>"
```

Where `<directory-slug>` is derived from the prompts directory path (e.g., `docs/test-harness/prompts` → `test-harness`). Use the parent directory name of the prompts dir, or the grandparent if the parent is literally "prompts".

### 4b. Build ctxmon (optional)

Build the context monitoring CLI. If the source is not available or the build fails, continue without monitoring — it is optional.

```bash
CTXMON_SRC="${CTXMON_SRC:-$HOME/git/drem-orchestrator.git}"
if [ -d "$CTXMON_SRC" ]; then
    go build -o /tmp/ctxmon "$CTXMON_SRC/cmd/ctxmon" 2>/dev/null
fi
```

If `/tmp/ctxmon` does not exist after this step, skip all ctxmon-related steps below and omit context usage from reports.

### 5. Create tasks

Create one task per prompt using TaskCreate:
- **subject**: `[Tier N] <prompt-filename>` (e.g., `[Tier 1] 01-cmake-infrastructure.md`)
- **description**: The first heading from the prompt file, plus the full file path
- **activeForm**: `Running <prompt-filename>`

Wire up tier dependencies: all tasks in Tier N+1 should be `blockedBy` all tasks in Tier N. Use TaskUpdate with `addBlockedBy` after creation.

### 6. Execute tiers

Process tiers from lowest to highest. For each tier:

#### 6a. Read prompt contents

For each prompt in the tier, read the full prompt file content.

#### 6b. Spawn agents

Prepend this preamble to each prompt's content before passing it to the agent.

**If ctxmon was built** (i.e., `/tmp/ctxmon` exists), use this preamble:

```
You are a swarm agent working in the current directory. Important rules:
- As your FIRST action, run: /tmp/ctxmon setup .
  (If ctxmon is not found, skip this step and continue normally)
- Do NOT create worktrees — work directly in the current directory
- Commit your changes when done with a descriptive commit message
- Run the build verification command after making changes: cmake --build --preset release
- If scripts/verify.sh exists, run it before declaring done
```

**If ctxmon was NOT built**, use this preamble (without the ctxmon line):

```
You are a swarm agent working in the current directory. Important rules:
- Do NOT create worktrees — work directly in the current directory
- Commit your changes when done with a descriptive commit message
- Run the build verification command after making changes: cmake --build --preset release
- If scripts/verify.sh exists, run it before declaring done
```

For each prompt, spawn an agent:

```
Agent:
  name: "agent-<NN>" (e.g., "agent-01")
  subagent_type: "general-purpose"
  team_name: <team-name>
  prompt: <preamble + prompt content>
  isolation: "worktree"
  mode: "bypassPermissions"
```

**Parallel tiers**: spawn all agents in the tier simultaneously (multiple Agent tool calls in one message). Then wait for all to complete.

**Sequential tiers**: spawn one agent at a time. Wait for it to complete before spawning the next.

As agents complete, update their tasks to `completed` via TaskUpdate.

#### 6c. Handle failures

If an agent reports a failure or error:
1. Mark the task as still `in_progress` (do not mark completed)
2. Report the error to the user with the agent name and a summary
3. Use AskUserQuestion with options:
   - **Retry** — re-run the same prompt
   - **Skip** — mark as completed anyway, continue to next
   - **Abort** — stop the entire swarm

#### 6d. Build verification between tiers

After all agents in a tier complete (and before starting the next tier), run build verification:

```bash
cmake --build --preset release 2>&1 | tail -50
```

If the build fails:
1. Show the last 50 lines of output
2. Use AskUserQuestion with options:
   - **Continue anyway** — proceed to next tier despite build failure
   - **Abort** — stop the swarm
   - **Fix manually** — pause and let the user fix, then continue

#### 6e. Context usage collection (if ctxmon available)

After each agent completes, if the Agent result includes a worktree path, collect context usage:

```bash
/tmp/ctxmon status <worktree-path>
```

Store the JSON output per agent. If ctxmon exits with code 2 (no data yet) or is not available, record "no data" for that agent.

#### 6f. Report tier completion

Report tier completion with context usage if available:

```
Tier N complete: <X>/<Y> prompts succeeded
Context usage:
  agent-01: 45% used, $0.12
  agent-02: 72% used, $0.35
```

If ctxmon is not available, omit the "Context usage" section:

```
Tier N complete: <X>/<Y> prompts succeeded
```

### 7. Final verification

After all tiers complete:

1. Run `scripts/verify.sh` if it exists in the working directory:
   ```bash
   scripts/verify.sh 2>&1 | tail -100
   ```

2. Report final summary. If ctxmon data was collected, include the context usage table:

   ```
   ## Swarm Complete

   **Directory**: <prompts-dir>
   **Results**: <N>/<M> prompts completed successfully

   ### Per-tier results
   - Tier 1 (<mode>): <X>/<Y> succeeded
   - Tier 2 (<mode>): <X>/<Y> succeeded
   ...

   ### Context usage
   | Agent | Used% | Input tokens | Output tokens | Cost |
   |-------|-------|-------------|--------------|------|
   | agent-01 | 45% | 12,345 | 3,456 | $0.12 |
   | agent-02 | 72% | 28,901 | 8,765 | $0.35 |
   | **Total** | | **41,246** | **12,221** | **$0.47** |

   ### Verification
   <pass/fail + summary>
   ```

   If ctxmon was not available or no data was collected, omit the "Context usage" section entirely.

### 8. Clean up

Send shutdown requests to any remaining active teammates, then delete the team:

```
TeamDelete
```
