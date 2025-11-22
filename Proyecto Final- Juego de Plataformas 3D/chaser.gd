extends Area3D

@export var chase_speed = 4.0
@export var detection_range = 10.0

var _is_chasing = false
var _player: Node3D = null

# Detector de paredes para no atravesarlas
@onready var wall_detector = $RayCast3D 

func _ready():
	var detection_area = Area3D.new()
	add_child(detection_area)
	
	var shape = SphereShape3D.new()
	shape.radius = detection_range
	var collision = CollisionShape3D.new()
	collision.shape = shape
	detection_area.add_child(collision)
	
	body_entered.connect(_on_body_entered)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	
	# Si no añadiste el RayCast manualmente, evita errores:
	if wall_detector: 
		wall_detector.enabled = true
		wall_detector.target_position = Vector3(0, 0, -1.5) # Mirar adelante

func _physics_process(delta):
	if _is_chasing and is_instance_valid(_player):
		# 1. Mirar al jugador
		look_at(_player.global_position, Vector3.UP)
		
		# 2. Moverse SOLO si no hay pared enfrente
		if wall_detector and not wall_detector.is_colliding():
			# Movemos en el eje Z local (hacia adelante)
			translate(Vector3(0, 0, -chase_speed * delta))
		
		# Si no tienes RayCast, usará la lógica antigua (que atraviesa paredes):
		elif not wall_detector:
			var direction = (_player.global_position - global_position).normalized()
			global_position += direction * chase_speed * delta

func _on_detection_area_body_entered(body: Node3D):
	if body.is_in_group("player"):
		_player = body
		_is_chasing = true

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		body.die_or_reset()
