extends Resource
class_name WeaponData

enum ShotType { HITSCAN, BALLISTIC, EXPLOSIVE }

@export var display_name := "Rifle"
@export var shot_type: ShotType = ShotType.HITSCAN
@export var damage := 18.0
@export var rounds_per_second := 8.0
@export_range(0.0, 30.0, 0.1) var recoil_degrees := 1.5
@export_range(0.0, 30.0, 0.1) var spread_degrees := 2.0
@export var range := 60.0
@export var projectile_speed := 28.0
@export var projectile_scene: PackedScene
@export var explosion_radius := 3.5
@export_flags_3d_physics var hit_mask := 4
