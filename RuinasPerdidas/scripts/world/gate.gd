class_name Gate
extends Node3D
## Barreira mágica no portão do templo. Abre quando todas as gemas são coletadas.
## O modelo do portão (Walls/Gate.glb) é decorativo; a barreira é um bloco invisível + véu.

const WIDTH := 6.6

var _barrier: StaticBody3D
var _veil: MeshInstance3D
var _is_open := false


func _ready() -> void:
    _barrier = StaticBody3D.new()
    _barrier.collision_layer = 1
    _barrier.collision_mask = 0
    var shape := BoxShape3D.new()
    shape.size = Vector3(WIDTH, 6.0, 0.6)
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position.y = 3.0
    _barrier.add_child(cs)
    add_child(_barrier)

    _veil = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(WIDTH - 1.0, 4.6, 0.15)
    _veil.mesh = box
    _veil.position.y = 2.3
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.3, 0.7, 1.0, 0.35)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _veil.material_override = mat
    _veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_veil)

    var trigger := Area3D.new()
    trigger.collision_layer = 0
    trigger.collision_mask = 2
    var tshape := BoxShape3D.new()
    tshape.size = Vector3(WIDTH, 4.0, 7.0)
    var tcs := CollisionShape3D.new()
    tcs.shape = tshape
    tcs.position.y = 2.0
    trigger.add_child(tcs)
    add_child(trigger)
    trigger.body_entered.connect(_on_trigger)

    Game.gems_changed.connect(_on_gems_changed)
    if Game.gems >= Game.GEMS_REQUIRED:
        _open()


func _on_trigger(body: Node3D) -> void:
    if not _is_open and body.is_in_group("player"):
        Game.message.emit("O portão está selado. Colete %d gemas." % Game.GEMS_REQUIRED)


func _on_gems_changed(count: int) -> void:
    if count >= Game.GEMS_REQUIRED and not _is_open:
        _open()


func _open() -> void:
    _is_open = true
    AudioManager.play_sfx("gate_open")
    _barrier.collision_layer = 0
    var mat := _veil.material_override as StandardMaterial3D
    var tw := create_tween()
    tw.tween_property(mat, "albedo_color:a", 0.0, 1.5)
    tw.tween_callback(_veil.queue_free)
