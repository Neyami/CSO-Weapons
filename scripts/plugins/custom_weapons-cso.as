#include "../maps/hunger/weapons/baseweapon"

//Melee
#include "../custom_weapons/cso/weapon_balrog9"
#include "../custom_weapons/cso/weapon_dragonclaw"
#include "../custom_weapons/cso/weapon_janus9"

//Pistols
#include "../custom_weapons/cso/weapon_desperado"
#include "../custom_weapons/cso/weapon_m950"

//Shotguns
#include "../custom_weapons/cso/weapon_blockas"

//Machine Guns
#include "../custom_weapons/cso/weapon_aeolis"

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
	cso_desperado::Register();
	cso_m950::Register();
	cso_blockas::Register();
	cso_aeolis::Register();
}
