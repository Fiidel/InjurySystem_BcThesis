# Manticore Enemy Injury System Demo Manual
## Demo Controls
- `WASD` movement
- `spacebar` jump
- `left click` shoot projectile
- `lshift (hold)` move faster
- `1, 2, 3` switch between projectile types
- `U` toggle debug mesh for deformation showcase
- `I` toggle behavior tree visualizer
- `O` toggle spawning debug sphere at hit location
- `P` toggle spawning debug cylinders at hit location oriented by the normal of the hit
- `R` reset the game

## Godot Nodes
### Imported Enemy
Import the enemy with the meshes and skeleton rig. If a ragdoll is desired, click on its `Skeleton3D` node and in the top bar, click `Skeleton3D -> Create Physical Skeleton` and set all of the generated bones' `Type` to `6DOF`.

### Body and BodyPart
Add a `Body` node as a child of the enemy. Set its overall health and references to the behavior tree root and animation tree. Optionally, turn on ragdoll activation and supply the newly visible variables.

Add `BodyPart` nodes as children of the `Body`. Choose whether to damage the overall health or set its own health (if it reaches 0, it is destroyed). Assign the corresponding mesh. If the body part is to be removed when destroyed, assign the root bone of the chain that is to be removed and the scene with the severed version of itself.

To attach `Hitbox` nodes for detecting hits, add `BoneAttachment3D` nodes with `Hitbox` children, which themselves have `CollisionShape3D` nodes. Each `BodyPart` can have multiple attachments with hitboxes for accurate hit detection. Finally, assign the hitboxes in the parent `BodyPart` node.

### Behavior Tree
Add a `BTRoot` node as a child of the enemy. Build the behavior tree with other behavior tree nodes as its children. The order of the children in the scene tree matters. Flow control (like sequences, selectors, and randomizers) nodes don't require special script overrides, although they might have some variables that can be set or adjusted. `BTCondition` must define a function that returns a bool, and set the base class's `condition` to the new function, e.g., `condition = new_bool_func`. `BTUtility` nodes must override `get_utility`. Action nodes should always be overridden with the desired behavior defined in the `execute` function. `BTWeightedRandomizer` expects its direct children to be `BTWeight` decorator nodes, otherwise it presumes a weight of `1.0`. `BTUtilityRandomizer` expects its direct children to be `BTUtility` decorator nodes. `BTBodyPartFilter` and `BTBodyPartFilterRecheck` nodes require `BodyPart` nodes for filtering.

### Mesh Shader
For each body part mesh, set the surface material override to `body_part_shader.gdshader`. Set its albedo and normal textures and any other material variables (e.g., roughness, specular, ...).

### Knockback
Add `BodyPartKnockback3D` as a child of the model's `Skeleton3D` node and assign the bone that is supposed to move with any applied knockback (for whole-body jerks).

Then add a `BoneKnockback3D` node as a child of `BodyPart`. Set the knockback strength, the bone that is supposed to jerk, and the reference to the `BodyPartKnockback3D` node. Do this for any body part you wish to have knockback.
