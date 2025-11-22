extends Node3D

@onready var _area_3d: Area3D = %Area3D

func _ready() -> void:
	_area_3d.body_entered.connect(_on_body_entered)

	# Registrar la meta en el UI para la brújula
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ui.has_method("register_goal"):
		ui.register_goal(self)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var EndScreenScript = load("res://EndScreen.gd")
		if EndScreenScript:
			EndScreenScript.is_win = true
			if "score" in body:
				EndScreenScript.final_score = body.score

		Events.flag_reached.emit()
