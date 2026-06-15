# Schematy Vivado (interaktywny viewer)

Otworz lokalnie: `index.html` (wymaga `svg-bundle.js`).

## GitHub Pages

1. Repo **Settings → Pages**
2. Source: branch `main`, folder **`/docs`**
3. Po deploy: https://ardysk.github.io/ring_oscilator_arty-s7/vivado_schematics/index.html

## Nawigacja

- Klik w **zolty blok** lub **nazwe modulu** na schemacie → otwiera podmodul
- Przycisk **← Wstecz** lub breadcrumb → powrot wyzej
- Zoom: scroll / +/- / Dopasuj

## Regeneracja po eksporcie SVG z Vivado

```powershell
python scripts\embed_vivado_svgs.py
```
