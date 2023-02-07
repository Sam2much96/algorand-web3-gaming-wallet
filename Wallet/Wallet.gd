# *************************************************
# godot3-Dystopia-game by INhumanity_arts
# Released under MIT License
# *************************************************
# Wallet
# Implements an Algorand Wallet in GDscript
# Parses an image from an NFT url, ising a Networking singleton
# NFT "Non FUungible Token
# To Do:
# (1) Implement Request Page as Asset Optin UI
# (2) Finish implementing Gallery UI + thumbnails
# (7) Test UX
		#- fix check account UX
		#- fix collectibles state (done 2/3) 
#Logic
# It uses the Networking singleton and Algorand library
# to get an asset's url and download the image from
# the asset's meta-data
# asset's url should be read 

#Features
#(1) Curerntly implements on the ALgorand blockchain, other chains not supported
# (2) Uses state machine -a Accounts State & -Collectible state & Other states
# (3) Implements Binary > Utf-8 encryption
# (4) Networking Test for Algorand node health, Good internet connection and local img storage
# (5) Drag and Drop Mechanics using custom comics script
# (6) Swipe Gestures using custom comics script
# (7) Animation Player, To fix State Controller button Positioning When changing states
# *************************************************
#Bugs:

#(1) UI is not intuitive (fixed)
#(2) NFT drag and Drop is buggy 
# (3)  Wallet Node's Process disrupts UI input ( fixed with state_controller and wallet _input() methods)
# (4) Wallet's Animation UI has Stuck animation transition bug. Use Animation Tree to Activate and Deactivate UI animations

# To-DO:
# 
# (10) IMplement Tokenized characters (player_v2)
# (11) Implement cryptographic encryption and decryption
# (12) Implement show mnemonic button and UI
		#alter UI scale for mobiles (done)
		#use animation player to alter UI (depreciated. Functions work faster)

# (15) Implement Comic book interface for interractible NFT (done)
# (16) Implement better NFT UI 
# (17) Delete local NFT's if token is sent
		#logic
		#if asset_url ='' && local_image_texture exists
		#delete local image texture
# (18) Show Asset ID on NFT
		#- Implement Asset UI
# (19) Transfer assets back to Creator Wallet
# (20) Implement Gallery UI for wallet
		#-Collectibles UI logic


# Testing
#(1) Image Downloder (works)
# (2) Create NFT (work with python script)
# (3) Parse NFT (works)
# (4) New UI
# *************************************************


extends Control

class_name wallet


var image_url
var json= File.new()
var account_info: Dictionary = {1:[]}
var save_dict: Dictionary = {}

#*****************************************************



#************** Algo Variables *************************
var Escrow_account: String #="L5ESENBL23J2GJGM64Y767IXWGBCKXMGS2OGZ3MC5BBGWJAKJJAUK7BJK4"  #should ideally be a smart contract
var Escrow_mnemoic: String
#Not needed, can be gotten from mnemonic alone

var Player_account: String  #="2NFCY7HBAFJ5YP7TXUOFHHMGAZ7AHEXPS5F3NENXSC3WXRVATBR4Y23AUM"
var Player_mnemonic: String 

var Player_account_details: Array =[]
var Player_account_temp: Array =[]

#************Wallet variables**************#

var amount : int
var address : String
var mnemonic : String

var recievers_addr : String = '' #for transactions
var _amount : int = 0#for transactions

var _asset_id :int = 0 # used for asset transactions
var smart_contract_addr : String = ""
var _app_id : int = 0
var _app_args : String = ""
var encoded_mnemonic : PoolByteArray
var encrypted_mnemonic 

var _wallet_algos: int
var asset_name : String
var asset_url : String
var asset_index : int
var asset_unit_name : String

#************NFT variables**************#
var _name : String
var _description : String
var _image
#************File Checkers*************#
var FileCheck1=File.new() #checks account info
var FileCheck2=File.new() #checks NFT metadata .json
var FileCheck3=File.new()#checks local image storage
var FileCheck4=File.new() # checks wallet mnemonic


var FileDirectory=Directory.new() #deletes all theon reset



#************Wallet Save Path**********************#
var token_write_path : String = "user://wallet/account_info.token" #creating directory bugs out
var token_dir : String = "user://wallet"

export (String) var local_image_path ="user://wallet/img0.png" #Loads the image file path from a folder to prevent redownloads (depreciated)
var local_image_file : String = "user://wallet/img0.png.png" 


#************Wallet Password & Keys **********************#
#var keys_path : String = "user://wallet/wallet_keys.cfg"
#var keys_passwrd : PoolByteArray = [1234]

"State Machine"

enum {NEW_ACCOUNT,CHECK_ACCOUNT, SHOW_ACCOUNT, IMPORT_ACCOUNT, TRANSACTIONS ,COLLECTIBLES, SMARTCONTRACTS, IDLE, PASSWORD, SHOW_MNEMONIC}
export var state = IDLE

var wallet_check : int = 0
var wallet_check_counter : int = 0
var params
var txn_check : int = 0 #stops transaction spamming
#************Helper Booleans ****************************#
var algod_node_exists: bool 
var algod_node_health_is_good: bool
var imported_mnemonic : bool = false
var transaction_valid: bool =false
var asset_id_valid : bool = false
var asset_optin : bool = false
var asset_txn : bool = false


var Asset_UI_showing : bool = false


var password_valid : bool = false
var loaded_wallet: bool= false #fixes looping loading bug
var good_internet : bool #debugs user's internet

var passed_all_connectivity_checks : bool = false #debugs all connectivity checks
var is_image_available_at_local_storage : bool  = FileCheck4.file_exists(local_image_path)
#*************Signals************************************#
signal completed #placehoder signal
signal transaction

#**********************************#
#onready var timer = $Timer #depreciated
onready var q = HTTPRequest.new()
onready var q2 = HTTPRequest.new()



var Algorand : Algodot
var state_controller : OptionButton
var dashboard_UI : Control
var passward_UI : Control
var Asset_UI : Control
var account_address : Label
var smart_contract_UI : Control
var wallet_algos : Label
var ingame_algos : Label
var password_Entered_Button : Button
var transaction_ui : Control
var mnemonic_ui : Control
var funding_success_ui : Control
var mnemonic_ui_lineEdit : LineEdit
var smartcontract_ui_address_lineEdit : LineEdit
var smartcontract_ui_appID_lineEdit : LineEdit
var smartcontract_ui_args_lineEdit : LineEdit
var smartcontract_UI_button : Button 
var collectibles_UI : Control
var txn_txn_valid_button : Button
var funding_success_close_button : Button
var imported_mnemonic_button : Button
var fund_Acct_Button : Button
var make_Payment_Button : Button
var UI_Elements : Array
var passward_UI_Buttons : Array
var canvas_layer : CanvasLayer
var _Create_Acct_button : Button
var CreatAccountSuccessful_UI : Control
var CreatAccountSuccessful_Mnemonic_Label : Label

var asset_txn_valid_button : Button
var asset_optin_txn_valid_button : Button
var asset_optin_txn_reject_button : Button
var CreatAccountSuccessful_Copy_Mnemonic_button : Button
var CreatAccountSuccessful_Proceed_home_button : Button

var txn_addr : LineEdit
var txn_amount : LineEdit
var nft_asset_id : LineEdit

#*****Collectible UI*******#
var NFT : TextureRect
var pfp : TextureRect
var kinematic2d : KinematicBody2D  # for NFT dragNdrop
var NFT_index_label : Label #Displays Asset Index
var Asset_UI_index : Label
var Asset_UI_amount : Label

#*****PasswordUI******#
var password_LineEdit : LineEdit
var _1 : Button
var _2 : Button
var _3 : Button
var _4 : Button
var _5 : Button
var _6 : Button
var _7 : Button
var _8 : Button
var _9 : Button
var _0 : Button
var zero : Button
var delete_last_button : Button 


# Processor Boolean
var processing : bool


#*****Animation Player******#
var _Animation : AnimationPlayer 
var _Animation_UI : AnimationPlayer
var _Animation_Tree : AnimationTree


# Placeholder Dictionary for creating New Accts
var dict : Dictionary = {'address': address, 'amount': 0, 'mnemonic': mnemonic }

"Checks the Nodes connection Between Singleton & UI"
func check_Nodes() -> bool:
	 
	
	#*****************Wallet UI ************************************
	
	UI_Elements = [
		state_controller, Algorand, dashboard_UI, wallet_algos, ingame_algos, mnemonic_ui,
		mnemonic_ui_lineEdit, txn_txn_valid_button, imported_mnemonic_button, passward_UI, 
		txn_addr, txn_amount, funding_success_ui, funding_success_close_button, smart_contract_UI, 
		smartcontract_ui_address_lineEdit, smartcontract_ui_appID_lineEdit, smartcontract_ui_args_lineEdit,
		smartcontract_UI_button, nft_asset_id, fund_Acct_Button, make_Payment_Button, password_Entered_Button,
		password_LineEdit, collectibles_UI, NFT, kinematic2d, NFT_index_label, _Animation, _Animation_UI, _Animation_Tree ,_Create_Acct_button,
		CreatAccountSuccessful_UI, CreatAccountSuccessful_Mnemonic_Label, CreatAccountSuccessful_Copy_Mnemonic_button,
		CreatAccountSuccessful_Proceed_home_button, Asset_UI, asset_txn_valid_button, asset_optin_txn_valid_button,
		asset_optin_txn_reject_button, pfp, Asset_UI_index, Asset_UI_amount 
	]
	
	passward_UI_Buttons = [_1,_2, _3, _4, _5, _6, _7, _8, _9, _0, zero,delete_last_button]
	
	var p : bool
	#checks if any UI element is null
	#works
	for i in UI_Elements:
		if i != null:
			p = i.is_inside_tree() 
		else: p = false
	return p
func __ready():
		#*****Txn UI options************#
	if bool(check_Nodes()) == true:
	
		#check if methods exist
		if (self.state_controller.get_item_count() == 0):
			
			#**********State Controller Options***********#
			
			self.state_controller.add_item("Show Account")
			self.state_controller.add_item("Check Account")
			#self.state_controller.add_item("New Account") # remove from state controller control. Has been mapped to UI button
			self.state_controller.add_item("Import Account")
			self.state_controller.add_item("Transactions")
			self.state_controller.add_item("SmartContacts") #should be a sub of Transactions
			self.state_controller.add_item('Collectibles')
			self.state_controller.add_item('Login')
			self.state_controller.add_item('Show Mnemonic')
		print ("HTTP REQUEST NODE: ",typeof(q))
		
		
		
	" Shows Login UI"
	
	#if user first boots app
	if OS.get_ticks_msec() < 10_000: 
		self.state_controller.select(6) #show password login


	"Mobile UI"
	print ('Screen orientation debug; ',Globals.screenOrientation)
	if Globals.screenOrientation == 1: #SCREEN_VERTICAL is 1
		#anim.play("MOBILE UI")
		
		#upscale_wallet_ui() #depreciated
		pass
	'Connect and Debug Networking signals'
	connect_signals()
	debug_signal_connections()



	print ("NFT debug: ", NFT)

	"General Wallet Checks"
	run_wallet_checks() #should be used sparingly?


	#connect_buttons() depreciated
	'NFT checks'
	
	"NFT Downloads"
	#if asset_url != "":
	#Networking. _connect_to_ipfs_gateway("ipfs://QmXYApu5uDsfQHMx149LWJy3x5XRssUeiPzvqPJyLV2ABx", q2) 
	

		#*******UI***********#

func _ready():
	self.add_child(q) #add networking node to the scene tree
	self.add_child(q2) #add networking node to the scene tree
	
	#works
	#print(Globals.calc_average([1,2,3,4,5,6,7,8,9,10])) # For debug purposes only 
	
	pass

func _process(_delta):
	
	
	# UI state Processing (works-ish)
	# Remove New Account State. It has a new UI mapping
	"Constantly Running Process Introduces a stuck state Bug"
	if self.state_controller.visible :
		if self.state_controller.get_selected() == 0:
			state = SHOW_ACCOUNT #only loads wallet once
			
		elif self.state_controller.get_selected() == 1:
			#wallet_check = 0 # resets the wallet check stopper
			state = CHECK_ACCOUNT
	#	elif self.state_controller.get_selected() == 2:
	#		wallet_check = 0 # resets the wallet check stopper
	#		state = NEW_ACCOUNT
		elif self.state_controller.get_selected() == 2:
			wallet_check = 0 # resets the wallet check stopper
			state = IMPORT_ACCOUNT
		elif self.state_controller.get_selected() == 3:
			wallet_check = 0 # resets the wallet check stopper
			state = TRANSACTIONS
		elif self.state_controller.get_selected() == 4:
			wallet_check = 0 # resets the wallet check stopper
			state = SMARTCONTRACTS
			
			
			
		elif self.state_controller.get_selected() == 5:
			wallet_check = 0 # resets the wallet check stopper
			state = COLLECTIBLES
		elif self.state_controller.get_selected() == 6:
			wallet_check = 0
			state = PASSWORD
		elif self.state_controller.get_selected() == 7:
			wallet_check = 0
			state = SHOW_MNEMONIC
	
	
	"Constantly Running Process Introduces a Text UI Bug"
	
	match state:
		NEW_ACCOUNT: #loads wallet details if account already exists
			
			# Reset UI animation for State controller 
			_Animation_UI.play("RESET_UI")
			
			
			
			# Buggy
			# Bug Details: It bugs up when saving New Account Details Generated 
			# Suggested Solutions: Debug Save Account Parameters for New Accounts
			# Work Around: SHow Mnemonic State

			
			'Generates New Account'
			# if account info directory doesn't exist
			# Error Catcher 1
			if not FileDirectory.dir_exists(token_dir): 
				print ("File directory" + token_dir + " doesn't exist") # for debug purposes only
				
				
				"Creates Wallet Directory if it doesn't exist"
				
				
				create_wallet_directory()
			if not FileCheck1.file_exists(token_write_path):
				save_account_info(dict , 0)
			
			# Error Catcher 3
			if FileCheck1.file_exists(token_write_path):
				'Generate new Account'
				self.Algorand.generate_new_account = true
				Player_account_details=self.Algorand.create_new_account(Player_account_temp)
				
				#wallet_check += 1
				'Gets the Users Wallet Address'
				
				address= Player_account_details[0]
				mnemonic= Player_account_details[1]
					
					#save_new_account_info(Player_account_details)
				'Attempts saving new account info'
					
				var _dict = {'address': address, 'amount': 0, 'mnemonic': mnemonic, 'asset_index': '','asset_name': '','asset_unit_name': '', 'asset_url': '' }
				
				print (_dict)
				
				"saves more account info"
				print (" Save account Info: ",save_account_info(_dict,0))
					
					#dsfsf
				# Exit Process Loop Show Mnemonic
				self.state_controller.select(7)
					
				return self.set_process(false)
				#state = SHOW_ACCOUNT
				#wallet_check += 1
				#if FileDirectory.file_exists(token_dir) :
					#state = SHOW_ACCOUNT
					
					# Exit Process Loop
				#	return self.state_controller.select(0)
				
				# Exit Process Loop to SHow Menm
				#return self.state_controller.select(0)
		CHECK_ACCOUNT:  #Works 
			
			if wallet_check == 0:
				#Make sure an algod node is running or connet to mainnet or testnet
				if self.Algorand.algod == null:
					self.Algorand.create_algod_node('TESTNET')
				var status : bool
				status= yield(self.Algorand.algod.health(), "completed")
				
				print ("Status debug: ", status,' ',wallet_check_counter)
				check_wallet_info() #checks saved wallet variables for error
				
				# Escape Current State to Show Account State
				self.state_controller.select(0) 
				state = SHOW_ACCOUNT
				

		#Loads all wallet details into Memory
		# Entering any other derivative states without 
		# entering show account previously would present new bugs
		SHOW_ACCOUNT: 
			# Reset UI animation for State controller 
			_Animation_UI.play("RESET_UI")
			
			
			"it's always load account details when ready"
			
			if FileCheck1.file_exists(token_write_path)  :
				#use animation player to alter UI
				
				hideUI()
				
				self.dashboard_UI.show()
				
				load_account_info(false)
				
				show_account_info(true)
				
				set_process(false)
					#state = GENERATE_ADDRESS
				
			'Handles if account info is deleted'
			#buggy on Android
			if not FileCheck1.file_exists(token_write_path) :
				#Revert to Import account state
				
				push_error('account info file does not exist, Import Wallet or generate New One')
				self.state_controller.select(2) 
			
			return
		IMPORT_ACCOUNT: #works 
			
			hideUI()
			
			
			# Reset UI animation for State controller 
			_Animation_UI.play("RESET_UI")
			
			self.mnemonic_ui.show()
			self.set_process(false)
			
			if  imported_mnemonic:
				
				'Cannot convert argument error'
				
				mnemonic = self.mnemonic_ui_lineEdit.text

				
				#*******Generates Address************#
				address = generate_address(mnemonic) #works
				
				'savins imported account info'
				
				#FIxes null parameters errors
				account_info = {"address":address, "amount":0, "mnemonic": mnemonic , "created-assets": [{"index": 0, "params":{"clawback":'', "creator":"", "decimals":0, "default-frozen": '', "freeze": '', "manager":"", "name":"Punk_001", "reserve":"", "total":1, "unit-name": 'XYZ', "url":""}}]}
				
				#"saves more account info"
				# Saves acct info & Debugs it to Output
				print ("Saved Acct Info: ",save_account_info(account_info,0)) 
				check_wallet_info()



				#state = SHOW_MNEMONIC

				#return self.set_process(false)
				return self.state_controller.select(7)
		#Saves transactions to be processed in the ready function
		# Saves the Transaction parameters and runs the txn() function
		# as a subprocess of the _ready() function
		#check https://github.com/lucasvanmol/algodot/issues/20 for more clarifications
		TRANSACTIONS: #Debugging
			#hide other ui states
			#use animation player to alter UI
			hideUI()
			self.transaction_ui.show()
			self.transaction_ui.focus_mode = 2

			# Reset UI animation for State controller 
			_Animation_UI.play("RESET_UI")

			
			#transaction_hint.show()
			
			" Swtiches Between Assets and Normal Transactions UI"
				
			if transaction_valid : #user selected normal transactions
					
					#saves transaction details
					#make them into a global variable so changing scenes doesn't reset it
				recievers_addr = self.txn_addr.text
				_amount = int(self.txn_amount.text)
					
					# cannot process any txn less than 10_000 microAlgos
				if _amount  < 100_000:
						
						#should ideally be sent to the UI
					# Use OS alert
					OS.alert("Cannot send balance less than 100_000 MicroAlgos","Alert")
					push_error('Cannot send balance less than 100_000 MicroAlgos')
					
					
					'Error Catcher 1'
						# return to show account
					self.state_controller.select(0)
				if _amount > 100_000 && txn_check == 0:
						
						
						
						#Saves the transaction files to be done
						
						#goes to the title screen to reset ready function
						#state = SHOW_ACCOUNT 
					self.state_controller.select(0) 

						#calls the transaction function which is a child of _ready()
					__ready()
						
					txn_check += 1
					return txn_check
				#uses two different buttons for assets and algo transactions
				
				# Remap asset_id_valid to Asset UI
				# Asset Optin Txn
				
				#Parameters : 
				# Asset optin Txn take 0 Amount as a Parameter with asset ID
				# The wallet address is same as users address & UI linedit is empty
				if asset_optin:
					
					hideUI()
					self.Asset_UI.show()
					self.asset_UI_amountLabel. text = amount
					self.asset_UI_ID_Label.text = asset_index
				
					recievers_addr = address
				
					asset_id_valid = true
				# Sends Asset Transactions
				
				#Parameters : 
				# Asset Transaction take 1 or more as an amount parameter
				# THe wallet address is different from the users address
				if asset_txn && _amount >= 1: # user selected asset transaction
					#eee
					_asset_id = int(self.nft_asset_id.text)
					recievers_addr = self.txn_addr.text
					
					
					asset_id_valid = true
					
					#Asset_UI.show()
					
					#change wallet state
					#state = SHOW_ACCOUNT 
					
					#self.state_controller.select(0) 

				if asset_id_valid:
					#calls the transaction function which is a subprocess of _ready() function
					__ready()
					
					
			pass
			
	
		COLLECTIBLES:
			# Reset UI animation for State controller 
			_Animation_UI.play("RESET_UI")
			
			"Checks if the Image is avalable Locally and either downloads or loads it"
			if wallet_check == 0:
				hideUI() 
				collectibles_UI.show()
				if not FileCheck3.file_exists(local_image_file): #works
					
					
					#print('NFT image is not available locally, Downloading now') 
					
					#************NFT Logic***********#
					if wallet_check == 0 && asset_url == '':
						#Make sure an algod node is running or connet to mainnet or testnet
						if self.Algorand.algod == null:
							self.Algorand.create_algod_node('TESTNET')
							#var status
						var status : bool
						status= yield(self.Algorand.algod.health(), "completed")
						
						print ("Status debug: ", status,' ',wallet_check_counter)
						
						#duplicates check wallet state function
						check_wallet_info()#saves account info with assets details
						

						# show account
						#self.state_controller.select(0) #Temporarily Disabling
					if asset_url && asset_name != '':
						
						'theres a problem with the network connection'
						'my server isnt serving the json file to godot properly'
						"using python instead"
						
						#image url should be gotten from asset-id
						# some hosted assets might be meta data, 
						#thats why image url is different fromasset-url
						
						#print ("asset url: ", asset_url) #for debug purposes only
						
						image_url=asset_url 
						
						print ('nft host site',image_url) #image_url should not be null
						Networking.url=image_url #disabling for now
						
						#makes a https request to download image from local server
						Networking.start_check(5)
						if not Networking.Timeout && wallet_check == 0 :
							wallet_check += 1
							
							# selet a random IPFS web 2.0 Gateway
							#Networking.genrate_random_gateway()
							
							# implement vaid gateways ass array link
							Networking. _connect_to_ipfs_gateway(Networking.url, Networking.gateway[0], q2)  
							#run this download in the __ready function
							__ready()
							return wallet_check
						#<asfa<sfa
						
							
					#***************************************************************
				if FileCheck3.file_exists(local_image_file) or is_image_available_at_local_storage:
					wallet_check += 1
					
					#connect to wallet NFT logic
					
					#NFT PFP
					NFT_index_label.text = "ID: "+ str(asset_index) + "/" + str(asset_name)
					Asset_UI_index.text = str(asset_index)
					Asset_UI_amount.text = "100,000"
					
					Comics.load_local_image_texture_from_global(self.pfp, local_image_file, true, 7)
					
					# Disabling Collectibes UI thumbnails
					return Comics.load_local_image_texture_from_global(self.NFT, local_image_file, true,1)
					
				"NFT PFP"
				#if is_image_available_at_local_storage:
					# set image texture
				
					
				#if Asset_UI.is_visible_in_tree():
					# Set Asset ID variables
				
				#pass
					
				#if Comics_v5.is_swiping == true:
				#	collectibles_UI.hide()
				#	Asset_UI.show()
				#else: return
		#opts into smart contracts with wallet
		SMARTCONTRACTS: # doesnt work 
			#hide other ui states
			#use animation player to alter UI
			#opt into counter smart contract deployed to host address
			#try running in ready function
			hideUI()
			smart_contract_UI.show()
			
			#Play Animation
			if state_controller.get_selected_id() == 4 :# && wallet_check == 0:
				#_Animation_UI.play("SWIPE_UP_UI")
				_Animation_UI.play("REST_UP")
				#wallet_check += 1
				
			
				
			
			#return _Animation_UI.queue("REST_UP")
			#get parameters from smart contract UI

			if transaction_valid: 
				smart_contract_addr = smartcontract_ui_address_lineEdit.text 
				_app_id = int(smartcontract_ui_appID_lineEdit.text)
				_app_args = smartcontract_ui_args_lineEdit.text
				
				#runs a smart contract deferred function in the ready function
				__ready()
				
				
				self.state_controller.select(0) #check account state 1,  show account state 0
			pass
		
		IDLE:
			set_process(false)
			pass
		PASSWORD:
			#Shows Password UI once app is booted first
			
						# Reset UI animation for State controller 
			_Animation_UI.play("PASSWORD")
			
			
			hideUI()
			
			passward_UI.show()
			
			self.set_process(false)
			
			if password_valid: 
			
			# Revert to dashboard state
				self.state_controller.select(0)
			pass
		SHOW_MNEMONIC:
			if mnemonic != "":
				hideUI()
				
			# Rest Up UI animation for State controller 
				_Animation_UI.play("SHOW_MNEMONIC")
				
				# Show CreatAccountSuccessful UI
				CreatAccountSuccessful_UI.show()
				
				# Display Mnemonic in UI label
				CreatAccountSuccessful_Mnemonic_Label.text = "Mnemmonic : "+ mnemonic
				self.set_process(false)
			elif mnemonic == "":
				# Revert to Import Mnemonic state
				self.state_controller.select(2) 
				return OS.alert("Mnemonic invalid", "Error")


func check_internet():
	if !good_internet:
		Networking._check_if_device_is_online(q)

# Uses Connection Health and internet health to check Account info

func run_wallet_checks()-> bool: # works 
	#Make sure an algod node is running or connet to mainnet or testnet
	# should be run in process method to avoid looping bug
	if self.Algorand.algod == null:
		self.Algorand.create_algod_node('TESTNET')
	
	check_internet()
	
	wallet_check_counter+= 1
	#var status
	var status : bool
	status= yield(self.Algorand.algod.health(), "completed")
	
	print ("Status debug:" , status, wallet_check_counter,  "good internet:", good_internet)
	
	#calculates suggested parameters for all transactions
	params = yield(self.Algorand.algod.suggested_transaction_params(), "completed") #works
	
	
	if status:
		print ("Node Health is Ok")
	if good_internet:
		print ('Internet connection is Ok')
	if params != null:
		print ('Suggested Transaction Parameters calculated')
	
	
	
	if status and good_internet: #prevents app breaking bug
		passed_all_connectivity_checks = true
		pass

	"Checks if image file is available"
	#should delete is assert url is empty string
	if local_image_path != '':
		#"Checks if image file is available"
		is_image_available_at_local_storage = FileCheck4.file_exists(local_image_file)
		print ("Is local image available: ", is_image_available_at_local_storage) #for debug purposes only
		 #= _r
	#return is_image_available_at_local_storage
	'Fixes account token 0 bytes bug'
	if FileDirectory.file_exists(token_write_path ):
		FileCheck1.open(token_write_path ,File.READ)
		if FileCheck1.get_len() == 0: #prevents a  0 bytes error
			FileCheck1.close()
			FileDirectory.remove(token_write_path ) #use Globals delete function instead


	print ("----wallet check done------")
	
	#***********Transaction and Smart Contract functions**************#
	call_deferred('txn')
	
	call_deferred('smart_contract')
	return 0;



#loads from saved account info 
func show_account_info(load_from_local_wallet: bool): 
	"load from local wallet"
	if load_from_local_wallet == true && loaded_wallet == false: 
		self.account_address.text = str(address)
		self.ingame_algos.text = str (Globals.algos)
		self.wallet_algos.text = "Algo: "+ str(_wallet_algos)
		loaded_wallet = true
		return 
	
	"load from Algorand Node"
	if load_from_local_wallet== false:
		print ('loading account info from Algorand Blockchain')
		#should load Account info from outside scene
		account_info=(yield(self.Algorand._check_account_information(Player_account, Player_mnemonic, ""), "completed"))
		self.account_address.text   = account_info['address']
		self.ingame_algos.text = str(Globals.algos)
		self.wallet_algos.text = account_info['amount']



func connect_signals(): #connects all required signals in the parent node
	print ("Connect Networking Signls please")
	#checks internet connectivity
	if not q.is_connected("request_completed", self, "_http_request_completed"):
		return q.connect("request_completed", self, "_http_request_completed")

	#checks Image downloader
	if not q2.is_connected("request_completed", self, "_http_request_completed_2"):
		return q2.connect("request_completed", self, "_http_request_completed_2")


	# Connect Comics swipe signals
	#if not Comics_v5.is_connected("previous_panel", self, "prev_UI"):
	#	Comics_v5.connect("previous_panel", self, "prev_UI")

	#if not Comics_v5.is_connected("next_panel", self, "next_UI"):
	#	Comics_v5.connect("next_panel", self, "next_UI")


func debug_signal_connections()->void:
	#debuggers
	print("Networking Connected: ",q.is_connected("request_completed", self, "_http_request_completed"))
	print ("please connect Networking Signals")

func generate_address(_mnemonic:String)-> String: #works
	var _address =self.Algorand.algod.get_address(_mnemonic)
	print ('address; ', _address)
	return _address
	



#saves account information to a dictionary
#i don't know what number does ngl. It jusst works, lol
func save_account_info( info : Dictionary, number: int)-> bool: 
	if not check_local_wallet_directory():
		push_error('Wallet Directry Not Yet Created.')
		create_wallet_directory()
	
	if FileDirectory.open(token_dir) == OK && check_local_wallet_directory() :
		FileCheck1.open(token_write_path, File.WRITE)
		#************Use Assets parameter ,Disabling for now*******************************#
		save_dict.address =info["address"] # stops presaved info from deletion
		save_dict.amount =info["amount"]
			
		# encode mnemonic
		save_dict.mnemonic = convert_string_to_binary(mnemonic)  #saves mnemonic as string error
		
		# saves if address has assets
		# doesnt account for multiple assets, only saves the first Asset
		if info.has("assets") :
			save_dict.asset_index =  info['assets'][number].get('asset-id')  #info["created-assets"][number]["index"] 
			save_dict.asset_amount = info['assets'][number].get('amount')
			
			# saves if address has created assets
		if info.has("created-assets"):
			save_dict.asset_name = info["created-assets"][number]["params"]["name"] 
			save_dict.asset_unit_name = info["created-assets"][number]["params"]['unit-name']
			save_dict.asset_url = info["created-assets"][number]['params']['url'] #asset Uro and asset uri are different. Separate them
			
		else: pass
		
		
		FileCheck1.store_line(to_json(save_dict))
		FileCheck1.close()
		
		print ("saved account info 1")
		return true
	
			#print ("saved account info")
			#return true
	if not FileDirectory.open(token_dir) == OK: 
		push_error("Error: " + str(FileDirectory.open(token_dir)))
		return false
	return false



func load_account_info(check_only=false):
	if !loaded_wallet:
		if not FileCheck2.file_exists(token_write_path):
			return false
		
		FileCheck2.open(token_write_path, File.READ)
		
		var save_dict = parse_json(FileCheck2.get_line())
		if typeof(save_dict) != TYPE_DICTIONARY:
			return false
		if not check_only:
			_restore_wallet_data(save_dict)
	

"Loads Wallet Variables into Scene Tree Memory"
func _restore_wallet_data(info: Dictionary):
	# JSON numbers are always parsed as floats. In this case we need to turn them into ints
	address = str(info.address)
	
	Globals.address = info.address
	
	"decode mnemonic"
	
	mnemonic = convert_binary_to_string(info.mnemonic)
	_wallet_algos = info.amount 
	
	#***********Assets Information*****************#
	
	#asset_name=info.asset_name
	#asset_index=info.asset_index
	#asset_url=info.asset_url
	
	if info.has('asset_index'):
		#asset_amount = int (info.asset_amount)
		asset_index = info.asset_index
	if info.has('asset_name'):
		asset_name = str (info.asset_name) 
		asset_url = str(info.asset_url) #asset url and asset meta data are different
		asset_unit_name = str(info.asset_unit_name)
	
	print ('wallet data restored from local database')
	
	print ("mnemonic load debug: ",mnemonic) #for debug purposes only
	print ("asset url debug: ",asset_url) # for debug purposes only



'Performs a Bunch of HTTP requests'
#(1) To Check if internet connection is good (works)
# (2) To download Images from IPFS (buggy)
func _http_request_completed(result, response_code, headers, body): #works with https connection
	print (" request done 1: ", result) #********for debug purposes only
	print (" headers 1: ", headers)#*************for debug purposes only
	print (" response code 1: ", response_code) #for debug purposes only
	
	if not body.empty():
		good_internet = true
	
	
	if body.empty(): #returns an empty body
		push_error("Result Unsuccessful")
		good_internet = false
		#Networking.stop_check()
	

			
	else: return


func _http_request_completed_2(result, response_code, headers, body): 
	print (" response code 2: ", response_code) #for debug purposes only
	if !body.empty() && !is_image_available_at_local_storage:
	
	#if not is_image_available_at_local_storage: 
		"Should Parse the NFT's meta-data to get the image ink"
		print ('request successful')
			
		"Downloads the NFT image"
		print (" request successful", typeof(body))
			
		
		#check if body is image type
		set_image_(Networking.download_image_(body, local_image_path,q2)) #works
	if body.empty():
		push_error("Problem downloading Image ")


func set_image_(texture):
	if FileCheck3.file_exists(local_image_path):#use file check
		#dowmload image
		self.NFT.set_texture(texture)
		"update Local image"
		print("Image Tex: ",NFT.texture)
		print("Image Format: ",NFT.texture.get_format() )
		print ("Is stored locally: ",is_image_available_at_local_storage)



func check_wallet_info(): #works. Pass a variable check
	#check if wallet token exits
	# check if Internet is OK
	#THen checks wallet account information
	
	if address != null && mnemonic != null && check_local_wallet_directory() && good_internet : 
		#print (Algorand.algod)
		account_info = yield(self.Algorand.algod.account_information(address), "completed")
		save_account_info(account_info, 0) #testing  
		print ("acct info: ",account_info) #for debug purposes only 
	if address == null:
		print ("check info Address debug: ",address)
		push_error('Either address  cannot be null')
	if mnemonic == null:
		push_error("mnemonic cannot be null Import Mnemonic or Generate New Account")
		print ("check info Mnemonic debug: ", mnemonic)
	
	if !good_internet:
		push_error(" Internet Connection Is Bad")
		check_internet()
	
	
	
	emit_signal('completed')
	#increases a wallet check timer
	wallet_check += 1
	return wallet_check


func _on_reset():
	#should deleta all account details
	print ('----Resetting')
	var a=token_write_path 
	var b=local_image_path
	#var c="res://wallet/wallet_keys.cfg"
	#var d="res://wallet/nft_metadata.json"
	var FilesToDelete=[]#stores all files in an array
	FilesToDelete.append(a,b)
	for _i in FilesToDelete: #looped delete
		var error=FileDirectory.remove(_i)
		if error==OK:
			print ('Deleting Wallet Details')
	return __ready()


func check_local_wallet_directory()-> bool:
	return FileDirectory. dir_exists("user://wallet")

func create_wallet_directory()-> void:
# Creates a Wallet folder.
	print (" Creating Wallet Directory")
	if not FileDirectory. dir_exists(token_dir):
		FileDirectory.make_dir(token_dir)
	else: return 


'Encryption and Decryption ALgorithms'
# cryptographically encrypt users mnemonic
func convert_string_to_binary(string : String)-> Array:
	var binary : Array = []
	for i in string:
		binary.append(ord(i))
	#print( 'Encoded Mnemonic: ',binary) #for debug purposes only
	return binary


func convert_binary_to_string(binary : PoolByteArray)-> String:
	var string : String
	string =binary.get_string_from_utf8()
	#print (string)# for debug purposes only
	return string


func _on_Main_menu_pressed():
	return Globals._go_to_title()


func _on_testnetdispenser_pressed(): #connect to UI
	_on_Copy_address_pressed() #copy address to clipboard
	return OS.shell_open('https://testnet.algoexplorer.io/dispenser')


#Updates Local Account Info
func _on_refresh_pressed(): #disabling refresh button

	#check_account()
	if passed_all_connectivity_checks:
		check_wallet_info()
	
	pass
	


#Deletes Local Account Info
func reset()-> void:
	Globals.delete_local_file(token_write_path)


'Copies Wallet Addresss to Clipboard'
func _on_Copy_address_pressed():
	print ("copied wallet address to clipboard")
	OS.set_clipboard(address) 



'Copies Wallet Addresss to Clipboard'
func _on_Copy_mnemonic_pressed():
	print ("copied wallet mnemonic to clipboard")
	OS.set_clipboard(mnemonic) 




"Parses Input frm UI buttons"
func _input(event):
	
	
	"Collectibles multitouch"
	# (1) Rewrite Zoom to take parameters like drag()
	# (2) Map Pinch , Twist and Tap iput actions in Comics script
	# (3) Upgrade Comics v 5.1 to implement proper gestures and global Swipe Dir indicator
	# (4) Depreciate Wallet Animation for Comics Animation Structure

	
	"Swipe Direction Debug"
	# Should Ideally be in COmics script. Requires rewrite for better structure
	# The current implementation is a fast hack
	if event is InputEventScreenDrag : #kinda works, for NFT Drag & Drop
		#Networking.start_check(4) #should take a timer as a parameter
		#if Networking.Timeout == false:
		
		
		Networking.start_check(4)
		
		
		"Swipe Detection"
		
		#Comics_v5.enabled = true
		Comics_v5._start_detection(event.position)
		
		
		# End Detection once Networking check has timedout
		
		#sdfhsdfhsdhsdg
		# Swipe Detection SHould SHow A new Aset UI with NFT PFP
		Comics_v5._end_detection(event.position)
		
		
		"NFT drag and drop"
		#works
		if self.NFT.visible:
			#print ("NFT visible: ",self.NFT.visible)
			
			Comics_v5.can_drag = self.NFT.visible
			
			# Activates Zoom
			Comics_v5.loaded_comics = self.NFT.visible
			Comics_v5.comics_placeholder = self.NFT
			Comics_v5.drag(event.position, event.position, kinematic2d)
		
	# Turns on and Off Wallet Processing with Single screen touches
	# 
	# Uses a Timer of 4 seconds to turn processing off
	
	if event is InputEventSingleScreenTouch:
		Networking.start_check(4) #should take a timer as a parameter
		
		
		#Turns processing off for 20 secs
		if Networking.Timeout == false :
			
			print ('Stoping Wallet Processing')
			self.set_process(false)
			processing = false
			return processing
		
		if Networking.Timeout == true :
			
			print ('Wallet Processing')
			
			self.set_process(true)
			processing = true
			return processing
	
	
	"BUTTON PRESSES"
	
	#fadhdsfhsdhs
	if asset_txn_valid_button.pressed:
		asset_txn = true
	if asset_optin_txn_valid_button.pressed:
		asset_optin = true
	if asset_optin_txn_reject_button.pressed:
		print ("asset optin cancelled")
		return self.state_controller.select(3) # Return to Transaction UI
	if _Create_Acct_button.pressed:
		
		# Fixes Stuck State Bug
		# Check state controller process()
		self.state_controller.select(-1)
		state = NEW_ACCOUNT
		
		
		#self.state_controller.select(2) #Create Account 
		print ("Create Acct button pressed", state)
		return state
	if txn_txn_valid_button.pressed:
		transaction_valid = true #works
		print ("Txn button pressed: ",transaction_valid) #for debug purposes only

	if smartcontract_UI_button.pressed: 
		transaction_valid = true
		print ("SmartContract button pressed: ",transaction_valid) #for debug purposes only
	if password_Entered_Button.pressed:
		password_valid = true
		print ("Password Placeholder entered", password_valid)
		self.set_process(true)


	if CreatAccountSuccessful_Copy_Mnemonic_button.pressed:
		return _on_Copy_mnemonic_pressed()
	if CreatAccountSuccessful_Proceed_home_button.pressed:
		return self.state_controller.select(0) # Show Account
	
	
	
	
	if fund_Acct_Button.pressed:
		_on_testnetdispenser_pressed()
	if make_Payment_Button.pressed:
		self.state_controller.select(3)
	if imported_mnemonic_button.pressed:
		imported_mnemonic = true
	if funding_success_close_button.pressed :
		reset_transaction_parameters()# fixes double spend bug
		state_controller.select(0) #show account dashboard


		#************PassWord UI**********#
	if state == PASSWORD:
		for i in passward_UI_Buttons:
			if i.pressed:
				password_LineEdit.text += i.text
			#else: break

'Processes Algo and Asset Transactions'
func txn(): #runs presaved transactions once wallet is ready
	"MicroAlgo Transactions"
	if recievers_addr != '' && _amount >= 100_000:
		print ('Transaction Debug: ',recievers_addr, '/','amount: ',_amount, '/', 'txn check', txn_check)
		
		yield(self.Algorand._send_txn_to_receiver_addr(params,mnemonic,recievers_addr, _amount), "completed")

		#reset transaction details
		recievers_addr = ''
		_amount = 0
		
		reset_transaction_parameters()
		hideUI()
		self.funding_success_ui.show()
	
	"Asset Transactions"
	# Sends Asset Transactions
	
	#Parameters : 
	# Asset Transaction take 1 or more as an amount parameter
	# THe wallet address is different from the users address
	
	if _asset_id != 0 && asset_id_valid  && _amount > 0:
		
		# Parameters
		if recievers_addr != address:
			print (' Asset Txn Debug: ',recievers_addr, '/','asset id: ',_asset_id, '/', 'txn check', txn_check)
		
			#can be used to send both NFT's and Tokens
			yield(self.Algorand.transferAssets(params,mnemonic, recievers_addr,_asset_id, _amount), "completed")
			
			#reset transaction details
			reset_transaction_parameters()
			hideUI()
			self.funding_success_ui.show()
		
	"Asset Optin Transactions"
	# Asset Optin Txn
	
	#Parameters : 
	# Asset optin Txn take 0 Amount as a Parameter with asset ID
	# The wallet address is same as users address & UI linedit is empty
	
	if _asset_id != 0 && asset_id_valid && _amount == 0:
		
		
		# Parameters
		if recievers_addr == address:
			
			print (' Asset Txn Debug: ',recievers_addr, '/','asset id: ',_asset_id, '/', 'txn check', txn_check)
			
			#can be used to send both NFT's and Tokens
			yield(self.Algorand.transferAssets(params,mnemonic, recievers_addr,_asset_id, _amount), "completed")
			
			#reset transaction details
			reset_transaction_parameters()
			hideUI()
			self.funding_success_ui.show()
	




'Processes Smart Contract NoOp transactions'
func smart_contract(): 
	if transaction_valid && _app_id != 0 && smart_contract_addr != "":
		#check that the address string variable length is valid
		var noOp_txn = self.Algorand.algod.construct_app_call(params, smart_contract_addr, _app_id,_app_args)
	
		print ("NoOp transcation: ",noOp_txn) 
		#print ("opt in transcation: ",noop_txn) #for debug purposes only
	
		# Signs the Raw transaction
		var stx = self.Algorand.algod.sign_transaction(noOp_txn, mnemonic)
		print ("Signed Transaction: ",stx) #shouldn't be null
		var txid = self.Algorand.algod.send_transaction(stx) # sends raw signed transaction to the network
		txid = self.Algorand.algod.send_transaction(stx)
		print ('Tx ID: ',txid)
		
		hideUI()
		self.funding_success_ui.show()
		
		self._Animation_UI.play("SUCCESS")
	
	transaction_valid = false
	_app_id = 0
	smart_contract_addr = ""
	return transaction_valid

func _on_enter_asset_pressed(): #depreciated
	asset_id_valid = true



"UI methods for handling the new Wallet UI"
func hideUI()-> void:
	for i in canvas_layer.get_children():
		i.set_mouse_filter(1)
		i.focus_mode = 0
		i.hide()

func showUI()-> void:
	for i in canvas_layer.get_children():
		i.focus_mode = 1
		i.show()

"Resets All Transaction Boolean & String Parameters"
#fixes double spend bug
func reset_transaction_parameters():
	transaction_valid = false
	asset_id_valid = false
	smart_contract_addr = ''
	recievers_addr = ""
	asset_optin = false
	asset_txn = false
	#smdslfksf

"Collectibles UI Logic"
# drag and Drop (done)
# comics node implemented (done)
# link with collectibles state
# Gallery View
# Multigesture Swipes for Collectibles Zoom in
# Implement Asset ID UI for Transactions
# Implement Asset Optin UX
#sdfksdlfnskdfnglk
#func _NFT():
	# create and hide buttons depending on the amount of Assets counted
	# Set gallery UI testure button to Asset NFT texture downloaded
	
	# load NFT script as child of Collectubles UI texture react
	
	# load, show and hide NFT's on Button clicks
	# Implement Drag and Drop mechanics
#	pass


