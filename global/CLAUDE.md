## Documentation
Make sure you read from docs/OVERVIEW.md when planning changes and finding where you need to explore in the codebase. If the overview
file does not exist, create it. It should not go into deep detail on features, but should link to other files in the docs folder
that are named after the feature.

The overview file should be structured with something like:

"
Overview:
    description:
        A general overview of what the codebase is trying to accomplish.
    subsystems:
        What the high level subsystems are and how they interact.
    data_flow:
        A basic model of the data/control flow across the boundaries of the major subsystems.

Features Index:
    feature1:
        description: \<description of feature\>
        entry_points: \[entry_point1, entry_point2\]
        depends_on: \[feature2\]
        doc: docs/features/feature1.md
    feature2:
        description: \<description of feature\>
        entry_points: \[entry_point1\]
        depends_on: \[\]
        doc: docs/features/feature2.md
"

If a feature is being worked on but does not have a doc in the folder, create one.
Feature docs should be much more detailed and include:
- A clear statement of what is in scope and not in scope
- Detailed data/control flow spec through the feature implementation.
- A list of all files that are related to the feature, what part of the feature is in them, and what key exports/interfaces it relies on.
- Invariants and constraints that should not be violated in the implementation

When you make changes, adjust docs/OVERVIEW.md and the relevant feature docs. 

## Planning and Parallel Work

When you make any changes that take more than 1 or 2 steps, make a plan first. When making plans, make sure you separate changes
by area of concern so that parallel subagents can easily split up the work. When grouping changes that touch the same files but
have different functionality, it is okay to create merge conflicts across branches but let the person merging handle them.

When making plans, be sure to ask the user anything where how to deal with it seems ambiguous or underspecified.

When executing plans with multiple workstreams, always use parallel subagents each with their own worktree. The branch name for a worktree should be based on the function of
the group of changes. Include a note in the PR body when known conflicts with sibling PRs are expected.

## Git Conventions

- Do not work on main unless otherwise specified.
- Use fix/, feat/, chore/, release/, docs/, release/, and test/ for branch naming.
- Publish branches and make a PR for each branch instead of just merging changes to main locally, but let the user merge them unless otherwise specified.
- Use short one line commit messages that are descriptive of the changes like "feat: add api support for steering functionality".
- Write detailed PR bodies that cover what changed and why. Don't add a test/verify section to PRs. Just what changed and why.

## Code Organization

Prefer small focused modules to monolithic files. Split files if they are above 1000 lines. Use nested directory structures for modules and submodules
so that things are cleanly separated.

## Type Systems

Always design your type system before implementing a feature, try to encode as much of the correctness checking into the type system
as you can. Invalid states should be unrepresentable wherever possible.

## Testing

- Always write extensive tests before implementing a feature. 
- Once a test is correct, do not change it. 
- If you did not write the test yourself, don't change it unless explicitly told it is wrong. 
- When implementing changes, make sure no regressions are introduced by running tests. 
- If code does not pass the tests, change the code and not the test.

## Dependency Management

- Freely add dependencies unless told otherwise. 
- Start with the latest releases unless you have a reason to believe that they won't work and older versions are what people actually use. 
- Pin versions where possible in order to ensure new releases don't break the environment or introduce security vulnerabilities.
- Make sure you remove dependencies that are no longer used after refactors.

## Error Handling

- Errors should be structured and typed.
- Always handle errors explicity, don't use bare try/catch logic.

## Architectural Decisions

- When choosing a database, always use Postgres for SQL unless using sqlite. 
- When choosing other databases, always prefer using postgres extensions (eg pgvector, Apache AGE, PostGIS, pg_trgm, timescaledb, etc.) over specialized databases unless there are genuine performance issues or architectural concerns like decoupled horizontal scaling.
- Always use asyncronous and parallel architectures where appropriate to ensure speed and efficiency.
- Use channels for message passing to avoid shared state where possible. If you must use shared state, use the languages typed synchronization primitives.
- Don't mix async and threaded concurrency models.
- Do not worry about making features backwards compatible unless told to.

## Logging and Observability

- Properly use logging levels with debug for development detail, info for operational events, warn for recoverable issues, and error for failures that need attention.
- Use structured logging with key-value pairs instead of just strings. 

## Configuration and Secrets

- Use .env files for secrets, never commit a secret.
- When creating configuration systems, use structured json/yaml config files for non-secret configuration options. If a configuration option needs a secret, have the config file point to an environment variable with a sensible default.


## Language Guides

Refer to these before writing code in a given language:
- ~/.claude/languages/PYTHON.md
- ~/.claude/languages/RUST.md
- ~/.claude/languages/TYPESCRIPT.md
