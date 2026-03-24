const panel = document.getElementById('panel');
const closeBtn = document.getElementById('closeBtn');
const pickBtn = document.getElementById('pickBtn');
const launchBtn = document.getElementById('launchBtn');
const missileCount = document.getElementById('missileCount');
const cooldown = document.getElementById('cooldown');
const targetState = document.getElementById('targetState');
const targetInfo = document.getElementById('targetInfo');

let hasTarget = false;
let currentCooldown = 0;

function nui(event, data = {}) {
  fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
}

function setTargetState(active) {
  hasTarget = active;
  if (active) {
    targetState.textContent = 'الهدف مثبت وجاهز للإطلاق';
    targetState.classList.remove('warn');
    targetState.classList.add('ok');
  } else {
    targetState.textContent = 'لا يوجد هدف محدد';
    targetState.classList.remove('ok');
    targetState.classList.add('warn');
    targetInfo.textContent = '---';
  }
}

closeBtn.addEventListener('click', () => nui('close'));
pickBtn.addEventListener('click', () => nui('pickTarget'));
launchBtn.addEventListener('click', () => {
  if (currentCooldown > 0) {
    nui('uiNotify', { message: 'النظام في تبريد، انتظر حتى ينتهي العداد', type: 'error' });
    return;
  }

  if (!hasTarget) {
    nui('uiNotify', { message: 'حدد الهدف أولاً من الـ Waypoint', type: 'error' });
    return;
  }

  nui('launch', {
    missiles: Number(missileCount.value || 1),
  });
});

window.addEventListener('message', (e) => {
  const data = e.data;
  if (!data || !data.action) return;

  if (data.action === 'open') {
    panel.classList.remove('hidden');
    missileCount.value = data.defaultMissiles || 6;
    missileCount.min = data.minMissiles || 1;
    missileCount.max = data.maxMissiles || 12;
    currentCooldown = data.cooldown || 0;
    cooldown.textContent = currentCooldown;
    setTargetState(Boolean(data.hasTarget));
  }

  if (data.action === 'close') {
    panel.classList.add('hidden');
  }

  if (data.action === 'targetSelected') {
    setTargetState(true);
    targetInfo.textContent =
      `X: ${data.x.toFixed(2)}\n` +
      `Y: ${data.y.toFixed(2)}\n` +
      `Z: ${data.z.toFixed(2)}\n` +
      `DIST: ${data.distance}m`;
  }

  if (data.action === 'clearTarget') {
    setTargetState(false);
  }

  if (data.action === 'cooldown') {
    currentCooldown = Number(data.cooldown || 0);
    cooldown.textContent = currentCooldown;
  }
});

setInterval(() => {
  if (currentCooldown > 0) {
    currentCooldown -= 1;
    cooldown.textContent = currentCooldown;
  }
}, 1000);

document.addEventListener('keyup', (e) => {
  if (e.key === 'Escape') nui('close');
});
