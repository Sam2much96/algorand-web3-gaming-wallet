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

onready var mnemonic_UI_LineEdit = get_parent().get_node("CanvasLayer/Mnemonic_UI/LineEdit")

onready var submit_txn_button = get_parent().get_node("CanvasLayer/Transaction_UI/Button")

onready var submit_mnemonic_button = get_parent().get_node("CanvasLayer/Mnemonic_UI/Button")

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


# Called when the node enters the scene tree for the first time.
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
	
	Wallet.mnemonic_ui_lineEdit = mnemonic_UI_LineEdit
	#print (dashboard_UI.get_children())
	
	###Setting this variables bug out the UI input system
	Wallet.wallet_algos = wallet_algos#dashboard_UI.get_child(4).get_child(1) #ingame_algos
	Wallet.ingame_algos = ingame_algos#dashboard_UI.get_child(5).get_child(2).get_child(0).get_child(0)#wallet_algos
	
	#Buttons
	Wallet.txn_txn_valid_button = submit_txn_button
	
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
	print("UI elemts OK: ",Wallet.check_Nodes()) #for debug purposes only
	#print ("Wallet UI elemts: ",Wallet.UI_Elements) #for debug purposes only
	Wallet.__ready()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

"Fixes Stuck Button Bug"
# By toggling the Wallet's Processing on/off
# replace state controller with swipe controls
func _on_state_controller_toggled(button_pressed):
	if button_pressed:
		Wallet.set_process(true)
	else : Wallet.set_process(false)
