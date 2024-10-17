extends Node

@onready var match_manager: Match = $Match

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

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

func _on_host_button_pressed() -> void:
	# Create server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	$Control.queue_free()

	match_manager.s_start()

	var server_is_player = true
	if server_is_player:
		match_manager.client_connected(multiplayer.get_unique_id())
