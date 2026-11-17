extends Node3D
class_name WeaponController

@export var weapon_data: WeaponData
@export var muzzle: Marker3D
@export var shooter: CollisionObject3D
@export var projectile_parent: Node3D
var _cooldown := 0.0

func _physics_process(delta: float) -> void: _cooldown = maxf(0.0, _cooldown - delta)

func try_fire(direction: Vector3) -> bool:
	if weapon_data == null or _cooldown > 0.0: return false
	_cooldown = 1.0 / maxf(0.1, weapon_data.rounds_per_second)
	var dir := _spread_direction(direction.normalized())
	match weapon_data.shot_type:
		WeaponData.ShotType.HITSCAN: _fire_hitscan(dir)
		WeaponData.ShotType.BALLISTIC, WeaponData.ShotType.EXPLOSIVE: _fire_projectile(dir)
	return true

func _spread_direction(direction: Vector3) -> Vector3:
	# Random angular spread plus a small upward recoil; aim remains in the XY plane.
	var jitter := deg_to_rad(randf_range(-weapon_data.spread_degrees, weapon_data.spread_degrees))
	var recoil := deg_to_rad(randf_range(0.0, weapon_data.recoil_degrees))
	return direction.rotated(Vector3.FORWARD, jitter + recoil).normalized()

func _fire_hitscan(direction: Vector3) -> void:
	var from := muzzle.global_position if muzzle else global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * weapon_data.range, weapon_data.hit_mask)
	if shooter: query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var target: Object = hit.collider
		if target.has_method("take_damage"): target.take_damage(weapon_data.damage)

func _fire_projectile(direction: Vector3) -> void:
	if weapon_data.projectile_scene == null: return
	var shot := weapon_data.projectile_scene.instantiate() as Projectile3D
	if shot == null: return
	(projectile_parent if projectile_parent else get_tree().current_scene).add_child(shot)
	shot.global_position = muzzle.global_position if muzzle else global_position
	shot.configure(direction * weapon_data.projectile_speed, weapon_data.damage,
		weapon_data.shot_type == WeaponData.ShotType.EXPLOSIVE, weapon_data.explosion_radius,
		weapon_data.hit_mask, shooter)
