const BOT_DATAURL = "https://raw.githubusercontent.com/akiradv/scriptsroblox/main/scripts.json";
let BOT_Scripts = [];
let BOT_Data = null;

async function loadScripts() {
  try {
    const response = await fetch(BOT_DATAURL + "?t=" + Date.now(), { cache: "no-store" });
    BOT_Data = await response.json();
    BOT_Scripts = BOT_Data.scripts.filter(s => s.available);
    renderScripts();
  } catch (err) {
    console.error("failed to load scripts.json", err);
    document.getElementById('scripts-container').innerHTML = '<p>failed to load scripts. check back later.</p>';
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
    container.innerHTML = '<p>no scripts available yet. check the roadmap.</p>';
    return;
  }

  BOT_Scripts.forEach((script, index) => {
    const card = document.createElement('div');
    card.className = 'script-card';
    card.style.animationDelay = `${index * 0.08}s`;

    const featuresHTML = script.features.map(f => `<li>${f}</li>`).join('');
    const statusClass = getStatusClass(script.status);

    card.innerHTML = `
      <div class="script-header">
        <div class="script-info">
          <h3>${script.name}</h3>
          <span class="script-game">${script.game}</span>
          <span class="script-version">v${script.version}</span>
        </div>
        <span class="status-pill ${statusClass}">${script.status}</span>
      </div>

      <div class="script-changelog">
        ${script.changelog.map(c => "• " + c).join(" · ")}
      </div>

      <div class="script-meta">
        <span>Updated: ${formatDate(script.lastUpdated)}</span>
      </div>

      <div class="loadstring-box">
        <div class="loadstring-header">
          <span>loadstring</span>
          <button class="loadstring-copy-btn" data-loadstring="${script.loadstring}" title="Copy">copy</button>
        </div>
        <code class="loadstring-code">${script.loadstring}</code>
      </div>

      <ul class="script-features">
        ${featuresHTML}
      </ul>

      <div class="script-actions">
        <button class="btn btn-copy" data-loadstring="${script.loadstring}">Copy Loadstring</button>
        <a href="https://github.com/akiradv/scriptsroblox/blob/main/scripts/${script.id}p.lua" target="_blank" class="btn btn-github">View on GitHub</a>
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