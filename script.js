const BOT_DATAURL = "https://raw.githubusercontent.com/akiradv/scriptsroblox/main/scripts.json";
let BOT_Scripts = [];
let BOT_Data = null;

async function loadScripts() {
    try {
        const response = await fetch(BOT_DATAURL + "?t=" + Date.now(), { cache: "no-store" });
        BOT_Data = await response.json();
        BOT_Scripts = BOT_Data.scripts.filter(s => s.available);
        renderScripts();
        renderRoadmap();
    } catch (err) {
        console.error("failed to load scripts.json", err);
        document.getElementById('scripts-container').innerHTML = '<p>failed to load scripts. check back later.</p>';
    }
}

function formatDate(dateString) {
    const BOT_Parts = String(dateString).split("-");
    if (BOT_Parts.length !== 3) return dateString;
    return BOT_Parts[2] + "/" + BOT_Parts[1] + "/" + BOT_Parts[0];
}

function getStatusClass(status) {
    const s = status.toLowerCase();
    if (s === "stable") return "status-stable";
    if (s === "beta") return "status-beta";
    if (s === "alpha") return "status-alpha";
    return "status-stable";
}

function getGitHubUrl(script) {
    const BOT_Match = script.loadstring.match(/scripts\/([A-Za-z0-9_.-]+\.lua)/);
    if (BOT_Match && BOT_Data) return BOT_Data.github + "/blob/main/scripts/" + BOT_Match[1];
    return BOT_Data ? BOT_Data.github : "#";
}

function renderScripts() {
    const container = document.getElementById('scripts-container');
    container.innerHTML = '';

    if (BOT_Scripts.length === 0) {
        container.innerHTML = '<p>no scripts available yet. check the roadmap.</p>';
        return;
    }

    const MAX_TAGS = 6;

    BOT_Scripts.forEach((script, index) => {
        const card = document.createElement('div');
        card.className = 'script-card';
        card.style.animationDelay = `${index * 0.08}s`;

        const statusClass = getStatusClass(script.status);

        const features = script.features || [];
        const hiddenCount = Math.max(0, features.length - MAX_TAGS);
        const tagsHTML = features.map((f, i) =>
            `<span class="tag${i >= MAX_TAGS ? ' tag-hidden' : ''}">${f}</span>`
        ).join('') + (hiddenCount > 0
            ? `<button type="button" class="tag tag-more" data-label="+${hiddenCount} more">+${hiddenCount} more</button>`
            : '');

        const desc = script.description || '';
        const changelogItems = script.changelog || [];
        const changelogHTML = changelogItems.map(c => `<li>${c}</li>`).join('');
        const changelogBlock = changelogItems.length > 0
            ? `<details class="card-changelog"><summary>changelog</summary><ul>${changelogHTML}</ul></details>`
            : '';

        card.innerHTML = `
            <div class="card-header">
                <div class="card-title-section">
                    <h3 class="card-title">${script.name}</h3>
                    <span class="card-game">${script.game}</span>
                    <span class="card-version">v${script.version}</span>
                </div>
                <span class="status-badge ${statusClass}"><span class="status-dot"></span>${script.status}</span>
            </div>
            ${desc ? `<p class="card-description">${desc}</p>` : ''}
            <div class="card-meta">
                <span class="meta-item">updated ${formatDate(script.lastUpdated)}</span>
                <span class="meta-item">id: ${script.id}</span>
            </div>
            <div class="card-tags">${tagsHTML}</div>
            ${changelogBlock}
            <div class="card-actions">
                <a class="btn btn-github" href="${getGitHubUrl(script)}" target="_blank" rel="noopener">View on GitHub</a>
            </div>
        `;

        container.appendChild(card);
    });
}

function renderRoadmap() {
    if (!BOT_Data || !BOT_Data.roadmap) return;

    const groups = {
        developing: document.getElementById('roadmap-developing'),
        planned: document.getElementById('roadmap-planned')
    };

    for (const key in groups) {
        const container = groups[key];
        if (!container) continue;
        container.innerHTML = '';
        (BOT_Data.roadmap[key] || []).forEach(function (item) {
            const el = document.createElement('div');
            el.className = 'roadmap-item';
            el.textContent = item;
            container.appendChild(el);
        });
    }
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showToast();
    }).catch(() => {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showToast();
    });
}

function showToast() {
    const toast = document.getElementById('toast');
    toast.classList.add('show');
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

document.addEventListener('click', function (e) {
    const btn = e.target.closest('.tag-more');
    if (!btn) return;
    const wrap = btn.closest('.card-tags');
    const expanded = wrap.classList.toggle('expanded');
    btn.textContent = expanded ? 'show less' : btn.getAttribute('data-label');
});

document.addEventListener('DOMContentLoaded', function () {
    loadScripts();

    const loaderCopyBtn = document.querySelector('.loader-copy-btn');
    if (loaderCopyBtn) {
        loaderCopyBtn.addEventListener('click', function () {
            const btn = this;
            const originalHTML = btn.innerHTML;
            copyToClipboard(btn.getAttribute('data-loadstring'));
            btn.innerHTML = `
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                Copied
            `;
            btn.classList.add('copied');
            setTimeout(() => {
                btn.innerHTML = originalHTML;
                btn.classList.remove('copied');
            }, 1500);
        });
    }
});