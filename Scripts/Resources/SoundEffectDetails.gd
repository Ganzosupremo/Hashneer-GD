class_name SoundEffectDetails extends Resource

enum SoundEffectType {
	AK47_RIFLE_FIRE,
	SNIPER_RIFLE_FIRE,
	PISTOL_FIRE,
	SHOTGUN_FIRE,
	MINI_UZI_FIRE,
	ENEMY_FIRE,
	PLAYER_DEATH,
	PLAYER_HIT,
	PLAYER_HEAL,
	PLAYER_WALK,
	ENEMY_HIT,
	ENEMY_DEATH,
	ENEMY_HEAL,
	FIAT_PICKUP,
	BTC_PICKUP,
	UI_BUTTON_CLICK,
	UI_BUTTON_HOVER,
	UI_BUTTON_RELEASE,
	UI_UPGRADE_BROUGHT,
	BOSS_SPAWN,
	BOSS_DEATH,
	BOSS_HIT,
	BOSS_HEAL,
	QUADRANT_CORE_DESTROYED,
	QUADRANT_HIT,
	UI_VOLUME_SLIDER_TEST,
}

## Maximum number of this SoundEffect to play simultaneously before culled.
@export_range(0, 10, 1, "or_greater") var limit: int = 5
## The unique sound effect in the [enum SoundEffectType] to associate with this effect. Each SoundEffectDetails resource should have it's own unique [enum SoundEffectType] setting.
@export var sound_type: SoundEffectType
## The audio bus to play this sound effect on.
## This is used to set the bus of the [member audio_stream] when it is played.
@export var destination_audio_bus: SFXManager.DestinationAudioBus = SFXManager.DestinationAudioBus.MASTER
## The volume of the [member audio_stream] in decibels.
@export_range(-80.0, 24.0) var sound_volume: float = 1.0
@export var audio_stream: AudioStream
@export_range(0.1, 2.0) var sound_pitch: float = 1.0
## The pitch randomness setting of the [member audio_stream].
@export_range(0.0, 1.0, .01) var pitch_randomness: float = 0.0

## The instances of this [AudioStream] currently playing.
var audio_count: int

## Takes [param amount] to change the [member audio_count]. 
func change_audio_count(amount: int) -> void:
	audio_count = max(0, audio_count + amount)

## Checkes whether the audio limit is reached. Returns true if the [member audio_count] is less than the [member limit].
func has_open_limit() -> bool:
	return audio_count < limit

## Connected to the [member audio_stream]'s finished signal to decrement the [member audio_count].
func on_audio_finished() -> void:
	change_audio_count(-1)

static func enum_to_string(type: SoundEffectType) -> String:
	match type:
		SoundEffectType.AK47_RIFLE_FIRE: return "AK47_RIFLE_FIRE"
		SoundEffectType.SNIPER_RIFLE_FIRE: return "SNIPER_RIFLE_FIRE"
		SoundEffectType.PISTOL_FIRE: return "PISTOL_FIRE"
		SoundEffectType.SHOTGUN_FIRE: return "SHOTGUN_FIRE"
		SoundEffectType.MINI_UZI_FIRE: return "MINI_UZI_FIRE"
		SoundEffectType.ENEMY_FIRE: return "ENEMY_FIRE"
		SoundEffectType.PLAYER_DEATH: return "PLAYER_DEATH"
		SoundEffectType.PLAYER_HIT: return "PLAYER_HIT"
		SoundEffectType.PLAYER_HEAL: return "PLAYER_HEAL"
		SoundEffectType.PLAYER_WALK: return "PLAYER_WALK"
		SoundEffectType.ENEMY_HIT: return "ENEMY_HIT"
		SoundEffectType.ENEMY_DEATH: return "ENEMY_DEATH"
		SoundEffectType.ENEMY_HEAL: return "ENEMY_HEAL"
		SoundEffectType.FIAT_PICKUP: return "FIAT_PICKUP"
		SoundEffectType.BTC_PICKUP: return "BTC_PICKUP"
		SoundEffectType.UI_BUTTON_CLICK: return "UI_BUTTON_CLICK"
		SoundEffectType.UI_BUTTON_HOVER: return "UI_BUTTON_HOVER"
		SoundEffectType.UI_BUTTON_RELEASE: return "UI_BUTTON_RELEASE"
		SoundEffectType.UI_UPGRADE_BROUGHT: return "UI_UPGRADE_BROUGHT"
		SoundEffectType.BOSS_SPAWN: return "BOSS_SPAWN"
		SoundEffectType.BOSS_DEATH: return "BOSS_DEATH"
		SoundEffectType.BOSS_HIT: return "BOSS_HIT"
	return "UNKNOWN"
