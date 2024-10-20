extends Resource
class_name InventoryData


@export var slot_datas : Array[SlotData] = []


signal inventory_updated


func add_item(item : Item, amount : int):
	# Get all slots that have the same item.
	### If item is stackable
		# Loop through the array and add the maximum amount that the slot can hold.
		# If the there are still items left to add, add them to empty slots.
	### If item isn't stackable
		# Loop through all empty slots, and add the item
	var slot_datas_with_item : Array = slot_datas.filter(func(slot_data): return slot_data.item == item and !(slot_data.quantity == slot_data.MAX_QUANTITY))
	var empty_slot_datas : Array = slot_datas.filter(func(slot_data): return slot_data.item == null)
	var items_left_to_add : int = amount
	if item.stackable:
		for slot_data in slot_datas_with_item:
			var items_that_should_be_added : int = min(slot_data.MAX_QUANTITY, items_left_to_add)
			slot_data.quantity += items_that_should_be_added
			items_left_to_add -= items_that_should_be_added
			items_left_to_add = clamp(items_left_to_add, 0, items_left_to_add)
			if items_left_to_add <= 0:
				inventory_updated.emit()
				return
		if items_left_to_add > 0:
			for empty_slot_data in empty_slot_datas:
				var items_that_should_be_added : int = min(empty_slot_data.MAX_QUANTITY, items_left_to_add)
				empty_slot_data.item = item
				empty_slot_data.quantity += items_that_should_be_added
				items_left_to_add -= items_that_should_be_added
				if items_left_to_add <= 0:
					inventory_updated.emit()
					return
	if !item.stackable:
		for empty_slot_data in empty_slot_datas:
			empty_slot_data.item = item
			empty_slot_data.quantity = 1
			items_left_to_add -= 1
			items_left_to_add = clamp(items_left_to_add, 0, items_left_to_add)
			if items_left_to_add <= 0:
				inventory_updated.emit()
				return


func remove_item(item : Item, amount : int):
	# Get all slot datas with the item
	# Loop through the slot datas, removing the amount that needs to be removed from the slot
	# If the slot's quantity == 0, delete the item
	var slot_datas_with_item : Array = slot_datas.filter(func(slot_data): return slot_data.item == item)
	var items_left_to_remove : int = amount
	for slot_data in slot_datas_with_item:
		var amount_that_slot_can_remove = slot_data.quantity - 0
		slot_data.quantity -= items_left_to_remove
		items_left_to_remove -= amount_that_slot_can_remove
		items_left_to_remove = clamp(items_left_to_remove, 0, items_left_to_remove)
		if slot_data.quantity == 0:
			slot_data.item = null
		if items_left_to_remove == 0:
			break
	inventory_updated.emit()
	return


func has_slot_data(slot_data_to_look_for : SlotData) -> bool:
	var slot_data_found : bool = false
	for slot_data in slot_datas:
		if slot_data == slot_data_to_look_for:
			slot_data_found = true
			break
	return slot_data_found
