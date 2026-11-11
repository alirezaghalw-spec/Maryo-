extends Control

var title_label: Label
var start_button: Button
var pulse := 0.0

const INK := Color("#231B28")
const CREAM := Color("#FFF4D6")
const TEAL := Color("#26C6B6")
const RED := Color("#F4513A")
const YELLOW := Color("#FFD166")
const UI_FONT = preload("res://assets/template/fonts/ui_regular.tres")

func _ready() -> void:
	set_process(true)
	build_ui()
	apply_font_recursive(self)
	queue_redraw()
	start_button.grab_focus()

func build_ui() -> void:
	var style := Theme.new()
	style.default_font_size = 22
	style.default_base_scale = 1.0
	theme = style
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-290, -220)
	panel.size = Vector2(580, 440)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#FFF4D6")
	panel_style.border_color = INK
	panel_style.set_border_width_all(7)
	panel_style.corner_radius_top_left = 28
	panel_style.corner_radius_top_right = 28
	panel_style.corner_radius_bottom_left = 28
	panel_style.corner_radius_bottom_right = 28
	panel_style.shadow_color = Color(0.05, 0.03, 0.08, 0.35)
	panel_style.shadow_size = 20
	panel_style.shadow_offset = Vector2(0, 12)
	panel_style.content_margin_left = 38
	panel_style.content_margin_right = 38
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 12)
	box.add_theme_constant_override("margin_left", 38)
	box.add_theme_constant_override("margin_right", 38)
	box.add_theme_constant_override("margin_top", 28)
	box.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(box)
	var kicker := Label.new()
	kicker.text = "MUSHROOM MAYHEM  /  COMIC EDITION"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_color_override("font_color", RED)
	box.add_child(kicker)
	title_label = Label.new()
	title_label.text = "قارچ‌خورِ کمیک"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", INK)
	title_label.add_theme_color_override("font_outline_color", Color("#F4513A"))
	title_label.add_theme_constant_override("outline_size", 3)
	box.add_child(title_label)
	var subtitle := Label.new()
	subtitle.text = "صفحه را ورق بزن؛ سکه جمع کن، دشمن‌ها را له کن!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", INK)
	box.add_child(subtitle)
	var speech := Label.new()
	speech.text = "بزن بریم!"
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech.add_theme_font_size_override("font_size", 26)
	speech.add_theme_color_override("font_color", INK)
	speech.add_theme_stylebox_override("normal", speech_style(YELLOW, 5, 18))
	speech.custom_minimum_size.y = 54
	box.add_child(speech)
	var controls := Label.new()
	controls.text = "حرکت: ← → یا A / D     پرش: Space\nروی موبایل از دکمه‌های لمسی استفاده کن"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", Color("#5E4A4A"))
	box.add_child(controls)
	start_button = Button.new()
	start_button.text = "شروع ماجرا"
	start_button.custom_minimum_size.y = 70
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.add_theme_color_override("font_color", CREAM)
	start_button.add_theme_color_override("font_hover_color", CREAM)
	start_button.add_theme_stylebox_override("normal", button_style(TEAL, INK, 6, 18))
	start_button.add_theme_stylebox_override("hover", button_style(Color("#3DE0CE"), INK, 7, 18))
	start_button.add_theme_stylebox_override("pressed", button_style(Color("#1EA494"), INK, 5, 18))
	start_button.pressed.connect(start_game)
	box.add_child(start_button)
	var legal := Label.new()
	legal.text = "یک بازی مستقل و اورجینال؛ بدون دارایی رسمی ماریو یا نینتندو"
	legal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legal.add_theme_font_size_override("font_size", 13)
	legal.add_theme_color_override("font_color", Color("#90766A"))
	box.add_child(legal)

func speech_style(color: Color, border: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = INK
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func button_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return speech_style(fill, border_width, radius)

func apply_font_recursive(node: Node) -> void:
	if node is Control:
		node.add_theme_font_override("font", UI_FONT)
	for child in node.get_children():
		apply_font_recursive(child)

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()
	if title_label:
		title_label.rotation = sin(pulse * 1.5) * 0.01

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#26C6B6"))
	for x in range(-20, int(size.x) + 20, 28):
		for y in range(-20, int(size.y) + 20, 28):
			draw_circle(Vector2(x + (y % 2) * 8, y), 2.0, Color(0.1, 0.07, 0.12, 0.12))
	draw_circle(Vector2(size.x * 0.84, size.y * 0.18), 92, Color("#FFD166"))
	draw_circle(Vector2(size.x * 0.84, size.y * 0.18), 92, INK, false, 6.0)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var p1 := Vector2(size.x * 0.84, size.y * 0.18) + Vector2(cos(a), sin(a)) * 112
		var p2 := Vector2(size.x * 0.84, size.y * 0.18) + Vector2(cos(a), sin(a)) * 154
		draw_line(p1, p2, INK, 6.0)
	draw_rect(Rect2(0, size.y - 64, size.x, 64), Color("#F4513A"))
	draw_line(Vector2(0, size.y - 64), Vector2(size.x, size.y - 64), INK, 8.0)
	for x in range(0, int(size.x), 42):
		draw_line(Vector2(x, size.y - 58), Vector2(x + 20, size.y - 20), Color("#231B28"), 3.0)
	var c := Vector2(size.x * 0.13, size.y * 0.22)
	draw_circle(c + Vector2(0, 32), 33, Color("#FFD0A6"))
	draw_circle(c + Vector2(0, 32), 33, INK, false, 6.0)
	draw_circle(c + Vector2(0, 2), 42, Color("#A7E64F"))
	draw_arc(c + Vector2(0, 2), 42, PI, TAU, 24, INK, 6.0)
	draw_circle(c + Vector2(-15, -10), 8, Color("#FFF4D6"))
	draw_circle(c + Vector2(15, -14), 7, Color("#FFF4D6"))
	draw_circle(c + Vector2(-11, 32), 5, INK)
	draw_circle(c + Vector2(11, 32), 5, INK)
	draw_line(c + Vector2(-20, 74), c + Vector2(-36, 108), INK, 8.0)
	draw_line(c + Vector2(20, 74), c + Vector2(36, 108), INK, 8.0)

func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
