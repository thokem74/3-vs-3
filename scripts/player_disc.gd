class_name PlayerDisc
extends RigidBody2D

## A single team piece. Its visible parts live in player_disc.tscn; this script
## manages its team, selected kit colors, and physics state.

@onready var body_polygon: Polygon2D = $Body
@onready var center_polygon: Polygon2D = $Center
@onready var active_ring: Line2D = $ActiveRing

var team: int = 1


func configure(new_team: int, body_color: Color, center_color: Color) -> void:
	team = new_team
	body_polygon.color = body_color
	center_polygon.color = center_color


func set_active(is_active: bool) -> void:
	active_ring.visible = is_active


func stop_moving() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
