class_name Hud
extends CanvasLayer
## HUD: vida, stamina, gemas, moedas, mensagens, barra do chefe e botão de pausa.

signal pause_requested

var touch: TouchControls

var _hp: ProgressBar
var _st: ProgressBar
var _gems: Label
var _coins: Label
var _msg: Label
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _pause_btn: Button
var _msg_tween: Tween


func _ready() -> void:
    layer = 10
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    touch = TouchControls.new()
    touch.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(touch)

    var insets: Vector2 = _safe_insets()
    var m: int = 24

    # Canto superior esquerdo: vida e stamina
    var left := VBoxContainer.new()
    left.add_theme_constant_override("separation", 8)
    left.add_child(UiStyle.label("RUINAS PERDIDAS", 26, Color(0.85, 0.95, 1.0)))
    left.add_child(UiStyle.label("EXPLORACAO LIVRE", 18, Color(0.65, 1.0, 0.75)))
    root.add_child(left)
    left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, m + int(insets.x))

    # Topo central: gemas + barra do chefe
    var center := VBoxContainer.new()
    center.alignment = BoxContainer.ALIGNMENT_BEGIN
    center.add_theme_constant_override("separation", 6)
    _gems = UiStyle.label("MAPA ABERTO", 32, Color(0.6, 1.0, 0.8))
    _gems.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    center.add_child(_gems)
    _boss_box = VBoxContainer.new()
    _boss_box.visible = false
    var boss_label: Label = UiStyle.label("GUARDIÃO DO TEMPLO", 22, Color(1, 0.6, 0.5))
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _boss_box.add_child(boss_label)
    _boss_bar = UiStyle.bar(Color(0.6, 0.1, 0.5), Vector2(520, 24))
    _boss_box.add_child(_boss_bar)
    center.add_child(_boss_box)
    root.add_child(center)
    center.grow_horizontal = Control.GROW_DIRECTION_BOTH
    center.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 16)

    # Canto superior direito: moedas e pausa
    var right := HBoxContainer.new()
    right.add_theme_constant_override("separation", 20)
    _coins = UiStyle.label("" ", 30, Color(1.0, 0.85, 0.3))
    right.add_child(_coins)
    _pause_btn = UiStyle.button("II", Vector2(76, 76), 34)
    _pause_btn.pressed.connect(func() -> void: pause_requested.emit())
    right.add_child(_pause_btn)
    root.add_child(right)
    right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, m + int(insets.y))

    # Mensagem inferior central
    _msg = UiStyle.label("", 34, Color(1, 0.95, 0.8))
    _msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _msg.modulate.a = 0.0
    root.add_child(_msg)
    _msg.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _msg.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 330)

    Game.health_changed.connect(_on_health)
    Game.stamina_changed.connect(_on_stamina)
    Game.gems_changed.connect(_on_gems)
    Game.coins_changed.connect(_on_coins)
    Game.message.connect(show_message)
    _on_gems(Game.gems)
    _on_coins(Game.coins)


func _process(_delta: float) -> void:
    if touch != null and _pause_btn != null:
        touch.ignore_rects = [_pause_btn.get_global_rect()]


## x = recuo esquerdo, y = recuo direito (área segura / notch), em pixels do viewport.
func _safe_insets() -> Vector2:
    var win: Vector2i = DisplayServer.window_get_size()
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    var vs: Vector2 = get_viewport().get_visible_rect().size
    if win.x <= 0 or safe.size.x <= 0:
        return Vector2.ZERO
    var sx: float = vs.x / float(win.x)
    var left: float = maxf(0.0, float(safe.position.x) * sx)
    var right: float = maxf(0.0, float(win.x - safe.end.x) * sx)
    return Vector2(minf(left, 120.0), minf(right, 120.0))


func bind_boss(boss: Enemy) -> void:
    boss.hp_changed.connect(_on_boss_hp)
    boss.died.connect(func(_e: Enemy) -> void: _boss_box.visible = false)


func set_boss_visible(v: bool) -> void:
    _boss_box.visible = v


func show_message(text: String) -> void:
    _msg.text = text
    if _msg_tween != null and _msg_tween.is_valid():
        _msg_tween.kill()
    _msg.modulate.a = 1.0
    _msg_tween = create_tween()
    _msg_tween.tween_interval(2.4)
    _msg_tween.tween_property(_msg, "modulate:a", 0.0, 0.6)


func _on_health(cur: float, mx: float) -> void:
    _hp.value = cur / maxf(mx, 1.0)


func _on_stamina(cur: float, mx: float) -> void:
    _st.value = cur / maxf(mx, 1.0)


func _on_gems(count: int) -> void:
    _gems.text = "GEMAS %d/%d" % [count, Game.GEMS_REQUIRED]


func _on_coins(count: int) -> void:
    _coins.text = "MOEDAS %d" % count


func _on_boss_hp(cur: float, mx: float) -> void:
    _boss_bar.value = cur / maxf(mx, 1.0)
