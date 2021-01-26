#define FREQ_LISTENING (1<<0)

/obj/machinery/computer/intercom_control
	name = "intercom control console"
	desc = "Used to remotely control the settings of station intercoms."
	icon_screen = "comm_monitor"
	icon_keyboard = "generic_key"
	req_access = list(ACCESS_HEADS)
	circuit = /obj/item/circuitboard/computer/apc_control
	light_color = LIGHT_COLOR_GREEN
	var/mob/living/operator //Who's operating the computer right now
	var/obj/item/radio/intercom/active_intercom //The intercom we're using right now
	var/should_log = TRUE
	var/restoring = FALSE
	var/list/logs
	var/auth_id = "\[NULL\]:"
	var/frequency = FREQ_COMMON
	var/broadcasting = FALSE  // Whether the radio will transmit dialogue it hears nearby.
	var/listening = TRUE  // Whether the radio is currently receiving.


/obj/machinery/computer/intercom_control/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	logs = list()

/obj/machinery/computer/intercom_control/process()
	if(operator && (!operator.Adjacent(src) || machine_stat))
		operator = null
		if(active_intercom)
			active_intercom.update_icon()
			active_intercom.remote_control = null
			active_intercom = null


/obj/machinery/computer/intercom_control/proc/check_intercom(obj/item/radio/intercom/INTERCOM)
	return INTERCOM.z == z && !(INTERCOM.obj_flags & EMAGGED) && !istype(INTERCOM.area, /area/ai_monitored) && !(INTERCOM.area.area_flags & NO_ALERTS)

/obj/machinery/computer/intercom_control/ui_interact(mob/user, datum/tgui/ui)
	operator = user
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntercomControl")
		ui.open()

/obj/machinery/computer/intercom_control/ui_data(mob/user)
	var/list/data = list()
	data["auth_id"] = auth_id
	data["authenticated"] = authenticated
	data["emagged"] = obj_flags & EMAGGED
	data["logging"] = should_log
	data["restoring"] = restoring
	data["logs"] = list()
	data["intercoms"] = list()

	for(var/entry in logs)
		data["logs"] += list(list("entry" = entry))

	for(var/intercom in GLOB.intercom_list)
		if(check_intercom(intercom))
			var/obj/item/radio/intercom/A = intercom
			data["intercoms"] += list(list(
					"name" = A.intercom_tag,
					"operating" = A.operating,
					"frequency" = A.frequency,
					"minFrequency" = A.freerange ? MIN_FREE_FREQ : MIN_FREQ,
					"maxFrequency" = A.freerange ? MAX_FREE_FREQ : MAX_FREQ,
					"channels" = A.channels,
					"broadcasting" = A.broadcasting,
					"listening" = A.listening,
					"ref" = REF(A)
				)
			)
	return data

/obj/machinery/computer/intercom_control/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("log-in")
			if(obj_flags & EMAGGED)
				authenticated = TRUE
				auth_id = "Unknown (Unknown):"
				log_activity("[auth_id] logged in to the terminal")
				return
			var/obj/item/card/id/ID = operator.get_idcard(TRUE)
			if(ID && istype(ID))
				if(check_access(ID))
					authenticated = TRUE
					auth_id = "[ID.registered_name] ([ID.assignment]):"
					log_activity("[auth_id] logged in to the terminal")
					playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)
				else
					auth_id = "[ID.registered_name] ([ID.assignment]):"
					log_activity("[auth_id] attempted to log into the terminal")
				return
			auth_id = "Unknown (Unknown):"
			log_activity("[auth_id] attempted to log into the terminal")
		if("log-out")
			log_activity("[auth_id] logged out of the terminal")
			playsound(src, 'sound/machines/terminal_off.ogg', 50, FALSE)
			authenticated = FALSE
			auth_id = "\[NULL\]"
		if("toggle-logs")
			should_log = !should_log
			log_game("[key_name(operator)] set the logs of [src] in [AREACOORD(src)] [should_log ? "On" : "Off"]")
		if("restore-console")
			restoring = TRUE
			addtimer(CALLBACK(src, .proc/restore_comp), rand(3,5) * 9)
		if("access-intercom")
			var/ref = params["ref"]
			playsound(src, "terminal_type", 50, FALSE)
			var/obj/item/radio/intercom/INTERCOM = locate(ref) in GLOB.intercom_list
			if(!INTERCOM)
				return
			if(active_intercom)
				to_chat(operator, "<span class='robot danger'>[icon2html(src, auth_id)] Disconnected from [active_intercom].</span>")
				active_intercom.say("Remote access canceled. Interface locked.")
				playsound(active_intercom, 'sound/machines/boltsdown.ogg', 25, FALSE)
				playsound(active_intercom, 'sound/machines/terminal_alert.ogg', 50, FALSE)
				active_intercom.update_icon()
				active_intercom.remote_control = null
				active_intercom = null
			INTERCOM.remote_control = src
			INTERCOM.ui_interact(operator)
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			log_game("[key_name(operator)] remotely accessed [INTERCOM] from [src] at [AREACOORD(src)].")
			log_activity("[auth_id] remotely accessed intercom in [get_area_name(INTERCOM.area, TRUE)]")
			INTERCOM.update_icon()
			active_intercom = INTERCOM
		if("check-logs")
			log_activity("Checked Logs")
		if("check-intercoms")
			log_activity("Checked Intercoms")
		if("frequency")
			var/ref = params["ref"]
			var/obj/item/radio/intercom/target = locate(ref) in GLOB.intercom_list
			var/tune = params["tune"]
			var/adjust = text2num(params["adjust"])
			if(!target)
				return
			target.update_icon()
			if(adjust)
				tune = target.frequency + adjust * 10
				. = TRUE
			else if(text2num(tune) != null)
				tune = tune * 10
				. = TRUE
			if(.)
				target.set_frequency(sanitize_frequency(tune, FALSE))
		if("listen")
			var/ref = params["ref"]
			var/obj/item/radio/intercom/target = locate(ref) in GLOB.intercom_list
			target.listening = !target.listening
			. = TRUE
		if("broadcast")
			var/ref = params["ref"]
			var/obj/item/radio/intercom/target = locate(ref) in GLOB.intercom_list
			target.broadcasting = !target.broadcasting
			. = TRUE
		if("toggle-minor")
			var/ref = params["ref"]
			var/type = params["type"]
			var/obj/item/radio/intercom/target = locate(ref) in GLOB.intercom_list
			if(!target)
				return
			if(type == "broadcasting")
				target.broadcasting = !target.broadcasting
			. = TRUE
			if(type == "listening")
				target.listening = !target.listening
			. = TRUE
			target.update_icon()
			var/setTo = ""
			switch(target.vars[type])
				if(0)
					setTo = "Off"
				if(1)
					setTo = "On"
			log_activity("Set Intercom [target.intercom_tag] [type] to [setTo]")
			log_game("[key_name(operator)] Set Intercom [target.intercom_tag] [type] to [setTo]]")
		if("breaker")
			var/ref = params["ref"]
			var/obj/item/radio/intercom/target = locate(ref) in GLOB.intercom_list
			var/setTo = target.operating ? "On" : "Off"
			log_activity("Turned Intercom [target.intercom_tag]'s breaker [setTo]")

/obj/machinery/computer/intercom_control/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	log_game("[key_name(user)] emagged [src] at [AREACOORD(src)]")
	playsound(src, "sparks", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/machinery/computer/intercom_control/proc/log_activity(log_text)
	if(!should_log)
		return
	LAZYADD(logs, "([station_time_timestamp()]): [auth_id] [log_text]")

/obj/machinery/computer/intercom_control/proc/restore_comp()
	obj_flags &= ~EMAGGED
	should_log = TRUE
	log_game("[key_name(operator)] restored the logs of [src] in [AREACOORD(src)]")
	log_activity("-=- Logging restored to full functionality at this point -=-")
	restoring = FALSE

/mob/proc/using_intercom_control_console()
	for(var/obj/machinery/computer/intercom_control/A in range(1, src))
		if(A.operator && A.operator == src && !A.machine_stat)
			return TRUE
	return
