---
name: document
description: document the codebase with overview and feature docs
---

Please use parallel subagents to explore the codebase and ensure docs/OVERVIEW.md is up to date.
Also use parallel subagents to make sure that docs/features/*.md are all up to date. 
If the overview file does not exist, create it. If a feature is not documented, create a feature doc file for it.

The overview file should not go into deep detail on features, but should link to other files in the docs folder
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
