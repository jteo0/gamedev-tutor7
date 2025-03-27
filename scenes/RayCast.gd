extends RayCast3D

var current_collider

@onready var label_node: Label = get_tree().root.find_child("InteractLabel", true, false)

func _ready():
	label_node.visible = false

func _process(delta):
	if is_colliding():
		var collider = get_collider()

		if collider is Interactable:
			label_node.text = collider.interaction_text
			label_node.visible = true

			if Input.is_action_just_pressed("interact"):
				collider.interact()
				label_node.visible = false
		return  

	label_node.visible = false
