class_name Match extends Node

@export var running: bool = false
@export var current_game_mode: String = "deathmatch"
@export var current_level_name: String = ""

@onready var player_mangaer: PlayerManager = $"../PlayerManager"


func _ready():
	set_multiplayer_authority(1)

var clients: Dictionary = {}
func client_connected(peer_id: int) -> void:
	print("Client connected: ", peer_id)
	clients[peer_id] = {}

	# ensure the client is up to speed
	if current_level_name != "":
		print("Sending level to client")
		($"../LevelManager" as LevelManager).change_level.rpc_id(peer_id, current_level_name)
	player_mangaer.s_spawn_existing_for(peer_id)

	print("Spawning client " + str(peer_id))
	player_mangaer.s_spawn_player(peer_id, find_spawn_point(peer_id))


func client_disconnected(peer_id: int) -> void:
	if clients.has(peer_id):
		clients.erase(peer_id)

func find_spawn_point(peer_id: int) -> Vector3:
	# needs to be adjusted for defusal etc
	var _client_info = clients[peer_id]
	var spawn_points = get_tree().get_nodes_in_group("spawn_point").filter(func (spawn_point: Node) -> bool:
		return (spawn_point as SpawnPoint).allow_in_deathmatch
	)

	if spawn_points.size() == 0:
		push_error("No spawn points found")
		return Vector3.ZERO
	
	return spawn_points[randi() % spawn_points.size()].global_transform.origin

func s_player_died(peer_id: int) -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 1
	timer.start()
	print("started respawn timer")
	timer.connect("timeout", func ():
		print("respawning player")
		player_mangaer.s_spawn_player(peer_id, find_spawn_point(peer_id))
	)

func s_start() -> void:
	running = true
	s_change_level("buffa")
	current_game_mode = "deathmatch"

func s_change_level(level_name: String) -> void:
	current_level_name = level_name
	($"../LevelManager" as LevelManager).change_level.rpc(level_name)
