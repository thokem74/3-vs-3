class_name NationFlag
extends Control

## Draws a compact, recognizable nation flag without requiring texture assets.
## The flag redraws only when its nation changes.

const FLAG_RECT := Rect2(3.0, 3.0, 34.0, 20.0)

var nation_name := ""


func set_nation(new_nation_name: String) -> void:
	if nation_name == new_nation_name:
		return

	nation_name = new_nation_name
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 40.0, 26.0), Color("#080b12"))
	draw_rect(Rect2(1.0, 1.0, 38.0, 24.0), Color("#f7f9f4"))

	match nation_name:
		"BRAZIL":
			_draw_brazil()
		"ARGENTINA":
			_draw_argentina()
		"GERMANY":
			_draw_horizontal_tricolor(Color.BLACK, Color("#dd0000"), Color("#ffcc00"))
		"FRANCE":
			_draw_vertical_tricolor(Color("#0055a4"), Color.WHITE, Color("#ef4135"))
		"NETHERLANDS":
			_draw_horizontal_tricolor(Color("#ae1c28"), Color.WHITE, Color("#21468b"))
		"PORTUGAL":
			_draw_portugal()
		"JAPAN":
			_draw_japan()
		"MEXICO":
			_draw_mexico()
		"NORWAY":
			_draw_norway()
		"SPAIN":
			_draw_spain()
		"ENGLAND":
			_draw_england()
		"SWITZERLAND":
			_draw_switzerland()
		_:
			draw_rect(FLAG_RECT, Color("#303746"))


func _draw_horizontal_tricolor(top: Color, middle: Color, bottom: Color) -> void:
	var band_height := FLAG_RECT.size.y / 3.0
	draw_rect(Rect2(FLAG_RECT.position, Vector2(FLAG_RECT.size.x, band_height)), top)
	draw_rect(
		Rect2(FLAG_RECT.position + Vector2(0.0, band_height), Vector2(FLAG_RECT.size.x, band_height)),
		middle
	)
	draw_rect(
		Rect2(
			FLAG_RECT.position + Vector2(0.0, band_height * 2.0),
			Vector2(FLAG_RECT.size.x, FLAG_RECT.size.y - band_height * 2.0)
		),
		bottom
	)


func _draw_vertical_tricolor(left: Color, middle: Color, right: Color) -> void:
	var band_width := FLAG_RECT.size.x / 3.0
	draw_rect(Rect2(FLAG_RECT.position, Vector2(band_width, FLAG_RECT.size.y)), left)
	draw_rect(
		Rect2(FLAG_RECT.position + Vector2(band_width, 0.0), Vector2(band_width, FLAG_RECT.size.y)),
		middle
	)
	draw_rect(
		Rect2(
			FLAG_RECT.position + Vector2(band_width * 2.0, 0.0),
			Vector2(FLAG_RECT.size.x - band_width * 2.0, FLAG_RECT.size.y)
		),
		right
	)


func _draw_brazil() -> void:
	draw_rect(FLAG_RECT, Color("#009c3b"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(20.0, 4.5),
			Vector2(35.0, 13.0),
			Vector2(20.0, 21.5),
			Vector2(5.0, 13.0),
		]),
		Color("#ffdf00")
	)
	draw_circle(Vector2(20.0, 13.0), 4.7, Color("#002776"), true, -1.0, true)


func _draw_argentina() -> void:
	_draw_horizontal_tricolor(Color("#74acdf"), Color.WHITE, Color("#74acdf"))
	draw_circle(Vector2(20.0, 13.0), 2.2, Color("#f6b40e"), true, -1.0, true)


func _draw_portugal() -> void:
	draw_rect(FLAG_RECT, Color("#da291c"))
	draw_rect(Rect2(FLAG_RECT.position, Vector2(13.0, FLAG_RECT.size.y)), Color("#046a38"))
	draw_circle(Vector2(16.0, 13.0), 2.6, Color("#ffcd00"), true, -1.0, true)


func _draw_japan() -> void:
	draw_rect(FLAG_RECT, Color.WHITE)
	draw_circle(Vector2(20.0, 13.0), 5.5, Color("#bc002d"), true, -1.0, true)


func _draw_mexico() -> void:
	_draw_vertical_tricolor(Color("#006847"), Color.WHITE, Color("#ce1126"))
	draw_circle(Vector2(20.0, 13.0), 2.0, Color("#8c6b2f"), true, -1.0, true)


func _draw_norway() -> void:
	draw_rect(FLAG_RECT, Color("#ba0c2f"))
	draw_rect(Rect2(3.0, 10.0, 34.0, 6.0), Color.WHITE)
	draw_rect(Rect2(13.0, 3.0, 6.0, 20.0), Color.WHITE)
	draw_rect(Rect2(3.0, 12.0, 34.0, 2.0), Color("#00205b"))
	draw_rect(Rect2(15.0, 3.0, 2.0, 20.0), Color("#00205b"))


func _draw_spain() -> void:
	draw_rect(FLAG_RECT, Color("#aa151b"))
	draw_rect(Rect2(3.0, 8.0, 34.0, 10.0), Color("#f1bf00"))


func _draw_england() -> void:
	draw_rect(FLAG_RECT, Color.WHITE)
	draw_rect(Rect2(3.0, 11.0, 34.0, 4.0), Color("#c8102e"))
	draw_rect(Rect2(18.0, 3.0, 4.0, 20.0), Color("#c8102e"))


func _draw_switzerland() -> void:
	draw_rect(FLAG_RECT, Color("#d52b1e"))
	draw_rect(Rect2(11.0, 11.0, 18.0, 4.0), Color.WHITE)
	draw_rect(Rect2(18.0, 6.0, 4.0, 14.0), Color.WHITE)
