# Persist Restored Fullscreen Area Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the selected fullscreen area across refreshes and restore it as the only content filling the page viewport until the user explicitly presses `EXIT`.

**Architecture:** Extract guarded local-storage operations and area validation into a small ES module with Node tests. Integrate that module into `index.html`, represent restored mode with a body class, and add focused CSS that makes the selected area fill `100dvh` while hiding unrelated page content.

**Tech Stack:** Vanilla JavaScript ES modules, CSS3, Node.js built-in test runner, Fullscreen API, browser localStorage

## Global Constraints

- `gfy_fullscreen_area` remains the storage key.
- A valid stored area remains selected when native fullscreen ends during refresh or Escape.
- Only an explicit press of the selected area's `EXIT` button clears the stored selection.
- Restored mode hides the public header, other areas, and champions summary.
- The restored area, app, and areas container fill `100dvh`.
- Browser-native fullscreen is never requested automatically after reload.
- Storage errors and invalid area IDs return safely to normal layout.
- Preserve the user's existing `package-lock.json` modification and unrelated untracked implementation plan.

---

### Task 1: Testable Fullscreen Selection State

**Files:**
- Create: `js/fullscreen-area-state.js`
- Create: `tests/fullscreen-area-state.test.mjs`

**Interfaces:**
- Consumes: A Storage-compatible object with `getItem`, `setItem`, and `removeItem`.
- Produces:
  - `FULLSCREEN_AREA_STORAGE_KEY: string`
  - `readFullscreenArea(storage): string | null`
  - `saveFullscreenArea(storage, areaId): boolean`
  - `clearFullscreenArea(storage): boolean`
  - `resolveFullscreenArea(savedAreaId, validAreaIds): string | null`

- [ ] **Step 1: Write the failing state tests**

Create `tests/fullscreen-area-state.test.mjs`:

```javascript
import test from "node:test";
import assert from "node:assert/strict";
import {
    FULLSCREEN_AREA_STORAGE_KEY,
    readFullscreenArea,
    saveFullscreenArea,
    clearFullscreenArea,
    resolveFullscreenArea
} from "../js/fullscreen-area-state.js";

function memoryStorage(initial = {}) {
    const values = new Map(Object.entries(initial));
    return {
        getItem(key) {
            return values.has(key) ? values.get(key) : null;
        },
        setItem(key, value) {
            values.set(key, String(value));
        },
        removeItem(key) {
            values.delete(key);
        }
    };
}

test("saves and reads the selected fullscreen area", () => {
    const storage = memoryStorage();
    assert.equal(saveFullscreenArea(storage, "area-1"), true);
    assert.equal(readFullscreenArea(storage), "area-1");
});

test("clears selection only when explicitly requested", () => {
    const storage = memoryStorage({ [FULLSCREEN_AREA_STORAGE_KEY]: "area-2" });
    assert.equal(readFullscreenArea(storage), "area-2");
    assert.equal(clearFullscreenArea(storage), true);
    assert.equal(readFullscreenArea(storage), null);
});

test("rejects missing or unknown saved areas", () => {
    assert.equal(resolveFullscreenArea(null, ["area-1"]), null);
    assert.equal(resolveFullscreenArea("", ["area-1"]), null);
    assert.equal(resolveFullscreenArea("missing", ["area-1"]), null);
    assert.equal(resolveFullscreenArea("area-1", ["area-1", "area-2"]), "area-1");
});

test("storage failures do not escape to the page", () => {
    const brokenStorage = {
        getItem() { throw new Error("blocked"); },
        setItem() { throw new Error("blocked"); },
        removeItem() { throw new Error("blocked"); }
    };
    assert.equal(readFullscreenArea(brokenStorage), null);
    assert.equal(saveFullscreenArea(brokenStorage, "area-1"), false);
    assert.equal(clearFullscreenArea(brokenStorage), false);
});
```

- [ ] **Step 2: Run the state tests and verify RED**

Run:

```bash
node --test tests/fullscreen-area-state.test.mjs
```

Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `js/fullscreen-area-state.js`.

- [ ] **Step 3: Implement the minimal state module**

Create `js/fullscreen-area-state.js`:

```javascript
export const FULLSCREEN_AREA_STORAGE_KEY = "gfy_fullscreen_area";

export function readFullscreenArea(storage) {
    try {
        return storage.getItem(FULLSCREEN_AREA_STORAGE_KEY) || null;
    } catch (_) {
        return null;
    }
}

export function saveFullscreenArea(storage, areaId) {
    try {
        storage.setItem(FULLSCREEN_AREA_STORAGE_KEY, areaId);
        return true;
    } catch (_) {
        return false;
    }
}

export function clearFullscreenArea(storage) {
    try {
        storage.removeItem(FULLSCREEN_AREA_STORAGE_KEY);
        return true;
    } catch (_) {
        return false;
    }
}

export function resolveFullscreenArea(savedAreaId, validAreaIds) {
    if (!savedAreaId || !validAreaIds.includes(savedAreaId)) return null;
    return savedAreaId;
}
```

- [ ] **Step 4: Run the state tests and verify GREEN**

Run:

```bash
node --test tests/fullscreen-area-state.test.mjs
```

Expected: `4` tests pass and `0` fail.

- [ ] **Step 5: Commit the tested state module**

```bash
git add -- js/fullscreen-area-state.js tests/fullscreen-area-state.test.mjs
git commit -m "test: add fullscreen area persistence state"
```

---

### Task 2: Restore Full-Viewport Area Layout

**Files:**
- Modify: `index.html:28-56`
- Modify: `index.html:492-552`
- Modify: `css/public.css:2243-2372`
- Create: `tests/fullscreen-area-integration.test.mjs`

**Interfaces:**
- Consumes: Task 1 exports and `.area-section[data-area-id]` elements produced by `renderAllBrackets()`.
- Produces:
  - Body class `area-fullscreen-restored-mode`
  - Area class `area-fullscreen-restored`
  - `restoreFullscreenArea(): void`
  - `exitAreaFullscreen(): Promise<void>`

- [ ] **Step 1: Write the failing integration contract**

Create `tests/fullscreen-area-integration.test.mjs`:

```javascript
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const html = await readFile(new URL("../index.html", import.meta.url), "utf8");
const css = await readFile(new URL("../css/public.css", import.meta.url), "utf8");

test("public page integrates explicit fullscreen selection persistence", () => {
    assert.match(html, /from "\.\/js\/fullscreen-area-state\.js"/);
    assert.match(html, /saveFullscreenArea\(localStorage,\s*areaId\)/);
    assert.match(html, /clearFullscreenArea\(localStorage\)/);
    assert.match(html, /document\.body\.classList\.add\("area-fullscreen-restored-mode"\)/);
    assert.match(html, /window\.exitAreaFullscreen\s*=\s*async function/);
});

test("fullscreenchange does not clear persisted selection", () => {
    const handler = html.match(/document\.addEventListener\("fullscreenchange",[\s\S]*?\n\s*\}\);/)?.[0] || "";
    assert.doesNotMatch(handler, /clearFullscreenArea|removeItem|setItem/);
    assert.match(handler, /restoreFullscreenArea\(\)/);
});

test("restored mode fills the viewport and hides unrelated content", () => {
    assert.match(css, /body\.area-fullscreen-restored-mode\s*\{[^}]*height:\s*100dvh;[^}]*overflow:\s*hidden;/s);
    assert.match(css, /\.area-fullscreen-restored-mode\s+\.public-header[^}]*\{[^}]*display:\s*none\s*!important;/s);
    assert.match(css, /\.area-fullscreen-restored-mode\s+\.area-summary-panel[^}]*\{[^}]*display:\s*none\s*!important;/s);
    assert.match(css, /\.area-fullscreen-restored-mode\s+#areas-container\s*\{[^}]*height:\s*100dvh;/s);
    assert.match(css, /\.area-section\.area-fullscreen-restored\s*\{[^}]*height:\s*100dvh;/s);
});
```

- [ ] **Step 2: Run the integration contract and verify RED**

Run:

```bash
node --test tests/fullscreen-area-integration.test.mjs
```

Expected: FAIL because the state module import, restored body class, explicit exit function, and full-viewport CSS are absent.

- [ ] **Step 3: Import and restore persisted state**

In the module import section of `index.html`, add:

```javascript
import {
    readFullscreenArea,
    saveFullscreenArea,
    clearFullscreenArea,
    resolveFullscreenArea
} from "./js/fullscreen-area-state.js";
```

Replace `restoreFullscreenArea()` with:

```javascript
function restoreFullscreenArea() {
    const savedAreaId = readFullscreenArea(localStorage);
    const validAreaId = resolveFullscreenArea(savedAreaId, areas.map(area => area.id));

    if (!validAreaId) {
        if (savedAreaId) clearFullscreenArea(localStorage);
        return;
    }

    const section = document.querySelector(`.area-section[data-area-id="${validAreaId}"]`);
    if (!section) {
        clearFullscreenArea(localStorage);
        return;
    }

    document.body.classList.add("area-fullscreen-restored-mode");
    document.querySelectorAll(".area-section").forEach(candidate => {
        candidate.classList.toggle("area-hidden", candidate.dataset.areaId !== validAreaId);
    });
    section.classList.add("area-fullscreen-restored");
    fullscreenAreaId = validAreaId;
    requestAnimationFrame(() => redrawAreaBracket(validAreaId));
}
```

- [ ] **Step 4: Make enter and exit persistence explicit**

Add this function before `toggleAreaFullscreen`:

```javascript
window.exitAreaFullscreen = async function () {
    const areaId = fullscreenAreaId || readFullscreenArea(localStorage);

    if (document.fullscreenElement) {
        await document.exitFullscreen().catch(() => {});
    }

    clearFullscreenArea(localStorage);
    fullscreenAreaId = null;
    document.body.classList.remove("area-fullscreen-restored-mode");
    document.querySelectorAll(".area-section").forEach(section => {
        section.classList.remove("area-hidden", "area-fullscreen-restored");
    });
    renderAllBrackets();

    if (areaId) requestAnimationFrame(() => redrawAreaBracket(areaId));
};
```

Replace the inline button handler in `renderAllBrackets()` with:

```javascript
onclick="window.handleAreaFullscreen('${area.id}')"
```

Replace `toggleAreaFullscreen` with:

```javascript
window.handleAreaFullscreen = async function (areaId) {
    const section = document.querySelector(`.area-section[data-area-id="${areaId}"]`);
    if (!section) return;

    const isSelected = fullscreenAreaId === areaId
        || section.classList.contains("area-fullscreen-restored")
        || document.fullscreenElement === section;

    if (isSelected) {
        await window.exitAreaFullscreen();
        return;
    }

    fullscreenAreaId = areaId;
    saveFullscreenArea(localStorage, areaId);

    try {
        if (document.fullscreenElement) await document.exitFullscreen();
        await section.requestFullscreen();
    } catch (err) {
        document.body.classList.add("area-fullscreen-restored-mode");
        restoreFullscreenArea();
        console.error(err);
        showToast("Fullscreen browser tidak dapat diaktifkan. Area tetap difokuskan.", "warning");
    }
};
```

Replace the `fullscreenchange` handler with:

```javascript
document.addEventListener("fullscreenchange", () => {
    const activeArea = document.fullscreenElement?.classList.contains("area-section")
        ? document.fullscreenElement
        : null;
    const areaId = activeArea?.dataset.areaId || fullscreenAreaId || readFullscreenArea(localStorage);

    if (activeArea) {
        fullscreenAreaId = activeArea.dataset.areaId;
        requestAnimationFrame(() => redrawAreaBracket(fullscreenAreaId));
    } else if (areaId) {
        restoreFullscreenArea();
    }
});
```

- [ ] **Step 5: Add full-viewport restored-mode CSS**

At the start of the existing restored fullscreen CSS section in
`css/public.css`, add:

```css
body.area-fullscreen-restored-mode {
    height: 100dvh;
    overflow: hidden;
}

.area-fullscreen-restored-mode #app,
.area-fullscreen-restored-mode #areas-container {
    width: 100%;
    height: 100dvh;
    min-height: 0;
    margin: 0;
    padding: 0;
    overflow: hidden;
}

.area-fullscreen-restored-mode .public-header,
.area-fullscreen-restored-mode .area-summary-panel {
    display: none !important;
}
```

Add `height: 100dvh;` to the existing
`.area-section.area-fullscreen-restored` rule.

- [ ] **Step 6: Run all focused tests and verify GREEN**

Run:

```bash
node --test tests/fullscreen-area-state.test.mjs tests/fullscreen-area-integration.test.mjs
```

Expected: `7` tests pass and `0` fail.

- [ ] **Step 7: Verify the refresh flow in the browser**

At `http://localhost:8080/`:

1. Press `FULL` on one area.
2. Refresh the page.
3. Confirm only the same area is visible.
4. Confirm the public header and champions summary are hidden.
5. Confirm the selected area fills the available viewport and `EXIT` remains visible.
6. Press `EXIT`.
7. Confirm all areas, the public header, and champions summary return.
8. Refresh again and confirm the normal multi-area page remains.

- [ ] **Step 8: Review and commit the integration**

Run:

```bash
git -c safe.directory="E:/Nest/2026/07. Juli 2026/pre-odt" diff -- index.html css/public.css js/fullscreen-area-state.js tests
git -c safe.directory="E:/Nest/2026/07. Juli 2026/pre-odt" status --short
```

Then commit only the integration files:

```bash
git add -- index.html css/public.css tests/fullscreen-area-integration.test.mjs
git commit -m "fix: restore focused fullscreen area after refresh"
```
