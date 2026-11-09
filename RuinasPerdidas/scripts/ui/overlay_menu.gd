class_name OverlayMenu
extends CanvasLayer
## Menus sobrepostos: pausa, vitória e derrota.

var _root: Control


func _ready() -> void:
    layer = 30
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false


func is_open() -> bool:
    return visible


func show_pause() -> void:
    _open("PAUSADO", "", [
        ["Continuar", _resume],
        ["Qualidade: %s" % Game.QUALITY_NAMES[Game.quality], _cycle_quality],
        ["FPS: %d" % Game.fps_cap, _toggle_fps],
        ["Menu principal", _to_menu],
    ])


func show_end(win: bool) -> void:
    var minutes: int = int(Game.elapsed) / 60
    var seconds: int = int(Game.elapsed) % 60
    var stats: String = "Tempo %02d:%02d   Moedas %d   Inimigos %d" % [minutes, seconds, Game.coins, Game.kills]
    var title: String = "VITÓRIA!" if win else "VOCÊ CAIU..."
    _open(title, stats, [
        ["Jogar novamente", _restart],
        ["Menu principal", _to_menu],
    ])
    AudioManager.play_sfx("win" if win else "lose", 0.0)


func toggle_pause() -> void:
    if visible:
        _resume()
    elif Game.running:
        show_pause()


func _open(title: String, subtitle: String, buttons: Array) -> void:
    if _root != null:
        _root.queue_free()
    _root = Control.new()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_root)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.62)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(dim)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 18)
    _root.add_child(box)
    box.set_anchors_preset(Control.PRESET_FULL_RECT)
    var t: Label = UiStyle.label(title, 72, Color(1, 0.9, 0.55))
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(t)
    if subtitle != "":
        var s: Label = UiStyle.label(subtitle, 30)
        s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(s)
    for entry in buttons:
        var b: Button = UiStyle.button(String(entry[0]))
        b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        b.pressed.connect(entry[1])
        box.add_child(b)
    visible = true
    get_tree().paused = true


func _close() -> void:
    visible = false
    get_tree().paused = false


func _resume() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    _close()


func _cycle_quality() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    Game.cycle_quality()
    show_pause()


func _toggle_fps() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    Game.toggle_fps()
    show_pause()


func _restart() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    _close()
    get_tree().reload_current_scene()


func _to_menu() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    _close()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
