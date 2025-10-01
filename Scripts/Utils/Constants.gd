class_name Constants extends Node

# Bullet Constants
const BULLET_MAX_VELOCITY : float = 1500.0
const BULLET_MIN_VELOCITY : float = 500.0
const BULLET_MAGNITUDE_SCALE_FACTOR : float = 3.0


# Line Constants
const LINE_FADE_SPEED : float  = 0.8
const CUT_LINE_EPSILON: float = 10.0

# UI constants
const ERROR_404: String = "Code 404: Health has reached zero..."
const ERROR_200: String = "Code 200: You have successfully mined the block..."
const ERROR_401: String = "Code 401: Block has been mined by other miner..."
const ERROR_210: String = "Code 210: Level terminated by user..."
const ERROR_500: String = "Code 500: This block has already been mined. No reward will be given..."

# Player Movement constants
const Player_Max_Speed: float = 600.0
const Player_Acceleration: float = 1500.0
const Player_Friction: float = 1000.0


enum ShakeMagnitude {
	None,
	Small,
	Medium,
	Large,
	ExtraLarge,
	Gigantius,
	Enormius
}

enum WeaponNames {
	NONE = -1,
	PISTOL,
	SHOTGUN,
	RIFLE,
	MINI_UZI,
	SNIPER,
	AK47,
	MACHINE_GUN,
	ROCKET_LAUNCHER,
	GRENADE_LAUNCHER,
	FLAMETHROWER,
	LASER,
	RAILGUN,
	PLASMA,
	RAYGUN,
	BAZOOKA,
	CANNON,
	BFG,
	MINIGUN,
	CHAINSAW,
	SWORD,
	AXE,
	HAMMER,
	MACE,
	SPEAR,
	BOW,
	CROSSBOW,
	SHURIKEN,
	KUNAI,
	NINJA_STAR,
	BOOMERANG,
	WHIP,
	LASSO,
	YOYO,
	SLINGSHOT,
	CATAPULT,
	TREBUCHET,
	BALLISTA,
	CANNONBALL,
	BOMB,
	MORTAR,
	LANDMINE,
	CLAYMORE 
}

## Shapes for the polygons
enum PolygonShape {
		Circular, ## Circular polygon
		Rectangular, ## Rectangular polygon
		Beam, ## Beam polygon
		SuperEllipse, ## A super ellipse polygon
		SuperShape ## A super shape polygon
}

## Shapes for the overall map grid
enum MapShape {
	Square, ## Square grid
	Circle, ## Circular grid
	Diamond, ## Diamond grid
	Cross, ## Cross grid
	Ring, ## Ring grid
	LShape, ## L-shaped grid
}


## Abilities that can be used by the player
enum AbilityNames {
	NONE, ## No ability
	BLOCK_CORE_FINDER, ## Finds the core of a block
	MAGNET, ## Attracts nearby resources
	REGEN_HEALTH_OVER_TIME, ## Regenerates health over time
	SHIELD, ## Provides a temporary shield
}

enum CurrencyType {
	FIAT,
	BITCOIN,
	BOTH,
}

enum ArmoryUpgradeType {
	WEAPON_FIRE_RATE,
	WEAPON_DAMAGE_MULTIPLIER,
	WEAPON_SPREAD_REDUCTION,
	WEAPON_PRECHARGE_TIME_REDUCTION,

	AMMO_DAMAGE,
	AMMO_SPEED,
	AMMO_EXPLOSION_RADIUS,
	AMMO_EXPLOSION_DAMAGE,
	AMMO_PIERCE_COUNT,
	AMMO_BOUNCE_COUNT,
	AMMO_BULLET_COUNT,
	AMMO_LASER_LENGTH,
	AMMO_LASER_DAMAGE,
}
