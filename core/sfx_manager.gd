extends Node
## Autoload central de SFX.
## Sons placeholder gerados em código; substituíveis por ficheiros em res://audio/sfx/<id>.ogg ou .wav

const FILE_DIR := "res://audio/sfx/"
const NO_POSITION := Vector2(INF, INF)
const SAMPLE_RATE := 22050
const POOL_2D_SIZE := 14
const POOL_UI_SIZE := 4
const MAX_DISTANCE := 2200.0

var _procedural: Dictionary = {}
var _file_cache: Dictionary = {}
var _pool_2d: Array = []
var _pool_ui: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_audio_buses()
	_build_procedural_library()
	_init_pools()


func play(
	sfx_id: String,
	world_pos: Vector2 = NO_POSITION,
	pitch_scale: float = -1.0,
	volume_db: float = 0.0
) -> void:
	var stream: AudioStream = _resolve_stream(sfx_id)
	if stream == null:
		return
	var pitch: float = pitch_scale if pitch_scale > 0.0 else _rng.randf_range(0.94, 1.06)
	if world_pos == NO_POSITION:
		_play_ui(stream, pitch, volume_db)
	else:
		_play_2d(stream, world_pos, pitch, volume_db)


func play_shot(
	owner_player: Player,
	spawn_position: Vector2,
	shot_flags: Dictionary,
	is_homing: bool
) -> void:
	if shot_flags.get("esqueleto_feixe", false):
		return
	if shot_flags.get("archer_split_child", false):
		return
	var sfx_id: String = "shoot_bow"
	if shot_flags.get("spike_shot", false) or shot_flags.get("spike_volley", false):
		sfx_id = "shoot_spike"
	elif is_homing:
		sfx_id = "shoot_magic"
	elif owner_player.is_pistoleiro() or owner_player is EsqueletoPlayer:
		sfx_id = "shoot_gun"
	play(sfx_id, spawn_position)


func play_arrow_hit(hit_position: Vector2, damage: int, flags: Dictionary) -> void:
	var sfx_id: String = "hit_light"
	if flags.get("esqueleto_feixe", false):
		sfx_id = "hit_feixe"
	elif damage >= 28 or flags.get("esqueleto_chuva_osso", false):
		sfx_id = "hit_heavy"
	play(sfx_id, hit_position)


func _resolve_stream(sfx_id: String) -> AudioStream:
	var key: String = sfx_id
	if _file_cache.has(key):
		return _file_cache[key] as AudioStream
	var loaded: AudioStream = _try_load_sfx_file(key, "ogg")
	if loaded == null:
		loaded = _try_load_sfx_file(key, "wav")
	if loaded == null:
		loaded = _try_load_sfx_file(key, "mp3")
	if loaded != null:
		return loaded
	if _procedural.has(key):
		return _procedural[key] as AudioStream
	push_warning("SfxManager: som desconhecido '%s'." % key)
	return null


func _try_load_sfx_file(key: String, ext: String) -> AudioStream:
	var path: String = FILE_DIR + key + "." + ext
	if not ResourceLoader.exists(path):
		return null
	var loaded: AudioStream = load(path) as AudioStream
	_file_cache[key] = loaded
	return loaded


func _play_2d(stream: AudioStream, world_pos: Vector2, pitch_scale: float, volume_db: float) -> void:
	var player: AudioStreamPlayer2D = _acquire_2d()
	player.stream = stream
	player.global_position = world_pos
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()


func _play_ui(stream: AudioStream, pitch_scale: float, volume_db: float) -> void:
	var player: AudioStreamPlayer = _acquire_ui()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()


func _acquire_2d() -> AudioStreamPlayer2D:
	for p in _pool_2d:
		var player := p as AudioStreamPlayer2D
		if not player.playing:
			return player
	return _pool_2d[0] as AudioStreamPlayer2D


func _acquire_ui() -> AudioStreamPlayer:
	for p in _pool_ui:
		var player := p as AudioStreamPlayer
		if not player.playing:
			return player
	return _pool_ui[0] as AudioStreamPlayer


func _init_pools() -> void:
	for i in POOL_2D_SIZE:
		var p2d := AudioStreamPlayer2D.new()
		p2d.bus = "SFX"
		p2d.max_distance = MAX_DISTANCE
		p2d.attenuation = 1.0
		add_child(p2d)
		_pool_2d.append(p2d)
	for i in POOL_UI_SIZE:
		var ui := AudioStreamPlayer.new()
		ui.bus = "UI"
		add_child(ui)
		_pool_ui.append(ui)


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")
	if AudioServer.get_bus_index("UI") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "UI")
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")


func _build_procedural_library() -> void:
	_procedural["shoot_bow"] = _make_whoosh(0.11, 920.0, 240.0, 0.28)
	_procedural["shoot_gun"] = _make_noise_burst(0.07, 0.42, 1800.0)
	_procedural["shoot_spike"] = _make_whoosh(0.08, 1100.0, 420.0, 0.22)
	_procedural["shoot_magic"] = _make_tone(440.0, 0.14, 0.2, true, 0.35)
	_procedural["shoot_feixe"] = _make_tone(180.0, 0.22, 0.16, false, 0.45)
	_procedural["shoot_ice"] = _make_tone(660.0, 0.1, 0.24, true, 0.3)
	_procedural["shoot_orb"] = _make_tone(120.0, 0.18, 0.2, false, 0.38)
	_procedural["hit_light"] = _make_impact(0.07, 280.0, 0.38)
	_procedural["hit_heavy"] = _make_impact(0.11, 160.0, 0.55)
	_procedural["hit_feixe"] = _make_impact(0.13, 120.0, 0.62)
	_procedural["explosion"] = _make_noise_burst(0.28, 0.72, 900.0)
	_procedural["explosion_small"] = _make_noise_burst(0.14, 0.45, 1400.0)
	_procedural["ricochet"] = _make_tone(880.0, 0.05, 0.18, true, 0.28)
	_procedural["dash"] = _make_whoosh(0.09, 300.0, 80.0, 0.24)
	_procedural["jump"] = _make_tone(520.0, 0.06, 0.22, true, 0.18)
	_procedural["shield_block"] = _make_tone(700.0, 0.09, 0.26, true, 0.34)
	_procedural["freeze"] = _make_tone(920.0, 0.16, 0.2, true, 0.3)
	_procedural["pit_fall"] = _make_whoosh(0.2, 500.0, 90.0, 0.36)
	_procedural["grenade_throw"] = _make_whoosh(0.1, 200.0, 60.0, 0.26)
	_procedural["grenade_bounce"] = _make_impact(0.05, 420.0, 0.22)
	_procedural["ult_start"] = _make_tone(90.0, 0.35, 0.14, false, 0.5)


func _wav_from_samples(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var s16: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	stream.data = data
	return stream


func _make_tone(
	freq: float,
	duration: float,
	attack: float,
	fade_out: bool,
	volume: float
) -> AudioStreamWAV:
	var count: int = maxi(1, int(SAMPLE_RATE * duration))
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0
		if attack > 0.0:
			env = minf(1.0, t / attack)
		if fade_out:
			env *= 1.0 - float(i) / float(count)
		samples[i] = sin(TAU * freq * t) * volume * env
	return _wav_from_samples(samples)


func _make_whoosh(duration: float, start_f: float, end_f: float, volume: float) -> AudioStreamWAV:
	var count: int = maxi(1, int(SAMPLE_RATE * duration))
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var u: float = float(i) / float(count)
		var freq: float = lerpf(start_f, end_f, u)
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - u) * (1.0 - u)
		var noise: float = _rng.randf_range(-1.0, 1.0) * 0.35
		samples[i] = (sin(TAU * freq * t) * 0.65 + noise) * volume * env
	return _wav_from_samples(samples)


func _make_noise_burst(duration: float, volume: float, lp_freq: float = 0.0) -> AudioStreamWAV:
	var count: int = maxi(1, int(SAMPLE_RATE * duration))
	var samples := PackedFloat32Array()
	samples.resize(count)
	var prev: float = 0.0
	for i in count:
		var env: float = pow(1.0 - float(i) / float(count), 1.6)
		var raw: float = _rng.randf_range(-1.0, 1.0)
		if lp_freq > 0.0:
			var dt: float = 1.0 / float(SAMPLE_RATE)
			var rc: float = 1.0 / (TAU * lp_freq)
			var alpha: float = dt / (rc + dt)
			raw = prev + alpha * (raw - prev)
			prev = raw
		samples[i] = raw * volume * env
	return _wav_from_samples(samples)


func _make_impact(duration: float, freq: float, volume: float) -> AudioStreamWAV:
	var count: int = maxi(1, int(SAMPLE_RATE * duration))
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var u: float = float(i) / float(count)
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = pow(1.0 - u, 2.2)
		var f: float = lerpf(freq, freq * 0.45, u)
		var noise: float = _rng.randf_range(-1.0, 1.0) * 0.4 * env
		samples[i] = (sin(TAU * f * t) * 0.55 + noise) * volume * env
	return _wav_from_samples(samples)
