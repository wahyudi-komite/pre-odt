export function formatWIB(dateString) {
    if (!dateString) return "-";
    const d = new Date(dateString);
    return d.toLocaleDateString("id-ID", {
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        timeZone: "Asia/Jakarta"
    }).replace(/\./g, ".") + " WIB";
}

export function formatTimeWIB(dateString) {
    if (!dateString) return "-";
    const d = new Date(dateString);
    return d.toLocaleTimeString("id-ID", {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        timeZone: "Asia/Jakarta"
    }) + " WIB";
}

export function escapeHtml(str) {
    if (str == null) return "";
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
}

export function debounce(fn, ms) {
    let timer;
    return function (...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), ms);
    };
}

export function statusLabel(status) {
    const map = {
        "not_started": "Belum Dimulai",
        "live": "Berlangsung",
        "finished": "Selesai"
    };
    return map[status] || status;
}

export function statusBadgeClass(status) {
    const map = {
        "not_started": "badge-not-started",
        "live": "badge-live",
        "finished": "badge-finished"
    };
    return map[status] || "";
}

export function stageLabel(stage) {
    const map = {
        "quarter_final": "Perempat Final",
        "semi_final": "Semifinal",
        "third_place": "Perebutan Juara 3",
        "final": "Final"
    };
    return map[stage] || stage;
}

export function errorMessage(err) {
    if (!err) return "Terjadi kesalahan yang tidak diketahui.";
    if (typeof err === "string") return err;
    if (err.message) return err.message;
    return "Terjadi kesalahan. Silakan coba lagi.";
}


