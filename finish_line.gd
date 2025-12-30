extends TextureRect

@export var player:player

func _ready() -> void:
	assert(player is player,"you forgot to set the player on your finish line.")
	player.finish_x=global_position.x
