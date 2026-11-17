extends StaticBody3D
class_name DestructibleProp

signal destroyed(prop: DestructibleProp)
@export var max_health := 60.0
@export var drop_scene: PackedScene
@export var drop_chance := 0.35
var health := 60.0

func _ready() -> void: health = max_health

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0: destroy()

func destroy() -> void:
	destroyed.emit(self)
	if drop_scene and randf() <= drop_chance:
		var drop := drop_scene.instantiate()
		get_tree().current_scene.add_child(drop)
		drop.global_position = global_position
	queue_free()
