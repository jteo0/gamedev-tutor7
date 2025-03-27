extends Interactable

class_name Collectible

@export var collectible_path : NodePath
@onready var collectible = get_node(collectible_path)

var collected: bool = false

func _ready() -> void:
	pass # Replace with function body.


func interact():
	if not collected:
		collected = true
		collectible.visible = false

		Inventory.add_item(self)
		
	else: 
		collectible.visible = false
		collectible.collected = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not collected:
		collected = true
		collectible.visible = false

		Inventory.add_item(self)
				
	else: 
		collectible.visible = false
		collectible.collected = true
