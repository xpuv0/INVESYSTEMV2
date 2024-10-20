extends Resource
class_name Item


@export var id : String
@export var name : String 
@export var texture : Texture
@export_multiline var description : String
@export var stackable : bool = true
@export var value : int = 0
@export_enum("Common", "Uncommon", "Rare", "Epic","Mythic","Legendary")  var rarity : String = "Common"
@export_enum("Normal", "Pickaxe") var slot_type : String = "Normal"
