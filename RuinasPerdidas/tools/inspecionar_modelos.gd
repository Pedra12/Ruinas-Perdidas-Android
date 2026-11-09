extends SceneTree

const PATHS := [
    "res://assets/characters/UAL1_Standard.glb",
    "res://assets/kaykit/Mannequin_Large.glb",
    "res://assets/kaykit/Rig_Large_MovementBasic.glb",
    "res://assets/kaykit/Rig_Large_MovementAdvanced.glb",
    "res://assets/kaykit/Rig_Large_CombatMelee.glb",
    "res://assets/kaykit/Rig_Large_General.glb",
    "res://assets/kaykit/Rig_Large_Special.glb"
]

func _initialize() -> void:
    call_deferred("_inspect")

func _inspect() -> void:
    for path in PATHS:
        print("\n=== MODEL ", path, " ===")
        var packed := load(path) as PackedScene
        if packed == null:
            print("LOAD FAILED")
            continue
        var root := packed.instantiate()
        var mesh_count := 0
        var skeleton_count := 0
        _walk(root, "", mesh_count, skeleton_count)
        print("SUMMARY meshes=", mesh_count, " skeletons=", skeleton_count)
        root.free()
    quit()

func _walk(node: Node, indent: String, mesh_count: int, skeleton_count: int) -> void:
    var extra := ""
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        if mi.mesh != null:
            mesh_count += 1
            extra = " mesh=" + str(mi.mesh.get_class())
    elif node is Skeleton3D:
        var sk := node as Skeleton3D
        skeleton_count += 1
        extra = " bones=" + str(sk.get_bone_count())
    elif node is AnimationPlayer:
        var ap := node as AnimationPlayer
        extra = " animations=" + str(ap.get_animation_list())
    print(indent, node.name, " [", node.get_class(), "]", extra)
    for child in node.get_children():
        _walk(child, indent + "  ", mesh_count, skeleton_count)
