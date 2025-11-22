extends Area3D

# Velocidad de rotación
@export var rotation_speed = 90.0
@export var speed = 0.0 # Aseguramos que la velocidad de movimiento es cero

func _ready():
	# Conexión de daño (es la misma para todos)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Rotación constante sobre el eje Y (mirando alrededor)
	rotate_y(deg_to_rad(rotation_speed * delta))
	
	# El enemigo permanece quieto, solo gira.

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		body.die_or_reset()
