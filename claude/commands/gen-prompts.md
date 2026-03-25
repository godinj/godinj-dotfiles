Generate agent prompts from design documentation. The argument should be a path to a doc directory or specific doc file (e.g., "docs/sans-juce" or "docs/sans-juce/05-audio-io.md").

## Overview

Read the provided design documentation and generate a set of focused agent prompts — one per logical work unit — that can be executed in parallel by Claude Code agents. The prompts should decompose the documented work into independent, buildable tasks.

## Steps

### 1. Gather context

- Read `CLAUDE.md` for project conventions, build commands, architecture, and branch context.
- Read all `.md` files in the provided doc path (or the single file if a file was given).
- If a migration guide exists (e.g., `*-migration-guide.md`), read it for file-by-file scope.
- Identify the current branch name with `git branch --show-current`.

### 2. Analyze the documentation

Identify the following from the docs:

- **Work units**: Logical chunks that one agent can implement independently. Group by subsystem, not by file. A work unit typically produces 2-5 new/modified files.
- **New types/APIs**: Classes, structs, enums to create (with method signatures).
- **Migrations**: Existing files that need updating, mapping old types to new types.
- **External dependencies**: System libraries to install, CMake additions needed.
- **Internal dependencies**: Which work units depend on outputs of other work units.
- **Existing foundation code**: Files the agent should reuse rather than reimplement (e.g., `spsc_queue.h`, `worker_thread.h`).

### 3. Organize into tiers

- **Tier 1**: Work units with no internal dependencies (can all run in parallel).
- **Tier 2**: Work units that depend on Tier 1 outputs.
- **Tier N**: Continue as needed.

Number prompts sequentially: `01-<name>.md`, `02-<name>.md`, etc. Tier 1 prompts come first.

### 4. Generate each prompt

Write each prompt to `docs/<feature>/prompts/NN-<slug>.md` where `<feature>` is derived from the doc directory name (e.g., `docs/sans-juce/` → `sans-juce`). If the docs are at the repo root, use the branch name.

Each prompt MUST follow this exact structure:

```markdown
# Agent: <Descriptive Name>

You are working on the `<branch>` branch of <Project Name>, a <short project description>.
Your task is <phase/scope description>: <what this agent does>.

## Context

Read these specs before starting:
- `<path to design doc>` (<which section>)
- `<path to migration guide>` (<which section>)
- `<path to existing file being replaced>` (current implementation to replace)

## Prerequisites

<Only if external dependencies are needed. Otherwise omit this section entirely.>

Ensure <library> is available:

\```bash
<install command>
\```

Add to `CMakeLists.txt`:

\```cmake
<pkg_check_modules / find_package / target_link_libraries>
\```

## Dependencies

<Only if this agent depends on another agent's output. Otherwise omit.>

This agent depends on Agent NN (<name>). If those files don't exist yet,
create stub headers with the interfaces from `<design doc>` and implement against them.

## Deliverables

### New files (<target directory>)

#### 1. <filename.h/.cpp>

<One-line description.>

- <method/type signatures as bullet list>
- <internal implementation notes>

### Migration

#### N. <existing file path>

<What to replace and what to keep. Be specific about old→new type mappings.>

## <Optional constraint section>

<IMPORTANT: Scope Limitation, Audio Thread Safety Rules, or similar.
Only include if there are critical constraints the agent must follow.>

## Conventions

- Namespace: `<namespace>`
- <Coding style from CLAUDE.md>
- Add all new `.cpp` files to `CMakeLists.txt` `target_sources`
- Build verification: `<build command from CLAUDE.md>`
```

### 5. Quality rules for prompts

- **Self-contained**: Each prompt must have enough detail for an agent to work without reading other prompts. Include full method signatures, not just "see the design doc."
- **Precise scope**: List every file the agent creates and every file it modifies. No ambiguity about what's in scope.
- **Boundary clarity**: If a file is shared between agents, explicitly say which agent owns it. If a JUCE/framework type remains at a boundary, call out that it's out of scope.
- **Actionable context section**: List specific files to read with parenthetical hints about what to look for in each.
- **Build-verifiable**: Every prompt ends with the build command so the agent knows when it's done.
- **No bloat**: Don't include architecture overviews or motivation. The agent doesn't need to understand why — just what to build and how.

### 6. Generate execution summary

After writing all prompts, create a `docs/<feature>/prompts/README.md` with:

- A table listing all prompts: number, name, tier, dependencies, files created, files migrated.
- The execution order showing which prompts can run in parallel.
- Example launch commands:

```bash
# Tier 1 (parallel)
claude --agent docs/<feature>/prompts/01-<name>.md
claude --agent docs/<feature>/prompts/02-<name>.md

# Tier 2 (after Tier 1 merges)
claude --agent docs/<feature>/prompts/04-<name>.md
```

### 7. Present for review

Before writing any files, present the proposed prompt breakdown to the user:

1. List each prompt with its name, scope, and tier.
2. Show the dependency graph.
3. Ask for confirmation before generating.

After generating, report the file paths and total prompt count.
