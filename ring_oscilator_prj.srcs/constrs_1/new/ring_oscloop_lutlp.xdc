# -----------------------------------------------------------------------------
# DRC LUTLP-1 (bitgen): pierścień = celowa pętla kombinacyjna.
# Tylko Implementation (w .xpr: UsedIn bez synthesis) — na etapie syntezy
# komórki sieci nie są jeszcze gotowe pod get_nets/get_cells.
# Bez foreach/if w XDC ([Designutils 20-1307]).
# Wszystkie segmenty sieci podłączone do hierarchii *u_ring* (instancja pierścienia).
# -----------------------------------------------------------------------------

set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -segments -of_objects [get_cells -hierarchical -filter {NAME =~ *u_ring*}]]
