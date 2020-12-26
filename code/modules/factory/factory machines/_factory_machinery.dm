/**Basic factory object.
* Objects that are factory but not a subtype are as of writing NULL
* Also please note that the factory component is toggled on and off by the component using a signal from default_unfasten_wrench, so dont worry about it
*/
/obj/machinery/factory
	name = "pipe thing"
	icon = 'icons/obj/factory/factory.dmi'
	icon_state = "belt"
	density = TRUE
	active_power_usage = 30
	use_power = ACTIVE_POWER_USE
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	///factory machinery is always gonna need reagents, so we might aswell put it here
	var/buffer = 50
	///Flags for materials, everything in DEFINES/materials.dm
	var/materials_flags = TRANSPARENT
	///wheter we partake in rcd construction or not

/obj/machinery/factory/Initialize(mapload, bolt = TRUE)
	. = ..()
	anchored = bolt
	create_reagents(buffer, materials_flags)
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS, null, CALLBACK(src, .proc/can_be_rotated))

/obj/machinery/factory/proc/can_be_rotated(mob/user,rotation_type)
	return !anchored

/obj/machinery/factory/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The maximum material display reads: <b>[reagents.maximum_volume] units</b>.</span>"

/obj/machinery/factory/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I)
	return TRUE

/*
/obj/machinery/factory/plunger_act(obj/item/plunger/P, mob/living/user, reinforced)
	to_chat(user, "<span class='notice'>You start furiously plunging [name].</span>")
	if(do_after(user, 30, target = src))
		to_chat(user, "<span class='notice'>You finish plunging the [name].</span>")
		reagents.expose(get_turf(src), TOUCH) //splash on the floor
		reagents.clear_reagents()
*/

/obj/machinery/factory/welder_act(mob/living/user, obj/item/I)
	. = ..()
	if(anchored)
		to_chat(user, "<span class='warning'>The [name] needs to be unbolted to do that!</span")
	if(I.tool_start_check(user, amount=0))
		to_chat(user, "<span class='notice'>You start slicing the [name] apart.</span")
		if(I.use_tool(src, user, (1.5 SECONDS), volume=50))
			deconstruct(TRUE)
			to_chat(user, "<span class='notice'>You slice the [name] apart.</span")
			return TRUE

///We can empty beakers in here and everything
/obj/machinery/factory/input
	name = "input gate"
	desc = "Can be manually filled with materials from crates."
	icon_state = "crate_input"
	//reagent_flags = TRANSPARENT | REFILLABLE
	density = FALSE

/obj/machinery/factory/input/Initialize(mapload, bolt)
	. = ..()
	AddComponent(/datum/component/factory/simple_supply, bolt)

///We can fill beakers in here and everything. we dont inheret from input because it has nothing that we need
/obj/machinery/factory/output
	name = "output gate"
	desc = "A manual output for factory systems, for taking materials directly into crates."
	icon_state = "crate_output"
	//reagent_flags = TRANSPARENT | DRAINABLE
	density = FALSE

/obj/machinery/factory/output/Initialize(mapload, bolt)
	. = ..()
	AddComponent(/datum/component/factory/simple_demand, bolt)

/obj/machinery/factory/rack
	name = "material rack"
	desc = "A massive enclosed material holding rack."
	icon_state = "rack"
	buffer = 400

/obj/machinery/factory/rack/Initialize(mapload, bolt)
	. = ..()
	AddComponent(/datum/component/factory/rack, bolt)
