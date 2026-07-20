# Larger Area Selection Buttons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the seven admin area-selection buttons substantially larger on desktop while preserving usable tablet and phone layouts.

**Architecture:** This is a CSS-only presentation change. A Node built-in test will assert the exact desktop and tablet sizing contract before `css/admin.css` is updated, and browser verification will confirm the rendered layout at desktop and phone viewport sizes.

**Tech Stack:** CSS3, Node.js built-in test runner, static HTML, browser visual inspection

## Global Constraints

- Modify only the seven `.area-btn` controls and their `.area-grid` layout.
- Keep the desktop grid at four columns with a `720px` maximum width.
- Desktop buttons use at least `100px` height, `28px 20px` padding, and `18px` labels.
- Tablet keeps three columns with at least `76px` height, `20px 12px` padding, and `16px` labels.
- Small phones keep the existing two-column layout.
- Do not modify HTML, JavaScript, authentication, area-selection behavior, or the logout button.
- Preserve the user's existing `package-lock.json` modification.

---

### Task 1: Responsive Area Button Sizing

**Files:**
- Create: `tests/area-picker-css.test.mjs`
- Modify: `css/admin.css:149-172`
- Modify: `css/admin.css:497-505`

**Interfaces:**
- Consumes: `.area-grid` and `.area-btn` selectors rendered by `admin.html`.
- Produces: A responsive CSS sizing contract verified by Node's built-in test runner.

- [ ] **Step 1: Write the failing CSS contract test**

```javascript
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const css = await readFile(new URL("../css/admin.css", import.meta.url), "utf8");

test("desktop area-selection buttons use the approved larger sizing", () => {
    assert.match(css, /\.area-grid\s*\{[^}]*gap:\s*16px;[^}]*max-width:\s*720px;/s);
    assert.match(css, /\.area-btn\s*\{[^}]*min-height:\s*100px;[^}]*padding:\s*28px 20px;[^}]*font-size:\s*18px;/s);
});

test("tablet area-selection buttons remain large and responsive", () => {
    assert.match(
        css,
        /@media \(max-width:\s*768px\)[\s\S]*?\.area-btn\s*\{[^}]*min-height:\s*76px;[^}]*padding:\s*20px 12px;[^}]*font-size:\s*16px;/s
    );
    assert.match(
        css,
        /@media \(max-width:\s*480px\)[\s\S]*?\.area-grid\s*\{[^}]*grid-template-columns:\s*repeat\(2,\s*1fr\);/s
    );
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
node --test tests/area-picker-css.test.mjs
```

Expected: two tests fail because the current grid is `500px` wide with a `12px` gap and the buttons do not have the approved minimum heights, padding, or font sizes.

- [ ] **Step 3: Implement the minimal desktop CSS**

Update the base selectors in `css/admin.css` to:

```css
.area-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    max-width: 720px;
    width: 100%;
}

.area-btn {
    background: var(--color-surface);
    border: 2px solid var(--color-border);
    border-radius: var(--radius-lg);
    min-height: 100px;
    padding: 28px 20px;
    font-size: 18px;
    font-weight: 700;
    color: var(--color-text);
    transition: all 0.2s;
    text-align: center;
}
```

- [ ] **Step 4: Implement the minimal tablet override**

Update the `.area-btn` rule inside `@media (max-width: 768px)` to:

```css
.area-btn {
    min-height: 76px;
    padding: 20px 12px;
    font-size: 16px;
}
```

Do not alter the existing three-column tablet rule or two-column phone rule.

- [ ] **Step 5: Run the CSS contract test**

Run:

```bash
node --test tests/area-picker-css.test.mjs
```

Expected: `2` tests pass, `0` tests fail.

- [ ] **Step 6: Verify the rendered page**

Open `http://localhost:8080/admin.html` and inspect:

- Desktop viewport near `1440 × 900`: four buttons on the first row, three on the second, each visibly larger and without horizontal overflow.
- Phone viewport near `390 × 844`: two columns, readable labels, no page-level horizontal overflow.

- [ ] **Step 7: Review the final diff**

Run:

```bash
git -c safe.directory="E:/Nest/2026/07. Juli 2026/pre-odt" diff -- css/admin.css tests/area-picker-css.test.mjs
git -c safe.directory="E:/Nest/2026/07. Juli 2026/pre-odt" status --short
```

Expected: only `css/admin.css`, the new test, and the previously existing user modification to `package-lock.json` are uncommitted.

- [ ] **Step 8: Commit the implementation**

```bash
git add -- css/admin.css tests/area-picker-css.test.mjs
git commit -m "style: enlarge admin area selection buttons"
```
