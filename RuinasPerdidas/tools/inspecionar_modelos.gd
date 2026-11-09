extends SceneTree

const PATHS := [
    "res://assets/characters/UAL1_Standard.glb",
    "res://assets/kaykit/Mannequin_Large.glb",
    "res://assets/kaykit/Rig_Large_MovementBasic.glb",
    "res://assets/kaykit/Rig_Large_MovementAdvanced.glb",
    "res://assets/kaykit/Rig_Large_CombatMelee.glb",
    "res://assets/kaykit/Rig_Large_General.glb",
    "res://assets/kaykit/Rig_Large_Special.glb",
    "res://assets/human_motion/Models/HumanM_Model.fbx",
    "res://assets/human_motion/Animations/Male/Idles/HumanM@Idle01.fbx",
    "res://assets/human_motion/Animations/Male/Movement/Walk/HumanM@Walk01_Forward.fbx",
    "res://assets/human_motion/Animations/Male/Movement/Run/HumanM@Run01_Forward.fbx",
    "res://assets/human_motion/Animations/Male/Movement/Sprint/HumanM@Sprint01_Forward.fbx",
    "res://assets/human_motion/Animations/Male/Movement/Jump/HumanM@Jump01.fbx"
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
        var mesh_count := root.find_children("*", "MeshInstance3D", true, false).size()
        var skeleton_count := root.find_children("*", "Skeleton3D", true, false).size()
        _walk(root, "")
        print("SUMMARY meshes=", mesh_count, " skeletons=", skeleton_count)
        root.free()
    quit()

func _walk(node: Node, indent: String) -> void:
    var extra := ""
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        if mi.mesh != null:
            extra = " mesh=" + str(mi.mesh.get_class())
            var mat := mi.get_active_material(0)
            if mat is StandardMaterial3D:
                var sm := mat as StandardMaterial3D
                extra += " material=" + sm.resource_name + " albedo=" + str(sm.albedo_color) + " texture=" + str(sm.albedo_texture != null)
    elif node is Skeleton3D:
        var sk := node as Skeleton3D
        var bones: Array[String] = []
        for i in sk.get_bone_count():
            bones.append(sk.get_bone_name(i))
        extra = " bones=" + str(sk.get_bone_count()) + " names=" + str(bones)
    elif node is AnimationPlayer:
        var ap := node as AnimationPlayer
        extra = " animations=" + str(ap.get_animation_list())
        for anim_name in ap.get_animation_list():
            if anim_name in ["Walk", "Sword_Attack", "Roll", "HumanM_Walk01_Forward", "HumanM_Idle01"]:
                var anim := ap.get_animation(anim_name)
                var tracks: Array[String] = []
                for ti in mini(anim.get_track_count(), 8):
                    tracks.append(str(anim.track_get_path(ti)))
                print(indent, "  TRACKS ", anim_name, " ", tracks)
    print(indent, node.name, " [", node.get_class(), "]", extra)
    for child in node.get_children():
        _walk(child, indent + "  ")
