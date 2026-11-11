extends CharacterBody2D

signal took_damage
signal jumped

const GRAVITY := 1850.0
const MOVE_SPEED := 360.0
const ACCELERATION := 2100.0
const FRICTION := 2400.0
const JUMP_SPEED := 735.0
const HITBOX := Vector2(38, 62)

var touch_left := false
var touch_right := false
var touch_jump := false
var touch_jump_was := false
var facing := 1.0
var powered := false
var invincible := 0.0
var anim_time := 0.0
var jump_buffer := 0.0
var coyote := 0.0
var spawn_point := Vector2.ZERO
var active := true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = HITBOX
	shape.shape = rect
	shape.position = Vector2(0, -1)
	add_child(shape)
	queue_redraw()

func reset_at(point: Vector2) -> void:
	global_position = point
	spawn_point = point
	velocity = Vector2.ZERO
	active = true
	invincible = 0.0
	jump_buffer = 0.0
	coyote = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	anim_time += delta
	invincible = maxf(0.0, invincible - delta)
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) < 0.05:
		axis = float(int(touch_right) - int(touch_left))
	if absf(axis) > 0.05:
		velocity.x = move_toward(velocity.x, axis * MOVE_SPEED, ACCELERATION * delta)
		facing = signf(axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	var jump_now := Input.is_action_pressed("jump") or touch_jump
	var jump_pressed := Input.is_action_just_pressed("jump") or (touch_jump and not touch_jump_was)
	var jump_released := Input.is_action_just_released("jump") or (not touch_jump and touch_jump_was)
	touch_jump_was = touch_jump
	if jump_pressed:
		jump_buffer = 0.14
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if is_on_floor():
		coyote = 0.12
	else:
		coyote = maxf(0.0, coyote - delta)
		velocity.y += GRAVITY * delta
	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = -JUMP_SPEED
		jump_buffer = 0.0
		coyote = 0.0
		jumped.emit()
	if jump_released and velocity.y < -265.0:
		velocity.y = -265.0
	move_and_slide()
	if position.y > 900.0 and active:
		active = false
		took_damage.emit()
	queue_redraw()

func hurt() -> bool:
	if invincible > 0.0 or not active:
		return false
	if powered:
		powered = false
		invincible = 1.4
		velocity.y = -320.0
		queue_redraw()
		return true
	invincible = 1.2
	took_damage.emit()
	return true

func bounce() -> void:
	velocity.y = -470.0

func _draw() -> void:
	var blink := invincible > 0.0 and int(invincible * 14.0) % 2 == 0
	if blink:
		return
	var ink := Color("#231B28")
	var skin := Color("#FFD0A6")
	var cap := Color("#F4513A")
	var cap_light := Color("#FF7450")
	var shirt := Color("#26C6B6")
	var pants := Color("#3159A6")
	var boot := Color("#F3A629")
	# Ground shadow
	draw_ellipse_shape(Vector2(0, 32), Vector2(28, 7), Color(0.08, 0.05, 0.1, 0.28))
	# Legs and boots
	draw_rect(Rect2(-17, 8, 13, 23), pants, true)
	draw_rect(Rect2(4, 8, 13, 23), pants, true)
	draw_rect(Rect2(-20, 27, 18, 8), boot, true)
	draw_rect(Rect2(2, 27, 20, 8), boot, true)
	draw_rect(Rect2(-20, 27, 18, 8), ink, false, 5.0)
	draw_rect(Rect2(2, 27, 20, 8), ink, false, 5.0)
	# Body with comic outline
	draw_circle(Vector2(0, 0), 24, shirt)
	draw_circle(Vector2(0, 0), 24, ink, false, 6.0)
	# Face
	draw_circle(Vector2(0, -21), 20, skin)
	draw_circle(Vector2(0, -21), 20, ink, false, 5.0)
	# Cap brim and dome
	draw_circle(Vector2(0, -35), 25, cap)
	draw_arc(Vector2(0, -35), 25, PI, TAU, 20, ink, 5.0)
	draw_rect(Rect2(-24, -38, 48, 10), cap_light, true)
	draw_line(Vector2(-24, -38), Vector2(24, -38), ink, 5.0)
	# Cap spots / halftone
	draw_circle(Vector2(-10, -44), 5, Color("#FFF0D0"))
	draw_circle(Vector2(10, -47), 4, Color("#FFF0D0"))
	# Eyes and smile
	draw_circle(Vector2(-7, -23), 3, ink)
	draw_circle(Vector2(7, -23), 3, ink)
	draw_arc(Vector2(0, -17), 8, 0.1, PI - 0.1, 12, ink, 3.0)
	# Power-up badge
	if powered:
		draw_circle(Vector2(20, -2), 9, Color("#A7E64F"))
		draw_circle(Vector2(20, -2), 9, ink, false, 3.0)
		draw_line(Vector2(16, -2), Vector2(24, -2), ink, 2.0)
		draw_line(Vector2(20, -6), Vector2(20, 2), ink, 2.0)

func draw_ellipse_shape(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
