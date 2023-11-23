Weapons from Counter-Strike Online ported to Sven Co-op in Angelscript.


There might be changes made to the game that cause the scripts to fail and there's nothing I can do about it at this time. 
But the fixes should be simple.

Some of the weapons aren't 100% finished but they're mostly tweaks such as muzzleflashes, animations, bulletspread, damage, and such.

It'll look really messy but should be relatively easy to use anyway.

Hopefully I can make it better in the future, but health reasons and being busy IRL currently prevents me from doing so.

The plugin `custom_weapons-cso.as` can be used if you're not using a buymenu plugin to register the weapons, the `give` command can be used, but I would recommend using AFBase for the `.player_give` command (among many other extremely useful things)

https://github.com/Zode/AFBase

If you don't use my plugin, then you'll have to put this in another plugin that you've got, such as a buymenu.

`#include "../maps/hunger/weapons/baseweapon"`

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

# PISTOLS
* Calico M950
    * [Video](https://youtu.be/unMsubpPTUQ)

    * ENTITIES
    * `weapon_m950` - Weapon
 
    * AMMO NAME
    * `9mm`


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


<BR>

# SNIPER RIFLES
* Savery

    * ENTITIES
    * `weapon_savery` - Weapon
 
    * AMMO NAME
    * `m40a1`
