class_name EconomicEvent extends Resource
## Represents an economic event that can affect the game world.
##
## This class defines the properties and behavior of an economic event,
## including its name, description, impact on the economy, type, and duration.
## Economic events can be picked randomly and can have various effects on the game,
## such as inflation, deflation, market crashes, and more.


## 
enum EventType {
    INFLATION, ## Represents an increase in prices and decrease in currency value
    DEFLATION, ## Represents a decrease in prices and increase in currency value
    MARKET_CRASH, ## Represents a sudden drop of the market
    MARKET_BOOM, ## Represents a sudden bull run of the market
    TAX_CHANGE, ## Represents a change in tax rates. Creates Inflation or Deflation.
    TECHNOLOGY_ADVANCEMENT, ## Represents a technological advancement that affects the economy. Creating Deflation.
    NATURAL_DISASTER ## Represents a natural disaster that affects the economy. Creating Inflation.
}

## Name of the economic event, which is used to identify it in the game.
@export var name: String
## A brief description of the economic event.
@export var description: String
## The type of the economic event, which determines its behavior and effects.
@export var event_type: EventType
## The impact of the event on the economy, represented as a multiplier.
@export_range(0.01, 2.0, 0.01) var impact: float
## The currency affected by this event, which determines which currency's value is impacted.
@export var currency_affected: Constants.CurrencyType
## The duration of the event in bitcoin blocks, which determines how long the event will last.
@export var duration_in_blocks: int = 0
## The remaining duration of the event in blocks, used to track how long the event has left.
## This is set when the event is picked and decremented each block until it expires.
var remaining_duration: int = 0
