# ADR-001: Flutter Web as the MVP Platform

- Status: Proposed; pending Project Lead approval
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-001, CSA-002, CSA-016

## Context

Acedra needs a responsive course-selling application for students and
administrators. The project documents identify browser delivery as the
initial platform and list Android and iOS as possible future platforms.
The product scope and acceptance criteria are still awaiting approval.

## Decision

Proposed: use Flutter Web for the MVP client, with responsive layouts and browser
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

Pending. Do not treat this proposal as an approved platform commitment
until the Project Lead records an approval decision.
