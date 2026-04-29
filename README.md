# Trash Manager Revamped

Revamped plenty of things on this mod. Which is still a work-in-progress and under testing.. Taken over by Stormbox as the main developer for Trash Manager: <https://steamcommunity.com/sharedfiles/filedetails/?id=1788913474>

# Trash Manager Revamped — Full Mod Guide

## Overview

**Trash Manager Revamped** is an Avorion quality-of-life mod that helps players manage large inventories by letting them **mark items as trash in bulk** using targeted filters, then sell those marked items through the game’s normal trash-selling flow at the appropriate merchants.

The mod is designed to:

- Reduce inventory cleanup time.
- Provide better control over what gets marked.
- Support both **private** and **alliance** inventory workflows.
- Stay compatible with Avorion’s existing merchant/trash pipeline instead of replacing it.

---

## Core Concept

The mod does **not** instantly destroy items and does **not** force immediate sales.

Instead, it marks selected items with Avorion’s trash flag so they can be sold later using merchant interactions (for example, with “Sell Trash” behavior where applicable). This gives players safe, reversible bulk sorting before selling.

---

## What the Mod Adds (Latest Confirmed Working Build)

## 1) Bulk Trash Marking Interface

The Trash Man UI allows filtered mass-marking by:

- **System rarity threshold**
- **Turret rarity threshold per material**
  - Iron
  - Titanium
  - Naonite
  - Trinium
  - Xanion
  - Ogonite
  - Avorion
- **Tech level filter (optional)**
  - Minimum tech filter
  - Maximum tech filter

This allows fine-grained selection of low-value items while preserving high-value or progression-critical loot.

---

## 2) Tech Level Filtering (Optional)

A major Revamped feature is optional filtering by item tech level.

### How it works

- `Min` tech: ignore items below selected minimum.
- `Max` tech: ignore items above selected maximum.
- Tech filtering is active by default with range 1–52.
- Players can optionally customize Min/Max values to narrow what gets marked.

### Supported behavior (current confirmed implementation)

For tech extraction, the script checks:

1. Turret/template `averageTech` when available.
2. Item custom value key `"tech"` as fallback when present.

This supports both vanilla-style items and modded items that store tech metadata.

### Why this matters

- Lets players preserve high-tech modded blueprints and late-tier drops.
- Prevents accidental trash marking of tech-critical items.
- Supports extended tech scenarios up to **52**, which is useful for modded/factory blueprint ecosystems.

---

## 3) Private and Alliance Inventory Support

The mod supports two workflows:

- **Private inventory mode** (player inventory)
- **Alliance inventory mode** (alliance storage path)

Alliance mode requires appropriate permissions and uses Avorion privilege checks.

If permissions are missing, the user receives a clear feedback message rather than silent failure.

---

## 4) Mark, Unmark, and Preview Actions

### Mark Selected

Marks all inventory items that match the configured filters as trash.

### Unmark All

Clears trash flags from marked items in the selected inventory context (private/alliance), allowing a full rollback when needed.

### Preview (Confirmed Latest Flow)

Preview runs the same active filters without changing inventory state and returns:
- how many items would be marked
- which scope is active (`private` or `alliance`)

The preview label updates in the Trash Man UI with this result so players can verify filters before committing mark operations.

---

## UI Layout and Design Notes

Confirmed current layout includes:

- Larger window for better readability and future feature growth.
- Tech level controls moved to a dedicated section under the action buttons.
- Cleaner visual hierarchy:
  1. System filter
  2. Turret-by-material filters
  3. Alliance toggle
  4. Action buttons
  5. Tech-level filter section

Default displayed tech labels are set to:

- **Min: 1**
- **Max: 52**

This matches expected practical limits for modded blueprint environments.

---

## Safety Rules in Marking Logic

The mod intentionally avoids marking:

- Favorite items (`item.favorite`)
- Already trashed items (`item.trash`)
- Items that fail selected rarity/material/tech checks
- Vanilla item types excluded by filter logic where applicable

This minimizes accidental cleanup mistakes.

---

## Compatibility Philosophy

Trash Manager Revamped is built as a QoL extension to Avorion’s existing inventory and merchant systems.

It aims for practical compatibility with larger mod collections by:

- Keeping behavior centered on native trash flags.
- Using clear, guarded server-side callable flows.
- Avoiding invasive replacement of unrelated mechanics.

For large all-in-one packs (e.g., integrated overhauls), maintaining parity between shared scripts helps reduce divergence and maintenance overhead. However, this mod is already implemented into `Cosmic Overhaul`.

---

## Typical Usage Workflow

1. Open Trash Man UI.
2. Choose system rarity threshold.
3. Configure turret rarity thresholds by material.
4. Enable Alliance mode if operating on alliance inventory.
5. Optionally set Min/Max tech filters.
6. Press **Mark Selected**.
7. Visit relevant merchant flow and sell trash.
8. If needed, press **Unmark All** to revert.

---

## Who This Mod Is For

- Players with large late-game inventories.
- Multiplayer groups managing alliance loot pools.
- Modded campaigns generating high-volume drops/blueprints.
- Users who want controlled cleanup without manual item-by-item sorting.

---

## Current Development Status

The currently documented/implemented state is the **confirmed working preview implementation** that has been validated in-game.

Planned roadmap expansions (presets, advanced class include/exclude controls, additional confirmation flows, and later milestones) are intentionally deferred until after player feedback.

## Summary

Trash Manager Revamped turns inventory cleanup from a repetitive manual task into a controlled, filter-driven workflow.  
It preserves player control, supports alliance operations, includes a confirmed working preview path, and adds tech-aware filtering to better match modern modded Avorion playthroughs.
