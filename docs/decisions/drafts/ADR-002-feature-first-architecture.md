# ADR-002: Feature-First Clean Architecture

- Status: Proposed; pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-007, CSA-016

## Context

The application has distinct areas such as authentication, marketplace,
checkout, payments, enrollments, learning, and administration. The project
needs feature ownership without coupling business rules to Flutter widgets.

## Decision

Proposed: organize application code by feature and keep presentation, domain, and
data responsibilities separated where the feature warrants those layers.
Keep shared core modules small and avoid circular dependencies.

## Alternatives considered

- A single layer-first tree: simpler to start, but spreads each feature
  across broad shared directories and makes ownership less clear.
- A more heavily layered architecture with abstractions for every
  dependency: may improve substitution in selected areas, but adds
  indirection without evidence that each abstraction is needed.

## Consequences and tradeoffs

- Feature boundaries make task ownership and focused tests clearer.
- Cross-feature contracts need deliberate ownership and review.
- Layers should be introduced when they protect a real boundary; avoid
  empty or duplicated abstractions.
- Shared routing, theme, and core files remain coordinated surfaces.

## Security and privacy impact

UI and domain code may guide behavior but cannot establish trusted
authorization. Payment finalization, role checks, and paid-content access
must be enforced by trusted backend and database controls.

## Approval

Pending Project Lead approval. The directory structure in current project
documents is a proposal until accepted.
