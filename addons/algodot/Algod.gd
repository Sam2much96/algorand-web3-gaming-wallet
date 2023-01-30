# *************************************************
# godot3-Algod Plugin- by Lucasvanmol & INhumanity_arts
# Released under MIT License
# *************************************************
# Algod Script
# Algorand Objects Within the Scene Tree
# *************************************************
# Features
# (1) Can create transactions between different accounts
# (2) Can transfer assets between accounts
# (3) Can check account information
# (4) Swipe Gestures as a State changer controller.
# (5) Swipe UI options


#Bugs:
# (1) Calling multiple yield functions sequentially breaks on testnet
# (2) Smart contract calls are buggy on testnet

# Requires
# (1) An algorand sandbox node for testing and proper debugging

# To Do:
#(1) Make functions easier to read (done)
# (2) Implement function parameters (done)
# (3) Write proper documentation (done)
# (4) Implement signals
# (5) Implement Testnet/ Localhost switch (done)
#
# *************************************************

extends Node

var algod: Algod

class_name Algodot, 'res://addons/algodot/icon.png'
export (String) var funder_mnemonic
#export (String) var funder_address


var params

" For Testing purpose only. Should be encrypted in release build"
export (String) var receivers_mnemonic
#export (String) var receivers_address



#*************placeholder variables****************#
export ( bool) var debug_txn   

export (bool) var generate_new_account = false # generates a new account & Mnemonic for testing
var new_account: Array # new generated account Placeholder
var transferred_assets: bool = false # Asset transfer boolean constructor

" Transaction PlaceHolder Variables"
var tx #______________ single transaction placeholder
var stx #______________Raw signed transaction placeholder
var txns  #____________Grouped transaction placeholder
var txid #_____________transaction Id placeholder
var asset_tx #_________asset transaction placeholder
var asset_index #______placeholder for asset index
var optin_tx #_________placeholder for opt in asset transaction

# account asset info placeholder
var _info : Dictionary

var wait # waits until txn is completed
var status: bool

#***********Node State Parameters************#

var algod_node_count: int = 0 #stops multiple instance bug
export (String, 'TESTNET', 'LOCALHOST', "MAINNET") var network_type

'Prevents Algod nnode from reverting to default settings'
func _enter_tree():
	if network_type != null:
		create_algod_node(network_type)


func _ready():
	
	
	if  debug_txn:
		_run_debug_test()

'Node url are set in _enter_tree()'
func create_algod_node(network_type: String):
	if algod_node_count == 0: 
		print(" -- Initialize Algod", network_type)

		if network_type == "localhost":
			algod = Algod.new() 
			algod.url = "http://localhost:4001"  #Used in sandbox environment. Used Change this variable for testnet/ mainnet
			algod.token = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" #Used in sandbox environment. Used Change this variable for testnet
			algod_node_count += 1
		elif network_type == "TESTNET":
			algod = Algod.new() 
			var url = "https://node.testnet.algoexplorerapi.io"
			var token = ""
			
			var headers_ : PoolStringArray = ["User-Agent","DoYouLoveMe?"]
			algod.set_url(url)
			algod.set_token(token)
			algod.set_headers(headers_)
			
			
			algod_node_count += 1
		elif network_type == "MAINNET":
			algod_node_count += 1
			return


func _run_debug_test():
	create_algod_node('localhost')

	print(" -- Get funder account")



	" These are custom tests for the Script. Run to test that Script works"

	status = status && yield(_test_algod_connection(), "completed") #works
	status = status && yield(_send_transaction_to_receiver_addr(funder_mnemonic , receivers_mnemonic,1000000000000000), "completed") #works
	status = status && yield(_send_asset_transfers_to_receivers_address(funder_mnemonic ,  receivers_mnemonic), "completed") #works
		
	if status:
		print(" -- Test run completed successfully.")
	else: #returns false even though transaction runs
		print(" -- Test run completed with errors.")
		print (status)
		OS.exit_code = 1

	print(" -- exiting.")
	get_tree().queue_delete(self)

func _timeout( wait_time : int):
	yield(get_tree().create_timer(wait_time), "timeout")
	print(" -- Test run is taking too long.")
	OS.exit_code = 1

	print(" -- exiting.")
	get_tree().quit()

func _test_algod_connection(): # original Dev Github Action test
	print(" -- _test_algod_connection")
	
	var status = yield(algod.health(), "completed") == OK
	
	if !status:
		printerr("   !! _test_algod_connection failed")
	#if status:
	#	#algod_node_health_is_good = true

	return status
	



func _on_Timer_timeout():
	_timeout(7)

' Feed it a Variable to Generate a New account & Mnemonic'
func create_new_account(_account : Array): #it should be fed the account varibles as parameters
	if generate_new_account == true:
		#create new account
		_account = algod.generate_key() 
		 # account 0 is account created, accout 1 is mnemonic
		print("New Account Details: ",_account[0], '////',_account[1])
		return _account
	elif generate_new_account == false:
		push_error(" Set Generate New Account to True before running this funtion")
		_timeout(1)


" Sends transaction btw two accounts"
func _send_transaction_to_receiver_addr( _funder_mnemonic : String, _receivers_address: String  , _amount: int): #works #should be fed the receiver and sender's accounts as parameters
	
	
	print(" -- _sending_transaction")
	
	print("sending tx")
	var _funder_address=algod.get_address(_funder_mnemonic)
	
	
	#var _receivers_address=algod.get_address(_receivers_mnemonic)
	
	#get suggested parameters
	
	params = yield(algod.suggested_transaction_params(), "completed")
	
	#get initial address amount #depreciated. Use check account state instead
	var _account_info: Dictionary=(yield(algod._check_account_information(_funder_address,_funder_mnemonic, ""), "completed"))
	
	var initial_amount: int = _account_info["amount"] #depreciated. Use check account state instead
	#create and sign transaction
	tx = algod.construct_payment(params, _funder_address, _receivers_address, _amount)
	
	#sending the signed transaction
	stx = algod.sign_transaction(tx, _funder_mnemonic)
	
	#generating the transaction ID
	txid = yield(algod.send_transaction(stx), "completed")
	
	#wait for confirmation
	print("waiting for confirmation")
	wait = yield(algod.wait_for_transaction(txid), "completed")
	
	# getting the account infromation
	var info = yield(algod.account_information(_receivers_address), "completed")
	
	assert(info.amount == initial_amount + _amount) #depreciated. Use check account state instead
	#verifying the receiver's account's algo holdings
	print (info.amount, (initial_amount+_amount))
	return info.amount == initial_amount + _amount


" Sends transaction btw two accounts Version 2 for Testnet"
func _send_txn_to_receiver_addr( params,_funder_mnemonic : String, _receivers_address: String  , _amount: int): #works #should be fed the receiver and sender's accounts as parameters
	
	
	print(" -- _sending_transaction")
	
	
	var _funder_address=algod.get_address(_funder_mnemonic)
	
	print("sending tx from  ", _funder_address, ' to ', _receivers_address)
	
	#create and sign transaction
	tx = algod.construct_payment(params, _funder_address, _receivers_address, _amount)
	
	print ("Txn Debug: ", tx) #for debug purposes only
	
	#sending the signed transaction
	stx = algod.sign_transaction(tx, _funder_mnemonic)
	
	#debug signed transaction
	#print ('Signed Txn Debug: ',stx) #for debug purposes only
	
	#returns the signed transactions
	txid = yield(algod.send_transaction(stx), "completed")
	
	#yield(get_tree().create_timer(20), "timeout")
	
	
	print ('tx id debug: ',txid)
	
	
	
	print("waiting for confirmation")
	wait=yield(algod.wait_for_transaction(txid), "completed")
	
	print ('wait: ',wait)

" Make Sure the Funder's Address has sufficient Algos or the Code will Break"
#need logic fix
func _send_asset_transfers_to_receivers_address( _funder_mnemonic : String, _receivers_mnemonic : String): # 
	print(" -- _sending_asset_transfers")

	params = yield(algod.suggested_transaction_params(), "completed") #duplicate of :generate_suggested_transaction_parameters()
	
	var _funder_address=algod.get_address(_funder_mnemonic)
	var _receivers_address=algod.get_address(_receivers_mnemonic)
	
	#creates assets
	create_assets("SamCoin", _receivers_address, 1000, "SC") 
	

	#generates Raw signed transaction
	
	stx = algod.sign_transaction(tx, _receivers_mnemonic)
	

	#Generating transaction Id from signed transaction
	txid = yield(algod.send_transaction(stx), "completed") 
	

	#wait for transaction to finish sending
	wait= yield(algod.wait_for_transaction(txid), "completed") 
	
	
	
	var tx_info = yield(algod.transaction_information(txid), "completed") 
	

	asset_index = int(tx_info.get("asset-index")) 

	#Opts in to the Asset transaction 
	opt_in_asset_transaction(params,_funder_address, asset_index)
	
	
	# Signs the Raw transaction
	raw_sign_transactions(optin_tx, _funder_mnemonic)
		
	yield(algod.send_transaction(stx), "completed") # sends raw signed transaction to the network


	print("atomic swap")

# constructs a new transaction 
	var algo_tx = algod.construct_payment(
		params,
		_funder_address,
		_receivers_address,
		100
	)

# constructs asset transfer from funder address to receiver address of 1 Aseet
	construct_asset_transfer(params,_receivers_address, _funder_address, 1, asset_index)


	# Sends grouped transactions
	create_grouped_transaction(algo_tx, asset_tx)
	#var txns = algod.group_transactions([algo_tx, asset_tx]) #ducplicate of code above
	
	# Both accounts sign transaction 
	txns[0] = algod.sign_transaction(txns[0], _funder_mnemonic)
	txns[1] = algod.sign_transaction(txns[1], _receivers_mnemonic)
#----------------------------------------------

	# send signed transaction
	yield(algod.send_transactions(txns), "completed") 
	

#-------------------------------------------------------------
	# gets account information as a dictionary
	var info = yield(algod.account_information(_receivers_address), "completed") #checks receivers address for asset tranfer #should contain account mnemonic?
	
	#print (asset_index) #for debugging in algod sandbox
	
	var funder_assets = info.assets
	for asset in funder_assets: # Checks users account for certain variables
		if transferred_assets == true:
			#check https://github.com/lucasvanmol/algodot/issues/5#issuecomment-1196307682 for more details about the below conditional

			if asset["asset-id"] && asset_index && asset["amount"] != null:
				return true
		else:
			print ("Asset Id :",asset["asset-id"], "//", " Asset Index: ", asset_index,"//", "Asset Amount: ",asset["amount"]) #for debug purposes only
			printerr("   !! _test_asset_transfers failed") #works
			return false

" This function can be expanded upon to print lots of Account specific details"

# broken in testnet
func _check_account_information(address : String, mnemonic : String, info : String) -> Dictionary: #account debugger #works
	_info = yield(algod.account_information(address,mnemonic), "completed")
	if info == "" or null:
		return (_info)
	elif info == "assets" :
		var _a = _info.assets
		return (_a)
	elif info == "asset-id":
		var _b = _info.get("asset-id")
		return (_b)
	else:
		return 

'Creates a Grouped transaction from 2 individual transactions'
func create_grouped_transaction(txn_1, txn_2):
	txns = algod.group_transactions([txn_1, txn_2])
	return txns

func raw_sign_transactions( transaction, mnemonic : String): # transaction is tx
	stx = algod.sign_transaction(transaction, mnemonic)
	return stx

func create_assets(asset_name : String, to_address : String, Total_supply: int, Unit_name: String): #works # breaks when not using default sandbox creator acct
	print("-----creating asset----", asset_name)
	tx = algod.construct_asset_create( #breaks
		params,
		to_address, # Creator #SDK uses default sandbox wallet and ignores this creator (fixed)
		asset_name,	# Asset name
		2,			# Decimals #i.e how many decimals from the total supply
		false,		# Default frozen?
		Total_supply,		# Total supply # This is 1000.00
		Unit_name		# Unit name eg GTC, TC, GC
	)
	return tx


func construct_asset_transfer( params,from_address : String, to_address : String, amount_ : int, _asset_index ):
	transferred_assets = true
	asset_tx = algod.construct_asset_xfer( # rewrite this as a separate function
		params,
		from_address,
		to_address,
		amount_,
		_asset_index
	)
	return asset_tx

#generates a suggested transaction parameter instead of manually creating one

func generate_suggested_transaction_parameters(): 
	params = yield(algod.suggested_transaction_params(), "completed") 
	return params

func opt_in_asset_transaction( params ,from_address: String, _asset_index):
	print("opt in")
	optin_tx = algod.construct_asset_opt_in(
		params,
		from_address,
		_asset_index
		)
	return optin_tx

#doesnt work in _process()
func opt_in_smart_contract(params, from_address: String): #duplicate of opt in asset transaction
	print("opt in")
	optin_tx = algod.construct_app_call(
		params,
		from_address
		)
	return optin_tx

#duplicate of send_assets() function
"Version 2 of Asset sending method working on Testnet" #breaks on NFT transfer
func transferAssets(params,_funder_mnemonic: String ,  _receiver_address : String,_asset_id, _amount: int):
	var _funder_address=algod.get_address(_funder_mnemonic)
	
	# Construct Aset tx
	construct_asset_transfer(params,_funder_address, _receiver_address, _amount, _asset_id)
	
	# Raw Sign Asset tx
	stx = algod.sign_transaction(asset_tx, _funder_mnemonic)
	
	#Generating transaction Id from signed transaction
	txid = yield(algod.send_transaction(stx), "completed") 
	
	print (txid)
	


#Buggy
func createAssets(_asset_name: String, _unit_name: String, _amount: int,_receivers_mnemonic: String, _receivers_address: String,_params):

	
	
	tx = algod.construct_asset_create( #breaks
		_params,
		_receivers_address, # Creator #SDK uses default sandbox wallet and ignores this creator (fixed)
		_asset_name,	# Asset name
		0,			# Decimals #i.e how many decimals from the total supply
		false,		# Default frozen?
		_amount,		# Total supply # This is 1000.00
		_unit_name,		# Unit name eg GTC, TC, GC
		PoolByteArray(['']),#metadata hash
		"ipfs://QmNoThogc1D7XCzQrjePPxChyGmuohX6LXqDTCLJwTUUfR" #url
	)
	return tx

	#generates Raw signed transaction
	
	stx = algod.sign_transaction(tx, _receivers_mnemonic)
	

	#Generating transaction Id from signed transaction
	txid = yield(algod.send_transaction(stx), "completed") 
	

	#wait for transaction to finish sending
	wait= yield(algod.wait_for_transaction(txid), "completed") 
	
	
	
	var tx_info = yield(algod.transaction_information(txid), "completed") 
	

	asset_index = int(tx_info.get("asset-index"))
	print (" Asset-ID: ",asset_index)



func AssetParams(_asset_index: int, Params):
	params
	
	pass

func x():
	algod.transaction_information()
