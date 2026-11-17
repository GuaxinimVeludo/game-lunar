extends RigidBody3D
class_name Projectile3D

@export var lifetime := 5.0
var damage := 10.0
var explosive := false
var blast_radius := 3.0
var hit_mask := 4
var _source: CollisionObject3D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func configure(initial_velocity: Vector3, hit_damage: float, is_explosive: bool,
		radius: float, mask: int, source: CollisionObject3D) -> void:
	linear_velocity = initial_velocity
	damage = hit_damage
	explosive = is_explosive
	blast_radius = radius
	hit_mask = mask
	_source = source
	collision_mask = mask
	collision_layer = 16 if source and source.is_in_group("enemies") else 8

func _on_body_entered(body: Node) -> void:
	if body == _source: return
	if explosive: _explode()
	else:
		if body.has_method("take_damage"): body.take_damage(damage)
		queue_free()

func _explode() -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = blast_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = hit_mask
	if _source: query.exclude = [_source.get_rid()]
	for result in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var target: Object = result.collider
		if target.has_method("take_damage"): target.take_damage(damage)
	queue_free()
