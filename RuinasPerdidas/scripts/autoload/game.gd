extends Node
## Estado global: progresso da partida, configurações e qualidade gráfica.

signal gems_changed(count: int)
signal coins_changed(count: int)
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal message(text: String)
signal game_over
signal victory

const SETTINGS_PATH := "user://settings.cfg"
const GEMS_REQUIRED := 3
const QUALITY_NAMES: Array[String] = ["Baixa", "Média", "Alta"]
const RENDER_SCALES: Array[float] = [0.6, 0.8, 1.0]
const SHADOW_ATLAS: Array[int] = [1024, 2048, 2048]
const SHADOW_DISTANCE: Array[float] = [0.0, 40.0, 45.0]
const VEG_FACTOR: Array[float] = [0.45, 0.75, 1.0]

var gems := 0
var coins := 0
var kills := 0
var elapsed := 0.0
var running := false
var best_time := 0.0

var quality := 2
var fps_cap := 60
var sfx_volume := 0.8
var music_volume := 0.5
var _adaptive_scale := 1.0
var _adaptive_timer := 1.0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_settings()
    apply_quality()


func _process(delta: float) -> void:
    _adaptive_timer -= delta
    if _adaptive_timer > 0.0:
        return
    _adaptive_timer = 1.25
    var fps: float = float(Engine.get_frames_per_second())
    if fps <= 0.0:
        return
    var next_scale: float = _adaptive_scale
    if fps < 46.0:
        next_scale = maxf(0.65, _adaptive_scale - 0.08)
    elif fps > 57.0:
        next_scale = minf(RENDER_SCALES[quality], _adaptive_scale + 0.025)
    if not is_equal_approx(next_scale, _adaptive_scale):
        _adaptive_scale = next_scale
        get_viewport().scaling_3d_scale = _adaptive_scale


func reset_run() -> void:
    gems = 0
    coins = 0
    kills = 0
    elapsed = 0.0
    running = true
    gems_changed.emit(gems)
    coins_changed.emit(coins)


func add_gem() -> void:
    gems += 1
    gems_changed.emit(gems)
    if gems >= GEMS_REQUIRED:
        message.emit("Todas as gemas! O portão do templo se abriu.")
    else:
        message.emit("Gema coletada: %d/%d" % [gems, GEMS_REQUIRED])


func add_coin(amount: int = 1) -> void:
    coins += amount
    coins_changed.emit(coins)


func set_health(current: float, maximum: float) -> void:
    health_changed.emit(current, maximum)


func set_stamina(current: float, maximum: float) -> void:
    stamina_changed.emit(current, maximum)


func finish(win: bool) -> void:
    if not running:
        return
    running = false
    if win and (best_time <= 0.0 or elapsed < best_time):
        best_time = elapsed
        save_settings()
    if win:
        victory.emit()
    else:
        game_over.emit()


func cycle_quality() -> void:
    quality = (quality + 1) % QUALITY_NAMES.size()
    apply_quality()
    save_settings()


func toggle_fps() -> void:
    fps_cap = 30 if fps_cap == 60 else 60
    apply_quality()
    save_settings()


func apply_quality() -> void:
    var vp: Viewport = get_viewport()
    if vp == null:
        return
    _adaptive_scale = RENDER_SCALES[quality]
    var s: float = _adaptive_scale
    vp.scaling_3d_scale = s
    vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    if quality == 0:
        vp.msaa_3d = Viewport.MSAA_DISABLED
        vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
    else:
        vp.msaa_3d = Viewport.MSAA_2X
        vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
    RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS[quality], true)
    Engine.max_fps = fps_cap


func shadows_enabled() -> bool:
    return quality > 0


func shadow_distance() -> float:
    return SHADOW_DISTANCE[quality]


func veg_factor() -> float:
    return VEG_FACTOR[quality]


func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("video", "settings_version", 2)
    cfg.set_value("video", "quality", quality)
    cfg.set_value("video", "fps_cap", fps_cap)
    cfg.set_value("audio", "sfx", sfx_volume)
    cfg.set_value("audio", "music", music_volume)
    cfg.set_value("progress", "best_time", best_time)
    cfg.save(SETTINGS_PATH)


func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_PATH) != OK:
        return
    var settings_version := int(cfg.get_value("video", "settings_version", 0))
    quality = 2 if settings_version < 2 else clampi(int(cfg.get_value("video", "quality", 2)), 0, QUALITY_NAMES.size() - 1)
    fps_cap = int(cfg.get_value("video", "fps_cap", 60))
    sfx_volume = float(cfg.get_value("audio", "sfx", 0.8))
    music_volume = float(cfg.get_value("audio", "music", 0.5))
    best_time = float(cfg.get_value("progress", "best_time", 0.0))
