# PR #197 backend review repair

Date: 2026-10-19. Owner: CODEX, Review and merge PRs 185–188 chat.
Status: IN_REVIEW. Authority: project owner requested fixing the remaining
review and CI issues and trying the merge. Coordination is recorded in issue193:
https://github.com/iamramishka/acendra/issues/193#issuecomment-6272328791

Branch: `fix/csa-267-pr-review`. Managed worktree: `pr197-review-fixes`.
Base: PR197 `8d592457f539080e8b9fdbca4c3305baa5ccc4fa`.
Scope: backend HTTP deadlines, PDF page content-stream parsing and regressions;
review evidence only. No SQL, role, payment, global theme or live configuration.
The parallel Chrome repair owns its isolated route-test/learning UI scope.
The existing CSA-267 integration owner retains its checkout and dev conflict
resolution; integrate only the latest published history, without force pushes.

Required verification: reproduce the slow-clean-inspector and malformed-page
failures before editing implementations; run Node and pinned Python checks;
retain timeout/failure denials; independently review the repaired diff; pass
current-head hosted checks and obtain required approval before a normal merge.
Live scanner/Storage acceptance and production release remain separate gates.

## Reproduced failures and repairs

- RED: real15.1-second clean inspection returned503 before final commit because
  the backend AbortSignal had already expired. GREEN: each Auth/Storage/RPC call
  now receives its own15-second signal; inspection keeps its separate25-second
  deadline, and successful inspection can reach the fresh finalization request.
- RED: a one-page PDF with an unterminated content string raised no exception.
  GREEN: force lazy page operator parsing inside the bounded child. The malformed
  stream is rejected while a valid content stream and blank pages remain accepted.

Fresh checks:42 focused Node tests passed with one Linux-CI-only skip;8 pinned
Python tests passed with one Linux-resource skip. Node's existing inspection
timeout, permission-recheck and unsafe-verdict denials still pass. Python uses
pypdf6.20.1 and Pillow12.3.0. `git diff --check` passed. A separate read-only agent
review found no actionable defect in the four-file repair; it is AI review, not
independent human approval. No DB schema or delivery authorization changed.

The parallel Chrome repair and the already-published dev integration will be
combined before final current-head checks. Hosted Linux limits, real managed
Storage/scanner acceptance, required approval and normal protected merge remain
unverified at this intermediate stage. No live deployment is performed here.
