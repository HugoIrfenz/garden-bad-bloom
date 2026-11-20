extends RefCounted

const Abilities = preload("res://scripts/hero_abilities.gd")
const Ultimates = preload("res://scripts/hero_ultimates.gd")
const Guests = preload("res://scripts/guest_combat.gd")
const Weapons = preload("res://scripts/weapon_catalog.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const LunaCombat = preload("res://scripts/luna_combat.gd")

const SKILL := 0
const ULTIMATE := 1
const FREEZE := 2
const DODGE := 3

static func skill(hero: int) -> Dictionary:
	var cooldown := "%.2fs" % Abilities.cooldown_for(hero)
	match hero:
		0:
			return {"damage": "+10–20 on a perfect counter", "cooldown": "%.0fs on miss · %.0fs after a block" % [Abilities.GUARD_UNUSED_RECHARGE, Abilities.GUARD_ABSORB_RECHARGE],
				"detail": "Block from any direction for %.1fs. Block in the first %.2fs to earn extra Resolve and prime your next landed strike. More Resolve strengthens the counter." % [Abilities.GUARD_DURATION, Abilities.PERFECT_WINDOW]}
		1:
			return {"damage": "20–40 per target", "cooldown": cooldown,
				"detail": "Call a rose burst around the nearest enemy in range. Each point of Ink spent adds 4 damage. Cover can block the burst."}
		2:
			return {"damage": "12–22 leap · 18–28 per follow-up", "cooldown": "Instant on hit · %.0fs on miss" % Abilities.cooldown_for(hero),
				"detail": "Leap into a cone punch. The first target hit can take two follow-ups if it stays in reach. Each point of Momentum adds 2 damage."}
		3:
			return {"damage": "0 with the starter bow", "cooldown": cooldown,
				"detail": "Dash in your facing direction and briefly avoid damage. Sewing Thread lets two casts link into a snaring tripwire."}
		4:
			return {"damage": "14–24 dash · 6–11 trail", "cooldown": cooldown,
				"detail": "Cut through enemies and leave a paint trail that damages foes who cross it. Both hits scale with the Spark you spend."}
		5:
			return {"damage": "Battle Temper adds up to %d%%" % roundi(Guests.TEMPER_BONUS * 100.0),
				"cooldown": "%.0fs from activation" % Guests.RAGE_COOLDOWN,
				"detail": "Rage gives +%d%% attack speed and +%d%% movement speed for %.0fs. Battle Temper still builds during combat and resets when the fight ends." % [
					roundi((Guests.RAGE_ATTACK_SPEED - 1.0) * 100.0), roundi((Guests.RAGE_MOVE_SPEED - 1.0) * 100.0), Guests.RAGE_TIME]}
		6:
			return {"damage": "Holy 12 · Mercy 6 · Ray 7", "cooldown": "Switch freely · %.2fs per cast" % Weapons.STARTER_INTERVAL[6],
				"detail": "Holy targets a single enemy at any distance. Mercy hits nearby enemies and heals 1 HP on hit. Ray pierces a line. Hit with all three to unleash Fivefold Judgment."}
		GuestRoster.LUNA:
			var pistol := Weapons.item(Weapons.starter(hero))
			return {"damage": "%d per Glock shot · %d per claw" % [pistol.damage, LunaCombat.CLAW_DAMAGE],
				"cooldown": "%.2fs per Glock shot · %.2fs per claw" % [pistol.interval, LunaCombat.CLAW_INTERVAL],
				"detail": "Land pistol shots within %d pixels to fill the Transformation Gauge. Cover stops shots. In wolf form, attack with short-range claws." % int(pistol.reach)}
	return {}

static func ultimate(hero: int) -> Dictionary:
	var charge := "%d charge" % Ultimates.CHARGE
	match hero:
		0:
			return {"damage": "%d wave · +13 on the aura counter" % Ultimates.BLADE_WAVE_DAMAGE, "cooldown": "%s · %.0fs after Valkyrie ends" % [charge, Ultimates.VALKYRIE_RECOVERY],
				"detail": "Send out a piercing blade wave, then enter Valkyrie form for %.1fs. Attack and recover your shield faster, take reduced damage, and resist knockback." % Ultimates.AURA_TIME}
		1:
			return {"damage": "13 / 16 / 19 · +9 in overlapping areas", "cooldown": charge,
				"detail": "Call three thorn bursts in front of you. A burst hits harder where it overlaps Midnight Verse or an earlier burst. Rosebound Refrain echoes all three at half power."}
		2:
			return {"damage": "20 total · 6 on collateral hits", "cooldown": "%s · %.0fs recovery" % [charge, Ultimates.BREACH_RECOVERY],
				"detail": "Stagger nearby enemies with three quick hits and launch regular foes with the finisher. Launched foes can damage enemies in their path."}
		3:
			return {"damage": "12 per arrow before mark bonuses", "cooldown": charge,
				"detail": "Fire a spread of five arrows. Each enemy can take up to two hits. Marked enemies take extra damage."}
		4:
			return {"damage": "12 / 18 / 24 · +12 on painted targets", "cooldown": charge,
				"detail": "Dash and slash three times. Each enemy can take up to two hits. An existing Graffiti Cut trail adds an opening slash for 11 damage."}
		5:
			return {"damage": "6 per hit before Battle Temper", "cooldown": charge,
				"detail": "Keep landing hits to spin longer. Heal %d HP at %.0fs and again at %.0fs. Hitting cover stuns you for %.0fs. Overlong spins leave you dizzy." % [Guests.SPIN_HEAL, Ultimates.SPIN_HEAL_INTERVAL, Ultimates.SPIN_HEAL_INTERVAL * 2.0, Guests.SPIN_STUN_TIME]}
		6:
			return {"damage": "Judgment 8 × 5 · Trance Holy 9", "cooldown": "Automatic · two combos in %.0fs" % Guests.JUDGMENT_WINDOW,
				"detail": "Each three-stance combo fires five strikes at random enemies. Complete two combos within %.0fs to enter a %.0fs trance and cast rapid Holy attacks." % [Guests.JUDGMENT_WINDOW, Guests.TRANCE_TIME]}
		GuestRoster.LUNA:
			return {"damage": "%d per claw · %d per wolf dash hit" % [LunaCombat.CLAW_DAMAGE, LunaCombat.WOLF_DASH_DAMAGE],
				"cooldown": "%d landed pistol shots" % LunaCombat.SHOTS_REQUIRED,
				"detail": "Shift into wolf form for %.1fs. Claw and chain damaging dashes until the frenzy fades. Your gauge empties on transformation." % LunaCombat.FRENZY_TIME}
	return {}

static func freeze() -> Dictionary:
	return {"damage": "5 per target", "cooldown": "%.1fs" % Abilities.FROST_RECHARGE,
		"detail": "Send out a frost burst at a nearby enemy. It briefly freezes regular enemies and can stagger most bosses. Freeze replaces Vivianne’s Dodge."}

static func dodge() -> Dictionary:
	return {"damage": "0 human · %d per target as wolf" % LunaCombat.WOLF_DASH_DAMAGE,
		"cooldown": "%.2fs human · chain as wolf" % LunaCombat.HUMAN_DODGE_CD,
		"detail": "Step clear of attacks in human form. In wolf form, dash through enemies. Each dash hits a target once and protects you briefly at its start."}
