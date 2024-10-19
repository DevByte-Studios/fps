class_name PlayerManager extends Node


@export var player_container: Node3D = null
@export var player_prefab: PackedScene

@onready var match: Match = %Match

# peer id -> player node
var s_players: Dictionary = {}

func is_spawned(peer_id: int) -> bool:
	return s_players.has(peer_id)

func s_spawn_existing_for(peer_id: int) -> void:
	for player in player_container.get_children():
		if player.peer_id != peer_id:
			c_spawn_player.rpc_id(peer_id, player.peer_id, player.global_transform.origin)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_multiplayer_authority(1)

@rpc("call_local", "authority")
func c_spawn_player(peer_id: int, spawn_location: Vector3) -> void:
	var player: Player = player_prefab.instantiate()
	player.get_node("WeaponManager").decal_manager = %DecalManager
	player.name = str(peer_id)
	player_container.add_child(player)
	player.global_transform.origin = spawn_location
	s_players[peer_id] = player

func s_spawn_player(peer_id: int, spawn_location: Vector3) -> void:
	c_spawn_player.rpc(
		peer_id,
		spawn_location
	)

