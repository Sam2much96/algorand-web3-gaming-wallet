# *************************************************
# godot3-Dystopia-game by INhumanity_arts
# Released under MIT License
# *************************************************
#
# This is a auto-included singleton containing
# information used by the Game 
# Features
# (1) Savings function
# (2) A Call to find the current scene
# (3) Both save and load functions
# (4) A video streaming function, which should originally have been a child of the video streamers, 
#     but it runs faster on a singleton script and so, was called from here
# (5) Store video files functions
# (6) It loads scenes for faster switiching between
# To Add
# (1) A working zip and unzip function through GDUnzip repurposed as an editor plugin #('insert GDUNzip github address')
# (2) ArrAnge code base, make it easier to read at a glance
# (3) Use resource oader for video loading script
# Bugs
# (1) COnnect to GDUNZIP via editor script to zip and unzip 
# (2) Lacks proper documentation
# (3) Lacks Performance Optimization and Proper variable mnaming conventions
# (4) Causes a performance hog with process functions
# (5) Causes a ram hog with loaded adn preloaded variables
# *************************************************

extends Node

#***********Delete Start*************************#
#use variables to code ux +add a scene tree calculator
#var cinematics = preload ('res://resources/title animation/title..ogv') #I free memory once this is used
#var Pilot_ep

#var AMV 
var pilot_ep 
var VIDEO

onready var form #= load ('res://scenes/UI & misc/form/form.tscn')
var title_screen #= load( 'res://scenes/Title screen.tscn')
#var shop = load('res://scenes/UI & misc/Shop.tscn')
var controls #= load ('res://scenes/UI & misc/Controls.tscn')

"Comics  Book Module variables"
onready var comics #= load ('res://scenes/UI & misc/Comics.tscn')
onready var comics___2 #= load ('res://scenes/UI & misc/Comics____2.tscn')
var comics_chapter 
var comics_page 


var game_loop

var prev_scene
var prev_scene_spawnpoint
var next_scene = null
onready var curr_scene #= get_tree().get_current_scene().get_name()
onready var os = str(OS.get_name())
onready var kill_count : int = 0 #update to load from savefile
var player  = []
#var _p # Player placeholder
var player_hitpoints : int
var enemy = null
var enemy_debug
var initial_level : String = "res://scenes/levels/Outside.tscn"  # loading outside environment bug fixed
#var _Debug = null
var _player_state # gets state data from the player state machine
var video_stream #for the video streamers



# warning-ignore:unused_class_variable
var spawnpoint : Vector2
var spawn_x : int 
var spawn_y : int 
var current_level 


var Music_on_settings
export (String, 'analogue', 'direction') var direction_control : String  #toggles btw analogue and d-pad

var uncompressed # Varible holds uncompressed zip files


'ingame Environment Variables'
var near_interractible_objects #which objects use this?

'Scene Loading variables'
var _q : PackedScene # Large Resouce Scene Placeholder
var _r # Large Resource Placeholder Variable
var _o #for polling resource loader
var err
var a : int # Loader progress variable (a/b) 
var b : int
var loading_resource : bool = false
onready var scene_loader= ResourceLoader
#onready var wait_frames : int = 10 #not used, delete later
onready var progress : float




#***********Delete End*************************#


"Crypto Variables" 
var address
var mnemonic
var player_name
var algos : int #currency system, connect to $xmr protocol

#var recievers_addr: String #receivers address
#var _amount : int #transaction amount




'Screen Size Resolution'
var screenSize : Vector2
enum { SCREEN_HORIZONTAL, SCREEN_VERTICAL} 

var screenOrientation 

"In Game FX"
#var blood_fx: PackedScene = load ('res://scenes/UI & misc/Blood_Splatter_FX.tscn') #only load this once gameplay is on (optimization)
#var despawn_fx: PackedScene = load ("res://scenes/UI & misc/DespawnFX.tscn")
#var bullet_fx : PackedScene

'Temporary variants'
var temp

"Wallet Algo"
var NFT: TextureRect #should ideally be an array for multiple NFT's
var wallet_state  #wallet state global variabe

func _ready():
#	print('Blood fx:',blood_fx) #optimize blood fx to only load during game runtimes
	
	# Resizes window the preselected sizes
	
	if os == "Android":
		screenOrientation = SCREEN_VERTICAL
	else: screenOrientation = SCREEN_HORIZONTAL 
	print ("Screen orientation is: ", screenOrientation)

	player.append( get_tree().get_nodes_in_group('player') )#gets all player nodes in the scene
	if player.empty() == true: #error catcher 1             #it shows deleted object once player is despawns. Fix pls
		player = null
	
	
	
	VisualServer.set_default_clear_color(ColorN("white")) #what does this do?


func _process(_delta): #Turn process off if not in use (optimiztion) turn_off_processing()

# Handles Screen Orientation
	if screenOrientation == SCREEN_VERTICAL :

		pass
	elif screenOrientation == SCREEN_HORIZONTAL:

		pass
	else: return 1;

	'Resource Loader FOr Large Scenes'

	if _r is String && _r != "" && _q == null:
		var time_max = 50000 #sets an estimate maximum time to load scene
		var t = OS.get_ticks_msec()
		
		#scene_loader.load_interactive(_r) 
		
		_o= (scene_loader.load_interactive(_r)) #function returns a resourceInteractiveLoader

		scene_loader.load_interactive(_r) #function returns a resourceInteractiveLoader
		
	
		print (" Loader Debug Outer loop >>> Inner Loop")
		while OS.get_ticks_msec() < (t + time_max) && _o != null: 

			err = _o.poll()
			#loading_resource = true
			
			print ("_q: ",_q," _r: ",_r," Error: ",str(err),"Loop Debug") #Debugger
			
			
			
			if err == ERR_FILE_EOF: # Finished Loading #Works
				loading_resource = false
				
				_q = (_o.get_resource()) 
				print (_q , "Resource Loaded")
				change_scene_to( _q) # auto changes the scene
				#turn_off_processing("off") #introduces bugs
				break
				#return _q
			elif err == OK: #works
				a = _o.get_stage()
				b = _o.get_stage_count() 
				progress = (b/a) 
				print (a, "/",b,'/',"Progress: ", progress) #progress Debug?
			else: # Error during loading
				push_error("Problems loading Scene.  Debug Gloabls scene loader")
				print (str(progress) + "% " + str (_r))
				
				break
	if _r is String && _q != null: # 
		return




"""
Really simple save file implementation. Just saving some variables to a dictionary
"""
func save_game(): #modify code to include current scene and player position. also enemy spawner postions and info
	var save_game = File.new()
	save_game.open("user://savegeme.save", File.WRITE)
	var save_dict = {}
	save_dict.player = player #saves the player node 
	#save_dict.spawnpoint = spawnpoint
	save_dict.spawn_x = spawn_x
	save_dict.spawn_y =spawn_y
	save_dict.current_level = current_level
#	save_dict.inventory = Inventory.list()
#	save_dict.quests = Quest.get_quest_list()
	#my code
	save_dict.os = os
	save_dict.kill_count = kill_count
	#save_dict.currency = Suds #should load from encrypted wallet.cfg
	save_dict.prev_scene = prev_scene
	save_dict.prev_scene_spawnpoint = prev_scene_spawnpoint
	save_dict.player_hitpoints = player_hitpoints
	save_dict.direction_control = direction_control
	save_dict.Music_on_settings = Music_on_settings #add other variables to save
	
	#Comics Variables
	#save_dict.comics_chapter
	#save_dict.comics_page
	
	save_game.store_line(to_json(save_dict))
	save_game.close()
	print ("saved gameplay")

"""
If check_only is true it will only check for a valid save file and return true or false without
restoring any data
"""
func load_game(check_only=false):
	var save_game = File.new()
	
	if not save_game.file_exists("user://savegeme.save"):
		return false
	
	save_game.open("user://savegeme.save", File.READ)
	
	var save_dict = parse_json(save_game.get_line())
	if typeof(save_dict) != TYPE_DICTIONARY:
		return false
	if not check_only:
		_restore_data(save_dict)
	
	save_game.close()
	return true

"""
Restores data from the JSON dictionary inside the save files
"""
func _restore_data(save_dict):
	# JSON numbers are always parsed as floats. In this case we need to turn them into ints
	for key in save_dict.quests:
		save_dict.quests[key] = int(save_dict.quests[key])
#	Quest.quest_list = save_dict.quests
	
	# JSON numbers are always parsed as floats. In this case we need to turn them into ints
	for key in save_dict.inventory:
		save_dict.inventory[key] = int(save_dict.inventory[key])
#	Inventory.inventory = save_dict.inventory
	
	spawn_x = save_dict.spawn_x 
	spawn_y = save_dict.spawn_y
	current_level = save_dict.current_level
	
	player = save_dict.player
	
	os = save_dict.os 
	kill_count = save_dict.kill_count 
	#Suds = save_dict.currency #should load from encrypted wallet.cfg. Check NFT parser 
	player_hitpoints = save_dict.player_hitpoints
	prev_scene =save_dict.prev_scene 
	prev_scene_spawnpoint = save_dict.prev_scene_spawnpoint 
	direction_control = save_dict.direction_control
	
	######################################################
	print ("Loaded gameplay")

func update_curr_scene(): 
	curr_scene= get_tree().get_current_scene().get_name() 
	
func _go_to_title():
	'Quits if already at title screen'
	if get_tree().get_current_scene().get_name() == 'Menu':
		get_tree().quit()
#	Music.play_track(Music.ui_sfx[1])
	
	'changes scene to title_screen'
	return get_tree().change_scene_to(title_screen)

func _go_to_cinematics():
	return get_tree().change_scene('res://scenes/cinematics/cinematics.tscn') 



func resize_window(x,y): #resizes the game window
	screenSize = Vector2(x,y);
	return OS.set_window_size(Vector2(x,y));

# Convert bytes to Megabytes
func _ram_convert(bytes) :
	if bytes >= int(1):
		var _mb = String(round(float(bytes) / 1_048_576))
		return _mb

func change_scene_to(scene): #Loads scenes faster?
	if scene is PackedScene: 
		if scene != null: return get_tree().change_scene_to(scene)  
	elif scene is String: 
		if scene != "": 
			loading_resource = true
			_r = scene # triggers an auto scene loader in the processes 
			return _r

	else: return (print (typeof(scene) ,"is not supported in this function"))
	#if scene is 
	
func turn_off_processing(toggle): # to improve game speed and turn off idle processsing
	if toggle is String:
		if toggle == "on":
			set_process(true)
		elif toggle == "off":
			set_process(false)
		else:
			push_warning ("This function only uses on/off strings to control the globals processing functon")
	else: return

func restaVectores(v1, v2): #vector substraction
	return Vector2(v1.x - v2.x, v1.y - v2.y)

func sumaVectores(v1, v2): #vector sum
	return Vector2(v1.x + v2.x, v1.y + v2.y)

func memory_leak_management():
	return print_stray_nodes() #prints all orphaned nodes in project

"Memory Leak/ Orphaned Nodes Management System"
static func queue_free_children(node: Node) -> void:
	for idx in node.get_child_count():
		node.queue_free()
		
static func free_children(node: Node) -> void:
	for idx in node.get_child_count():
		node.free()

'Delete Files'
func delete_local_file(path_to_file: String) -> void:
	var dir = Directory.new()
	if dir.file_exists(path_to_file):
		dir.remove(path_to_file)
		dir.queue_free()
	else:
		push_error('File To Delete Doesnt Exist')
		return
