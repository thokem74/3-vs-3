class_name PitchBody
extends RigidBody2D

## Shared physics-safe repositioning for the ball and team pieces.

var reset_pending := false
var _reset_position := Vector2.ZERO
var _reset_rotation := 0.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not reset_pending:
		return

	# Change the simulation's transform so an old physics update cannot undo
	# the kickoff placement. Clear any motion from the previous play as well.
	state.transform = Transform2D(_reset_rotation, _reset_position)
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	reset_pending = false
	reset_physics_interpolation()


func reset_to(start_position: Vector2, start_rotation: float = 0.0) -> void:
	_reset_position = start_position
	_reset_rotation = start_rotation
	reset_pending = true
	# Sleeping bodies need to wake up to receive their integration callback.
	sleeping = false
