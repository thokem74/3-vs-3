extends Node2D

## Pocket Pitch is a small, turn-based flick soccer game. Players drag backward
## from one of their pieces and release. A turn ends once every body settles.

enum GameMode {
	SINGLE_PLAYER,
	TWO_PLAYERS,
}

enum TeamSize {
	THREE_VS_THREE = 3,
	FIVE_VS_FIVE = 5,
}

enum VictoryCondition {
	GOALS,
	TIME,
}

enum MatchState {
	MENU,
	READY,
	SHOT_MOVING,
	AI_THINKING,
	ROUND_PAUSE,
	GAME_OVER,
}

const DISC_SCENE := preload("res://scenes/player_disc.tscn")
const MATCH_RULE_VALUES: Array[int] = [3, 5, 10]
const MIN_DRAG_DISTANCE := 18.0
const MAX_DRAG_DISTANCE := 150.0
const SHOT_STRENGTH := 7.2
const SETTLED_SPEED := 9.0
const SETTLED_TIME := 0.45
const MAX_SHOT_TIME := 8.0
const PITCH_CENTER_X := 576.0
# The score line is one ball radius behind each edge of the field. This means
# the whole ball must enter the goal, while still remaining in front of the
# physical back wall where its center can actually reach the line.
const GOAL_LINE_LEFT := 76.0
const GOAL_LINE_RIGHT := 1076.0
const GOAL_TOP := 254.0
const GOAL_BOTTOM := 394.0

@onready var pieces: Node2D = $Pieces
@onready var ball: RigidBody2D = $Pieces/Ball
@onready var aim_guide: Line2D = $AimGuide
@onready var aim_arrow_head: Polygon2D = $AimGuide/ArrowHead
@onready var menu: Control = $Interface/Menu
@onready var team_customization: TeamCustomization = $Interface/TeamCustomization
@onready var hud: Control = $Interface/HUD
@onready var end_panel: Control = $Interface/EndPanel
@onready var score_label: Label = $Interface/HUD/Score
@onready var timer_label: Label = $Interface/HUD/Timer
@onready var team_one_flag: NationFlag = $Interface/HUD/TeamOneFlag
@onready var team_one_name_label: Label = $Interface/HUD/TeamOneName
@onready var team_two_flag: NationFlag = $Interface/HUD/TeamTwoFlag
@onready var team_two_name_label: Label = $Interface/HUD/TeamTwoName
@onready var turn_label: Label = $Interface/HUD/Turn
@onready var hint_label: Label = $Interface/HUD/Hint
@onready var winner_label: Label = $Interface/EndPanel/Panel/Winner
@onready var retro_audio: RetroAudio = $RetroAudio
@onready var goal_target_button: Button = $Interface/Menu/Panel/GoalTarget
@onready var time_limit_button: Button = $Interface/Menu/Panel/TimeLimit

var game_mode := GameMode.SINGLE_PLAYER
var team_size := TeamSize.THREE_VS_THREE
var victory_condition := VictoryCondition.GOALS
var goal_target := 3
var time_limit_minutes := 3
var remaining_match_time := 0.0
var match_state := MatchState.MENU
var current_team := 1
var scores := [0, 0]
var team_one_pieces: Array[PlayerDisc] = []
var team_two_pieces: Array[PlayerDisc] = []
var selected_piece: PlayerDisc
var dragging := false
var shot_elapsed := 0.0
var settled_elapsed := 0.0
var ai_think_elapsed := 0.0
var round_pause_elapsed := 0.0
var next_round_team := 1
var bump_cooldown := 0.0


func _ready() -> void:
	$Interface/Menu/Panel/ThreeVsThree.pressed.connect(
		_select_team_size.bind(TeamSize.THREE_VS_THREE)
	)
	$Interface/Menu/Panel/FiveVsFive.pressed.connect(
		_select_team_size.bind(TeamSize.FIVE_VS_FIVE)
	)
	$Interface/Menu/Panel/SinglePlayer.pressed.connect(
		_select_game_mode.bind(GameMode.SINGLE_PLAYER)
	)
	$Interface/Menu/Panel/TwoPlayers.pressed.connect(
		_select_game_mode.bind(GameMode.TWO_PLAYERS)
	)
	goal_target_button.pressed.connect(
		_select_victory_condition.bind(VictoryCondition.GOALS)
	)
	time_limit_button.pressed.connect(
		_select_victory_condition.bind(VictoryCondition.TIME)
	)
	$Interface/Menu/Panel/CustomizeTeams.pressed.connect(_show_team_customization)
	$Interface/Menu/Panel/Start.pressed.connect(_start_match)
	$Interface/HUD/MenuButton.pressed.connect(_show_menu)
	$Interface/EndPanel/Panel/PlayAgain.pressed.connect(_restart_match)
	$Interface/EndPanel/Panel/MainMenu.pressed.connect(_show_menu)
	ball.body_entered.connect(_on_body_collided)

	_update_match_rule_buttons()
	_show_menu()


func _physics_process(delta: float) -> void:
	bump_cooldown = maxf(0.0, bump_cooldown - delta)

	if match_state == MatchState.SHOT_MOVING:
		_update_moving_shot(delta)
	elif match_state == MatchState.AI_THINKING:
		_update_ai_turn(delta)
	elif match_state == MatchState.ROUND_PAUSE:
		_update_round_pause(delta)

	if match_state not in [MatchState.MENU, MatchState.GAME_OVER]:
		_check_for_goal()
		_update_match_clock(delta)


func _unhandled_input(event: InputEvent) -> void:
	if match_state != MatchState.READY or _is_ai_turn():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_release_drag(event.position)
	elif event is InputEventScreenDrag:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_release_drag(event.position)
	elif event is InputEventMouseMotion and dragging:
		_update_drag(event.position)


func _create_team_pieces() -> void:
	for child in pieces.get_children():
		if child is PlayerDisc:
			pieces.remove_child(child)
			child.queue_free()

	team_one_pieces.clear()
	team_two_pieces.clear()

	for team_one_position in _team_one_start_positions():
		var team_two_position := _mirror_position(team_one_position)
		var team_one_piece := _create_piece(1, team_one_position)
		var team_two_piece := _create_piece(2, team_two_position)
		team_one_pieces.append(team_one_piece)
		team_two_pieces.append(team_two_piece)


func _create_piece(team: int, start_position: Vector2) -> PlayerDisc:
	var piece := DISC_SCENE.instantiate() as PlayerDisc
	piece.position = start_position
	pieces.add_child(piece)
	# Adding the scene first initializes its @onready visual references.
	var team_colors := team_customization.get_team_colors(team)
	piece.configure(team, team_colors[0], team_colors[1], team_colors[2])
	return piece


func _select_team_size(selected_team_size: TeamSize) -> void:
	team_size = selected_team_size
	retro_audio.play_button()


func _select_game_mode(selected_game_mode: GameMode) -> void:
	game_mode = selected_game_mode
	retro_audio.play_button()


func _select_victory_condition(selected_condition: VictoryCondition) -> void:
	if victory_condition == selected_condition:
		if selected_condition == VictoryCondition.GOALS:
			goal_target = _next_match_rule_value(goal_target)
		else:
			time_limit_minutes = _next_match_rule_value(time_limit_minutes)
	else:
		victory_condition = selected_condition

	_update_match_rule_buttons()
	retro_audio.play_button()


func _next_match_rule_value(current_value: int) -> int:
	var current_index := MATCH_RULE_VALUES.find(current_value)
	var next_index := (current_index + 1) % MATCH_RULE_VALUES.size()
	return MATCH_RULE_VALUES[next_index]


func _update_match_rule_buttons() -> void:
	goal_target_button.text = "%d GOALS" % goal_target
	time_limit_button.text = "%d MIN" % time_limit_minutes
	goal_target_button.button_pressed = victory_condition == VictoryCondition.GOALS
	time_limit_button.button_pressed = victory_condition == VictoryCondition.TIME


func _show_team_customization() -> void:
	retro_audio.play_button()
	team_customization.show_customization()


func _start_match() -> void:
	scores = [0, 0]
	current_team = 1
	remaining_match_time = float(time_limit_minutes * 60)
	timer_label.visible = victory_condition == VictoryCondition.TIME
	_update_timer_label()
	_update_team_hud()
	menu.visible = false
	end_panel.visible = false
	hud.visible = true
	retro_audio.play_button()
	_create_team_pieces()
	_reset_board()
	_begin_ready_turn()


func _restart_match() -> void:
	_start_match()


func _update_team_hud() -> void:
	var team_one_name := team_customization.get_team_name(1)
	var team_two_name := team_customization.get_team_name(2)
	team_one_name_label.text = team_one_name
	team_two_name_label.text = team_two_name
	team_one_flag.set_nation(team_one_name)
	team_two_flag.set_nation(team_two_name)


func _show_menu() -> void:
	match_state = MatchState.MENU
	dragging = false
	selected_piece = null
	aim_guide.visible = false
	_stop_all_bodies()
	menu.visible = true
	hud.visible = false
	end_panel.visible = false
	timer_label.visible = false


func _begin_drag(pointer_position: Vector2) -> void:
	var closest_piece: PlayerDisc
	var closest_distance := 46.0

	for piece in _current_team_pieces():
		var distance := piece.global_position.distance_to(pointer_position)
		if distance < closest_distance:
			closest_piece = piece
			closest_distance = distance

	if closest_piece == null:
		return

	selected_piece = closest_piece
	dragging = true
	aim_guide.visible = true
	_update_drag(pointer_position)


func _update_drag(pointer_position: Vector2) -> void:
	if not dragging or selected_piece == null:
		return

	var pull_vector := selected_piece.global_position - pointer_position
	if pull_vector.length() > MAX_DRAG_DISTANCE:
		pull_vector = pull_vector.normalized() * MAX_DRAG_DISTANCE

	# The three points show the finger, the selected piece, and the shot path.
	var shot_end := selected_piece.global_position + pull_vector * 1.35
	aim_guide.points = PackedVector2Array([
		selected_piece.global_position - pull_vector,
		selected_piece.global_position,
		shot_end,
	])
	aim_arrow_head.position = shot_end
	aim_arrow_head.rotation = pull_vector.angle()


func _release_drag(pointer_position: Vector2) -> void:
	if not dragging or selected_piece == null:
		return

	var pull_vector := selected_piece.global_position - pointer_position
	pull_vector = pull_vector.limit_length(MAX_DRAG_DISTANCE)
	dragging = false
	aim_guide.visible = false

	if pull_vector.length() < MIN_DRAG_DISTANCE:
		selected_piece = null
		return

	selected_piece.apply_central_impulse(pull_vector * SHOT_STRENGTH)
	selected_piece = null
	retro_audio.play_shot()
	_start_shot_motion()


func _start_shot_motion() -> void:
	match_state = MatchState.SHOT_MOVING
	shot_elapsed = 0.0
	settled_elapsed = 0.0
	hint_label.text = "BALL IN PLAY"
	_set_piece_highlights(false)


func _update_moving_shot(delta: float) -> void:
	shot_elapsed += delta

	if _all_bodies_settled():
		settled_elapsed += delta
	else:
		settled_elapsed = 0.0

	if settled_elapsed >= SETTLED_TIME or shot_elapsed >= MAX_SHOT_TIME:
		_stop_all_bodies()
		current_team = 2 if current_team == 1 else 1
		_begin_ready_turn()


func _begin_ready_turn() -> void:
	_update_hud()
	_set_piece_highlights(true)

	if _is_ai_turn():
		match_state = MatchState.AI_THINKING
		ai_think_elapsed = 0.0
		hint_label.text = "CPU IS THINKING..."
	else:
		match_state = MatchState.READY
		hint_label.text = "DRAG BACK • RELEASE TO SHOOT"


func _update_ai_turn(delta: float) -> void:
	ai_think_elapsed += delta
	if ai_think_elapsed < 0.75:
		return

	var chosen_piece := _closest_piece_to_ball(team_two_pieces)
	var target := ball.global_position

	# A small lead toward the player's goal makes the AI purposeful but beatable.
	var goal_direction := Vector2.LEFT
	var approach_offset := goal_direction * 16.0
	var shot_direction := (target + approach_offset - chosen_piece.global_position).normalized()
	var distance_to_ball := chosen_piece.global_position.distance_to(target)
	var power := clampf(distance_to_ball * 1.65, 500.0, 880.0)

	chosen_piece.apply_central_impulse(shot_direction * power)
	retro_audio.play_shot()
	_start_shot_motion()


func _check_for_goal() -> void:
	if ball.global_position.y < GOAL_TOP or ball.global_position.y > GOAL_BOTTOM:
		return

	if ball.global_position.x < GOAL_LINE_LEFT:
		_score_goal(2)
	elif ball.global_position.x > GOAL_LINE_RIGHT:
		_score_goal(1)


func _score_goal(scoring_team: int) -> void:
	if match_state == MatchState.ROUND_PAUSE:
		return

	scores[scoring_team - 1] += 1
	retro_audio.play_goal()
	_stop_all_bodies()
	_update_hud()

	if (
		victory_condition == VictoryCondition.GOALS
		and scores[scoring_team - 1] >= goal_target
	):
		_finish_match(scoring_team)
		return

	match_state = MatchState.ROUND_PAUSE
	round_pause_elapsed = 0.0
	next_round_team = 2 if scoring_team == 1 else 1
	turn_label.text = "GOAL!"
	hint_label.text = "TEAM %d SCORES" % scoring_team
	_set_piece_highlights(false)


func _update_round_pause(delta: float) -> void:
	round_pause_elapsed += delta
	if round_pause_elapsed < 1.25:
		return

	current_team = next_round_team
	_reset_board()
	_begin_ready_turn()


func _update_match_clock(delta: float) -> void:
	if victory_condition != VictoryCondition.TIME:
		return

	remaining_match_time = maxf(0.0, remaining_match_time - delta)
	_update_timer_label()
	if remaining_match_time > 0.0:
		return

	if scores[0] > scores[1]:
		_finish_match(1)
	elif scores[1] > scores[0]:
		_finish_match(2)
	else:
		_finish_match(0)


func _update_timer_label() -> void:
	var total_seconds := ceili(remaining_match_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _finish_match(winning_team: int) -> void:
	match_state = MatchState.GAME_OVER
	dragging = false
	selected_piece = null
	aim_guide.visible = false
	_stop_all_bodies()
	hud.visible = false
	end_panel.visible = true
	_set_piece_highlights(false)

	if winning_team == 0:
		winner_label.text = "DRAW!"
	elif game_mode == GameMode.SINGLE_PLAYER:
		winner_label.text = "YOU WIN!" if winning_team == 1 else "CPU WINS"
	else:
		winner_label.text = "TEAM %d WINS!" % winning_team


func _reset_board() -> void:
	ball.position = Vector2(576.0, 324.0)
	ball.rotation = 0.0
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0

	var team_one_positions := _team_one_start_positions()
	for index in team_one_positions.size():
		team_one_pieces[index].position = team_one_positions[index]
		team_two_pieces[index].position = _mirror_position(team_one_positions[index])
		team_one_pieces[index].rotation = 0.0
		team_two_pieces[index].rotation = 0.0
		team_one_pieces[index].stop_moving()
		team_two_pieces[index].stop_moving()


func _team_one_start_positions() -> Array[Vector2]:
	if team_size == TeamSize.FIVE_VS_FIVE:
		return [
			Vector2(220.0, 324.0),
			Vector2(340.0, 220.0),
			Vector2(340.0, 428.0),
			Vector2(455.0, 270.0),
			Vector2(455.0, 378.0),
		]

	return [
		Vector2(270.0, 324.0),
		Vector2(400.0, 245.0),
		Vector2(400.0, 403.0),
	]


func _mirror_position(position: Vector2) -> Vector2:
	return Vector2(PITCH_CENTER_X * 2.0 - position.x, position.y)


func _stop_all_bodies() -> void:
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	for piece in team_one_pieces + team_two_pieces:
		piece.stop_moving()


func _all_bodies_settled() -> bool:
	if ball.linear_velocity.length() > SETTLED_SPEED:
		return false

	for piece in team_one_pieces + team_two_pieces:
		if piece.linear_velocity.length() > SETTLED_SPEED:
			return false
	return true


func _current_team_pieces() -> Array[PlayerDisc]:
	return team_one_pieces if current_team == 1 else team_two_pieces


func _closest_piece_to_ball(team_pieces: Array[PlayerDisc]) -> PlayerDisc:
	var closest_piece := team_pieces[0]
	var closest_distance := closest_piece.global_position.distance_squared_to(ball.global_position)

	for piece in team_pieces:
		var distance := piece.global_position.distance_squared_to(ball.global_position)
		if distance < closest_distance:
			closest_piece = piece
			closest_distance = distance
	return closest_piece


func _is_ai_turn() -> bool:
	return game_mode == GameMode.SINGLE_PLAYER and current_team == 2


func _set_piece_highlights(show_current_team: bool) -> void:
	for piece in team_one_pieces + team_two_pieces:
		piece.set_active(show_current_team and piece.team == current_team)


func _update_hud() -> void:
	score_label.text = "%d  :  %d" % [scores[0], scores[1]]
	if game_mode == GameMode.SINGLE_PLAYER:
		turn_label.text = "YOUR TURN" if current_team == 1 else "CPU TURN"
	else:
		turn_label.text = "TEAM %d TURN" % current_team


func _on_body_collided(_body: Node) -> void:
	if bump_cooldown > 0.0 or match_state != MatchState.SHOT_MOVING:
		return
	bump_cooldown = 0.08
	retro_audio.play_bump()
