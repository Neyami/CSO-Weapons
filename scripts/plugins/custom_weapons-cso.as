#include "../maps/hunger/weapons/baseweapon"

#include "../custom_weapons/cso/weapon_blockas"
#include "../custom_weapons/cso/weapon_desperado"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Nero" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/0wtJ6aAd7XOGI6vI" );
}

void MapInit()
{
	cso_blockas::Register();
	cso_desperado::Register();
}
