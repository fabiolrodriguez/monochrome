class_name DestroyNestsObjective
extends BaseObjective

const NEST_SCENE := preload("res://src/gameplay/objectives/hive_nest.tscn")
const UPGRADE_PICKUP_SCENE := preload("res://src/gameplay/pickups/upgrade_pickup.tscn")

var _nest_data: DestroyNestsObjectiveData
var _director: ThreatDirector
var _player: Player


func configure(objective_data: ObjectiveData, context: Dictionary) -> void:
	super.configure(objective_data, context)
	_nest_data = objective_data as DestroyNestsObjectiveData
	assert(_nest_data != null and _nest_data.spawn_enemy_data != null, "Nest objective requires spawn data.")
	_director = context.get("threat_director") as ThreatDirector
	_player = get_tree().get_first_node_in_group("player") as Player
	required_progress = _nest_data.nest_count
	for index: int in _nest_data.nest_count:
		var nest := NEST_SCENE.instantiate() as HiveNest
		nest.maximum_health = _nest_data.nest_health * (1.0 + float(index) * 0.12)
		nest.spawn_interval = _nest_data.nest_spawn_interval
		nest.spawn_enemy_data = _nest_data.spawn_enemy_data
		nest.director = _director
		add_child(nest)
		nest.position = _nest_data.nest_positions[index] if index < _nest_data.nest_positions.size() else Vector2.RIGHT.rotated(TAU * index / _nest_data.nest_count) * 430.0
		nest.destroyed.connect(_on_nest_destroyed)
	if _director != null:
		_director.set_hive_sources(_nest_data.nest_count, _nest_data.nest_count)


func _on_nest_destroyed(_nest: HiveNest) -> void:
	_drop_upgrade(_nest.global_position)
	current_progress += 1.0
	progress_changed.emit(current_progress, required_progress)
	var remaining := maxi(_nest_data.nest_count - int(current_progress), 0)
	if _director != null:
		_director.set_hive_sources(remaining, _nest_data.nest_count)
	_award_nest_reward()
	if current_progress >= required_progress:
		complete()


func _drop_upgrade(world_position: Vector2) -> void:
	var controller := get_tree().get_first_node_in_group("upgrade_controller") as UpgradeController
	if controller == null:
		return
	var selected := controller.roll_world_upgrade()
	if selected == null:
		return
	var pickup := UPGRADE_PICKUP_SCENE.instantiate() as UpgradePickup
	pickup.upgrade = selected
	var container := get_tree().get_first_node_in_group("pickup_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(pickup)
	pickup.global_position = world_position


func _award_nest_reward() -> void:
	if is_instance_valid(_player):
		_player.experience.add_experience(_nest_data.experience_reward)
		_player.health.heal(_nest_data.healing_reward)
	var currency := get_tree().get_first_node_in_group("run_currency") as RunCurrency
	if currency != null:
		currency.collect_coins(_nest_data.coin_reward)
	AudioManager.play_sfx(&"confirm", -10.0)
