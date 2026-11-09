class_name Pickup
extends Area3D
## Moeda ou gema coletável. Configure kind/model_path/model_scale antes de add_child.

enum Kind { COIN, GEM }

var kind: Kind = Kind.COIN
var model_path: String = AssetPaths.COIN
var model_scale := 0.5
var light_color := Color(1.0, 0.8, 0.2)
var value := 1

var _spin: Node3D
var _t := 0.0
var _taken := false


func _ready() -> void:
    collision_layer = 0
    collision_mask = 2
    var shape := SphereShape3D.new()
    shape.radius = 1.8 if kind == Kind.GEM else 1.3
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position.y = 1.0
    add_child(cs)

    _spin = Node3D.new()
    _spin.position.y = 1.0
    add_child(_spin)
    var model: Node3D = Utils.instance_model(model_path)
    model.scale = Vector3.ONE * model_scale
    model.rotation_degrees.x = 90.0
    _spin.add_child(model)

    if kind == Kind.GEM:
        var light := OmniLight3D.new()
        light.light_color = light_color
        light.light_energy = 1.6
        light.omni_range = 5.0
        light.position.y = 1.2
        light.shadow_enabled = false
        add_child(light)
    _t = randf() * TAU
    body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
    _t += delta
    _spin.rotation.y += 2.4 * delta
    _spin.position.y = 1.0 + sin(_t * 3.0) * 0.15


func _on_body_entered(body: Node3D) -> void:
    if _taken or not body.is_in_group("player"):
        return
    _taken = true
    if kind == Kind.GEM:
        Game.add_gem()
        AudioManager.play_sfx("gem")
    else:
        Game.add_coin(value)
        AudioManager.play_sfx("coin", 0.1)
    queue_free()
