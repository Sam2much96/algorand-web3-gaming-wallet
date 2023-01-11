extends TextureRect



# Makes The SceneTree's Texture React Easily callable
class_name NFT

func _ready():
	#makes itself a global variable to avvoid proken node paths
	Globals.NFT = self
	pass # Replace with function body.

" Sets Img Texture To A Texture React"


