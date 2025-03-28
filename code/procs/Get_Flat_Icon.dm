/// Creates a single icon from a given /atom or /image.  Only the first argument is required.
/proc/getFlatIcon(image/A, defdir, deficon, defstate, defblend, start = TRUE, no_anim = FALSE)
	var/static/icon/flat_template = icon('icons/misc/flatBlank.dmi')

	#define INDEX_X_LOW 1
	#define INDEX_X_HIGH 2
	#define INDEX_Y_LOW 3
	#define INDEX_Y_HIGH 4

	#define flatX1 flat_size[INDEX_X_LOW]
	#define flatX2 flat_size[INDEX_X_HIGH]
	#define flatY1 flat_size[INDEX_Y_LOW]
	#define flatY2 flat_size[INDEX_Y_HIGH]
	#define addX1 add_size[INDEX_X_LOW]
	#define addX2 add_size[INDEX_X_HIGH]
	#define addY1 add_size[INDEX_Y_LOW]
	#define addY2 add_size[INDEX_Y_HIGH]

	if(!A || A.alpha <= 0)
		return icon(flat_template)

	var/noIcon = FALSE
	if(start)
		if(!defdir)
			defdir = A.dir
		if(!deficon)
			deficon = A.icon
		if(!defstate)
			defstate = A.icon_state
		if(!defblend)
			defblend = A.blend_mode

	var/curicon = A.icon || deficon
	var/curstate = A.icon_state || defstate

	if(!((noIcon = (!curicon))))
		var/curstates = get_icon_states(curicon)
		if(!(curstate in curstates))
			if("" in curstates)
				curstate = ""
			else
				noIcon = TRUE // Do not render this object.

	var/curdir
	var/base_icon_dir	//We'll use this to get the icon state to display if not null BUT NOT pass it to overlays as the dir we have

	//These should use the parent's direction (most likely)
	if(!A.dir || A.dir == SOUTH)
		curdir = defdir
	else
		curdir = A.dir

	//Try to remove/optimize this section ASAP, CPU hog.
	//Determines if there's directionals.
	if(!noIcon && curdir != SOUTH)
		var/exist = FALSE
		var/static/list/checkdirs = list(NORTH, EAST, WEST)
		for(var/i in checkdirs)		//Not using GLOB for a reason.
			if(length(icon_states(icon(curicon, curstate, i))))
				exist = TRUE
				break
		if(!exist)
			base_icon_dir = SOUTH
	//

	if(!base_icon_dir)
		base_icon_dir = curdir

	var/curblend = A.blend_mode || defblend

	if(length(A.overlays) || length(A.underlays))
		var/icon/flat = icon(flat_template)
		// Layers will be a sorted list of icons/overlays, based on the order in which they are displayed
		var/list/layers = list()
		var/image/copy
		// Add the atom's icon itself, without pixel_x/y offsets.
		if(!noIcon)
			copy = image(icon=curicon, icon_state=curstate, layer=A.layer, dir=base_icon_dir)
			copy.color = A.color
			copy.alpha = A.alpha
			copy.blend_mode = curblend
			layers[copy] = A.layer

		// Loop through the underlays, then overlays, sorting them into the layers list
		for(var/process_set in 0 to 1)
			var/list/process = process_set ? A.overlays : A.underlays
			for(var/i in 1 to length(process))
				var/image/current = process[i]
				if(!current)
					continue
				if(startswith(current.render_target, "*"))
					continue
				if(current.plane != FLOAT_PLANE && current.plane != A.plane)
					continue
				var/current_layer = current.layer
				if(current_layer < 0)
					if(current_layer <= -1000)
						return flat
					current_layer = process_set + A.layer + (current_layer / 1000)

				for(var/p in 1 to length(layers))
					var/image/cmp = layers[p]
					if(current_layer < layers[cmp])
						layers.Insert(p, current)
						break
				layers[current] = current_layer

		//sortTim(layers, /proc/cmp_image_layer_asc)

		var/icon/add // Icon of overlay being added

		// Current dimensions of flattened icon
		var/list/flat_size = list(1, flat.Width(), 1, flat.Height())
		// Dimensions of overlay being added
		var/list/add_size[4]

		for (var/image/I as anything in layers)
			if(I.alpha == 0)
				continue

			if(I == copy) // 'I' is an /image based on the object being flattened.
				add = icon(I.icon, I.icon_state, base_icon_dir)
			else // 'I' is an appearance object.
				add = getFlatIcon(image(I), curdir, curicon, curstate, I.blend_mode, FALSE, no_anim)
			if(!add)
				continue
			// Find the new dimensions of the flat icon to fit the added overlay
			add_size = list(
				min(flatX1, I.pixel_x + 1),
				max(flatX2, I.pixel_x + add.Width()),
				min(flatY1, I.pixel_y + 1),
				max(flatY2, I.pixel_y + add.Height())
			)

			if(flat_size ~! add_size)
				// Resize the flattened icon so the new icon fits
				flat.Crop(
				addX1 - flatX1 + 1,
				addY1 - flatY1 + 1,
				addX2 - flatX1 + 1,
				addY2 - flatY1 + 1
				)
				flat_size = add_size.Copy()

			// Blend the overlay into the flattened icon
			var/Iblend = I.blend_mode
			if(Iblend == BLEND_INSET_OVERLAY)
				var/icon/flat_alpha_mask = icon(flat)
				flat_alpha_mask.MapColors(0,0,0, 0,0,0, 0,0,0, 0,0,0)
				add.Blend(flat_alpha_mask, ICON_AND)
				Iblend = BLEND_OVERLAY
			flat.Blend(add, blendMode2iconMode(Iblend), I.pixel_x + 2 - flatX1, I.pixel_y + 2 - flatY1)

		if(islist(A.color))
			var/list/c = normalize_color_to_matrix(A.color)
			flat.MapColors(c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12],c[13],c[14],c[15],c[16],c[17],c[18],c[19],c[20])
		else
			if(A.color)
				flat.Blend(A.color, ICON_MULTIPLY)
			if(A.alpha < 255)
				flat.Blend(rgb(255, 255, 255, A.alpha), ICON_MULTIPLY)

		if(no_anim)
			//Clean up repeated frames
			var/icon/cleaned = new /icon()
			cleaned.Insert(flat, "", SOUTH, 1, 0)
			. = cleaned
		else
			. = icon(flat, "", SOUTH)
	else	//There's no overlays.
		if(!noIcon)
			var/icon/SELF_ICON=icon(icon(curicon, curstate, base_icon_dir),"",SOUTH,no_anim?1:null)
			if(islist(A.color))
				var/list/c = normalize_color_to_matrix(A.color)
				SELF_ICON.MapColors(c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12],c[13],c[14],c[15],c[16],c[17],c[18],c[19],c[20])
			else
				if(A.alpha<255)
					SELF_ICON.Blend(rgb(255,255,255,A.alpha),ICON_MULTIPLY)
				if(A.color)
					SELF_ICON.Blend(A.color,ICON_MULTIPLY)
			. = SELF_ICON

//Converts a blend_mode constant to one acceptable to icon.Blend()
/proc/blendMode2iconMode(blend_mode)
	switch(blend_mode)
		if(BLEND_MULTIPLY)
			return ICON_MULTIPLY
		if(BLEND_ADD)
			return ICON_ADD
		if(BLEND_SUBTRACT)
			return ICON_SUBTRACT
		else
			return ICON_OVERLAY

	//Clear defines
	#undef flatX1
	#undef flatX2
	#undef flatY1
	#undef flatY2
	#undef addX1
	#undef addX2
	#undef addY1
	#undef addY2

	#undef INDEX_X_LOW
	#undef INDEX_X_HIGH
	#undef INDEX_Y_LOW
	#undef INDEX_Y_HIGH
