extends SceneTree

## Run with: godot --headless --path . --script tests/post_goal_reset.gd

var failures := 0


func _initialize() -> void:
	_run_checks.call_deferred()


func _run_checks() -> void:
	var match_scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(match_scene)
	match_scene.game_mode = match_scene.GameMode.TWO_PLAYERS
	match_scene.goal_target = 100

	for team_size in [3, 5]:
		match_scene.team_size = team_size
		match_scene._start_match()
		await _wait_frames(5)
		_check_formation(match_scene, "match start, %d players" % team_size)

		for goal_index in 12:
			# Cover human kickoffs and all CPU levels, before the CPU shoots.
			match_scene.game_mode = (
				match_scene.GameMode.TWO_PLAYERS
				if goal_index < 6 else match_scene.GameMode.SINGLE_PLAYER
			)
			match_scene.cpu_level = goal_index % 3 + 1
			var shooter: PlayerDisc = match_scene._current_team_pieces()[0]
			match_scene._start_shot_motion(shooter)
			# Leave bodies asleep, moving, and touching at different locations.
			# This exercises physics synchronization rather than only scene positions.
			var bodies: Array[RigidBody2D] = [match_scene.ball]
			bodies.append_array(match_scene.team_one_pieces)
			bodies.append_array(match_scene.team_two_pieces)
			for index in bodies.size():
				var body := bodies[index]
				# Keep the tracked shooter clear of this artificial contact pile.
				# The test below exercises legal goals; fouls have a separate suite.
				if body == shooter:
					body.reset_to(Vector2(200.0, 150.0))
					continue
				body.global_position = Vector2(480.0 + index * 25.0, 320.0)
				body.linear_velocity = Vector2(300.0 - index * 50.0, 80.0)
				body.angular_velocity = 2.0
				body.sleeping = index % 2 == 0
			await _wait_frames(3)

			var scoring_team: int = goal_index % 2 + 1
			var previous_scores: Array = match_scene.scores.duplicate()
			var goal_x := 1082.0 if scoring_team == 1 else 70.0
			match_scene.ball.reset_to(Vector2(goal_x, 324.0))
			await _wait_frames(5)
			_check(
				match_scene.match_state == match_scene.MatchState.ROUND_PAUSE,
				"Ball crossing goal line starts celebration",
			)
			# Finish the celebration on the next actual physics tick.
			match_scene.round_pause_elapsed = 1.25
			await _wait_frames(10)
			_check_formation(match_scene, "goal %d, %d players" % [goal_index + 1, team_size])
			_check(match_scene.current_team == 3 - scoring_team, "Conceding team kicks off")
			for team_index in 2:
				var expected_score: int = previous_scores[team_index]
				if team_index == scoring_team - 1:
					expected_score += 1
				_check(match_scene.scores[team_index] == expected_score, "Goal counts once")
			if match_scene._is_ai_turn():
				_check(
					match_scene.match_state == match_scene.MatchState.AI_THINKING,
					"CPU plans the kickoff after reset",
				)
				var expected_direction: Vector2 = (
					match_scene._ai_aim_target() - match_scene.ai_planned_piece.global_position
				).normalized()
				_check(
					match_scene.ai_planned_direction.is_equal_approx(expected_direction),
					"CPU aims from the restored formation",
				)
			else:
				_check(match_scene.match_state == match_scene.MatchState.READY, "Turn is ready")

	# Let the audio thread release the last goal sound before shutting down.
	match_scene.retro_audio.effect_player.stop()
	await _wait_frames(5)
	match_scene.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: formations stay correct after 24 goals across 3v3 and 5v5.")
	quit(1 if failures > 0 else 0)


func _wait_frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func _check_formation(match_scene: Node, context: String) -> void:
	_check_body(match_scene.ball, Vector2(576.0, 324.0), context + ": ball")
	var positions: Array[Vector2] = match_scene._team_one_start_positions()
	for index in positions.size():
		_check_body(match_scene.team_one_pieces[index], positions[index], context + ": team 1")
		_check_body(
			match_scene.team_two_pieces[index],
			match_scene._mirror_position(positions[index]),
			context + ": team 2",
		)


func _check_body(body: RigidBody2D, expected_position: Vector2, context: String) -> void:
	_check(body.global_position.distance_to(expected_position) < 0.1, context + ": position")
	_check(body.linear_velocity.length() < 0.1, context + ": velocity")
	_check(absf(body.angular_velocity) < 0.1, context + ": angular velocity")
	_check(absf(body.rotation) < 0.001, context + ": rotation")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
