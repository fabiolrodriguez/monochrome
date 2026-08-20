extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SUPPORTED_LOCALES: Array[StringName] = [&"en", &"pt_BR", &"es"]

var master_volume := 0.8
var fullscreen := false
var locale: StringName = &"en"
var flash_intensity := 1.0
var screen_shake := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	apply_settings()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save_settings()
	settings_changed.emit()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	_save_settings()
	settings_changed.emit()


func set_locale(value: StringName) -> void:
	locale = value if SUPPORTED_LOCALES.has(value) else &"en"
	TranslationServer.set_locale(str(locale))
	_save_settings()
	settings_changed.emit()


func set_flash_intensity(value: float) -> void:
	flash_intensity = clampf(value, 0.0, 1.0)
	_save_settings()
	settings_changed.emit()


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	_save_settings()
	settings_changed.emit()


func apply_settings() -> void:
	_apply_volume()
	_apply_fullscreen()
	TranslationServer.set_locale(str(locale))


func _apply_volume() -> void:
	var bus_index := AudioServer.get_bus_index(&"Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume) if master_volume > 0.001 else -80.0)


func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	flash_intensity = clampf(float(config.get_value("accessibility", "flash_intensity", flash_intensity)), 0.0, 1.0)
	screen_shake = bool(config.get_value("accessibility", "screen_shake", screen_shake))
	var saved_locale := StringName(str(config.get_value("language", "locale", locale)))
	locale = saved_locale if SUPPORTED_LOCALES.has(saved_locale) else &"en"


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("accessibility", "flash_intensity", flash_intensity)
	config.set_value("accessibility", "screen_shake", screen_shake)
	config.set_value("language", "locale", str(locale))
	config.save(SETTINGS_PATH)
