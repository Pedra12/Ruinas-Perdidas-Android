class_name Chest
extends Node3D
## Baú dourado final. Fica selado até o chefe morrer; ao abrir, vence o jogo.

signal opened

var locked := true

var _lid: Node3D
var _glow: OmniLight3D
var _is_open := false


func _ready() -> void:
    var body := StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    add_child(body)
    var base: Node3D = Utils.instance_model(AssetPaths.CHEST_BASE)
    body.add_child(base)
    Utils.add_box_collider(body, Utils.aabb_in(body, base))

    _lid = Utils.instance_model(AssetPaths.CHEST_LID)
    add_child(_lid)

    _glow = OmniLight3D.new()
    _glow.light_color = Color(1.0, 0.8, 0.3)
    _glow.light_energy = 0.0
    _glow.omni_range = 7.0
    _glow.position.y = 1.5
    add_child(_glow)

    var trigger := Area3D.new()
    trigger.collision_layer = 0
    trigger.collision_mask = 2
    var shape := SphereShape3D.new()
    shape.radius = 3.2
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position.y = 1.0
    trigger.add_child(cs)
    add_child(trigger)
    trigger.body_entered.connect(_on_body_entered)


func unlock() -> void:
    locked = false
    _glow.light_energy = 2.0
    Game.message.emit("O baú dourado foi liberado!")


func _on_body_entered(body: Node3D) -> void:
    if _is_open or not body.is_in_group("player"):
        return
    if locked:
        Game.message.emit("O baú está selado pelo guardião do templo.")
    else:
        _open()


func _open() -> void:
    _is_open = true
    AudioManager.play_sfx("chest_open")
    Game.add_coin(25)
    var tw := create_tween()
    tw.tween_property(_lid, "position:y", 1.6, 0.9)
    tw.parallel().tween_property(_lid, "rotation:z", -1.1, 0.9)
    tw.parallel().tween_property(_glow, "light_energy", 5.0, 0.9)
    tw.tween_interval(0.6)
    tw.tween_callback(func() -> void: opened.emit())
