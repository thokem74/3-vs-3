class_name PlayerDisc
extends PitchBody

## A single team piece. Its visible parts live in player_disc.tscn; this script
## manages its team, selected kit colors, and physics state.

signal shot_contacts_reported(touched_ball: bool, touched_opponent: bool)

@onready var body_polygon: Polygon2D = $Body
@onready var inner_polygon: Polygon2D = $Inner
@onready var center_polygon: Polygon2D = $Center
@onready var active_ring: Line2D = $ActiveRing

var team: int = 1
# Only the flicked piece watches contacts, until it plays the ball or fouls.
var shot_ball: PitchBody


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var was_resetting := reset_pending
	super._integrate_forces(state)
	if was_resetting or shot_ball == null:
		return

	var touched_ball := false
	var touched_opponent := false
	for contact_index in state.get_contact_count():
		var collider := state.get_contact_collider_object(contact_index)
		if collider == shot_ball:
			touched_ball = true
		elif collider is PlayerDisc and collider.team != team:
			touched_opponent = true

	# Report a whole physics step together: simultaneous ball and opponent
	# contact counts as ball-first, regardless of the engine's contact order.
	if touched_ball or touched_opponent:
		shot_contacts_reported.emit(touched_ball, touched_opponent)


func configure(
		new_team: int,
		body_color: Color,
		inner_color: Color,
		center_color: Color,
) -> void:
	team = new_team
	body_polygon.color = body_color
	inner_polygon.color = inner_color
	center_polygon.color = center_color


func set_active(is_active: bool) -> void:
	active_ring.visible = is_active


func stop_moving() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
