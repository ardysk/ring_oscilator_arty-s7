# Vivado diagramy (BD) → interaktywny viewer

To o co prosisz (klikany diagram jak w Vivado) jest najłatwiejsze, gdy źródłem są **prawdziwe eksporty z GUI Vivado**:

- `File → Export → Export Diagram...` w oknie Block Design
- format: **PDF** (albo SVG, jeśli Vivado pozwala)

## Jak użyć w tym repo

1. W Vivado otwórz projekt `ring_oscilator_prj.xpr`.
2. Otwórz BD `mb_ro_system`.
3. Zrób eksport:
   - `docs/vivado_diagrams/mb_ro_system.pdf`
   - (opcjonalnie) `docs/vivado_diagrams/ro_axi_0.pdf` / inne poddiagramy jeśli robisz „schodzenie” po hierarchii
4. Otwórz `docs/vivado_diagrams/viewer.html` w przeglądarce i dodaj mapowania w `docs/vivado_diagrams/maps.js`.

## Dlaczego nie generuję tego w batch TCL?

W Vivado 2018.3 komendy typu `show_schematic` działają tylko w IDE (GUI), a eksport „BD canvas” do PDF nie ma stabilnego odpowiednika do automatyzacji w batchu.
Dlatego generacja PDF/SVG musi iść przez GUI, a my automatyzujemy **warstwę interaktywności** (klik/hover) po stronie HTML.

