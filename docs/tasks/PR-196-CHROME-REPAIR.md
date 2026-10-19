# Chrome lesson-route regression repair

Date: 2026-10-19. Owner: CODEX Chrome repair worker. Status: IN_PROGRESS.
Authority: owner requested fixing the remaining review/CI issues and trying merge;
coordination: https://github.com/iamramishka/acendra/issues/193#issuecomment-6272328791.
Branch: fix/csa-265-chrome-route-checks.
Worktree: C:/Users/ramis/.codex/worktrees/pr196-chrome-fixes/acendra.
Base: 3049c16e33d11d0547f0252ae5258ad2d48e21ee.

Scope: test/browser/lesson_route_regressions.dart; narrowly affected learning
workspace UI only if a production bug is reproduced. Preserve all existing route,
content, completion and drawer assertions. Exclude other active media/backend,
course-artwork, dependency, router and deployment work. PR196 is closed as a
duplicate; the coordinator will integrate this commit into the shared dev/PR197
candidate, without reopening PR196.

Dependencies: existing reviewed lesson routing and saved-progress contracts;
serialized Flutter/Chrome SDK use assigned to this worker. Do not terminate
unowned browser/compiler processes.

Acceptance: reproduce the two Chrome failures from hosted job 118171192501,
diagnose their cause, apply a bounded fix, run the affected Chrome suite and
relevant local checks, then self-review and hand off a commit. Maintainer approval,
current-head CI and protected merge remain coordinator-owned gates. No push,
review publication, merge or production changes by this worker.

Hosted RED: job 118171192501 at head 569f8cbc reports the completion and mobile
drawer failures. The test file blob is identical at that head and this base:
40bf3769b63e64b4f61232980fdeea8179fa180f. The final completion tap at y=760
hits a bottom overlay: the earlier module-finished snackbar still has its display
timer active; pumpAndSettle only drains scheduled animation frames.

Repair: assert module feedback, advance the snackbar's actual duration and settle
its exit before opening/tapping the final lesson. Preserve every original route,
content and drawer assertion. A bounded mobile diagnostic prints actual route,
content count and sheet count before the existing assertions so the hosted GitHub
reporter cannot conceal the failing state. No production change is inferred yet.

Local locked offline dependency restore passes. Local Chrome compiled and launched
but the Windows Flutter test host failed before executing any test: its generated
nested test key loses a path separator, and local CanvasKit requests return 404.
Owned test/compiler/browser processes were stopped; other chats' processes were
untouched. A temporary VM wrapper also cannot execute the web-only PDF imports
(dart:js_interop is unavailable). The wrapper is removed, no SDK workaround is
committed, and no local Chrome/VM product pass is claimed. The coordinator will
use hosted Linux Chrome for the next RED/GREEN and remaining mobile diagnosis.

Hosted follow-up at integrated head 767b8b5 (job 118188092427): desktop completion
now passes. Mobile reports the correct /learn/course/second route, one matching
content widget and zero sheets, yet the binding still fails the test. Capture and
print every pending framework exception after those unchanged assertions and
require the collected list to be empty, so diagnostics cannot suppress a failure.
No production change is made without the exception evidence.
