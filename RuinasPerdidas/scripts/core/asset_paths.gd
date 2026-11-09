class_name AssetPaths
extends RefCounted
## Caminhos centrais dos assets. Se a estrutura do repositório for diferente,
## altere SOMENTE este arquivo (veja tools/organizar_assets.sh).

const ROOT := "res://assets/"

const PLAYER := ROOT + "human_motion/Models/HumanM_Model.fbx"
const PLAYER_PALETTE := ROOT + "human_motion/Textures/HumanAnimations_ColorPalette.png"
const PLAYER_ANIMATION_SOURCE := ROOT + "characters/UAL1_Standard.glb"
const PLAYER_IDLE_ANIM := ROOT + "human_motion/Animations/Male/Idles/HumanM@Idle01.fbx"
const PLAYER_WALK_ANIM := ROOT + "human_motion/Animations/Male/Movement/Walk/HumanM@Walk01_Forward.fbx"
const PLAYER_RUN_ANIM := ROOT + "human_motion/Animations/Male/Movement/Run/HumanM@Run01_Forward.fbx"
const PLAYER_SPRINT_ANIM := ROOT + "human_motion/Animations/Male/Movement/Sprint/HumanM@Sprint01_Forward.fbx"

const SKELY := ROOT + "enemies/Skely.glb"
const SKELY_DRAUGR := ROOT + "enemies/SkelyDraugr.glb"
const SKELY_POISON := ROOT + "enemies/SkelyPoison.glb"

const RUINS := ROOT + "ruins/"
const NATURE := ROOT + "nature/"

const GEM_EMERALD := RUINS + "Accessories/AncientCoinEmerald.glb"
const GEM_RUBY := RUINS + "Accessories/AncientCoinRuby.glb"
const GEM_AMETHYST := RUINS + "Accessories/AncientCoinAmethyst.glb"
const COIN := RUINS + "Accessories/AncientCoinRuby.glb"

const CHEST_BASE := RUINS + "Accessories/ChestBaseGold.glb"
const CHEST_LID := RUINS + "Accessories/ChestCover.glb"
const ALTAR := RUINS + "Accessories/Altar.glb"
const GATE := RUINS + "Walls/Gate.glb"
