@tool
class_name QuickAddMenu extends EditorPlugin

var menu_button:MenuButton
var parent_node:Node

const TOOLTIP = "Quick Add Child Node... (Ctrl+E)\nQuickly Add/Create a New Node."

func add_custom_items(): ## Add custom items
	# Add your own code
	pass

func _enter_tree() -> void:
	add_custom_items()
	
	var root_node = get_editor_interface().get_base_control()
	var top_container:HBoxContainer = root_node.get_node("/root/@EditorNode@18865/@Panel@14/@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockVSplitLeftR/DockSlotLeftUR/Scene/@VBoxContainer@4681/@HBoxContainer@4684")
	
	menu_button = MenuButton.new()
	menu_button.theme_type_variation = &"FlatMenuButton"
	menu_button.icon = load("uid://ds2d3cnebnoxj")
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
	
	menu_button.get_popup().id_pressed.connect(item_selected)
	menu_button.about_to_popup.connect(update_add_list)
	
	if EditorInterface.get_selection().get_selected_nodes().size() == 0:
		menu_button.hide()

func _exit_tree() -> void: ## Delete [member menu_button]
	menu_button.queue_free()
	menu_button = null

func update_add_list() -> void: ## Updates list of items to quick add
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
	
	static func new_header(name:String, icon:Texture2D = null) -> Item:
		var preset = Item.new(name, icon, (func(): return false))
		preset.header = true
		return preset

## Items for [Node3D]s.
static var node_3d_list:Array[Item] = [
	Item.new_header("Primitive Shapes"),
	Item.new("Plane", load("uid://04sjd3fhspum"), func(): return create_primitive_3d(0)),
	Item.new("Box", load("uid://kcqkdkckt74o"), func(): return create_primitive_3d(1)),
	Item.new("Sphere", load("uid://c1qotmgdt3wv3"), func(): return create_primitive_3d(2)),
	Item.new("Capsule", load("uid://fhywelx5d3gd"), func(): return create_primitive_3d(3)),
	Item.new("Cylinder", load("uid://dv1xiqpngy1pk"), func(): return create_primitive_3d(4)),
	Item.new("Prism", load("uid://bkqqtifxdtts8"), func(): return create_primitive_3d(5)),
	Item.new("Torus", load("uid://bui2yippw5un6"), func(): return create_primitive_3d(6)),
	Item.new_header("CSGs"),
	Item.new("Box CSG", load("uid://mru2wroj0hws"), func(): return create_csg_3d(0)),
	Item.new("Sphere CSG", load("uid://dpcm004e20a7i"), func(): return create_csg_3d(1)),
	Item.new("Cylinder CSG", load("uid://60vpd04k7ajx"), func(): return create_csg_3d(2)),
	Item.new("Torus CSG", load("uid://b5ycf41f2iwyv"), func(): return create_csg_3d(3)),
	Item.new("CSG Combiner", load("uid://c3f30fs8pq6wq"), func(): return create_csg_3d(4))
]

## Items for [Node2D]s.
static var node_2d_list:Array[Item] = [
	Item.new_header("Nodes"),
	Item.new("Sprite", load("uid://da6h1txipiy4"), func(): return create_node_2d(0)),
	Item.new("Animated Sprite", load("uid://ci35f6n6m2mke"), func(): return create_node_2d(1)),
	Item.new("Tile Map", load("uid://b4wwexqygjm0"), func(): return create_node_2d(2)),
	Item.new("Static Body", load("uid://ciyi48ox8bqtr"), func(): return create_node_2d(3)),
	Item.new("Collision Shape", load("uid://cdnwk2nynvqcs"), func(): return create_node_2d(4)),
]

## Items for [Control]s.
static var control_list:Array[Item] = [
	Item.new_header("UI Elements"),
	Item.new("Button", load("uid://hphfsmmjje1h"), func(): return create_control(0)),
	Item.new("Check Box", load("uid://dxncpjvjumkws"), func(): return create_control(1)),
	Item.new("Label", load("uid://bs34kqsixe1yx"), func(): return create_control(2)),
	Item.new("Line Edit", load("uid://biddvfrt12q3l"), func(): return create_control(3)),
	Item.new("VBox Container", load("uid://d353irfrid81h"), func(): return create_control(4)),
	Item.new("HBox Container", load("uid://b3lyvsbrgyvak"), func(): return create_control(5))
]

## Items for [Node].
static var node_list:Array[Item] = [
	Item.new_header("Nodes"),
	Item.new("Node 2D", load("uid://b7c51h128c283"), func(): return create_node(0)),
	Item.new("Node 3D", load("uid://bjrkhgqok8bge"), func(): return create_node(1)),
	Item.new("Control", load("uid://6e8ojoc4n6v8"), func(): return create_node(2))
]

static func create_primitive_3d(type:int) -> Array[Node]: ## Creates a [StaticBody3D] with a [MeshInstance3D] and a [CollisionShape3D] supposed to be it's children.
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

static func create_csg_3d(type:int) -> Array[Node]: ## Creates a [CSGShape3D].
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

static func create_control(type:int) -> Array[Node]: ## Creates a [Control].
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

static func create_node(type:int) -> Array[Node]: ## Creates a [Node].
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

static func create_node_2d(type:int) -> Array[Node]: ## Creates a [Node2D].
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

func item_selected(id:int) -> void: ## When an item is selected off of the list.
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


''' UNUSED CODE (Keeping bc godot might change UI naming / hierarchy, so ts is gonna be needed, but if you aren't me, just ignore it lol)

func find_place(node_list:Node, p:int) -> bool: ## Ik ts is horrible code, and I will NOT be fixing it unless godot gets better at stuff like ts >:3
	p += 1
	for i in node_list.get_children():
		if i is Button:
			if p == 9 and i.name == "@Button@4682":
				topbox = i.get_parent()
				print(topbox.get_path())
				return true
		if find_place(i, p):
			return true
	return false

'''
