extends Node


@onready var player_spawner := $GameWorld/Players

@export var player_prefab: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func spawn_player(peer_id: int) -> void:
	var player = player_prefab.instantiate()
	player.peer_id = peer_id
	player.name = str(peer_id)
	player_spawner.add_child(player)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		spawn_player(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

	spawn_player(1)
