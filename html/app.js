const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const commanderState = document.getElementById('commanderState');
const blackoutState = document.getElementById('blackoutState');
const typeSelect = document.getElementById('typeSelect');
const countInput = document.getElementById('countInput');
const launcherInput = document.getElementById('launcherInput');
const fireBtn = document.getElementById('fireBtn');
const tracksEl = document.getElementById('tracks');
const alertsEl = document.getElementById('alerts');
const radarState = document.getElementById('radarState');

let bootstrapLoaded = false;

function post(event, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).then((r) => r.json());
}

function addAlert(text) {
  const li = document.createElement('li');
  li.className = 'alert';
  li.textContent = text;
  alertsEl.prepend(li);
  while (alertsEl.children.length > 20) alertsEl.removeChild(alertsEl.lastChild);
}

async function ensureBootstrap() {
  if (bootstrapLoaded) return;
  const data = await post('requestBootstrap');

  typeSelect.innerHTML = '';
  Object.keys(data.missileTypes).forEach((key) => {
    const opt = document.createElement('option');
    opt.value = key;
    opt.textContent = `${key} - ${data.missileTypes[key].label}`;
    typeSelect.appendChild(opt);
  });

  commanderState.textContent = data.commander ? `Server ID: ${data.commander}` : 'لا يوجد قائد نشط';
  blackoutState.textContent = `Blackout: ${data.blackout || 0}%`;
  bootstrapLoaded = true;
}

fireBtn.addEventListener('click', async () => {
  await post('fireMission', {
    typeKey: typeSelect.value,
    count: Number(countInput.value || 1),
    launcherName: launcherInput.value || 'Battery-01'
  });
  addAlert('تم إرسال أمر الإطلاق للقائد.');
});

closeBtn.addEventListener('click', () => {
  app.classList.add('hidden');
  post('close');
});

window.addEventListener('message', async (event) => {
  const data = event.data;

  if (data.action === 'toggle') {
    if (data.show) {
      app.classList.remove('hidden');
      await ensureBootstrap();
    } else {
      app.classList.add('hidden');
    }
  }

  if (data.action === 'commander') {
    commanderState.textContent = data.serverId ? `Server ID: ${data.serverId}` : 'لا يوجد قائد نشط';
  }

  if (data.action === 'tracks') {
    tracksEl.innerHTML = '';
    data.tracks.forEach((t) => {
      const li = document.createElement('li');
      li.innerHTML = `<b>${t.id}</b> | ${t.typeKey} | ETA ${t.eta}s<br><span class="small">Heading: ${t.heading.toFixed(1)}° | Speed: ${t.speed.toFixed(1)} m/s | Zone: ${t.zone}</span>`;
      tracksEl.appendChild(li);
    });
  }

  if (data.action === 'launch') {
    addAlert(`Incoming Missile (${data.data.missileType}) ETA ${data.data.eta}s`);
  }

  if (data.action === 'blackout') {
    blackoutState.textContent = `Blackout: ${data.level}%`;
    if (data.level >= 50) addAlert('انقطاع كهرباء متزايد بسبب إصابة محطات الطاقة.');
  }

  if (data.action === 'radar_offline') {
    radarState.textContent = `Offline (${data.seconds}s)`;
    addAlert(`تعطّل الرادار لمدة ${data.seconds} ثانية.`);
  }
});
