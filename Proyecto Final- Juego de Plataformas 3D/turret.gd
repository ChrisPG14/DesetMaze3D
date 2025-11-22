extends Area3D

# Referencia a la escena del proyectil
const BULLET_SCENE = preload("res://Bullet.tscn") # ¡CAMBIA ESTA RUTA!

@export var fire_rate = 2.0 # Segundos entre disparos
@export var rotation_speed = 90.0
@export var projectile_offset = 1.0 # Distancia para disparar el proyectil

@onready var fire_timer = $FireTimer

func _ready():
	# 1. Configurar el Timer
	fire_timer.wait_time = fire_rate
	fire_timer.timeout.connect(fire_projectile)
	fire_timer.start()

func _physics_process(delta):
	# El torreón simplemente gira (como un vigilante, pero disparando)
	rotate_y(deg_to_rad(rotation_speed * delta))

func fire_projectile():
	# 1. Instanciar la bala
	var bullet = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet) # Añade la bala al mismo padre que el torreón

	# 2. Calcular la posición y dirección de disparo
	var fire_direction = -global_basis.z # Dispara hacia donde está mirando (hacia adelante/atrás)
	var spawn_pos = global_position + fire_direction * projectile_offset
	
	bullet.global_position = spawn_pos
	
	# 3. Asignar la dirección al script de la bala
	bullet.direction = fire_direction
