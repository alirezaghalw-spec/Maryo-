extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/comic_player.gd")
const EFFECTS_SCRIPT = preload("res://scripts/comic_effects.gd")

const INK := Color("#231B28")
const SKY := Color("#26C6B6")
const TEAL := Color("#26C6B6")
const CREAM := Color("#FFF4D6")
const RED := Color("#F4513A")
const YELLOW := Color("#FFD166")
const GREEN := Color("#A7E64F")
const PURPLE := Color("#6746A8")
const UI_FONT = preload("res://assets/template/fonts/ui_regular.tres")

var player: CharacterBody2D
var effects: Node2D
var platforms: Array[Rect2] = []
var coins: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var mushroom := Vector2.ZERO
var mushroom_taken := false
var finish_x := 0.0
var section := 0
var score := 0
var coin_count := 0
var lives := 3
var power_time := 0.0
var time := 0.0
var game_state := "playing"
var banner_timer := 0.0
var camera: Camera2D
var collision_root: Node2D
var hud: CanvasLayer
var score_label: Label
var coin_label: Label
var lives_label: Label
var section_label: Label
var banner: Label
var pause_panel: Panel
var left_button: Button
var right_button: Button
var jump_button: Button
var prev_touch := false

func _ready() -> void:
	create_world()
	create_hud()
	start_section(0)
	queue_redraw()

func create_world() -> void:
	effects = EFFECTS_SCRIPT.new()
	effects.name = "ComicEffects"
	effects.z_index = 10
	add_child(effects)
	var player_node := PLAYER_SCRIPT.new()
	player = player_node
	player.name = "Hero"
	player.took_damage.connect(_on_player_hurt)
	player.jumped.connect(_on_player_jump)
	add_child(player)
	collision_root = Node2D.new()
	collision_root.name = "PlatformCollisions"
	add_child(collision_root)
	camera = Camera2D.new()
	camera.position = Vector2(300, -90)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = 2600
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)

func start_section(index: int) -> void:
	section = index
	game_state = "playing"
	banner_timer = 0.0
	platforms.clear()
	coins.clear()
	enemies.clear()
	particles.clear()
	mushroom_taken = false
	power_time = 0.0
	if section == 0:
		platforms = [Rect2(0, 610, 760, 150), Rect2(920, 610, 600, 150), Rect2(1690, 610, 920, 150), Rect2(260, 470, 220, 34), Rect2(610, 380, 220, 34), Rect2(1010, 470, 220, 34), Rect2(1320, 360, 210, 34), Rect2(1760, 470, 220, 34), Rect2(2070, 375, 230, 34)]
		coins = make_points([[180, 540], [300, 420], [390, 420], [690, 330], [1040, 420], [1130, 420], [1390, 310], [1810, 420], [2120, 325], [2210, 325]])
		enemies = make_enemies([[520, 560], [1090, 560], [1440, 560], [1870, 560], [2180, 325]])
		mushroom = Vector2(1180, 420)
		finish_x = 2460.0
		player.reset_at(Vector2(90, 540))
		player.powered = false
		camera.position = Vector2(300, -90)
		banner.visible = true
		banner.text = "بخش اول: تپه‌های مرکبی!"
		banner_timer = 2.5
	else:
		platforms = [Rect2(0, 610, 570, 150), Rect2(740, 610, 630, 150), Rect2(1550, 610, 1050, 150), Rect2(160, 455, 190, 34), Rect2(470, 330, 210, 34), Rect2(850, 470, 240, 34), Rect2(1190, 350, 220, 34), Rect2(1620, 470, 220, 34), Rect2(1920, 360, 240, 34), Rect2(2270, 285, 190, 34)]
		coins = make_points([[130, 540], [235, 405], [525, 280], [900, 420], [1000, 420], [1260, 300], [1680, 420], [1780, 420], [1990, 310], [2320, 235], [2440, 540]])
		enemies = make_enemies([[360, 560], [980, 560], [1280, 300], [1740, 560], [2050, 310], [2380, 540]])
		mushroom = Vector2(1320, 300)
		finish_x = 2490.0
		player.reset_at(Vector2(90, 540))
		player.powered = false
		camera.position = Vector2(300, -90)
		banner.visible = true
		banner.text = "بخش دوم: شهر قارچی!"
		banner_timer = 2.5
	rebuild_collisions()
	update_hud()

func rebuild_collisions() -> void:
	for child in collision_root.get_children():
		child.queue_free()
	for rect in platforms:
		var body := StaticBody2D.new()
		body.position = rect.position + rect.size * 0.5
		body.collision_layer = 1
		body.collision_mask = 2
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		body.add_child(shape)
		collision_root.add_child(body)

func make_points(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		result.append({"position": Vector2(value[0], value[1]), "taken": false, "spin": randf() * TAU})
	return result

func make_enemies(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		result.append({"position": Vector2(value[0], value[1]), "origin": Vector2(value[0], value[1]), "direction": -1.0, "alive": true, "phase": randf() * TAU})
	return result

func create_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_top = 16
	top.offset_right = -18
	top.offset_bottom = 78
	top.add_theme_constant_override("separation", 10)
	hud.add_child(top)
	score_label = hud_label("امتیاز ۰۰۰۰۰۰", 22)
	coin_label = hud_label("سکه ۰۰", 22)
	lives_label = hud_label("جان ۳", 22)
	section_label = hud_label("بخش ۱ / ۲", 20)
	for label in [score_label, coin_label, lives_label, section_label]:
		label.add_theme_stylebox_override("normal", chip_style(CREAM, INK, 4, 12))
		label.custom_minimum_size = Vector2(150, 48)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		top.add_child(label)
	section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	banner = Label.new()
	banner.text = "بخش اول: تپه‌های مرکبی!"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 92
	banner.offset_bottom = 148
	banner.add_theme_font_size_override("font_size", 26)
	banner.add_theme_color_override("font_color", INK)
	banner.add_theme_stylebox_override("normal", chip_style(YELLOW, INK, 5, 18))
	hud.add_child(banner)
	var hint := Label.new()
	hint.text = "حرکت ← → / A D     پرش Space     توقف P"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 20
	hint.offset_top = -46
	hint.offset_right = -20
	hint.offset_bottom = -12
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", CREAM)
	hud.add_child(hint)
	create_touch_controls()
	apply_font_recursive(hud)

func apply_font_recursive(node: Node) -> void:
	if node is Control:
		node.add_theme_font_override("font", UI_FONT)
	for child in node.get_children():
		apply_font_recursive(child)

func create_touch_controls() -> void:
	left_button = touch_button("◀")
	right_button = touch_button("▶")
	jump_button = touch_button("پرش")
	left_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left_button.offset_left = 24
	left_button.offset_top = -96
	left_button.offset_right = 94
	left_button.offset_bottom = -26
	right_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	right_button.offset_left = 104
	right_button.offset_top = -96
	right_button.offset_right = 174
	right_button.offset_bottom = -26
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.offset_left = -146
	jump_button.offset_top = -96
	jump_button.offset_right = -24
	jump_button.offset_bottom = -26
	for button in [left_button, right_button, jump_button]:
		hud.add_child(button)
	left_button.button_down.connect(func(): player.touch_left = true)
	left_button.button_up.connect(func(): player.touch_left = false)
	right_button.button_down.connect(func(): player.touch_right = true)
	right_button.button_up.connect(func(): player.touch_right = false)
	jump_button.button_down.connect(func(): player.touch_jump = true)
	jump_button.button_up.connect(func(): player.touch_jump = false)

func touch_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(70, 70)
	button.add_theme_font_size_override("font_size", 24 if text != "پرش" else 18)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", chip_style(Color(0.14, 0.11, 0.17, 0.92), CREAM, 4, 18))
	button.add_theme_stylebox_override("hover", chip_style(Color("#6746A8"), CREAM, 5, 18))
	button.add_theme_stylebox_override("pressed", chip_style(RED, INK, 5, 18))
	return button

func hud_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", INK)
	return label

func chip_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box

func _process(delta: float) -> void:
	time += delta
	banner_timer = maxf(0.0, banner_timer - delta)
	if banner_timer <= 0.0 and game_state == "playing":
		banner.visible = false
	if game_state != "playing":
		queue_redraw()
		return
	power_time = maxf(0.0, power_time - delta)
	if power_time <= 0.0 and player.powered:
		player.powered = false
	for enemy in enemies:
		if not bool(enemy.alive):
			continue
		var enemy_pos: Vector2 = enemy.position
		enemy_pos.x += float(enemy.direction) * 68.0 * delta
		if absf(enemy_pos.x - float(enemy.origin.x)) > 95.0:
			enemy.direction = -float(enemy.direction)
		enemy.position = enemy_pos
		if enemy_pos.distance_to(player.global_position) < 58.0:
			if player.velocity.y > 40.0 and player.global_position.y < enemy_pos.y - 14.0:
				enemy.alive = false
				player.bounce()
				score += 250
				effects.pop(enemy_pos, YELLOW, "بووم!")
			else:
				player.hurt()
	for coin in coins:
		if not bool(coin.taken) and player.global_position.distance_to(coin.position) < 46.0:
			coin.taken = true
			coin_count += 1
			score += 100
			effects.pop(coin.position, YELLOW, "+۱۰۰")
	if not mushroom_taken and player.global_position.distance_to(mushroom) < 48.0:
		mushroom_taken = true
		player.powered = true
		power_time = 18.0
		score += 500
		effects.pop(mushroom, GREEN, "قوی شدی!")
	if player.global_position.x >= finish_x:
		complete_section()
	if player.global_position.y > 900.0:
		_on_player_hurt()
	update_hud()
	queue_redraw()

func complete_section() -> void:
	if game_state != "playing":
		return
	if section == 0:
		game_state = "transition"
		banner.visible = true
		banner.text = "عالی بود! بخش دوم باز شد"
		banner_timer = 2.0
		effects.pop(player.global_position, TEAL, "مرحله پاک شد!")
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree():
			start_section(1)
	else:
		game_state = "won"
		player.set_physics_process(false)
		show_terminal("بردی!", "تمام سکه‌ها را جمع کردی و پرچم نهایی را پیدا کردی.")

func _on_player_hurt() -> void:
	if game_state != "playing":
		return
	lives -= 1
	effects.pop(player.global_position, RED, "آخ!")
	if lives <= 0:
		game_state = "lost"
		player.set_physics_process(false)
		show_terminal("باختی!", "این بار قارچ‌ها کم آوردند؛ دوباره امتحان کن.")
		return
	player.reset_at(Vector2(90, 540))
	player.powered = false
	power_time = 0.0
	banner.visible = true
	banner.text = "یک جان کم شد؛ ادامه بده!"
	banner_timer = 1.6
	update_hud()

func _on_player_jump() -> void:
	effects.pop(player.global_position + Vector2(0, 24), TEAL, "هاپ!")

func update_hud() -> void:
	if not is_instance_valid(score_label):
		return
	score_label.text = "امتیاز %06d" % score
	coin_label.text = "سکه %02d" % coin_count
	lives_label.text = "جان %d" % lives
	section_label.text = "بخش %d / ۲" % (section + 1)

func show_terminal(title: String, subtitle: String) -> void:
	for button in [left_button, right_button, jump_button]:
		button.visible = false
	var panel := Panel.new()
	panel.name = "TerminalPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-300, -210)
	panel.size = Vector2(600, 420)
	panel.add_theme_stylebox_override("panel", chip_style(CREAM, INK, 7, 26))
	hud.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 52)
	heading.add_theme_color_override("font_color", RED if game_state == "lost" else TEAL)
	box.add_child(heading)
	var body := Label.new()
	body.text = subtitle + "\n\nامتیاز نهایی: %06d\nسکه‌های جمع‌شده: %02d" % [score, coin_count]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 22)
	body.add_theme_color_override("font_color", INK)
	box.add_child(body)
	var again := Button.new()
	again.text = "دوباره بازی کن"
	again.custom_minimum_size.y = 64
	again.add_theme_font_size_override("font_size", 24)
	again.add_theme_color_override("font_color", CREAM)
	again.add_theme_stylebox_override("normal", chip_style(TEAL, INK, 5, 16))
	again.pressed.connect(func(): get_tree().reload_current_scene())
	box.add_child(again)
	var menu := Button.new()
	menu.text = "بازگشت به صفحه‌ی شروع"
	menu.custom_minimum_size.y = 52
	menu.add_theme_font_size_override("font_size", 18)
	menu.add_theme_color_override("font_color", INK)
	menu.add_theme_stylebox_override("normal", chip_style(YELLOW, INK, 4, 14))
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	box.add_child(menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game_state == "playing":
		get_tree().paused = true
		pause_panel = Panel.new()
		pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_panel.set_anchors_preset(Control.PRESET_CENTER)
		pause_panel.position = Vector2(-220, -130)
		pause_panel.size = Vector2(440, 260)
		pause_panel.add_theme_stylebox_override("panel", chip_style(CREAM, INK, 6, 22))
		hud.add_child(pause_panel)
		var label := Label.new()
		label.text = "توقف کوتاه\n\nبرای ادامه روی دکمه بزن"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		label.offset_top = 24
		label.offset_bottom = 130
		pause_panel.add_child(label)
		var resume := Button.new()
		resume.text = "ادامه"
		resume.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		resume.offset_left = 34
		resume.offset_top = -78
		resume.offset_right = -34
		resume.offset_bottom = -24
		resume.add_theme_font_size_override("font_size", 22)
		resume.add_theme_stylebox_override("normal", chip_style(TEAL, INK, 4, 14))
		resume.pressed.connect(func(): pause_panel.queue_free(); pause_panel = null; get_tree().paused = false)
		pause_panel.add_child(resume)
		resume.grab_focus()

func _draw() -> void:
	# Sky backdrop
	draw_rect(Rect2(-200, -100, 3000, 900), SKY)
	# Halftone cloud bank
	for x in range(-100, 2800, 34):
		for y in range(80, 330, 34):
			draw_circle(Vector2(x + (y % 2) * 8, y), 2.0, Color(0.08, 0.07, 0.14, 0.14))
	# Far mountains
	var far := PackedVector2Array([Vector2(-100, 500), Vector2(300, 270), Vector2(650, 500), Vector2(1020, 240), Vector2(1430, 500), Vector2(1880, 280), Vector2(2310, 500), Vector2(2800, 300), Vector2(2800, 720), Vector2(-100, 720)])
	draw_colored_polygon(far, Color("#5B8BBF"))
	# Near hills
	for x in range(-120, 2800, 260):
		draw_circle(Vector2(x + 120, 570), 180, Color("#2A7E7E"))
	# Clouds as outlined blobs
	for c in [Vector2(280, 150), Vector2(900, 220), Vector2(1560, 130), Vector2(2240, 210)]:
		draw_circle(c, 44, CREAM)
		draw_circle(c + Vector2(38, 12), 34, CREAM)
		draw_circle(c + Vector2(-38, 16), 30, CREAM)
		draw_line(c + Vector2(-78, 38), c + Vector2(82, 38), INK, 5.0)
	# Platforms and chunky ground
	for rect in platforms:
		draw_rect(rect, Color("#D76C42"), true)
		draw_rect(rect, INK, false, 7.0)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 12)), Color("#F2A145"), true)
		for x in range(int(rect.position.x) + 18, int(rect.end.x), 32):
			draw_line(Vector2(x, rect.position.y + 18), Vector2(x + 14, rect.position.y + 30), Color("#8C3F36"), 3.0)
	# Pits: black warning panels
	for gap in [Rect2(760, 610, 160, 110), Rect2(1520, 610, 170, 110)]:
		draw_rect(gap, Color("#231B28"))
		for x in range(int(gap.position.x), int(gap.end.x), 24):
			draw_line(Vector2(x, 610), Vector2(x + 18, 632), RED, 4.0)
	# Coins
	for coin in coins:
		if bool(coin.taken):
			continue
		var pos: Vector2 = coin.position
		var bob := sin(time * 4.0 + float(coin.spin)) * 7.0
		draw_circle(pos + Vector2(0, bob), 18, YELLOW)
		draw_circle(pos + Vector2(0, bob), 18, INK, false, 5.0)
		draw_line(pos + Vector2(0, bob - 10), pos + Vector2(0, bob + 10), Color("#FFF4D6"), 4.0)
	# Mushroom power-up
	if not mushroom_taken:
		var m := mushroom + Vector2(0, sin(time * 3.0) * 5.0)
		draw_circle(m + Vector2(0, 16), 17, CREAM)
		draw_circle(m + Vector2(0, 16), 17, INK, false, 5.0)
		draw_circle(m + Vector2(0, -2), 27, GREEN)
		draw_arc(m + Vector2(0, -2), 27, PI, TAU, 18, INK, 5.0)
		draw_circle(m + Vector2(-10, -10), 6, CREAM)
		draw_circle(m + Vector2(10, -13), 5, CREAM)
	# Enemies
	for enemy in enemies:
		if not bool(enemy.alive):
			continue
		var e: Vector2 = enemy.position
		draw_ellipse_shape(e + Vector2(0, 12), Vector2(27, 11), Color(0.08, 0.05, 0.1, 0.28))
		draw_circle(e, 25, PURPLE)
		draw_circle(e, 25, INK, false, 6.0)
		draw_circle(e + Vector2(-9, -2), 4, CREAM)
		draw_circle(e + Vector2(9, -2), 4, CREAM)
		draw_circle(e + Vector2(-9, -2), 2, INK)
		draw_circle(e + Vector2(9, -2), 2, INK)
		draw_line(e + Vector2(-12, 17), e + Vector2(-3, 23), INK, 4.0)
		draw_line(e + Vector2(12, 17), e + Vector2(3, 23), INK, 4.0)
	# Finish flag
	var flag := Vector2(finish_x, 610)
	draw_line(flag, flag + Vector2(0, -150), INK, 7.0)
	draw_colored_polygon(PackedVector2Array([flag + Vector2(0, -145), flag + Vector2(88, -120), flag + Vector2(0, -90)]), RED)
	draw_polyline(PackedVector2Array([flag + Vector2(0, -145), flag + Vector2(88, -120), flag + Vector2(0, -90)]), INK, 5.0)
	draw_circle(flag + Vector2(0, -158), 10, YELLOW)
	# Finish speech bubble
	var font := ThemeDB.fallback_font
	draw_string(font, flag + Vector2(-72, -178), "پایان!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)

func draw_ellipse_shape(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
