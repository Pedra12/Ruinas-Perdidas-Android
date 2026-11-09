extends Control
## Menu principal (construído por código).

var _quality_btn: Button
var _fps_btn: Button


func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.09, 0.13, 0.11)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var glow := ColorRect.new()
    glow.color = Color(0.2, 0.45, 0.35, 0.25)
    glow.set_anchors_preset(Control.PRESET_FULL_RECT)
    glow.anchor_top = 0.55
    add_child(glow)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 20)
    add_child(box)
    box.set_anchors_preset(Control.PRESET_FULL_RECT)

    var title: Label = UiStyle.label("RUÍNAS PERDIDAS", 96, Color(0.95, 0.88, 0.6))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)
    var sub: Label = UiStyle.label("Encontre as 3 gemas e derrote o guardião do templo", 30, Color(0.8, 0.9, 0.85))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(sub)
    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 30)
    box.add_child(spacer)

    var play: Button = UiStyle.button("JOGAR", Vector2(460, 96), 42)
    play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    play.pressed.connect(_on_play)
    box.add_child(play)

    _quality_btn = UiStyle.button("", Vector2(460, 80))
    _quality_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _quality_btn.pressed.connect(_on_quality)
    box.add_child(_quality_btn)

    _fps_btn = UiStyle.button("", Vector2(460, 80))
    _fps_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _fps_btn.pressed.connect(_on_fps)
    box.add_child(_fps_btn)

    if Game.best_time > 0.0:
        var best: Label = UiStyle.label("Melhor tempo: %02d:%02d" % [int(Game.best_time) / 60, int(Game.best_time) % 60], 26, Color(1, 0.9, 0.5))
        best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(best)

    _refresh()
    AudioManager.play_music("music_menu")


func _refresh() -> void:
    _quality_btn.text = "Qualidade: %s" % Game.QUALITY_NAMES[Game.quality]
    _fps_btn.text = "Limite de FPS: %d" % Game.fps_cap


func _on_play() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quality() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    Game.cycle_quality()
    _refresh()


func _on_fps() -> void:
    AudioManager.play_sfx("ui_click", 0.0)
    Game.toggle_fps()
    _refresh()
