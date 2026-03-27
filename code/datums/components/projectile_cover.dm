/// Projectile cover component. Used by tables and other objects to block projectiles.
/datum/component/projectile_cover


/datum/component/projectile_cover/Initialize()
	. = ..()
	if(!istype(parent, /obj))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_ATOM_CROSSED, PROC_REF(atom_crossed))


/datum/component/projectile_cover/proc/atom_crossed(obj/target, atom/crossed)
	if (istype(crossed, /obj/projectile))
		var/obj/projectile/P = crossed
		P.handle_flyover()
