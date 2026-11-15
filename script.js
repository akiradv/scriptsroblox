const BOT_DATAURL = "https://raw.githubusercontent.com/akiradv/scriptsroblox/main/scripts.json";
const BOT_LOCALURL = "scripts.json";
const BOT_CACHE_KEY = "scriptsdev:data:v1";
const BOT_CACHE_TTL = 60 * 60 * 1000;

const BOT_GAMEICONS_KEY = "scriptsdev:gameicons:v1";
const BOT_GAMEICONS_TTL = 24 * 60 * 60 * 1000;
const BOT_ROPROXY = "https://apis.roproxy.com/universes/v1/places/";
const BOT_THUMBS = "https://thumbnails.roproxy.com/v1/games/icons?universeIds=";

const BOT_TEAM_KEY = "scriptsdev:team:v2";
const BOT_TEAM_TTL = 60 * 60 * 1000;
const BOT_TEAM_APIS = [
    "https://discord-lookup.lookupbotdc.workers.dev/search/",
    "https://japi.rest/discord/v1/user/"
];
const BOT_TEAM_CDN = "https://cdn.discordapp.com/avatars/";

const BOT_WIDGET_KEY = "scriptsdev:widget:v1";
const BOT_WIDGET_TTL = 10 * 60 * 1000;

let BOT_Scripts = [];
let BOT_Data = null;
let BOT_ActiveTag = "";

function readStore(key) {
    try {
        const raw = localStorage.getItem(key);
        if (!raw) return null;
        return JSON.parse(raw);
    } catch (err) {
        return null;
    }
}

function writeStore(key, value) {
    try {
        localStorage.setItem(key, JSON.stringify(value));
    } catch (err) {
        // storage unavailable, everything still works without the cache
    }
}

function fetchJSON(url) {
    return fetch(url, { cache: "no-store" }).then(function (res) {
        if (!res.ok) throw new Error("bad response");
        return res.json();
    });
}

function readCachedData() {
    const entry = readStore(BOT_CACHE_KEY);
    if (!entry || !entry.at || !entry.data) return null;
    if (Date.now() - entry.at > BOT_CACHE_TTL) return null;
    return entry.data;
}

async function fetchScripts() {
    const cached = readCachedData();
    const remote = fetchJSON(BOT_DATAURL + "?t=" + Date.now()).then(function (data) {
        if (data && Array.isArray(data.scripts)) {
            writeStore(BOT_CACHE_KEY, { at: Date.now(), data: data });
        }
        return data;
    });

    if (cached) {
        remote.catch(function () {});
        return cached;
    }

    try {
        return await remote;
    } catch (err) {
        try {
            return await fetchJSON(BOT_LOCALURL);
        } catch (localErr) {
            return null;
        }
    }
}

function buildTagFilter() {
    const bar = document.getElementById('script-filter');
    if (!bar) return;

    const counts = {};
    BOT_Scripts.forEach(function (script) {
        (script.tags || []).forEach(function (tag) {
            counts[tag] = (counts[tag] || 0) + 1;
        });
    });

    const tags = Object.keys(counts).sort(function (a, b) {
        if (counts[b] !== counts[a]) return counts[b] - counts[a];
        return a.localeCompare(b);
    });

    while (bar.children.length > 1) bar.removeChild(bar.lastChild);

    const all = bar.firstElementChild;
    all.textContent = 'All';
    all.classList.toggle('is-active', BOT_ActiveTag === '');
    all.setAttribute('aria-pressed', BOT_ActiveTag === '' ? 'true' : 'false');

    const allCount = document.createElement('span');
    allCount.className = 'filter-chip-count';
    allCount.textContent = BOT_Scripts.length;
    all.appendChild(allCount);

    tags.forEach(function (tag) {
        const chip = document.createElement('button');
        chip.type = 'button';
        chip.className = 'filter-chip' + (BOT_ActiveTag === tag ? ' is-active' : '');
        chip.setAttribute('data-tag', tag);
        chip.setAttribute('aria-pressed', BOT_ActiveTag === tag ? 'true' : 'false');
        chip.textContent = tag;

        const count = document.createElement('span');
        count.className = 'filter-chip-count';
        count.textContent = counts[tag];
        chip.appendChild(count);

        bar.appendChild(chip);
    });

    bar.hidden = tags.length === 0;
}

function setupTagFilter() {
    const bar = document.getElementById('script-filter');
    if (!bar) return;

    bar.addEventListener('click', function (e) {
        const chip = e.target.closest('.filter-chip');
        if (!chip) return;

        const tag = chip.getAttribute('data-tag') || '';
        if (tag === BOT_ActiveTag) return;

        BOT_ActiveTag = tag;
        Array.prototype.forEach.call(bar.querySelectorAll('.filter-chip'), function (el) {
            const isActive = (el.getAttribute('data-tag') || '') === tag;
            el.classList.toggle('is-active', isActive);
            el.setAttribute('aria-pressed', isActive ? 'true' : 'false');
        });
        renderScripts();
    });
}

async function loadScripts() {
    const container = document.getElementById('scripts-container');
    if (!container) return;

    BOT_Data = await fetchScripts();

    if (!BOT_Data || !Array.isArray(BOT_Data.scripts)) {
        container.innerHTML = '<p class="card-description">failed to load scripts. check back later.</p>';
        return;
    }

    BOT_Scripts = BOT_Data.scripts.filter(function (s) { return s.available; });
    buildTagFilter();
    renderScripts();
    renderRoadmap();
}

function formatDate(dateString) {
    const parts = String(dateString).split("-");
    if (parts.length !== 3) return dateString;
    return parts[2] + "/" + parts[1] + "/" + parts[0];
}

function getStatusClass(working) {
    return working === false ? "status-broken" : "status-stable";
}

function getGitHubUrl(script) {
    const match = String(script.loadstring || "").match(/scripts\/([A-Za-z0-9_.-]+\.lua)/);
    if (match && BOT_Data) return BOT_Data.github + "/blob/main/scripts/" + match[1];
    return BOT_Data ? BOT_Data.github : "#";
}

function buildChangelogEntry(line) {
    const raw = String(line || "");
    const match = raw.match(/^\s*(v?\d+(?:\.\d+)*)\s*[:\u2013-]\s*(.+)$/);

    if (!match) {
        return '<div class="changelog-entry"><p class="changelog-text">' + raw + '</p></div>';
    }

    const version = match[1].charAt(0) === 'v' ? match[1] : 'v' + match[1];
    const body = match[2].trim();
    const parts = body.split(/,\s*/).filter(function (item) { return item.length > 0; });

    const list = parts.length > 1
        ? '<ul class="changelog-items">' + parts.map(function (item) {
              return '<li>' + item.replace(/\.$/, '') + '</li>';
          }).join('') + '</ul>'
        : '<p class="changelog-text">' + body + '</p>';

    return '<div class="changelog-entry"><span class="changelog-version">' + version + '</span>' + list + '</div>';
}

function renderScripts() {
    const container = document.getElementById('scripts-container');
    if (!container) return;
    container.innerHTML = '';

    if (BOT_Scripts.length === 0) {
        container.innerHTML = '<p class="card-description">no scripts available yet. check the roadmap.</p>';
        return;
    }

    const MAX_TAGS = 6;

    const visible = BOT_ActiveTag
        ? BOT_Scripts.filter(function (script) {
              return (script.tags || []).indexOf(BOT_ActiveTag) !== -1;
          })
        : BOT_Scripts;

    if (visible.length === 0) {
        const empty = document.createElement('p');
        empty.className = 'filter-empty';
        empty.textContent = 'no scripts with this tag yet.';
        container.appendChild(empty);
    }

    visible.forEach(function (script) {
        const card = document.createElement('article');
        card.className = 'script-card';

        const isWorking = script.working !== false;
        const statusClass = getStatusClass(isWorking);
        const statusText = isWorking ? "Working" : "Not Working";

        const features = script.features || [];
        const hiddenCount = Math.max(0, features.length - MAX_TAGS);
        const tagsHTML = features.map(function (f, i) {
            return '<span class="tag' + (i >= MAX_TAGS ? ' tag-hidden' : '') + '">' + f + '</span>';
        }).join('') + (hiddenCount > 0
            ? '<button type="button" class="tag tag-more" data-label="+' + hiddenCount + ' more">+' + hiddenCount + ' more</button>'
            : '');

        const desc = script.description || '';
        const changelogItems = script.changelog || [];
        const changelogBlock = changelogItems.length > 0
            ? '<details class="card-changelog"><summary>changelog</summary><div class="changelog-list">' +
              changelogItems.map(buildChangelogEntry).join('') +
              '</div></details>'
            : '';

        const iconSrc = script.icon || ('assets/games/' + script.id + '.webp');
        const iconFallback = String(script.game || script.name || "?").trim().charAt(0).toUpperCase();

        card.innerHTML =
            '<div class="card-header">' +
                '<div class="game-icon" data-fallback="' + iconFallback + '">' +
                    '<img src="' + iconSrc + '" alt="" width="64" height="64" loading="lazy" data-game-icon="' + script.id + '" onerror="this.remove()">' +
                '</div>' +
                '<div class="card-title-section">' +
                    '<h3 class="card-title">' + script.name + '</h3>' +
                    '<span class="card-game">' + script.game + ' <span class="card-version">v' + script.version + '</span></span>' +
                '</div>' +
                '<span class="status-badge ' + statusClass + '"><span class="status-dot"></span>' + statusText + '</span>' +
            '</div>' +
            (desc ? '<p class="card-description">' + desc + '</p>' : '') +
            '<div class="card-meta">' +
                '<span>updated ' + formatDate(script.lastUpdated) + '</span>' +
                '<span>id: ' + script.id + '</span>' +
            '</div>' +
            '<div class="card-tags">' + tagsHTML + '</div>' +
            changelogBlock +
            '<div class="card-actions">' +
                '<a class="btn" href="' + getGitHubUrl(script) + '" target="_blank" rel="noopener">View on GitHub</a>' +
            '</div>';

        container.appendChild(card);
    });

    resolveScriptIcons(BOT_Scripts).catch(function () {});
}

const BOT_ROADMAP_LIMIT = 10;

function buildRoadmapItem(text) {
    const el = document.createElement('div');
    el.className = 'roadmap-item';
    el.textContent = text;
    return el;
}

function renderRoadmapGroup(container, items, limit) {
    container.innerHTML = '';

    const group = container.closest('.roadmap-group') || container.parentNode;
    const oldReveal = group.querySelector('.roadmap-reveal');
    if (oldReveal) oldReveal.remove();

    const visible = items.slice(0, limit);
    const rest = items.slice(limit);

    visible.forEach(function (item) {
        container.appendChild(buildRoadmapItem(item));
    });

    if (rest.length === 0) return;


    const reveal = document.createElement('div');
    reveal.className = 'roadmap-reveal';

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'roadmap-more';
    btn.setAttribute('aria-label', 'show ' + rest.length + ' more');
    btn.innerHTML = '<span>View more</span>' +
        '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="6 9 12 15 18 9"></polyline></svg>';

    btn.addEventListener('click', function () {
        reveal.remove();
        rest.forEach(function (item) {
            container.appendChild(buildRoadmapItem(item));
        });
    });

    reveal.appendChild(btn);
    group.appendChild(reveal);
}

function renderRoadmap() {
    if (!BOT_Data || !BOT_Data.roadmap) return;

    const groups = {
        developing: document.getElementById('roadmap-developing'),
        planned: document.getElementById('roadmap-planned')
    };

    Object.keys(groups).forEach(function (key) {
        const container = groups[key];
        if (!container) return;
        renderRoadmapGroup(container, BOT_Data.roadmap[key] || [], BOT_ROADMAP_LIMIT);
    });
}

function readGameIconCache() {
    const entry = readStore(BOT_GAMEICONS_KEY);
    if (!entry || typeof entry !== "object" || !entry.map || typeof entry.map !== "object") {
        return { map: {} };
    }
    return entry;
}

function placeIdsOf(script) {
    if (Array.isArray(script.placeIds) && script.placeIds.length > 0) return script.placeIds;
    return script.placeId ? [script.placeId] : [];
}

function samePlaceIds(a, b) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) {
        if (String(a[i]) !== String(b[i])) return false;
    }
    return true;
}

async function fetchGameIcon(script) {
    const ids = placeIdsOf(script);
    let universe = null;

    for (const placeId of ids) {
        const result = await fetchJSON(BOT_ROPROXY + placeId + "/universe").catch(function () { return null; });
        if (result && result.universeId) {
            universe = result;
            break;
        }
    }

    if (!universe || !universe.universeId) throw new Error("no universe id");

    const icons = await fetchJSON(BOT_THUMBS + universe.universeId + "&size=256x256&format=Png&isCircular=false");
    const url = icons && icons.data && icons.data[0] ? icons.data[0].imageUrl : null;
    if (!url) throw new Error("no thumbnail");
    return url;
}

async function resolveScriptIcons(scripts) {
    const targets = scripts.filter(function (sc) { return placeIdsOf(sc).length > 0 && !sc.icon; });
    if (targets.length === 0) return;

    const cache = readGameIconCache();
    const icons = cache.map;
    const now = Date.now();

    const pending = [];

    for (const script of targets) {
        const cached = icons[script.id];

        if (cached && samePlaceIds(cached.placeIds, placeIdsOf(script)) && now - cached.at < BOT_GAMEICONS_TTL) {
            script.icon = cached.url;
            continue;
        }

        pending.push(script);
    }

    if (pending.length === 0) return;

    await Promise.all(pending.map(async function (script) {
        try {
            const url = await fetchGameIcon(script);
            script.icon = url;
            icons[script.id] = { url: url, placeIds: placeIdsOf(script), at: Date.now() };
            writeStore(BOT_GAMEICONS_KEY, cache);

            const img = document.querySelector('img[data-game-icon="' + script.id + '"]');
            if (img && img.getAttribute("src") !== url) img.setAttribute("src", url);
        } catch (err) {
            // keep the bundled icon, try again on the next visit
        }
    }));
}

const BOT_AVATAR_SVG = "data:image/svg+xml," + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 112 112">' +
    '<rect width="112" height="112" fill="#12161a"/>' +
    '<circle cx="56" cy="44" r="17" fill="#2b333a"/>' +
    '<path d="M24 106c0-18 14-30 32-30s32 12 32 30z" fill="#2b333a"/>' +
    '</svg>'
);

function readTeamCache() {
    const entry = readStore(BOT_TEAM_KEY);
    if (!entry || typeof entry !== "object") return {};
    return entry;
}

function avatarURL(userId, hash, size) {
    const animated = /^a_/i.test(hash);
    return BOT_TEAM_CDN + userId + "/" + hash + (animated ? ".gif" : ".webp") + "?size=" + size;
}

async function lookupAvatarHash(userId) {
    for (const base of BOT_TEAM_APIS) {
        try {
            const payload = await fetchJSON(base + userId);
            const hash = payload && payload.user ? payload.user.avatar
                : payload && payload.data ? payload.data.avatar
                : null;
            if (hash) return String(hash);
        } catch (err) {
            // try the next provider
        }
    }
    throw new Error("no provider returned an avatar");
}

function setAvatar(slot, url, name) {
    let img = slot.querySelector("img");
    if (!img) {
        img = document.createElement("img");
        img.alt = name || "";
        img.width = 112;
        img.height = 112;
        img.decoding = "async";
        img.addEventListener("error", function () {
            const current = img.getAttribute("src") || "";
            if (current.indexOf(".webp") !== -1) {
                img.setAttribute("src", current.replace(".webp", ".png"));
                return;
            }
            if (current !== BOT_AVATAR_SVG) img.setAttribute("src", BOT_AVATAR_SVG);
        });
        slot.appendChild(img);
    }
    if (img.getAttribute("src") !== url) img.setAttribute("src", url);
}

function widgetFallback() {
    return '<a class="widget-fallback" href="https://discord.gg/2ksQSAnnW6" target="_blank" rel="noopener">' +
        '<span class="widget-fallback-label">community</span>' +
        '<span class="widget-fallback-name">scripts.dev</span>' +
        '<span class="widget-fallback-meta">join us on discord for support, updates and suggestions.</span>' +
        '<span class="widget-fallback-cta">Join the server</span>' +
        '</a>';
}

async function loadDiscordWidget() {
    const box = document.getElementById('discord-widget');
    if (!box) return;

    const guild = box.getAttribute('data-guild');
    if (!guild) return;

    box.classList.add('discord-widget--fallback');
    box.innerHTML = widgetFallback();

    let cached = null;
    try {
        cached = readStore(BOT_WIDGET_KEY);
    } catch (err) {
        cached = null;
    }

    if (cached && cached.at && Date.now() - cached.at < BOT_WIDGET_TTL && cached.guild === guild) {
        paintWidgetEmbed(box, guild, cached);
        return;
    }

    const data = await fetchJSON(
        'https://discord.com/api/guilds/' + guild + '/widget.json'
    ).catch(function () { return null; });

    if (!data || !data.name) return;

    const meta = {
        guild: guild,
        at: Date.now(),
        name: data.name,
        presence: data.presence_count || 0
    };
    writeStore(BOT_WIDGET_KEY, meta);
    paintWidgetEmbed(box, guild, meta);
}

function paintWidgetEmbed(box, guild, meta) {
    box.classList.remove('discord-widget--fallback');
    box.classList.add('discord-widget--embed');
    box.innerHTML = '<iframe src="https://discord.com/widget?id=' + guild +
        '&theme=dark" width="100%" height="340" allowtransparency="true" frameborder="0" ' +
        'sandbox="allow-popups allow-popups-to-escape-sandbox allow-same-origin allow-scripts" ' +
        'title="' + (meta && meta.name ? meta.name : 'Discord') + '"></iframe>';
}

async function refreshTeamAvatars() {
    const slots = Array.prototype.slice.call(document.querySelectorAll(".team-avatar[data-user]"));
    if (slots.length === 0) return;

    const cache = readTeamCache();
    const now = Date.now();
    let changed = false;

    for (const slot of slots) {
        const userId = slot.getAttribute("data-user");
        if (!userId) continue;

        const name = slot.getAttribute("data-name") || "";
        const knownHash = slot.getAttribute("data-hash") || "";
        const entry = cache[userId];
        const cachedHash = entry && entry.hash ? entry.hash : "";

        const usableHash = cachedHash || knownHash;
        setAvatar(slot, usableHash ? avatarURL(userId, usableHash, 256) : BOT_AVATAR_SVG, name);

        const fresh = entry && entry.at && now - entry.at < BOT_TEAM_TTL;
        if (fresh) continue;

        try {
            const hash = await lookupAvatarHash(userId);
            cache[userId] = { hash: hash, at: Date.now() };
            changed = true;

            if (hash !== usableHash) {
                setAvatar(slot, avatarURL(userId, hash, 256), name);
                slot.setAttribute("data-hash", hash);
            }
        } catch (err) {
            // keep whatever is on screen
        }
    }

    if (changed) writeStore(BOT_TEAM_KEY, cache);
}

function copyToClipboard(text) {
    const fallback = function () {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        try {
            document.execCommand('copy');
        } catch (err) {
            // nothing else to try
        }
        document.body.removeChild(textarea);
        showToast();
    };

    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).then(showToast).catch(fallback);
        return;
    }
    fallback();
}

function showToast() {
    const toast = document.getElementById('toast');
    if (!toast) return;
    toast.classList.add('show');
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(function () {
        toast.classList.remove('show');
    }, 2600);
}

document.addEventListener('click', function (e) {
    const btn = e.target.closest('.tag-more');
    if (!btn) return;
    const wrap = btn.closest('.card-tags');
    const expanded = wrap.classList.toggle('expanded');
    btn.textContent = expanded ? 'show less' : btn.getAttribute('data-label');
});

function setupNav() {
    const toggle = document.querySelector('.nav-toggle');
    const links = document.getElementById('nav-links');
    if (!toggle || !links) return;

    const close = function () {
        document.body.classList.remove('nav-menu-open');
        toggle.setAttribute('aria-expanded', 'false');
        toggle.setAttribute('aria-label', 'Open menu');
    };

    toggle.addEventListener('click', function () {
        const open = document.body.classList.toggle('nav-menu-open');
        toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    });

    links.addEventListener('click', function (e) {
        if (e.target.closest('a')) close();
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') close();
    });

    document.addEventListener('click', function (e) {
        if (!document.body.classList.contains('nav-menu-open')) return;
        if (e.target.closest('.nav-links') || e.target.closest('.nav-toggle')) return;
        close();
    });

    window.addEventListener('resize', function () {
        if (window.innerWidth > 768) close();
    });
}

function setupStickyHeader() {
    const bar = document.querySelector('.topbar');
    if (!bar) return;

    const update = function () {
        bar.classList.toggle('is-stuck', window.scrollY > 8);
    };

    update();
    window.addEventListener('scroll', update, { passive: true });
}

document.addEventListener('DOMContentLoaded', function () {
    setupNav();
    setupStickyHeader();
    setupTagFilter();
    loadScripts();
    refreshTeamAvatars().catch(function () {});
    loadDiscordWidget();

    const loaderCopyBtn = document.querySelector('.loader-copy-btn');
    if (loaderCopyBtn) {
        loaderCopyBtn.addEventListener('click', function () {
            const btn = this;
            const originalHTML = btn.innerHTML;
            copyToClipboard(btn.getAttribute('data-loadstring'));
            btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>Copied';
            btn.classList.add('copied');
            setTimeout(function () {
                btn.innerHTML = originalHTML;
                btn.classList.remove('copied');
            }, 1600);
        });
    }
});
