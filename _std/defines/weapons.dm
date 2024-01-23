/// Incompatible source ammo type inserted
#define AMMO_RELOAD_INCOMPATIBLE 1
/// Source object being inserted is empty
#define AMMO_RELOAD_SOURCE_EMPTY 2
/// Target object is already full
#define AMMO_RELOAD_ALREADY_FULL 4
/// Target object was partially filled
#define AMMO_RELOAD_PARTIAL 8
/// Target object was filled completely
#define AMMO_RELOAD_FULLY 16
/// Target ammo was swapped with source ammo
#define AMMO_RELOAD_TYPE_SWAP 32
/// Empty magazine was inserted to magless gun
#define AMMO_RELOAD_EMPTY_MAG 64
/// Target object was partially filled, but not due to lack of ammo (like loading 1 shotshell)
#define AMMO_RELOAD_PARTIAL_DELIBERATE 128

#define AMMO_SWAP_INCOMPATIBLE 1
#define AMMO_SWAP_SOURCE_EMPTY 2
#define AMMO_SWAP_ALREADY_FULL 4
