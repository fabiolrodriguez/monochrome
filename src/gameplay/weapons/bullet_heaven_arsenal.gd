class_name BulletHeavenArsenal
extends Node2D

@export var weapon_path: NodePath
@export var orbital_scene: PackedScene

var radial_pulse_level := 0
var seeker_level := 0
var orbital_level := 0
var _radial_cooldown := 0.0
var _seeker_cooldown := 0.0
var _orbit_angle := 0.0
var _orbitals: Array[OrbitalWard] = []
var _weapon: Weapon
var _void_storm := false
var _chain_wisp := false
var _orbital_aegis := false


func _ready() -> void:
	_weapon = get_node(weapon_path) as Weapon
	assert(_weapon != null, "BulletHeavenArsenal requires the player's Weapon.")


func _physics_process(delta: float) -> void:
	_update_orbitals(delta)
	if radial_pulse_level > 0:
		_radial_cooldown -= delta
		if _radial_cooldown <= 0.0:
			_fire_radial_pulse()
	if seeker_level > 0:
		_seeker_cooldown -= delta
		if _seeker_cooldown <= 0.0:
			_fire_seekers()


func add_radial_pulse_level() -> void:
	radial_pulse_level += 1
	_radial_cooldown = minf(_radial_cooldown, 0.35)


func add_seeker_level() -> void:
	seeker_level += 1
	_seeker_cooldown = minf(_seeker_cooldown, 0.25)


func add_orbital_level() -> void:
	orbital_level += 1
	_refresh_orbitals()


func evolve_void_storm() -> void:
	_void_storm = true


func evolve_chain_wisp() -> void:
	_chain_wisp = true


func evolve_orbital_aegis() -> void:
	_orbital_aegis = true
	_refresh_orbitals()


func _fire_radial_pulse() -> void:
	var projectile_count := 4 + radial_pulse_level * 2
	var rotation_offset := _orbit_angle * 0.35
	for index: int in projectile_count:
		var direction := Vector2.RIGHT.rotated(rotation_offset + TAU * float(index) / float(projectile_count))
		_weapon.fire_passive(direction, 0.32 + radial_pulse_level * 0.08, Color("9d70ff"))
	if _void_storm:
		for index: int in projectile_count:
			var direction := Vector2.RIGHT.rotated(rotation_offset + PI / float(projectile_count) + TAU * float(index) / float(projectile_count))
			_weapon.fire_passive(direction, 0.26 + radial_pulse_level * 0.07, Color("d2b3ff"))
	_radial_cooldown = maxf(3.4 - radial_pulse_level * 0.32, 1.65)


func _fire_seekers() -> void:
	var targets: Array[Node2D] = []
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node2D
		if enemy != null and is_instance_valid(enemy):
			targets.append(enemy)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	var shot_count := mini(1 + floori(float(seeker_level - 1) / 2.0) + (1 if _chain_wisp else 0), 4)
	for index: int in mini(shot_count, targets.size()):
		_weapon.fire_passive(global_position.direction_to(targets[index].global_position), 0.5 + seeker_level * 0.1, Color("63dcff"), 2 if _chain_wisp else 0)
	_seeker_cooldown = maxf(2.15 - seeker_level * 0.22, 0.95)


func _refresh_orbitals() -> void:
	if orbital_scene == null:
		return
	var desired_count := mini(orbital_level + (1 if _orbital_aegis else 0), 5)
	while _orbitals.size() < desired_count:
		var orbital := orbital_scene.instantiate() as OrbitalWard
		if orbital == null:
			return
		add_child(orbital)
		_orbitals.append(orbital)
	for orbital: OrbitalWard in _orbitals:
		orbital.damage = 6.0 + orbital_level * 2.0


func _update_orbitals(delta: float) -> void:
	if _orbitals.is_empty():
		return
	_orbit_angle = fmod(_orbit_angle + delta * (1.7 + orbital_level * 0.12), TAU)
	var radius := 19.0 + orbital_level * 2.0
	for index: int in _orbitals.size():
		var angle := _orbit_angle + TAU * float(index) / float(_orbitals.size())
		_orbitals[index].damage = (6.0 + orbital_level * 2.0) * _weapon.damage_multiplier * (1.25 if _orbital_aegis else 1.0)
		_orbitals[index].position = Vector2.RIGHT.rotated(angle) * radius
