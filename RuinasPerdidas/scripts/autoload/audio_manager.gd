extends Node
## Sons e músicas. Procura arquivos em res://audio/sfx e res://audio/music.
## Se um arquivo não existir, simplesmente não toca (sem erro).

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const POOL_SIZE := 10

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _current_music := ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for i in POOL_SIZE:
        var p := AudioStreamPlayer.new()
        add_child(p)
        _players.append(p)
    _music = AudioStreamPlayer.new()
    add_child(_music)
    _music.finished.connect(_on_music_finished)


func _get_stream(path: String) -> AudioStream:
    if _cache.has(path):
        return _cache[path]
    var stream: AudioStream = null
    if ResourceLoader.exists(path):
        stream = load(path) as AudioStream
    _cache[path] = stream
    return stream


func play_sfx(sfx_name: String, pitch_jitter: float = 0.06, volume_db: float = 0.0) -> void:
    var stream: AudioStream = _get_stream(SFX_DIR + sfx_name + ".wav")
    if stream == null:
        return
    var p: AudioStreamPlayer = _players[_next]
    _next = (_next + 1) % _players.size()
    p.stream = stream
    p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
    p.volume_db = linear_to_db(maxf(Game.sfx_volume, 0.0001)) + volume_db
    p.play()


func play_music(music_name: String) -> void:
    if music_name == _current_music and _music.playing:
        return
    var stream: AudioStream = _get_stream(MUSIC_DIR + music_name + ".wav")
    _current_music = music_name
    if stream == null:
        _music.stop()
        return
    _music.stream = stream
    _music.volume_db = linear_to_db(maxf(Game.music_volume, 0.0001))
    _music.play()


func stop_music() -> void:
    _current_music = ""
    _music.stop()


func _on_music_finished() -> void:
    if _current_music != "":
        _music.play()
