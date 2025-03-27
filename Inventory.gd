extends Node

var collected_items: Array = []

func _ready():
	get_tree().root.add_child(self)

func add_item(item: Collectible):
	if item not in collected_items:
		collected_items.append(item)
