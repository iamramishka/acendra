# Student dashboard visual verification

2026-10-18, CODEX. Local offline release preview with synthetic repositories and
test identity; real dashboard widgets and router. This does not establish live
backend, authentication-provider, entitlement or payment acceptance.

| CSS viewport | Light | Dark |
| --- | --- | --- |
| 390 | [Mobile](mobile-light.png) | [Mobile](mobile-dark.png) |
| 768 | [Tablet](tablet-light.png) | [Tablet](tablet-dark.png) |
| 1440 | [Desktop](desktop-light.png) | [Desktop](desktop-dark.png) |

Additional scroll views:

- [Mobile benefits and four destinations](mobile-dark-lower.png)
- [Tablet two-column cards](tablet-dark-grid.png)
- [Desktop three-column cards](desktop-light-grid.png)
- [Desktop two-column learning highlights](desktop-dark-lower.png)

Screenshots include the QA wrapper and may show only part of the 900-pixel-high
iframe until the wrapper is scrolled. Desktop is visually scaled to fit the
review window without changing its 1440-pixel layout width. Hover tooltips can
appear in captured views. No visible overflow was found in the inspected views.

[Full verification record](../../tasks/CSA-DASH-001-PHASE6.md).
