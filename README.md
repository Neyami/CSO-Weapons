Weapons from Counter-Strike Online ported to Sven Co-op in Angelscript.  

CREDITS:  
Nexon for the models, textures, sounds, and sprites.  
Sven Co-op hands courtesy of DNIO071, Garompa, Nova, Föur-Nïnes  
AS Plugins by me, sometimes with code converted from various AMXX plugins.


Some of the weapons aren't 100% finished but they're mostly tweaks such as muzzleflashes, animations, bulletspread, damage, and such.

The plugin `custom_weapons-cso.as` can be used if you're not using a buymenu plugin to register the weapons, the `give` command can be used, but I would recommend using AFBase for the `.player_give` command (among many other extremely useful things)

https://github.com/Zode/AFBase

If you don't use my plugin, then you'll have to put this in another plugin that you've got, such as a buymenu.

`#include "../custom_weapons/cso/csobaseweapon"`  
`#include "../custom_weapons/cso/csocommon"`  

Set bUseDroppedItemEffect to false in csocommon.as if you don't want to use CSO-like dropped weapons.  
Change USE_CSLIKE_RECOIL and USE_PENETRATION in some weapons to your preference.  
Some weapons have 3 different hand models (Male, Female, Sven Co-op) that can be switched with TertiaryAttack.

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

* Ripper

    * ENTITIES
    * `weapon_ripper` - Weapon

    * AMMO NAME
    * `ripperammo`

<BR>

* Dual Sword Phantom Slayer
    * ENTITIES
    * `weapon_dualsword` - Weapon
    * `ef_dualsword` - Various Effects

<BR>


# PISTOLS
* Glock 18

    * ENTITIES
    * `weapon_glock18` - Weapon
 
    * AMMO NAME
    * `glock18ammo` (9mm)

<BR>

* Beretta 92G Elite II

    * ENTITIES
    * `weapon_elites` - Weapon
 
    * AMMO NAME
    * `9mm`

<BR>

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

* Dual Beretta Gunslinger
    * [Video](https://youtu.be/mQSxw8vazlg) - [Video2](https://youtu.be/dNz_p7xw-G0)

    * ENTITIES
    * `weapon_gunkata` - Weapon
    * `ef_gunkata` - Wooshing Effect
    * `ef_gunkatablast` - Blast effect
    * `ef_gunkataweapon` - First person view extra weapon animations
    * `ef_gunkatashadow` - Shadow Effect
 
    * AMMO NAME
    * `gunkataammo`

<BR>

* Winchester M1887 Maverick

    * ENTITIES
    * `weapon_m1887craft` - Weapon
 
    * AMMO NAME
    * `buckshot`

<BR>

* CROW-1

    * ENTITIES
    * `weapon_crow1` - Weapon
 
    * AMMO NAME
    * `crow1ammo` (9mm)

<BR>




# SHOTGUNS
* Benelli M3

    * ENTITIES
    * `weapon_m3` - Weapon
 
    * AMMO NAME
    * `buckshot`


<BR>

* Daewoo USAS-12

    * ENTITIES
    * `weapon_usas12` - Weapon
 
    * AMMO NAME
    * `buckshot`

<BR>

* Winchester M1887

    * ENTITIES
    * `weapon_m1887` - Weapon
 
    * AMMO NAME
    * `buckshot`

<BR>

* Quad-barreled shotgun

    * ENTITIES
    * `weapon_qbarrel` - Weapon
 
    * AMMO NAME
    * `buckshot`

<BR>

* SKULL-11
    * [Video](https://www.youtube.com/watch?v=BYXfCY4s3Lk)

    * ENTITIES
    * `weapon_skull11` - Weapon
 
    * AMMO NAME
    * `buckshot`

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

* Brick Piece M777
    * [Video](https://youtu.be/7mOEY7KNsA0)

    * ENTITIES
    * `weapon_blockas` - Weapon
    * `block_missile` - Projectile
 
    * AMMO NAME
    * `buckshot`
    * `m777shot`

<BR>


# SUBMACHINE GUNS  
* FN P90

    * ENTITIES
    * `weapon_p90` - Weapon
 
    * AMMO NAME
    * `p90ammo`

<BR>

* CROW-3
    * [Video](https://youtu.be/dIPY_jT4ArQ)

    * ENTITIES
    * `weapon_crow3` - Weapon
 
    * AMMO NAME
    * `9mm`

<BR>


* Thompson M1928

    * ENTITIES
    * `weapon_thompson` - Weapon
 
    * AMMO NAME
    * `thompsonammo`

<BR>



# ASSAULT RIFLES
* AK-47

    * ENTITIES
    * `weapon_ak47` - Weapon
 
    * AMMO NAME
    * `ak47ammo`


<BR>


* Steyr AUG A1

    * ENTITIES
    * `weapon_aug` - Weapon
 
    * AMMO NAME
    * `556`


<BR>


* Lightning AR-1
    * [Video](https://youtu.be/jmp9SVYchD0)

    * ENTITIES
    * `weapon_guitar` - Weapon
    * `ef_guitar` - Note effects
 
    * AMMO NAME
    * `556`

<BR>


* Ethereal

    * ENTITIES
    * `weapon_ethereal` - Weapon
 
    * AMMO NAME
    * `etherealammo`

<BR>


* Crossbow
    * [Video](https://youtu.be/A9f2aC1fSUU)

    * ENTITIES
    * `weapon_csocrossbow` - Weapon
 
    * AMMO NAME
    * `csoxbowammo`

<BR>


* Plasma Gun

    * ENTITIES
    * `weapon_plasmagun` - Weapon
    * `ammo_plasmashell` - Ammo
    * `plasmaball` - Projectile
 
    * AMMO NAME
    * `plasma`


<BR>



* Burning AUG

    * ENTITIES
    * `weapon_augex` - Weapon
    * `augex_grenade` - Projectile
 
    * AMMO NAME
    * `augexammo1`
    * `augexammo2`


<BR>


* AK-47 Paladin

    * ENTITIES
    * `weapon_buffak` - Weapon
    * `csoproj_buffak` - Projectile
 
    * AMMO NAME
    * `buffak47ammo`


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


* CROW-5

    * ENTITIES
    * `weapon_crow5` - Weapon
 
    * AMMO NAME
    * `crow5ammo` (556)


<BR>



# SNIPER RIFLES
* Accuracy International AWP

    * ENTITIES
    * `weapon_awp` - Weapon
 
    * AMMO NAME
    * `m40a1`

<BR>


* Cheytac M200

    * ENTITIES
    * `weapon_m400` - Weapon
    * `ammo_762` - Ammo
 
    * AMMO NAME
    * `m40a1`

<BR>


* Barrett M95

    * ENTITIES
    * `weapon_m95` - Weapon
 
    * AMMO NAME
    * `m95ammo`

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
    * `net_shot` - Net Projectile
    * `net_hit` - Net Holding Mobs
    * `m95_tiger` - Skill Tiger
    * `ef_claw` - Skill Hit Effect
 
    * AMMO NAME
    * `m95tigerammo`
    * `m95tigernets`

<BR>


* Dragunov SVD

    * ENTITIES
    * `weapon_svd` - Weapon
 
    * AMMO NAME
    * `m40a1`

<BR>


* SVD Custom
    * [Video](https://youtu.be/yWXAxLXlhNU)

    * ENTITIES
    * `weapon_svdex` - Weapon
    * `svd_rocket` - Projectile
 
    * AMMO NAME
    * `m40a1`
    * `ARgrenades`

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
 
    * AMMO NAME
    * `m134heroammo`


<BR>


* M2 Browning
    * [Video1](https://youtu.be/UclXLsp09EU)

    * ENTITIES
    * `weapon_m2` - Weapon
 
    * AMMO NAME
    * `m2ammo`

<BR>


* CROW-7

    * ENTITIES
    * `weapon_crow7` - Weapon
 
    * AMMO NAME
    * `crow7ammo` (556)


<BR>


# EXPLOSIVES
* M136 AT4

    * ENTITIES
    * `weapon_at4` - Weapon
    * `at4rocket` - Projectile
 
    * AMMO NAME
    * `rockets`

<BR>


* AT4-CS
    * [Video](https://www.youtube.com/watch?v=7DhqGnh572c)

    * ENTITIES
    * `weapon_at4ex` - Weapon
    * `at4exrocket` - Projectile
 
    * AMMO NAME
    * `rockets`

<BR>


# OTHER
* Salamander Flamethrower
    * [Video](https://youtu.be/-SwjvvFgoIo)

    * ENTITIES
    * `weapon_salamander` - Weapon
    * `csoproj_flame` - Projectile
 
    * AMMO NAME
    * `salamanderammo`

<BR>
