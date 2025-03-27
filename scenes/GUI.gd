extends Control

@onready var inventory = $Inventory
@onready var inventory_label = $Inventory/InventoryLabel

func _ready() -> void:
	inventory.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		get_tree().paused = !get_tree().paused
		write_label()
		inventory.visible = !inventory.visible

func write_label():
	inventory_label.text = "INVENTORY: "
	for item in Inventory.collected_items:
		inventory_label.text += "\n- " + item.name
