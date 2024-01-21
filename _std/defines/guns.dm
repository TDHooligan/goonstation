

// LOADING BEHAVIOURS
/// If TRUE, hitting a magazine weapon with loose bullets will load bullets straight into the magazine.
#define KINETIC_OPEN_LOAD_EVERYTHING FALSE

/// If TRUE, swapping magazines will instead attempt to load the new magazine's bullets into the current magazine
/// This is functionally to how old kinetic loading worked. You pour bullets into your gun.
#define KINETIC_BULLET_SLURPING FALSE


// CHAMBERING BEHAVIOURS
/// If TRUE, tactically reloading or *racking a magazine fed gun will keep up to (internal_magazine) bullets chambered.
/// So, if you reload early. you could load 31 rounds in a 30 round gun. Or 6 in a 5 round bolt action, etc.
#define KINETIC_CHAMBERING TRUE

/// QOL. If TRUE, when you unload a gun, chambered bullets will be magically put back in the mag. Then anything else is spit out on the floor.
#define KINETIC_MAGIC_UNCHAMBERING_ON_UNLOAD TRUE
/// Does the same, but when you change magazine to a different ammo type. Stops you being able to mix ammunition by mag swapping.
#define KINETIC_MAGIC_UNCHAMBERING_PREVENT_MIXED_LOADS TRUE


// OPTIONS THAT MIGHT BE MORE USEFUL LATER
/// If TRUE, removes auto-racking.
/// IE, Semi-automatics must be *racked to load their first bullet. (this is REALLY SHIT until someone adds gun circle selectors)
#define KINETIC_AWFUL_MANUAL_CHAMBERING FALSE
