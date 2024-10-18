class_name NetworkSoundSource
extends Node

@export var audio_stream_parent: Node = null

@export var audio_streams: Array[PlayableSound]

func play_sound(
	stream_name: String,
	volume_linear = 1.0,
	pitch = 1.0
) -> void:
	if not is_multiplayer_authority():
		push_error("Error: Only the player authority can play sounds")
	_play_sound.rpc(stream_name, volume_linear, pitch)

func find_audio_stream(stream_name: String) -> AudioStream:
	for audio_stream in audio_streams:
		if audio_stream.name == stream_name:
			return audio_stream.audio_stream
	push_error("Error: Audio stream not found")
	return null

@rpc("authority", "call_local")
func _play_sound(stream_name: String, volume_linear = 1.0, pitch = 1.0) -> void:
	var audioPlayer = AudioStreamPlayer3D.new()
	audio_stream_parent.add_child(audioPlayer)
	audioPlayer.stream = find_audio_stream(stream_name)
	audioPlayer.volume_db = db_to_linear(volume_linear)
	audioPlayer.pitch_scale = pitch
	audioPlayer.play()

	await audioPlayer.finished
	audioPlayer.queue_free()
