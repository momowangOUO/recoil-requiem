# Quest props v1

Generated with the built-in imagegen tool on 2026-09-21 for Recoil Requiem. The returned RGBA source is preserved unchanged as `quest_props_v1.png` (2172 × 724). No external reference image was supplied. No third-party image was copied. This records provenance, not a legal exclusivity claim.

The generator returned a larger sheet than the requested size. Runtime uses three `Sprite3D.region_rect` crops; the PNG is not repainted, stretched or destructively split:

| Stable action ID | Source rectangle x,y,w,h | Runtime width |
|---|---|---|
| tools | 49,118,627,526 | 28 logical pixels |
| records | 760,183,652,461 | 28 logical pixels |
| luggage | 1493,252,634,399 | 28 logical pixels |

These objects replace default lever visuals only on the current campaign. They have no new collision. Feet use the authored action position; shaded paper sits just behind the gameplay plane, nearest sampled. Collected tools disappear, the read ledger remains available, and luggage returned upstairs disappears from its previous location. The corresponding event IDs and quest consequences are unchanged.

## Generation prompt

Create a production pixel-art game prop sprite sheet, transparent RGBA background, landscape 1536x512. Three equal 512x512 cells in ONE ROW, separated by ample transparent padding, no labels or text, no floors, no cast shadows outside the objects. Each object occupies central 330x300 pixels and sits on same baseline y430. Left cell: compact open dark red wooden and brass mechanic's tool chest, clearly visible wrench and pliers inside, sturdy carry handle folded down. Center cell: opened ivory maintenance ledger with a dark red hardback cover lying angled on a LOW small wooden reading stand, brass corner protectors, abstract ink marks but no legible words; entire object similarly squat and comparable size to other two. Right cell: closed dark brown leather travelling suitcase, two straps, brass latches, top carrying handle, no label. Gothic Victorian steampunk monastery, vampire game, restrained old brass ivory burgundy palette. Finely authored PIXEL ART with clean stepped edges, intentional large pixel clusters, dark outline, 4 tone shading, not vector not smooth painted concept art. View from side with a slight view of tops, suitable as 2D paper props on a side scrolling 3D floor. Object height at runtime about half of a 42px tall character. Make each cell self-contained with no shared ornaments, nothing overlaps adjacent cell. Background truly transparent.
