class_name Enemy
extends CharacterBody3D
## Esqueleto inimigo (Skely, SkelyDraugr, SkelyPoison) e chefe (is_boss = true).
## Configure as propriedades ANTES de adicionar à cena.

signal died(enemy: Enemy)
signal hp_changed(current: float, maximum: float)

enum S { IDLE, CHASE, ATTACK, HURT, DEAD }

const GRAVITY := 22.0
const SLEEP_DISTANCE := 75.0
const MODEL_YAW_OFFSET := 0.0  # ajuste (ex.: PI) se o modelo olhar para trás

@export var model_path: String = AssetPaths.SKELY
@export var max_hp := 3.0
@export var move_speed := 3.0
@export var damage := 10.0
@export var height := 1.9
@export var body_radius := 0.5
@export var detect_range := 18.0
@export var attack_range := 1.9
@export var is_boss := false

var hp := 3.0
var target: Node3D
var state: S = S.IDLE

var _model: Node3D
var _anim: AnimationPlayer
var _t := 0.0
var _cooldown := 0.0
var _hit_done := false
var _attack_len := 1.0
var _check := 0.0


func _ready() -> void:
    add_to_group("enemies")
    hp = max_hp
    collision_layer = 4
    collision_mask = 1 | 2 | 4
    var shape := CapsuleShape3D.new()
    shape.radius = body_radius
    shape.height = height
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position.y = height * 0.5
    add_child(cs)

    _model = Utils.instance_model(model_path)
    add_child(_model)
    Utils.fit_height(self, _model, height)
    _anim = Utils.find_anim_player(_model)
    Utils.force_loops(_anim, ["Idle", "Run"])
    _play("Idle")
    hp_changed.emit(hp, max_hp)


func is_dead() -> bool:
    return state == S.DEAD


func _physics_process(delta: float) -> void:
    if state == S.DEAD:
        return
    if target == null or not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player") as Node3D
        if target == null:
            return
    var to: Vector3 = target.global_position - global_position
    to.y = 0.0
    var dist: float = to.length()

    if dist > SLEEP_DISTANCE:
        velocity = Vector3.ZERO
        return

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    _t += delta
    _cooldown = maxf(0.0, _cooldown - delta)
    var player_dead: bool = bool(target.call("is_dead"))

    match state:
        S.IDLE:
            velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
            if not player_dead and dist < detect_range:
                _enter_chase()
        S.CHASE:
            if player_dead or dist > detect_range * 1.8:
                state = S.IDLE
                _play("Idle")
            elif dist <= attack_range and _cooldown <= 0.0:
                _start_attack(to)
            else:
                _face(to, delta)
                if dist > attack_range * 0.8:
                    var dir: Vector3 = to.normalized()
                    velocity.x = dir.x * move_speed
                    velocity.z = dir.z * move_speed
                    _play("Run")
                else:
                    velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
                    velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
                    _play("Idle")
        S.ATTACK:
            velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)
            if not _hit_done and _t >= _attack_len * 0.45:
                _hit_done = true
                if dist <= attack_range + 0.9:
                    target.call("hurt", damage, global_position)
            if _t >= _attack_len:
                state = S.CHASE
                _cooldown = 0.5 if is_boss else 0.9
        S.HURT:
            velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
            if _t >= 0.4:
                state = S.CHASE

    move_and_slide()


func _enter_chase() -> void:
    state = S.CHASE
    _t = 0.0
    if is_boss:
        AudioManager.play_sfx("boss_roar", 0.02)
        _play("Scream", 1.0, 0.1, true)
        _cooldown = 1.2
    else:
        AudioManager.play_sfx("enemy_alert", 0.1, -4.0)


func _face(to: Vector3, delta: float) -> void:
    if to.length() < 0.01:
        return
    var yaw: float = atan2(to.x, to.z) + MODEL_YAW_OFFSET
    _model.rotation.y = lerp_angle(_model.rotation.y, yaw, clampf(10.0 * delta, 0.0, 1.0))


func _start_attack(to: Vector3) -> void:
    state = S.ATTACK
    _t = 0.0
    _hit_done = false
    _face(to, 1.0)
    _attack_len = 1.0
    if _anim != null and _anim.has_animation("Attack"):
        _attack_len = _anim.get_animation("Attack").length
    _play("Attack", 1.0, 0.08, true)


## Chamado pelo jogador.
func take_damage(amount: float, from: Vector3) -> void:
    if state == S.DEAD:
        return
    hp = maxf(0.0, hp - amount)
    hp_changed.emit(hp, max_hp)
    var away: Vector3 = global_position - from
    away.y = 0.0
    if away.length() > 0.01:
        away = away.normalized()
    velocity.x = away.x * (2.0 if is_boss else 5.0)
    velocity.z = away.z * (2.0 if is_boss else 5.0)
    if hp <= 0.0:
        _die()
        return
    if state == S.IDLE:
        _enter_chase()
    if not is_boss:
        state = S.HURT
        _t = 0.0
        _play("Hit", 1.0, 0.05, true)


func _die() -> void:
    state = S.DEAD
    collision_layer = 0
    collision_mask = 0
    remove_from_group("enemies")
    _play("Death", 1.0, 0.08, true)
    AudioManager.play_sfx("enemy_die")
    Game.kills += 1
    died.emit(self)
    get_tree().create_timer(7.0).timeout.connect(queue_free)


func _play(anim_name: String, speed: float = 1.0, blend: float = 0.15, restart: bool = false) -> void:
    if _anim == null or not _anim.has_animation(anim_name):
        return
    if restart:
        _anim.stop()
    elif _anim.current_animation == anim_name and _anim.is_playing():
        return
    _anim.play(anim_name, blend, speed)
