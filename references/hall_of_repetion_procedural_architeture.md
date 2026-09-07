## Hall_of_Repetition Procedural Body Architecture

Each villager is one Node3D.

The visual body is generated at runtime.

Recommended scene:

ProceduralVillager
├── BodyPrimary
│   ├── torso
│   ├── neck
│   ├── upper_arm_left
│   ├── lower_arm_left
│   ├── upper_arm_right
│   ├── lower_arm_right
│   ├── upper_leg_left
│   ├── lower_leg_left
│   ├── upper_leg_right
│   ├── lower_leg_right
│   ├── ribs
│   ├── pelvis
│   ├── chest
│   ├── head
│   └── face_quad
├── BodyEcho
│   └── same procedural body
├── SpectralFacets
└── MistFragments

No rigged character is necessary.

Do not use:

Skeleton3D
AnimationTree
NavigationAgent3D
combat AI
13. Primitive Construction

Use low-resolution primitives.

Limbs
CylinderMesh
Chest / pelvis / head
SphereMesh

or similar low-poly primitives.

Face
QuadMesh
Spectral fragments
BoxMesh
SphereMesh
14. Joint Architecture

Calculate joint points mathematically every frame.

Required points:

pelvis
chest
neck
head

left_shoulder
left_elbow
left_hand

right_shoulder
right_elbow
right_hand

left_hip
left_knee
left_foot

right_hip
right_knee
right_foot

The figure is reconstructed from these positions every frame.

15. Cylinder Between Joints

Use:

func set_segment(
    segment: MeshInstance3D,
    point_a: Vector3,
    point_b: Vector3,
    radius: float
) -> void:
    var delta := point_b - point_a
    var length := delta.length()

    if length <= 0.001:
        segment.visible = false
        return

    segment.visible = true

    var y_axis := delta / length
    var helper := Vector3.FORWARD

    if absf(y_axis.dot(Vector3.FORWARD)) >= 0.94:
        helper = Vector3.RIGHT

    var x_axis := helper.cross(y_axis).normalized()
    var z_axis := x_axis.cross(y_axis).normalized()

    var basis := Basis(
        x_axis,
        y_axis,
        z_axis
    ).scaled(
        Vector3(
            radius * 2.0,
            length,
            radius * 2.0
        )
    )

    segment.transform = Transform3D(
        basis,
        (point_a + point_b) * 0.5
    )

This is the central construction rule.

16. Individual Figure Parameters

Expose:

@export var identity_seed: float = 1.0
@export var motion_rate: float = 1.0
@export var pose_variant: int = 0
@export var body_scale: float = 1.0
@export var mirror_motion: bool = false
@export var face_texture: Texture2D
@export var face_height: float = 0.25
@export var spectral_tint: Color
@export var echo_distance: float = 0.02

Every villager receives different values.

Do not synchronize movement.

17. Motion Phase

Use:

var phase := (
    elapsed_time
    * 3.25
    * motion_rate
    + identity_seed * 2.11
)

The phase provides asynchronous procedural movement.

However:

do not recreate the Hall dancing motion.

The BODY OF MINE villagers should move like restrained humans.

18. Pose State Machine

Use:

enum VillagerPose {
    IDLE,
    WORKING,
    NOTICE,
    FREEZE,
    RECOIL,
    WATCH,
    ARMING,
    DEFENSIVE,
    RETREAT
}

Each state changes calculated joint positions.

19. IDLE

Movement should be minimal.

Example:

var pelvis := Vector3(
    sin(phase * 0.40 + identity_seed) * 0.015,
    0.91,
    cos(phase * 0.35 + identity_seed) * 0.010
)

var chest := pelvis + Vector3(
    sin(phase * 0.47 + identity_seed) * 0.020,
    0.45 + cos(phase * 0.61) * 0.008,
    0.0
)

Idle should communicate:

breathing;
weight shift;
working posture;
small human irregularities.
20. Working Poses

Different villagers should begin with different activities.

Examples:

repairing fishing net
holding basket
working beside barrel
handling rope
standing beside cart
carrying wood

No elaborate animation is required.

These can be procedural arm-position variants.

21. NOTICE Pose

When a villager notices the Sailor:

activity stops
↓
brief freeze
↓
head turns first
↓
chest follows
↓
body remains mostly stationary

The recognition should appear involuntary.

22. FREEZE Pose

All procedural body motion becomes almost zero.

This moment is important.

The absence of motion creates tension.

23. RECOIL Pose

Use:

pelvis shifts backward
chest leans away
head remains focused on Sailor
one arm rises
one foot moves backward

The woman uses the strongest recoil variant.

24. ARMING Pose

The figure reaches toward a weapon prop.

Weapons can begin attached to:

wall
barrel
ground
cart
working table

During the pose, interpolate the weapon from its world position to the procedural hand.

After acquisition, update its transform from the hand joint every frame.

25. DEFENSIVE Pose

Use:

feet separated
body leaning slightly backward
weapon extended
head watching Sailor

The pose must show:

fear + refusal

rather than aggression.

26. RETREAT Pose

If the Sailor advances:

the figure's root Node3D moves toward a predetermined retreat anchor.

The procedural body continues animating independently.

No pathfinding is needed.

27. Face System

The user will supply the historical face textures.

Codex only needs to implement a flexible texture slot.

Use:

QuadMesh

on or just in front of the procedural head.

Normal behavior:

face follows head orientation

During recognition:

allow a short stronger camera-facing orientation.

This should last only approximately:

0.3–0.8 seconds

Then return toward normal orientation.

Avoid permanently billboarded faces.

28. Face Visual Treatment

The face shader may contain restrained:

horizontal displacement;
texture breakup;
opacity fluctuation;
temporal dropout;
slight image misregistration.

Avoid modern computer glitch aesthetics.

The effect should resemble:

damaged print;
decomposed photographic plate;
misaligned engraving;
image doubling.
29. Displaced Body Echo

Every villager contains:

BodyPrimary
BodyEcho

The second copy is offset slightly.

Example:

var echo_offset := Vector3(
    echo_direction * echo_distance,
    0.017,
    0.046
)
30. Normal Visual State

Before recognition:

primary_alpha ≈ 0.90
echo_alpha ≈ 0.05–0.10
fracture_strength ≈ very low

The villagers should first read as human figures.

31. Recognition Distortion

When the villager recognizes the Sailor:

echo_alpha increases
echo_distance increases slightly
fracture_strength increases
small spectral fragments appear

Suggested:

echo_alpha ≈ 0.25–0.35

The effect then partially subsides.

The distortion should remain subtle.

32. Visual Meaning of Distortion

The supernatural instability becomes strongest when the villagers perceive the Sailor.

Do not explain why.

The effect should suggest that something about the encounter destabilizes representation itself.

33. Shader Base

Body shader:

shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

Expose:

uniform float fracture = 0.05;
uniform float phase = 0.0;

Basic displacement:

float tear = sin(
    VERTEX.y * 19.0
    + TIME * 9.0
    + phase * 7.0
);

VERTEX.x += tear * fracture * 0.018;
VERTEX.z -= tear * fracture * 0.011;

Keep fracture nearly invisible under normal conditions.

34. Spectral Facets

Create a small number of fragments around:

head;
shoulders;
torso.

Normally hidden.

Recognition or high fear activates them briefly.

Do not create a dense particle cloud.

35. Shadow Rule

For spectral meshes:

mesh_instance.cast_shadow = \
    GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

The displaced elements should not cast ordinary physical shadows.

36. Scene Architecture

Recommended:

VillageFirstConfrontation
├── VillageConfrontationController
├── RecognitionTrigger
├── ApproachBoundary
├── Villagers
│   ├── Villager01_Fisherman
│   ├── Villager02_VillageMan
│   ├── Villager03_Defender
│   ├── Villager04_OlderMan
│   └── Villager05_Woman
├── Weapons
│   ├── Pitchfork
│   ├── FishingSpear
│   ├── Axe
│   └── Pole
├── RetreatAnchors
│   ├── Retreat01
│   ├── Retreat02
│   ├── Retreat03
│   └── Retreat04
├── Audio
└── VillageGeometry
37. Figure Public API

Each figure exposes:

func set_pose(new_pose: VillagerPose) -> void

func look_at_target(target: Node3D) -> void

func set_fear_level(value: float) -> void

func set_fracture_level(value: float) -> void

func move_to_anchor(anchor: Node3D) -> void

func equip_prop(prop: Node3D) -> void

func set_face_texture(texture: Texture2D) -> void

The figure controls its body.

The confrontation controller controls the scene.
