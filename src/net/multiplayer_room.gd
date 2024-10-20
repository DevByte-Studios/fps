extends Node

@onready var match_manager: Match = %Match

@onready var map_selector: OptionButton = $Control/Options/Host/OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	for map in (%LevelManager as LevelManager).levels:
		map_selector.add_item(map.level_name)

	var args = Array(OS.get_cmdline_args())
	if args.has("server"):
		_on_host_button_pressed()
	elif args.has("client"):
		_on_join_button_pressed()

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		match_manager.client_connected(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		match_manager.client_disconnected(peer_id)

const PORT = 4433

func _on_join_button_pressed() -> void:
	# Create client.
	var peer = ENetMultiplayerPeer.new()
	var IP_ADDRESS = $Control/Options/Join/IpAddress.text
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	$Control.queue_free()

	get_window().title = "Client"

func _on_host_button_pressed() -> void:
	# Create server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	$Control.queue_free()

	match_manager.s_start(
		map_selector.get_item_text(map_selector.selected)
	)

	get_window().title = "Server"

	var server_is_player = true
	if server_is_player:
		match_manager.client_connected(multiplayer.get_unique_id())
