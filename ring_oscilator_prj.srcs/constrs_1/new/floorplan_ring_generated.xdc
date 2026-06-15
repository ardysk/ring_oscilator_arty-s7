## -----------------------------------------------------------------------------
## Spartan-7 / zmiana części: NIE odwzorowywać starych CLOCKREGION z Zynq.
## Wygeneruj ponownie po routed DCP dla ro_top_arty:
##   vivado -mode batch -source scripts/gen_floorplan_pblock.tcl
## Albo ustaw constrain w GUI (Floorplanning).
## -----------------------------------------------------------------------------
## (pusta — aby nie wymusić przestarzałego Pblock pod Zed)
