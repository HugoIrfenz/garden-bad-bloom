# Garden: Bad Bloom 0.1.9 player checks

Open a newly earned chest to try the new run upgrades. A chest already open or opening in an older save still offers Thorn Edge. Chests offer two upgrades when there is room beside the recovery card. Equipment and pocket rewards keep their third slot when offered.

| Reward | Effect per pick | Maximum rank |
| --- | --- | --- |
| Thorn Edge | +2 flat damage | 4 |
| Quickstep | 6% shorter Dodge recovery | 3 |
| Quickhands | 7% shorter basic attack recovery | 3 |
| Wildstride | 5% faster walking | 3 |
| Petal Aegis | Blocks up to 5 damage on the first qualifying hit in each combat room | 2 |
| First Bloom | +1 class pip when entering a combat room, up to your usual meter limit | 2 |
| Steady Spell | 6% shorter Skill recovery for Vivianne, Nixia, Virelia, and Zaria | 3 |
| Velvet Purse | 12 Petals immediately | Immediate payout |

- Open a fresh chest, interrupt the game once while it opens, and resume. The cards and their order should stay consistent. Claim an upgrade, then open **Pause → Upgrades** to see its rank and cumulative effect.
- With **Petal Aegis**, check the shield icon by the class pips. Let a direct hit through and look for the petal burst, sound, and dimmed icon. The effect leaves at least 1 incoming damage. Resume after spending it to check that it stays spent in that room and recharges in the next fight.
- Check **First Bloom** with an incomplete class meter when walking through the next combat door. Resume after entering and check for a single grant. Try **Quickhands** with Cursed Lily to check that both strikes still play.
- Beat Bloomheart and choose **Continue into Garden Without End**. Check the floor arrival, HUD, next door, Pause, and Run History. In Bahasa Indonesia the player-facing name is **Taman Tanpa Ujung**.

## Upgrade artwork

The built-in imagegen tool created the RGBA [run upgrade atlas](../assets/art/items/run_upgrades.png). It used the second forge atlas as the style reference. The Thorn Edge card uses the existing dagger artwork.

```text
Create one original inventory sprite atlas for Garden: Bad Bloom, exactly seven different icons arranged in a 4 columns by 2 rows grid, leave the last (bottom-right) cell completely empty. Each icon single, cleanly separated, equal size with large true transparent gutters, centered exactly at its cell center. Reference attached is STYLE ONLY, match the material lighting, warm aubergine crisp contour, detailed yet precisely fine-pixel chibi anime botanical fantasy inventory art. Readable down to 40 pixels. Row 1 L to R: 1 Quickstep, a single cropped mint-green petal spur strapped to an old small brass heel plate, compact curved feather silhouette tilted upward; 2 Quickhands, two overlapping slim leather gardener gloves with deep ruby bands and gold stitching, knuckles elegantly tucked, lively diagonal silhouette; 3 Wildstride, an amethyst sprig of two boot-like wild leaves coiled around a small copper seed compass with dark green center, not a shoe; 4 Petal Aegis, an ivory-copper tiny domed shield in the shape of a rose cross-section, one blue central stone, brass trim, robust shield silhouette. Row 2 L to R: 5 First Bloom, luminous late-pink dewy flower bud opening in a golden cup of two leaves with an orange seed at its core, small magical charging gem feel; 6 Steady Spell, a short ornate moon-purple staff-pendulum with one lavender crystal and bronze circular orbit, diagonally tilted, deliberate refined outline; 7 Velvet Purse, plump cinched rose-purple Victorian pouch with two antique gold Petals visible tucked beneath its string and subtle floral embroidery; last cell is EMPTY, no eighth icon. Full genuinely transparent RGBA alpha background everywhere including margins and spaces; no frames, shadows beyond silhouettes, text, labels, numbers, outlines around cells or giant pixels. These will be small reward card icons presented on dark cream paper; use finely stepped outlines, coherent warmth and matte highlights, keep all seven immediately distinct. Ultra-wide about 2:1.
```
