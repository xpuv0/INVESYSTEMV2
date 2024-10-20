extends Control
class_name Inventory
## This inventory system functions by changing the slot data array and making the slot UI change from it
## This allows for modular and clean code later on
## Only real issue I can see with this approach is how you need to constantly duplicate slot datas
## In order to prevent resources to be shared across the inventory
## IMPORTANT
## Add equipment slots below the equipment container for it to work, and change slot_Type var
# Completed 25/6/24
# Equiping added 30/6/24


const SLOT = preload("res://Inventory/Scenes/slot.tscn")

@onready var slot_container = $SlotContainer
@onready var equipment_container = $EquipmentContainer
@onready var grabbed_slot = $GrabbedSlot


@export var inventory_data : InventoryData
@export var equipment_data : InventoryData

const GOLDEN_PICKAXE = preload("res://Items/Data/golden_pickaxe.tres")
const GOLD_INGOT = preload("res://Items/Data/gold_ingot.tres")

func _ready():
	initialize_inventory()
	inventory_data.add_item(GOLDEN_PICKAXE)
	inventory_data.add_item(GOLD_INGOT, 100)


func _physics_process(_delta):
	grabbed_slot.global_position = get_global_mouse_position()


func initialize_inventory():
	setup_grabbed_slot()
	connect_signals()
	fill_and_update_containers()


func setup_grabbed_slot():
	grabbed_slot.slot_data.set_parent_inventory_data(inventory_data)


func connect_signals():
	inventory_data.inventory_updated.connect(_on_inventory_updated)
	

func fill_and_update_containers():
	fill_container(inventory_data, slot_container)
	# Because we dont want to fill the equipment container if slots are already there
	update_container_data(equipment_data, equipment_container)


func fill_container(data: InventoryData, container):
	for i in range(data.slot_datas.size()):
		var slot = create_slot(container)
		slot.set_slot_data(data.slot_datas[i])
		slot.slot_data.set_parent_inventory_data(data)
		slot.gui_input.connect(_on_slot_gui_input.bind(slot))


func update_container_data(data: InventoryData, container):
	for i in range(data.slot_datas.size()):
		var slot = get_slot(container, i)
		slot.set_slot_data(data.slot_datas[i])
		slot.slot_data.set_parent_inventory_data(data)
		slot.gui_input.connect(_on_slot_gui_input.bind(slot))


func create_slot(container : GridContainer):
	var new_slot = SLOT.instantiate()
	container.add_child(new_slot)
	return new_slot


func get_slot(container : GridContainer, index : int):
	if index < container.get_child_count():
		return container.get_child(index)


func _on_inventory_updated():
	refresh_container_slots(inventory_data, slot_container)
	refresh_container_slots(equipment_data, equipment_container)


func refresh_container_slots(data: InventoryData, container : GridContainer):
	for i in range(data.slot_datas.size()):
		var slot = container.get_child(i)
		slot.set_slot_data(data.slot_datas[i])


func _on_slot_gui_input(event: InputEvent, slot: Slot):
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_MASK_LEFT:
				handle_left_click(slot)
			MOUSE_BUTTON_RIGHT:
				handle_right_click(slot)


func handle_left_click(slot: Slot):
	if grabbed_slot.slot_data.item == null:
		grab_item(slot)
	elif slot.slot_data.item == null:
		place_item_in_empty_slot(slot)
	elif slot.slot_data.item != grabbed_slot.slot_data.item:
		swap_or_stack(slot)
	else:
		stack_items_if_possible(slot)

	update_parent_inventory_data(slot)


func grab_item(slot: Slot):
	if slot.slot_data.item:
		grabbed_slot.set_slot_data(slot.slot_data.duplicate())
		set_physics_process(true)
		slot.reset_slot_data()


func place_item_in_empty_slot(slot: Slot):
	if slot.type_check(grabbed_slot.slot_data.item):
		slot.set_slot_data(grabbed_slot.slot_data.duplicate())
		grabbed_slot.reset_slot_data()


func swap_or_stack(slot: Slot):
	if slot.type_check(grabbed_slot.slot_data.item):
		swap_items(slot)
	elif slot.slot_data.item.stackable:
		stack_items(slot)


func stack_items_if_possible(slot: Slot):
	if slot.slot_data.item.stackable:
		stack_items(slot)


func update_parent_inventory_data(slot: Slot):
	set_parent_inventory_data(slot.slot_data.parent_inventory_data, slot)


func handle_right_click(slot: Slot):
	if grabbed_slot.slot_data.item == null:
		return # Show item information
	elif slot.slot_data.item == null:
		if slot.type_check(grabbed_slot.slot_data.item):
			split_item(slot)
	elif slot.slot_data.item == grabbed_slot.slot_data.item and slot.slot_data.item.stackable:
		add_item_to_stack(slot)

	if !are_inventories_different(slot.slot_data, grabbed_slot.slot_data):
		update_parent_inventory_data(slot)


func swap_items(slot: Slot):
	var temp_data = grabbed_slot.slot_data.duplicate()
	grabbed_slot.set_slot_data(slot.slot_data.duplicate())
	slot.set_slot_data(temp_data)


func stack_items(slot: Slot):
	var total_quantity = grabbed_slot.slot_data.quantity + slot.slot_data.quantity
	if total_quantity > slot.slot_data.MAX_QUANTITY:
		grabbed_slot.slot_data.quantity = total_quantity - slot.slot_data.MAX_QUANTITY
		slot.slot_data.quantity = slot.slot_data.MAX_QUANTITY
	else:
		slot.slot_data.quantity += grabbed_slot.slot_data.quantity
		grabbed_slot.reset_slot_data()

	update_ui(slot)


func split_item(slot: Slot):
	var new_slot_data = grabbed_slot.slot_data.duplicate()
	new_slot_data.quantity = 1
	slot.set_slot_data(new_slot_data)
	grabbed_slot.slot_data.quantity -= 1
	update_ui(slot)

	if grabbed_slot.slot_data.quantity == 0:
		grabbed_slot.reset_slot_data()


func add_item_to_stack(slot: Slot):
	if slot.slot_data.quantity < slot.slot_data.MAX_QUANTITY:
		slot.slot_data.quantity += 1
		grabbed_slot.slot_data.quantity -= 1
		update_ui(slot)

		if grabbed_slot.slot_data.quantity == 0:
			grabbed_slot.reset_slot_data()


func update_ui(slot: Slot):
	slot.update_ui()
	grabbed_slot.update_ui()


func set_parent_inventory_data(parent_inventory_data: InventoryData, slot: Slot):
	# Allows for the inventory data to change when swapping between two different inventories
	parent_inventory_data.slot_datas[slot.get_index()] = slot.slot_data

func are_inventories_different(slot_data1: SlotData, slot_data2: SlotData) -> bool:
	return slot_data1.parent_inventory_data != slot_data2.parent_inventory_data
