extends OptionButton

"""
WALLET NODE MANAGER

"""
# Implement TouchScreen Controller for State controller

onready var canvasLayer = get_parent().get_node("CanvasLayer")
onready var Algorand = get_parent().get_node("Algodot")
onready var dashboard_UI = get_parent().get_node("CanvasLayer/Dashboard_UI")
onready var transaction_UI = get_parent().get_node("CanvasLayer/Transaction_UI")
onready var account_addr = get_parent().get_node("CanvasLayer/Dashboard_UI/YSort/Label2") 

onready var ingame_algos = get_parent().get_node("CanvasLayer/Dashboard_UI/YSort2/HBoxContainer/VBoxContainer2/Label2")

onready var wallet_algos = get_parent().get_node("CanvasLayer/Dashboard_UI/YSort/Label")

onready var mnemonic_UI = get_parent().get_node("CanvasLayer/Mnemonic_UI")
onready var Collectibles_UI = get_parent().get_node("CanvasLayer/Collectibles_UI")
onready var mnemonic_UI_LineEdit = get_parent().get_node("CanvasLayer/Mnemonic_UI/LineEdit")

onready var submit_txn_button = get_parent().get_node("CanvasLayer/Transaction_UI/Button")

onready var submit_mnemonic_button = get_parent().get_node("CanvasLayer/Mnemonic_UI/Button")
onready var image_texture_holder = get_parent().get_node("CanvasLayer/Collectibles_UI/KinematicBody2D/TextureRect")
onready var kinematic2d = get_parent().get_node("CanvasLayer/Collectibles_UI/KinematicBody2D")
onready var asset_index_label = get_parent().get_node("CanvasLayer/Collectibles_UI/KinematicBody2D/Label")
onready var Password_UI = get_parent().get_node("CanvasLayer/Password_UI")
onready var App_Call_UI = get_parent().get_node("CanvasLayer/SmartContract_UI")
onready var transaction_UI_address_lineEdit = get_parent().get_node("CanvasLayer/Transaction_UI/LineEdit")

onready var transaction_UI_amount_lineEdit = get_parent().get_node("CanvasLayer/Transaction_UI/LineEdit2")
onready var FundingSuccessUI = get_parent().get_node("CanvasLayer/FundingSuccess")
onready var Funding_Success_Close_Button = get_parent().get_node("CanvasLayer/FundingSuccess/Button")
onready var fund_account_Button = get_parent().get_node("CanvasLayer/Dashboard_UI/Button")
onready var make_payment_state_controller_button = get_parent().get_node("CanvasLayer/Dashboard_UI/Button2")
onready var smartcontract_UI_Address = get_parent().get_node("CanvasLayer/SmartContract_UI/LineEdit")
onready var smartcontract_UI_AppID = get_parent().get_node("CanvasLayer/SmartContract_UI/LineEdit2")
onready var smartcontract_UI_AppArgs = get_parent().get_node("CanvasLayer/SmartContract_UI/LineEdit3")
onready var smartcontract_UI_Button = get_parent().get_node("CanvasLayer/SmartContract_UI/Button")
onready var transaction_UI_asset_id_LineEdit = get_parent().get_node("CanvasLayer/Transaction_UI/LineEdit3")
onready var enter_wallet_PassWord_Button = get_parent().get_node("CanvasLayer/Password_UI/Button")
onready var password_Enter_LineEdit = get_parent().get_node("CanvasLayer/Password_UI/LineEdit")
onready var create_new_acct_button = get_parent().get_node("CanvasLayer/Mnemonic_UI/Button2")


onready var create_account_succcessful_UI = get_parent().get_node("CanvasLayer/CreateAccountSuccess")
onready var create_account_succcessful_Label = get_parent().get_node("CanvasLayer/CreateAccountSuccess/Label2")
onready var copy_mnemonic_button = get_parent().get_node("CanvasLayer/CreateAccountSuccess/Button") 
onready var proceed_home_button = get_parent().get_node("CanvasLayer/CreateAccountSuccess/Button2")

onready var asset__UI = get_parent().get_node("CanvasLayer/Asset_UI")
onready var asset_Txn_valid_Button = get_parent().get_node("CanvasLayer/Transaction_UI/Button2")
onready var asset_Optin_Txn_valid_Button = get_parent().get_node("CanvasLayer/Asset_UI/Button")
onready var asset_Optin_Txn_reject_Button = get_parent().get_node("CanvasLayer/Asset_UI/Button2")

onready var button_0  = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button10")
onready var button_1 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button")
onready var button_2 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button2")
onready var button_3 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button3")
onready var button_4 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button4")
onready var button_5 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button5")
onready var button_6 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button6")
onready var button_7 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button7")
onready var button_8 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button8")
onready var button_9 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button9")
onready var button_11 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button11")
onready var button_12 = get_parent().get_node("CanvasLayer/Password_UI/GridContainer/Button12")


onready var AnimationPlayer_ = get_parent().get_node("AnimationTree/AnimationPlayer") # icon and minor UI animations
onready var AnimationPlayer_2 = get_parent().get_node("AnimationTree/AnimationPlayer2") # State Controller button ANimation
onready var AnimationTree_ = get_parent().get_node("AnimationTree") #animation tree for complex animations

onready var profile_pic = get_parent().get_node("CanvasLayer/Asset_UI/TextureRect") 
onready var asset_ui_index = get_parent().get_node("CanvasLayer/Asset_UI/YSort/VBoxContainer/HBoxContainer2/Label3")  
onready var asset_ui_amount = get_parent().get_node("CanvasLayer/Asset_UI/YSort/VBoxContainer/HBoxContainer/Label2")  


func _ready():
	Wallet.state_controller = self
	Wallet.Algorand = Algorand
	Wallet.canvas_layer = canvasLayer
	Wallet.account_address = account_addr
	Wallet.dashboard_UI = dashboard_UI
	Wallet.transaction_ui = transaction_UI
	Wallet.passward_UI = Password_UI
	Wallet.funding_success_ui = FundingSuccessUI
	Wallet.mnemonic_ui = mnemonic_UI
	Wallet.collectibles_UI = Collectibles_UI
	Wallet.mnemonic_ui_lineEdit = mnemonic_UI_LineEdit
	#print (dashboard_UI.get_children())
	
	###Setting this variables bug out the UI input system
	Wallet.wallet_algos = wallet_algos
	Wallet.ingame_algos = ingame_algos
	
	#Collectibles
	Wallet.NFT = image_texture_holder
	Wallet.kinematic2d = kinematic2d
	Wallet.NFT_index_label = asset_index_label
	Wallet.pfp = profile_pic
	Wallet.Asset_UI_index = asset_ui_index
	Wallet.Asset_UI_amount = asset_ui_amount
	
	#Buttons
	Wallet.txn_txn_valid_button = submit_txn_button
	Wallet.password_Entered_Button = enter_wallet_PassWord_Button #placeholder button
	Wallet.imported_mnemonic_button = submit_mnemonic_button
	Wallet.txn_addr = transaction_UI_address_lineEdit
	Wallet.txn_amount = transaction_UI_amount_lineEdit
	Wallet.funding_success_close_button = Funding_Success_Close_Button
	Wallet.smart_contract_UI = App_Call_UI
	Wallet.smartcontract_ui_address_lineEdit = smartcontract_UI_Address
	Wallet.smartcontract_ui_appID_lineEdit = smartcontract_UI_AppID
	Wallet.smartcontract_ui_args_lineEdit = smartcontract_UI_AppArgs
	Wallet.smartcontract_UI_button = smartcontract_UI_Button
	Wallet.make_Payment_Button = make_payment_state_controller_button
	Wallet.nft_asset_id = transaction_UI_asset_id_LineEdit
	Wallet.fund_Acct_Button = fund_account_Button
	Wallet.password_LineEdit = password_Enter_LineEdit
	Wallet._Create_Acct_button = create_new_acct_button
	
	Wallet.CreatAccountSuccessful_UI = create_account_succcessful_UI
	Wallet.CreatAccountSuccessful_Mnemonic_Label = create_account_succcessful_Label
	Wallet.CreatAccountSuccessful_Copy_Mnemonic_button = copy_mnemonic_button
	Wallet.CreatAccountSuccessful_Proceed_home_button = proceed_home_button
	
	
	Wallet.Asset_UI = asset__UI
	Wallet.asset_txn_valid_button = asset_Txn_valid_Button
	Wallet.asset_optin_txn_valid_button =asset_Optin_Txn_valid_Button
	Wallet.asset_optin_txn_reject_button = asset_Optin_Txn_reject_Button
	print("UI elemts OK: ",Wallet.check_Nodes()) #for debug purposes only
	
	Wallet._1 = button_1
	Wallet._2 = button_2
	Wallet._3 = button_3
	Wallet._4 = button_4
	Wallet._5 = button_5
	Wallet._6 = button_6
	Wallet._7 = button_7
	Wallet._8 = button_8
	Wallet._9 = button_9
	Wallet._0 = button_0
	Wallet.zero = button_11
	Wallet.delete_last_button = button_12
	
	#*****Animation ******#
	Wallet._Animation = AnimationPlayer_
	Wallet._Animation_UI = AnimationPlayer_2
	Wallet._Animation_Tree = AnimationTree_
	
	#print ("Wallet UI elemts: ",Wallet.UI_Elements) #for debug purposes only
	
	# Triggers CUstom Ready State in Wallet Node
	
	Wallet.__ready()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

"Fixes Stuck Button Bug"
# By toggling the Wallet's Processing on/off
# replace state controller with swipe controls
# Works Alongside Touch Screen Inputs for a beter UX
func _on_state_controller_toggled(button_pressed):
	if button_pressed:
		pass
		Wallet.set_process(true)
	else :
		pass
		Wallet.set_process(false)
	
	
	
