class_name Utils
extends RefCounted
## Funções utilitárias estáticas (carregar modelos, medir, ajustar escala).


static func load_packed(path: String) -> PackedScene:
    if ResourceLoader.exists(path):
        var res: Resource = load(path)
        if res is PackedScene:
            return res
    push_warning("Asset ausente ou inválido: %s" % path)
    return null


## Instancia um modelo. Se o arquivo não existir, devolve um cubo magenta
## (o jogo nunca quebra por falta de asset).
static func instance_model(path: String) -> Node3D:
    var packed: PackedScene = load_packed(path)
    if packed != null:
        var inst: Node = packed.instantiate()
        if inst is Node3D:
            return inst
        inst.queue_free()
    return _placeholder()


static func _placeholder() -> Node3D:
    var root := Node3D.new()
    var mi := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1, 1, 1)
    mi.mesh = box
    mi.position.y = 0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1, 0, 1)
    mi.material_override = mat
    root.add_child(mi)
    return root


static func find_anim_player(root: Node) -> AnimationPlayer:
    var found: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
    if found.is_empty():
        return null
    return found[0] as AnimationPlayer


## Força loop em animações cujo nome termina com "_loop" ou que estejam em `extra`.
static func force_loops(ap: AnimationPlayer, extra: Array = []) -> void:
    if ap == null:
        return
    for n in ap.get_animation_list():
        var nm: String = str(n)
        var anim: Animation = ap.get_animation(nm)
        if anim == null:
            continue
        if nm.to_lower().ends_with("_loop") or extra.has(nm):
            anim.loop_mode = Animation.LOOP_LINEAR


static func first_mesh(root: Node) -> Mesh:
    var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
    for n in found:
        var mi := n as MeshInstance3D
        if mi != null and mi.mesh != null:
            return mi.mesh
    return null


## AABB de todas as malhas de `subtree`, expresso no espaço local de `space`.
## Os nós precisam já estar na árvore de cena.
static func aabb_in(space: Node3D, subtree: Node) -> AABB:
    var inv: Transform3D = space.global_transform.affine_inverse()
    var result := AABB()
    var has_box := false
    var found: Array[Node] = subtree.find_children("*", "MeshInstance3D", true, false)
    if subtree is MeshInstance3D:
        found.append(subtree)
    for n in found:
        var mi := n as MeshInstance3D
        if mi == null or mi.mesh == null:
            continue
        var box: AABB = (inv * mi.global_transform) * mi.get_aabb()
        if has_box:
            result = result.merge(box)
        else:
            result = box
            has_box = true
    return result


## Escala `model` (já filho de `space` e na árvore) para ter `target` metros de altura
## e apoia os pés em y=0. Útil porque modelos Mixamo (Skely) vêm em centímetros.
static func fit_height(space: Node3D, model: Node3D, target: float) -> void:
    var box: AABB = aabb_in(space, model)
    if box.size.y < 0.001:
        return
    var k: float = target / box.size.y
    model.scale = model.scale * k
    box = aabb_in(space, model)
    model.position.y -= box.position.y


static func add_box_collider(body: Node3D, box: AABB) -> void:
    if box.size.length() < 0.01:
        return
    var shape := BoxShape3D.new()
    shape.size = box.size
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position = box.get_center()
    body.add_child(cs)
