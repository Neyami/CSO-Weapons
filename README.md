Weapons from Counter-Strike Online ported to Sven Co-op in Angelscript.


There might be changes made to the game that cause the scripts to fail and there's nothing I can do about it at this time. 
But the fixes should be simple.

Some of the weapons aren't 100% finished but they're mostly tweaks such as muzzleflashes, animations, bulletspread, damage, and such.

It'll look really messy but should be relatively easy to use anyway.

Hopefully I can make it better in the future, but health reasons and being busy IRL currently prevents me from doing so.

The plugin `custom_weapons-cso.as` can be used if you're not using a buymenu plugin to register the weapons, the `give` command can be used, but I would recommend using AFBase for the `.player_give` command (among many other extremely useful things)

https://github.com/Zode/AFBase

<BR>

# MELEE
* BALROG-IX
    * [Video](https://youtu.be/o5kG6LZiBlM) -- [Quick Download](https://www.dropbox.com/s/8jlcoda7ocjezlq/weapon_balrog9-v1.0.zip?dl=0)

    * ENTITIES
    * `weapon_balrog9`

    * REGISTRATION FUNCTIONS
    * `CSO_RegisterWeapon_BALROG9();`

<BR>

* Dragon Claw
    * [Video](https://youtu.be/yhOwNG_B25M?si=WRR-ZUeEjBnkgLVl)

    * ENTITIES
    * `weapon_dragonclaw`

    * REGISTRATION FUNCTIONS
    * `CSO_RegisterWeapon_DRAGONCLAW();`

<BR>

# PISTOLS
* Calico M950
    * [Video](https://youtu.be/unMsubpPTUQ)

    * ENTITIES
    * `weapon_m950`
 
    * AMMO NAME
    * `9mm`

    * REGISTRATION FUNCTIONS
    * `CSO_RegisterWeapon_M950();`


* Python Desperado
    * [Video](https://youtu.be/Q2NYPb8EBTg?si=qQ1JgZLca-3g85fj)

    * ENTITIES
    * `weapon_desperado` - Weapon
 
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

# MACHINE GUNS
* Aeolis
    * [Video](https://youtu.be/Komeh8zz1Jc)

    * ENTITIES
    * `weapon_aeolis` - Weapon
    * `csoproj_flame` - Projectile
 
    * AMMO NAME
    * `556`

    * REGISTRATION FUNCTIONS
    * `CSO_RegisterWeapon_AEOLIS();`
    * `CSO_RegisterProjectiles();`
