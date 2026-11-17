extends CharacterBody3D
class_name PlayerController

signal health_changed(current: float, maximum: float)

@export var max_health := 100.0
@export var run_speed := 7.0
@export var crouch_speed := 3.2
@export var jump_speed := 10.5
@export var gravity := 26.0
@export var melee_damage := 25.0
@export var melee_range := 1.15
@export var melee_interval := 0.18
@export_flags_3d_physics var melee_mask := 4
@export var weapon_controller: WeaponController
@export var torso_pivot: Node3D
@export var arm_pivot: Node3D
@export var body_shape: CollisionShape3D
@export var standing_capsule_height := 1.7
@export var crouched_capsule_height := 1.0

var health := 100.0
var facing := 1.0
var current_vehicle: VehicleController
var invulnerable_time := 0.0
var state_name := ""
var _states: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	health = max_health
	_states = {
		"idle": PlayerStates.Idle.new(self), "run": PlayerStates.Run.new(self),
		"jump": PlayerStates.Jump.new(self), "crouch": PlayerStates.Crouch.new(self),
		"melee": PlayerStates.MeleeAttack.new(self), "vehicle": PlayerStates.VehicleMode.new(self)
	}
	change_state("idle")
	global_position.z = 0.0

func _physics_process(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	_states[state_name].physics_update(delta)
	if current_vehicle == null:
		if not is_on_floor(): velocity.y -= gravity * delta
		else: velocity.y = maxf(velocity.y, 0.0)
		velocity.z = 0.0
		move_and_slide()
		global_position.z = 0.0
		_update_aim()
	if weapon_controller and Input.is_action_pressed("fire") and current_vehicle == null:
		weapon_controller.try_fire(aim_direction())

func change_state(next: String) -> void:
	if next == state_name or not _states.has(next): return
	if not state_name.is_empty(): _states[state_name].exit()
	state_name = next
	_states[state_name].enter()

func move_axis() -> float:
	return Input.get_axis("move_left", "move_right")

func apply_horizontal(axis: float, speed: float = -1.0) -> void:
	if absf(axis) > 0.01: facing = signf(axis)
	velocity.x = axis * (run_speed if speed < 0.0 else speed)
	velocity.z = 0.0

func _wants_jump() -> bool: return Input.is_action_just_pressed("jump") and is_on_floor()
func _wants_crouch() -> bool: return Input.is_action_pressed("crouch") and is_on_floor()
func _wants_melee() -> bool: return Input.is_action_pressed("melee")
func _wants_vehicle() -> bool: return Input.is_action_just_pressed("interact")

func _try_interact() -> void:
	if current_vehicle:
		current_vehicle.eject_driver()
		return
	var nearest: VehicleController
	var best := 2.2
	for node in get_tree().get_nodes_in_group("vehicles"):
		var vehicle := node as VehicleController
		if vehicle and not vehicle.has_driver:
			var distance := global_position.distance_to(vehicle.global_position)
			if distance < best: nearest = vehicle; best = distance
	if nearest: nearest.enter_driver(self)

func set_crouched(value: bool) -> void:
	if body_shape and body_shape.shape is CapsuleShape3D:
		var capsule := body_shape.shape as CapsuleShape3D
		capsule = capsule.duplicate() as CapsuleShape3D
		body_shape.shape = capsule
		capsule.height = crouched_capsule_height if value else standing_capsule_height
		body_shape.position.y = capsule.height * 0.5

func aim_direction() -> Vector3:
	var x := Input.get_axis("aim_left", "aim_right")
	var y := Input.get_axis("aim_down", "aim_up")
	if absf(x) < 0.1 and absf(y) < 0.1: x = facing
	if absf(x) > 0.1: facing = signf(x)
	return Vector3(x, y, 0.0).normalized()

func _update_aim() -> void:
	var direction := aim_direction()
	var angle := atan2(direction.y, direction.x)
	if torso_pivot: torso_pivot.rotation.z = angle
	if arm_pivot: arm_pivot.rotation.z = angle

func melee_tick() -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = melee_range
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(facing * melee_range * 0.7, 0.5, 0.0))
	query.collision_mask = melee_mask
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var target: Object = hit.collider
		if target.has_method("take_damage"): target.take_damage(melee_damage)

func take_damage(amount: float) -> void:
	if invulnerable_time > 0.0 or current_vehicle != null: return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	invulnerable_time = 0.55
	if health <= 0.0: queue_free()

func mount_vehicle(vehicle: VehicleController) -> void:
	current_vehicle = vehicle
	visible = false
	if body_shape: body_shape.disabled = true
	velocity = Vector3.ZERO
	change_state("vehicle")

func dismount_vehicle(exit_position: Vector3, eject_invulnerability := 1.2) -> void:
	global_position = exit_position
	current_vehicle = null
	visible = true
	if body_shape: body_shape.disabled = false
	invulnerable_time = eject_invulnerability
	change_state("idle")
