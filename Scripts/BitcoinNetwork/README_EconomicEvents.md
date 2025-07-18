# Economic Event Pe4. **Persistence**: When the game is saved, the current active event and its remaining duration are stored
5. **Restoration**: When the game is loaded, any active event is restored with its remaining duration
6. **Expiration**: When an event's duration reaches 0, it expires and all effects are automatically reverted
7. **System Reset**: All affected systems (upgrade costs, etc.) return to their original values
8. **New Event Selection**: After expiration, the system tries to pick a new eventstence System

## Overview

The Economic Event system now supports full persistence across game sessions. Events have durations measured in Bitcoin blocks, and the system automatically tracks and restores their state when the game is loaded.

## Key Features

- **Block-based Duration**: Events last for a specified number of Bitcoin blocks
- **Automatic Persistence**: Events are saved and restored across game sessions
- **Duration Tracking**: As new blocks are mined, event duration automatically decreases
- **No Overlapping Events**: Only one event can be active at a time
- **Automatic Event Cycling**: When an event expires, the system tries to pick a new one
- **Effect Reversal**: When events expire, all affected systems return to their original state

## How It Works

1. **Event Selection**: Each time a new block is mined, the system has a chance to pick a random economic event (default 50%)
2. **Duration Tracking**: The selected event's duration is tracked in Bitcoin blocks
3. **Persistence**: When the game is saved, the current active event and its remaining duration are stored
4. **Restoration**: When the game is loaded, any active event is restored with its remaining duration
5. **Expiration**: When an event's duration reaches 0, it expires and the system tries to pick a new event

## Implementation Details

### RandomEconomicEventPicker Class

The main class that handles all economic event logic:

- **Signals**:
  - `event_picked(economic_event: EconomicEvent)`: Emitted when a new event starts
  - `event_expired(economic_event: EconomicEvent)`: Emitted when an event expires

- **Key Methods**:
  - `pick_random_event()`: Manually trigger event selection
  - `get_current_event()`: Get the currently active event
  - `get_remaining_duration()`: Get remaining blocks for current event
  - `is_event_active()`: Check if an event is currently active
  - `force_expire_event()`: Manually expire the current event
  - `force_pick_event(event_name)`: Force pick a specific event for testing
  - `force_revert_all_effects()`: Manually revert all economic effects for testing

### Persistence System Integration

The system implements `IPersistenceData` interface:

- **save_data()**: Saves current event name and remaining duration
- **load_data()**: Restores saved event and applies its effects
- Automatically added to "PersistentNodes" group for inclusion in save/load cycle

## Setup Instructions

1. **Add to Scene**: The `RandomEconomicEventPicker` is already set up in `SkillTree.tscn`

2. **Configure Events**: Add your economic events to the `economic_events` array in the editor

3. **Connect Event Bus**: Assign the `main_event_bus` resource

4. **BitcoinNetwork**: The system automatically connects to the global `BitcoinNetwork` singleton

## Usage Examples

### Basic Event Listening

```gdscript
func _ready():
    event_picker.event_picked.connect(_on_event_picked)
    event_picker.event_expired.connect(_on_event_expired)

func _on_event_picked(event: EconomicEvent):
    print("New event: " + event.name)
    # Apply event effects to your systems

func _on_event_expired(event: EconomicEvent):
    print("Event expired: " + event.name)
    print("All systems should now return to normal values")
    # Effects are automatically reverted - no manual cleanup needed
```

### Manual Event Control (for testing)

```gdscript
# Force pick a specific event
event_picker.force_pick_event("Inflation")

# Check current status
if event_picker.is_event_active():
    var event = event_picker.get_current_event()
    var remaining = event_picker.get_remaining_duration()
    print(event.name + " - " + str(remaining) + " blocks left")

# Adjust event chance
event_picker.set_chance_of_event(0.8)  # 80% chance per block

# Manually revert all effects (for testing)
event_picker.force_revert_all_effects()
```

### Effect Reversal System

The system automatically stores original values before applying economic events:

- **UpgradeData**: Stores original `upgrade_cost_base` and `upgrade_cost_base_btc` values
- **Automatic Storage**: Original values are stored when the first economic event is applied
- **Automatic Restoration**: When an event expires, all affected values return to their originals
- **Persistence**: Original values are saved/loaded with the game state

### Integration with Existing Systems

The system already integrates with:

- **SkillNode**: Events automatically affect upgrade costs via `apply_random_economic_event()`
- **UpgradeData**: Each upgrade type responds to different economic events and can revert effects
- **MainEventBus**: Events are broadcast through `economy_event_picked` and `economy_event_expired` signals
- **NotificationManager**: Displays event notifications to players

## Debugging

Use the `get_debug_info()` method to get detailed system status:

```gdscript
print(event_picker.get_debug_info())
```

Output example:
```
=== Economic Event Picker Debug Info ===
Available events: 6
Chance per block: 50.0%
Current event: Market Crash
Remaining duration: 3 blocks
Event type: 2
Impact: 0.15
Currency affected: 0
```

## Economic Event Configuration

Events are configured with:

- **name**: Display name
- **description**: Event description
- **event_type**: Type of event (inflation, deflation, etc.)
- **impact**: Strength of the effect (0.01 to 2.0)
- **currency_affected**: Which currency is affected
- **duration_in_blocks**: How long the event lasts

## Save Data Structure

The system saves:
```json
{
  "current_event_name": "Market Crash",
  "event_duration": 3
}
```

For each skill node with active economic effects:
```json
{
  "upgrade_level": 5,
  "original_upgrade_cost_base": 10.0,
  "original_upgrade_cost_base_btc": 1.0,
  "current_upgrade_cost_base": 11.5,
  "current_upgrade_cost_base_btc": 1.15,
  "has_stored_original_values": true
}
```

## Notes

- Events are automatically restored when the game loads
- If a saved event is no longer available in the events list, it's safely cleared
- The system prevents picking new events while one is active
- All event applications are handled through the existing `apply_random_economic_event()` methods
- **Original values are automatically stored** before applying any economic event
- **Effects are automatically reverted** when events expire - no manual cleanup required
- Original values persist across save/load cycles to ensure proper restoration
