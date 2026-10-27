extends SceneTree

## Run with: godot --headless --path . --script tests/foul_rules.gd
## Real physics collisions cover detection; controlled contact reports cover
## simultaneous contacts and ordering that would otherwise depend on timing.

var game: Node
var failures := 0
var checks := 0


func _initialize() -> void:
	_run_checks.call_deferred()


func _run_checks() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for team_size in [3, 5]:
		for shooting_team in [1, 2]:
			await _check_foul_restore(team_size, shooting_team)
		await _check_contact_rules(team_size)
		await _check_turn_sequence(team_size)
		await _check_goals(team_size)
	for level in [1, 2, 3]:
		await _check_cpu(level)
	await _check_lifecycle()
	game.retro_audio.effect_player.stop()
	await _wait_frames(5)
	game.queue_free()
	await process_frame
	print("Foul rules: %d checks, %d failures." % [checks, failures])
	quit(1 if failures > 0 else 0)


func _new_match(team_size: int = 3, shooting_team: int = 1) -> void:
	game.game_mode = game.GameMode.TWO_PLAYERS
	game.victory_condition = game.VictoryCondition.GOALS
	game.goal_target = 100
	game.team_size = team_size
	game._start_match()
	await _wait_frames(5)
	game.current_team = shooting_team
	game._begin_ready_turn()


func _layout(shooting_team: int, ball_first: bool = false) -> PlayerDisc:
	# All spare discs are separated, leaving a clear horizontal test lane.
	for index in game.team_one_pieces.size():
		game.team_one_pieces[index].reset_to(Vector2(180.0 + index * 85.0, 480.0), 0.1 * index)
		game.team_two_pieces[index].reset_to(Vector2(970.0 - index * 85.0, 480.0), -0.1 * index)
	var shooter: PlayerDisc = game._current_team_pieces()[0]
	var opponents: Array[PlayerDisc] = (
		game.team_two_pieces if shooting_team == 1 else game.team_one_pieces
	)
	var ball_position := Vector2(450.0, 324.0) if ball_first else Vector2(760.0, 324.0)
	var opponent_position := Vector2(720.0, 324.0) if ball_first else Vector2(450.0, 324.0)
	shooter.reset_to(_position_for_team(Vector2(330.0, 324.0), shooting_team), 0.4)
	opponents[0].reset_to(_position_for_team(opponent_position, shooting_team), -0.6)
	game.ball.reset_to(_position_for_team(ball_position, shooting_team), 0.7)
	await _wait_frames(5)
	return shooter


func _position_for_team(position: Vector2, team: int) -> Vector2:
	return position if team == 1 else game._mirror_position(position)


func _snapshot() -> Dictionary[PitchBody, Transform2D]:
	var result: Dictionary[PitchBody, Transform2D] = {game.ball: game.ball.global_transform}
	for piece: PlayerDisc in game.team_one_pieces + game.team_two_pieces:
		result[piece as PitchBody] = piece.global_transform
	return result


func _touch_shot(shooter: PlayerDisc) -> void:
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = shooter.global_position
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	var direction := Vector2.RIGHT if shooter.team == 1 else Vector2.LEFT
	release.position = shooter.global_position - direction * 130.0
	game._unhandled_input(release)


func _wait_for_foul() -> void:
	for frame in 150:
		if game.shot_foul:
			return
		await _wait_frames(1)
	_check(false, "Opponent-first collision must register a foul")


func _finish_shot() -> void:
	game.shot_elapsed = game.MAX_SHOT_TIME
	await _wait_frames(5)


func _check_foul_restore(team_size: int, shooting_team: int) -> void:
	await _new_match(team_size, shooting_team)
	var shooter := await _layout(shooting_team)
	var saved := _snapshot()
	_touch_shot(shooter)
	_check(game.active_shooter == shooter, "Touch input tracks the flicked piece")
	_check(game.pre_shot_transforms == saved, "Snapshot precedes the impulse")
	await _wait_for_foul()
	_check(game.match_state == game.MatchState.SHOT_MOVING, "Foul lets movement finish")
	_check(game.turn_label.text == "FOUL", "Foul is visible")
	_check(
		game.hint_label.text == "OPPONENT FIRST • FREE KICK TO TEAM %d" % (3 - shooting_team),
		"Foul announces the opponent's free kick",
	)
	_check(shooter.linear_velocity.length() > 0.1, "Foul does not stop the shooter immediately")
	_check_label_fits(game.hint_label, 440.0)
	# A later ball contact or repeated opponent contact cannot reverse/stack it.
	shooter.shot_contacts_reported.emit(true, false)
	shooter.shot_contacts_reported.emit(false, true)
	_check(game.shot_foul and not game.ball_played, "Foul stays latched")
	# Neither a goal nor an own goal can count after the foul.
	for goal_x in [70.0, 1082.0]:
		game.ball.reset_to(Vector2(goal_x, 324.0))
		await _wait_frames(3)
		_check(game.scores == [0, 0], "Fouling shot cannot score for either team")
	await _finish_shot()
	_check(game.current_team == 3 - shooting_team, "Opponent receives the penalty")
	_check(game.moves_remaining == 1, "Award is exactly one free kick")
	_check(game.match_state == game.MatchState.READY, "Ready only after restoring the board")
	_check_label_fits(game.turn_label, 312.0)
	for body: PitchBody in saved:
		_check(body.global_transform.is_equal_approx(saved[body]), "Restore full pre-shot transform")
		_check(body.linear_velocity.is_zero_approx(), "Restored body has no linear velocity")
		_check(is_zero_approx(body.angular_velocity), "Restored body has no angular velocity")
	_check(game.pre_shot_transforms.is_empty(), "Completed foul releases its snapshot")


func _check_contact_rules(team_size: int) -> void:
	await _new_match(team_size)
	var shooter := await _layout(1, true)
	_touch_shot(shooter)
	for frame in 90:
		if game.ball_played:
			break
		await _wait_frames(1)
	_check(game.ball_played and not game.shot_foul, "Real ball-first collision is legal")
	shooter.shot_contacts_reported.emit(false, true)
	_check(not game.shot_foul, "Opponent contact after the ball stays legal")
	await _finish_shot()
	_check(game.current_team == 2 and game.moves_remaining == 1, "Legal shot alternates teams")

	await _new_match(team_size)
	shooter = await _layout(1)
	game._start_shot_motion(shooter)
	game.team_one_pieces[1].shot_contacts_reported.emit(false, true)
	_check(not game.shot_foul, "Indirect teammate collision does not foul")
	shooter.shot_contacts_reported.emit(true, true)
	_check(game.ball_played and not game.shot_foul, "Same-step contacts favor ball-first")
	await _finish_shot()

	await _new_match(team_size)
	shooter = await _layout(1)
	game.team_two_pieces[0].reset_to(Vector2(900.0, 150.0))
	game.team_one_pieces[1].reset_to(Vector2(450.0, 324.0))
	await _wait_frames(3)
	_touch_shot(shooter)
	await _wait_frames(25)
	_check(game.team_one_pieces[1].global_position.x > 455.0, "Shot actually hits a teammate")
	_check(not game.shot_foul and not game.ball_played, "Teammate contact alone is legal")
	await _finish_shot()

	await _new_match(team_size)
	shooter = await _layout(1)
	shooter.reset_to(Vector2(330.0, 135.0))
	await _wait_frames(3)
	game._start_shot_motion(shooter)
	shooter.apply_central_impulse(Vector2(0.0, -400.0))
	await _wait_frames(20)
	_check(shooter.global_position.y > 135.0, "Shot actually bounces off the wall")
	_check(not game.shot_foul and not game.ball_played, "Wall contact alone is legal")
	await _finish_shot()

	await _new_match(team_size)
	shooter = await _layout(1)
	game._start_shot_motion(shooter)
	shooter.apply_central_impulse(Vector2(0.0, -30.0))
	await _finish_shot()
	_check(game.current_team == 2 and game.moves_remaining == 1, "A complete miss is legal")


func _check_turn_sequence(team_size: int) -> void:
	for shooting_team in [1, 2]:
		await _new_match(team_size, shooting_team)
		var shooter := await _layout(shooting_team)
		_touch_shot(shooter)
		await _wait_for_foul()
		await _finish_shot()
		game._start_shot_motion(game._current_team_pieces()[0])
		await _finish_shot()
		_check(
			game.current_team == shooting_team and game.moves_remaining == 1,
			"Switch teams after the single legal free kick",
		)
		_check(game.turn_label.text.contains("1 MOVE"), "HUD shows one move")

	await _new_match(team_size)
	for shooting_team in [1, 2, 1]:
		var shooter := await _layout(shooting_team)
		_touch_shot(shooter)
		await _wait_for_foul()
		await _finish_shot()
		_check(
			game.current_team == 3 - shooting_team and game.moves_remaining == 1,
			"Repeated foul awards exactly one free kick to the other team",
		)


func _check_goals(team_size: int) -> void:
	await _new_match(team_size, 2)
	var shooter := await _layout(2)
	_touch_shot(shooter)
	await _wait_for_foul()
	await _finish_shot()
	game._start_shot_motion(game.team_one_pieces[0])
	game.ball.reset_to(Vector2(1082.0, 324.0))
	await _wait_frames(5)
	_check(game.scores == [1, 0], "Legal free kick can score")
	_check(game.moves_remaining == 1, "Legal goal leaves one kickoff move")
	game.round_pause_elapsed = 1.25
	await _wait_frames(5)
	_check(
		game.current_team == 2 and game.match_state == game.MatchState.READY,
		"Conceding team kicks off",
	)


func _check_cpu(level: int) -> void:
	await _new_match(5, 2)
	var shooter := await _layout(2)
	game.ball.reset_to(Vector2(572.0, 324.0))
	for index in range(1, game.team_two_pieces.size()):
		game.team_two_pieces[index].reset_to(Vector2(970.0, 130.0 + index * 90.0))
	await _wait_frames(5)
	var saved := _snapshot()
	game.game_mode = game.GameMode.SINGLE_PLAYER
	game.cpu_level = level
	game._begin_ready_turn()
	_check(game.ai_planned_piece == shooter, "CPU fixture selects blocked shooter")
	await _wait_for_foul()
	_check(game.pre_shot_transforms == saved, "CPU snapshots before its impulse")
	await _finish_shot()
	_check(game.current_team == 1 and game.moves_remaining == 1, "CPU foul awards human one free kick")

	await _new_match()
	shooter = await _layout(1)
	_touch_shot(shooter)
	await _wait_for_foul()
	game.game_mode = game.GameMode.SINGLE_PLAYER
	game.cpu_level = level
	await _finish_shot()
	_check(game.current_team == 2 and game.moves_remaining == 1, "Human foul awards CPU one free kick")
	_check_label_fits(game.turn_label, 312.0)
	for frame in 90:
		if game.match_state == game.MatchState.SHOT_MOVING:
			break
		await _wait_frames(1)
	_check(game.active_shooter != null, "CPU automatically launches its free kick")
	await _finish_shot()
	_check(game.current_team == 1 and game.moves_remaining == 1, "CPU yields after one free kick")


func _check_lifecycle() -> void:
	await _new_match()
	var shooter := await _layout(1)
	_touch_shot(shooter)
	await _wait_for_foul()
	game.victory_condition = game.VictoryCondition.TIME
	game.remaining_match_time = 5.0
	await _finish_shot()
	_check(game.remaining_match_time < 5.0, "Foul restoration does not refund time")
	game._show_menu()
	_check(
		game.moves_remaining == 1 and game.pre_shot_transforms.is_empty(),
		"Menu clears penalty state",
	)
	game._restart_match()
	await _wait_frames(5)
	_check(game.current_team == 1 and game.moves_remaining == 1, "Restart begins with one move")
	_check(game.active_shooter == null and not game.shot_foul, "Restart clears contact tracking")

	shooter = await _layout(1)
	_touch_shot(shooter)
	await _wait_for_foul()
	game.remaining_match_time = 0.001
	await _wait_frames(5)
	_check(game.match_state == game.MatchState.GAME_OVER, "Match can expire during a foul")
	_check(
		game.moves_remaining == 1 and game.pre_shot_transforms.is_empty(),
		"Match end clears penalty state",
	)
	await _wait_frames(5)
	_check(
		game.match_state == game.MatchState.GAME_OVER,
		"Pending play cannot reopen a finished match",
	)


func _check_label_fits(label: Label, width: float) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_check(text_width <= width, "HUD text fits its scene-authored width: " + label.text)


func _wait_frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
