extends Resource
class_name InventoryData


@export var slot_datas : Array[SlotData] = []


signal inventory_updated


func add_item(item: Item, amount: int = 1):
	var items_left_to_add: int = amount
	var slot_datas_with_item: Array = slot_datas.filter(func(slot_data): return slot_data.item == item and slot_data.quantity < slot_data.MAX_QUANTITY)
	var empty_slot_datas: Array = slot_datas.filter(func(slot_data): return slot_data.item == null)

	if item.stackable:
		items_left_to_add = add_slot_data_to_slots(slot_datas_with_item, item, items_left_to_add)
		if items_left_to_add > 0:
			items_left_to_add = add_slot_data_to_slots(empty_slot_datas, item, items_left_to_add, true)
	else:
		items_left_to_add = add_non_stackable_items(empty_slot_datas, item, items_left_to_add)

	inventory_updated.emit()


func add_slot_data_to_slots(slot_data_array: Array[SlotData], item: Item, amount: int, is_new_slot: bool = false) -> int:
	for slot_data in slot_data_array:
		if is_new_slot == true:
			slot_data.item = item
		var items_to_add: int = min(slot_data.MAX_QUANTITY - slot_data.quantity, amount)
		slot_data.quantity += items_to_add
		amount -= items_to_add
		if amount <= 0:
			return 0
	return amount


func add_non_stackable_items(slot_data_array: Array[SlotData], item: Item, amount: int) -> int:
	for slot_data in slot_data_array:
		slot_data.item = item
		slot_data.quantity = 1
		amount -= 1
		if amount <= 0:
			return 0 
	return amount


func remove_item(item: Item, amount: int):
	var items_left_to_remove: int = amount
	var slot_datas_with_item: Array[SlotData] = slot_datas.filter(func(slot_data): return slot_data.item == item)

	for slot_data in slot_datas_with_item:
		var amount_to_remove: int = min(slot_data.quantity, items_left_to_remove)
		slot_data.quantity -= amount_to_remove
		items_left_to_remove -= amount_to_remove
		if slot_data.quantity == 0:
			slot_data.item = null
		if items_left_to_remove <= 0:
			break

	inventory_updated.emit()



func has_slot_data(slot_data_to_look_for : SlotData) -> bool:
	var slot_data_found : bool = false
	for slot_data in slot_datas:
		if slot_data == slot_data_to_look_for:
			slot_data_found = true
			break
	return slot_data_found
