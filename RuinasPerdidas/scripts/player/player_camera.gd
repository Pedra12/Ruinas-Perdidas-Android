class_name PlayerCamera
extends Node3D
## Câmera em terceira pessoa com SpringArm (não atravessa paredes).

const SENSITIVITY := 0.0042
const KEY_SPEED := 2.2
const PITCH_MIN := -1.1
const PITCH_MAX := 0.3

var target: Node3D
var touch: TouchControls
var yaw := 0.0
var pitch := -0.32

var _arm: SpringArm3D
var camera: Camera3D


func _ready() -> void:
    top_level = true
    _arm = SpringArm3D.new()
    _arm.spring_length = 5.5
    _arm.collision_mask = 1
    _arm.margin = 0.3
    var sphere := SphereShape3D.new()
    sphere.radius = 0.3
    _arm.shape = sphere
    add_child(_arm)
    camera = Camera3D.new()
    camera.fov = 65.0
    camera.near = 0.1
    camera.far = 260.0
    _arm.add_child(camera)
    camera.current = true


func _process(delta: float) -> void:
    if target == null:
        return
    if touch != null:
        var d: Vector2 = touch.consume_camera()
        yaw -= d.x * SENSITIVITY
        pitch = clampf(pitch - d.y * SENSITIVITY, PITCH_MIN, PITCH_MAX)
    if Input.is_physical_key_pressed(KEY_Q):
        yaw += KEY_SPEED * delta
    if Input.is_physical_key_pressed(KEY_E):
        yaw -= KEY_SPEED * delta
    var goal: Vector3 = target.global_position + Vector3(0.0, 1.5, 0.0)
    global_position = global_position.lerp(goal, 1.0 - exp(-14.0 * delta))
    rotation = Vector3(0.0, yaw, 0.0)
    _arm.rotation.x = pitch
