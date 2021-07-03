/datum/wires/factory
	holder_type = /obj/machinery/factory
	proper_name = "Factory"

/datum/wires/factory/New(atom/holder)
	wires = list(
		WIRE_HACK, WIRE_DISABLE
	)
	add_duds(2)
	..()

/datum/wires/factory/interactable(mob/user)
	if(!..())
		return FALSE
	var/obj/machinery/factory/A = holder
	if(A.panel_open)
		return TRUE

/datum/wires/factory/get_status()
	var/obj/machinery/factory/A = holder
	var/list/status = list()
	status += "The red light is [A.disabled ? "on" : "off"]."
	status += "The blue light is [A.hacked ? "on" : "off"]."
	return status

/datum/wires/factory/on_pulse(wire)
	var/obj/machinery/factory/A = holder
	switch(wire)
		if(WIRE_HACK)
			A.adjust_hacked(!A.hacked)
			addtimer(CALLBACK(A, /obj/machinery/factory.proc/reset, wire), 60)
		if(WIRE_DISABLE)
			A.disabled = !A.disabled
			addtimer(CALLBACK(A, /obj/machinery/factory.proc/reset, wire), 60)

/datum/wires/factory/on_cut(wire, mend)
	var/obj/machinery/factory/A = holder
	switch(wire)
		if(WIRE_HACK)
			A.adjust_hacked(!mend)
		if(WIRE_DISABLE)
			A.disabled = !mend
