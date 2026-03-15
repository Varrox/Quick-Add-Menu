@tool
class_name QuickAddMenu extends EditorPlugin

var menu_button:MenuButton
var parent_node:Node

static var base_control:Control = EditorInterface.get_base_control()

const TOOLTIP = "Quick Add Child Node... (Ctrl+E)\nQuickly Add/Create a New Node."

## Add custom items
func _add_custom_items():
	# Add your own code
	pass

func _enter_tree() -> void:
	_add_custom_items()
	
	var top_container:HBoxContainer = _find_place(base_control)
	
	menu_button = MenuButton.new()
	menu_button.theme_type_variation = &"FlatMenuButton"
	menu_button.icon = _get_icon("Object")
	menu_button.flat = false
	menu_button.tooltip_text = TOOLTIP
	
	top_container.add_child(menu_button)
	top_container.move_child(menu_button, 1)
	
	# Shortcut
	
	menu_button.shortcut_context = top_container.get_parent()
	menu_button.shortcut = Shortcut.new()
	menu_button.shortcut_in_tooltip = false
	
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_E
	key_event.ctrl_pressed = true
	key_event.command_or_control_autoremap = true # Swaps Ctrl for Command on Mac.
	
	menu_button.shortcut.events = [key_event]

	# Finalize
	
	menu_button.get_popup().id_pressed.connect(_item_selected)
	menu_button.about_to_popup.connect(_update_add_list)
	
	if EditorInterface.get_selection().get_selected_nodes().size() == 0:
		menu_button.hide()

## Delete [member menu_button]
func _exit_tree() -> void:
	menu_button.queue_free()
	menu_button = null

## Updates list of items to quick add
func _update_add_list() -> void:
	menu_button.get_popup().clear()
	var items:Array[Item]
	
	if parent_node is Node3D:
		items = node_3d_list
	elif parent_node is Node2D:
		items = node_2d_list
	elif parent_node is Control:
		items = control_list
	elif parent_node is Node:
		items = node_list
	
	for i in items:
		if i.header:
			menu_button.get_popup().add_separator(i.name)
		else:
			menu_button.get_popup().add_icon_item(i.icon, i.name)

## Gets an editor icon
static func _get_icon(icon:String) -> Texture2D:
	return base_control.get_theme_icon(icon, "EditorIcons")

class Item:
	var name:String
	var icon:Texture2D
	var header:bool = false
	var spawn_callable:Callable
	
	func _init(name:String, icon:Texture2D, spawn_callable:Callable) -> void:
		self.name = name
		self.icon = icon
		self.spawn_callable = spawn_callable
		self.header = header
	
	## Creates a header item
	static func new_header(name:String, icon:Texture2D = null) -> Item:
		var preset = Item.new(name, icon, (func(): return false))
		preset.header = true
		return preset

## Items for [Node3D]s.
static var node_3d_list:Array[Item] = [
	Item.new_header("Primitive Shapes"),
	Item.new("Plane", load("uid://04sjd3fhspum"), func(): return _create_primitive_3d(0)),
	Item.new("Box", _get_icon("BoxShape3D"), func(): return _create_primitive_3d(1)),
	Item.new("Sphere", _get_icon("SphereShape3D"), func(): return _create_primitive_3d(2)),
	Item.new("Capsule", _get_icon("CapsuleShape3D"), func(): return _create_primitive_3d(3)),
	Item.new("Cylinder", _get_icon("CylinderShape3D"), func(): return _create_primitive_3d(4)),
	Item.new("Prism", load("uid://bkqqtifxdtts8"), func(): return _create_primitive_3d(5)),
	Item.new("Torus", load("uid://bui2yippw5un6"), func(): return _create_primitive_3d(6)),
	Item.new_header("CSGs"),
	Item.new("Box CSG", _get_icon("CSGBox3D"), func(): return _create_csg_3d(0)),
	Item.new("Sphere CSG", _get_icon("CSGSphere3D"), func(): return _create_csg_3d(1)),
	Item.new("Cylinder CSG", _get_icon("CSGCylinder3D"), func(): return _create_csg_3d(2)),
	Item.new("Torus CSG", _get_icon("CSGTorus3D"), func(): return _create_csg_3d(3)),
	Item.new("CSG Combiner", _get_icon("CSGCombiner3D"), func(): return _create_csg_3d(4))
]

## Items for [Node2D]s.
static var node_2d_list:Array[Item] = [
	Item.new_header("Nodes"),
	Item.new("Sprite", _get_icon("Sprite2D"), func(): return _create_node_2d(0)),
	Item.new("Animated Sprite", _get_icon("AnimatedSprite2D"), func(): return _create_node_2d(1)),
	Item.new("Tile Map", _get_icon("TileMapLayer"), func(): return _create_node_2d(2)),
	Item.new("Static Body", _get_icon("StaticBody2D"), func(): return _create_node_2d(3)),
	Item.new("Collision Shape", _get_icon("CollisionShape2D"), func(): return _create_node_2d(4)),
]

## Items for [Control]s.
static var control_list:Array[Item] = [
	Item.new_header("UI Elements"),
	Item.new("Button", _get_icon("Button"), func(): return _create_control(0)),
	Item.new("Check Box", _get_icon("CheckBox"), func(): return _create_control(1)),
	Item.new("Label", _get_icon("Label"), func(): return _create_control(2)),
	Item.new("Line Edit", _get_icon("LineEdit"), func(): return _create_control(3)),
	Item.new("VBox Container", _get_icon("VBoxContainer"), func(): return _create_control(4)),
	Item.new("HBox Container", _get_icon("HBoxContainer"), func(): return _create_control(5))
]

## Items for [Node].
static var node_list:Array[Item] = [
	Item.new_header("Nodes"),
	Item.new("Node 2D", _get_icon("Node2D"), func(): return _create_node(0)),
	Item.new("Node 3D", _get_icon("Node3D"), func(): return _create_node(1)),
	Item.new("Control", _get_icon("Control"), func(): return _create_node(2)),
	Item.new("File Dialog", _get_icon("FileDialog"), func(): return _create_node(2))
]

## Creates a [StaticBody3D] with a [MeshInstance3D] and a [CollisionShape3D] supposed to be it's children.
static func _create_primitive_3d(type:int) -> Array[Node]:
	var root = StaticBody3D.new()
	var mesh = MeshInstance3D.new()
	var collider = CollisionShape3D.new()
	
	mesh.name = "Mesh"
	collider.name = "Collider"
	
	match type:
		0: # Plane
			mesh.mesh = PlaneMesh.new()
			collider.shape = mesh.mesh.create_convex_shape()
			root.name = "Plane"
		1: # Box
			mesh.mesh = BoxMesh.new()
			collider.shape = BoxShape3D.new()
			root.name = "Box"
		2: # Sphere
			mesh.mesh = SphereMesh.new()
			collider.shape = SphereShape3D.new()
			root.name = "Sphere"
		3: # Capsule
			mesh.mesh = CapsuleMesh.new()
			collider.shape = CapsuleShape3D.new()
			root.name = "Capsule"
		4: # Cylinder
			mesh.mesh = CylinderMesh.new()
			collider.shape = CylinderShape3D.new()
			root.name = "Cylinder"
		5: # Prism
			mesh.mesh = PrismMesh.new()
			collider.shape = mesh.mesh.create_convex_shape()
			root.name = "Prism"
		6: # Torus
			mesh.mesh = TorusMesh.new()
			collider.shape = mesh.mesh.create_trimesh_shape()
			root.name = "Torus"
	
	return [root, mesh, collider]

## Creates a [CSGShape3D].
static func _create_csg_3d(type:int) -> Array[Node]:
	var csg:Node
	
	match type:
		0: # Box CSG
			csg = CSGBox3D.new()
			csg.name = "CSG Box"
		1: # Sphere CSG
			csg = CSGSphere3D.new()
			csg.name = "CSG Sphere"
			csg.rings = 32
			csg.radial_segments = 64
		2: # Cylinder CSG
			csg = CSGCylinder3D.new()
			csg.name = "CSG Cylinder"
			csg.sides = 64
		3: # Torus CSG
			csg = CSGTorus3D.new()
			csg.name = "CSG Torus"
			csg.ring_sides = 32
			csg.sides = 64
		4: # CSG Combiner
			csg = CSGCombiner3D.new()
			csg.name = "CSG Combiner"
	
	return [csg]

## Creates a [Control].
static func _create_control(type:int) -> Array[Node]:
	var control:Control
	
	match type:
		0: # Button
			control = Button.new()
			control.name = "Button"
		1: # Check Box
			control = CheckBox.new()
			control.name = "Check Box"
		2: # Label
			control = Label.new()
			control.name = "Label"
		3: # Line Edit
			control = LineEdit.new()
			control.name = "Line Edit"
		4: # VBox Container
			control = VBoxContainer.new()
			control.name = "VBox Container"
		5: # HBox Container
			control = HBoxContainer.new()
			control.name = "HBox Container"
	
	return [control]

## Creates a [Node].
static func _create_node(type:int) -> Array[Node]:
	var node:Node
	
	match type:
		0: # Node 2D
			node = Node2D.new()
			node.name = "Node 2D"
		1: # Node 3D
			node = Node3D.new()
			node.name = "Node 3D"
		2: # Control
			node = Control.new()
			node.name = "Control"
	
	return [node]

## Creates a [Node2D].
static func _create_node_2d(type:int) -> Array[Node]:
	var node:Node
	
	match type:
		0: # Sprite
			node = Sprite2D.new()
			node.name = "Sprite 2D"
		1: # Animated Sprite
			node = AnimatedSprite2D.new()
			node.name = "Animated Sprite 2D"
		2: # Tile Map
			node = TileMapLayer.new()
			node.name = "Tile Map Layer"
		3: # Static Body
			node = StaticBody2D.new()
			node.name = "Static Body 2D"
		4: # Collision Shape
			node = CollisionShape2D.new()
			node.name = "Collision Shape 2D"
	
	return [node]

## When an item is selected off of the list.
func _item_selected(id:int) -> void:
	if parent_node == null:
		parent_node = get_editor_interface().get_edited_scene_root().get_child(0)
	
	# Get Correct List
	
	var item_list:Array[Item]
	
	if parent_node is Node3D:
		item_list = node_3d_list
	elif parent_node is Node2D:
		item_list = node_2d_list
	elif parent_node is Control:
		item_list = control_list
	elif parent_node is Node:
		item_list = node_list
	else:
		return # parent_node is null or somehow not a node_list
	
	# Create Nodes

	var nodes_to_spawn:Array[Node] ## First node_list is parent, node_list after are children

	var name = menu_button.get_popup().get_item_text(id)
	nodes_to_spawn = item_list[item_list.find_custom(func(i): return i.name == name)].spawn_callable.call()
	
	# Rename
	
	var original_name:String = nodes_to_spawn[0].name
	
	if parent_node.get_children().any(func(child): return child.name == original_name): # If sibling already has name, find new available name
		var last_index:int
		
		for i in parent_node.get_children():
			if original_name in i.name:
				last_index += 1
		
		nodes_to_spawn[0].name = str(original_name, " ", last_index)
	
	# Add To Selected Node as Child
	
	parent_node.add_child(nodes_to_spawn[0])
	
	nodes_to_spawn[0].owner = get_editor_interface().get_edited_scene_root()
	
	for i in range(1, nodes_to_spawn.size()):
		nodes_to_spawn[0].add_child(nodes_to_spawn[i])
		nodes_to_spawn[i].owner = get_editor_interface().get_edited_scene_root()
	
	# Select New Node
	
	EditorInterface.get_selection().clear()
	EditorInterface.edit_node(nodes_to_spawn[0])

func _handles(object) -> bool:
	return object is Node

func _edit(object: Object) -> void:
	if !object:
		return
	
	parent_node = object

func _make_visible(visible: bool) -> void:
	menu_button.visible = visible

## Find the container for the quick add button to be placed in
func _find_place(node:Node) -> Node:
	for i in node.get_children():
		if i is Button && i.get_parent() is HBoxContainer:
			if (i as Button).icon == _get_icon("Add"):
				return i.get_parent()
		var d = _find_place(i)
		if d != null:
			return d
	return null

# ^^ I know this is horrible code, and I will NOT be fixing it unless godot adds better ways to get specific UI elements >:3
