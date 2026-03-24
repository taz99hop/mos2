const panel = document.getElementById("panel");
const fireBtn = document.getElementById("fire");
const closeBtn = document.getElementById("close");

function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
}

window.addEventListener("message", (e) => {
  const d = e.data || {};
  if (d.action === "open") {
    panel.classList.remove("hidden");
  }
});

fireBtn.addEventListener("click", () => {
  post("fire_waypoint", {
    rockets: Number(document.getElementById("rockets").value || 6),
    spread: Number(document.getElementById("spread").value || 35),
    delay: Number(document.getElementById("delay").value || 500),
  });
});

closeBtn.addEventListener("click", () => {
  panel.classList.add("hidden");
  post("close");
});

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    panel.classList.add("hidden");
    post("close");
  }
});
