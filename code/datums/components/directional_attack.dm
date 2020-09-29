/datum/component/directional_attack
	var/active = TRUE

/datum/component/directional_attack/Initialize()
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(active)
		RegisterSignal(parent, COMSIG_MOB_CLICKON, .proc/select_directional_action)

/datum/component/directional_attack/Destroy(force, silent)
    QDEL_NULL(toggle_action)
    return ..()

/datum/component/directional_attack/RegisterWithParent()
	RegisterSignal(parent, COMSIG_DIRECTIONAL_ATTACK_ACTIVE, .proc/attack_active)

/datum/component/directional_attack/proc/attack_active()
	if(active)
		return COMPONENT_DIRECTIONAL_ATTACK_GO

/datum/component/directional_attack/proc/select_directional_action(datum/source, atom/A, params)
	if(isxeno(parent))
		xeno_directional_action(A, params)
	else if(ishuman(parent))
		human_directional_action(A, params)
	else
		living_directional_action(A, params)

/datum/component/directional_attack/proc/living_directional_action_checks(mob/living/L)
	var/mob/living/carbon/attacker = parent
	if(COOLDOWN_CHECK(src, COOLDOWN_DIRECTIONAL_ATTACK))
		return NONE
	if(L.throwing)
		return NONE
	if(attacker.get_active_held_item())
		return NONE //We have something in our hand.

/datum/component/directional_attack/proc/carbon_directional_action_checks(mob/living/L)
	var/mob/living/carbon/attacker = parent
	. = living_directional_action_checks(L)
	if(!isnull(.))
		return NONE
	if(QDELETED(L))
		return NONE
	switch(attacker.a_intent)
		if(INTENT_HELP, INTENT_GRAB)
			return NONE
	
/datum/component/directional_attack/proc/figure_out_living_target(atom/target)
	var/clickDir = get_dir(parent, target)
	var/turf/presumedPos = get_step(parent, clickDir)
	var/mob/living/L = locate() in presumedPos
	if(presumedPos == get_turf(target) && L == null)
		return target
	return L

/datum/component/directional_attack/proc/living_directional_action(atom/A, params)
	var/atom/T
	if(isturf(A))
		T = A
	else
		T = get_turf(A)
	var/atom/hold = figure_out_living_target(T)
	if (isnull(hold))
		return
	if(isturf(hold))
		hold = A
	if(isliving(hold))
		var/mob/living/L = hold
		. = living_directional_action_checks(L)
		if(!isnull(.))
			return
	else 
		if(COOLDOWN_CHECK(src, COOLDOWN_DIRECTIONAL_ATTACK))
			return
	return living_do_directional_action(hold)

/datum/component/directional_attack/proc/human_directional_action(atom/A, params)
	var/atom/T
	if(!isturf(A))
		T = A
	else 
		T = get_turf(A)
	var/mob/living/carbon/human/attacker = parent
	var/atom/hold = figure_out_living_target(T)
	if (isnull(hold))
		return
	if(isturf(hold))
		hold = A
	if(isliving(hold))
		var/mob/living/L = hold
		. = carbon_directional_action_checks(L)
		if(!isnull(.))
			return
		if(attacker.faction == L.faction)
			return //FF
	else 
		if(COOLDOWN_CHECK(src, COOLDOWN_DIRECTIONAL_ATTACK))
			return
	return living_do_directional_action(hold)

/datum/component/directional_attack/proc/xeno_directional_action(atom/A, params)
	var/atom/T
	if(!isturf(A))
		T = A
	else 
		T = get_turf(A)
	var/mob/living/carbon/xenomorph/attacker = parent
	var/atom/hold = figure_out_living_target(T)
	if (isnull(hold))
		return
	if(isturf(hold))
		hold = A
	if(isliving(hold))
		var/mob/living/L = hold
		. = carbon_directional_action_checks(L)
		if(!isnull(.))
			return
		if(attacker.issamexenohive(L))
			return //No more nibbling.
	else 
		if(COOLDOWN_CHECK(src, COOLDOWN_DIRECTIONAL_ATTACK))
			return
	return living_do_directional_action(hold)

/datum/component/directional_attack/proc/living_do_directional_action(atom/target)
	var/mob/living/attacker = parent
	attacker.UnarmedAttack(target, TRUE)
	COOLDOWN_START(src, COOLDOWN_DIRECTIONAL_ATTACK, CLICK_CD_MELEE)


