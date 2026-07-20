# Quarterfinal Card Spacing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Increase the vertical separation between QF1-QF4 cards in the desktop multi-area view without changing other bracket rounds or fullscreen layouts.

**Architecture:** This is a targeted CSS-only layout change inside the existing `min-width: 769px` media query. A Node built-in contract test will isolate that desktop block and verify the quarterfinal-only flex distribution, responsive gap, and wrapper padding before the CSS is changed.

**Tech Stack:** CSS3 flexbox, Node.js built-in test runner, static HTML

## Global Constraints

- Apply the spacing change only to `.round-quarter` inside the desktop one-screen layout at widths of 769 px and above.
- Use `justify-content: space-between` and `gap: clamp(4px, 0.45vh, 6px)`.
- Set vertical padding to zero only on `.round-quarter .match-wrapper`.
- Keep semifinal, final, podium, mobile, native-fullscreen, and restored-fullscreen spacing unchanged.
- Do not change HTML, JavaScript, bracket data, connector drawing, card dimensions, or the seven-area grid.
- Preserve the existing unrelated `package-lock.json` modification.

---

### Task 1: Desktop Quarterfinal Spacing

**Files:**
- Create: `tests/quarterfinal-card-spacing.test.mjs`
- Modify: `css/public.css:2014-2020`

**Interfaces:**
- Consumes: `.round-quarter` and `.match-wrapper` elements rendered by `js/bracket-engine.js`.
- Produces: A desktop-only CSS contract that separates QF1-QF4 while preserving the existing global desktop wrapper spacing.

- [ ] **Step 1: Write the failing CSS contract test**

Create `tests/quarterfinal-card-spacing.test.mjs`:

```javascript
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const css = await readFile(new URL("../css/public.css", import.meta.url), "utf8");
const desktopStart = css.indexOf("@media (min-width: 769px) {");
const desktopEnd = css.indexOf(
    "@media (min-width: 1600px) and (min-height: 850px)",
    desktopStart
);
const desktopCss = desktopStart >= 0 && desktopEnd > desktopStart
    ? css.slice(desktopStart, desktopEnd)
    : "";

test("desktop quarterfinal cards use dedicated vertical spacing", () => {
    assert.notEqual(desktopCss, "");
    assert.match(
        desktopCss,
        /\.round-quarter\s*\{[^}]*justify-content:\s*space-between;[^}]*gap:\s*clamp\(4px,\s*0\.45vh,\s*6px\);[^}]*\}/s
    );
    assert.match(
        desktopCss,
        /\.round-quarter\s+\.match-wrapper\s*\{[^}]*padding:\s*0;[^}]*\}/s
    );
});

test("other desktop rounds retain the compact wrapper spacing", () => {
    assert.match(
        desktopCss,
        /\.match-wrapper\s*\{\s*min-height:\s*0;\s*padding:\s*1px 0;\s*\}/
    );
});
```

- [ ] **Step 2: Run the focused test and verify the red state**

Run in PowerShell:

```powershell
& 'C:\Program Files\nodejs\node.exe' --test tests/quarterfinal-card-spacing.test.mjs
```

Expected: one test passes and `desktop quarterfinal cards use dedicated vertical spacing` fails because the quarterfinal-only rules do not exist.

- [ ] **Step 3: Add the minimal desktop quarterfinal rules**

In `css/public.css`, immediately after the desktop `.bracket-round` block and before the existing `.match-wrapper` rule, add:

```css
    .round-quarter {
        justify-content: space-between;
        gap: clamp(4px, 0.45vh, 6px);
    }

    .round-quarter .match-wrapper { padding: 0; }
```

Keep the existing general rule unchanged:

```css
    .match-wrapper { min-height: 0; padding: 1px 0; }
```

- [ ] **Step 4: Run the focused test and verify the green state**

Run:

```powershell
& 'C:\Program Files\nodejs\node.exe' --test tests/quarterfinal-card-spacing.test.mjs
```

Expected: both tests pass.

- [ ] **Step 5: Run the full regression suite**

Run:

```powershell
& 'C:\Program Files\nodejs\node.exe' --no-warnings --experimental-default-type=module --experimental-vm-modules --test tests/fullscreen-area-state.test.mjs tests/fullscreen-area-integration.test.mjs tests/quarterfinal-card-spacing.test.mjs
```

Expected: all quarterfinal spacing and fullscreen persistence tests pass with zero failures.

- [ ] **Step 6: Verify the rendered layout**

At `http://localhost:8080/` with a 1920 x 990 viewport:

1. Confirm QF1-QF4 have clearly visible and consistent vertical separation in all seven area cards.
2. Confirm all seven areas and the champions summary remain visible in the single-screen grid.
3. Confirm SF, final, and podium cards retain their previous spacing.
4. Enter native fullscreen for one area and confirm its existing larger spacing is unchanged.
5. Refresh while focused on that area and confirm restored-fullscreen spacing is unchanged.

- [ ] **Step 7: Commit the implementation**

```powershell
git add -- tests/quarterfinal-card-spacing.test.mjs css/public.css
git commit -m "style: increase quarterfinal card spacing"
```

Expected: the commit includes only the new test and `css/public.css`; `package-lock.json` remains uncommitted.
