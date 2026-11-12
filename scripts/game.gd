extends Node3D

const CELL := 10.0
const WALL_H := 3.8
const SPEED := 4.2
const SPRINT := 6.3
const LOOK := 0.003
const MAZE := [
	"###############",
	"#.....#.......#",
	"#.##..#.###.#.#",
	"#....##...#...#",
	"###.####..###.#",
	"#...#......#..#",
	"#.#.#.####.#.##",
	"#.#...#....#..#",
	"#.#####.##.##.#",
	"#.....#.......#",
	"#.##..###.###.#",
	"#....#.....#..#",
	"###.####.#.#..#",
	"#......#.#....#",
	"###############"
]

var player: CharacterBody3D
var camera: Camera3D
var monster: CharacterBody3D
var flashlight: SpotLight3D
var stamina := 100.0
var battery := 100.0
var notes := 0
var sprinting := false
var mobile_move := Vector2.ZERO
var move_finger := -1
var look_finger := -1
var move_origin := Vector2.ZERO
var monster_timer := 0.0
var game_finished := false
var hud: CanvasLayer
var note_text: Label
var status_text: Label
var stamina_bar: ProgressBar
var battery_bar: ProgressBar

func _ready() -> void:
	_build_world()
	_build_player()
	_build_monster()
	_build_pickups()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _make_box(size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.15, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.68, 0.43)
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.34, 0.31, 0.20)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.72, 0.68, 0.43)
	var ceil_mat := StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.56, 0.53, 0.38)
	add_child(_make_box(Vector3(150, 0.2, 150), Vector3(0, -0.15, 0), floor_mat))
	add_child(_make_box(Vector3(150, 0.2, 150), Vector3(0, WALL_H, 0), ceil_mat))
	for z in range(MAZE.size()):
		for x in range(MAZE[z].length()):
			var pos := Vector3((x - 7) * CELL, WALL_H * 0.5, (z - 7) * CELL)
			if MAZE[z][x] == "#":
				add_child(_make_box(Vector3(CELL, WALL_H, CELL), pos, wall_mat))
			elif (x * 7 + z * 11) % 13 == 0:
				var light := OmniLight3D.new()
				light.position = Vector3(pos.x, WALL_H - 0.35, pos.z)
				light.light_color = Color(1.0, 0.86, 0.52)
				light.light_energy = 1.25
				light.omni_range = 9.0
				light.shadow_enabled = false
				add_child(light)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(-60, 1.0, -60)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 0.62
	camera.fov = 82.0
	player.add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0, 0, -0.2)
	flashlight.rotation.x = deg_to_rad(-5)
	flashlight.light_color = Color(1.0, 0.94, 0.78)
	flashlight.light_energy = 3.0
	flashlight.spot_range = 24.0
	flashlight.spot_angle = 34.0
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)

func _build_monster() -> void:
	monster = CharacterBody3D.new()
	monster.position = Vector3(50, 1.0, 50)
	add_child(monster)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 2.2
	shape.shape = capsule
	monster.add_child(shape)
	var mesh := MeshInstance3D.new()
	var visual := CapsuleMesh.new()
	visual.radius = 0.48
	visual.height = 2.2
	mesh.mesh = visual
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.025, 0.018, 0.02)
	mesh.material_override = mat
	monster.add_child(mesh)

func _build_pickups() -> void:
	var spots := [Vector3(-20, 1, -40), Vector3(10, 1, -20), Vector3(30, 1, 0), Vector3(-10, 1, 30), Vector3(40, 1, 40)]
	for p in spots:
		var note := Area3D.new()
		note.position = p
		var mesh := MeshInstance3D.new()
		var paper := BoxMesh.new()
		paper.size = Vector3(0.45, 0.06, 0.6)
		mesh.mesh = paper
		var paper_mat := StandardMaterial3D.new()
		paper_mat.albedo_color = Color(0.82, 0.78, 0.62)
		mesh.material_override = paper_mat
		note.add_child(mesh)
		var hit := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.2
		hit.shape = sphere
		note.add_child(hit)
		note.body_entered.connect(_on_note_entered.bind(note))
		add_child(note)
	var exit := Node3D.new()
	exit.position = Vector3(50, 0, -60)
	add_child(exit)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.18, 0.62, 0.38)
	green.emission_enabled = true
	green.emission = Color(0.08, 0.55, 0.22)
	for part in [
		_make_box(Vector3(0.35, 3.1, 0.35), Vector3(48.8, 1.55, -60), green),
		_make_box(Vector3(0.35, 3.1, 0.35), Vector3(51.2, 1.55, -60), green),
		_make_box(Vector3(2.75, 0.35, 0.35), Vector3(50, 3.0, -60), green)
	]:
		exit.add_child(part)

func _on_note_entered(body: Node3D, note: Area3D) -> void:
	if body == player and is_instance_valid(note):
		notes += 1
		note.queue_free()
		note_text.text = "ЗАПИСКИ: %d / 5" % notes
		if notes == 5:
			status_text.text = "Все записки найдены. Найди зелёный выход!"

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.02, 0.015, 0.62)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(270, 190)
	hud.add_child(panel)
	var title := Label.new()
	title.text = "BACKROOMS // LEVEL 0"
	title.position = Vector2(30, 24)
	title.add_theme_font_size_override("font_size", 17)
	hud.add_child(title)
	stamina_bar = _make_bar(Vector2(30, 58), "ВЫНОСЛИВОСТЬ")
	battery_bar = _make_bar(Vector2(30, 94), "БАТАРЕЯ")
	status_text = Label.new()
	status_text.text = "Найди 5 записок и выход. Не шуми."
	status_text.position = Vector2(24, 132)
	status_text.add_theme_font_size_override("font_size", 16)
	hud.add_child(status_text)
	note_text = Label.new()
	note_text.text = "ЗАПИСКИ: 0 / 5"
	note_text.position = Vector2(24, 165)
	hud.add_child(note_text)
	var sprint_button := Button.new()
	sprint_button.text = "БЕГ"
	sprint_button.position = Vector2(-145, -135)
	sprint_button.size = Vector2(110, 60)
	sprint_button.anchor_left = 1.0
	sprint_button.anchor_right = 1.0
	sprint_button.anchor_top = 1.0
	sprint_button.anchor_bottom = 1.0
	sprint_button.button_down.connect(func(): sprinting = true)
	sprint_button.button_up.connect(func(): sprinting = false)
	hud.add_child(sprint_button)
	var light_button := Button.new()
	light_button.text = "ФОНАРЬ"
	light_button.position = Vector2(-145, -65)
	light_button.size = Vector2(110, 55)
	light_button.anchor_left = 1.0
	light_button.anchor_right = 1.0
	light_button.anchor_top = 1.0
	light_button.anchor_bottom = 1.0
	light_button.pressed.connect(func(): flashlight.visible = not flashlight.visible)
	hud.add_child(light_button)

func _make_bar(pos: Vector2, caption: String) -> ProgressBar:
	var label := Label.new()
	label.text = caption
	label.position = pos
	label.add_theme_font_size_override("font_size", 11)
	hud.add_child(label)
	var bar := ProgressBar.new()
	bar.position = pos + Vector2(105, 0)
	bar.size = Vector2(140, 16)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	hud.add_child(bar)
	return bar

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * LOOK)
		camera.rotate_x(-event.relative.y * LOOK)
		camera.rotation.x = clamp(camera.rotation.x, -1.35, 1.35)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_F:
			flashlight.visible = not flashlight.visible
		elif event.keycode == KEY_SHIFT:
			sprinting = true
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_SHIFT:
		sprinting = false
	elif event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > get_viewport().size.x * 0.42:
				look_finger = event.index
			else:
				move_finger = event.index
				move_origin = event.position
		else:
			if event.index == look_finger:
				look_finger = -1
			if event.index == move_finger:
				move_finger = -1
				mobile_move = Vector2.ZERO
	elif event is InputEventScreenDrag:
		if event.index == look_finger:
			player.rotate_y(-event.relative.x * 0.006)
			camera.rotate_x(-event.relative.y * 0.006)
			camera.rotation.x = clamp(camera.rotation.x, -1.35, 1.35)
		elif event.index == move_finger:
			mobile_move = ((event.position - move_origin) / 95.0).limit_length(1.0)

func _physics_process(delta: float) -> void:
	if game_finished:
		return
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	if mobile_move.length() > 0.12:
		input_dir = mobile_move
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var running := sprinting or Input.is_key_pressed(KEY_SHIFT)
	var speed := SPEED
	if running and stamina > 1.0 and input_dir.length() > 0.1:
		speed = SPRINT
		stamina = maxf(0.0, stamina - 24.0 * delta)
	else:
		stamina = minf(100.0, stamina + 15.0 * delta)
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	player.velocity.y -= 20.0 * delta
	player.move_and_slide()
	var offset := player.global_position - monster.global_position
	var distance := offset.length()
	monster_timer -= delta
	if distance < 42.0 and monster_timer <= 0.0:
		var target := Vector3(player.global_position.x, monster.global_position.y, player.global_position.z)
		var route := target - monster.global_position
		monster.velocity.x = route.normalized().x * (3.2 if distance < 12.0 else 2.0)
		monster.velocity.z = route.normalized().z * (3.2 if distance < 12.0 else 2.0)
		if route.length() > 0.1:
			monster.look_at(target)
		monster_timer = 0.12
	else:
		monster.velocity.x = 0.0
		monster.velocity.z = 0.0
	monster.velocity.y -= 20.0 * delta
	monster.move_and_slide()
	if distance < 1.5:
		_finish(false)
	battery = maxf(0.0, battery - (0.9 if flashlight.visible else 0.12) * delta)
	if battery <= 0.0:
		flashlight.visible = false
	stamina_bar.value = stamina
	battery_bar.value = battery
	if notes >= 5 and player.global_position.distance_to(Vector3(50, 1, -60)) < 3.0:
		_finish(true)

func _finish(won: bool) -> void:
	game_finished = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(overlay)
	var label := Label.new()
	label.text = "ТЫ ВЫБРАЛСЯ" if won else "ОН ТЕБЯ НАШЁЛ"
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position = Vector2(-190, -45)
	label.add_theme_font_size_override("font_size", 42)
	overlay.add_child(label)
