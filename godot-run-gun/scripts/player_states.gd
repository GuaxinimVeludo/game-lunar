extends RefCounted
class_name PlayerStates

## Concrete states are nested here to keep the small FSM easy to distribute.
class Base extends RefCounted:
	var player: PlayerController
	func _init(p: PlayerController) -> void: player = p
	func enter() -> void: pass
	func exit() -> void: pass
	func physics_update(_delta: float) -> void: pass

class Idle extends Base:
	func physics_update(_delta: float) -> void:
		if player._wants_vehicle(): player._try_interact(); return
		if player._wants_melee(): player.change_state("melee"); return
		if player._wants_jump(): player.change_state("jump"); return
		if player._wants_crouch(): player.change_state("crouch"); return
		if absf(player.move_axis()) > 0.01: player.change_state("run"); return
		player.apply_horizontal(0.0)

class Run extends Base:
	func physics_update(_delta: float) -> void:
		if player._wants_vehicle(): player._try_interact(); return
		if player._wants_melee(): player.change_state("melee"); return
		if player._wants_jump(): player.change_state("jump"); return
		if player._wants_crouch(): player.change_state("crouch"); return
		player.apply_horizontal(player.move_axis())
		if absf(player.move_axis()) <= 0.01: player.change_state("idle")

class Jump extends Base:
	func enter() -> void: player.velocity.y = player.jump_speed
	func physics_update(_delta: float) -> void:
		if player._wants_vehicle(): player._try_interact(); return
		player.apply_horizontal(player.move_axis())
		if player.is_on_floor() and player.velocity.y <= 0.0:
			if player._wants_crouch(): player.change_state("crouch")
			elif absf(player.move_axis()) > 0.01: player.change_state("run")
			else: player.change_state("idle")

class Crouch extends Base:
	func enter() -> void: player.set_crouched(true)
	func exit() -> void: player.set_crouched(false)
	func physics_update(_delta: float) -> void:
		if player._wants_melee(): player.change_state("melee"); return
		if not player._wants_crouch(): player.change_state("idle"); return
		player.apply_horizontal(player.move_axis(), player.crouch_speed)

class MeleeAttack extends Base:
	var cooldown := 0.0
	var elapsed := 0.0
	func enter() -> void: cooldown = 0.0; elapsed = 0.32
	func physics_update(delta: float) -> void:
		elapsed -= delta
		cooldown -= delta
		player.apply_horizontal(0.0)
		if cooldown <= 0.0:
			player.melee_tick()
			cooldown = player.melee_interval
		if elapsed <= 0.0:
			if player._wants_crouch(): player.change_state("crouch")
			elif absf(player.move_axis()) > 0.01: player.change_state("run")
			else: player.change_state("idle")

class VehicleMode extends Base:
	func physics_update(_delta: float) -> void:
		if player.current_vehicle == null:
			player.change_state("idle"); return
		if Input.is_action_just_pressed("interact"):
			player.current_vehicle.eject_driver()
			return
		player.current_vehicle.drive_from_input()
