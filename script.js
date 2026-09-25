const BOT_DataURL = "https://raw.githubusercontent.com/akiradv/scriptsroblox/main/scripts.json";
let BOT_Scripts = [];
let BOT_Data = null;

async function loadScripts() {
  try {
    const response = await fetch(BOT_DataURL);
    BOT_Data = await response.json();
    BOT_Scripts = BOT_Data.scripts.filter(s => s.available);
    renderScripts();
  } catch (err) {
    console.error("failed to load scripts.json", err);
    document.getElementById('scripts-container').innerHTML = '<p class="error">failed to load scripts. check back later.</p>';
  }
}

function formatDate(dateString) {
    const date = new Date(dateString);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}/${month}/${year}`;
}

function getStatusClass(status) {
    const s = status.toLowerCase();
    if (s === "stable") return "status-stable";
    if (s === "beta") return "status-beta";
    if (s === "alpha") return "status-alpha";
    return "status-stable";
}

function renderScripts() {
    const container = document.getElementById('scripts-container');
    container.innerHTML = '';
    
    if (BOT_Scripts.length === 0) {
        container.innerHTML = '<p style="color: var(--text-dim); font-size: 14px;">no scripts available yet. check the roadmap.</p>';
        return;
    }
    
    BOT_Scripts.forEach((script, index) => {
        const card = document.createElement('div');
        card.className = 'script-card';
        card.style.animationDelay = `${index * 0.08}s`;
        
        const featuresHTML = script.features.map(f => `<span class="tag">${f}</span>`).join('');
        const statusClass = getStatusClass(script.status);
        
        card.innerHTML = `
            <div class="card-header">
                <div class="card-title-section">
                    <h3 class="card-title">${script.name}</h3>
                    <span class="card-game">${script.game}</span>
                </div>
                <div class="card-version">v${script.version}</div>
            </div>
            
            <p class="card-description">${script.changelog.map(c => "• " + c).join(" · ")}</p>
            
            <div class="card-meta">
                <div class="meta-item">
                    <span>Updated: ${formatDate(script.lastUpdated)}</span>
                </div>
                <div class="meta-item">
                    <span class="status-badge ${statusClass}">
                        <span class="status-dot"></span>
                        ${script.status}
                    </span>
                </div>
            </div>

            <div class="card-loadstring">
                <div class="loadstring-header">
                    <span class="loadstring-label">loadstring</span>
                    <button class="loadstring-copy-btn" data-loadstring="${script.loadstring}">
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                        </svg>
                        copy
                    </button>
                </div>
                <code class="loadstring-code">${script.loadstring}</code>
            </div>
            
            <div class="card-tags">
                ${featuresHTML}
            </div>
            
            <div class="card-actions">
                <button class="btn btn-copy" data-loadstring="${script.loadstring}">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                        <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                    </svg>
                    Copy Loadstring
                </button>
                <a href="${BOT_Data.github}" target="_blank" class="btn btn-github">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                    </svg>
                    View on GitHub
                </a>
            </div>
        `;
        
        container.appendChild(card);
    });
    
    document.querySelectorAll('.btn-copy').forEach(button => {
        button.addEventListener('click', function() {
            const loadstring = this.getAttribute('data-loadstring');
            copyToClipboard(loadstring);
        });
    });

    document.querySelectorAll('.loadstring-copy-btn').forEach(button => {
        button.addEventListener('click', function() {
            const loadstring = this.getAttribute('data-loadstring');
            copyToClipboard(loadstring);
        });
    });
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

document.addEventListener('DOMContentLoaded', loadScripts);