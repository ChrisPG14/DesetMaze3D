extends Area3D

@export var speed = 3.0
# Variables para la flotación (conservamos esto para que se vea bien)
@export var float_height = 0.2
@export var float_speed = 3.0

var _start_y = 0.0
var _direction = 1

# Referencia al RayCast (Asegúrate de que el nodo hijo se llame RayCast3D)
@onready var wall_detector = $RayCast3D

func _ready():
	# Guardamos la altura inicial para la flotación
	_start_y = global_position.y
	wall_detector.target_position.x = 1.0
	body_entered.connect(_on_body_entered)
	
	# Ajustar velocidad según dificultad
	match Events.difficulty:
		"easy":
			speed *= 0.7
		"normal":
			pass
		"hard":
			speed *= 1.5

func _physics_process(delta):
	# 1. Movimiento Horizontal
	position.x += speed * _direction * delta

	# 2. Movimiento Vertical (Flotación - Lo mantenemos)
	var offset_y = sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_height
	global_position.y = _start_y + offset_y

	# 3. Lógica de Paredes (Reemplaza la distancia por el RayCast)
	if wall_detector.is_colliding():
		# Si el RayCast toca una pared, invertimos la dirección
		_direction *= -1
		
		# Invertimos el RayCast para que mire hacia el nuevo frente
		wall_detector.target_position.x *= -1
		
		# Opcional: Si quieres rotar el modelo visual 180 grados
		# $MeshInstance3D.rotate_y(deg_to_rad(180))

# 4. Lógica de Daño (Interactúa con el nuevo sistema de vidas)
func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		if body.has_method("die_or_reset"):
			body.die_or_reset()
