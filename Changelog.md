# Trash Manager Revamped — Changelog

---

## [v2.0.0] — 2026-08-28

### New Features

#### Item Type Toggles
- Added three independent enable/disable checkboxes at the top of the UI:
  - **Turrets** — controls whether standard turret items are candidates for trash marking.
  - **Systems** — controls whether system upgrade items are candidates.
  - **Templates** — controls whether turret blueprint (template) items are candidates.
- All three default to enabled, matching previous behaviour when first opened.
- These toggles interact with all operations: Mark, Unmark Filter, and Preview.

#### Turret Template (Blueprint) Support
- Turret templates (`TurretTemplate` item type) are now explicitly handled as a first-class item category.
- Templates respect the per-material rarity thresholds set in the turret filter rows.
- Templates are tracked separately in Preview and Mark feedback messages.
- The `Templates` item type toggle provides independent enable/disable control.

#### Consolidate Inventory to Vault
- Added a new **Consolidate Inventory to Vault** full-width button in the UI.
- Instantly transfers all unequipped, non-favorite turrets, turret blueprints (templates), and system upgrades from the player's **private inventory** directly into the **Alliance Vault**.
- Requires the player to be a member of an alliance with a reachable alliance inventory.
- Items marked as favorites are always skipped and remain in the player's private inventory.
- If the Alliance Vault is completely full, excess items are safely dropped near the ship in space (via `addOrDrop`) rather than lost.
- The live inventory stats bar is automatically refreshed after the operation completes.
- The button is always a one-way private→vault transfer regardless of the Alliance mode toggle state.
- Chat feedback includes a count of items moved and a separate notice if any were dropped due to vault capacity.

#### Unmark by Filter
- Added a new **Unmark Filter** button alongside the existing action buttons.
- Unlike **Unmark All** (which clears every trash flag unconditionally), **Unmark Filter** only untrashes items that currently match the active filter configuration.
- Useful for surgical rollback: undo a specific material tier or rarity sweep without touching other marked items.
- Works for both private and alliance inventories.

#### Persistent Filter Presets (3 Slots)
- Added a **Filter Presets** panel at the bottom of the UI with three save/load slots.
- **Save #N** captures the complete current filter state: item type toggles, system rarity, all per-material turret rarity settings, alliance toggle, min/max tech bounds.
- **Load #N** restores a saved preset, updating all UI controls instantly.
- Presets are persisted server-side per player (`player:setValue`) and survive across game sessions, ship changes, and server restarts.
- Preset slot status is displayed next to each button: grey `- empty -` when unpopulated, green `* Saved` when a preset exists.
- Slot status is refreshed automatically when the Trash Man window is opened.
- All save/load operations report success or failure via chat message.

#### Live Inventory Stats Bar
- A stats bar at the top of the window now shows real-time inventory information:
  `Inventory: N items  |  N trash  |  N favorites`
- Stats are automatically refreshed after every Mark, Unmark, Unmark Filter, and Preview operation.
- Stats are also fetched from the server when the window is first opened.
- When Alliance mode is active, stats reflect the alliance inventory.

#### Detailed Preview Breakdown
- The **Preview** result label now shows a category breakdown:
  `Preview (private): 42 items -> 30 turrets, 8 systems, 4 templates`
- Color coding: amber/yellow when items would be marked; grey when nothing matches.
- Scope (private or alliance) is always displayed in the preview result.
- Preview no longer marks anything — it remains a pure dry-run.

#### Improved Alliance Feedback
- Alliance operation error messages are now more descriptive and consistently prefixed with `[Trash Manager]` for easy log filtering.
- Shared `resolveAlliance()` helper centralises alliance validation logic across all server functions.

### Bug Fixes

#### Rarity Off-by-One (Systems)
- **Fixed:** Selecting "Petty" in the Systems combobox previously resulted in an internal rarity threshold of `-1`, which meant no systems were ever marked when "Petty" was selected.
- The offset has been corrected from `selectedIndex - 2` to `selectedIndex - 1`:
  - `None` (index 0) → threshold `-1` → no systems marked ✓
  - `Petty` (index 1) → threshold `0` → marks Petty systems ✓
  - `Common` (index 2) → threshold `1` → marks Petty + Common systems ✓

#### Rarity Off-by-One (Turrets)
- **Fixed:** Selecting "Petty" in any material rarity combobox previously resulted in an internal threshold of `-1`, meaning Petty turrets were never marked when "Petty" was the selected rarity.
- The offset has been corrected from `selectedIndex - 1` to `selectedIndex`:
  - `Petty` (index 0) → threshold `0` → marks Petty turrets ✓
  - `Common` (index 1) → threshold `1` → marks Petty + Common turrets ✓

### Code Quality & Architecture

- Removed bespoke `getItemTechLevel()` in favour of `SellableInventoryItem.tech`, which is already computed by the vanilla library for Turrets and TurretTemplates.
- Extracted shared `resolveAlliance(player)` helper to eliminate duplicated nil-guard logic across all four alliance server functions.
- `processTrashInInventory()` now returns a counts table `{turrets, systems, templates, total}` instead of a plain integer, enabling downstream breakdown reporting.
- Added `processUnmarkFilteredInInventory()` — the selective-unmark traversal function.
- Added `getInventoryStats(inv)` — inventory statistics aggregator used by the stats bar.
- Added `serializeUIState()` / `applyUIState(data)` for preset serialisation/deserialisation.
- Added `savePlayerPreset()` / `loadPlayerPreset()` with `pcall` guards for safe persistent storage.
- All new server callables correctly use `callable(TrashMan, "functionName")` — namespace-bound.
- All `%_t` localisation calls remain strictly inside function bodies (never global scope).
- Window enlarged from 460×540 to 510×775 to accommodate new UI sections.

### UI Changes

- **Window size:** 460×540 → 510×775
- **New top section:** Inventory stats bar
- **New section:** Item Types to Mark (Turrets / Systems / Templates checkboxes)
- **New button:** Unmark Filter (between Unmark All and Preview)
- **New bottom section:** Filter Presets with 3 save/load slots
- Visual separator frames added between major sections for improved readability
- Preview label colour is now context-sensitive (amber when matches found; grey for empty results; blue when preset is loaded)

---

## [v1.3.2] — Previous Release

- Stable working baseline taken over by Stormbox.
- Turret rarity filtering per material (Iron through Avorion).
- System upgrade rarity filtering.
- Optional tech level min/max filtering (range 1–52).
- Private and alliance inventory modes.
- Preview (dry-run count) operation.
- Unmark All operation.
- Favorite-item protection.
