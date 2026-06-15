extends Node
## Autoload de música de fundo (loops). Ficheiros em res://audio/music/<id>.ogg|.wav|.mp3

const FILE_DIR := "res://audio/music/"

var _player: AudioStreamPlayer
var _file_cache: Dictionary = {}
var _current_track_id: String = ""
var _loop: bool = true


func _ready() -> void:
	_ensure_music_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	_player.finished.connect(_on_player_finished)
	add_child(_player)


func play(track_id: String, volume_db: float = -6.0) -> void:
	if track_id.is_empty():
		stop()
		return
	var stream: AudioStream = _resolve_stream(track_id)
	if stream == null:
		push_warning("MusicManager: faixa desconhecida '%s'." % track_id)
		stop()
		return
	if _current_track_id == track_id and _player.playing:
		return
	_current_track_id = track_id
	_loop = true
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()


func stop() -> void:
	_current_track_id = ""
	_loop = false
	if _player.playing:
		_player.stop()


func _resolve_stream(track_id: String) -> AudioStream:
	if _file_cache.has(track_id):
		return _file_cache[track_id] as AudioStream
	var loaded: AudioStream = _try_load_track_file(track_id, "ogg")
	if loaded == null:
		loaded = _try_load_track_file(track_id, "wav")
	if loaded == null:
		loaded = _try_load_track_file(track_id, "mp3")
	if loaded != null:
		_file_cache[track_id] = loaded
	return loaded


func _try_load_track_file(track_id: String, ext: String) -> AudioStream:
	var path: String = FILE_DIR + track_id + "." + ext
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _on_player_finished() -> void:
	if _loop and _current_track_id != "":
		_player.play()


func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") != -1:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")
