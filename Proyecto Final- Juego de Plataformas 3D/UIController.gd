extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var pause_menu = $PauseMenu
@onready var resume_button = pause_menu.get_node("ButtonContainer/ResumeButton")
@onready var quit_button = pause_menu.get_node("ButtonContainer/QuitButton")

# Brújula
@onready var compass_node: Node2D = $Compass
@onready var compass_arrow: TextureRect = $Compass/Arrow

var is_paused: bool = false
var player_ref: Node3D = null
var goal_ref: Node3D = null

func _ready() -> void:
	# MUY IMPORTANTE: seguir procesando aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = false
	pause_menu.visible = false
	compass_node.visible = true


func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
	if is_paused:
		toggle_pause()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://menu.tscn")

# HUD
func update_score(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func update_lives(current_lives: int) -> void:
	if lives_label:
		lives_label.text = "Vidas: " + str(current_lives)

# Registro de referencias para la brújula
func register_player(player: Node3D) -> void:
	player_ref = player

	# Si el jugador tiene la variable current_lives, actualizamos el label
	if player_ref and "current_lives" in player_ref:
		update_lives(player_ref.current_lives)

func register_goal(goal: Node3D) -> void:
	goal_ref = goal

func _process(delta: float) -> void:
	_update_compass()

func _update_compass() -> void:
	if player_ref == null or goal_ref == null:
		compass_node.visible = false
		return

	var dir_world: Vector3 = goal_ref.global_position - player_ref.global_position
	dir_world.y = 0.0

	if dir_world.length() < 0.1:
		compass_node.visible = false
		return

	# Obtener la cámara del jugador
	var cam: Camera3D = player_ref.get_node("%Camera3D") as Camera3D
	if cam == null:
		return

	var forward: Vector3 = cam.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = cam.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var local_x: float = dir_world.dot(right)
	var local_z: float = dir_world.dot(forward)

	var angle: float = atan2(local_x, local_z)
	compass_arrow.rotation = angle
