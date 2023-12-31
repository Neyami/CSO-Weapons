//#include "../maps/hunger/weapons/baseweapon"
#include "../custom_weapons/baseweapon"
#include "../custom_weapons/cso/csocommon"


//Melee
#include "../custom_weapons/cso/weapon_balrog9"
#include "../custom_weapons/cso/weapon_dragonclaw"
#include "../custom_weapons/cso/weapon_janus9"
#include "../custom_weapons/cso/weapon_thanatos9"

//Pistols
#include "../custom_weapons/cso/weapon_desperado"
#include "../custom_weapons/cso/weapon_m950"
#include "../custom_weapons/cso/weapon_skull2"
#include "../custom_weapons/cso/weapon_bloodhunter"

//Shotguns
#include "../custom_weapons/cso/weapon_blockas"
#include "../custom_weapons/cso/weapon_balrog11"
//#include "../custom_weapons/cso/weapon_balrog11-wip"
#include "../custom_weapons/cso/weapon_volcano"
#include "../custom_weapons/cso/weapon_mk3a1"

//Assault Rifles
#include "../custom_weapons/cso/weapon_plasmagun"

//Machine Guns
#include "../custom_weapons/cso/weapon_aeolis"

//Sniper Rifles
#include "../custom_weapons/cso/weapon_savery"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Nero" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/0wtJ6aAd7XOGI6vI" );
}

void MapInit()
{
	cso_balrog9::Register();
	cso_dragonclaw::Register();
	cso_janus9::Register();
	cso_thanatos9::Register();
	cso_desperado::Register();
	cso_m950::Register();
	cso_skull2::Register();
	cso_bloodhunter::Register();
	cso_blockas::Register();
	cso_balrog11::Register();
	cso_volcano::Register();
	cso_mk3a1::Register();
	cso_plasmagun::Register();
	cso_aeolis::Register();
	cso_savery::Register();
}
