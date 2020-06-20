/datum/component/directional_attack
	var/active = TRUE
	var/directional_action_path
	var/datum/action/directional_attack_toggle/toggle_action

/datum/component/directional_attack/Initialize()
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	toggle_action = new()
	var/toggle_path
	if(ishuman(parent))
		directional_action_path = .proc/human_directional_action
	else if(isxeno(parent))
		directional_action_path = .proc/xeno_directional_action
	else
		directional_action_path = .proc/living_directional_action
	toggle_path = .proc/living_activation_toggle
	toggle_action.give_action(parent)
	toggle_action.update_button_icon(active)
	RegisterSignal(toggle_action, COMSIG_ACTION_TRIGGER, toggle_path)
	if(active)
		RegisterSignal(parent, COMSIG_CLICK, directional_action_path)
/datum/component/directional_attack/Destroy(force, silent)
    QDEL_NULL(toggle_action)
    return ..()

/datum/component/directional_attack/proc/living_activation_toggle(datum/source)
	var/mob/living/attacker = parent
	active = !active
	to_chat(attacker, "<span class='notice'>You will now [active ? "attack" : "not attack"] enemies in melee range upon clicking in their direction.</span>")
	if(active)
		RegisterSignal(attacker, COMSIG_CLICK, directional_action_path)
	else
		UnregisterSignal(attacker, COMSIG_CLICK, directional_action_path)
	toggle_action.update_button_icon(active)

/datum/component/directional_attack/proc/living_directional_action_checks(mob/living/L)
	if(COOLDOWN_CHECK(src, COOLDOWN_DIRECTIONAL_ATTACK))
		return NONE
	if(L.throwing || L.incapacitated())
		return NONE

/datum/component/directional_attack/proc/carbon_directional_action_checks(mob/living/L)
	var/mob/living/carbon/attacker = parent
	. = living_directional_action_checks(L)
	if(!isnull(.))
		return
	if(QDELETED(L))
		return
	switch(attacker.a_intent)
		if(INTENT_HELP, INTENT_GRAB)
			return NONE
	if(attacker.get_active_held_item())
		return NONE //We have something in our hand.
/datum/component/directional_attack/proc/figure_out_living_target(datum/source, atom/target)
	var/clickDir = get_dir(parent, target)
	var/turf/presumedPos = get_step(parent, clickDir)
	var/mob/living/L = locate() in presumedPos
	return L
/datum/component/directional_attack/proc/living_directional_action(datum/source, target)
	var/atom/targ = target
	var/mob/living/L = figure_out_living_target(targ)
	. = living_directional_action_checks(L)
	if(!isnull(.))
		return
	return living_do_directional_action(L)

/datum/component/directional_attack/proc/human_directional_action(datum/source, target)
	var/atom/targ = target
	var/mob/living/carbon/xenomorph/attacker = parent
	var/mob/living/L = figure_out_living_target(targ)
	. = carbon_directional_action_checks(targ)
	if(!isnull(.))
		return
	if(attacker.faction == L.faction)
		return //FF
	return living_do_directional_action(L)

/datum/component/directional_attack/proc/xeno_directional_action(datum/source, target)
	to_chat(parent, "Target Location: [target]")
	var/atom/targ = target
	var/mob/living/carbon/xenomorph/attacker = parent
	var/mob/living/L = figure_out_living_target(targ)
	. = carbon_directional_action_checks(L)
	if(!isnull(.))
		return
	if(attacker.issamexenohive(L))
		return //No more nibbling.
	return living_do_directional_action(L)


/datum/component/directional_attack/proc/living_do_directional_action(mob/living/L)
	var/mob/living/attacker = parent
	attacker.UnarmedAttack(L, TRUE)
	COOLDOWN_START(src, COOLDOWN_DIRECTIONAL_ATTACK, CLICK_CD_MELEE)
			