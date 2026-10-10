# ADR-001: Flutter Web as the MVP Platform

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-001, CSA-002, CSA-016

## Context

Acedra needs a responsive course-selling application for students and
administrators. The project documents identify browser delivery as the
initial platform and list Android and iOS as possible future platforms.
The product scope and acceptance criteria were accepted under CSA-001/002.

## Decision

use Flutter Web for the MVP client, with responsive layouts and browser
navigation behavior. Treat mobile applications as future clients, not as
part of the MVP commitment.

## Alternatives considered

- A web-first HTML client: could better match browser conventions, but
  would depart from the proposed shared Flutter direction.
- Separate native clients: could provide platform-specific experiences,
  but would expand MVP delivery and maintenance scope.

## Consequences and tradeoffs

- A shared Flutter codebase may reduce duplicated client implementation.
- Browser rendering, accessibility, download handling, and protected
  content limits must be evaluated in web-specific testing.
- Flutter Web cannot prevent screenshots, recording, or copying bytes
  delivered to an authorized browser.
- Search visibility, browser performance, and any non-functional browser
  requirements still require explicit product review.

## Security and privacy impact

The browser is an untrusted environment. Client route guards, hidden UI,
and client-held state must not authorize student, administrator, payment,
or content access. Enforce authorization in trusted backend and database
boundaries.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
