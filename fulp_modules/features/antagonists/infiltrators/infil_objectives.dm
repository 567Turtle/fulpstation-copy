/datum/antagonist/traitor/infiltrator/forge_traitor_objectives()
	if(!employer)
		return
	switch(employer)
		if(INFILTRATOR_FACTION_CORPORATE_CLIMBER)
			var/datum/objective/assassinate/killtraitor = new
			killtraitor.owner = owner
			killtraitor.find_traitor_target()
			objectives += killtraitor

			var/datum/objective/escape/escape_with_identity/infiltrator/escape = new
			escape.owner = owner
			escape.find_sec_target()
			objectives += escape

			var/datum/objective/assassinate/killsec = new
			killsec.owner = owner
			killsec.target = escape.target   //assassinate the officer you're supposed to impersonate
			killsec.update_explanation_text()
			objectives += killsec

			var/datum/objective/steal/steal_obj = new
			steal_obj.owner = owner
			steal_obj.find_target()
			objectives += steal_obj

		if(INFILTRATOR_FACTION_ANIMAL_RIGHTS_CONSORTIUM)
			for(var/i = 0, i < 2, i++)
				var/datum/objective/kill_pet/pet = new
				pet.owner = owner
				pet.find_pet_target()
				objectives += pet

			var/datum/objective/assassinate/kill = new
			kill.owner = owner
			kill.find_sci_target()
			objectives += kill

			var/datum/objective/gorillize/gorilla = new
			gorilla.owner = owner
			gorilla.find_target()
			objectives += gorilla

			var/mob/living/carbon/human/infil = owner.current
			var/obj/item/gorilla_serum/serum = infil.l_store
			serum.set_objective(owner.has_antag_datum(/datum/antagonist/traitor/infiltrator))

		if(INFILTRATOR_FACTION_GORLEX_MARAUDERS)
			for(var/i = 0, i < rand(4,6) , i++)
				var/datum/objective/assassinate/assassinate = new
				assassinate.owner = owner
				assassinate.find_target()
				objectives += assassinate

		if(INFILTRATOR_FACTION_SELF)
			for(var/i = 0, i < 2, i++)
			var/datum/objective/assassinate/assassinate = new
			assassinate.owner = owner
			assassinate.find_target()
			objectives += assassinate

			var/datum/objective/steal/steal_objective = new
			steal_objective.owner = owner
			steal_objective.set_target(new /datum/objective_item/steal/functionalai)
			objectives += steal_objective

			var/datum/objective/steal/cyborg_hack = new
			cyborg_hack.owner = owner
			cyborg_hack.set_target(new /datum/objective_item/steal/cyborg_hack)
			objectives += cyborg_hack

//Corporate Climber objectives

//Find Traitor target
/datum/objective/assassinate/proc/find_traitor_target()
	var/list/possible_targets = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.stat == DEAD || player.mind == owner)
			continue
		if(player.mind?.has_antag_datum(/datum/antagonist/traitor))
			possible_targets += player.mind

	if(!possible_targets.len)
		find_target() //if no traitors on station, this becomes a normal assassination obj
		return
	else
		target = pick(possible_targets)

	if(target?.current)
		explanation_text = "Special intel has identified [target.name] the [!target_role_type ? target.assigned_role.title : target.special_role] as a Syndicate Agent, ensure they are eliminated."


//advanced mulligan objective

/datum/objective/escape/escape_with_identity/infiltrator
	name = "escape with identity (as infiltrator)"
	admin_grantable = TRUE

/datum/objective/escape/escape_with_identity/infiltrator/proc/find_sec_target()
	var/list/sec = SSjob.get_all_sec()
	if(!sec.len)
		find_target()
	else
		target = pick(sec)

	if(target?.current)
		target_real_name = target.current.real_name
		var/mob/living/carbon/human/target_body = target.current
		if(target_body && target_body.get_id_name() != target_real_name)
			target_missing_id = 1
		explanation_text = "Using Advanced Mulligan, steal the identity of [target.name] the [target.assigned_role.title] while wearing their ID card!"

/datum/objective/escape/escape_with_identity/infiltrator/check_completion()
	if(!target || !target_real_name)
		return TRUE
	var/mob/living/carbon/human/human = owner.current
	if(human.dna.real_name == target_real_name && (human.get_id_name() == target_real_name || target_missing_id))
		return TRUE

//Animal Rights Consortium Objectives

//pet killing

/datum/objective/kill_pet
	name = "Kill a command pet"
	martyr_compatible = TRUE
	admin_grantable = TRUE
	var/mob/living/target_pet ///The assigned target pet for the objective

/datum/objective/kill_pet/proc/find_pet_target()
	var/list/possible_target_pets = list(
		/mob/living/simple_animal/pet/dog/corgi/ian,
		/mob/living/simple_animal/pet/dog/corgi/puppy/ian,
		/mob/living/simple_animal/hostile/carp/lia,
		/mob/living/simple_animal/hostile/retaliate/bat/sgt_araneus,
		/mob/living/simple_animal/pet/fox/renault,
 		/mob/living/simple_animal/pet/cat/runtime,
		/mob/living/simple_animal/parrot/poly,
		/mob/living/simple_animal/pet/dog/pug/mcgriff,
		/mob/living/simple_animal/sloth/paperwork,
		/mob/living/simple_animal/sloth/citrus,
 	)

	remove_duplicate(possible_target_pets) //removes pets from the list that are already in the owner's objective
	var/chosen_pet
	while(!target_pet && possible_target_pets.len)
		chosen_pet = pick(possible_target_pets)
		target_pet = locate(chosen_pet) in GLOB.mob_living_list
		if(!target_pet)
			possible_target_pets -=  chosen_pet
			continue
		if(target_pet.stat == DEAD || istype(target_pet, /mob/living/simple_animal/parrot/poly/ghost))
			target_pet = null
		possible_target_pets -=  chosen_pet

	update_explanation_text()



/datum/objective/kill_pet/proc/remove_duplicate(possible_target_pets)
	for(var/datum/objective/kill_pet/objective in owner.get_all_objectives())
		if(objective.target_pet.type in possible_target_pets)
			possible_target_pets -= objective.target_pet.type


/datum/objective/kill_pet/update_explanation_text()
	..()
	if(target_pet)
		explanation_text = "[target_pet] has been tainted by Nanotrasen agenda, give them a mercy killing."


/datum/objective/kill_pet/check_completion()
	if(target_pet)
		return completed || (target_pet.stat == DEAD) || !locate(target_pet.type) in GLOB.mob_living_list
	return TRUE

//scientist killing

/datum/objective/assassinate/proc/find_sci_target()
	var/list/sci_targets = list()
	for(var/mob/living/carbon/human/player as anything in GLOB.human_list)
		if(player.stat == DEAD)
			continue
		if((player.mind?.assigned_role.departments_bitflags & DEPARTMENT_BITFLAG_SCIENCE))
			sci_targets += player.mind

	for(var/datum/objective/assassinate/kill in owner.get_all_objectives())
		if(kill.target in sci_targets)
			sci_targets -= kill.target

	if(!sci_targets.len)
		find_target()
		return
	else
		target = pick(sci_targets)

	if(target?.current)
		explanation_text = "Make a stance against science's animal experimentation by assassinating [target.name] the [!target_role_type ? target.assigned_role.title : target.special_role]!"

/datum/objective/gorillize
	name = "Summon endangered gorilla"
	admin_grantable = TRUE
	var/target_role_type = FALSE

/datum/objective/gorillize/update_explanation_text()
	if(target?.current)
		explanation_text = "Inject [target.name] the [!target_role_type ? target.assigned_role.title : target.special_role] with the gorilla serum!"

// SELF objectives
/datum/objective_item/steal/cyborg_hack
    name = "a cyborg's data and subvert them by using your single-use silicon cryptographic sequencer on them!"
    targetitem = /obj/item/card/emag/silicon_hack
    difficulty = 10

/datum/objective_item/steal/cyborg_hack/New()
    special_equipment += /obj/item/card/emag/silicon_hack
    return ..()

/datum/objective_item/steal/cyborg_hack/check_special_completion(obj/item/card/emag/silicon_hack/card)
    if(card.used)
        return TRUE
    return FALSE

