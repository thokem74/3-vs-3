class_name PitchBody
extends RigidBody2D

## Shared physics-safe repositioning for the ball and team pieces.

var reset_pending := false
var _reset_position := Vector2.ZERO


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not reset_pending:
		return

	# Change the simulation's transform so an old physics update cannot undo
	# the kickoff placement. Clear any motion from the previous play as well.
	state.transform = Transform2D(0.0, _reset_position)
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	reset_pending = false
	reset_physics_interpolation()


func reset_to(start_position: Vector2) -> void:
	_reset_position = start_position
	reset_pending = true
	# Sleeping bodies need to wake up to receive their integration callback.
	sleeping = false
