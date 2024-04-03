#include "../custom_weapons/cso/csobaseweapon"
#include "../custom_weapons/cso/csocommon"


//Melee
#include "../custom_weapons/cso/weapon_balrog9"
#include "../custom_weapons/cso/weapon_dragonclaw"
#include "../custom_weapons/cso/weapon_janus9"
#include "../custom_weapons/cso/weapon_thanatos9"
#include "../custom_weapons/cso/weapon_dualwaki"
#include "../custom_weapons/cso/weapon_beamsword"
#include "../custom_weapons/cso/weapon_ripper"
#include "../custom_weapons/cso/weapon_dualsword"

//Pistols
#include "../custom_weapons/cso/weapon_elites"
#include "../custom_weapons/cso/weapon_desperado"
#include "../custom_weapons/cso/weapon_m950"
#include "../custom_weapons/cso/weapon_skull2"
#include "../custom_weapons/cso/weapon_bloodhunter"
#include "../custom_weapons/cso/weapon_gunkata"

//Shotguns
#include "../custom_weapons/cso/weapon_blockas"
#include "../custom_weapons/cso/weapon_mk3a1"
#include "../custom_weapons/cso/weapon_volcano"
#include "../custom_weapons/cso/weapon_qbarrel"

//Submachine Guns
#include "../custom_weapons/cso/weapon_crow3"
#include "../custom_weapons/cso/weapon_p90"

//Assault Rifles
#include "../custom_weapons/cso/weapon_aug"
#include "../custom_weapons/cso/weapon_plasmagun"
#include "../custom_weapons/cso/weapon_csobow"
#include "../custom_weapons/cso/weapon_failnaught"
#include "../custom_weapons/cso/weapon_augex"
#include "../custom_weapons/cso/weapon_guitar"
#include "../custom_weapons/cso/weapon_ethereal"

//Sniper Rifles
#include "../custom_weapons/cso/weapon_awp"
#include "../custom_weapons/cso/weapon_svd"
#include "../custom_weapons/cso/weapon_svdex"
#include "../custom_weapons/cso/weapon_m95"
#include "../custom_weapons/cso/weapon_savery"
#include "../custom_weapons/cso/weapon_m95tiger"

//Machine Guns
#include "../custom_weapons/cso/weapon_aeolis"
#include "../custom_weapons/cso/weapon_m134hero"
#include "../custom_weapons/cso/weapon_m2"

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
	cso_dualwaki::Register();
	cso_beamsword::Register();
	cso_ripper::Register();
	cso_dualsword::Register();

	cso_elites::Register();
	cso_desperado::Register();
	cso_m950::Register();
	cso_skull2::Register();
	cso_bloodhunter::Register();
	cso_gunkata::Register();

	cso_blockas::Register();
	cso_mk3a1::Register();
	cso_volcano::Register();
	cso_qbarrel::Register();

	cso_p90::Register();
	cso_crow3::Register();

	cso_aug::Register();
	cso_plasmagun::Register();
	cso_bow::Register();
	cso_failnaught::Register();
	cso_augex::Register();
	cso_guitar::Register();
	cso_ethereal::Register();

	cso_awp::Register();
	cso_svd::Register();
	cso_svdex::Register();
	cso_m95::Register();
	cso_savery::Register();
	cso_m95tiger::Register();

	cso_aeolis::Register();
	cso_m134hero::Register();
	cso_m2::Register();
}
