extends Node

const SFX: Dictionary[StringName, AudioStream] = {
	&"ui_click": preload("res://assets/audio/sfx/ui_click.ogg"),
	&"confirm": preload("res://assets/audio/sfx/confirm.ogg"),
	&"enemy_defeat": preload("res://assets/audio/sfx/enemy_defeat.ogg"),
	&"player_hit": preload("res://assets/audio/sfx/player_hit.ogg"),
	&"player_shot": preload("res://assets/audio/sfx/player_shot.ogg"),
	&"pickup": preload("res://assets/audio/sfx/pickup.ogg"),
	&"boss_spawn": preload("res://assets/audio/sfx/boss_spawn.ogg"),
	&"dash": preload("res://assets/audio/sfx/dash.ogg"),
}
const AMBIENCE: Dictionary[StringName, AudioStream] = {
	&"menu": preload("res://assets/audio/ambient/menu_drone.ogg"),
	&"void_garden": preload("res://assets/audio/ambient/void_garden.ogg"),
}
const PLAYER_COUNT := 10

var _players: Array[AudioStreamPlayer] = []
var _ambient_player: AudioStreamPlayer
var _next_player := 0
var _last_played_ms: Dictionary[StringName, int] = {}
var _current_ambience: StringName


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _index: int in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.volume_db = -24.0
	_ambient_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ambient_player)
	get_tree().node_added.connect(_on_node_added)


func play_sfx(sound_id: StringName, volume_db := -12.0, minimum_interval := 0.0) -> void:
	var stream := SFX.get(sound_id) as AudioStream
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	var minimum_ms := roundi(minimum_interval * 1000.0)
	if now - _last_played_ms.get(sound_id, -minimum_ms) < minimum_ms:
		return
	_last_played_ms[sound_id] = now
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()


func play_ambience(ambience_id: StringName) -> void:
	if ambience_id == _current_ambience and _ambient_player.playing:
		return
	var stream := AMBIENCE.get(ambience_id) as AudioStream
	if stream == null:
		return
	_current_ambience = ambience_id
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_ambient_player.stream = stream
	_ambient_player.play()


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_register_button", node)


func _register_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
	var callback := Callable(self, "_play_ui_click")
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _play_ui_click() -> void:
	play_sfx(&"ui_click", -14.0, 0.03)
