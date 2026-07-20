# Persist Restored Fullscreen Area

## Goal

When a user refreshes the public monitoring page while one area is in native
fullscreen, keep that same area as the only visible content and make it fill
the page viewport after reload. Native browser fullscreen may require another
user click because browsers do not allow automatic fullscreen entry after a
reload.

## Current Problem

The selected area ID is stored in `localStorage`, but the `fullscreenchange`
handler can replace it with an empty value when native fullscreen ends during
refresh. When restoration does occur, only the other area cards are hidden;
the site header and champions summary remain visible, so the restored area does
not fill the viewport.

## State Model

- `gfy_fullscreen_area` stores the selected area ID.
- A valid stored ID means restored-area mode is active, even when
  `document.fullscreenElement` is `null`.
- Native fullscreen state and persisted area selection are related but
  independent.
- Only an explicit press of the area's `EXIT` button clears the saved area.
- A browser-driven native fullscreen exit, including refresh or Escape, does
  not silently clear the selected area.

## Restore Behavior

After tournament data and area cards render:

1. Read the saved area ID inside a guarded `localStorage` access.
2. Validate that the ID belongs to a currently rendered area.
3. If valid, add a restored-area state class to the document body and the
   selected area.
4. Hide the public header, all other areas, and the champions summary.
5. Make the app, areas container, and selected area fill `100dvh`.
6. Keep the selected area's `EXIT` button visible.
7. Redraw the bracket after the restored layout is active so connector and
   card dimensions match the available viewport.

If the saved ID is invalid, remove it and render the normal monitoring page.

## Enter and Exit Behavior

- Pressing `FULL` saves the area ID before calling `requestFullscreen()`.
- Failure to enter native fullscreen leaves the restored-area selection
  available instead of discarding it.
- Pressing `EXIT` exits native fullscreen if necessary, clears
  `gfy_fullscreen_area`, removes restored-area classes, and renders all areas
  and the champions summary again.
- The `fullscreenchange` handler redraws the affected bracket but does not
  overwrite persisted selection during browser-driven fullscreen exit.

## Error Handling

- All storage access remains inside `try/catch`.
- Unsupported or denied native fullscreen shows the existing error feedback,
  while the selected area remains usable in restored-area mode.
- Missing DOM elements cause a safe return to normal layout.

## Verification

- Select an area and enter native fullscreen.
- Refresh the page.
- Confirm the same area is the only content view, fills the available viewport,
  and retains the `EXIT` button.
- Confirm the public header, other areas, and champions summary are hidden.
- Press `EXIT` and confirm normal multi-area monitoring returns and the stored
  selection is removed.
- Confirm an invalid stored area ID is cleared without a page error.
- Preserve existing unrelated changes, including `package-lock.json` and the
  untracked larger-area-button implementation plan.
