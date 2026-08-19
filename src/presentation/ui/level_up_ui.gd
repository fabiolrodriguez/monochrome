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
			button.text = "%s\n%s\n%s %d/%d" % [tr(upgrade.name_key), tr(upgrade.description_key), tr("UI_LEVEL"), next_level, upgrade.max_level]
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
