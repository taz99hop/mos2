const panel = document.getElementById('panel');
const statusText = document.getElementById('statusText');
const coordsText = document.getElementById('coords');
const strikeType = document.getElementById('strikeType');

function post(action, extra = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ strikeType: strikeType.value, ...extra })
  });
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'open') {
    panel.classList.remove('hidden');
  }
  if (data.action === 'close') {
    panel.classList.add('hidden');
  }
  if (data.action === 'status') {
    statusText.textContent = data.text || '...';
  }
  if (data.action === 'target') {
    if (data.coords) {
      coordsText.textContent = `الهدف: X ${data.coords.x.toFixed(1)} | Y ${data.coords.y.toFixed(1)} | Z ${data.coords.z.toFixed(1)}`;
    } else {
      coordsText.textContent = 'الهدف: غير محدد';
    }
  }
});

document.querySelectorAll('button').forEach((btn) => {
  btn.addEventListener('click', () => {
    post(btn.dataset.action);
  });
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    post('close');
  }
});
