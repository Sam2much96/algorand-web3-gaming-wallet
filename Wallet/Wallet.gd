# *************************************************
# godot3-Dystopia-game by INhumanity_arts
# Released under MIT License
# *************************************************
# Wallet
# Implements an Algorand Wallet in GDscript
# Parses an image from an NFT url, ising a Networking singleton
# NFT "Non FUungible Token
# To Do:
#(1) Fix Hacky Spagetti Code
#(2) Implement NFT subcode.
# (3) Unimplement Networking Singleton i.e. script should run it's own networking node
# (4) Users should be able to copy wallet details
# (5) Test transaction state for Tokens and Algos
# (6) Compile Teal FOr SMartContract Testing
# (7) 
#Logic
# It uses the Networking singleton and Algorand library
# to get an asset's url and download the image from
# the asset's meta-data
# asset's url should be read 

#Features
#(1) Curerntly implements on the ALgorand blockchain, other chains not supported
# (2) Uses two states -a Accounts State & -Collectible state
# (3) Implements Binary > Utf-8 encryption
# (4) Networking Test for Algorand node health, Good internet connection and local img storage
# *************************************************
#Bugs:

#(1) UI is not intuitive 
#(2) NFT drag and Drop is buggy

# To-DO:
# (1) Implement as State Machine (done)
# (2) Update transaction logic (done)
# (3) Test Smart Contracts 
		#Test counter smart contract (buggy)
# (4) Implement Proper wallet security (needs encryption and decryption algorithm) (step 1 done)
# (5) Copy and Paste Wallet Address (done)
# (6) Use time timeout to transition btw states (depreciated)
# (7) Import wallet (done)
# (8) Implement IPFS web 2 Gateway as a callale Networking SIngleton function (done)
# 
# (10) IMplement Tokenized characters (player_v2)
# (11) Implement cryptographic encryption and decryption
# (12) Implement show mnemonic button
# (13) Improve UI 
		#alter UI scale for mobiles (done)
		#use animation player to alter UI (depreciated. Functions work faster)
# (14) Implement SHow mnemonic button
# (15) Implement Comic book interface for interractible NFT (done)
# (16) Implement better NFT UI (buggy)
# (17) Delete local NFT's if token is sent
		#logic
		#if asset_url ='' && local_image_texture exists
		#delete local image texture
# (18) Show Asset ID on NFT

# Testing
#(1) Image Downloder (works)
# (2) Create NFT (work with python script)
# (3) Parse NFT (works)
# (4) New UI
# *************************************************


extends Control

#class_name wallet


var image_url
var json= File.new()
var account_info: Dictionary = {1:[]}

onready var Algorand = $Algodot

#*****************Wallet UI ************************************
# Undergoing upgrades

#**********UI************#
onready var dashboard_UI = $CanvasLayer/Dashboard_UI
onready var dashboard_UI_amount_label = $CanvasLayer/Dashboard_UI/YSort/Label



onready var account_address = $wallet_ui/address
onready var ingame_algos = $wallet_ui/ingame_algos
onready var wallet_algos = $wallet_ui/wallet_algos
onready var withdraw_button = $wallet_ui/HBoxContainer/withdraw
onready var refresh_button= $wallet_ui/HBoxContainer/refresh

onready var wallet_ui = $wallet_ui
onready var mnemonic_ui = $CanvasLayer/Mnemonic_UI 
onready var transaction_ui = $CanvasLayer/Transaction_UI
onready var funding_success_ui = $CanvasLayer/FundingSuccess

onready var txn_ui_options = $transaction_ui/txn_ui_options

onready var address_ui_options = $mnemonic_ui/address_ui_options

#updating for the new ui

onready var nft_asset_id = $transaction_ui/nft


onready var txn_amount = $transaction_ui/transaction_amount

onready var txn_addr = $CanvasLayer/Transaction_UI/LineEdit

onready var txn_ui_options_button = $transaction_ui/txn_ui_options
onready var txn_assets_valid_button = $transaction_ui/enter_asset

#Txn valid should use Passward UI
onready var passward_UI = $CanvasLayer/Password_UI

onready var txn_txn_valid_button = $CanvasLayer/Transaction_UI/Button

onready var transaction_hint= $transaction_ui/Label


onready var NFT =  get_tree().get_nodes_in_group('NFT')#$Control/TextureRect
onready var state_controller = $CanvasLayer/state_controller
onready var anim = $AnimationPlayer
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
var _asset_id :int = 0

var encoded_mnemonic : PoolByteArray
var encrypted_mnemonic 

var _wallet_algos: int
var asset_name : String
var asset_url : String
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

#var FileCheck5 = ResourceLoader #checks if the image texture is stored locally (depreciiated)

var FileDirectory=Directory.new() #deletes all theon reset



#************Wallet Save Path**********************#
var token_path : String = "user://wallet/account_info.token"
export (String) var local_image_path ="user://wallet/img0.png" #Loads the image file path from a folder to prevent redownloads (depreciated)
#var keys_path : String = "user://wallet/wallet_keys.cfg"
#var keys_passwrd : PoolByteArray = [1234]

"State Machine"

enum {NEW_ACCOUNT,CHECK_ACCOUNT, SHOW_ACCOUNT, IMPORT_ACCOUNT, TRANSACTIONS ,COLLECTIBLES, SMARTCONTRACTS, IDLE}
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





func _ready():
	
	print ("HTTP REQUEST NODE: ",typeof(q))
	

	
	
	#*****Txn UI options************#
	#check if methods exist
	if (txn_ui_options_button.get_item_count() == 0):
		txn_ui_options.add_item('Transactions') 
		txn_ui_options.add_item('Assets') 
		
		#**********State Controller Options***********#
		#add error checker so its not duplicated
		#if _ready() is called multiple times
		#sssss
		state_controller.add_item("Show Account")
		state_controller.add_item("Check Account")
		state_controller.add_item("New Account")
		state_controller.add_item("Import Account")
		state_controller.add_item("Transactions")
		state_controller.add_item("SmartContacts") #should be a sub of Transactions
		state_controller.add_item('NFT')
	
	
	
	"Mobile UI"
	print ('Screen orientation debug; ',Globals.screenOrientation)
	if Globals.screenOrientation == 1: #SCREEN_VERTICAL is 1
		#anim.play("MOBILE UI")
		
		upscale_wallet_ui()

	'Connect and Debug Networking signals'
	connect_signals()
	debug_signal_connections()

	'NFT checks'
	print ("NFT debug: ", NFT)

	"General Wallet Checks"
	run_wallet_checks() #should be used sparingly?

	#generating smart contract mnemonic
	#generate_address('purity inner pilot suggest cave funny hip joke bean radar cheese moon sad depth book laundry pave lift robust length task fringe they abandon kitten')

		#*******UI***********#
	setUp_UI()


func _process(_delta):
	#makes the state a global variable
	Globals.wallet_state = state
	
	
	# UI state Processing (works-ish)
	if state_controller.get_selected() == 0:
		state = SHOW_ACCOUNT #only loads wallet once
		
	elif state_controller.get_selected() == 1:
		#wallet_check = 0 # resets the wallet check stopper
		state = CHECK_ACCOUNT
	elif state_controller.get_selected() == 2:
		wallet_check = 0 # resets the wallet check stopper
		state = NEW_ACCOUNT
	elif state_controller.get_selected() == 3:
		wallet_check = 0 # resets the wallet check stopper
		state = IMPORT_ACCOUNT
	elif state_controller.get_selected() == 4:
		wallet_check = 0 # resets the wallet check stopper
		state = TRANSACTIONS
	elif state_controller.get_selected() == 5:
		wallet_check = 0 # resets the wallet check stopper
		state = SMARTCONTRACTS
	elif state_controller.get_selected() == 6:
		wallet_check = 0 # resets the wallet check stopper
		state = COLLECTIBLES
	
	
	## PROCESS STATES (testing)
	
	match state:
		NEW_ACCOUNT: #loads wallet details if account already exists
			
			run_wallet_checks()
			if not algod_node_exists:
				#Make sure an algod node is running or connet to mainnet or testnet
				Algorand.create_algod_node('TESTNET')
				Algorand._test_algod_connection()
				algod_node_exists= true
		
			
			'Generates New Account'
			if not FileDirectory.file_exists(token_path) : # if account info doesn't exist
				
				"Creates Wallet Directory if it doesn't exist"
				create_wallet_directory()
				

				'Generate new Account'
				Algorand.generate_new_account = true
				Player_account_details=Algorand.create_new_account(Player_account_temp)
				
				#wallet_check += 1
				'Gets the Users Wallet Address'
				#Player_account =get_wallet_address_from_mnemonic(Player_account_details[1])
				#Escrow_account =get_wallet_address_from_mnemonic(Escrow_account)
				address= Player_account_details[0]
				mnemonic= Player_account_details[1]
				
				#save_new_account_info(Player_account_details)
				'Attempts saving new account info'
				#breaks
				var dict = {'address': address, 'amount': 0, 'mnemonic': mnemonic, 'asset_index': '','asset_name': '','asset_unit_name': '', 'asset_url': '' }
				
				"saves more account info"
				save_account_info(dict,1)
				
				state = SHOW_ACCOUNT
				#wallet_check += 1
			if FileDirectory.file_exists(token_path) :
				state = SHOW_ACCOUNT
				return
	
		#"Try running outside process funtion"
		CHECK_ACCOUNT:  #Works too well. Overprints texts
			#if FileCheck1.file_exists("user://wallet/account_info.token") :
			if wallet_check == 0:
				#Make sure an algod node is running or connet to mainnet or testnet
				if Algorand.algod == null:
					Algorand.create_algod_node('TESTNET')

					
					#var status
				var status : bool
				status= yield(Algorand.algod.health(), "completed")
				
				print ("Status debug: ", status,' ',wallet_check_counter)
				yield(check_wallet_info(),"completed")#ddd
				
				# Escape Current State to Show Account State
				state_controller.select(0) 
				state = SHOW_ACCOUNT
				

		
		SHOW_ACCOUNT: #buggy with state controller
			"it's always load account details when ready"
			if FileCheck1.file_exists("user://wallet/account_info.token")  :
				#use animation player to alter UI
				
				hideUI()
				
				dashboard_UI.show()
				
				#wallet_ui.show()
				#mnemonic_ui.hide()
				#transaction_ui.hide()
				
				load_account_info(false)
				
				show_account_info(true)
				
			
					#state = GENERATE_ADDRESS
				
			'Handles if account info is deleted'
			if not FileCheck1.file_exists("user://wallet/account_info.token"):
				#Revert to Import account state
				
				push_error('account info file does not exist, Import Wallet or generate New One')
				state_controller.select(3) #rewrite as a method
				#state = IMPORT_ACCOUNT  #rewrite as a method
				
				#programmatically delete NFT
			


			return
		IMPORT_ACCOUNT: #works ish. But kinda broken too 
			# hide wallet ui, show mnemonic ui
			#use animation player to alter UI 
			
			
			hideUI()
			
			#transaction_ui.hide()
			#wallet_ui.hide()
			
			mnemonic_ui.show()
			
			#hide mnemonic characters
			#mnemonic_ui.set_secret(true) 
			

			if  imported_mnemonic:
				#address=(Algorand.algod.get_address(mnemonic))
				#var address : String
				
				
				'Cannot convert argument error'
				
				mnemonic = mnemonic_ui.text

				
				#*******Generates Address************#
				address = generate_address(mnemonic) #works
					



				'savins imported account info'
				
				#FIxes null parameters errors
				#account_info = {'address': address, 'amount': 0, 'mnemonic': mnemonic, 'asset_index': 0,'asset_name': '','asset_unit_name': '', 'asset_url': '',  "created-assets": [{}],}
				
				account_info = {"address":address, "amount":0, "mnemonic": mnemonic , "created-assets": [{"index": 0, "params":{"clawback":'', "creator":"", "decimals":0, "default-frozen": '', "freeze": '', "manager":"", "name":"Punk_001", "reserve":"", "total":1, "unit-name": 'XYZ', "url":""}}]}
				
				"saves more account info"
				save_account_info(account_info,0)
				
				
				# check account and saves automatically
				#check_wallet_info() #breaks sometimes
				
				
				
				# show account
				state_controller.select(0)

			pass
		#Saves transactions to be processed in the ready function
		# Saves the Transaction parameters and runs the txn() function
		#as a subprocess of the _ready() function
		#check https://github.com/lucasvanmol/algodot/issues/20 for more clarifications
		TRANSACTIONS: #works
			#hide other ui states
			#use animation player to alter UI
			hideUI()
			transaction_ui.show()
			
			#mnemonic_ui.hide()
			#wallet_ui.hide()
			
			txn_ui_options_button.show()
			transaction_hint.show()
			
			" Swtiches Between Assets and Normal Transactions UI"
			if txn_ui_options.get_selected() == 0:
				txn_amount.show()
				nft_asset_id.hide()
				
				txn_assets_valid_button.hide()

				
				
				if transaction_valid : #user selected normal transactions
					
					#saves transaction details
					#make them into a global variable so changing scenes doesn't reset it
					recievers_addr = txn_addr.text
					_amount = int(txn_amount.text)
					
					# cannot process any txn less than 10_000 microAlgos
					if _amount  < 100_000:
						
						#should ideally be sent to the UI
						push_error('Cannot send balance less tha 100_000 MicroAlgos')
						
						
						'Error Catcher 1'
						# return to show account
						state_controller.select(0)
					if _amount > 100_000 && txn_check == 0:
						
						#txn_check += 1
						
						#should save the transaction files to be done
						
						#goes to the title screen to reset ready function
						#state = SHOW_ACCOUNT 
						state_controller.select(0) 

						#calls the transaction function which is a child of _ready()
						_ready()
						
						txn_check += 1
						return txn_check

			if txn_ui_options.get_selected() == 1:
				#txn_amount.hide()
				#uses two different buttons for assets and algo transactions
				txn_assets_valid_button.show()
				txn_txn_valid_button.hide()
				nft_asset_id.show()
				if asset_id_valid : # user selected asset transaction
					#eee
					_asset_id = int(nft_asset_id.text)
					recievers_addr = txn_addr.text
					
					#change wallet state
					#state = SHOW_ACCOUNT 
					state_controller.select(0) 

					
					#calls the transaction function which is a subprocess of _ready() function
					_ready()
					
			pass
			
	
		COLLECTIBLES: 
			"Checks if the Image is avalable Locally and either downloads or loads it"
			if wallet_check == 0:
				if not FileCheck3.file_exists(local_image_path): #works
					
					
					#print('NFT image is not available locally, Downloading now') 
					
					#************NFT Logic***********#
					if wallet_check == 0 && asset_url == '':
						#Make sure an algod node is running or connet to mainnet or testnet
						if Algorand.algod == null:
							Algorand.create_algod_node('TESTNET')

							
							#var status
						var status : bool
						status= yield(Algorand.algod.health(), "completed")
						
						print ("Status debug: ", status,' ',wallet_check_counter)
						check_wallet_info()#saves account info with assets details
						

						# show account
						state_controller.select(0)
					if asset_url && asset_name != '':

						
						'theres a problem with the network connection'
						'my server isnt serving the json file to godot properly'
						"using python instead"
						
						#image url should be gotten from asset-id
						# some hosted assets might be meta data, 
						#thats why image url is different fromasset-url
						image_url=asset_url 
						
						print ('nft host site',image_url) #image_url should not be null
						Networking.url=image_url #disabling for now
						 
						#makes a https request to download image from local server
						
						Networking. _connect_to_ipfs_gateway(image_url, q)  
						
						
						wallet_check += 1
					#***************************************************************
				if FileCheck3.file_exists(local_image_path) or is_image_available_at_local_storage:
					#print ('adfbsdjfbasdfjsdfs') #works
					#load_local_image_texture()
					wallet_check += 1
					
					#calls NFT from a class #depreciated
					#NFT.load_local_image_texture(local_image_path) #loop error 
					
					
					#calls NFT from comics node
					#NFT is a call to the SceneTree's Texture react
					Comics.load_local_image_texture_from_global(NFT, local_image_path)
					
					#change states
					state_controller.select(0)
				 #duplicate of above for bug catching
					#load_local_image_texture()
				else: return
		#opts into smart contracts with wallet
		SMARTCONTRACTS: # doesnt work 
			#hide other ui states
			#use animation player to alter UI
			#opt into counter smart contract deployed to host address
			#try running in ready function
			transaction_ui.show()
			mnemonic_ui.hide()
			wallet_ui.hide()
			
			transaction_hint.hide()
			txn_amount.hide()
			txn_assets_valid_button.hide()
			nft_asset_id.hide()
			txn_ui_options.hide()
			if transaction_valid: #buggy
				#Would Require Compiling to Teal
				print (" Opt into Smartcontract---Debugging")
				
				#runs a smart contract deferred function in the ready function
				_ready()

					#change state to check success of app call
				state_controller.select(0) #check account state 1,  show account state 0
			pass
		
		IDLE:
			set_process(false)
			pass
		


# Uses Connection Health and internet health to check Account info
#Rewrite to include local NFT images check and all checks
func run_wallet_checks()-> bool: # works #run networking internet checks test before running this function
#if wallet_check == 0:
	#Make sure an algod node is running or connet to mainnet or testnet
	if Algorand.algod == null:
		Algorand.create_algod_node('TESTNET')
	
	if !good_internet:
		Networking._check_if_device_is_online()
	
	wallet_check_counter+= 1
	#var status
	var status : bool
	status= yield(Algorand.algod.health(), "completed")
	
	print ("Status debug:" , status, wallet_check_counter,  "good internet:", good_internet)
	
	#calculates suggested parameters for all transactions
	params = yield(Algorand.algod.suggested_transaction_params(), "completed") #works
	
	
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
		is_image_available_at_local_storage = FileCheck4.file_exists(local_image_path)
		print ("Is local image available: ", is_image_available_at_local_storage) #for debug purposes only
		 #= _r
	#return is_image_available_at_local_storage
	'Fixes account token 0 bytes bug'
	if FileDirectory.file_exists(token_path ):
		FileCheck1.open(token_path ,File.READ)
		if FileCheck1.get_len() == 0: #prevents a  0 bytes error
			FileCheck1.close()
			FileDirectory.remove(token_path ) #use Globals delete function instead


	print ("----wallet check done------")
	
	#***********Transaction and Smart Contract functions**************#
	call_deferred('txn')
	
	call_deferred('smart_contract')
	return 0;

#loads from saved account info 
func show_account_info(load_from_local_wallet: bool): 
	"load from local wallet"
	if load_from_local_wallet == true && loaded_wallet == false: 
		#account_address.text = str(Globals.address)
		#looping bug : fix is bolean
		account_address.text = str(address)
		ingame_algos.text += str (Globals.algos)
		wallet_algos.text += str(_wallet_algos)
		loaded_wallet = true
		return 
	
	"load from Algorand Node"
	if load_from_local_wallet== false:
		print ('loading account info from Algorand Blockchain')
		#should load Account info from outside scene
		account_info=(yield(Algorand._check_account_information(Player_account, Player_mnemonic, ""), "completed"))
		account_address.text   = account_info['address']
		ingame_algos.text = str(Globals.algos)
		wallet_algos.text = account_info['amount']

func connect_signals(): #connects all required signals in the parent node
	print ("Connect Networking Signls please")
	if not q.is_connected("request_completed", self, "_http_request_completed"):
		return q.connect("request_completed", self, "_http_request_completed")

func debug_signal_connections()->void:
	#debuggers
	print("Networking Connected: ",q.is_connected("request_completed", self, "_http_request_completed"))
	print ("please connect Networking Signals")

func generate_address(_mnemonic:String)-> String: #works
	var _address =Algorand.algod.get_address(_mnemonic)
	print ('address; ', _address)
	return _address
	



#saves account information to a dictionary
#i don't know what number does ngl. It jusst works, lol
func save_account_info( info : Dictionary, number: int): 
	var save_game = File.new() #change from save game
	save_game.open(token_path, File.WRITE)
	var save_dict = {}
	
	#************Use Assets parameter ,Disabling for now*******************************#
	
	save_dict.address =info["address"] # stops presaved info from deletion
	save_dict.amount =info["amount"]
		
	# encode mnemonic
	save_dict.mnemonic = convert_string_to_binary(mnemonic)  #saves mnemonic as string error
		
	# Temporarily disabling
	
	save_dict.asset_index =info["created-assets"][number]["index"] 
	save_dict.asset_name = info["created-assets"][number]["params"]["name"] 
	save_dict.asset_unit_name = info["created-assets"][number]["params"]['unit-name']
	save_dict.asset_url = info["created-assets"][number]['params']['url'] #asset Uro and asset uri are different. Separate them
	
	save_game.store_line(to_json(save_dict))
	save_game.close()
	
	print ("saved account info")




func load_account_info(check_only=false):
	if !loaded_wallet:
		var save_game = File.new()
		
		if not save_game.file_exists(token_path):
			return false
		
		save_game.open(token_path, File.READ)
		
		var save_dict = parse_json(save_game.get_line())

		if typeof(save_dict) != TYPE_DICTIONARY:
			return false
		if not check_only:
			_restore_wallet_data(save_dict)
	

func _restore_wallet_data(info: Dictionary):
	# JSON numbers are always parsed as floats. In this case we need to turn them into ints
	address = str(info.address)

	
	Globals.address = info.address
	
	#decode mnemonic
	#fixes string conversion error with regex
	
	
	mnemonic = convert_binary_to_string(info.mnemonic)
	_wallet_algos = info.amount 
	
	#***********Assets Information*****************#
	#might break if wallet has no assets. 
	#Write proper fix for this function and save asset function which duplicates code
	asset_name = str (info.asset_name) 
	asset_url = str(info.asset_url) #asset url and asset meta data are different
	asset_unit_name = str(info.asset_unit_name)
	
	print ('wallet data restored from local database')
	
	print ("mnemonic load debug: ",mnemonic) #for debug purposes only




'Performs a Bunch of HTTP requests'
func _http_request_completed(result, response_code, headers, body): #works with https connection
	print (" request done: ", result) #********for debug purposes only
	print (" headers: ", headers)#*************for debug purposes only
	print (" response code: ", response_code) #for debug purposes only
	
	if not body.empty():
		good_internet = true
	
	
	if body.empty(): #returns an empty body
		push_error("Result Unsuccessful")
		good_internet = false
		#Networking.stop_check()
	
	if not is_image_available_at_local_storage: 
		"Should Parse the NFT's meta-data to get the image ink"
		#if body.empty() != true:
		print ('request successful')
			
		"Downloads the NFT image"
		print (" request successful")
			
			#disabling for now
		set_image_(Networking.download_image_(body, "user://wallet/img0",q)) #works
			
	else: return
	#Networking.cancel_request()

func set_image_(texture):
	if FileCheck3.file_exists(local_image_path):#use file check
		#dowmload image
		NFT.set_texture(texture)
		"update Local image"
		print("Image Tex: ",NFT.texture)
		print("Image Format: ",NFT.texture.get_format() )
		#local_image_path = "user://wallet/img0.png"

		
		print ("Is stored locally: ",is_image_available_at_local_storage)




func check_wallet_info(): #works. Pass a variable check
	#check if wallet token exits
	#THen checks wallet account information
	
	if address != null && mnemonic != null && check_local_wallet_directory():
		account_info = yield(Algorand.algod.account_information(address), "completed")
		save_account_info(account_info, 0) #testing
	else : 
		push_error('Either address or mnemonic cannot be null')
		push_error("Import Mnemonic or Generate New Account")
		print ("check info Address debug: ",address)
		print ("check info Mnemonic debug: ", mnemonic)
	print (account_info) #for debug purposes only 
	
	emit_signal('completed')
	#increases a wallet check timer
	wallet_check += 1

func _on_withraw(): #withdraws Algos from wallet data into my test algorand wallet
	#var status
	#if Globals.algos != 0: #cannot withdraw with zero balance
	#	Algorand.create_algod_node() #from an escrow account
		
	#	status = status && yield(Algorand._send_transaction_to_receiver_addr(Escrow_mnemoic ,"rigid steak better media circle nothing range tray firm fatigue pool damage welcome supply police spoon soul topic grant offer chimney total bronze able human", Globals.algos), "completed") #works
		#status = status && yield(_send_asset_transfers_to_receivers_address(funder_address , funder_mnemonic , receivers_address , receivers_mnemonic), "completed") #works
	#	print (status)
	#if Globals.algos == 0:
		
	#	print ("Cannot withdraw from ",Globals.algos, " balance")
		
	#if status:
	#	print('withdrawal Successful')
	#	show_account_info(false) #updates account info
	pass

func _on_reset():
	#should deleta all account details
	print ('----Resetting')
	var a=token_path 
	var b=local_image_path
	#var c="res://wallet/wallet_keys.cfg"
	#var d="res://wallet/nft_metadata.json"
	var FilesToDelete=[]#stores all files in an array
	FilesToDelete.append(a,b)
	for _i in FilesToDelete: #looped delete
		var error=FileDirectory.remove(_i)
		if error==OK:
			print ('Deleting Wallet Details')
	return _ready()

#func error_checkers()-> void:

#			return

func check_local_wallet_directory()-> bool:
	return FileDirectory. dir_exists("user://wallet")

func create_wallet_directory()-> void:
# Creates a Wallet folder.
	if not FileDirectory. dir_exists("user://wallet"):
		FileDirectory.make_dir("user://wallet")
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


"UI Buttons"
#increases all UI parents scale for horizontal screens
func upscale_wallet_ui()-> void:
	var newScale = Vector2(0.08, 0.08)
	var newScale2 = Vector2(0.25,0.25)
	var newScale3 = Vector2(1.5,1.5)
	
	wallet_ui.set_scale(newScale) 
	mnemonic_ui.set_scale(newScale2)
	transaction_ui.set_scale(newScale2)
	
	#upscale their childern
	
	for i in wallet_ui.get_children():
		i.set_scale(newScale)
	
	for t in mnemonic_ui.get_children():
		if not t is Timer:
			t.set_scale(newScale3)
	
	#transaction_ui.get_children().set_scale(newScale)
	
	#scale selection button
	state_controller.set_scale(newScale2) #doenst work. Using aniamtion player instead
	pass

func _on_withdraw_pressed():
	#Music.play_track(Music.ui_sfx[0])
	_on_withraw()


func _on_Main_menu_pressed():
	#Music.play_track(Music.ui_sfx[0])
	return Globals._go_to_title()


func _on_testnetdispenser_pressed():
	return OS.shell_open('https://testnet.algoexplorer.io/dispenser')


#Updates Local Account Info
func _on_refresh_pressed(): #disabling refresh button

	#check_account()
	if passed_all_connectivity_checks:
		check_wallet_info()
	
	pass
	#


#Deletes Local Account Info
func reset()-> void:
	Globals.delete_local_file(token_path)


'Copies Wallet Addresss to Clipboard'
func _on_Copy_address_pressed():
	print ("copied wallet address to clipboard")
	OS.set_clipboard(address) 



'For Importing Mnemonic and Address'
func _on_enter_mnemonic_pressed():
	imported_mnemonic = true


func _on_enter_transaction_pressed():
	transaction_valid = true


'Processes Algo and Asset Transactions'
func txn(): #runs presaved transactions once wallet is ready
	
	
	if recievers_addr != '' && _amount >= 100_000:
		print ('Transaction Debug: ',recievers_addr, '/','amount: ',_amount, '/', 'txn check', txn_check)
		
		yield(Algorand._send_txn_to_receiver_addr(params,mnemonic,recievers_addr, _amount), "completed")

		#reset transaction details
		recievers_addr = ''
		_amount = 0
		
		transaction_valid = false
		
		hideUI()
		funding_success_ui.show()
	
	if _asset_id != 0 && asset_id_valid :
		print (' Asset Txn Debug: ',recievers_addr, '/','asset id: ',_asset_id, '/', 'txn check', txn_check)
		
		#can be used to send both NFT's and Tokens
		yield(Algorand.transferAssets(params,mnemonic, recievers_addr,_asset_id, _amount), "completed")
		
		#reset transaction details
		recievers_addr = ''
		_asset_id = 0
		asset_id_valid = false

		hideUI()
		funding_success_ui.show()
	

'Processes Smart Contract NoOp transactions'
func smart_contract(): 
	if transaction_valid:
		var noop_txn = Algorand.algod.construct_app_call(params, '4KMRCP23JP4SM2L65WBLK6A3TPT723ILD27R7W755P7GAU5VCE7LJHAUEQ', 116639568,['4KMRCP23JP4SM2L65WBLK6A3TPT723ILD27R7W755P7GAU5VCE7LJHAUEQ'],["inc"])
	

		#print ("opt in transcation: ",noop_txn) #for debug purposes only
	
		# Signs the Raw transaction
		var stx = Algorand.raw_sign_transactions(noop_txn, mnemonic)
	
	#print ("Raw Signed Transaction: ",stx) #shouldn't be null

		var txid = Algorand.algod.send_transaction(stx) # sends raw signed transaction to the network

		txid = Algorand.algod.send_transaction(stx)
	
	#print (txid)
	
	#wait for transaction to finish sending
	#var wait= yield(Algorand.algod.wait_for_transaction(txid), "completed") 
	
	#print ('wait: ', wait)
	transaction_valid = false
	return transaction_valid

func _on_enter_asset_pressed():
	asset_id_valid = true

"Placeholder method for setting the UI elements"
func setUp_UI()-> bool:
	if dashboard_UI_amount_label != null:
		dashboard_UI_amount_label.set_text("Algo: "+str(_wallet_algos))
		return true
	return false

"UI methods for handling the new Wallet UI"
func hideUI()-> void:
	for i in $CanvasLayer.get_children():
		if i.name != 'state_controller':
			i.hide()

func showUI()-> void:
	for i in $CanvasLayer.get_children():
		if i.name != 'state_controller':
			i.show()
