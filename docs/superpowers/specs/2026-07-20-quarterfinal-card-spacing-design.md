# Quarterfinal Card Spacing

## Goal

Increase the vertical distance between QF1, QF2, QF3, and QF4 cards on the
desktop multi-area monitoring page so the quarterfinal matches are easier to
distinguish while all seven area cards still fit in one viewport.

## Revision Rationale

The first implementation used `clamp(4px, 0.45vh, 6px)`. At the target
1920 x 990 viewport, that resolves to about 4.5 px. Because the previous
wrapper padding already created about 2 px between adjacent cards, the visible
increase was only about 2.5 px and the cards still appeared crowded.

## Scope

- Apply the spacing change only to the quarterfinal column (`.round-quarter`)
  inside the desktop one-screen layout at widths of 769 px and above.
- Keep the semifinal, final, podium, fullscreen, and restored-fullscreen
  layouts unchanged.
- Do not change bracket markup, match data, connector drawing, or JavaScript.

## Layout Behavior

Within the existing desktop media query:

- Change the quarterfinal column to distribute its four match wrappers with
  `justify-content: space-between`.
- Add a responsive minimum vertical `gap` of
  `clamp(10px, 1.2vh, 12px)` between quarterfinal match wrappers. This resolves
  to about 11.9 px at the target 1920 x 990 viewport.
- Remove the inherited 1 px vertical wrapper padding only for quarterfinal
  wrappers, so the explicit gap is the single source of spacing.
- Preserve the existing compact match-card dimensions and the outer bracket
  padding so the seven-area grid remains visible without increasing page
  height.

The gap may become larger when the quarterfinal column has unused vertical
space because `space-between` distributes that space between the four
wrappers. It must not reduce below the explicit responsive gap.

## Responsive Behavior

- Desktop multi-area view (`min-width: 769px`) receives the new QF spacing.
- Mobile and narrow layouts continue using their existing flow.
- Native fullscreen and restored fullscreen retain their existing larger card
  spacing rules and are not overridden by this change.

## Verification

- Add a CSS contract test that confirms the desktop media query contains a
  quarterfinal-only rule with `justify-content: space-between`, the responsive
  gap, and zero vertical wrapper padding.
- Confirm the test rejects the superseded 4-6 px gap so the visually
  insufficient spacing cannot return.
- Confirm the global desktop `.match-wrapper` rule remains unchanged so SF and
  final cards keep their current spacing.
- At the target 1920 x 990 viewport, confirm QF1-QF4 have visibly separated
  vertical gaps in every area and that all seven areas plus the summary remain
  in the one-screen grid.
- Enter native fullscreen and restored-fullscreen modes and confirm their
  spacing and layout remain unchanged.

## Non-Goals

- Increasing the width of the quarterfinal column.
- Changing horizontal spacing between bracket rounds.
- Resizing match text or cards.
- Changing the number or placement of area cards.
