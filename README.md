Weapons from Counter-Strike Online ported to Sven Co-op in Angelscript.

They'll be placed in their own separate folders for now.

They might not be the latest versions that I've made, but they are working releases  

There might be changes made to the game that cause the scripts to fail and there's nothing I can do about it at this time. 
But the fixes should be simple.

Some weapons have extra scripts that contain functions that several weapons use, and they'll be identical in some cases.

It'll look really messy but should be relatively easy to use anyway.

Hopefully I can make it better in the future, but health reasons and being busy IRL currently prevents me from doing so.
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
