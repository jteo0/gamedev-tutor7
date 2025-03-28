# Tutorial 7
<h3>Player in 3D + Running and Crouching</h3>
<p>The Player scene consists of a CharacterPlayer3D root node that has a CollisionBody3D, MeshInstance3D, and Node3D (with a Camera3D child and RayCast3D child node of that) for children nodes. The MeshInstance3D makes up the actual player model, which in this case is a capsule mesh, and CollisionBody3D is it's collision area. The Node 3D is the 'Head' of the player, acting as the player's head/POV, allowing them to rotate their head (moving the camera) and 'look' at objects (pointing the raycast at objects).</p>

<p>Player movement is mapped to the WASD keys, with the space key mapping to jumping, shift mapping to crouching (a slightly lowered POV and slower movement speed), and double clicking forward mapping to running (an increased movement speed until either the player lets go of forward/presses shift).</p>

<p>The following are the scripts used in the scene:</p>

```py
# Player.gd
extends CharacterBody3D

@export var speed: float = 10.0
@export var acceleration: float = 5.0
@export var gravity: float = 9.8
@export var jump_power: float = 5.0
@export var mouse_sensitivity: float = 0.3

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var camera_x_rotation: float = 0.0
var double_tap_timer = 0
var is_running = false
var is_crouching = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		var x_delta = event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation + x_delta, -90.0, 90.0)
		camera.rotation_degrees.x = -camera_x_rotation

func _process(delta):
    # timer to count if the player double clicked forward
	if double_tap_timer > 0:
		double_tap_timer -= delta
		
	if Input.is_action_just_released("movement_forward"):
		double_tap_timer = 0.25
		speed = 10.0
		is_running = false

func _physics_process(delta):
	var movement_vector = Vector3.ZERO

	if Input.is_action_pressed("movement_forward"):
		if double_tap_timer > 0 or is_running == true and not is_crouching:
			is_running = true
			speed = 20.0
		movement_vector -= head.basis.z
	if Input.is_action_pressed("movement_backward"):
		movement_vector += head.basis.z
	if Input.is_action_pressed("movement_left"):
		movement_vector -= head.basis.x
	if Input.is_action_pressed("movement_right"):
		movement_vector += head.basis.x

    # Crouching
	if Input.is_action_pressed("shift"):
		speed = 4.0
		head.position.y = 0.900
		is_crouching = true
	if Input.is_action_just_released("shift"):
		speed = 10.0
		head.position.y = 0.999
		is_crouching = false
		
	movement_vector = movement_vector.normalized()

	velocity.x = lerp(velocity.x, movement_vector.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, movement_vector.z * speed, acceleration * delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_power

	move_and_slide()
```

<p>This one is for the raycast:</p>

```py
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
```

<h3>Lights</h3>
There are 2 types of lights used here, 10 OmniLight3D and DirectionalLight3D. The OmniLight3Ds scattered across the ceiling and are there to provide minimal lighting to that World 1 isn't completely dark at the start. The first 4 lights at the starting room are completely unchanged from the default, while the other 6 in the corridor have higher energy (are brighter) and have a slightly more blue hue (color changed). The DirectionalLight3D is a decent distance above the world, and it's off by default. It only turns on when the player interacts with a switch, and then it turns off when it's interacted with again. <br>

<h3>Rooms, Objects, Platforms</h3>
<p>The platforms and rooms are made with CSGBox3Ds and CSGBox3Ds combined into one as child nodes of CSGCombiner3D. The rooms have flip face toggled on so they act as rooms, and they both have collision on so that they collide with the player. The CSGCombiner3D has union as the operation variable, so that the child boxes combine while removing intersecting walls.</p>

<p>The lone object is a lamp made up with a CSGCombiner3D root node, 2 CSGCylinder3D nodes and one CSGPolygon node as children. The cylinders are adjusted to resemble the pole and base of the lamp, while the polygon makes up the head of the lamp. The whole thing has collision on, so the player collides with it.</p>

<h3>Area Triggers</h3>
The Area Trigger scene is an Area3D node with a CollisionShape3D that sends out a signal everytime the player enters it. It's used in game as a 'DeathPit' to make the player respawn if the fall into the pit, and the same principle is used by the collectibles, in that if the player collides with/enters their area, they get picked up and put into the inventory. The following is the code used for the AreaTrigger scene:<br>

```py
extends Area3D

@export var sceneName := "Level 1"

func _on_body_entered(body: Node3D) -> void:
	if body.get_name() == "Player":
		get_tree().change_scene_to_file(str("res://scenes/" + sceneName + ".tscn"))
    
    # Clears out the inventory array of freed objects every time a respawn happens
	if self.get_name().contains("DeathPit"):
		Inventory.collected_items.clear()

```
<h3>Interactables</h3>
<p>As of now, there is only one working interactable in the world, which is the light switch. It's a StaticBody3D node with a CollisionShape3D and MeshInstance3D (both box shaped) as children. When the player looks at it, that is, when the Player's RayCast3D collides with the collision shape, it will prompt a text to appear the bottom of the screen, telling the player that they can interact with the object. If they click 'E', they will interact with the object and the the DirectionalLight3D the switch is connected to will turn on/off. Below is the script used for this:</p>

```py
extends Interactable

@export var light : NodePath
@export var on_by_default = true
@export var energy_when_on = 1.5
@export var energy_when_off = 0

@onready var light_node : Light3D = get_node(light)

var on = false

func _ready():
	light_node.light_energy = energy_when_on if on else energy_when_off

func interact():
	on = !on
	light_node.light_energy = energy_when_on if on else energy_when_off

```

<p>Here is the Interactable class it extends from:</p>

```py
extends Node

class_name Interactable

# Text that appears
@export var interaction_text : String = "Press [E] to interact!"

func interact():
	pass

```

<h3>Collectibles</h3>
The collectibles are 3D models imported from blender that disappear from the map and added into the inventory if the player runs into them. The following is the script they use:<br>

```py
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

```

<h3>Inventory</h3>
The inventory is made with a margin container, with a texture rect and label children. When a collectible is picked up, it's added to the inventory's array of items, which is shown when the player clicks the I key. The following is the script it uses:<br>

```py
extends Node

var collected_items: Array = []

func _ready():
	get_tree().root.add_child(self)

func add_item(item: Collectible):
	if item not in collected_items:
		collected_items.append(item)

```
<p>Additionally, the GUI control node, which is the parent node of the inventory margin container, has the following code. It pauses the game when the inventory is up, and writes up what the inventory label will say. Also, in order not to pause along with the game, the whole GUI control node has it's process always on.</p>

```py
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

```
<h3>Importing Models from Blender</h3>
The donut and sword models are imported as glb files from blender, and then dragged into the Godot Editor.<br>
<h4>References:</h4>
- fonts: https://www.dafont.com/theme.php?cat=102&page=2<br>
- https://www.reddit.com/r/godot/comments/17dxfb3/blender_to_godot_updated_workflow_guide_for/<br>
