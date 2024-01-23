
//represents a container of loose ammo
//that can be attached to a kinetic firearmm
/obj/item/ammo/magazine
	/// How many bullets this mag will start with
	var/start_amount = 0
	/// How many bullets this mag can hold. Overrides max_amount on the underlying ammo boject
	var/max_amount = 1000
	/// The kind of bullets this starts loaded with
	var/default_load = /obj/item/ammo/bullets/bullet_9mm
	/// If defined, how many bullets can be inserted in one action
	var/load_cap = 0
	/// The ammo categories this magazine supports.
	var/ammo_cats
	/// The ammo object. This may contain more than 1 slot's worth of ammo!
	var/obj/item/ammo/bullets/ammo
	var/sound_load = 'sound/weapons/gunload_light.ogg'
	var/icon_dynamic = 0 // For dynamic desc and/or icon updates (Convair880).
	var/icon_short = null // If dynamic = 1, the short icon_state has to be specified as well.
	var/icon_empty = null
	name = "magazine"


	/// Is this a speedloader? If yes, interact operations will treat this as a handful of loose bullets.
	var/is_speedloader = FALSE
	/// Are you blocked from removing bullets from this magazine?
	/// You might want to toggle this to 'true' if you don't want nukies emptying contents into their pockets & refilling mags.
	var/locked = FALSE
	attack_hand(mob/user)
		if (!user)
			return
		if (!locked)
			if ((src.loc == user) && user.find_in_hand(src))
				var/obj/item/ammo/bullets/object
				if (ammo.amount_left > ammo.max_amount)
					object = new ammo.type
					object.amount_left = ammo.max_amount
					ammo.amount_left -= ammo.max_amount
				else
					object = src.ammo
					src.ammo = null
				object.UpdateIcon()
				user?.visible_message("<span class='alert'>[user] unloads [src].</span>", "<span class='alert'>You unload [src]. It has [src.ammo?.amount_left ? src.ammo.amount_left : 0] rounds remaining.</span>")
				user.put_in_hand_or_drop(object)
				UpdateIcon()
				return
		..()
	New()
		RegisterSignal(src, COMSIG_UPDATE_ICON, /atom/proc/UpdateIcon)
		ammo = new default_load()
		ammo.set_loc(src)
		ammo.max_amount = max_amount
		ammo.amount_left = start_amount
		inventory_counter?.update_number(src.ammo?.amount_left)
		..()


	update_icon()
		if (src.ammo)
			inventory_counter?.update_number(src.ammo?.amount_left)
		else
			inventory_counter?.update_text("-")
		src.tooltip_rebuild = 1
		if (src.ammo?.amount_left > 0)
			if (src.icon_dynamic && src.icon_short)
				src.icon_state = text("[src.icon_short]-[src.ammo?.amount_left]")
			else if(src.icon_empty)
				src.icon_state = initial(src.icon_state)
		else
			if (src.icon_empty)
				src.icon_state = src.icon_empty
		return

	proc/full()
		return (ammo_left() >= max_amount)

	/// Adds the specified ammunition to the magazine.
	/// Returns TRUE if an action was performed.
	proc/merge_ammo(obj/item/ammo/bullets/otherAmmo, mob/user)
		if (src.ammo && src.ammo.type == otherAmmo.type)
			var/result = src.ammo.merge_ammo(otherAmmo, user)
			UpdateIcon()
			return result
		else
			src.ammo = new otherAmmo.type()
			var/amt = min(max_amount,otherAmmo.amount_left)
			src.ammo.amount_left = amt
			user?.visible_message("<span class='alert'>[user] refills [src].</span>", "<span class='alert'>You swap the ammo loaded in [src]. It has [src.ammo.amount_left] rounds remaining.</span>")
			otherAmmo.use(amt)
			if (otherAmmo.amount_left <= 0)
				qdel(otherAmmo)
			UpdateIcon()


	proc/get_ammo_type()
		return ammo.ammo_type

	ammo_left()
		return ammo?.amount_left

	/// Pulls a new ammo object from the top of the magazine
	proc/pull_ammo(var/desired_quantity)
		var/obj/item/ammo/bullets/result
		if (ammo.amount_left == 0)
			return null
		else
			result = new ammo.type()
			var/amt = min(desired_quantity,ammo.amount_left)
			result.amount_left = amt
			ammo.use(amt)
			return result

	use(var/amt = 0)
		var/res = ammo.use(amt)
		src.UpdateIcon()
		return res



	swap(var/obj/item/ammo/magazine/newMag, var/obj/item/gun/kinetic/K)
		//attempt to implicitly chamber a round for tactical reloading without using *rack
		if (newMag.ammo.type == ammo.type)
			K.pull_ammo()
		else if (K.magic_unswap)
			if (K.magazine.ammo_left() < K.magazine.max_amount)
				K.magazine.merge_ammo(K.ammo)

		usr.u_equip(newMag)
		usr.put_in_hand_or_drop(src)
		newMag.set_loc(K)
		if (K.magic_unswap && newMag.ammo.type != ammo.type)
			K.magazine = null
			K.rack_slide()
		K.magazine = newMag
		K.UpdateIcon()
		src.UpdateIcon()
		newMag.UpdateIcon()
		..()

	proc/loadammo(var/obj/item/gun/kinetic/K, var/mob/usr)
		if (is_speedloader)
			//weirdness loading mostly-loaded revolvers with partial ammo
			var/result = ammo.loadammo(K,usr)
			UpdateIcon()
			return result
		// Also see attackby() in kinetic.dm.
		if (!K)
			return 0 // Error message.
		if (K.sanitycheck() == 0)
			return 0
		if (!K.can_swap_magazine)
			return AMMO_RELOAD_INCOMPATIBLE
		var/check = 0
		// make sure we can load whatever ammo is in here
		if (!ammo || (ammo.ammo_cat in K.ammo_cats))
			check = 1
		else if (K.ammo_cats == null) //someone forgot to set ammo cats. scream
			check = 1
		if (length(K.supported_magazine_types))
			var/valid = FALSE
			for (var/type as anything in K.supported_magazine_types)
				if (istype(src,type))
					valid = TRUE
			if (!valid)
				check = 0

		if (!check)
			return AMMO_RELOAD_INCOMPATIBLE

		K.add_fingerprint(usr)
		src.add_fingerprint(usr)
		if(K.sound_load_override)
			playsound(K, K.sound_load_override, 50, 1)
		else
			playsound(K, sound_load, 50, 1)

		if (ammo_left() < 1)
			if (K.magazine)
				return AMMO_RELOAD_SOURCE_EMPTY // Magazine's empty and there's a mag loaded. no point swapping.
			else
				K.magazine = src
				usr.u_equip(src)
				src.set_loc(K)
				K.UpdateIcon()
				return AMMO_RELOAD_EMPTY_MAG
		if (K.magazine)
			return AMMO_RELOAD_TYPE_SWAP // Call swap().
		else
			K.magazine = src
			usr.u_equip(src)
			src.set_loc(K)
			K.UpdateIcon()
			return AMMO_RELOAD_FULLY // Full reload or ammo left over.


	attackby(obj/b, mob/user)
		if(istype(b, /obj/item/ammo/bullets))
			var/obj/item/ammo/bullets/loadedAmmo = b
			if (b.type == src.ammo?.type)
				src.ammo.attackby(b,user)
				UpdateIcon()
			else if(loadedAmmo.ammo_cat in ammo_cats)
				merge_ammo(b,user)
				return

	speedloader
		bullet_38
			is_speedloader = TRUE
			icon_short = "38"
			icon_empty = "speedloader_empty"
			name = ".38 speedloader"
			desc = "A speedloader for .38 ammunition."
			icon_state = "38-7"
			ammo_cats = list(AMMO_REVOLVER_DETECTIVE)
			start_amount = 7
			max_amount = 7
			icon_dynamic = 1
			default_load = /obj/item/ammo/bullets/a38


	smg
		name = "9mm SMG magazine"
		desc = "An extended 9mm magazine for a sub machine gun."
		icon_state = "smg_magazine"
		ammo_cats = list( AMMO_SMG_9MM)
		start_amount = 30
		max_amount = 30
		default_load = /obj/item/ammo/bullets/bullet_9mm/smg


		//debug magazine, to test bullets frequently swapping
		incen
			var/ammo_left = 30
			icon_state = "smg_magazine_inc"
			var/obj/item/ammo/bullets/ammo_1 = new/obj/item/ammo/bullets/bullet_9mm/smg/incendiary
			var/obj/item/ammo/bullets/ammo_2 = new/obj/item/ammo/bullets/bullet_9mm/smg
			get_ammo_type()
				if (ammo_left%2)
					return ammo_1.ammo_type
				else
					return ammo_2.ammo_type

			ammo_left()
				return ammo_left

			/// Pulls a new ammo object from the top of the magazine
			pull_ammo(var/desired_quantity)
				if (ammo_left == 0)
					return null
				else
					var/obj/item/ammo/bullets/result
					if (ammo_left%2)
						result = new ammo_1.type()
					else
						result = new ammo_2.type()
					result.amount_left = 1
					ammo_left--
					return result

			use(var/amt = 0)
				if (ammo_left >= amt)
					ammo_left -= amt
					src.UpdateIcon()
					return TRUE
				return FALSE

	bullet_9mm
		icon_state = "pistol_magazine"
		start_amount = 15
		max_amount = 15
		desc = "A handgun magazine full of 9x19mm rounds, an intermediate pistol cartridge."
		default_load = /obj/item/ammo/bullets/bullet_9mm


	bullet_22

		icon_state = "pistol_magazine"
		start_amount = 10
		max_amount = 10
		desc = "A tiny magazine for tiny bullets."
		default_load = /obj/item/ammo/bullets/bullet_22
		ammo_cats = list( AMMO_PISTOL_22)
		faith
			start_amount = 4
			max_amount = 4
			name = ".22 Faith magazine"
			desc = "A cute little .22 mag! It holds 4 rounds"
			default_load = /obj/item/ammo/bullets/bullet_22

	riot_12
		icon_state = "pistol_magazine"
		start_amount = 7 // + 1 in the shotgun
		max_amount = 7
		desc = "A tube magazine for a shotgun. You shouldn't see this!"
		default_load = /obj/item/ammo/bullets/abg
		ammo_cats = list( AMMO_SHOTGUN_ALL)
		// FILO mags support mixed loads. it's an interesting area to explore for shotguns. also just an easy test case for the refactor
		filo
			var/list/obj/item/ammo/bullets/ammos
			load_cap = 1
			New()
				..()
				ammos = new/list()
			merge_ammo(obj/item/ammo/bullets/otherAmmo, mob/user)
				var/amount = min(load_cap,min(otherAmmo.amount_left, max_amount-ammo_left()))
				var/success = FALSE
				if (amount == 0)
					success = AMMO_RELOAD_ALREADY_FULL
					return
				playsound(user.loc, 'sound/weapons/gunload_click.ogg', 50, 1)
				//Merge ammos if types match, rather than making a new ammo object
				if (length(ammos) && otherAmmo.type == ammos[length(ammos)].type)
					otherAmmo.amount_left -= amount
					ammos[length(ammos)].amount_left += amount
					if (max_amount == ammo_left())
						success = AMMO_RELOAD_FULLY
					else if (load_cap == amount)
						success = AMMO_RELOAD_PARTIAL_DELIBERATE
					else
						success = AMMO_RELOAD_PARTIAL
				else
					//If types don't match, and we can fit the whole stack inside the mag
					if (amount >= otherAmmo.amount_left)
						ammos += otherAmmo
						user.u_equip(otherAmmo)
						otherAmmo.set_loc(src) //... simply move the ammo item inside the mag.
						if (max_amount == ammo_left())
							success = AMMO_RELOAD_FULLY
						else if (load_cap == amount)
							success = AMMO_RELOAD_PARTIAL_DELIBERATE
						else
							success = AMMO_RELOAD_PARTIAL
					else
						//if ammo types don't match and we need only part of the stack, make a new ammo object
						var/obj/item/ammo/bullets/newAmmo = new otherAmmo.type(src)
						newAmmo.amount_left = amount
						otherAmmo.amount_left -= amount
						newAmmo.set_loc(src)
						ammos += newAmmo
						success = AMMO_RELOAD_FULLY

				if (otherAmmo.amount_left == 0)
					qdel(otherAmmo)
				else
					otherAmmo.UpdateIcon()
				return success

			// FILO breaks down if you shoot a fraction of a bullet, as this only returns the top shot.
			// but this is a bizarre use case I don't think has ever had a reason to exist in kinetics.
			get_ammo_type()
				if (ammo_left() == 0)
					return null
				return ammos[length(ammos)].ammo_type

			ammo_left()
				var/total = 0
				for (var/obj/item/ammo/bullets/bullet as anything in ammos)
					total += bullet.amount_left
				return total
			use(var/amt = 0)
				var/res = ammos[length(ammos)].use(amt)
				if (ammos[length(ammos)].amount_left == 0) //delete empty stacks
					qdel(ammos[length(ammos)])
					ammos -= ammos[length(ammos)]
				src.UpdateIcon()
				return res

			pull_ammo(var/quantity)
				var/obj/item/ammo/bullets/result
				if (ammo_left() == 0)
					return null
				else
					var/bulletType = (ammos[length(ammos)]).type
					result = new bulletType
					var/amt = min(quantity,ammos[length(ammos)].amount_left)
					result.amount_left = amt
					ammos[length(ammos)].use(amt)
					if (ammos[length(ammos)].amount_left == 0) //delete empty stacks
						ammos -= ammos[length(ammos)]
					return result
