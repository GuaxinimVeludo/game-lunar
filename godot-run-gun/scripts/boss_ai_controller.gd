extends CharacterBody3D
class_name BossAIController

enum Attack { SWEEP, SLAM, VOLLEY }
@export var max_health := 1000.0
@export var player_path: NodePath
@export var projectile_scene: PackedScene
@export var muzzle: Marker3D
@export var telegraph_mesh: MeshInstance3D
@export var attack_cooldown := 2.4
@export var gravity := 24.0
@export var heavy_attack_threshold := 0.55
@export var attack_damage := 22.0
@export var attack_speed := 20.0
var health := 1000.0
var player: PlayerController
var _cooldown := 1.0
var _attacking := false

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	player = get_node_or_null(player_path) as PlayerController
	if telegraph_mesh: telegraph_mesh.visible = false

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player): return
	if not is_on_floor(): velocity.y -= gravity * delta
	velocity.z = 0.0
	move_and_slide()
	_cooldown -= delta
	if _cooldown <= 0.0 and not _attacking: _begin_attack(_choose_attack())

func _choose_attack() -> Attack:
	var distance := absf(player.global_position.x - global_position.x)
	var hp_ratio := health / maxf(1.0, max_health)
	if hp_ratio <= heavy_attack_threshold:
		return Attack.SWEEP if distance > 7.0 else Attack.SLAM
	return Attack.VOLLEY if distance > 5.0 else Attack.SLAM

func _begin_attack(attack: Attack) -> void:
	_attacking = true
	if telegraph_mesh:
		telegraph_mesh.visible = true
		_update_telegraph(attack)
	# Telegraph window gives the player time to react before damaging shots spawn.
	await get_tree().create_timer(0.85).timeout
	if not is_inside_tree(): return
	if telegraph_mesh: telegraph_mesh.visible = false
	_perform_attack(attack)
	_attacking = false
	_cooldown = attack_cooldown

func _update_telegraph(attack: Attack) -> void:
	if telegraph_mesh == null: return
	var target := player.global_position
	var origin := muzzle.global_position if muzzle else global_position
	var end := target
	if attack == Attack.SWEEP: end = origin + Vector3(signf(target.x - origin.x) * 14.0, 0.0, 0.0)
	var delta := end - origin
	telegraph_mesh.global_position = (origin + end) * 0.5
	telegraph_mesh.scale = Vector3(maxf(0.08, delta.length()), 0.08, 0.08)
	telegraph_mesh.rotation.z = atan2(delta.y, delta.x)

func _perform_attack(attack: Attack) -> void:
	match attack:
		Attack.SLAM:
			if global_position.distance_to(player.global_position) < 4.0: player.take_damage(attack_damage * 1.5)
			_fire_at_player(1)
		Attack.SWEEP: _fire_at_player(5, 0.18)
		Attack.VOLLEY: _fire_at_player(3, 0.12)

func _fire_at_player(count: int, delay := 0.0) -> void:
	for i in count:
		if projectile_scene:
			var projectile := projectile_scene.instantiate() as Projectile3D
			if projectile:
				get_tree().current_scene.add_child(projectile)
				var origin := muzzle.global_position if muzzle else global_position
				projectile.global_position = origin
	var direction := (player.global_position + Vector3(0, 0.7, 0) - origin).normalized()
				projectile.configure(direction * attack_speed, attack_damage, false, 0.0, 2, self)
		if delay > 0.0: await get_tree().create_timer(delay).timeout

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0: queue_free()
