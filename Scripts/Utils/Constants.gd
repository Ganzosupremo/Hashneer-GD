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
	NONE,
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

enum PolygonShape {
        Circular,
        Rectangular,
        Beam,
        SuperEllipse,
        SuperShape
}

# Shapes for the overall map grid
enum MapShape {
        Square,
        Circle,
        Diamond
}


enum AbilityNames {
	NONE,
	BLOCK_CORE_FINDER,
	MAGNET,
	REGEN_HEALTH_OVER_TIME,
}

enum CurrencyType {
	FIAT,
	BITCOIN,
}
