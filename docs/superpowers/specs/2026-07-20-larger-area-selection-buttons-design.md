# Larger Area Selection Buttons

## Goal

Make the seven `AREA 1` through `AREA 7` buttons on the admin area-selection
screen substantially larger and easier to scan and tap, without changing the
picker workflow or enlarging unrelated controls.

## Design

- Increase the desktop area grid maximum width from `500px` to `720px`.
- Increase the desktop grid gap from `12px` to `16px`.
- Give each area button a minimum height of `100px`.
- Increase desktop button padding to `28px 20px` and label size to `18px`.
- Preserve the existing four-column desktop layout, producing four buttons on
  the first row and three on the second.
- Preserve three columns on tablet and two columns on small phones.
- On tablet, keep buttons comfortably large with at least `76px` height,
  `20px 12px` padding, and `16px` labels.
- Do not modify HTML, JavaScript, authentication, area-selection behavior, or
  the logout button.

## Verification

- Confirm the area grid and button sizing declarations are present in
  `css/admin.css`.
- Open `admin.html` at desktop width and verify the buttons are visibly larger,
  remain aligned, and do not overflow.
- Check a phone-sized viewport and verify the two-column layout remains within
  the page and labels remain readable.
- Confirm only the intended CSS and this design document are changed; preserve
  the user's existing `package-lock.json` modification.
