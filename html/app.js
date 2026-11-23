// Locator receiver HUD — driven by SendNUIMessage from client/main.lua
const hud = document.getElementById('hud');
const barsEl = document.getElementById('bars');
const utilityEl = document.getElementById('utility');
const depthEl = document.getElementById('depth');
const statusEl = document.getElementById('status');
const marksEl = document.getElementById('marks');

const BAR_COUNT = 10;
const bars = [];
for (let i = 0; i < BAR_COUNT; i++) {
  const b = document.createElement('div');
  b.className = 'bar';
  barsEl.appendChild(b);
  bars.push(b);
}

function render(strength) {
  const lit = Math.round(strength / 10);
  bars.forEach((b, i) => {
    b.className = 'bar';
    if (i < lit) {
      b.classList.add('on');
      if (i >= 8) b.classList.add('peak');
      else if (i >= 6) b.classList.add('hot');
    }
  });
}

window.addEventListener('message', (event) => {
  const d = event.data;
  if (!d || !d.action) return;
  if (d.action === 'setVisible') {
    hud.classList.toggle('hidden', !d.visible);
  } else if (d.action === 'update') {
    render(d.strength || 0);
    utilityEl.textContent = d.utility || '';
    depthEl.textContent = (d.depth != null ? d.depth.toFixed(1) + 'm deep' : '');
    statusEl.textContent = d.status || '';
    marksEl.textContent = d.marks + ' / ' + d.required + ' marks';
  }
});
