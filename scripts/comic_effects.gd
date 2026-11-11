extends Node2D

var bursts: Array[Dictionary] = []

func pop(position: Vector2, color: Color, text: String) -> void:
	bursts.append({"position": position, "color": color, "text": text, "age": 0.0, "life": 0.72})
	queue_redraw()

func _process(delta: float) -> void:
	for burst in bursts:
		burst.age = float(burst.age) + delta
	for i in range(bursts.size() - 1, -1, -1):
		if float(bursts[i].age) >= float(bursts[i].life):
			bursts.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for burst in bursts:
		var age := float(burst.age)
		var life := float(burst.life)
		var t := clampf(age / life, 0.0, 1.0)
		var center: Vector2 = burst.position + Vector2(0, -52.0 * t)
		var radius := 18.0 + t * 54.0
		var color: Color = burst.color
		color.a = 1.0 - t
		for i in 10:
			var angle := TAU * float(i) / 10.0 + age * 2.0
			var inner := center + Vector2(cos(angle), sin(angle)) * (radius * 0.25)
			var outer := center + Vector2(cos(angle), sin(angle)) * radius
			draw_line(inner, outer, color, maxf(2.0, 7.0 - t * 4.0))
		for i in 6:
			var dot_angle := TAU * float(i) / 6.0 - age
			var dot := center + Vector2(cos(dot_angle), sin(dot_angle)) * radius * 0.62
			draw_circle(dot, 3.0 * (1.0 - t), color)
		if t < 0.7:
			var font := ThemeDB.fallback_font
			var label := str(burst.text)
			var font_size := 24
			var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var box := Rect2(center + Vector2(-width * 0.5 - 14, -22), Vector2(width + 28, 42))
			draw_style_box(make_bubble(color), box)
			draw_string(font, center + Vector2(-width * 0.5, 7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#231B28"))

func make_bubble(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 0.96, 0.84, 0.96)
	box.border_color = color
	box.set_border_width_all(4)
	box.set_corner_radius_all(12)
	return box
