const app = document.getElementById('app');
const stateOpen = document.getElementById('stateOpen');
const stateRise = document.getElementById('stateRise');
const stateArm = document.getElementById('stateArm');
const stateReady = document.getElementById('stateReady');
const stateSequence = document.getElementById('stateSequence');

const missileType = document.getElementById('missileType');
const targetX = document.getElementById('targetX');
const targetY = document.getElementById('targetY');
const targetZ = document.getElementById('targetZ');

function post(event, data = {}) {
  fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
}

function applyState(s) {
  if (!s) return;
  stateOpen.textContent = s.isOpen ? 'مفتوحة' : 'مغلقة';
  stateRise.textContent = s.isRisen ? 'على السطح' : 'أسفل';
  stateArm.textContent = s.isArmed ? 'رأسي' : 'أفقي';
  stateReady.textContent = s.launchReady ? 'جاهز' : 'غير جاهز';
  stateSequence.textContent = s.sequence;
  missileType.value = s.missileType || 'tactical';

  if (s.target) {
    targetX.value = Number(s.target.x || 0).toFixed(2);
    targetY.value = Number(s.target.y || 0).toFixed(2);
    targetZ.value = Number(s.target.z || 0).toFixed(2);
  }
}

window.addEventListener('message', (ev) => {
  const msg = ev.data;
  if (!msg) return;

  if (msg.action === 'toggle') {
    app.classList.toggle('hidden', !msg.show);
    applyState(msg.payload);
  }

  if (msg.action === 'state') {
    applyState(msg.payload);
  }
});

document.getElementById('closeBtn').addEventListener('click', () => post('close'));
document.getElementById('targetBtn').addEventListener('click', () => {
  post('setTarget', {
    x: Number(targetX.value || 0),
    y: Number(targetY.value || 0),
    z: Number(targetZ.value || 0)
  });
});

missileType.addEventListener('change', () => {
  post('setMissileType', { type: missileType.value });
});

for (const btn of document.querySelectorAll('[data-action]')) {
  btn.addEventListener('click', () => {
    post('stepAction', { action: btn.dataset.action });
  });
}

document.addEventListener('keyup', (ev) => {
  if (ev.key === 'Escape') post('close');
});
