## Documentation

Read docs/OVERVIEW.md before planning changes. Create it if missing. Structure:

```yaml
Overview:
  description: What the codebase does
  subsystems: High-level subsystems and interactions
  data_flow: Data/control flow across subsystem boundaries
Features Index:
  feature_name:
    description: <description>
    entry_points: [entry1, entry2]
    depends_on: [other_feature]
    doc: docs/features/feature_name.md
```

Create feature docs for any feature being worked on. Each must include:
- Scope and non-scope
- Detailed data/control flow through the implementation
- All related files, their role, and key exports/interfaces
- Invariants and constraints

Update docs/OVERVIEW.md and relevant feature docs with every change.

## Planning and Parallel Work

- Plan first for any change beyond 1-2 steps. Separate by area of concern for parallel subagents.
- Ask about anything ambiguous or underspecified.
- Execute multi-workstream plans with parallel subagents in separate worktrees.
- Branch names based on the change's function. Note expected sibling-PR conflicts in PR bodies.
- Cross-branch merge conflicts from overlapping files are acceptable; let the merger resolve.

## Git Conventions

- Never work on main unless specified.
- Branch prefixes: fix/, feat/, chore/, release/, docs/, test/
- Publish branches and open PRs; don't merge to main locally. Let the user merge.
- Commit messages: short, one-line, descriptive (e.g. "feat: add api support for steering").
- PR bodies: what changed and why. No test/verify section.

## Code Organization

- Small focused modules over monolithic files. Split at ~1000 lines.
- Nested directory structures for clean separation.

## Type Systems

Design types before implementing. Encode correctness into the type system. Make invalid states unrepresentable.

## Testing

- Write extensive tests before implementing.
- Never change a correct test. Never change tests you didn't write unless told they're wrong.
- Run tests to catch regressions. If tests fail, fix the code, not the test.

## Dependency Management

- Freely add dependencies. Use latest releases unless known issues exist.
- Pin versions. Remove unused dependencies after refactors.

## Error Handling

- Errors must be structured and typed.
- Handle errors explicitly — no bare try/catch.

## Architecture

- SQL: Postgres (or SQLite). Prefer Postgres extensions (pgvector, AGE, PostGIS, pg_trgm, timescaledb) over specialized databases unless genuine perf/scaling concerns.
- Use async/parallel architectures where appropriate.
- Prefer channels over shared state. If shared state is necessary, use typed synchronization primitives.
- Don't mix async and threaded concurrency. If both needed, use task parallelism with channels.
- No backwards compatibility unless asked.

## Logging

- Levels: debug (dev detail), info (operational), warn (recoverable), error (needs attention).
- Structured logging with key-value pairs, not plain strings.

## Configuration and Secrets

- Secrets in .env files, never committed.
- Non-secret config in structured json/yaml. Secret references point to env vars with sensible defaults.

## Language Guides

Refer to these before writing code:
- ~/.claude/languages/PYTHON.md
- ~/.claude/languages/RUST.md
- ~/.claude/languages/TYPESCRIPT.md