extends Node

signal platform_ready
signal achievement_synced(steam_api_name: StringName)

const RETRY_SECONDS := 5.0
const STORE_RETRY_SECONDS := 30.0

var _steam: Object
var _stats_ready := false
var _retry_remaining := 0.0
var _store_retry_remaining := 0.0
var _store_pending := false
var _pending: Dictionary[StringName, bool] = {}
var _synced: Dictionary[StringName, bool] = {}


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		set_process(false)
		return
	_steam = Engine.get_singleton("Steam")
	if _steam.has_method("steamInitEx"):
		_steam.call("steamInitEx")
	if _steam.has_signal("current_stats_received"):
		_steam.connect("current_stats_received", _on_current_stats_received)
	if _steam.has_signal("current_stats_stored"):
		_steam.connect("current_stats_stored", _on_current_stats_stored)
	_request_current_stats()


func _process(delta: float) -> void:
	if _steam == null:
		return
	if _steam.has_method("run_callbacks"):
		_steam.call("run_callbacks")
	if _stats_ready:
		if _store_pending:
			_store_retry_remaining -= delta
			if _store_retry_remaining <= 0.0:
				_try_store()
		return
	_retry_remaining -= delta
	if _retry_remaining <= 0.0:
		_request_current_stats()


func sync_catalog(catalog: AchievementCatalog, unlocked_ids: Array[StringName]) -> void:
	if catalog == null:
		return
	var registered_names: Dictionary[StringName, bool] = {}
	for achievement: AchievementData in catalog.achievements:
		if achievement.steam_api_name == &"":
			push_error("Achievement %s has no Steam API Name." % achievement.id)
			continue
		if registered_names.has(achievement.steam_api_name):
			push_error("Duplicate Steam achievement API Name: %s" % achievement.steam_api_name)
			continue
		registered_names[achievement.steam_api_name] = true
		if unlocked_ids.has(achievement.id):
			_pending[achievement.steam_api_name] = true
	_flush_pending()


func is_platform_available() -> bool:
	return _steam != null


func _request_current_stats() -> void:
	_retry_remaining = RETRY_SECONDS
	if _steam == null or not _steam.has_method("requestCurrentStats"):
		return
	var requested: Variant = _steam.call("requestCurrentStats")
	# GodotSteam exposes the callback signal. Other adapters may report readiness
	# directly and omit it, so support both without a compile-time dependency.
	if not _steam.has_signal("current_stats_received") and _call_succeeded(requested):
		_mark_stats_ready()


func _on_current_stats_received(_game_id: int = 0, result: int = 1) -> void:
	# Steam's k_EResultOK is 1.
	if result == 1:
		_mark_stats_ready()


func _on_current_stats_stored(_game_id: int = 0, result: int = 1) -> void:
	if result != 1:
		_store_pending = true
		_store_retry_remaining = STORE_RETRY_SECONDS


func _mark_stats_ready() -> void:
	if _stats_ready:
		return
	_stats_ready = true
	platform_ready.emit()
	_flush_pending()


func _flush_pending() -> void:
	if not _stats_ready or _steam == null or not _steam.has_method("setAchievement"):
		return
	var changed := false
	for steam_api_name: StringName in _pending.keys():
		if _synced.has(steam_api_name):
			continue
		var result: Variant = _steam.call("setAchievement", str(steam_api_name))
		if not _call_succeeded(result):
			continue
		_synced[steam_api_name] = true
		changed = true
		achievement_synced.emit(steam_api_name)
	if changed:
		_store_pending = true
		_try_store()


func _try_store() -> void:
	_store_retry_remaining = STORE_RETRY_SECONDS
	if _steam == null or not _steam.has_method("storeStats"):
		return
	var result: Variant = _steam.call("storeStats")
	if _call_succeeded(result):
		_store_pending = false


func _call_succeeded(result: Variant) -> bool:
	if result is bool:
		return result
	if result is Dictionary:
		return bool((result as Dictionary).get("ret", (result as Dictionary).get("status", false)))
	return result != null
