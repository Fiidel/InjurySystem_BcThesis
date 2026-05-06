extends Node

const STUTTER_THRESHOLD_MS: float = 16.67 # 60FPS

var m_projectile_spawn_last_ms: float = 0.0
var m_projectile_spawn_peak_ms: float = 0.0
var m_projectile_spawn_stutter_count: int = 0

var m_projectile_impact_vfx_last_ms: float = 0.0
var m_projectile_impact_vfx_peak_ms: float = 0.0
var m_projectile_impact_vfx_stutter_count: int = 0

var m_enemy_fade_last_ms: float = 0.0
var m_enemy_fade_peak_ms: float = 0.0
var m_enemy_fade_stutter_count: int = 0

var m_hit_flash_activation_last_ms: float = 0.0
var m_hit_flash_activation_peak_ms: float = 0.0
var m_hit_flash_activation_stutter_count: int = 0


func _ready() -> void:
	Performance.add_custom_monitor("combat/projectile_spawn_last_ms", m_get_projectile_spawn_last_ms)
	Performance.add_custom_monitor("combat/projectile_spawn_peak_ms", m_get_projectile_spawn_peak_ms)
	Performance.add_custom_monitor("combat/projectile_spawn_stutter_count", m_get_projectile_spawn_stutter_count)
	Performance.add_custom_monitor("combat/projectile_impact_vfx_last_ms", m_get_projectile_impact_vfx_last_ms)
	Performance.add_custom_monitor("combat/projectile_impact_vfx_peak_ms", m_get_projectile_impact_vfx_peak_ms)
	Performance.add_custom_monitor("combat/projectile_impact_vfx_stutter_count", m_get_projectile_impact_vfx_stutter_count)
	Performance.add_custom_monitor("combat/enemy_fade_last_ms", m_get_enemy_fade_last_ms)
	Performance.add_custom_monitor("combat/enemy_fade_peak_ms", m_get_enemy_fade_peak_ms)
	Performance.add_custom_monitor("combat/enemy_fade_stutter_count", m_get_enemy_fade_stutter_count)
	Performance.add_custom_monitor("combat/hit_flash_activation_last_ms", m_get_hit_flash_activation_last_ms)
	Performance.add_custom_monitor("combat/hit_flash_activation_peak_ms", m_get_hit_flash_activation_peak_ms)
	Performance.add_custom_monitor("combat/hit_flash_activation_stutter_count", m_get_hit_flash_activation_stutter_count)


func m_now_usec() -> int:
	return Time.get_ticks_usec()


func m_record_projectile_spawn(duration_ms: float) -> void:
	m_projectile_spawn_last_ms = duration_ms
	m_projectile_spawn_peak_ms = max(m_projectile_spawn_peak_ms, duration_ms)
	if duration_ms > STUTTER_THRESHOLD_MS:
		m_projectile_spawn_stutter_count += 1


func m_record_projectile_impact_vfx(duration_ms: float) -> void:
	m_projectile_impact_vfx_last_ms = duration_ms
	m_projectile_impact_vfx_peak_ms = max(m_projectile_impact_vfx_peak_ms, duration_ms)
	if duration_ms > STUTTER_THRESHOLD_MS:
		m_projectile_impact_vfx_stutter_count += 1


func m_record_enemy_fade(duration_ms: float) -> void:
	m_enemy_fade_last_ms = duration_ms
	m_enemy_fade_peak_ms = max(m_enemy_fade_peak_ms, duration_ms)
	if duration_ms > STUTTER_THRESHOLD_MS:
		m_enemy_fade_stutter_count += 1


func m_record_hit_flash_activation(duration_ms: float) -> void:
	m_hit_flash_activation_last_ms = duration_ms
	m_hit_flash_activation_peak_ms = max(m_hit_flash_activation_peak_ms, duration_ms)
	if duration_ms > STUTTER_THRESHOLD_MS:
		m_hit_flash_activation_stutter_count += 1


func m_get_projectile_spawn_last_ms() -> float:
	return m_projectile_spawn_last_ms


func m_get_projectile_spawn_peak_ms() -> float:
	return m_projectile_spawn_peak_ms


func m_get_projectile_spawn_stutter_count() -> int:
	return m_projectile_spawn_stutter_count


func m_get_projectile_impact_vfx_last_ms() -> float:
	return m_projectile_impact_vfx_last_ms


func m_get_projectile_impact_vfx_peak_ms() -> float:
	return m_projectile_impact_vfx_peak_ms


func m_get_projectile_impact_vfx_stutter_count() -> int:
	return m_projectile_impact_vfx_stutter_count


func m_get_enemy_fade_last_ms() -> float:
	return m_enemy_fade_last_ms


func m_get_enemy_fade_peak_ms() -> float:
	return m_enemy_fade_peak_ms


func m_get_enemy_fade_stutter_count() -> int:
	return m_enemy_fade_stutter_count


func m_get_hit_flash_activation_last_ms() -> float:
	return m_hit_flash_activation_last_ms


func m_get_hit_flash_activation_peak_ms() -> float:
	return m_hit_flash_activation_peak_ms


func m_get_hit_flash_activation_stutter_count() -> int:
	return m_hit_flash_activation_stutter_count
