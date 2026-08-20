class_name LevelUpUI
extends CanvasLayer

signal upgrade_selected(upgrade: UpgradeData)
signal reroll_requested

@onready var panel: PanelContainer = $Panel
@onready var buttons: Array[Button] = [$Panel/Layout/Cards/Card1, $Panel/Layout/Cards/Card2, $Panel/Layout/Cards/Card3]
@onready var icons: Array[TextureRect] = [$Panel/Layout/Cards/Card1/Icon, $Panel/Layout/Cards/Card2/Icon, $Panel/Layout/Cards/Card3/Icon]
@onready var reroll_button: Button = $Panel/Layout/Reroll

var _options: Array[UpgradeData] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	for index: int in buttons.size():
		buttons[index].pressed.connect(_select.bind(index))
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	panel.hide()


func present(options: Array[UpgradeData], levels: Dictionary[StringName, int]) -> void:
	_options = options
	for index: int in buttons.size():
		var button := buttons[index]
		button.visible = index < options.size()
		if button.visible:
			var upgrade := options[index]
			var next_level: int = levels.get(upgrade.id, 0) + 1
			button.icon = null
			icons[index].texture = upgrade.icon
			var rarity_key := _rarity_key(upgrade.rarity)
			button.text = "[%s] %s\n%s\n%s %d/%d" % [tr(rarity_key), tr(upgrade.name_key), tr(upgrade.description_key), tr("UI_LEVEL"), next_level, upgrade.max_level]
			_apply_rarity_style(button, upgrade.rarity)
	panel.show()
	get_tree().paused = true
	buttons[0].grab_focus()


func close() -> void:
	panel.hide()
	get_tree().paused = false


func is_open() -> bool:
	return panel.visible


func set_rerolls_remaining(amount: int) -> void:
	if reroll_button == null:
		call_deferred("set_rerolls_remaining", amount)
		return
	reroll_button.visible = amount > 0
	reroll_button.text = "%s (%d)" % [tr("UI_REROLL"), amount]


func _select(index: int) -> void:
	if index >= _options.size():
		return
	upgrade_selected.emit(_options[index])


func _rarity_key(rarity: UpgradeData.Rarity) -> StringName:
	return [&"UI_RARITY_COMMON", &"UI_RARITY_UNCOMMON", &"UI_RARITY_RARE", &"UI_RARITY_EPIC", &"UI_RARITY_LEGENDARY"][rarity]


func _rarity_color(rarity: UpgradeData.Rarity) -> Color:
	return [Color("8b8e94"), Color("e8e9ed"), Color("63dcff"), Color("b67cff"), Color("ffd84a")][rarity]


func _apply_rarity_style(button: Button, rarity: UpgradeData.Rarity) -> void:
	var rarity_color := _rarity_color(rarity)
	var normal := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	normal.border_color = rarity_color
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_color_override("font_color", rarity_color)
