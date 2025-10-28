# Game Mode Changes - Mining Experience (REVISED)

## Core Concept

The player is in a mining world where they can extract dirt to mine different types of ores and gems. The objective is to find the Bitcoin before AI competitors do. Players earn fiat money by selling mined ores at the surface shop.

**Win Condition**: Find the Bitcoin ore before AI competitors  
**Loss Condition**: AI competitors find the Bitcoin first  
**No time limit** - pressure comes from AI competition

---

## Mining Mechanics

### Tool System
Instead of shooting, players use mining tools with different capabilities:

- **Basic Pickaxe** (starter tool)
  - 1x1 mining area
  - Moderate speed
  
- **Iron Drill** (shop upgrade)
  - 2x2 mining area
  - Faster mining speed
  
- **Diamond Drill** (shop upgrade)
  - 3x3 mining area
  - Fastest speed
  - Reveals ore types in nearby quadrants
  
- **Explosive Charges** (consumable)
  - Large area destruction (5x5)
  - Destroys some ore value as trade-off

### ~~Stamina System~~ (REMOVED)
**Removed for better game flow** - Mining is only limited by tool cooldowns, allowing continuous action without frustrating regeneration waits.

### Depth Progression
The mining world is structured in vertical layers within the **same world space** (not parallel shafts):

**Depth Layers 0-5 (Surface)**
- 80% Dirt, 15% Coal, 5% Iron
- Easy to mine
- Low value ores

**Depth Layers 6-10 (Mid-depth)**
- 60% Dirt, 20% Coal, 10% Iron, 5% Copper, 5% Silver
- Moderate mining difficulty
- Medium value ores

**Depth Layers 11-15 (Deep)**
- 50% Dirt, 15% Coal, 15% Iron, 10% Gold, 5% Emerald, 5% Diamond
- Harder to mine
- High value ores

**Depth Layers 16-20 (Bitcoin Zone)**
- 40% Dirt, 20% Iron, 15% Gold, 10% Diamond, 14% Silver, 1% Bitcoin Ore
- Hardest to mine
- Bitcoin spawns here

---

## Ore & Resource System

### Ore Types (by rarity)

**Common**
- Dirt (no value, filler)
- Coal (low value)
- Iron (medium value)

**Uncommon**
- Copper
- Silver

**Rare**
- Gold
- Emerald
- Diamond

**Ultra Rare**
- Bitcoin Ore (the objective)

### Ore Properties
- **Base Value**: Fiat earned when sold
- **Spawn Weight**: Determines rarity
- **Depth Multiplier**: Value increases at deeper layers (e.g., Gold at depth 15 worth more than Gold at depth 10)
- **Visual Effects**: Unique textures and particle colors

### Ore Vein System
When a player mines a valuable ore, nearby quadrants (3x3 radius) have a **40% chance** of containing the same ore type (realistic vein distribution). This encourages strategic exploration and creates natural ore clusters.

---

## AI Competition System

### Competing Miners - Same World Mechanics
AI competitors mine in the **same world space** as the player:

- **Competitor Names**: "Satoshi AI", "Hash Hunter", "Block Breaker"
- **Visual Presence**: Semi-transparent AI miner entities visible mining nearby blocks
- **Shared Bitcoin**: All miners race to find the same Bitcoin ore in depth 16-20
- **Instant Loss**: If any AI miner collects the Bitcoin ore, player loses immediately

### AI Behavior
- AI miners dig downward at a steady pace in the same grid
- **Difficulty Scaling**: AI gets 10% faster each game level (capped at 130% speed at level 16+)
- **Rubber-banding**: If player falls 5+ layers behind, AI slows by 15% to keep competitive
- **Smart Pacing**: If player dominates (5+ layers ahead), AI speeds up by 15% to maintain challenge

### AI Personalities (Distinct Behaviors)

**Satoshi AI** (Balanced)
- Consistent, methodical pace
- Mines straight down with occasional horizontal exploration
- 100% base speed

**Hash Hunter** (Fast & Erratic)
- 110% base speed but makes mistakes
- Occasionally backtracks or mines inefficiently
- More aggressive but less reliable

**Block Breaker** (Late Game Threat)
- 80% speed at depth 0-10
- Accelerates to 130% speed at depth 11+
- Dangerous if you're slow early

### Pressure Feedback (No Timer!)

Instead of a countdown timer, players get **contextual warnings**:

**AI Progress Stages**:
- 0-30% complete: "Competitors are still at the surface"
- 30-60% complete: "⚠️ Hash Hunter is catching up!"
- 60-85% complete: "🚨 URGENT: Satoshi AI at depth 15!"
- 85%+ complete: "💀 CRITICAL: Competitors near Bitcoin!"

**Visual Feedback**:
- Progress bar comparing player depth vs AI depth (side-by-side)
- Mini-map showing relative positions (optional toggle, OFF by default)
- Screen shake when AI makes breakthroughs
- Periodic notifications: "Satoshi AI found Gold!"

**Optional Time Estimate** (information, not a limit):
- Show "Estimated time until AI victory: ~3 minutes"
- Updates dynamically based on AI progress
- Helps players gauge urgency without hard cutoff

---

## Level Shop

### Shop Access: Surface Return
Players must **climb back to depth 0 (surface)** to access the shop:
- AI miners continue making progress while player returns to surface
- Creates strategic decision: "Return now to sell/upgrade, or push deeper?"
- Makes **Auto-Seller upgrade** extremely valuable (sell without returning)

### Shop Structure
Players spend fiat earned from selling ores to buy upgrades.

### Temporary Upgrades (Lost on Level Failure)

**Boosts**
- **AI Slowdown** - Slow AI competitors by 15% for 60 seconds
- **Speed Boost** - Increase movement/mining speed by 25%
- **Fortune Multiplier** - Ore values worth 25%/50%/100% more this run
- **Auto-Seller** - Automatically sells collected ores without returning to surface

**Tools**
- **Ore Scanner** - Highlights valuable ores within radius
- **Sabotage Kit** - Slow all competitors by 20% for 90 seconds
- **Explosive Charges** (x5) - Consumable large-area mining

### Permanent Tools (Carry Over on Success)

**Mining Tools**
- **Iron Drill** - 2x2 mining area (persists if level completed)
- **Diamond Drill** - 3x3 mining area (persists if level completed)

**Progression Upgrades**
- **Backpack Upgrades** - Carry more ore before needing to sell
- **Tool Speed** - Permanently reduce mining cooldown by 10%/20%/30%

### Strategic Choice
```
Spend fiat on temporary boosts to guarantee this level's success?
OR
Save fiat for permanent upgrades that help all future game levels?
```

---

## Level Completion Flow

### Victory (Bitcoin Found)

**Level Complete Screen Shows**:
- Bitcoin found animation
- Stats: Total ores mined, fiat earned, depth reached
- AI progress at time of victory (competitive ranking)
- Bonuses earned (see below)

**Player Options**:
- **Continue to Next Level** - Keeps permanent shop upgrades, proceeds immediately
- **Return to Main Menu** - Sells all remaining ores, resets shop upgrades

**Progression Rewards**:
- **Speed Bonus**: Faster completion (AI < 50% progress) = 2x fiat multiplier
- **Combo System**: 
  - 3x same ore type consecutively = 1.5x value multiplier
  - 5x same ore = 2x value multiplier
  - 10x same ore = 3x value + special particle effect
- **Perfect Run**: Finding Bitcoin with AI below 50% progress = extra 1000 fiat
- **Collection Bonus**: Percentage of total ores found gives bonus fiat

### Defeat (AI Finds Bitcoin First)

**Game Over Screen Shows**:
- AI competitor winning animation ("Hash Hunter found the Bitcoin first!")
- Partial earnings from ores already sold at surface
- Stats: Depth reached, AI progress comparison

**Consequences**:
- **Lose all shop upgrades** (temporary AND permanent tools)
- Earn partial fiat from sold ores only (ores in backpack lost)
- Return to level select to retry

---

## Level Structure

### Quadrant System
Levels are composed of destroyable quadrants in the same world grid:

**Quadrant Types**:
- **Dirt Blocks** (majority) - No ore drops, easy to destroy, low health
- **Ore Blocks** - Contain ores based on depth layer spawn rates, health varies by ore type
- **Hard Rock** - Takes more hits, may contain rare ores (future enhancement)
- **Vein Blocks** - Connected ore clusters created by vein propagation system

### World Generation
- Procedurally generated each game level (same seed for fair competition)
- Depth layer system (0-20) determines ore distribution
- Bitcoin ore spawns at depth 16-20 with 1% spawn rate
- Ore veins create realistic clusters (40% propagation in 3x3 radius)

### Destruction Mechanics
- Reuse existing QuadrantBuilder fracture system
- Block health based on ore type: dirt (1x) < coal (1.2x) < iron (1.5x) < diamond (2.5x) < Bitcoin (3x)
- Particle effects show ore type when destroyed (use ore particle_color)
- Visual cracks appear before block breaks using existing PolygonFracture lib

---

## Special Events & Features

### Random Events

**Cave-ins** (5% chance every 30 seconds)
- Random quadrants collapse during mining
- Creates new paths and shortcuts
- Can reveal hidden ore veins
- Affects both player and AI progress

**Ore Rush** (10% chance every 60 seconds)
- Temporary 30-second event
- All ore values doubled
- Audio/visual cues for activation
- Rush timer displayed on HUD

**Lucky Streak** (3% chance every 45 seconds)
- Next 5 ores mined guaranteed rare or better
- Rare random occurrence
- High-value reward for lucky players

**Max 1 event active at a time** to prevent chaos.

### Risk/Reward Mechanics

**Deep Dive Challenge**
- Optional strategy: Ignore shallow ores, rush to depth 15+
- Higher risk: Harder blocks, AI gets closer
- Higher reward: Better ore density, speed bonus if successful

**Market Events**
- Economic events affect ore prices dynamically
- Market Crash: Ore values drop 25%
- Market Boom: Ore values increase 50%
- Linked to existing EconomicEventsManager system

### Bitcoin Proximity Ping (NEW)
When player reaches depth 11-15 (within 5 layers of Bitcoin zone):
- Subtle audio ping plays periodically
- Ping frequency increases as player gets closer to depth 16
- Creates excitement without spoiling exact Bitcoin location
- Helps orient player toward Bitcoin zone

---

## Meta Progression

### Game Level Progression

**Level 1-5: Dirt Quarry**
- Tutorial zone
- Basic ores (coal, iron, copper)
- AI at 70% base speed
- Learn mechanics

**Level 6-10: Crystal Caves**
- More gems appear
- AI at 100% base speed
- Introduces ore veins

**Level 11-15: Deep Mines**
- Gold/diamond focus
- AI at 120% base speed
- Harder blocks

**Level 16+: Bitcoin Depths**
- Highest ore concentration
- AI at 130% base speed (capped)
- Expert challenge

### Difficulty Modes (Optional)

**Relaxed Mode**
- AI at 70% speed
- Learn mechanics without pressure

**Competitive Mode** (Default)
- AI at 100% speed
- Normal challenge

**Hardcore Mode**
- AI at 130% speed (immediately)
- More aggressive warnings
- Expert players only

---

## Integration with Existing Systems

### Bitcoin Network
- Mining Bitcoin ore triggers `BitcoinNetwork.mine_block()`
- Links to `MainEventBus.level_completed` signal
- Economic events affect shop prices

### Economic System
- Ore prices affected by `EconomicEventsManager`
- Shop uses existing `Constants.CurrencyType.FIAT`
- Market dynamics create strategic selling decisions

### Weapon System Adaptation
- Reuse `FireWeaponComponent` structure for `MiningToolComponent`
- Tool fire rate = mining cooldown
- Bullet damage → mining power conversion

### QuadrantBuilder Adaptation
- Modify to spawn ore-type quadrants based on depth
- Use existing fracture system for destruction
- BlockCore health varies by ore hardness multiplier

### Item Drops System
- Leverage existing `item_drops` addon
- Create `OrePickupResource` similar to `CurrencyPickupResource`
- Ores auto-collect when player is near them (like currency pickups)
- Auto-Seller upgrade interfaces with pickup system to sell without returning to surface

### Save System
- Track shop upgrades separately from skill tree
- Clear temporary upgrades on failure
- Save permanent tool upgrades on success

---

## UI/UX Elements

### In-Game HUD (Simplified)

**Primary Displays**:
- **Depth Comparison Bar** - Player depth vs AI depth side-by-side (most important)
- **Ore Counter** - Total ores collected (detailed breakdown in pause menu)
- **Current Depth Indicator** - Shows which layer (0-20) with Bitcoin zone highlight
- **Fiat Earned** - Running total for current run

**Mini-Map** (Optional, OFF by default):
- Shows player position
- AI miner positions (ghosted)
- Ore vein locations (if scanner equipped)
- Bitcoin zone highlight (depth 16-20)

### Audio Cues

**Mining Sounds**:
- Different sounds per ore type (from OreDetails resource)
- Satisfying impact feedback
- Rare ore "ding" sound for Gold/Emerald/Diamond

**Music Progression**:
- Calm music at surface (depth 0-5)
- Tension builds at mid-depth (6-10)
- Urgent music at deep levels (11-15)
- Critical intensity in Bitcoin zone (16-20)
- Triumphant theme when Bitcoin found

**AI Competition**:
- Audio stings when AI makes progress
- Warning sounds for urgent AI stages (60%+, 85%+)
- Competitor breakthrough notifications
- Bitcoin proximity ping (depth 11-15)

---

## Summary of Key Improvements

✅ **No arbitrary time limit** - Pressure from dynamic AI competition  
✅ **No stamina frustration** - Tool cooldowns only, continuous action  
✅ **Same-world competition** - See AI miners in your grid, shared Bitcoin  
✅ **Strategic depth** - Tool choices, upgrade decisions, surface return timing  
✅ **Roguelite elements** - Carry-over on success, lose-all on failure  
✅ **Visual competition** - See AI miners, track progress dynamically  
✅ **Organic difficulty scaling** - AI speeds up with game level (capped at 130%), rubber-bands for fairness  
✅ **Player agency** - Sabotage tools, market timing, exploration strategies  
✅ **Replayability** - Procedural generation, random events, multiple paths to victory  
✅ **Thematic immersion** - Mining competition feels more meaningful than racing clock  
✅ **Combo rewards** - Strategic mining patterns for value multipliers  
✅ **Bitcoin proximity feedback** - Audio ping creates excitement without spoiling location
