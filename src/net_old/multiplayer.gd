extends Node

# @onready var main_menu = $MainMenu
@onready var connection_panel = $ConnectionPanel
@onready var host_field = $ConnectionPanel/VBoxContainer/GridContainer/HostField
@onready var port_field = $ConnectionPanel/VBoxContainer/GridContainer/PortField
@onready var message_label = $MessageLabel
@onready var sync_lost_label = $SyncLostLabel
# @onready var reset_button = $ResetButton

@export var player_prefab: PackedScene = null

var prefix = ""
func p(msg: String) -> void:
	print("[" + str(multiplayer.get_unique_id()) + "]" + prefix + msg)


func _ready() -> void:
	multiplayer.peer_connected.connect(self._on_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
	multiplayer.connected_to_server.connect(self._on_server_connected)
	multiplayer.server_disconnected.connect(self._on_server_disconnected)

	SyncManager.sync_started.connect(self._on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(self._on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(self._on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(self._on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(self._on_SyncManager_sync_error)

func _on_server_button_pressed() -> void:
	prefix = "Server: "
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text))
	multiplayer.multiplayer_peer = peer
	print(SyncManager.network_adaptor.get_network_unique_id())
	connection_panel.visible = false
	message_label.text = "Starting..."

func _on_client_button_pressed() -> void:
	prefix = "Client: "
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	print(SyncManager.network_adaptor.get_network_unique_id())
	connection_panel.visible = false
	message_label.text = "Connecting..."

func _on_peer_connected(peer_id: int):
	p("Peer connected: " + str(peer_id))

	if multiplayer.is_server() and peer_id != 1:
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()

@rpc("any_peer")
func register_player(options: Dictionary = {}) -> void:
	var peer_id = multiplayer.get_remote_sender_id()
	if not peer_id == SyncManager.network_adaptor.get_network_unique_id():
		SyncManager.add_peer(peer_id)
		var peer = SyncManager.peers[peer_id]

	$ClientPlayer.set_multiplayer_authority(peer_id)

	if multiplayer.is_server():
		multiplayer.multiplayer_peer.refuse_new_connections = true

		message_label.text = "Starting..."
		# Give a little time to get ping data.
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()

func _on_peer_disconnected(peer_id: int):
	SyncManager.remove_peer(peer_id)

func _on_server_connected() -> void:
	p("Connected to server")

	SyncManager.add_peer(1)
	message_label.text = "Connected!"

func _on_server_disconnected() -> void:
	p("Disconnected from server")
	_on_peer_disconnected(1)

func _on_SyncManager_sync_started() -> void:
	p("Sync started")
	message_label.text = "Started!"

func _on_SyncManager_sync_stopped() -> void:
	pass

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false

	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()

# func _on_ResetButton_pressed() -> void:
# 	SyncManager.stop()
# 	SyncManager.clear_peers()
# 	var peer = multiplayer.multiplayer_peer
# 	if peer:
# 		peer.close()
# 	get_tree().reload_current_scene()
