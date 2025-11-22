extends Area3D

# Distancia vertical total
@export var float_range = 4.0
# Velocidad de oscilación (frecuencia)
@export var float_speed = 2.0

var _start_y = 0.0

func _ready():
	_start_y = global_position.y
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Usa la función 'sin' (seno) para crear un movimiento cíclico suave
	var offset_y = sin(Time.get_ticks_msec() / 1000.0 * float_speed) * float_range / 2.0
	global_position.y = _start_y + offset_y
	
	# El movimiento horizontal se deja nulo.

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		body.die_or_reset()
