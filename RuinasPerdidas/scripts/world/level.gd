extends Node3D
## Nível único: floresta -> ruínas -> pátio do templo (chefe + baú).
## Todo o mundo é montado por código usando os assets em res://assets.
## Orçamento mobile: ~150 draw calls, MultiMesh em cenários repetidos, 1 luz com sombra.

const WORLD := 100.0
const START_POS := Vector3(0.0, 0.3, 70.0)
const BOSS_POS := Vector3(0.0, 0.0, -46.0)
const CHEST_POS := Vector3(0.0, 0.0, -57.0)
const GATE_POS := Vector3(0.0, 0.0, -25.0)

const GEM_SPOTS := [
    {"pos": Vector3(-22.0, 0.0, 45.0), "model": AssetPaths.GEM_EMERALD, "color": Color(0.2, 1.0, 0.5)},
    {"pos": Vector3(24.0, 0.0, 2.0), "model": AssetPaths.GEM_RUBY, "color": Color(1.0, 0.25, 0.25)},
    {"pos": Vector3(-28.0, 0.0, -8.0), "model": AssetPaths.GEM_AMETHYST, "color": Color(0.7, 0.4, 1.0)},
]

# [arquivo, posição, rotação Y em graus] — zona de ruínas (meio do mapa)
const RUIN_PIECES := [
    ["Walls/WallBrokenMD.glb", Vector3(-14.0, 0.0, 12.0), 15.0],
    ["Walls/WallNormalMD.glb", Vector3(12.0, 0.0, 16.0), -30.0],
    ["Walls/WallBrokenXl.glb", Vector3(-6.0, 0.0, -6.0), 80.0],
    ["Walls/WallEnd.glb", Vector3(16.0, 0.0, -8.0), 110.0],
    ["Walls/WallBrokenXS.glb", Vector3(4.0, 0.0, 8.0), 0.0],
    ["Pillars/PillarRoundCut.glb", Vector3(8.0, 0.0, 6.0), 0.0],
    ["Pillars/PillarSquareCut.glb", Vector3(-12.0, 0.0, -12.0), 0.0],
    ["Pillars/PillarRound.glb", Vector3(18.0, 0.0, -14.0), 0.0],
    ["Pillars/PillarSquare.glb", Vector3(-20.0, 0.0, 6.0), 0.0],
    ["Blocks/BlockMossMD.glb", Vector3(30.0, 0.0, 14.0), 20.0],
    ["Blocks/BlockNormalXL.glb", Vector3(-32.0, 0.0, 14.0), 0.0],
    ["Blocks/BlockCrackMD.glb", Vector3(-4.0, 0.0, 20.0), 35.0],
    ["Blocks/BlockMossXL.glb", Vector3(34.0, 0.0, -12.0), 0.0],
    ["Accessories/Vase.glb", Vector3(3.0, 0.0, 12.0), 0.0],
    ["Accessories/Vase.glb", Vector3(-9.0, 0.0, 2.0), 40.0],
    ["Accessories/Skull.glb", Vector3(10.0, 0.0, -3.0), 90.0],
]

# Vegetação: [arquivo, quantidade(Alta), escala mín, escala máx, sombra, dist. visível, grande?, colisão]
const VEGETATION := [
    ["CommonTree_1.gltf", 34, 1.0, 1.5, true, 95.0, true, true],
    ["CommonTree_3.gltf", 28, 1.0, 1.5, true, 95.0, true, true],
    ["CommonTree_5.gltf", 24, 1.0, 1.5, true, 95.0, true, true],
    ["DeadTree_1.gltf", 8, 0.9, 1.2, true, 95.0, true, true],
    ["Bush_Common.gltf", 70, 1.0, 1.7, false, 60.0, false, false],
    ["Bush_Common_Flowers.gltf", 40, 1.0, 1.6, false, 60.0, false, false],
    ["Grass_Common_Tall.gltf", 900, 0.6, 1.1, false, 42.0, false, false],
    ["Grass_Wispy_Short.gltf", 700, 0.6, 1.1, false, 42.0, false, false],
    ["Flower_3_Group.gltf", 120, 0.8, 1.3, false, 40.0, false, false],
    ["Flower_4_Group.gltf", 120, 0.8, 1.3, false, 40.0, false, false],
    ["Fern_1.gltf", 60, 0.18, 0.3, false, 50.0, false, false],
    ["Mushroom_Common.gltf", 50, 1.0, 1.8, false, 35.0, false, false],
    ["Pebble_Round_1.gltf", 70, 1.0, 2.0, false, 35.0, false, false],
]

const ENEMY_KINDS := {
    "skely": {"path": AssetPaths.SKELY, "hp": 3.0, "speed": 3.0, "damage": 10.0},
    "poison": {"path": AssetPaths.SKELY_POISON, "hp": 4.0, "speed": 3.4, "damage": 13.0},
    "draugr": {"path": AssetPaths.SKELY_DRAUGR, "hp": 5.0, "speed": 3.2, "damage": 16.0},
}

# [tipo, posição]
const ENEMY_SPAWNS := [
    ["skely", Vector3(-17.0, 0.0, 40.0)],
    ["skely", Vector3(-27.0, 0.0, 49.0)],
    ["skely", Vector3(2.0, 0.0, 30.0)],
    ["skely", Vector3(10.0, 0.0, 18.0)],
    ["poison", Vector3(20.0, 0.0, 6.0)],
    ["poison", Vector3(29.0, 0.0, -1.0)],
    ["poison", Vector3(22.0, 0.0, -5.0)],
    ["skely", Vector3(-8.0, 0.0, 0.0)],
    ["draugr", Vector3(-24.0, 0.0, -4.0)],
    ["draugr", Vector3(-32.0, 0.0, -10.0)],
    ["draugr", Vector3(-26.0, 0.0, -14.0)],
    ["draugr", Vector3(-10.0, 0.0, -36.0)],
    ["draugr", Vector3(10.0, 0.0, -36.0)],
]

var player: Player
var cam: PlayerCamera
var hud: Hud
var overlay: OverlayMenu
var boss: Enemy
var chest: Chest

var _props_root: Node3D
var _keep_clear: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()
var _music_timer := 0.0


func _ready() -> void:
    _rng.seed = 20260611
    get_tree().paused = false
    Game.reset_run()
    Game.apply_quality()

    _props_root = Node3D.new()
    _props_root.name = "Props"
    add_child(_props_root)

    for g in GEM_SPOTS:
        _keep_clear.append(g["pos"])
    _keep_clear.append(START_POS)
    _keep_clear.append(BOSS_POS)

    _build_environment()
    _build_ground()
    _build_courtyard()
    _build_ruins()
    _build_vegetation()
    _spawn_player()
    _build_hud()
    _spawn_pickups()
    _spawn_enemies()
    _spawn_boss_and_chest()

    Game.victory.connect(_on_end.bind(true))
    Game.game_over.connect(_on_end.bind(false))
    AudioManager.play_music("music_game")
    hud.show_message("Encontre 3 gemas para abrir o portão do templo")


func _process(delta: float) -> void:
    if Game.running:
        Game.elapsed += delta
    _music_timer -= delta
    if _music_timer <= 0.0:
        _music_timer = 0.5
        _update_music()


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST and overlay != null:
        overlay.toggle_pause()


func _update_music() -> void:
    if boss == null or boss.is_dead() or player == null:
        return
    var near: bool = boss.global_position.distance_to(player.global_position) < 28.0
    hud.set_boss_visible(near)
    AudioManager.play_music("music_boss" if near else "music_game")


# ---------------------------------------------------------------- ambiente

func _build_environment() -> void:
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.25, 0.5, 0.85)
    sky_mat.sky_horizon_color = Color(0.7, 0.82, 0.9)
    sky_mat.ground_horizon_color = Color(0.6, 0.7, 0.65)
    sky_mat.ground_bottom_color = Color(0.25, 0.32, 0.25)
    var sky := Sky.new()
    sky.sky_material = sky_mat
    sky.radiance_size = Sky.RADIANCE_SIZE_64
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 1.0
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color(0.48, 0.58, 0.52)
    env.fog_density = 0.0035
    env.fog_sky_affect = 0.2
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
    sun.light_color = Color(1.0, 0.95, 0.85)
    sun.light_energy = 1.25
    sun.shadow_enabled = Game.shadows_enabled()
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    sun.directional_shadow_max_distance = maxf(Game.shadow_distance(), 10.0)
    sun.shadow_bias = 0.06
    sun.shadow_normal_bias = 1.0
    add_child(sun)


func _build_ground() -> void:
    var body := StaticBody3D.new()
    body.name = "Ground"
    body.collision_layer = 1
    body.collision_mask = 0
    var shape := BoxShape3D.new()
    shape.size = Vector3(WORLD * 2.0, 2.0, WORLD * 2.0)
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position.y = -1.0
    body.add_child(cs)
    add_child(body)

    body.add_child(_flat_quad(Vector2(WORLD * 2.0, WORLD * 2.0), Vector3.ZERO, Color(0.3, 0.48, 0.22)))
    # Trilha de terra do início até o portão e dentro do pátio
    body.add_child(_flat_quad(Vector2(6.0, 96.0), Vector3(0.0, 0.06, 22.0), Color(0.45, 0.36, 0.24)))
    body.add_child(_flat_quad(Vector2(46.0, 40.0), Vector3(0.0, 0.05, -45.0), Color(0.5, 0.46, 0.38)))

    # Limites invisíveis do mapa
    var limits: Array[Array] = [
        [Vector3(0.0, 10.0, WORLD), Vector3(WORLD * 2.0, 20.0, 2.0)],
        [Vector3(0.0, 10.0, -WORLD), Vector3(WORLD * 2.0, 20.0, 2.0)],
        [Vector3(WORLD, 10.0, 0.0), Vector3(2.0, 20.0, WORLD * 2.0)],
        [Vector3(-WORLD, 10.0, 0.0), Vector3(2.0, 20.0, WORLD * 2.0)],
    ]
    for l in limits:
        var wall := StaticBody3D.new()
        wall.collision_layer = 1
        wall.collision_mask = 0
        wall.position = l[0]
        var ws := BoxShape3D.new()
        ws.size = l[1]
        var wcs := CollisionShape3D.new()
        wcs.shape = ws
        wall.add_child(wcs)
        add_child(wall)


func _flat_quad(size: Vector2, pos: Vector3, color: Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = size
    mi.mesh = plane
    mi.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 1.0
    mi.material_override = mat
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return mi


# ---------------------------------------------------------------- props

## Instancia um modelo com colisão em caixa (AABB) opcional.
func _prop(path: String, pos: Vector3, yaw_deg: float = 0.0, s: float = 1.0, collide: bool = true) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    body.position = pos
    body.rotation_degrees.y = yaw_deg
    _props_root.add_child(body)
    var model: Node3D = Utils.instance_model(path)
    model.scale = Vector3.ONE * s
    body.add_child(model)
    if collide:
        Utils.add_box_collider(body, Utils.aabb_in(body, model))
    return body


func _build_courtyard() -> void:
    var r: String = AssetPaths.RUINS
    # Muro sul (com portão no centro, x = 0)
    var xs: Array[float] = [-19.8, -13.2, -6.6, 6.6, 13.2, 19.8]
    for i in xs.size():
        var file: String = "Walls/WallNormalXL.glb" if i % 2 == 0 else "Walls/WallBrokenXl.glb"
        _prop(r + file, Vector3(xs[i], 0.0, GATE_POS.z), 90.0)
    _prop(AssetPaths.GATE, GATE_POS, 90.0, 1.0, false)
    var gate := Gate.new()
    gate.position = GATE_POS
    add_child(gate)

    # Muro norte
    var nx: Array[float] = [-19.8, -13.2, -6.6, 0.0, 6.6, 13.2, 19.8]
    for x in nx:
        _prop(r + "Walls/WallNormalMD.glb", Vector3(x, 0.0, -65.0), 90.0)
    # Muros oeste e leste
    for i in 6:
        var z: float = -28.3 - 6.6 * float(i)
        var file2: String = "Walls/WallNormalMD.glb" if i % 3 != 1 else "Walls/WallBrokenMD.glb"
        _prop(r + file2, Vector3(-23.1, 0.0, z), 0.0)
        _prop(r + file2, Vector3(23.1, 0.0, z), 0.0)
    # Pilares de canto e internos
    for cx in [-23.1, 23.1]:
        _prop(r + "Pillars/PillarSquare.glb", Vector3(cx, 0.0, -25.0))
        _prop(r + "Pillars/PillarSquare.glb", Vector3(cx, 0.0, -65.0))
    for px in [-10.0, 10.0]:
        _prop(r + "Pillars/PillarRound.glb", Vector3(px, 0.0, -36.0))
        _prop(r + "Pillars/PillarRound.glb", Vector3(px, 0.0, -54.0))
    _prop(AssetPaths.ALTAR, Vector3(0.0, 0.0, -62.0), 0.0, 1.8)
    _prop(r + "Accessories/WallLight.glb", Vector3(-4.0, 0.0, -62.0), 0.0, 1.0, false)


func _build_ruins() -> void:
    for piece in RUIN_PIECES:
        _prop(AssetPaths.RUINS + String(piece[0]), piece[1], float(piece[2]))


# ---------------------------------------------------------------- vegetação

func _is_free(p: Vector3, big: bool) -> bool:
    if absf(p.x) < 4.5 and p.z > -26.0 and p.z < 74.0:
        return false  # trilha
    if absf(p.x) < 27.0 and p.z < -20.0 and p.z > -70.0:
        return false  # pátio do templo
    if Vector2(p.x - START_POS.x, p.z - START_POS.z).length() < 8.0:
        return false
    for k in _keep_clear:
        if Vector2(p.x - k.x, p.z - k.z).length() < 5.0:
            return false
    if big and absf(p.x) < 42.0 and p.z > -22.0 and p.z < 26.0:
        return false  # zona de ruínas fica mais aberta
    return true


func _random_spot(big: bool) -> Vector3:
    for i in 14:
        var p := Vector3(_rng.randf_range(-WORLD + 5.0, WORLD - 5.0), 0.0, _rng.randf_range(-WORLD + 5.0, WORLD - 5.0))
        if _is_free(p, big):
            return p
    return Vector3(1.0e9, 0.0, 1.0e9)


func _build_vegetation() -> void:
    var tree_body := StaticBody3D.new()
    tree_body.name = "TreeColliders"
    tree_body.collision_layer = 1
    tree_body.collision_mask = 0
    add_child(tree_body)
    var trunk := CylinderShape3D.new()
    trunk.radius = 0.5
    trunk.height = 4.0

    var factor: float = Game.veg_factor()
    for v in VEGETATION:
        var packed: PackedScene = Utils.load_packed(AssetPaths.NATURE + String(v[0]))
        if packed == null:
            continue
        var inst: Node = packed.instantiate()
        var mesh: Mesh = Utils.first_mesh(inst)
        inst.free()
        if mesh == null:
            continue
        var count: int = int(float(v[1]) * factor)
        var smin: float = float(v[2])
        var smax: float = float(v[3])
        var big: bool = bool(v[6])
        var with_col: bool = bool(v[7])
        var xforms: Array[Transform3D] = []
        for i in count:
            var p: Vector3 = _random_spot(big)
            if p.x > 1.0e8:
                continue
            var s: float = _rng.randf_range(smin, smax)
            var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
            xforms.append(Transform3D(basis, p))
            if with_col:
                var cs := CollisionShape3D.new()
                cs.shape = trunk
                cs.position = Vector3(p.x, 2.0, p.z)
                tree_body.add_child(cs)
        var cell: float = 100.0
        _scatter(mesh, xforms, cell, float(v[5]), bool(v[4]))


## Cria MultiMeshes em "células" espaciais para permitir culling por distância.
func _scatter(mesh: Mesh, xforms: Array[Transform3D], cell: float, vis_end: float, cast_shadow: bool) -> void:
    var cells: Dictionary = {}
    for t in xforms:
        var key := Vector2i(floori(t.origin.x / cell), floori(t.origin.z / cell))
        if not cells.has(key):
            cells[key] = []
        cells[key].append(t)
    for key in cells:
        var list: Array = cells[key]
        var k: Vector2i = key
        var center := Vector3((float(k.x) + 0.5) * cell, 0.0, (float(k.y) + 0.5) * cell)
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = mesh
        mm.instance_count = list.size()
        for i in list.size():
            var t: Transform3D = list[i]
            t.origin -= center
            mm.set_instance_transform(i, t)
        var mmi := MultiMeshInstance3D.new()
        mmi.multimesh = mm
        mmi.position = center
        mmi.visibility_range_end = vis_end
        mmi.visibility_range_end_margin = 6.0
        mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (cast_shadow and Game.shadows_enabled()) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(mmi)


# ---------------------------------------------------------------- jogador e UI

func _spawn_player() -> void:
    cam = PlayerCamera.new()
    add_child(cam)
    player = Player.new()
    player.position = START_POS
    player.cam = cam
    cam.target = player
    cam.global_position = START_POS + Vector3(0.0, 1.5, 0.0)


func _build_hud() -> void:
    hud = Hud.new()
    add_child(hud)
    overlay = OverlayMenu.new()
    add_child(overlay)
    hud.pause_requested.connect(overlay.toggle_pause)
    # O jogador precisa do TouchControls antes de entrar na árvore (_ready conecta sinais).
    cam.touch = hud.touch
    player.touch = hud.touch
    add_child(player)


# ---------------------------------------------------------------- coletáveis e inimigos

func _spawn_pickups() -> void:
    for g in GEM_SPOTS:
        var gem := Pickup.new()
        gem.kind = Pickup.Kind.GEM
        gem.model_path = String(g["model"])
        gem.model_scale = 1.0
        gem.light_color = g["color"]
        gem.position = g["pos"]
        add_child(gem)
    for i in 18:
        var p: Vector3 = _random_spot(false)
        if p.x > 1.0e8 or p.z < -22.0:
            continue
        var coin := Pickup.new()
        coin.kind = Pickup.Kind.COIN
        coin.model_path = AssetPaths.COIN
        coin.model_scale = 0.45
        coin.position = p
        add_child(coin)


func _make_enemy(kind: String, pos: Vector3) -> Enemy:
    var cfg: Dictionary = ENEMY_KINDS[kind]
    var e := Enemy.new()
    e.model_path = String(cfg["path"])
    e.max_hp = float(cfg["hp"])
    e.move_speed = float(cfg["speed"])
    e.damage = float(cfg["damage"])
    e.position = pos
    e.target = player
    add_child(e)
    return e


func _spawn_enemies() -> void:
    for s in ENEMY_SPAWNS:
        var e: Enemy = _make_enemy(String(s[0]), s[1])
        e.died.connect(_on_enemy_died)


func _spawn_boss_and_chest() -> void:
    boss = Enemy.new()
    boss.model_path = AssetPaths.SKELY_DRAUGR
    boss.is_boss = true
    boss.max_hp = 14.0
    boss.move_speed = 2.8
    boss.damage = 22.0
    boss.height = 4.4
    boss.body_radius = 1.1
    boss.attack_range = 3.6
    boss.detect_range = 24.0
    boss.position = BOSS_POS
    boss.target = player
    add_child(boss)
    boss.died.connect(_on_boss_died)
    hud.bind_boss(boss)

    chest = Chest.new()
    chest.position = CHEST_POS
    add_child(chest)
    chest.opened.connect(_on_chest_opened)


func _on_enemy_died(e: Enemy) -> void:
    var coin := Pickup.new()
    coin.kind = Pickup.Kind.COIN
    coin.model_path = AssetPaths.COIN
    coin.model_scale = 0.45
    coin.position = Vector3(e.global_position.x, 0.0, e.global_position.z)
    call_deferred("add_child", coin)


func _on_boss_died(_e: Enemy) -> void:
    hud.set_boss_visible(false)
    chest.unlock()
    AudioManager.play_music("music_game")


func _on_chest_opened() -> void:
    Game.finish(true)


func _on_end(win: bool) -> void:
    overlay.show_end(win)
