class_name TeamCustomization
extends Control

## Controls the session-only team kit choices. The visible customization UI
## lives in main.tscn so its layout remains easy to inspect in the editor.

const KIT_NAMES: Array[String] = [
	"BRAZIL",
	"ARGENTINA",
	"GERMANY",
	"FRANCE",
	"NETHERLANDS",
	"PORTUGAL",
	"JAPAN",
	"MEXICO",
]
const KIT_BODY_COLORS: Array[Color] = [
	Color("#009c3b"),
	Color("#74acdf"),
	Color("#ffcc00"),
	Color("#0055a4"),
	Color("#ae1c28"),
	Color("#046a38"),
	Color("#ffffff"),
	Color("#006847"),
]
const KIT_INNER_COLORS: Array[Color] = [
	Color("#ffdf00"),
	Color("#ffffff"),
	Color("#dd0000"),
	Color("#ffffff"),
	Color("#ffffff"),
	Color("#da291c"),
	Color("#ffffff"),
	Color("#ffffff"),
]
const KIT_CENTER_COLORS: Array[Color] = [
	Color("#002776"),
	Color("#f6b40e"),
	Color("#000000"),
	Color("#ef4135"),
	Color("#21468b"),
	Color("#ffcd00"),
	Color("#bc002d"),
	Color("#ce1126"),
]
const DEFAULT_TEAM_ONE_KIT := 5
const DEFAULT_TEAM_TWO_KIT := 3

@onready var team_one_tab: Button = $Panel/TeamOneTab
@onready var team_two_tab: Button = $Panel/TeamTwoTab
@onready var team_one_preview_body: Polygon2D = $Panel/TeamOnePreview/Body
@onready var team_one_preview_inner: Polygon2D = $Panel/TeamOnePreview/Inner
@onready var team_one_preview_center: Polygon2D = $Panel/TeamOnePreview/Center
@onready var team_two_preview_body: Polygon2D = $Panel/TeamTwoPreview/Body
@onready var team_two_preview_inner: Polygon2D = $Panel/TeamTwoPreview/Inner
@onready var team_two_preview_center: Polygon2D = $Panel/TeamTwoPreview/Center
@onready var team_one_kit_label: Label = $Panel/TeamOneKit
@onready var team_two_kit_label: Label = $Panel/TeamTwoKit
@onready var done_button: Button = $Panel/Done
@onready var kit_buttons: Array[Button] = [
	$Panel/KitGrid/Brazil,
	$Panel/KitGrid/Argentina,
	$Panel/KitGrid/Germany,
	$Panel/KitGrid/France,
	$Panel/KitGrid/Netherlands,
	$Panel/KitGrid/Portugal,
	$Panel/KitGrid/Japan,
	$Panel/KitGrid/Mexico,
]

var active_team := 1
var selected_kit_indices := [DEFAULT_TEAM_ONE_KIT, DEFAULT_TEAM_TWO_KIT]


func _ready() -> void:
	team_one_tab.pressed.connect(_select_team.bind(1))
	team_two_tab.pressed.connect(_select_team.bind(2))
	done_button.pressed.connect(hide)
	for kit_index in kit_buttons.size():
		kit_buttons[kit_index].pressed.connect(_select_kit.bind(kit_index))
	_update_ui()


func show_customization() -> void:
	active_team = 1
	_update_ui()
	show()


func get_team_colors(team: int) -> PackedColorArray:
	var team_index := 0 if team == 1 else 1
	var kit_index: int = selected_kit_indices[team_index]
	return PackedColorArray([
		KIT_BODY_COLORS[kit_index],
		KIT_INNER_COLORS[kit_index],
		KIT_CENTER_COLORS[kit_index],
	])


func _select_team(team: int) -> void:
	active_team = team
	_update_ui()


func _select_kit(kit_index: int) -> void:
	selected_kit_indices[active_team - 1] = kit_index
	_update_ui()


func _update_ui() -> void:
	team_one_tab.button_pressed = active_team == 1
	team_two_tab.button_pressed = active_team == 2

	var current_kit: int = selected_kit_indices[active_team - 1]
	var other_team_index := 1 if active_team == 1 else 0
	var unavailable_kit: int = selected_kit_indices[other_team_index]
	for kit_index in kit_buttons.size():
		kit_buttons[kit_index].disabled = kit_index == unavailable_kit
		kit_buttons[kit_index].button_pressed = kit_index == current_kit

	_update_preview(1, selected_kit_indices[0])
	_update_preview(2, selected_kit_indices[1])


func _update_preview(team: int, kit_index: int) -> void:
	var body := team_one_preview_body if team == 1 else team_two_preview_body
	var inner := team_one_preview_inner if team == 1 else team_two_preview_inner
	var center := team_one_preview_center if team == 1 else team_two_preview_center
	var label := team_one_kit_label if team == 1 else team_two_kit_label
	body.color = KIT_BODY_COLORS[kit_index]
	inner.color = KIT_INNER_COLORS[kit_index]
	center.color = KIT_CENTER_COLORS[kit_index]
	label.text = "TEAM %d • %s" % [team, KIT_NAMES[kit_index]]
