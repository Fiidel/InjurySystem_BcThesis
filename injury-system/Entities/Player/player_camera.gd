extends Camera3D

@export var fov_zoom: float = 10.0
@export var fov_zoom_duration: float = 1.0
var default_fov: float


func _ready() -> void:
	default_fov = fov
	SignalBus.body_part_destroyed.connect(on_body_part_destroyed)


func on_body_part_destroyed() -> void:
	var fov_tween = create_tween()
	fov_tween.set_ignore_time_scale(true)
	fov_tween.set_ease(Tween.EASE_IN_OUT)
	fov_tween.tween_property(self, "fov", default_fov - fov_zoom, fov_zoom_duration * 0.5)
	fov_tween.tween_property(self, "fov", default_fov, fov_zoom_duration * 0.5)
