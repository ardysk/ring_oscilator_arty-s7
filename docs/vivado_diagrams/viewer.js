const pdfSel = document.getElementById("pdfSel");
const btnPrev = document.getElementById("prev");
const btnNext = document.getElementById("next");
const pageInp = document.getElementById("page");
const canvas = document.getElementById("c");
const overlay = document.getElementById("overlay");
const tip = document.getElementById("tip");
const btnPick = document.getElementById("pick");

const FILES = window.VIVADO_PDF_FILES || [];
const MAP = window.VIVADO_PDF_MAP || {};

let state = {
  pdf: FILES[0] || null,
  page: 1,
  scale: 1.5,
  doc: null,
  picking: false,
  pickStart: null,
  pickBox: null,
};

function showTip(x, y, title, desc) {
  tip.style.left = `${x + 12}px`;
  tip.style.top = `${y + 12}px`;
  tip.innerHTML = `<div class="t">${title}</div><div class="d">${desc || ""}</div>`;
  tip.style.display = "block";
}
function hideTip() { tip.style.display = "none"; }

function rebuildSelect() {
  pdfSel.innerHTML = "";
  FILES.forEach(f => {
    const opt = document.createElement("option");
    opt.value = f;
    opt.textContent = f;
    pdfSel.appendChild(opt);
  });
  if (state.pdf) pdfSel.value = state.pdf;
}

async function loadPdf(file) {
  state.pdf = file;
  state.doc = await pdfjsLib.getDocument(file).promise;
  state.page = Math.max(1, Math.min(state.page, state.doc.numPages));
  pageInp.value = state.page;
  await render();
}

function clearOverlay() {
  overlay.innerHTML = "";
}

function addBox(link) {
  const d = document.createElement("div");
  d.className = "box";
  d.style.left = `${link.x}px`;
  d.style.top = `${link.y}px`;
  d.style.width = `${link.w}px`;
  d.style.height = `${link.h}px`;

  d.addEventListener("mousemove", (e) => showTip(e.clientX, e.clientY, link.title || link.id, link.desc || ""));
  d.addEventListener("mouseleave", hideTip);
  d.addEventListener("click", () => {
    const g = link.goto;
    if (!g) return;
    if (g.pdf) {
      state.page = g.page || 1;
      loadPdf(g.pdf);
    }
  });

  overlay.appendChild(d);
}

function renderLinks() {
  clearOverlay();
  const m = MAP[state.pdf];
  if (!m || !m.links) return;
  const links = m.links.filter(l => (l.page || 1) === state.page);
  links.forEach(addBox);
}

async function render() {
  if (!state.doc) return;
  const page = await state.doc.getPage(state.page);
  const viewport = page.getViewport({ scale: state.scale });
  const ctx = canvas.getContext("2d");
  canvas.width = Math.floor(viewport.width);
  canvas.height = Math.floor(viewport.height);
  overlay.style.width = canvas.width + "px";
  overlay.style.height = canvas.height + "px";
  overlay.style.position = "absolute";

  await page.render({ canvasContext: ctx, viewport }).promise;
  renderLinks();
}

function logPickRect(x, y, w, h) {
  // Print a ready-to-paste entry for maps.js
  const msg =
`{ id: \"<ID>\", page: ${state.page}, x: ${x}, y: ${y}, w: ${w}, h: ${h},\n  title: \"<title>\", desc: \"<opis>\",\n  goto: { pdf: \"<target.pdf>\", page: 1 }\n},`;
  console.log(msg);
}

function enablePicking(on) {
  state.picking = on;
  btnPick.textContent = on ? "Pick ON (ESC wyłącza)" : "Pick (rysuj prostokąt)";
}

overlay.addEventListener("mousedown", (e) => {
  if (!state.picking) return;
  state.pickStart = { x: e.offsetX, y: e.offsetY };
  state.pickBox = document.createElement("div");
  state.pickBox.className = "box";
  state.pickBox.style.borderStyle = "dashed";
  overlay.appendChild(state.pickBox);
});

overlay.addEventListener("mousemove", (e) => {
  if (!state.picking || !state.pickStart || !state.pickBox) return;
  const x0 = state.pickStart.x, y0 = state.pickStart.y;
  const x1 = e.offsetX, y1 = e.offsetY;
  const x = Math.min(x0, x1);
  const y = Math.min(y0, y1);
  const w = Math.abs(x1 - x0);
  const h = Math.abs(y1 - y0);
  state.pickBox.style.left = `${x}px`;
  state.pickBox.style.top = `${y}px`;
  state.pickBox.style.width = `${w}px`;
  state.pickBox.style.height = `${h}px`;
});

overlay.addEventListener("mouseup", (e) => {
  if (!state.picking || !state.pickStart || !state.pickBox) return;
  const rect = state.pickBox.getBoundingClientRect();
  const parentRect = overlay.getBoundingClientRect();
  const x = Math.round(rect.left - parentRect.left);
  const y = Math.round(rect.top - parentRect.top);
  const w = Math.round(rect.width);
  const h = Math.round(rect.height);
  state.pickStart = null;
  state.pickBox.remove();
  state.pickBox = null;
  logPickRect(x, y, w, h);
});

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") enablePicking(false);
});

btnPick.addEventListener("click", () => enablePicking(!state.picking));

pdfSel.addEventListener("change", () => {
  state.page = 1;
  loadPdf(pdfSel.value);
});
btnPrev.addEventListener("click", () => { state.page = Math.max(1, state.page - 1); pageInp.value = state.page; render(); });
btnNext.addEventListener("click", () => { state.page = Math.min(state.doc?.numPages || 999, state.page + 1); pageInp.value = state.page; render(); });
pageInp.addEventListener("change", () => { state.page = Math.max(1, Number(pageInp.value || 1)); render(); });

rebuildSelect();
if (state.pdf) {
  loadPdf(state.pdf);
}

