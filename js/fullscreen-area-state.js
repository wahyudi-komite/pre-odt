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
