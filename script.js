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

  BOT_Scripts.forEach((script, index) => {
    const card = document.createElement('div');
    card.className = 'script-card';
    card.style.animationDelay = `${index * 0.08}s`;

    const statusClass = getStatusClass(script.status);
    const tagsHTML = script.features.map(f => `<span class="tag">${f}</span>`).join('');
    const changelogHTML = script.changelog.map(c => `• ${c}`).join('<br>');

    card.innerHTML = `
      <div class="card-header">
        <div class="card-title-section">
          <h3 class="card-title">${script.name}</h3>
          <span class="card-game">${script.game}</span>
          <span class="card-version">v${script.version}</span>
        </div>
        <span class="status-badge ${statusClass}"><span class="status-dot"></span>${script.status}</span>
      </div>
      <p class="card-description">${changelogHTML}</p>
      <div class="card-meta">
        <span class="meta-item">updated ${formatDate(script.lastUpdated)}</span>
        <span class="meta-item">id: ${script.id}</span>
      </div>
      <div class="card-loadstring">
        <div class="loadstring-header">
          <span class="loadstring-label">loadstring</span>
          <button class="loadstring-copy-btn" data-loadstring="${script.loadstring}">copy</button>
        </div>
        <code class="loadstring-code">${script.loadstring}</code>
      </div>
      <div class="card-tags">${tagsHTML}</div>
      <div class="card-actions">
        <button class="btn btn-copy" data-loadstring="${script.loadstring}">Copy Loadstring</button>
        <a class="btn btn-github" href="${getGitHubUrl(script)}" target="_blank" rel="noopener">View on GitHub</a>
      </div>
    `;

    container.appendChild(card);
  });

  document.querySelectorAll('.btn-copy').forEach(button => {
    button.addEventListener('click', function() {
      copyToClipboard(this.getAttribute('data-loadstring'));
    });
  });

  document.querySelectorAll('.loadstring-copy-btn').forEach(button => {
    button.addEventListener('click', function() {
      copyToClipboard(this.getAttribute('data-loadstring'));
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