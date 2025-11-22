extends CharacterBody3D

@export_group("PowerUps")
@export var speed_boost_multiplier := 1.8
@export var speed_boost_duration := 5.0
@export var invincibility_duration := 5.0

var base_move_speed := 0.0
var base_acceleration := 0.0
var is_speed_boost_active := false

@export_group("Movement")
## Character maximum run speed on the ground in meters per second.
@export var move_speed := 8.0
## Ground movement acceleration in meters per second squared.
@export var acceleration := 20.0
## When the player is on the ground and presses the jump button, the vertical
## velocity is set to this value.
@export var jump_impulse := 12.0
## Player model rotation speed in arbitrary units. Controls how fast the
## character skin orients to the movement or camera direction.
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character skin's
## animation tree changes between the idle and running states.
@export var stopping_speed := 1.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

# --- VARIABLES DE JUEGO ---
var score: int = 0

## Sistema de Vidas
var max_lives: int = 3
var current_lives: int = 3
var is_invulnerable: bool = false # Para evitar morir instantáneamente al tocar un enemigo

var ground_height := 0.0
var _gravity := -30.0
var _was_on_floor_last_frame := true
var _camera_input_direction := Vector2.ZERO

@onready var _last_input_direction := global_basis.z
@onready var _start_position := global_position

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: SophiaSkin = %SophiaSkin
@onready var _landing_sound: AudioStreamPlayer3D = %LandingSound
@onready var _jump_sound: AudioStreamPlayer3D = %JumpSound
@onready var _dust_particles: GPUParticles3D = %DustParticles

# Variable para guardar la referencia al controlador de la UI
var ui_controller: CanvasLayer = null


func _ready() -> void:
	# Ajustar por dificultad
	match Events.difficulty:
		"easy":
			max_lives = 5
		"normal":
			max_lives = 3
		"hard":
			max_lives = 2
	# --- INICIALIZACIÓN DE VIDAS ---
	current_lives = max_lives
	base_move_speed = move_speed
	base_acceleration = acceleration

	# Esperar un frame para asegurarnos de que la UI ya esté en el arbol
	call_deferred("_setup_ui_and_signals")


func _setup_ui_and_signals() -> void:
	# Buscar la UI ahora que todo ya está cargado
	ui_controller = get_tree().get_first_node_in_group("ui") as CanvasLayer

	if ui_controller:
		# Registrar el jugador en la UI (para brújula, etc.)
		if ui_controller.has_method("register_player"):
			ui_controller.register_player(self)

		# Actualizar las vidas en pantalla desde el inicio
		if ui_controller.has_method("update_lives"):
			ui_controller.update_lives(current_lives)

	# --- CONEXIÓN DE CAÍDA AL VACÍO (KILL PLANE) ---
	Events.kill_plane_touched.connect(func on_kill_plane_touched() -> void:
		take_damage(true) # 'true' significa que SÍ debe reiniciar posición
	)

	Events.flag_reached.connect(func on_flag_reached() -> void:
		set_physics_process(false)
		_skin.idle()
		_dust_particles.emitting = false
	)


func _input(event: InputEvent) -> void:
	if not get_tree().paused:
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.is_action_pressed("left_click"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# DETECCIÓN DE PAUSA (MÁXIMA PRIORIDAD)
	if Input.is_action_just_pressed("pause"):
		if ui_controller and ui_controller.has_method("toggle_pause"):
			ui_controller.toggle_pause()
			get_viewport().set_input_as_handled()
			return

	if get_tree().paused:
		return

	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction.x = -event.relative.x * mouse_sensitivity
		_camera_input_direction.y = -event.relative.y * mouse_sensitivity
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x -= _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y += _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.4)
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	if move_direction.length() > 0.2:
		_last_input_direction = move_direction.normalized()
	var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	if is_equal_approx(move_direction.length_squared(), 0.0) and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO
	velocity.y = y_velocity + _gravity * delta

	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_just_jumping:
		velocity.y += jump_impulse
		_skin.jump()
		_jump_sound.play()
	elif not is_on_floor() and velocity.y < 0:
		_skin.fall()
	elif is_on_floor():
		if ground_speed > 0.0:
			_skin.move()
		else:
			_skin.idle()

	_dust_particles.emitting = is_on_floor() && ground_speed > 0.0

	if is_on_floor() and not _was_on_floor_last_frame:
		_landing_sound.play()

	_was_on_floor_last_frame = is_on_floor()
	move_and_slide()


# ----------------------------------------------------------------------
# Lógica de Monedas
# ----------------------------------------------------------------------
func collect_coin(amount: int):
	score += amount
	if ui_controller and ui_controller.has_method("update_score"):
		ui_controller.update_score(score) 
	print("¡Moneda recogida! Puntaje actual: ", score)


# ----------------------------------------------------------------------
# SISTEMA DE DAÑO (MODIFICADO)
# ----------------------------------------------------------------------

# Esta es la función que llaman los ENEMIGOS y PROYECTILES.
# Por defecto, los enemigos NO reinician posición (should_reset = false)
func die_or_reset():
	# Llamamos a la función interna indicando que NO queremos reiniciar posición
	take_damage(false)

# Función interna para manejar el daño
func take_damage(should_reset_position: bool):
	# Si somos invulnerables, ignoramos el daño (a menos que sea caída al vacío que siempre mata)
	if is_invulnerable and not should_reset_position:
		return

	# 1. Restar vida
	current_lives -= 1
	print("¡Auch! Te quedan: ", current_lives, " vidas.")

	# 2. Actualizar UI
	if ui_controller and ui_controller.has_method("update_lives"):
		ui_controller.update_lives(current_lives)

	# 3. Chequear si perdimos el juego
	if current_lives <= 0:
		print("GAME OVER")
		
		# Cargar datos en la pantalla de fin
		var EndScreen = load("res://EndScreen.gd") # Carga la referencia al script para acceder a las variables estáticas
		EndScreen.is_win = false
		EndScreen.final_score = score
		
		# Cambiar de escena
		get_tree().change_scene_to_file("res://EndScreen.tscn")
		return

	# 4. Si seguimos vivos...
	if should_reset_position:
		# Si fue por CAÍDA (KillPlane), regresamos al inicio
		global_position = _start_position
		velocity = Vector3.ZERO
		_skin.idle()
	else:
		# Si fue por ENEMIGO, nos quedamos donde estamos pero nos hacemos invulnerables un momento
		# para no recibir daño continuo inmediato.
		activar_invulnerabilidad()

func activar_invulnerabilidad():
	is_invulnerable = true
	# Aquí podrías hacer parpadear al personaje si quisieras
	print("¡Invencibilidad temporal activada!")
	
	# Creamos un temporizador simple de 2 segundos
	await get_tree().create_timer(2.0).timeout
	
	is_invulnerable = false
	print("Ya no eres invencible.")
	
#POWER-UP: VELOCIDAD
func apply_speed_boost(multiplier: float, duration: float) -> void:
	if is_speed_boost_active:
		return # ya está activo, no acumular

	is_speed_boost_active = true
	move_speed = base_move_speed * multiplier
	acceleration = base_acceleration * multiplier
	print("Speed Boost activado")

	# Aquí podrías activar partículas especiales en el jugador
	if _dust_particles:
		_dust_particles.emitting = true

	await get_tree().create_timer(duration).timeout

	# Restaurar
	move_speed = base_move_speed
	acceleration = base_acceleration
	is_speed_boost_active = false
	print("Speed Boost terminado")

	if _dust_particles:
		_dust_particles.emitting = false


# POWER-UP: INVENCIBILIDAD
func apply_invincibility_powerup(duration: float) -> void:
	if is_invulnerable:
		return

	is_invulnerable = true
	print("Power-up de invencibilidad ACTIVADO")

	# Aquí podrías hacer parpadear el mesh del personaje o cambiar material
	# por ejemplo:
	# if $SophiaSkin:
	#     $SophiaSkin.modulate = Color(1, 1, 0.5)

	await get_tree().create_timer(duration).timeout

	is_invulnerable = false
	print("Power-up de invencibilidad TERMINADO")
	# if $SophiaSkin:
	#     $SophiaSkin.modulate = Color(1, 1, 1)
