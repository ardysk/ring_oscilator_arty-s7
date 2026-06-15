## -----------------------------------------------------------------------------
## Floorplan — osobny plik: edytuj po pierwszym place, gdy znasz sito SLICE.
## -----------------------------------------------------------------------------
## 1) Otwórz implemented design → Floorplanning → zaznacz u_ring → wstaw Pblock.
## 2) Zamień zakres poniżej na rzeczywisty prostokąt z chipa (7Z020).
## 3) Odkomentuj create_pblock ... lub użyj TCL z saved constraints z Vivado.

## PRZYKŁAD (ZAWSZE ZWERYFIKUJ WSPÓŁRZĘDNE — to tylko szablon):
# create_pblock pblock_ring
# resize_pblock [get_pblocks pblock_ring] -add {SLICE_X40Y50:SLICE_X55Y65}
# add_cells_to_pblock [get_pblocks pblock_ring] [get_cells u_ring]

## Sztywne LOC per slice — użyj po wygenerowaniu listy komórek z Technology Map Viewer:
# set_property LOC SLICE_X44Y58 [get_cells u_ring/g_inv[0].*]

## Jeśli narzęcje łączą etapy, rozważ jedną komórkę na etap w osobnym module
## i przypnij każdy LUT przez UCF/XDC (advanced).
