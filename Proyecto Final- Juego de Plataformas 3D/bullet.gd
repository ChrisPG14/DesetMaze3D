extends Area3D

@export var speed = 15.0
var direction = Vector3.ZERO
# Tiempo de vida para que no viajen por siempre si se escapan del mapa
var life_time = 5.0 

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += direction * speed * delta
	
	# Temporizador de seguridad manual
	life_time -= delta
	if life_time <= 0:
		queue_free()

func _on_body_entered(body: Node3D):
	# 1. Si toca al jugador -> Daño
	if body.is_in_group("player"):
		if body.has_method("die_or_reset"):
			body.die_or_reset()
		queue_free() # La bala desaparece al golpear al jugador
	
	# 2. Si toca cualquier otra cosa (Paredes, Suelo) -> Se destruye
	# (Excluimos al propio enemigo que la disparó si es necesario, pero usualmente no hace falta con Area3D simples)
	else:
		queue_free()
