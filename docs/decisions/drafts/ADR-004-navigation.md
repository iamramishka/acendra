# ADR-004: go_router for Application Navigation

- Status: Proposed; pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-007, CSA-016

## Context

Acedra needs browser-compatible navigation for public catalog pages,
authenticated student flows, and administrative screens. Project
documents propose go_router.

## Decision

Proposed: use go_router for route composition, URL handling, and navigation
integration in the Flutter client. Keep authorization enforcement in
trusted backend services and database policies.

## Alternatives considered

- Flutter Navigator APIs directly: a supported option with fewer routing
  concepts, but requires the project to assemble more URL and route policy.
- Another routing package: could meet the same need, but would create an
  additional dependency and convention without a documented requirement.

## Consequences and tradeoffs

- Named routes and URL integration provide a common navigation contract.
- Route definitions and shared redirects are a coordinated file surface.
- Deep links and browser back/forward behavior need verification.

## Security and privacy impact

Redirects and route guards improve user experience only. Direct API calls
must still fail when the caller is unauthorized. Avoid sensitive personal,
payment, or private storage data in URLs.

## Approval

Pending Project Lead approval. This record does not authorize a dependency
version change.
