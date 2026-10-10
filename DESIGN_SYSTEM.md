
# DESIGN_SYSTEM.md
# Acedra - UI/UX Design System

Document ID: CSA-DS-001
Version: 1.1
Status: Approved Documentation Baseline - Implementation and Release Gates Retained
Approval: Project owner, 2026-10-11; see docs/requirements/CSA-011-017-APPROVAL.md.
Review: CSA-014, 2026-10-11; proposed clarifications, no implementation sign-off
Project: Course Selling Application
Working Brand: Acedra
Primary Platform: Flutter Web
Future Platforms: Android and iOS
UI Framework: Flutter Material 3
Design Philosophy: Premium, Minimal, Accessible
Classification: Internal Design Documentation

---

# 1. PURPOSE

This document defines the visual, interaction,
responsive, and accessibility standards for
the Course Selling Application.

It is the authoritative design reference
for developers, UI/UX designers, QA engineers,
and AI coding agents.

The design system ensures:

- Consistent visual identity
- Professional student experience
- Excellent course readability
- Premium PDF reading experience
- Simple and trustworthy checkout
- Efficient admin workflows
- Responsive cross-device interfaces
- Consistent light and dark themes
- Accessibility and inclusive design
- Reusable Flutter UI components
- Maintainable design tokens
- Predictable interaction patterns

Every application screen must follow
this design system.

---

# 2. RELATED DOCUMENTS

The design system must remain consistent with:

- SRS.md
- PLAN.md
- AGENTS.md
- ARCHITECTURE.md
- DATABASE_DESIGN.md
- SECURITY.md
- Approved UI/UX layout specification
- Approved brand identity and logo assets

Document responsibilities:

SRS.md:
Defines required functionality.

ARCHITECTURE.md:
Defines technical implementation boundaries.

DESIGN_SYSTEM.md:
Defines appearance and interaction behavior.

AGENTS.md:
Defines implementation and review rules.

PLAN.md:
Defines development phases and priorities.

---

# 3. DESIGN PRINCIPLES

## 3.1 Simplicity

Interfaces must be easy to understand.

- Reduce unnecessary visual complexity.
- Use clear navigation.
- Show important information first.
- Avoid competing primary actions.
- Prefer familiar interaction patterns.

## 3.2 Consistency

The same component must behave
consistently throughout the application.

- Reuse design tokens.
- Reuse components.
- Preserve consistent spacing.
- Use consistent terminology.
- Use predictable interactions.

## 3.3 Readability First

The application is an educational platform.

Learning content must be comfortable
to read for extended periods.

Prioritize:

- Typography
- Contrast
- Line spacing
- Document clarity
- Reading width
- Zoom
- Focused reading layouts

## 3.4 Accessibility

Design for people with different:

- Visual abilities
- Motor abilities
- Reading preferences
- Screen sizes
- Input methods
- Assistive technologies

## 3.5 Trust and Transparency

Students must understand:

- Course prices
- Payment methods
- Payment status
- Course access status
- Refund information
- Content restrictions

Never use misleading payment interfaces.

## 3.6 Progressive Disclosure

Show essential information first.

Reveal advanced controls when required.

Example:

PDF Reader:
Show navigation and zoom controls.

Advanced Settings:
Place secondary options in a menu.

## 3.7 Security Without Poor UX

Security controls must not introduce
unnecessary learning difficulties.

No false promises about screenshot
or recording prevention.

Content protection must work alongside
readability and accessibility.

---

# 4. BRAND IDENTITY

## 4.1 Brand Foundation

Working Brand Name:
Acedra

Brand Personality:

- Modern
- Premium
- Intelligent
- Trustworthy
- Calm
- Professional
- Educational
- Minimal

Brand Positioning:

A premium digital learning environment
focused on confident, comfortable learning.

## 4.2 Brand Usage

The application should use:

- Consistent logo placement
- Recognizable brand colors
- Professional typography
- Minimal visual decoration
- Clear page hierarchy
- Consistent illustrations and icons

The final logo, trademark clearance,
and brand guidelines require approval.

The earlier CourseFlow prototype name
is a demonstration placeholder.

## 4.3 Logo Rules

- Use approved logo assets only.
- Preserve logo proportions.
- Do not stretch or distort the logo.
- Maintain adequate clear space.
- Provide light and dark variants.
- Use a compact logo for small screens.
- Provide suitable accessible naming.
- Avoid placing the logo on backgrounds
  that reduce visibility.

Recommended assets:

- Full horizontal logo
- Compact brand mark
- Light-mode variant
- Dark-mode variant
- Browser favicon
- Application icon

Do not create unofficial logo variations
without design approval.

---

# 5. DESIGN TOKEN ARCHITECTURE

All visual properties should use
centralized design tokens.

Token categories:

1. Color tokens
2. Typography tokens
3. Spacing tokens
4. Radius tokens
5. Elevation tokens
6. Border tokens
7. Icon tokens
8. Motion tokens
9. Responsive tokens
10. Component-specific tokens

Avoid hardcoded values inside
individual feature widgets.

Tokens should use semantic naming.

Preferred:

colorScheme.primary
appColors.surfaceSecondary
appSpacing.md
appRadius.card

Avoid:

Color(0xFF5146E5) in every widget
randomPadding = 19
arbitraryCardRadius = 17

Raw values belong in the centralized
design token definitions.

---

# 6. COLOR SYSTEM

## 6.1 Primary Brand Palette

The initial palette is based on the
existing application layout prototype.

Primary Light:
#5146E5

Primary Dark:
#A7A8FF

Brand Direction:
Indigo with soft violet accents.

Use brand colors for:

- Primary actions
- Selected navigation
- Active tabs
- Progress indicators
- Interactive highlights
- Important emphasis

Avoid excessive primary-colored surfaces.

---

# 7. LIGHT THEME TOKENS

## 7.1 Light Color Palette

| Token | Hex Value |
|-------|-----------|
| background | #F6F8FC |
| surface | #FFFFFF |
| surfaceSecondary | #EEF2FA |
| surfaceTertiary | #E6EAF6 |
| textPrimary | #101828 |
| textSecondary | #5B667A |
| border | #E0E6F0 |
| primary | #5146E5 |
| onPrimary | #FFFFFF |
| primaryContainer | #EEECFF |
| onPrimaryContainer | #473CC2 |
| success | #147D43 |
| successContainer | #E9F8EF |
| warning | #A85B00 |
| warningContainer | #FFF4DF |
| error | #B42318 |
| errorContainer | #FFF0EF |
| focusRing | #F59E0B |

## 7.2 Light Theme Rules

- Use background for main page canvases.
- Use surface for cards and form containers.
- Use primary for key actions.
- Use textPrimary for headings and body text.
- Use textSecondary for supporting information.
- Use borders for subtle separation.
- Use semantic colors for real status meanings.

Do not use success colors merely
for decorative emphasis.

---

# 8. DARK THEME TOKENS

## 8.1 Dark Color Palette

| Token | Hex Value |
|-------|-----------|
| background | #0B1020 |
| surface | #151D30 |
| surfaceSecondary | #202B41 |
| surfaceTertiary | #29374F |
| textPrimary | #F5F7FE |
| textSecondary | #B0BED4 |
| border | #334158 |
| primary | #A7A8FF |
| onPrimary | #11152C |
| primaryContainer | #28284D |
| onPrimaryContainer | #D1D1FF |
| success | #83E8AE |
| successContainer | #183C2F |
| warning | #F4BF70 |
| warningContainer | #4A371B |
| error | #FF9F9B |
| errorContainer | #4F282F |
| focusRing | #F9C46B |

## 8.2 Dark Theme Rules

- Use dark navy surfaces instead of pure black.
- Keep text highly readable.
- Avoid unnecessarily bright surfaces.
- Keep borders subtle but distinguishable.
- Use appropriate dark-mode image overlays.
- Preserve visual hierarchy.

Do not automatically invert images,
course thumbnails, or PDF document pages.

The PDF reader's surrounding interface
may be dark while the PDF itself
retains its original page colors.

---

# 9. SEMANTIC COLOR RULES

Colors must describe meaning,
not arbitrary visual decoration.

## Success

Examples:

- Payment approved
- Course completed
- Upload successful
- Verified enrollment

## Warning

Examples:

- Payment pending
- Bank receipt under review
- Session nearing expiration
- Action requires attention

## Error

Examples:

- Payment rejected
- Upload failed
- Invalid field
- Unauthorized operation

## Neutral

Examples:

- Draft course
- Not purchased
- Archived record
- Inactive feature

Status communication must include
clear text or icons.

Never communicate status by color alone.

Color combinations must be tested
against accessibility contrast requirements.

---

# 10. TYPOGRAPHY SYSTEM

## 10.1 Font Family

Primary Latin Font:
Inter

Fallback:
System sans-serif fonts

Potential multilingual support:

- Noto Sans Sinhala
- Noto Sans Tamil
- Appropriate system font fallbacks

Font assets must be used under
their applicable licenses.

Do not assume a font includes every
required language character.

## 10.2 Font Weights

Regular: 400
Medium: 500
SemiBold: 600
Bold: 700

Avoid excessive font-weight variations.

## 10.3 Typography Scale

| Style | Size | Weight | Line Height |
|-------|------|--------|-------------|
| Display | 40 | 700 | 1.15 |
| H1 | 32 | 700 | 1.20 |
| H2 | 26 | 700 | 1.25 |
| H3 | 22 | 600 | 1.30 |
| H4 | 18 | 600 | 1.35 |
| Body Large | 18 | 400 | 1.55 |
| Body | 16 | 400 | 1.50 |
| Body Small | 14 | 400 | 1.50 |
| Label | 14 | 600 | 1.40 |
| Caption | 12 | 400 | 1.45 |

All size values are logical pixels.

Proposed Flutter mapping: Display = displayLarge; H1 = headlineLarge;
H2 = headlineMedium; H3 = headlineSmall; H4 = titleLarge;
Body Large = bodyLarge; Body = bodyMedium; Body Small = bodySmall;
Label = labelLarge; Caption = labelSmall.
The table above defines the intended values; current Dart styles are
not evidence that these values are approved or correctly implemented.

Small text must not carry essential
information when larger text is feasible.

## 10.4 Mobile Heading Adaptation

Suggested adjustments:

Desktop H1:
32-40

Mobile H1:
26-30

Desktop H2:
26-28

Mobile H2:
22-24

Choose typography using
available layout constraints.

## 10.5 Reading Typography

For ordinary text lessons:

- Body size: 16-19
- Comfortable line height: 1.5-1.7
- Clear paragraph spacing
- Readable heading structure
- Limited line width

Recommended reading width:
Approximately 60-75 characters per line,
where language and content allow.

PDF pages must be rendered faithfully
with user-controlled zoom.

## 10.6 Text Scaling

Text must support increased scaling
without clipping important information.

Do not use fixed-height containers
that cut off enlarged text.

Test key interfaces at increased
browser and accessibility text sizes.

---

# 11. SPACING SYSTEM

Use a consistent 4-pixel spacing grid.

## 11.1 Spacing Scale

| Token | Value |
|-------|-------|
| space0 | 0 |
| space1 | 4 |
| space2 | 8 |
| space3 | 12 |
| space4 | 16 |
| space5 | 20 |
| space6 | 24 |
| space8 | 32 |
| space10 | 40 |
| space12 | 48 |
| space16 | 64 |

All values are logical pixels.

## 11.2 Usage Guidelines

Between icon and label:
8

Between related form fields:
16

Between unrelated form sections:
24-32

Card internal padding:
16-24

Page section spacing:
32-48

Large desktop section spacing:
48-64

Avoid arbitrary spacing values
without a documented reason.

---

# 12. CORNER RADIUS SYSTEM

| Component | Radius |
|-----------|--------|
| Small controls | 8 |
| Buttons | 12 |
| Inputs | 12 |
| Cards | 18 |
| Panels | 18 |
| Dialogs | 20 |
| Large feature containers | 24 |
| Pills | 999 |

Use fewer radius variations
for visual consistency.

Never apply oversized rounding
to every element automatically.

---

# 13. ELEVATION AND SHADOW SYSTEM

Use borders and surface differences
for most containers.

Elevation levels:

Level 0:
Flat page content.

Level 1:
Standard card or raised surface.

Level 2:
Floating menu or sticky interface.

Level 3:
Dialog, popup, or modal.

Rules:

- Avoid heavy shadows on every card.
- Use subtle shadows in light mode.
- Use surface separation in dark mode.
- Do not rely only on shadows for boundaries.
- Maintain consistent overlay hierarchy.

---

# 14. ICONOGRAPHY

Preferred approach:
Use Flutter's standard Material icons
or a single approved consistent icon family.

## 14.1 Icon Sizes

Small:
16

Standard:
20

Navigation:
24

Large:
28-32

Decorative:
40+

## 14.2 Icon Rules

- Use consistent stroke and visual weight.
- Provide tooltips for icon-only actions.
- Include accessible labels.
- Avoid ambiguous icons without text.
- Avoid mixing unrelated icon styles.
- Use icons to support meaning, not replace it.

Examples:

Home:
Home icon

Explore:
Search/compass icon

My Courses:
Book icon

Payments:
Receipt icon

Settings:
Settings icon

Admin:
Dashboard icon

---

# 15. RESPONSIVE DESIGN SYSTEM

## 15.1 Breakpoints

| Layout | Available Width |
|--------|-----------------|
| Compact | 0-599 |
| Medium | 600-1023 |
| Expanded | 1024+ |

These are proposed logical-pixel
layout classes.

Reference widths:

Mobile: 390
Tablet: 768
Desktop: 1440

Minimum-width testing should include
320 logical pixels.

Breakpoints depend on available width,
not device brand or device category.

Use half-open intervals: Compact width < 600, Medium 600 <= width < 1024,
Expanded width >= 1024. Evaluate the actual available content constraints
after shell navigation takes space. A sidebar must collapse when the
remaining content cannot fit its controls, including at enlarged text sizes.

## 15.2 Page Margins

Compact:
16

Medium:
24

Expanded:
24-32

## 15.3 Content Width

Recommended maximum main content width:
1280

Reading content:
Use a narrower comfortable measure.

PDF reader:
Use available width according
to page aspect ratio and zoom.

## 15.4 Layout Columns

Mobile:
1 primary column

Tablet:
1-2 columns depending on content

Desktop:
2-4 content columns when suitable

Never force multiple columns if doing so
makes text or controls too narrow.

## 15.5 Flutter Responsive Rules

Use:

- LayoutBuilder
- MediaQuery.sizeOf where appropriate
- Flexible
- Expanded
- ConstrainedBox
- Wrap
- Sliver widgets for large scrollable lists

Avoid fixed pixel widths that
break intermediate viewports.

Check text scaling and browser zoom.

---

# 16. APPLICATION LAYOUT SHELLS

The platform will use these main shells:

1. PublicShell
2. AuthShell
3. StudentShell
4. CheckoutShell
5. LearningShell
6. ReaderShell
7. AdminShell

Shells share design tokens
but may have different navigation patterns.

---

# 17. PUBLIC LAYOUT

Purpose:
Course discovery and conversion.

Desktop layout:

- Top navigation bar
- Brand logo
- Course search
- Main navigation
- Login/register actions
- Content container
- Footer

Mobile layout:

- Compact brand header
- Search access
- Menu action
- Single-column content
- Responsive course cards

Navigation must remain accessible
without horizontal overflow.

---

# 18. AUTHENTICATION LAYOUT

Screens:

- Login
- Registration
- Email verification
- Forgot password
- Reset password

Desktop:

Centered authentication card.

Optional supporting branding panel
only when it improves clarity.

Mobile:

Full-width form with safe margins.

Rules:

- Visible field labels
- Clear validation
- Accessible password visibility control
- Obvious submit button
- Clear login/register navigation
- No deceptive account creation flow

Do not expose account existence
through sensitive error messages.

---

# 19. STUDENT NAVIGATION LAYOUT

## Desktop

Recommended:

- Header
- Sidebar or navigation rail
- Main content region
- Optional contextual actions

## Mobile

Recommended bottom navigation:

1. Home
2. Explore
3. My Courses
4. Profile

Secondary actions belong in
the relevant screens or menus.

Rules:

- Show active navigation clearly.
- Preserve browser back behavior.
- Support keyboard navigation.
- Use readable navigation labels.
- Do not overcrowd bottom navigation.

---

# 20. ADMIN NAVIGATION LAYOUT

## Desktop

Recommended sidebar width:
248

Main sections:

- Dashboard
- Courses
- Students
- Payments
- Enrollments
- Reports
- Settings

## Tablet

Use a collapsed sidebar or rail
when space allows.

## Mobile

Use a navigation drawer.

Avoid displaying a permanently expanded
sidebar on narrow screens.

Admin navigation must respect
the user's authorized permissions.

Hiding an item does not replace
backend permission checks.

---

# 21. BUTTON COMPONENTS

## 21.1 Button Variants

Primary Button:
Main action on a screen.

Secondary Button:
Supporting action.

Outlined Button:
Alternative non-primary action.

Text Button:
Low-emphasis action.

Destructive Button:
Deletion, revocation, or rejection.

Icon Button:
Compact toolbar action.

## 21.2 Recommended Sizes

| Size | Minimum Height |
|------|----------------|
| Small | 36 |
| Medium | 44 |
| Large | 48 |

For touch-first critical actions,
prefer 44 or larger.

These heights describe visual sizing, not guaranteed pointer target bounds.
Use at least a 44 x 44 logical-pixel hit region for primary touch actions,
including small confirmation buttons; allow labels to wrap or grow.

## 21.3 Button States

Every button must support:

- Default
- Hover, where applicable
- Focus
- Pressed
- Disabled
- Loading

## 21.4 Button Rules

- Use clear action labels.
- Show progress during submission.
- Prevent accidental repeated submits.
- Do not use multiple competing primary CTAs.
- Use confirmation for destructive actions.
- Maintain visible keyboard focus.

UI prevention of repeated clicks
does not replace backend idempotency.

---

# 22. INPUT AND FORM COMPONENTS

Approved input types:

- Text field
- Email field
- Password field
- Number field
- Search field
- Dropdown/select
- Checkbox
- Radio group
- Toggle
- Text area
- File upload
- Date selection, when needed

## 22.1 Input Rules

- Visible label required.
- Placeholder is not a replacement for label.
- Show required information.
- Display relevant helper text.
- Display validation near affected fields.
- Preserve user input after recoverable errors.
- Use appropriate keyboard/input types.
- Avoid unnecessary mandatory fields.

## 22.2 Validation States

- Idle
- Focused
- Valid
- Invalid
- Disabled
- Submitting

## 22.3 Error Messages

Poor:
Invalid input.

Preferred:
Enter a valid email address.

Poor:
Payment failed.

Preferred:
We could not confirm your payment.
Check the status before trying again.

Errors must be clear without exposing
sensitive internal details.

---

# 23. CARD COMPONENTS

Core card variants:

- CourseCard
- FeaturedCourseCard
- EnrollmentCard
- ContinueLearningCard
- StatCard
- PaymentCard
- NotificationCard
- AdminSummaryCard

## 23.1 Course Card

Required elements:

- Thumbnail
- Course title
- Price or enrollment state
- Relevant course metadata
- Clear action

Optional elements:

- Instructor name
- Duration
- Course level
- Genuine rating
- Discount badge, when applicable

## 23.2 Course Card Rules

- Consistent image aspect ratios.
- Do not stretch thumbnails.
- Truncate titles carefully.
- Preserve important price information.
- Avoid excessive badges.
- Use one clear main action.
- Provide accessible card navigation.

Recommended thumbnail ratio:
16:9

---

# 24. COURSE MARKETPLACE DESIGN

The marketplace must prioritize
discovery and clear decision-making.

Sections may include:

- Welcome/hero section
- Featured courses
- Categories
- Course grid
- Search and filtering
- Course recommendations
- Footer

## Desktop

- Responsive course grid
- 3 columns typically
- 4 columns only if readable
- Sidebar or horizontal filters as appropriate

## Tablet

- Typically 2 columns

## Mobile

- Single-column cards
- Compact filters
- Search at a prominent location

## Marketplace States

- Loading
- Empty catalog
- No search results
- Network failure
- Course unavailable
- Already enrolled

Do not fabricate ratings or scarcity signals.

---

# 25. COURSE DETAIL PAGE

The course detail page is a
business-critical conversion screen.

## 25.1 Layout

Desktop:

Left:
- Course title
- Description
- Learning outcomes
- Curriculum
- Instructor information
- Course FAQ

Right:
- Course preview
- Price
- Purchase card
- Course summary
- Payment information

Mobile:

Stack course content into
one readable column.

## 25.2 Primary Actions

Unpurchased:
Buy Course

Purchased:
Continue Learning

Pending Bank Verification:
View Payment Status

Unavailable:
Show clear availability information

The frontend must display the
authoritative server-reported state.

## 25.3 Course Detail Rules

- Clear price and currency
- Transparent payment methods
- No misleading discounts
- No hidden charges
- Obvious curriculum preview
- Readable learning outcomes
- Clear ownership/enrollment state

---

# 26. CHECKOUT DESIGN SYSTEM

Checkout must be focused, trustworthy,
and easy to complete.

## 26.1 Layout

Desktop:

Left:
Payment method and relevant form.

Right:
Order summary.

Mobile:

Single-column checkout with
the total and action clearly visible.

## 26.2 Payment Methods

- Online payment gateway
- Bank transfer

Approved MVP: PayHere, LKR, one course per order (SRS 1.1 and CSA-004).
Show the approved lifetime-access and seven-day refund-request terms accurately
under CSA-006; a request is subject to review, not a guaranteed refund.

The selected method must
be visually and semantically clear.

## 26.3 Checkout Components

- OrderSummaryCard
- PaymentMethodSelector
- BankDetailsCard
- ReceiptUploadField
- PaymentStatusBanner
- CheckoutActionBar

## 26.4 Checkout Rules

- Show total payable amount.
- Show correct currency.
- Explain the payment method.
- Avoid unnecessary distractions.
- Handle failures without losing context.
- Never claim payment success before verification.

Bank transfer messaging:

Payment Submitted:
Awaiting Verification

Approved:
Payment Verified

Rejected:
Payment Requires Attention

A receipt submission must never
display "Course Unlocked" immediately.

---

# 27. BANK RECEIPT UPLOAD EXPERIENCE

Required interface elements:

- Order reference
- Bank name
- Account details
- Amount to transfer
- Currency
- Upload instructions
- File selection
- File preview
- Submission confirmation
- Review status

## 27.1 Upload States

- No file selected
- File selected
- File validating
- Uploading
- Upload successful
- Upload failed
- Receipt under review

## 27.2 Upload Design Rules

Approved receipt policy: JPEG, PNG or PDF; maximum 5 MiB (5,242,880 bytes).
Display these limits before file selection. Follow CSA-005 for same-order
resubmission when still payable; preserve prior rejected submission history.

- Explain accepted file formats.
- Explain maximum file size.
- Provide file-name feedback.
- Allow retry after failure.
- Do not expose private storage paths.
- Do not request unnecessary banking details.

The frontend may validate files
for immediate feedback.

Backend validation remains mandatory.

---

# 28. STUDENT LEARNING WORKSPACE

The learning workspace should be
calm, focused, and distraction-free.

## 28.1 Desktop Layout

Recommended:

Curriculum Sidebar:
280-320 width

Main Area:
Flexible lesson content

Header:
Course title and learning progress

Footer:
Previous/next lesson controls

## 28.2 Mobile Layout

- Compact course header
- Collapsible lesson navigation
- Full-width lesson content
- Clear previous/next actions
- No unnecessary global navigation

## 28.3 Learning Components

- CourseProgressBar
- CurriculumSection
- LessonListItem
- LessonTypeIcon
- LessonViewer
- LessonNavigationBar
- CompletionIndicator
- ResumeLearningCard

## 28.4 Lesson States

- Available
- Active
- Completed
- Locked
- Loading
- Failed
- Unavailable

Use accessible labels alongside icons.

## 28.5 Progress Indicators

Progress must use actual stored data.

Never visually mark a lesson as completed
without the applicable completion rule.

Use readable percentage labels
where relevant.

---

# 29. VIDEO PLAYER DESIGN

Required controls:

- Play/pause
- Seek
- Volume
- Full-screen
- Loading indicator
- Error feedback

Recommended:

- Playback speed
- Captions
- Resume playback
- Keyboard shortcuts where appropriate

## 29.1 Video Layout Rules

- Preserve video aspect ratio.
- Avoid distorted playback.
- Keep controls accessible.
- Prevent controls from obscuring captions.
- Provide a suitable loading state.
- Handle failed playback gracefully.

Recommended video aspect ratio:
16:9 where content supports it.

Do not display permanent media URLs
as unnecessary visible UI data.

---

# 30. PREMIUM PDF READER

The PDF reader is a priority module.

Its design must balance:

1. Readability
2. Accessibility
3. Performance
4. Practical content protection
5. Consistent navigation

## 30.1 Reader Layout

Desktop:

- Compact header
- Optional outline/sidebar
- Central document canvas
- Zoom/page navigation toolbar
- Optional reading progress

Mobile:

- Full-width document region
- Compact controls
- Collapsible outline
- Page navigation
- No unnecessary bottom navigation

## 30.2 Reader Components

- PdfReaderShell
- PdfToolbar
- PdfPageViewport
- PdfPageNavigator
- PdfZoomControls
- PdfOutlinePanel
- PdfBookmarkControl
- PdfLoadingState
- PdfErrorState
- PdfWatermarkLayer

## 30.3 Reader Controls

Required:

- Previous page
- Next page
- Current page
- Total page count
- Zoom in
- Zoom out
- Fit to width
- Full-screen or expanded view

Recommended:

- Search
- Bookmarks
- Document outline
- Remember last position

## 30.4 Reading Experience

- Keep the reading canvas uncluttered.
- Use readable page rendering.
- Preserve document aspect ratio.
- Avoid accidental horizontal scrolling.
- Support keyboard controls where possible.
- Make zoom easy on touch devices.
- Preserve progress when supported.
- Provide clear loading feedback.

## 30.5 Dark Mode

Dark mode changes:

- Reader header
- Toolbars
- Background canvas
- Navigation panels
- Controls

Do not automatically invert PDF pages.

Preserve original document colors
unless an approved reading transformation
is explicitly selected and tested.

## 30.6 Watermark Design

CSA-010 selects authenticated proxy delivery of private, server-watermarked
derivatives. A presentation-layer watermark may complement that delivery;
it does not replace the approved server watermark. Appearance and disclosed
personal information remain subject to the approved privacy/security review.
Approved CSA-010 text: "Licensed to <display name> - <opaque license ID>"
on every page, derived from trusted identity. Exclude email, phone, NIC and
bank information; disclose its purpose before first reading.

Watermarks should:

- Be visible but subtle.
- Avoid obscuring important text.
- Use limited personal information.
- Remain reasonably traceable.
- Be disclosed to the student.

A UI-rendered watermark alone
does not prevent extracting PDF bytes.

## 30.7 Content Protection UX

Allowed deterrents may include:

- No exposed download control
- No exposed print control
- Controlled access interface
- Student-specific watermark display
- Clear account access messaging

Important:

Flutter Web cannot guarantee prevention
of screenshots, screen recordings,
or all forms of copying.

Do not create misleading security messages.

Do not unnecessarily remove accessibility
features to discourage copying.

Protected document authorization and
delivery are backend responsibilities.

---

# 31. ADMIN DASHBOARD DESIGN

Admin interfaces must prioritize:

- Clarity
- Data accuracy
- Fast task completion
- Operational visibility
- Safe destructive actions

## 31.1 Dashboard Sections

- Summary statistics
- Recent transactions
- Pending approvals
- Course performance
- Recent enrollments
- Important alerts

## 31.2 Statistics Cards

Each card should contain:

- Clear title
- Primary value
- Unit/currency where appropriate
- Optional comparison
- Optional supporting description

Do not display fabricated analytics.

## 31.3 Admin Tables

Required capabilities where applicable:

- Search
- Filter
- Sort
- Pagination
- Status labels
- Row actions
- Loading states
- Empty states

On narrow screens:

Use structured cards or
appropriate overflow handling.

Critical actions must remain reachable.

---

# 32. BANK TRANSFER ADMIN REVIEW

The bank receipt review interface
is a high-priority financial workflow.

## 32.1 Desktop Layout

Recommended:

Left:
Pending payment queue.

Center:
Receipt preview.

Right or lower detail area:
Order and payment information.

Bottom:
Review actions.

## 32.2 Required Information

- Order reference
- Student identifier
- Course purchased
- Expected amount
- Currency
- Submitted reference
- Receipt document
- Submission time
- Current status
- Review history, where relevant

## 32.3 Review Actions

Available actions:

- Approve
- Reject
- Request clarification, if supported
- Open transaction details

## 32.4 Approval Safety

CSA-003/005 require an authorized independent finance reviewer and prohibit
own-purchase approval, including for super admins. Production finance actions
require MFA. Show only permitted case details, and keep internal bank evidence
and reviewer notes out of student-facing rejection/status messages.

Before approval:

- Reviewer must verify actual bank credit.
- Amount and reference must be checked.
- Reviewer must understand the consequence.
- High-impact approval must receive confirmation.

Approval must not happen automatically
because the user opened the receipt.

## 32.5 Rejection UX

Rejection should require a reason.

Possible reason categories:

- Payment not found
- Amount mismatch
- Unreadable receipt
- Duplicate submission
- Incorrect transaction details
- Other verified reason

Show clear information without
exposing unnecessary financial data.

## 32.6 Review States

- Pending
- Under Review
- Approved
- Rejected
- Already Finalized
- Verification Error

Concurrent review conflicts must
display a clear error and refresh path.

---

# 33. MODALS, DIALOGS, AND BOTTOM SHEETS

## 33.1 Dialog Usage

Use dialogs for:

- Destructive confirmations
- Important irreversible actions
- Critical decisions
- Short focused interactions

Do not use dialogs for long workflows
that deserve their own page.

## 33.2 Dialog Rules

- Clear title
- Concise explanation
- Primary action
- Safe cancellation option
- Visible focus
- Keyboard support
- Accessible dismissal behavior

## 33.3 Mobile Bottom Sheets

Use for:

- Filters
- Lesson navigation
- Secondary options
- Contextual actions

Avoid bottom sheets that exceed
usable screen space without scrolling.

---

# 34. NOTIFICATION AND FEEDBACK COMPONENTS

Approved feedback patterns:

- Toast/snackbar
- Inline success message
- Inline error message
- Status banner
- Confirmation dialog
- Progress indicator

## 34.1 Toasts

Use for short confirmations.

Examples:

"Profile updated."

"Bookmark saved."

Do not rely on disappearing toasts
as the only communication for a
critical financial or authorization result.

## 34.2 Financial Feedback

Important payment status must remain
visible in the relevant screen.

Examples:

"Payment is under review."

"Payment verified. Course access is active."

"Receipt rejected. Review the reason below."

## 34.3 Notification Accessibility

Use semantic announcements where supported.

Ensure messages remain understandable
without color or animation.

---

# 35. LOADING, EMPTY, AND ERROR STATES

Every important screen must define
its complete state behavior.

## 35.1 Loading

- Skeleton placeholders where appropriate
- Progress indicators
- Accessible loading labels
- No misleading completed state

## 35.2 Empty

Examples:

- No purchased courses
- No courses found
- No notifications
- No pending payments

Provide a useful next action
when one exists.

## 35.3 Errors

Examples:

- Internet connection unavailable
- Payment cannot be verified
- PDF cannot be loaded
- Access denied
- Session expired
- Course unavailable

Use friendly, actionable messages.

## 35.4 Access Denied

Use a clear access-denied interface.

Do not expose sensitive resource details
when the user lacks authorization.

Do not imply that hiding the content
in the UI is sufficient authorization.

---

# 36. INTERACTION AND MOTION

Motion should support comprehension,
not distract students.

## 36.1 Animation Duration

Fast:
100-150 ms

Standard:
150-250 ms

Emphasized:
250-350 ms

Actual duration may vary
based on interaction type.

## 36.2 Recommended Animations

- Button state transition
- Navigation selection
- Accordion expansion
- Dialog appearance
- Skeleton loading
- Controlled page transitions
- Progress updates

## 36.3 Motion Rules

- Avoid excessive animations.
- Avoid unnecessary parallax.
- Avoid distracting loops.
- Avoid motion that blocks navigation.
- Respect reduced-motion preferences.

Essential information must not depend
only on an animation.

---

# 37. ACCESSIBILITY STANDARD

Target:
WCAG 2.2 AA where applicable.

This remains a proposed target subject to DS-OPEN-009. SRS NFR-ACC-001
through 005 and 007 remain mandatory regardless of that decision.
Reference: [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/).

Actual conformance requires testing.

## 37.1 Text Contrast

Normal text:
Minimum 4.5:1

Large text:
Minimum 3:1

Non-text UI components:
Use applicable 3:1 contrast requirements.

Test actual foreground/background pairs.

Do not assume a token is accessible
in every possible combination.

The existing light focusRing and both border tokens are unsuitable as
the sole contrasting boundary on their default surface backgrounds.
Keep their palette values; pair them with an independently visible,
tested focus/control boundary. Decorative dividers may retain subtle borders.
Verify computed Material foregrounds, overlays and component states as well
as the raw token pairs; never infer accessibility from a palette table.

## 37.2 Interaction Targets

Preferred touch target:
44 x 44 logical pixels or larger.

WCAG 2.2 AA Target Size Minimum:
24 x 24 CSS pixels, subject to
the specification's exceptions.

## 37.3 Keyboard Accessibility

Support:

- Tab navigation
- Enter/Space activation
- Escape where appropriate
- Visible focus
- Logical focus order
- Accessible dialogs
- Keyboard-operable menus

## 37.4 Screen Reader Support

- Provide meaningful semantics.
- Use descriptive labels.
- Avoid redundant announcements.
- Use semantic headings where possible.
- Announce important state changes.
- Test Flutter Web accessibility behavior.

## 37.5 Form Accessibility

- Associate labels with inputs.
- Explain validation errors.
- Preserve keyboard focus appropriately.
- Make required fields understandable.
- Avoid error messages based only on color.

## 37.6 Content Accessibility

Where feasible:

- Video captions
- Text alternatives
- Accessible document structure
- Readable PDF zoom
- Keyboard navigation
- Text scaling
- Accessible lesson controls

If PDF protection conflicts with
accessibility requirements, evaluate
a suitable authorized alternative.

---

# 38. CONTENT DESIGN AND MICROCOPY

Interface language should be:

- Clear
- Professional
- Concise
- Human-readable
- Consistent
- Non-deceptive

## 38.1 Preferred Terminology

Use:
"My Courses"

Avoid:
"My Owned Educational Content Resources"

Use:
"Buy Course"

Avoid:
"Execute Purchase Operation"

Use:
"Payment Under Review"

Avoid:
"Payment Successfully Completed"
when the bank transfer is unverified.

Use:
"Continue Learning"

Avoid:
"Resume Educational Interaction Process"

## 38.2 Currency Display

- Show currency clearly.
- Use locale-appropriate formatting.
- Avoid ambiguous price labels.
- Display actual payable totals.
- Never present hidden fees.

## 38.3 Confirmation Language

Explain consequences before:

- Refund
- Enrollment revocation
- Course deletion
- Payment rejection
- Significant administrator actions

Avoid deceptive urgency or
unverified scarcity marketing.

---

# 39. IMAGE AND MEDIA GUIDELINES

## 39.1 Course Thumbnails

Recommended aspect ratio:
16:9

Requirements:

- High-quality imagery
- Consistent crop behavior
- Optimized file sizes
- Readable embedded text, if used
- Appropriate alternative descriptions

## 39.2 Images

Do not:

- Stretch images.
- Use irrelevant stock images.
- Use unlicensed assets.
- Upload unnecessarily large images.
- Place important text only inside images.

## 39.3 Video and PDF Previews

Preview areas must clearly indicate
whether content is playable,
locked, or available.

Never visually suggest access that
the student does not have.

---

# 40. LOCALIZATION READINESS

The design system should support
future multilingual interfaces.

Potential languages:

- English
- Sinhala
- Tamil

Actual supported languages must
be approved in the requirements.

## Localization Rules

- Avoid hardcoded text in widgets.
- Use localization resources.
- Support longer translated labels.
- Support appropriate font fallbacks.
- Format currency and dates by locale.
- Allow text to wrap without clipping.
- Avoid embedding UI text into images.

Use Flutter localization tooling
according to the approved architecture.

---

# 41. FLUTTER DESIGN SYSTEM IMPLEMENTATION

Recommended folders:

lib/
  app/
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
      app_elevation.dart
      app_breakpoints.dart
      app_theme_extensions.dart

  core/
    widgets/
      buttons/
      inputs/
      cards/
      dialogs/
      feedback/
      layout/
      navigation/

  features/
    marketplace/
      presentation/
        widgets/

    learning/
      presentation/
        widgets/

    pdf_reader/
      presentation/
        widgets/

    admin/
      presentation/
        widgets/

## 41.1 ThemeData

Use Flutter ThemeData and Material 3.

Centralize:

- ColorScheme
- TextTheme
- Button themes
- Input themes
- Card themes
- Dialog themes
- Navigation themes
- Tooltip themes

Use ThemeExtension for custom
application-specific semantic tokens.

Avoid multiple unrelated ThemeData
definitions throughout feature modules.

## 41.2 Color Token Mapping

Map design tokens into:

- Material ColorScheme
- Custom semantic ThemeExtensions

Do not assume a generated ColorScheme
will exactly reproduce the approved palette.

Explicit token overrides may be required.

## 41.3 Component Ownership

Global reusable components:
core/widgets

Feature-specific components:
features/<feature>/presentation/widgets

Avoid placing every widget
in the global shared folder.

## 41.4 Theme Persistence

Support:

- Light mode
- Dark mode
- Optional system theme

Persist the user's preference
using the approved state/storage strategy.

Theme changes must not affect
permissions, purchases, or learning data.

---

# 42. DESIGN COMPONENT INVENTORY

The initial component library should include:

Foundations:
- AppTheme
- AppColors
- AppTypography
- AppSpacing
- AppRadius
- AppBreakpoints

Layout:
- AppScaffold
- PublicShell
- StudentShell
- AdminShell
- LearningShell
- ReaderShell
- ResponsiveContainer

Navigation:
- AppHeader
- AppSidebar
- StudentBottomNavigation
- AppBreadcrumbs
- AppTabs

Actions:
- PrimaryButton
- SecondaryButton
- OutlineButton
- DestructiveButton
- AppIconButton

Forms:
- AppTextField
- AppPasswordField
- AppDropdown
- AppCheckbox
- AppRadioGroup
- AppFileUpload

Feedback:
- AppSnackbar
- AppDialog
- ErrorState
- EmptyState
- LoadingState
- StatusBadge

Course:
- CourseCard
- FeaturedCourseCard
- CurriculumAccordion
- EnrollmentCard
- CourseProgressIndicator

Learning:
- LessonListItem
- LessonNavigationBar
- VideoLessonViewer
- TextLessonViewer
- ImageLessonViewer

PDF:
- PdfReaderShell
- PdfToolbar
- PdfPageNavigator
- PdfOutlinePanel
- PdfZoomControls

Admin:
- AdminStatCard
- AdminDataTable
- PaymentReviewCard
- ReceiptPreviewPanel
- AuditTimeline

Do not implement all components upfront
if they are not needed by approved features.

Prefer incremental component development.

---

# 43. COMPONENT DOCUMENTATION

Every reusable component should document:

1. Component name
2. Intended purpose
3. Public properties
4. Visual variants
5. Interaction states
6. Accessibility behavior
7. Responsive behavior
8. Usage examples
9. Known limitations
10. Associated tests

Example:

Component:
PrimaryButton

Purpose:
Execute the main action on a screen.

States:
Default, hover, focus, pressed,
disabled, loading.

Requirements:
Accessible label, visible focus,
minimum target size, loading feedback.

Avoid multiple competing primary
buttons in the same decision region.

---

# 44. DESIGN TESTING STRATEGY

## 44.1 Responsive Testing

Test representative widths:

- 320
- 390
- 600
- 768
- 1024
- 1440

Also test intermediate widths
and increased text scaling.

## 44.2 Theme Testing

Every core screen must be checked in:

- Light mode
- Dark mode

Verify:

- Text contrast
- Icon contrast
- Card surfaces
- Form controls
- Dialogs
- Status components
- PDF toolbar readability

## 44.3 Widget Testing

Test reusable components for:

- Correct rendering
- Expected interaction
- Disabled states
- Loading states
- Validation states
- Theme support
- Accessibility semantics

## 44.4 Golden Tests

Use Flutter golden tests for
stable, important components/screens.

Prioritize:

- Course cards
- Authentication forms
- Course detail layouts
- Checkout panels
- Learning workspace
- PDF reader toolbar
- Admin receipt review

Golden tests complement, but do not
replace, functional or accessibility tests.

## 44.5 Manual UX Testing

Validate:

- Course discovery
- Purchase clarity
- Bank receipt submission
- Learning navigation
- PDF reading
- Admin payment review
- Keyboard navigation
- Error recovery

---

# 45. UI/UX ACCEPTANCE CHECKLIST

A screen is ready for review when:

- [ ] Uses approved design tokens.
- [ ] Uses approved typography.
- [ ] Follows consistent spacing.
- [ ] Supports light mode.
- [ ] Supports dark mode.
- [ ] Works at compact widths.
- [ ] Works at medium widths.
- [ ] Works at expanded widths.
- [ ] Handles long text.
- [ ] Supports relevant keyboard actions.
- [ ] Has accessible controls.
- [ ] Has clear loading behavior.
- [ ] Has an appropriate empty state.
- [ ] Has clear error behavior.
- [ ] Has correct user-facing terminology.
- [ ] Has no misleading payment status.
- [ ] Has no obvious layout overflow.
- [ ] Has relevant widget tests.
- [ ] Has been reviewed against requirements.

Critical student and payment workflows
require additional end-to-end verification.

---

# 46. DESIGN REVIEW PROCESS

Every important UI change should follow:

1. Review the related SRS requirements.
2. Review existing design tokens.
3. Identify reused components.
4. Create or update the design.
5. Review responsive behavior.
6. Review light and dark themes.
7. Review accessibility.
8. Implement Flutter components.
9. Test interactions.
10. Review differences from approved design.
11. Document approved changes.
12. Complete pull request review.

Avoid changing established styling
without a documented reason.

---

# 47. RULES FOR AI DESIGN AGENTS

All AI coding/design agents must:

- Read DESIGN_SYSTEM.md first.
- Read relevant requirements.
- Reuse existing components.
- Use semantic design tokens.
- Follow responsive layout rules.
- Support light and dark modes.
- Preserve accessibility.
- Validate interaction states.
- Avoid arbitrary styling decisions.
- Avoid unrelated visual redesigns.
- Avoid introducing new UI dependencies
  without justification.
- Report untested responsive behavior.
- Never claim visual testing was performed
  if it was not performed.

For significant redesigns:

Explain the reason, tradeoffs,
and impacted screens.

AI agents must not silently replace
the approved design system.

---

# 48. DESIGN ANTI-PATTERNS

The following are prohibited
unless explicitly approved.

- Random hardcoded colors
- Inconsistent spacing
- Excessive drop shadows
- Unnecessarily complex animations
- Multiple competing primary CTAs
- Low-contrast critical text
- Placeholder-only input labels
- Tiny unlabeled icon buttons
- Inaccessible custom controls
- Fixed-width layouts causing overflow
- Important information communicated
  exclusively by color
- Fake payment success states
- Misleading discount or urgency messages
- Fake screenshot-prevention claims
- Watermarks that obscure lesson content
- Unreviewed design-system changes
- Layout decisions based only
  on a specific phone model

---

# 49. DESIGN GOVERNANCE

DESIGN_SYSTEM.md is the
authoritative UI/UX reference.

Changes to foundational tokens require:

- Design rationale
- Impact assessment
- Light/dark review
- Accessibility checks
- Flutter implementation updates
- Relevant testing
- Documentation updates

For breaking design changes:

- Record affected components.
- Identify migration requirements.
- Update screenshots or golden baselines.
- Obtain appropriate review.

Design versions should be tracked
through Git.

---

# 50. OPEN DESIGN DECISIONS

DS-OPEN-001:
Approve final Acedra logo and identity.

DS-OPEN-002:
Approve primary and supporting colors.

DS-OPEN-003:
Confirm production typography and licenses.

DS-OPEN-004:
Approve student navigation patterns.

DS-OPEN-005:
Approve admin responsive behavior.

DS-OPEN-006:
Finalize PDF watermark appearance.

DS-OPEN-007:
Finalize reader toolbar controls.

DS-OPEN-008:
Confirm supported application languages.

DS-OPEN-009:
Approve required accessibility target.

DS-OPEN-010:
Approve production course imagery guidelines.

DS-OPEN-011:
Confirm the final brand terminology.

DS-OPEN-012:
Finalize component inventory for MVP.

All open decisions must be resolved
before their dependent production release.

---

# 51. DESIGN SYSTEM DEFINITION OF DONE

CSA-014 review completion is distinct from implementation completion:
the review supplies a refined proposal, source findings and acceptance
criteria. It does not check off the implementation checklist below.

The design system is considered
implementation-ready when:

- [ ] Brand direction is approved.
- [ ] Light palette is approved.
- [ ] Dark palette is approved.
- [ ] Typography is approved.
- [ ] Spacing tokens are defined.
- [ ] Radius tokens are defined.
- [ ] Responsive rules are documented.
- [ ] Navigation shells are specified.
- [ ] Core components are documented.
- [ ] Theme implementation is tested.
- [ ] Main responsive layouts are tested.
- [ ] Accessibility checks are completed.
- [ ] Course detail layout is validated.
- [ ] Learning workspace is validated.
- [ ] PDF reader layout is validated.
- [ ] Bank payment review layout is validated.
- [ ] Developers understand component ownership.
- [ ] Changes can be reviewed through GitHub.

## 51.1 Proposed MVP Verification Contract

The approved SRS 1.1 retains MUST requirements and defers SHOULD features.
This matrix does not promote captions, optional reader search/bookmarks,
video timestamp resume or theme persistence into mandatory MVP features.
Check optional features when implemented, or record them as deferred; assess
any impact on the proposed accessibility target before a conformance claim.

Use this matrix for implementation review after the relevant screens exist.
All rows require both light and dark themes. Capture the application revision,
browser/version, viewport, scale, fixture, observed result and evidence link.
Record failures and limitations explicitly. Synthetic finance and entitlement
fixtures must be identified; a UI fixture never proves backend authorization.

| ID | Scope and requirement | Observable acceptance | Evidence required |
| --- | --- | --- | --- |
| DS-AC-01 | Responsive shells; NFR-RESP-001 through 005 | At widths 320, 390, 599, 600, 768, 1023, 1024 and 1440, navigation, totals and primary actions remain reachable without page-wide horizontal overflow. A PDF at deliberate zoom or a wide data table may scroll within its own region. | Screenshots plus overflow assertions at boundaries; keyboard walkthrough of student/admin shells. |
| DS-AC-02 | Typography and layout; NFR-UX-001 through 009, NFR-ACC-003 | Documented token mapping is consistent. At 200% text scale and browser zoom, headings, price labels and form errors remain readable; at a 320 CSS-pixel content width the main workflow reflows. Test text scaling and browser zoom separately. | Token comparison, screenshots and browser checks; document any content-specific exception. |
| DS-AC-03 | Keyboard and focus; NFR-ACC-001, 002, 005 | Forward/reverse traversal follows the screen order. Menus, forms, media controls and dialogs work with keyboard input. Dialog dismissal returns focus to its opener; sticky headers/action bars leave the focused control visible. Shortcuts do not intercept typing in inputs. | Recorded keyboard sequence and focus assertions; accessible names/roles checked in the browser. |
| DS-AC-04 | Color and status; NFR-ACC-003, 004 | Actual text and control contrast meets section 37 for each supported state; pending, rejected, verified and locked states include words. | Measured foreground/background pairs for both themes; visual and semantics checks. |
| DS-AC-05 | Authentication/forms; NFR-ACC-002, NFR-UX-004 | Labels persist; password visibility has an action name and announced state. Invalid submission identifies fields and provides an actionable message. Recoverable errors preserve safe entered values. Password paste/autofill remains usable. | Invalid/valid/disabled fixtures; keyboard and screen reader checks. |
| DS-AC-06 | Feedback and motion; NFR-UX-006 through 008 | Loading preserves an accessible action name and announces busy state. Error/empty screens offer only valid next actions. Reduced motion uses static skeletons. Critical status remains visible after transient feedback disappears. | Loading/error/empty/offline fixtures, reduced-motion browser setting and announcements. |
| DS-AC-07 | Checkout and receipts; FR-PAY-001 through 014, FR-BANK-001 through 018 | Server state determines status. Return from gateway, upload success and pending review never imply paid access. Show amount/currency, upload limits and retry context. Concurrent finance decisions refresh authoritative state before another action; approval confirmation explains the entitlement consequence. | Synthetic pending/rejected/verified/unknown/conflict fixtures; trusted integration evidence separately required. |
| DS-AC-08 | Learning/PDF/video; FR-PDF-001 through 015, NFR-ACC-007 | Navigation/zoom/fit controls remain usable on mobile. Original PDF colors and aspect ratio remain intact in dark mode. Expired/revoked access yields recovery guidance without restricted previews; failed progress save is not presented as saved. Captions and document accessibility limitations are recorded. | Representative document/media fixtures and both-theme controls checks; authorization tested separately. |
| DS-AC-09 | Theme preference; NFR-UX-002, NFR-UX-010 (SHOULD) | User can select light/dark; proposed persistence survives reload using approved storage. If system mode is offered, it follows system changes without resetting the reading position. | Reload/system-switch browser evidence; no entitlement or payment data changes. |

These checks validate design behavior; they do not establish complete WCAG
conformance. The accessibility reviewer must assess applicable criteria across
complete supported user journeys and document unresolved limitations.

## 51.2 Implementation Handoff

The CSA-014 source review and open owner decisions are recorded in
[CSA-014 design review](docs/reviews/CSA-014-DESIGN-REVIEW.md).
Existing implementation mismatches must be assigned as bounded follow-up
work with ownership of shared theme/widget files before changing code.
Do not update golden baselines merely to accept an unexplained mismatch.

---

# 52. FINAL DESIGN DIRECTIVE

Acedra must provide a premium,
comfortable, modern learning experience.

Every screen must be:

- Simple
- Consistent
- Professional
- Accessible
- Responsive
- Trustworthy
- Easy to navigate
- Easy to maintain

Students should focus on learning,
not understanding complicated interfaces.

Administrators should manage operations
efficiently and accurately.

Course details should inspire confidence.

Checkout must be transparent.

The learning workspace must reduce distractions.

The PDF reader must prioritize readability.

Light and dark modes must feel cohesive.

All screens must follow centralized
tokens and reusable components.

DESIGN CONSISTENCY.
READABILITY FIRST.
ACCESSIBILITY BY DESIGN.
RESPONSIVE EVERYWHERE.
TRUSTWORTHY INTERACTIONS.
PREMIUM LEARNING EXPERIENCE.

END OF DESIGN SYSTEM DOCUMENT
