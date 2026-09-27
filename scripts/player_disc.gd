class_name PlayerDisc
extends RigidBody2D

## A single team piece. Its visible parts live in player_disc.tscn; this script
## only manages state and physics so the piece remains easy to edit in Godot.

@onready var body_polygon: Polygon2D = $Body
@onready var center_polygon: Polygon2D = $Center
@onready var active_ring: Line2D = $ActiveRing

var team: int = 1


func configure(new_team: int) -> void:
	team = new_team

	if team == 1:
		body_polygon.color = Color("#e5484d")
		center_polygon.color = Color("#ffcf70")
	else:
		body_polygon.color = Color("#3f7dd9")
		center_polygon.color = Color("#b8f3ff")


func set_active(is_active: bool) -> void:
	active_ring.visible = is_active


func stop_moving() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
