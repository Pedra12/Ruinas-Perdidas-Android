class_name Player
extends CharacterBody3D
## Jogador: movimento, rolar, pular, ataque de espada, vida e stamina.
## Animações da Universal Animation Library (nomes: Idle_Loop, Jog_Fwd_Loop...).

enum State { MOVE, ATTACK, ROLL, HURT, DEAD }

const JOG_SPEED := 5.0
const WALK_SPEED := 2.4
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 22.0
const ROLL_SPEED := 9.5
const ROLL_TIME := 0.6
const ATTACK_RANGE := 2.8
const ATTACK_ARC_DEG := 85.0
const ATTACK_ANIM_SPEED := 1.4
const MAX_HEALTH := 100.0
const MAX_STAMINA := 100.0
const HEIGHT := 1.8

var touch: TouchControls
var cam: PlayerCamera
var health := MAX_HEALTH
var stamina := MAX_STAMINA
var state: State = State.MOVE

var _model: Node3D
var _anim: AnimationPlayer
var _t := 0.0
var _facing := 0.0
var _hit_done := false
var _attack_len := 0.6
var _invuln := 0.0
var _regen_delay := 0.0
var _roll_dir := Vector3.ZERO
var _step_timer := 0.0
var _buf_attack := 0.0
var _buf_roll := 0.0
var _buf_jump := 0.0
var _last_stamina_sent := -1.0


func _ready() -> void:
    add_to_group("player")
    collision_layer = 2
    collision_mask = 1 | 4
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = HEIGHT
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position.y = HEIGHT * 0.5
    add_child(cs)

    _model = Utils.instance_model(AssetPaths.PLAYER)
    add_child(_model)
    Utils.fit_height(self, _model, HEIGHT)
    _anim = Utils.find_anim_player(_model)
    Utils.force_loops(_anim, ["Idle", "Walk", "Jog_Fwd", "Sprint", "Jump"])
    _play("Idle")
    Game.set_health(health, MAX_HEALTH)
    Game.set_stamina(stamina, MAX_STAMINA)
    if touch != null:
        touch.attack_pressed.connect(request_attack)
        touch.roll_pressed.connect(request_roll)
        touch.jump_pressed.connect(request_jump)


func is_dead() -> bool:
    return state == State.DEAD


func request_attack() -> void:
    _buf_attack = 0.25


func request_roll() -> void:
    _buf_roll = 0.25


func request_jump() -> void:
    _buf_jump = 0.2


func _unhandled_input(event: InputEvent) -> void:
    var k := event as InputEventKey
    if k != null and k.pressed and not k.echo:
        match k.physical_keycode:
            KEY_J, KEY_F:
                request_attack()
            KEY_K, KEY_SHIFT:
                request_roll()
            KEY_SPACE:
                request_jump()


func _move_input() -> Vector2:
    var v := Vector2.ZERO
    if touch != null:
        v = touch.move_vec
    if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
        v.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
        v.x += 1.0
    if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
        v.y -= 1.0
    if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
        v.y += 1.0
    return v.limit_length(1.0)


func _physics_process(delta: float) -> void:
    _invuln = maxf(0.0, _invuln - delta)
    _buf_attack = maxf(0.0, _buf_attack - delta)
    _buf_roll = maxf(0.0, _buf_roll - delta)
    _buf_jump = maxf(0.0, _buf_jump - delta)
    _t += delta

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    match state:
        State.MOVE:
            _state_move(delta)
        State.ATTACK:
            _state_attack(delta)
        State.ROLL:
            _state_roll(delta)
        State.HURT:
            _state_hurt(delta)
        State.DEAD:
            velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

    move_and_slide()
    _regen(delta)


func _cam_dir(input: Vector2) -> Vector3:
    var yaw: float = cam.yaw if cam != null else 0.0
    return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)


func _state_move(delta: float) -> void:
    var input: Vector2 = _move_input()
    var mag: float = input.length()
    var dir: Vector3 = _cam_dir(input)
    var sprint: bool = mag > 0.92 and stamina > 5.0 and is_on_floor()
    var speed: float = JOG_SPEED
    if sprint:
        speed = SPRINT_SPEED
    elif mag < 0.5:
        speed = WALK_SPEED
    var target_vel := Vector3.ZERO
    if mag > 0.05:
        target_vel = dir.normalized() * speed
        _facing = lerp_angle(_facing, atan2(dir.x, dir.z), clampf(16.0 * delta, 0.0, 1.0))
        _model.rotation.y = _facing
    velocity.x = move_toward(velocity.x, target_vel.x, 45.0 * delta)
    velocity.z = move_toward(velocity.z, target_vel.z, 45.0 * delta)

    if sprint:
        stamina = maxf(0.0, stamina - 14.0 * delta)
        _regen_delay = 0.6

    if _buf_jump > 0.0 and is_on_floor():
        velocity.y = JUMP_VELOCITY
        _buf_jump = 0.0
        AudioManager.play_sfx("jump")
        _play("Jump_Start", 1.0, 0.05, true)
    elif _buf_roll > 0.0 and stamina >= 25.0 and is_on_floor():
        _start_roll(dir if mag > 0.05 else Vector3(sin(_facing), 0.0, cos(_facing)))
        return
    elif _buf_attack > 0.0 and stamina >= 12.0 and is_on_floor():
        _start_attack()
        return

    if not is_on_floor():
        if velocity.y > 1.0 and _anim != null and _anim.current_animation == "Jump_Start":
            pass
        else:
            _play("Jump")
    elif mag > 0.05:
        if sprint:
            _play("Sprint")
        elif mag < 0.90:
            _play("Walk")
        else:
            _play("Jog_Fwd")
        _step_timer -= delta
        if _step_timer <= 0.0:
            AudioManager.play_sfx("footstep", 0.12, -6.0)
            _step_timer = 0.28 if sprint else 0.38
    else:
        _play("Idle")


func _anim_len(anim_name: String, fallback: float) -> float:
    if _anim != null and _anim.has_animation(anim_name):
        return _anim.get_animation(anim_name).length
    return fallback


func _start_attack() -> void:
    state = State.ATTACK
    _t = 0.0
    _hit_done = false
    _buf_attack = 0.0
    stamina -= 12.0
    _regen_delay = 0.8
    _attack_len = _anim_len("Sword_Attack", 0.8) / ATTACK_ANIM_SPEED
    _play("Sword_Attack", ATTACK_ANIM_SPEED, 0.05, true)
    var nearest := _nearest_enemy(4.5)
    if nearest != null:
        var to: Vector3 = nearest.global_position - global_position
        _facing = atan2(to.x, to.z)
        _model.rotation.y = _facing
    var fwd := Vector3(sin(_facing), 0.0, cos(_facing))
    velocity.x = fwd.x * 2.5
    velocity.z = fwd.z * 2.5


func _state_attack(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
    if not _hit_done and _t >= _attack_len * 0.4:
        _hit_done = true
        _apply_hit()
    if _t >= _attack_len:
        state = State.MOVE


func _nearest_enemy(max_dist: float) -> Node3D:
    var best: Node3D = null
    var best_d := max_dist
    for e in get_tree().get_nodes_in_group("enemies"):
        var n := e as Node3D
        if n == null or n.call("is_dead"):
            continue
        var d: float = n.global_position.distance_to(global_position)
        if d < best_d:
            best_d = d
            best = n
    return best


func _apply_hit() -> void:
    AudioManager.play_sfx("swing")
    var fwd := Vector3(sin(_facing), 0.0, cos(_facing))
    for e in get_tree().get_nodes_in_group("enemies"):
        var n := e as Node3D
        if n == null or n.call("is_dead"):
            continue
        var to: Vector3 = n.global_position - global_position
        to.y = 0.0
        var d: float = to.length()
        var reach: float = ATTACK_RANGE + float(n.get("body_radius"))
        if d > reach:
            continue
        if d > 0.01 and rad_to_deg(fwd.angle_to(to.normalized())) > ATTACK_ARC_DEG:
            continue
        n.call("take_damage", 1.0, global_position)
        AudioManager.play_sfx("hit")


func _start_roll(dir: Vector3) -> void:
    state = State.ROLL
    _t = 0.0
    _buf_roll = 0.0
    stamina -= 25.0
    _regen_delay = 0.9
    _roll_dir = dir.normalized()
    _facing = atan2(_roll_dir.x, _roll_dir.z)
    _model.rotation.y = _facing
    _invuln = ROLL_TIME
    var len_roll: float = _anim_len("Roll", ROLL_TIME)
    _play("Roll", len_roll / ROLL_TIME, 0.05, true)
    AudioManager.play_sfx("roll")


func _state_roll(_delta: float) -> void:
    velocity.x = _roll_dir.x * ROLL_SPEED
    velocity.z = _roll_dir.z * ROLL_SPEED
    if _t >= ROLL_TIME:
        state = State.MOVE


func _state_hurt(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
    if _t >= 0.4:
        state = State.MOVE


## Chamado pelos inimigos.
func hurt(amount: float, from: Vector3) -> void:
    if state == State.DEAD or state == State.ROLL or _invuln > 0.0:
        return
    health = maxf(0.0, health - amount)
    Game.set_health(health, MAX_HEALTH)
    AudioManager.play_sfx("player_hurt")
    if health <= 0.0:
        _die()
        return
    state = State.HURT
    _t = 0.0
    _invuln = 0.9
    var away: Vector3 = global_position - from
    away.y = 0.0
    if away.length() > 0.01:
        away = away.normalized()
    velocity.x = away.x * 6.0
    velocity.z = away.z * 6.0
    _play("Hit_Chest", 1.0, 0.05, true)


func heal(amount: float) -> void:
    health = minf(MAX_HEALTH, health + amount)
    Game.set_health(health, MAX_HEALTH)


func _die() -> void:
    state = State.DEAD
    _play("Death01", 1.0, 0.1, true)
    get_tree().create_timer(2.4).timeout.connect(Game.finish.bind(false))


func _regen(delta: float) -> void:
    if state == State.DEAD:
        return
    _regen_delay = maxf(0.0, _regen_delay - delta)
    if _regen_delay <= 0.0 and stamina < MAX_STAMINA:
        stamina = minf(MAX_STAMINA, stamina + 22.0 * delta)
    stamina = clampf(stamina, 0.0, MAX_STAMINA)
    if absf(stamina - _last_stamina_sent) >= 0.5:
        _last_stamina_sent = stamina
        Game.set_stamina(stamina, MAX_STAMINA)


func _play(anim_name: String, speed: float = 1.0, blend: float = 0.15, restart: bool = false) -> void:
    if _anim == null or not _anim.has_animation(anim_name):
        return
    if restart:
        _anim.stop()
    elif _anim.current_animation == anim_name and _anim.is_playing():
        return
    _anim.play(anim_name, blend, speed)
