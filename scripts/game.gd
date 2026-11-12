extends Node3D

const CELL := 10.0
const WALL_H := 3.8
const PLAYER_SPEED := 4.2
const SPRINT_SPEED := 6.3
const LOOK_SENS := 0.003

var maze := [
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
var flash: SpotLight3D
var hud: CanvasLayer
var stamina_bar: ProgressBar
var battery_bar: ProgressBar
var status_label: Label
var note_label: Label
var ambient_audio: AudioStreamPlayer
var monster_audio: AudioStreamPlayer
var stamina := 100.0
var battery := 100.0
var notes := 0
var sprinting := false
var mobile_move := Vector2.ZERO
var move_finger := -1
var look_finger := -1
var move_origin := Vector2.ZERO
var path: Array = []
var path_timer := 0.0
var heartbeat_timer := 0.0
var flicker_timer := 0.0
var finished := false

func _ready() -> void:
	_build_world()
	_build_player()
	_build_monster()
	_build_notes()
	_build_exit()
	_build_audio()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _box(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	body.add_child(visual)
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
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.34, 0.31, 0.20)
	floor_mat.roughness = 1.0
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.72, 0.68, 0.43)
	wall_mat.roughness = 0.95
	var ceiling_mat := StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.56, 0.53, 0.38)
	add_child(_box(Vector3(150, 0.2, 150), Vector3(0, -0.15, 0), floor_mat))
	add_child(_box(Vector3(150, 0.2, 150), Vector3(0, WALL_H, 0), ceiling_mat))
	for z in range(15):
		for x in range(15):
			var p := Vector3((x - 7) * CELL, WALL_H * 0.5, (z - 7) * CELL)
			if maze[z][x] == "#":
				add_child(_box(Vector3(CELL, WALL_H, CELL), p, wall_mat))
			elif (x * 7 + z * 11) % 13 == 0:
				var light := OmniLight3D.new()
				light.position = Vector3(p.x, WALL_H - 0.35, p.z)
				light.light_color = Color(1.0, 0.86, 0.52)
				light.light_energy = 1.25
				light.omni_range = 9.0
				add_child(light)
				var fixture_mat := StandardMaterial3D.new()
				fixture_mat.albedo_color = Color(1.0, 0.92, 0.66)
				fixture_mat.emission_enabled = true
				fixture_mat.emission = Color(0.55, 0.48, 0.25)
				add_child(_box(Vector3(2.2, 0.12, 0.55), light.position + Vector3(0, 0.15, 0), fixture_mat))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(-60, 1, -60)
	add_child(player)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 0.62
	camera.fov = 82
	player.add_child(camera)
	flash = SpotLight3D.new()
	flash.position = Vector3(0, 0, -0.2)
	flash.rotation.x = deg_to_rad(-5)
	flash.light_color = Color(1, 0.94, 0.78)
	flash.light_energy = 3
	flash.spot_range = 24
	flash.spot_angle = 34
	camera.add_child(flash)

func _build_monster() -> void:
	monster = CharacterBody3D.new()
	monster.position = Vector3(50, 1, 50)
	add_child(monster)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 2.2
	var collision := CollisionShape3D.new()
	collision.shape = shape
	monster.add_child(collision)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.025, 0.018, 0.02)
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 2.2
	body.mesh = mesh
	body.material_override = mat
	monster.add_child(body)
	var eyes := StandardMaterial3D.new()
	eyes.albedo_color = Color(0.9, 0.02, 0.015)
	eyes.emission_enabled = true
	eyes.emission = Color(0.9, 0, 0)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.07
		sphere.height = 0.14
		eye.mesh = sphere
		eye.material_override = eyes
		eye.position = Vector3(side * 0.17, 0.45, -0.36)
		monster.add_child(eye)

func _build_exit() -> void:
	var root := Node3D.new()
	root.position = Vector3(50, 0, -60)
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.62, 0.38)
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.55, 0.22)
	root.add_child(_box(Vector3(0.35, 3.1, 0.35), Vector3(-1.2, 1.55, 0), mat))
	root.add_child(_box(Vector3(0.35, 3.1, 0.35), Vector3(1.2, 1.55, 0), mat))
	root.add_child(_box(Vector3(2.75, 0.35, 0.35), Vector3(0, 3, 0), mat))
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 2, -1)
	glow.light_color = Color(0.18, 1, 0.42)
	glow.light_energy = 1.8
	glow.omni_range = 7
	root.add_child(glow)

func _build_audio() -> void:
	ambient_audio = AudioStreamPlayer.new()
	ambient_audio.stream = _make_hum()
	ambient_audio.volume_db = -25
	add_child(ambient_audio)
	ambient_audio.play()
	monster_audio = AudioStreamPlayer.new()
	monster_audio.stream = _make_heartbeat()
	monster_audio.volume_db = -12
	add_child(monster_audio)

func _make_hum() -> AudioStreamWAV:
	var rate := 22050
	var samples := rate * 3
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / rate
		var wobble := 0.72 + 0.28 * sin(TAU * 0.23 * t)
		var v := (sin(TAU * 50 * t) * 0.48 + sin(TAU * 100 * t) * 0.16 + sin(TAU * 137 * t) * 0.05) * wobble
		data.encode_s16(i * 2, int(clampf(v, -1, 1) * 32767))
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = rate
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_begin = 0
	audio.loop_end = samples
	audio.data = data
	return audio

func _make_heartbeat() -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * 0.72)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / rate
		var envelope := exp(-t * 9) * (1.0 if t < 0.22 else 0.0) + exp(-(t - 0.32) * 12) * (1.0 if t >= 0.32 else 0.0)
		var v := sin(TAU * 58 * t) * envelope * 0.55
		data.encode_s16(i * 2, int(clampf(v, -1, 1) * 32767))
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = rate
	audio.data = data
	return audio

func _build_notes() -> void:
	var positions := [Vector3(-30, 0.7, -50), Vector3(20, 0.7, -30), Vector3(-40, 0.7, 20), Vector3(30, 0.7, 40), Vector3(0, 0.7, -20)]
	for i in positions.size():
		var note := Area3D.new()
		note.position = positions[i]
		var mesh := MeshInstance3D.new()
		var paper := BoxMesh.new()
		paper.size = Vector3(0.45, 0.06, 0.6)
		mesh.mesh = paper
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.82, 0.78, 0.62)
		mesh.material_override = mat
		note.add_child(mesh)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.2
		collision.shape = sphere
		note.add_child(collision)
		note.body_entered.connect(_on_note.bind(note))
		add_child(note)

func _on_note(body: Node3D, note: Area3D) -> void:
	if body == player and is_instance_valid(note):
		notes += 1
		note.queue_free()
		if notes >= 5:
			status_label.text = "Все записки найдены. Найди выход!"

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.02, 0.015, 0.62)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(250, 112)
	hud.add_child(panel)
	var title := Label.new()
	title.text = "BACKROOMS // LEVEL 0"
	title.position = Vector2(30, 24)
	title.add_theme_font_size_override("font_size", 17)
	hud.add_child(title)
	stamina_bar = _bar(Vector2(30, 55), "ВЫНОСЛИВОСТЬ")
	battery_bar = _bar(Vector2(30, 91), "БАТАРЕЯ")
	status_label = Label.new()
	status_label.text = "Найди 5 записок и выход. Не шуми."
	status_label.position = Vector2(24, 140)
	status_label.add_theme_font_size_override("font_size", 17)
	hud.add_child(status_label)
	note_label = Label.new()
	note_label.text = "ЗАПИСКИ: 0 / 5"
	note_label.position = Vector2(24, 172)
	note_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(note_label)
	var help := Label.new()
	help.text = "WASD + мышь | Shift — бег | F — фонарь\nНа телефоне: слева движение, справа обзор"
	help.position = Vector2(24, 210)
	help.add_theme_font_size_override("font_size", 13)
	hud.add_child(help)
	var run := _button("БЕГ", Vector2(-150, -145), Vector2(110, 65))
	run.anchor_left = 1
	run.anchor_right = 1
	run.anchor_top = 1
	run.anchor_bottom = 1
	run.button_down.connect(func(): sprinting = true)
	run.button_up.connect(func(): sprinting = false)
	var lamp := _button("ФОНАРЬ", Vector2(-150, -70), Vector2(110, 55))
	lamp.anchor_left = 1
	lamp.anchor_right = 1
	lamp.anchor_top = 1
	lamp.anchor_bottom = 1
	lamp.pressed.connect(func(): flash.visible = not flash.visible)
	hud.add_child(run)
	hud.add_child(lamp)

func _bar(pos: Vector2, caption: String) -> ProgressBar:
	var label := Label.new()
	label.text = caption
	label.position = pos
	label.add_theme_font_size_override("font_size", 11)
	hud.add_child(label)
	var bar := ProgressBar.new()
	bar.position = pos + Vector2(100, 0)
	bar.size = Vector2(125, 16)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	hud.add_child(bar)
	return bar

func _button(caption: String, pos: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 17)
	hud.add_child(button)
	return button

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * LOOK_SENS)
		camera.rotate_x(-event.relative.y * LOOK_SENS)
		camera.rotation.x = clamp(camera.rotation.x, -1.35, 1.35)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_F:
			flash.visible = not flash.visible
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
	if finished:
		return
	var input_dir := Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), Input.get_action_strength("move_back") - Input.get_action_strength("move_forward"))
	if mobile_move.length() > 0.12:
		input_dir = mobile_move
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var running := sprinting or Input.is_key_pressed(KEY_SHIFT)
	var speed := PLAYER_SPEED
	if running and stamina > 1 and input_dir.length() > 0.1:
		speed = SPRINT_SPEED
		stamina = maxf(0, stamina - 24 * delta)
	else:
		stamina = minf(100, stamina + 15 * delta)
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	player.velocity.y -= 20 * delta
	player.move_and_slide()
	var distance := player.global_position.distance_to(monster.global_position)
	path_timer -= delta
	var hearing := 42.0 if running and input_dir.length() > 0.1 else 30.0
	if distance < hearing and path_timer <= 0:
		path = _find_path()
		path_timer = 0.45
	if distance < hearing and not path.is_empty():
		var target: Vector3 = path[0]
		var flat := Vector3(target.x, monster.global_position.y, target.z)
		if monster.global_position.distance_to(flat) < 1 and path.size() > 1:
			path.pop_front()
			target = path[0]
			flat = Vector3(target.x, monster.global_position.y, target.z)
		var route := flat - monster.global_position
		var chase := 2.15 if distance > 12 else 3.55
		monster.velocity.x = route.normalized().x * chase
		monster.velocity.z = route.normalized().z * chase
		if route.length() > 0.1:
			monster.look_at(flat)
	else:
		monster.velocity.x = 0
		monster.velocity.z = 0
	monster.velocity.y -= 20 * delta
	monster.move_and_slide()
	if distance < 1.55:
		_finish(false)
	heartbeat_timer -= delta
	if distance < 13 and heartbeat_timer <= 0 and not monster_audio.playing:
		monster_audio.play()
		heartbeat_timer = 1.8
	battery = maxf(0, battery - (0.9 if flash.visible else 0.12) * delta)
	if battery <= 0:
		flash.visible = false
	flicker_timer += delta
	if flicker_timer > 0.12:
		flicker_timer = 0
		if randf() < 0.025:
			flash.light_energy = randf_range(1.5, 3)
	stamina_bar.value = stamina
	battery_bar.value = battery
	note_label.text = "ЗАПИСКИ: %d / 5" % notes
	if notes >= 5 and player.global_position.distance_to(Vector3(50, 1, -60)) < 3:
		_finish(true)

func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(clampi(roundi(pos.x / CELL) + 7, 0, 14), clampi(roundi(pos.z / CELL) + 7, 0, 14))

func _open(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < 15 and c.y >= 0 and c.y < 15 and maze[c.y][c.x] == "."

func _nearest(c: Vector2i) -> Vector2i:
	if _open(c):
		return c
	for r in range(1, 15):
		for y in range(maxi(0, c.y-r), mini(15, c.y+r+1)):
			for x in range(maxi(0, c.x-r), mini(15, c.x+r+1)):
				var q := Vector2i(x, y)
				if _open(q):
					return q
	return Vector2i(1, 1)

func _find_path() -> Array:
	var start := _nearest(_cell(monster.global_position))
	var goal := _nearest(_cell(player.global_position))
	var queue: Array[Vector2i] = [start]
	var previous := {start: start}
	var dirs := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		if current == goal:
			break
		for d in dirs:
			var next := current + d
			if _open(next) and not previous.has(next):
				previous[next] = current
				queue.append(next)
	if not previous.has(goal):
		return []
	var result: Array = []
	var step := goal
	while step != start:
		result.push_front(Vector3((step.x - 7) * CELL, 1, (step.y - 7) * CELL))
		step = previous[step]
	if result.is_empty():
		result.append(Vector3((goal.x - 7) * CELL, 1, (goal.y - 7) * CELL))
	return result

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(overlay)
	var label := Label.new()
	label.text = "ТЫ ВЫБРАЛСЯ" if success else "ОН ТЕБЯ НАШЁЛ"
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position = Vector2(-210, -55)
	label.add_theme_font_size_override("font_size", 42)
	overlay.add_child(label)
