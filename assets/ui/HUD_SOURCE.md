# Combat atlas v1

2026-09-11, imagegen source `exec-2c9377dd-f29e-4e4b-a7cd-e47fd8ff2462`, saved as combat_atlas_v1.png.

Brief: Gothic vampire/steampunk HUD, bone-silver medallion, full/empty crimson life crystals and distinct right-facing revolver, shotgun, SMG; six isolated assets in a 3×2 sheet, no text. Readable at 56/32/22 pixels. The transparency attempt contained baked checkerboard, so the accepted edit replaced every backdrop pixel with flat #FF00FF.

CombatHud keys magenta, splits three columns at row int(height*.585), trims alpha bounds and caches the six icons. Native-resolution UI uses linear filtering. World textures retain nearest sampling. Runtime numbers and reload progress are never baked into the art.
