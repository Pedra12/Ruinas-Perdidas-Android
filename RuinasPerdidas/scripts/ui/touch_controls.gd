class_name TouchControls
extends Control
## Controles de toque: joystick (esquerda), botões (direita) e arrastar para a câmera.
## Também funciona com mouse no PC (emulate_touch_from_mouse=true no project.godot).

signal attack_pressed
signal roll_pressed
signal jump_pressed

const JOY_RADIUS := 120.0
const DEADZONE := 0.12
const CAMERA_SPLIT := 0.45

var move_vec := Vector2.ZERO
var ignore_rects: Array[Rect2] = []
var enabled := true

var _camera_accum := Vector2.ZERO
var _move_finger := -1
var _cam_finger := -1
var _joy_origin := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _buttons: Array[Dictionary] = []


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(_layout)
    _layout()


func _layout() -> void:
    var s: Vector2 = size
    _buttons = [
        {"id": "jump", "label": "PULAR", "center": Vector2(s.x - 150.0, s.y - 190.0), "radius": 70.0, "finger": -1},
    ]
    queue_redraw()


func consume_camera() -> Vector2:
    var d: Vector2 = _camera_accum
    _camera_accum = Vector2.ZERO
    return d


func _ignored(p: Vector2) -> bool:
    for r in ignore_rects:
        if r.has_point(p):
            return true
    return false


func _input(event: InputEvent) -> void:
    if not enabled or not is_visible_in_tree():
        return
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed:
            _on_press(t.index, t.position)
        else:
            _on_release(t.index)
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        _on_drag(d.index, d.position, d.relative)


func _on_press(index: int, pos: Vector2) -> void:
    if _ignored(pos):
        return
    for b in _buttons:
        if b["finger"] == -1 and pos.distance_to(b["center"]) <= float(b["radius"]) * 1.15:
            b["finger"] = index
            _emit_button(String(b["id"]))
            queue_redraw()
            return
    if pos.x < size.x * CAMERA_SPLIT:
        if _move_finger == -1:
            _move_finger = index
            _joy_origin = pos
            _joy_pos = pos
            move_vec = Vector2.ZERO
            queue_redraw()
    elif _cam_finger == -1:
        _cam_finger = index


func _on_release(index: int) -> void:
    if index == _move_finger:
        _move_finger = -1
        move_vec = Vector2.ZERO
    if index == _cam_finger:
        _cam_finger = -1
    for b in _buttons:
        if b["finger"] == index:
            b["finger"] = -1
    queue_redraw()


func _on_drag(index: int, pos: Vector2, rel: Vector2) -> void:
    if index == _move_finger:
        _joy_pos = pos
        var diff: Vector2 = (pos - _joy_origin) / JOY_RADIUS
        if diff.length() < DEADZONE:
            move_vec = Vector2.ZERO
        else:
            move_vec = diff.limit_length(1.0)
        queue_redraw()
    elif index == _cam_finger:
        _camera_accum += rel


func _emit_button(id: String) -> void:
    match id:
        "attack":
            attack_pressed.emit()
        "roll":
            roll_pressed.emit()
        "jump":
            jump_pressed.emit()


func _draw() -> void:
    for b in _buttons:
        var pressed: bool = b["finger"] != -1
        var col := Color(1, 1, 1, 0.38 if pressed else 0.2)
        draw_circle(b["center"], b["radius"], col)
        draw_arc(b["center"], b["radius"], 0.0, TAU, 48, Color(1, 1, 1, 0.6), 3.0, true)
        var font: Font = ThemeDB.fallback_font
        var fs := 22
        var ts: Vector2 = font.get_string_size(String(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
        draw_string(font, b["center"] + Vector2(-ts.x * 0.5, ts.y * 0.3), String(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
    if _move_finger != -1:
        draw_circle(_joy_origin, JOY_RADIUS, Color(1, 1, 1, 0.12))
        draw_arc(_joy_origin, JOY_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 3.0, true)
        var knob: Vector2 = _joy_origin + (_joy_pos - _joy_origin).limit_length(JOY_RADIUS)
        draw_circle(knob, 48.0, Color(1, 1, 1, 0.4))
