# *************************************************
# godot3-Dystopia-game by INhumanity_arts
# Released under MIT License
# *************************************************
# Comics 5.1.1
# This is a plugin containing the comics bool page logic
# A comic book module for Godot game engine.
# I implemented A touch input manager here
# *************************************************
# Features
#(1) Loads, Zooms and Drags Comic Pages
#(2) Uses New multitouch gestures by implementing a touch input manager
#
# To DO:
#(1) connect this script with  the dialogue singleton for translation and wordbubble fx co-ordination
#(2) Update Logic to be used by Texture React nodes NFT
# (3) Add more parameters to the drag() function to be reusable in other scripts
# (4) Copy NFT storage codes to save downloaded comic chapters locally. It'll optimize file sizes
# (5) Implement State Machine (on It)
# (6) Implement Extendible (NFT) drag and Drop (buggy)
# (7) Implement Page state and Pages state
# *************************************************
# Bugs:
# (1) it has a wierd updatable bug that's visible in the debug panel
# (2) Center Page is buggy
# (3) Drag and Drop across small distances is buggy (fixed)
# (4) Calibrate Swipe Gestures
# *************************************************



extends Control

class_name Comics


signal comics_showing
signal loaded_comics 
signal freed_comics
#signal panel_change
signal swiped(direction)
signal swiped_canceled(start_position)
 

#Placeholder signals
#signal next_panel
#signal previous_panel

export (PackedScene) var current_comics 

"Prealoaded Comics"
# host on ipfs and use local user directory to store comic files
# run file checks to verify image downloadds and load
#programmatically
# Size optimization
var comics = {
	 1: 'res://scenes/Comics/chapter 1/chapter 1.tscn',
	2:'res://scenes/Comics/chapter 2/chapter 2.tscn',
	3:'res://scenes/Comics/chapter 3/chapter 3.tscn',
	4:"res://scenes/Comics/chapter 4/chapter 4.tscn",
	5:"res://scenes/Comics/chapter 5/chapter 5.tscn",
	6:"res://scenes/Comics/chapter 6/chapter 6.tscn",
	7:"res://scenes/Comics/chapter 7/chapter 7.tscn",
	8: 'res://scenes/Comics/Outside/outside.tscn'}

var swipe_start_position = Vector2()

export var memory = {} #use this variable to store current frame and comics info

export (int) var  current_frame   = 0
export (int) var current_chapter 

onready var next_scene = null

var can_drag : bool = false
onready var zoom = false
onready var comics_placeholder 

#onready var animation = $AnimationPlayer 
onready var buttons
onready var Kinematic_2d  #the kinematic 2d node for drag and drop
#onready var camera2d = $Kinematic_2D/placeholder/Camera2D 
onready var position 
onready var center
onready var target =Vector2(0,0) 
onready var origin = get_viewport_rect().size/2#set origin point to the center of the viewport

onready var loaded_comics : bool = false

onready var _input_device
onready var _e = Timer.new()
onready var _comics_root = self

#onready var _debug_= get_tree().get_root().get_node("/root/Debug")

"Bug FIx from <200 absolute Distances"

var target_memory_x: Array = [] #stores vector 2 of previous targets
var target_memory_y: Array = [] #stores vector 2 of previous targets


var enabled : bool 

#**********Swipe Detection Direction Calculation Parameters************#
var swipe_target_memory_x : Array = [] # for swipe direction x calculation
var swipe_target_memory_y : Array = [] # for swipe direction y calculation
var direction : Vector2
var swipe_parameters : float = 0.1 # is 1 in Dystopia-App
var x1 #: float
var x2 #: float
var y1 #: float
var y2 #: float
export(float,0.5,1.5) var MAX_DIAGONAL_SLOPE  = 1.3


# For Panel Changer
var q : Array = []

func _ready():
	#wordbubble() #for debug purposes only
	
	if current_comics !=null:
		load_comics()
		#Globals.comics = self #updates itself to the globals singleton



	enabled = false
	#target = Vector2() duplicate code 
	 #for swipe detection
	_e.one_shot = true
	_e.wait_time = 0.5
	_e.name = str ('swipe detection timer')
	_comics_root.call_deferred('add_child',_e)
	for _c in get_children():
		if _c is Timer:
			return connect('Timeout',_e,'_on_Timer_timeout') #connect timer to node with code

"""
LOAD COMICS INTO THE SCENE TREE AS SPRITESHEETS
"""
#implement Texture react node functionality 

func load_comics(): 
	if current_comics != null && current_comics.can_instance() == true:
		for _p in get_tree().get_nodes_in_group('Cmx_Root'):
			enabled = true
			zoom = false

			can_drag = true

			current_frame =  int(0)
			Kinematic_2d = KinematicBody2D.new()
			comics_placeholder = Control.new()
		
			Kinematic_2d.name= 'Kinematic_2d'
			comics_placeholder.name = 'comics_placeholder'
	
			comics_placeholder.set_mouse_filter(2)

			_p.call_deferred('add_child',comics_placeholder) #reparents comic placeholder node 

			print ('Comic root:',_p)

			

			comics_placeholder.add_child(Kinematic_2d)
	
			var collision_shape =CollisionShape2D.new()
			var shape = RectangleShape2D.new() #new code
			shape.set_extents((Vector2(130,130))) #new code
			collision_shape.set_shape (shape) #new code
	
			#Kinematic Body 2D
			Kinematic_2d.add_child(collision_shape) #set the collision shape
			#connect signals
			Kinematic_2d.connect("mouse_exited",self,'_on_Kinematic_2D_mouse_exited') 
			Kinematic_2d.connect('mouse_entered',self,'_on_Kinematic_2D_mouse_entered')

			#Loaded Comic Signal
			emit_signal("loaded_comics")
			print ('loading comics') #for debug purposes 

			var _x = current_comics.instance()
			Kinematic_2d.add_child(_x) 
			
			#position pages
			_x.position =Kinematic_2d.position
 
	# Error Catcher 1
	if current_comics == null and current_comics.can_instance() == false  :
		push_error('unable to instance comics scene')
		pass
	if memory.empty() != true && current_comics == null: #error catcher 1
		current_comics = memory[0] # load from memory

	if memory.empty() == true && current_comics == null: #error catcher 2
		push_error('current comics empty')
		current_comics = comics[1] #default comic


	loaded_comics = true
	comics_placeholder.show()
	emit_signal("comics_showing")
	center_page()



func _input(event): 
	"""
	#Comic panel changer
	"""
	if event.is_action_pressed("ui_focus_next") && enabled : #button controls
		
		next_panel()
	if event.is_action_pressed("ui_focus_prev") && enabled:
		prev_panel()


#Toggles comics visibility on/off
#It disappears if not enabled 
	"Enables and Disables Comics Node (when Comics button is pressed)"
		#TEmporarily disabling
	
	# check if the event is valid
	#if  enabled == false and event.is_action_pressed("comics") : #SImplifying this code bloc
	#	enabled = true 
	#elif enabled == true and event.is_action_pressed("comics") :
	#	enabled = false

	"Controller for Joypad"
	if event is InputEventJoypadButton && self.visible == true:
		if event.is_action_pressed("ui_select"): _zoom(comics_placeholder)


	if event is InputEventJoypadMotion and self.visible == true:
		var axis = event.get_axis_value()
		print('JoyStick Axis Value' ,axis)
		
		#Changes Page Panels
		if round(axis) == 1:
			next_panel()
		if round(axis) == -1:
			prev_panel()
		pass

	"Stops From Processing Mouse Inputs"
	if event is InputEventMouse:
		#return
		pass
	if event in InputEventMouseMotion:
		#return
		pass


	# Handle Touch
	"""
	CONTROLS THE TOUCH INPPUT FOR THE COMICS NODE
	"""
	if event is InputEventScreenTouch :
		#if event is  InputEventMultiScreenDrag == true : # Works
		target =  event.get_position()
		#if event.get_index() == int(2) and event is InputEventScreenPinch : #zoom if screentouch is 2 fingers & uses input manager from https://github.com/Federico-Ciuffardi/Godot-Touch-Input-Manager/releases
		#		
		#		_zoom() #you can use get_index to get the number of fingers
		
		"Handles Swipe Detection" #buggy 
		_handle_swipe_detection(event)

	"Handles Screen Dragging"
	if event is InputEventScreenDrag   :
		pass

	"Handles Multitouch Gesture"
	#Documentation: https://github.com/Federico-Ciuffardi/Godot-Touch-Input-Manager/wiki
	# Use Global Animation Player to play Swipe Gesture Actions
	# Export Animation Resource File from AlgoWallet App
	# Load Animation As resource file
	if event is InputEventScreenTwist:
		print ("Input: Screen Twist / Action: Rotate")
	
	# Zoom in/out Gesture
	if event is InputEventScreenPinch :
		print ("Input: Screen Pinch / Action: Zoom In/Out")
	
	# Zoom in/out gesture
	if event is InputEventMultiScreenTap :
		print ("Input: Screen Tap / Action: Zoom in/OUt")

# Handles releasing 
	#pass
# Handles double clicking
	#pass



	if event is InputEventMouseButton && event.doubleclick && loaded_comics == true:
		
		_zoom(comics_placeholder) #disabled for debugging, enable when done debugging
		return



func _process(_delta):
	"Limits memory usage for Drag and Drop bug fixer"
	#optimize code
	if target_memory_x.size() > 30:
		target_memory_x.clear() 
	if target_memory_y.size() > 30:
		target_memory_y.clear() 


	# ReWrite to Use State machine
	if current_comics != null:
		loaded_comics = true
	#print(position,target)
	if current_comics == null or current_frame == null  : #error catcher 
		#emit_signal("freed_comics") disabling signals for now
		loaded_comics = false
	
	
	if loaded_comics == true:
		#emit_signal("loaded_comics")
		pass
	
	"VISIBILITY"
	# add counter
	if enabled == true: #toggles visibility 
		show() #Disabling for debugging
		
		#print ("Enabled")
		
		pass

	if enabled == false:
		hide() #Disabling for debugging
		#print ("DIsabled")
		pass
	memory=get_tree().get_nodes_in_group("comics") #an array of all comics in the scene tree

	if memory.empty() != true :
		pass
	elif memory.empty() == true:
		#current_comics = load_comics()
		pass
	if loaded_comics == true && memory.size() >= 2: #double instancing error fix
		get_tree().queue_delete(memory.front()) 
		loaded_comics = false 

#current frame controler

	if enabled != false && Kinematic_2d != null:
		
		if comics_placeholder != null:
			for _i in Kinematic_2d.get_children():
				if _i is AnimatedSprite:
					_i.set_frame(int(current_frame))  
					#working
					_i.update() #canvas layer not updating changes
					if  current_frame > _i.get_frame() : 
						comics_placeholder.queue_free() 
						comics_placeholder = null
						enabled = false 
						loaded_comics = false #working buggy
						current_frame = null # working buggy
						emit_signal("freed_comics")

	"""Updates the Comic Debug to a global debug singleton"""
	if enabled:
		pass
		#if _debug_ != null && _debug_.enabled == true:
			#var Debug  = Engine.get_singleton('Debug')
		#	_debug_.Comics_debug = str(
		#		'Curr frme:', current_frame , 'Cmx: ',current_comics, 'Enbled',enabled,'can drag: ',#can_drag,
		#		 ' Zoom: ',zoom, 'LC: ',loaded_comics
		#		)
"""
DRAG FUNCTION
"""
#body must be a kinematic body 2d
func drag(_target : Vector2, _position : Vector2, _body : KinematicBody2D)-> void: #pass this method some parmeters
	#add more parameters
 # Input manager from https://github.com/Federico-Ciuffardi/Godot-Touch-Input-Manager/releases 
	
	
	if can_drag:
		center = restaVectores(_target, _position)
		_body.set_position(_target)
		#can_drag = true 
			
		" Drag n Drop Logic"
			
			
		"If Distance to input target is greater than 200"
		#for large size drags
		if abs(_position.distance_to(_target)) > 200: #if its far...
		##use suma vectores function for vector maths
			_body.move_and_slide(center) #move and slide to center
			#print ('moving to center') #for debug purposes only


#******************************Bug Begins**********************#

		"If Distance is less than 200"
		#for small size drags
		#Works
		if abs(_position.distance_to(_target)) < 200 : #if its close
				#_body.move_and_slide(target)
				#how to fix
				
			"""
			I can calculate the difference between the last 2 drags to fix this bug
			drag bug is caused by sudden disparity between the target vectors
			if the previous target position is different by a large amount, discard it and wait for next target input
			"""
				
			var x : int = _target.x
			var y : int = _target.y
			target_memory_x.append(x) #works
			target_memory_y.append(y) #works
			
			# Rejects buggy input targets
			# Save both x & y inputs in similar array to properly debug
			if abs(target_memory_x[target_memory_x.size() - 2] - x) > 3: #if more than 3 buggy inputs have been saved
				
				#print ('Error x axis') #for debug purposes only
				#print ('x axis size debug: ' ,target_memory_x.size()) #for debug purposes only
				#print (target_memory_x) #temporarily disabling for debug purposes
				
				
				
				
				
				#deletes bad input
				target_memory_x.erase(x) #temporarily disabling for debugging
				
				
				
				
				#target_memory_x.remove(target_memory_x[-1]) #deletes error #introduces bug
				if target_memory_x.size() == 1:
					_body.move_and_slide(Vector2(target_memory_x[0], target_memory_y.back()))
				
				#Erases Faulty Horizontal Input
				if target_memory_x.size() > 1:
					_body.move_and_slide(Vector2(target_memory_x[target_memory_x.size() - 2], target_memory_y.back()))
				
				return
			if abs(target_memory_y[target_memory_y.size() - 2] - x) > 3:
				
				#print ('Error y axis')
				#print ('y axis size debug: ' ,target_memory_y.size()) 
				#print (target_memory_y) #For debug purposes only
				
				
				
				
				
				#deletes bad input
				target_memory_y.erase(y) #temporarily disabling for debugging
				
				
				
				
				
				if target_memory_y.size() == 1: #error catcher
					
					#moves to a predicted presaved axis
					_body.move_and_slide(Vector2(target_memory_x.back(), target_memory_y[0]))
				
				elif target_memory_y.size() > 1:
					
					#moves to a predicted presaved axis
					_body.move_and_slide(Vector2(target_memory_x.back(), target_memory_y[target_memory_y.size() - 1]))
				return 

			#code base is too long to debug. Simplify
			if not abs(target_memory_y[target_memory_y.size() - 2] - x) && abs(target_memory_x[target_memory_x.size() - 2] - x) > 3 :
				#_body.set_position(_target)
				_body.move_and_slide(_target)

#******************************Bug Ends**********************#
"""
				 ZOOM

"""

func _zoom(_comics_placeholder : Control)-> bool:
	
	if loaded_comics == true:
		var scale =_comics_placeholder.get_scale()
		if scale == Vector2(1,1)  :
			#print ('zoom in') #for debug purposes only
			_comics_placeholder.set_scale(scale * 2) 
			zoom = true
			return true 
		if scale > Vector2(1,1):
			#print ('zoom out') #for debug purposes only
			scale = _comics_placeholder.get_scale()
			_comics_placeholder.set_scale(scale / 2) 
			zoom = false
	return zoom 

'sets comic page to center of screen'
func center_page(): #
	if loaded_comics == true:
		if zoom == false: 
			if Kinematic_2d.position or origin != null:
				Kinematic_2d.position = origin
			else:
				pass


" Triggers a State Change in Wallet Nodes"
# Different Mechanics are Implemented For Different Wallet Nodes

func next_panel():
	print ('Next Panel')
	
	#********Wallet State Controller Logic*******#

	# Hacky
	
	
		# Bug: Adds up number too rapidly
		# Solutions
		# (1) Change the Current Frame Data Structure to Array, for comparisons



	if Wallet.state != Wallet.COLLECTIBLES:
		# save the current index to array
		q.append(Wallet.state_controller.get_selected_id())
		
		var l : int = q.pop_back() #Wallet.state_controller.get_selected_id()
		var p = l + 1
			#if q < p :

		if p <= Wallet.state_controller.get_item_count():
			# Play Animation
		
			Wallet._Animation.play("SWIPE_RIGHT")
			Wallet._Animation.queue("RESET")

			Wallet.state_controller.select(p)
			


		print ('Selected Wallet State: ',Wallet.state_controller.get_selected_id()) # for debug purposes
		print (q) # for debug purposes only



		# Stops Overflow with thos array
		if q.size() >= Wallet.state_controller.get_item_count():
			q.clear()


func prev_panel():
	print ('prev panel')
	
	#********Wallet State Controller Logic*******#
	# Hacky


	if Wallet.state != Wallet.COLLECTIBLES :
		q.append(Wallet.state_controller.get_selected_id())
		#var p : int = Wallet.state_controller.get_index()
		var l : int = Wallet.state_controller.get_selected_id()
		var p = l - 1
		 
		if p <= Wallet.state_controller.get_item_count() && p != -1 :
			Wallet.state_controller.select(p)
		
			# Play Animation
			Wallet._Animation.play("SWIPE_LEFT")
			return Wallet._Animation.queue("RESET")
			
		print ('Selected Wallet State: ',Wallet.state_controller.get_selected_id()) # for debug purposes
		print (q)
	if Wallet.state == Wallet.COLLECTIBLES:
		print("Asset UI Visible: ", Wallet.Asset_UI.is_visible_in_tree()) # For Debug Purposes only
		if Wallet.Asset_UI.is_visible_in_tree() == true:
			Wallet.hideUI()
			Wallet.collectibles_UI.show()
			
			pass
		if Wallet.Asset_UI.is_visible_in_tree() == false:
			Wallet.hideUI()
			Wallet.Asset_UI.show()
			pass


		# Stops Overflow with thos array
		if q.size() >= Wallet.state_controller.get_item_count():
			q.clear()



func _on_Backwards_pressed(): #Connect these signals automatically? #Produce the buttons programmatically
	prev_panel()


func _on_Forward_pressed():
	next_panel()


func next_chap(): # Unused Code
	print ('next chapter') 
	load_chapter(current_chapter + 1)

func prev_chap():
	print ('prev chapter') 
	load_chapter(current_chapter - 1)


"""
	   DRAG AND DROP logic
"""
#it requires you set mouse filter to ignore on all control nodes 
#so the area 2d can get mouse input data


func restaVectores(v1, v2): #vector substraction
	if loaded_comics == true:
		return Vector2(v1.x - v2.x, v1.y - v2.y)

func sumaVectores(v1, v2): #vector sum
	if loaded_comics == true:
		return Vector2(v1.x + v2.x, v1.y + v2.y)


"""
		  SWIPE DETECTION
"""

func _handle_swipe_detection(event)-> void:
	"Handles Swipe Detection" #buggy
	if event.pressed:
		_start_detection(event.position)
	elif not _e.is_stopped():
		_end_detection(event.position)

" Swipe Direction Detection"
#Buggy swipe direction
# Use an Array to store the first position and all end positions
# Difference between both extremes is the swipe position
func clear_memory()-> void:
	swipe_target_memory_x.clear()
	swipe_target_memory_y.clear()



func _start_detection(_position): #for swipe detection
	if enabled == true:
		

		
		#swipe_start_position = _position
		if not swipe_target_memory_x.has(_position.x): 
			swipe_target_memory_x.append(_position.x)
		if not swipe_target_memory_y.has(_position.y):
			swipe_target_memory_y.append(_position.y)
		
		
		_e.start()
		print ('start swipe detection :') #for debug purposes delete later


"Only Two Swipe Directions Are Currently Implemented"
func _end_detection(__position):
#_e.stop()
	direction = (__position - swipe_start_position).normalized()
	"Left and Right "
		
	if round(direction.x) == -1: # Doesnt work
		print('left swipe 1') #for debug purposes
		#next_panel()
		
		
		
		# Play Animation
		#Wallet._Animation.play("SWIPE_LEFT")
		#return Wallet._Animation.queue("RESET")
		
		
	if round(direction.x) == 1: # works
		print('right swipe 1 - works') #for debug purposes
		
		next_panel() #works
		
	
	"Up and Down"
	
	if -sign(direction.y) < -swipe_parameters: # works
		print('down swipe 1 = wrong calibration error ') #for debug purposes
		
		#Disabled. Calling from Wallet Scene Instead
		# To avoid Looping bug
		prev_panel()
		
		

		
	if -sign(direction.y)  > swipe_parameters: # Doesnt work
		print('up swipe 1') #for debug purposes
		#prev_panel()
		
		
		# Play Animation
		return Wallet._Animation.play("SWIPE_UP")
	
	
	# Saves swipe direction details to memory
	# It'll improve start position - end position calculation
	if not swipe_target_memory_x.has(__position.x) && __position.x != null: 
		swipe_target_memory_x.append(__position.x)
	if not swipe_target_memory_y.has(__position.y) && __position.y != null:
		swipe_target_memory_y.append(__position.y)
	_e.stop()
	
	#Works
	if swipe_target_memory_x.size() && swipe_target_memory_y.size() >= 3 && swipe_target_memory_x.pop_back() != null:
		x1 = swipe_target_memory_x.pop_front()
		x2  = swipe_target_memory_x.pop_back()
		
		y1 = swipe_target_memory_y.pop_front()
		y2  = swipe_target_memory_y.pop_back()
		
		#print ("Swipe Detection Debug: ",x1,"/",x2,"/",y1,"/",y2,"/", swipe_target_memory_x.size()) #For Debug purposes only 
		
		#separate x & y position calculations for x and y swipes
		#
		"Horizontal Swipe"
		if x1 && x2  != null && swipe_target_memory_x.size() > 2:
			
			#calculate averages got x and y
			
			var x_average: int = Globals.calc_average(swipe_target_memory_x)
			
			print ("X average: ",x_average)
			print (x1, "/",x2)
			direction.x  = (x1-x2)/x_average
			
			print ("direction x: ",direction.x)
			
			print ('end detection: ','direction: ',direction ,'position',__position, "max diag slope", MAX_DIAGONAL_SLOPE) #for debug purposes only
			#print ("X: ",swipe_target_memory_x)#*********For Debug purposes only
			#print ("Y: ",swipe_target_memory_x)#*********For Debug purposes only
		
		"Vertical Swipe"
		if y1 && y2 != null && swipe_target_memory_y.size() > 2:
			var y_average: int = Globals.calc_average(swipe_target_memory_y)
			
			#print ("Y average: ",y_average) #*********For Debug purposes only
			#print (y1, "/",y2) #*********For Debug purposes only
			#direction.y  = (y1-y2)/y_average #*********For Debug purposes only
			
			#print ("direction y: ",direction.y) #*********For Debug purposes only
			
			#print ('end detection: ','direction: ',direction ,'position',__position, "max diag slope", MAX_DIAGONAL_SLOPE) #for debug purposes only
			#print ("X: ",swipe_target_memory_x)#*********For Debug purposes only
			#print ("Y: ",swipe_target_memory_x)#*********For Debug purposes only
		



		if abs (direction.x) + abs(direction.y) >= MAX_DIAGONAL_SLOPE:
			return
		if abs (direction.x) > abs(direction.y):
			emit_signal('swiped',Vector2(-sign(direction.x), 0.0))
			
			#print (1111)
			print ('Direction on X: ', direction.x, "/", direction.y) #horizontal swipe debug purposs
		if -sign(direction.x) < swipe_parameters:
			print('left swipe') #for debug purposes
			next_panel() 
			
			
			# Play Animation
			return Wallet._Animation.play("SWIPE_LEFT")
		
		if -sign(direction.x) > swipe_parameters:
			print('right swipe') #for debug purposes
			prev_panel()
			
			
			
			# Play Animation
			return Wallet._Animation.play("SWIPE_RIGHT")
		
			
		if abs (direction.y) > abs(direction.x):
			emit_signal('swiped',Vector2(-sign(direction.y), 0.0))
			print ('Direction on Y: ', direction.x) #horizontal swipe debug purposs
			#print (2222)
			
		"Up & Down"
		
		if -sign(direction.y) < -swipe_parameters:
			print('up swipe 2') #for debug purposes
			next_panel() 
			
			# Play Animation
			return Wallet._Animation.play("SWIPE_UP")
		
			
		if -sign(direction.y)  > swipe_parameters:
			print('down swipe 2') #for debug purposes
			prev_panel()
			
			# Play Animation
			return Wallet._Animation.play("SWIPE_DOWN")
			
		emit_signal('swiped', Vector2(0.0,-sign(direction.y))) #vertical swipe
			#	print ('poot poot poot') 
	
	if swipe_target_memory_x.size() && swipe_target_memory_y.size() > 50:
		clear_memory()

	else: return

func _on_Timer_timeout():
	if self.visible : # Only Swipe Detect once visible
		emit_signal('swiped_canceled', swipe_start_position)
		print ('on timer timeout: ',swipe_start_position) #for debug purposes delete later




# It uses a camera 2d to simulate guided view. Should not be used when running the game
func guided_view()-> void: #Unwriten code
	#It's supposed tobe a controlled zoom
	pass


func _on_Rotate_pressed():#Page Rotation #Rewrite this function as a module
	if loaded_comics == true:
		var _r = Kinematic_2d.get_rotation_degrees()
		var _s = self.get_scale()
	#print(_r, _s) #for debug purposes only
		if _r <= 0:
			self.set_scale(Vector2(0.9,0.9))
			Kinematic_2d.set_rotation_degrees(90)
			comics_placeholder.set_position ( center) 
		if _r >= 90:
			self.set_scale(Vector2(1,1))
			Kinematic_2d.set_rotation_degrees(0)
			comics_placeholder.set_position ( center)




static func load_local_image_texture_from_global(node : TextureRect, _local_image_path: String)-> void:
	#print ("NFT debug: ", NFT) #for debug purposes only
	var texture = ImageTexture.new()
	var image = Image.new()
	image.load(_local_image_path)
	texture.create_from_image(image)
	node.show()
	node.set_texture(texture) #cannot load directly from local storage without permissions
		#print (NFT.texture) for debug purposes only
	node.set_expand(true)


"""
button connections 
"""

func _on_chap_1_pressed(): #Simplify this function
	load_chapter(1)

func _on_chap_2_pressed(): #Simplify this function
	load_chapter(2)

func _on_chap_3_pressed(): #Simplify this function
	load_chapter(3)


func _on_Zoom_pressed(): #temporary zoom funtion for android #connect code  with code
	_zoom(comics_placeholder)

"""
load chapter function 
"""

func load_chapter(number):#generic load chapter function
	if number is int:
		print ('loading Chapter :', number)
		current_comics = load(comics[number])
		current_chapter = number #Update the current chapter loaded
		load_comics()



func _on_chap_4_pressed():
	load_chapter(4)


func _on_chap_5_pressed():
	load_chapter(5)


func _on_chap_6_pressed():
	load_chapter(6)


func _on_chap_7_pressed():
	load_chapter(7)
