Weapons from Counter-Strike Online ported to Sven Co-op in Angelscript.  

CREDITS:  
Nexon for the models, textures, sounds, and sprites.  
Sven Co-op hands courtesy of DNIO071  
AS Plugins by me, sometimes with code converted from various AMXX plugins.


Some of the weapons aren't 100% finished but they're mostly tweaks such as muzzleflashes, animations, bulletspread, damage, and such.

It'll look really messy but should be relatively easy to use anyway.

Hopefully I can make it better in the future, but health reasons and being busy IRL currently prevents me from doing so.

The plugin `custom_weapons-cso.as` can be used if you're not using a buymenu plugin to register the weapons, the `give` command can be used, but I would recommend using AFBase for the `.player_give` command (among many other extremely useful things)

https://github.com/Zode/AFBase

If you don't use my plugin, then you'll have to put this in another plugin that you've got, such as a buymenu.

`#include "../custom_weapons/cso/csobaseweapon"`  
`#include "../custom_weapons/cso/csocommon"`  

Set bUseDroppedItemEffect to true in csocommon.as if you want to use CSO-like dropped weapons  
Change USE_CSLIKE_RECOIL and USE_PENETRATION in weapon_aug and weapon_augex to your preference.  
Some weapons have 3 different hand models (Male, Female, Sven Co-op) that can be switched with TertiaryAttack

<BR>

# MELEE
* BALROG-IX
    * [Video](https://youtu.be/o5kG6LZiBlM)

    * ENTITIES
    * `weapon_balrog9` - Weapon

<BR>

* Dragon Claw
    * [Video](https://youtu.be/yhOwNG_B25M)

    * ENTITIES
    * `weapon_dragonclaw` - Weapon

<BR>

* JANUS-9
    * [Video1](https://youtu.be/owMgJFILI-w) - [Video2](https://youtu.be/yf02rPy7KAo)

    * ENTITIES
    * `weapon_janus9` - Weapon

<BR>

* THANATOS-9
    * [Video1](https://youtu.be/OaEFiLME8LQ) - [Video2](https://youtu.be/rFWrYytDOpc)

    * ENTITIES
    * `weapon_thanatos9` - Weapon

<BR>

* Dual Wakizashi	

    * ENTITIES
    * `weapon_dualwaki` - Weapon

<BR>

* Beam Sword
  * [Video](https://youtu.be/RDDUPTiOmNQ)

    * ENTITIES
    * `weapon_beamsword` - Weapon

<BR>

* Dual Sword Phantom Slayer
    * ENTITIES
    * `weapon_dualsword` - Weapon
    * `ef_dualsword` - Various Effects

<BR>


# PISTOLS
* Calico M950
    * [Video](https://youtu.be/unMsubpPTUQ)

    * ENTITIES
    * `weapon_m950` - Weapon
 
    * AMMO NAME
    * `9mm`

<BR>

* Python Desperado
    * [Video](https://youtu.be/Q2NYPb8EBTg?si=qQ1JgZLca-3g85fj)

    * ENTITIES
    * `weapon_desperado` - Weapon
 
    * AMMO NAME
    * `357`

<BR>

* SKULL-2
    * [Video](https://youtu.be/z6jt6cxAdCo)

    * ENTITIES
    * `weapon_skull2` - Weapon
 
    * AMMO NAME
    * `357`

<BR>

* Desert Eagle Crimson Hunter
    * [Video](https://youtu.be/sxIQScNbdJI)

    * ENTITIES
    * `weapon_bloodhunter` - Weapon
    * `bloodgrenade` - Grenade
    * `bloodhunter_effect` - Blood Siphon Effect
 
    * AMMO NAME
    * `357`

<BR>


# SHOTGUNS
* Brick Piece M777
    * [Video](https://youtu.be/7mOEY7KNsA0)

    * ENTITIES
    * `weapon_blockas` - Weapon
    * `block_missile` - Projectile
 
    * AMMO NAME
    * `buckshot`
    * `m777shot`

<BR>

* BALROG-XI REMOVED FOR NOW
    * [Video](https://youtu.be/QV1UfLhlgrE)

    * ENTITIES
    * `weapon_balrog11` - Weapon
    * `balrog11_fire` - Projectile
 
    * AMMO NAME
    * `buckshot`
    * `b11shot`

<BR>

* Volcano

    * ENTITIES
    * `weapon_volcano` - Weapon
 
    * AMMO NAME
    * `buckshot`

<BR>

* Pancor Jackhammer MK3A1

    * ENTITIES
    * `weapon_mk3a1` - Weapon
 
    * AMMO NAME
    * `buckshot`

<BR>


# SUBMACHINE GUNS  
* CROW-3
    * [Video](https://youtu.be/dIPY_jT4ArQ)

    * ENTITIES
    * `weapon_crow3` - Weapon
 
    * AMMO NAME
    * `9mm`

<BR>

* FN P90

    * ENTITIES
    * `weapon_p90` - Weapon
    * `ammo_57mm` - Ammo
 
    * AMMO NAME
    * `57mm`

<BR>


# ASSAULT RIFLES
* Steyr AUG A1

    * ENTITIES
    * `weapon_aug` - Weapon
 
    * AMMO NAME
    * `556`


<BR>


* Plasma Gun

    * ENTITIES
    * `weapon_plasmagun` - Weapon
    * `ammo_plasmashell` - Ammo
    * `plasmaball` - Projectile
 
    * AMMO NAME
    * `plasma`


<BR>


* Compound Bow

    * ENTITIES
    * `weapon_csobow` - Weapon
    * `ammo_csoarrows` - Ammo
    * `csoarrow` - Projectile
 
    * AMMO NAME
    * `csoarrows`


<BR>


* Failnaught

    * ENTITIES
    * `weapon_failnaught` - Weapon
    * `holyarrow` - Projectile
    * `ammo_holyarrows` - Ammo
 
    * AMMO NAME
    * `holyarrows`


<BR>


* Burning AUG

    * ENTITIES
    * `weapon_augex` - Weapon
    * `augex_grenade` - Projectile
 
    * AMMO NAME
    * `556`
    * `ARgrenades`


<BR>


# SNIPER RIFLES
* Accuracy International AWP

    * ENTITIES
    * `weapon_awp` - Weapon
 
    * AMMO NAME
    * `m40a1`

<BR>


* Barrett M95

    * ENTITIES
    * `weapon_m95` - Weapon
    * `ammo_50bmg` - Ammo
 
    * AMMO NAME
    * `50bmg`

<BR>


* Savery

    * ENTITIES
    * `weapon_savery` - Weapon
 
    * AMMO NAME
    * `m40a1`

<BR>


* Barrett M95 White Tiger

    * ENTITIES
    * `weapon_m95tiger` - Weapon
    * `ammo_50bmg` - Ammo
    * `net_shot` - Net Projectile
    * `net_hit` - Net Holding Mobs
    * `m95_tiger` - Skill Tiger
    * `ef_claw` - Skill Hit Effect
 
    * AMMO NAME
    * `50bmg`

<BR>


# MACHINE GUNS
* Aeolis
    * [Video](https://youtu.be/Komeh8zz1Jc)

    * ENTITIES
    * `weapon_aeolis` - Weapon
    * `csoproj_flame` - Projectile
 
    * AMMO NAME
    * `556`


<BR>


* M134 Vulcan
    * [Video1](https://youtu.be/ilttN8HlO9A) - [Video2](https://youtu.be/dkn2-j5sAt0)

    * ENTITIES
    * `weapon_m134hero` - Weapon
    * `ef_gundrop` - Dropped Item Effect
 
    * AMMO NAME
    * `762mg`
