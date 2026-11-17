extends CharacterBody3D
class_name VehicleController

signal health_changed(current: float, maximum: float)
signal destroyed
@export var max_integrity := 250.0
@export var drive_speed := 12.0
@export var jump_speed := 7.5
@export var gravity := 24.0
@export var seat: Marker3D
@export var exit_offset := Vector3(1.8, 0.2, 0.0)
@export var driver_weapon: WeaponController
@export var eject_invulnerability := 1.2
var integrity := 250.0
var driver: PlayerController
var has_driver: bool:
	get:
		return driver != null

func _ready() -> void:
	add_to_group("vehicles")
	integrity = max_integrity

func enter_driver(player: PlayerController) -> void:
	if has_driver or player == null: return
	driver = player
	driver.mount_vehicle(self)
	if seat: driver.global_position = seat.global_position

func drive_from_input() -> void:
	if not has_driver: return
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * drive_speed
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = jump_speed
	if not is_on_floor(): velocity.y -= gravity * get_physics_process_delta_time()
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0
	if driver_weapon and Input.is_action_pressed("fire"):
		driver_weapon.try_fire(driver.aim_direction())
	if seat: driver.global_position = seat.global_position

func eject_driver() -> void:
	if not has_driver: return
	var player := driver
	driver = null
	var seat_position := seat.global_position if seat else global_position
	player.dismount_vehicle(seat_position + exit_offset, eject_invulnerability)

func take_damage(amount: float) -> void:
	integrity = maxf(0.0, integrity - amount)
	health_changed.emit(integrity, max_integrity)
	if integrity <= 0.0:
		eject_driver()
		destroyed.emit()
		queue_free()
