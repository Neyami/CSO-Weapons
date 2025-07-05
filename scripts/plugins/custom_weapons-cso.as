#include "../custom_weapons/cso/csobaseweapon"
#include "../custom_weapons/cso/csocommon"

//Melee (8)
#include "../custom_weapons/cso/weapon_balrog9"
#include "../custom_weapons/cso/weapon_dragonclaw"
#include "../custom_weapons/cso/weapon_janus9"
#include "../custom_weapons/cso/weapon_thanatos9"
#include "../custom_weapons/cso/weapon_dualwaki"
#include "../custom_weapons/cso/weapon_beamsword"
#include "../custom_weapons/cso/weapon_ripper"
#include "../custom_weapons/cso/weapon_dualsword"

//Pistols (7)
#include "../custom_weapons/cso/weapon_elites"
#include "../custom_weapons/cso/weapon_desperado"
#include "../custom_weapons/cso/weapon_m950"
#include "../custom_weapons/cso/weapon_skull2"
#include "../custom_weapons/cso/weapon_bloodhunter"
#include "../custom_weapons/cso/weapon_gunkata"
#include "../custom_weapons/cso/weapon_m1887craft"

//Shotguns (8)
#include "../custom_weapons/cso/weapon_m3"
#include "../custom_weapons/cso/weapon_usas12"
#include "../custom_weapons/cso/weapon_m1887"
#include "../custom_weapons/cso/weapon_qbarrel"
#include "../custom_weapons/cso/weapon_skull11"
#include "../custom_weapons/cso/weapon_volcano"
#include "../custom_weapons/cso/weapon_mk3a1"
#include "../custom_weapons/cso/weapon_blockas"

//Submachine Guns (3)
#include "../custom_weapons/cso/weapon_p90"
#include "../custom_weapons/cso/weapon_thompson"
#include "../custom_weapons/cso/weapon_crow3"

//Assault Rifles (8)
#include "../custom_weapons/cso/weapon_aug"
#include "../custom_weapons/cso/weapon_guitar"
#include "../custom_weapons/cso/weapon_ethereal"
#include "../custom_weapons/cso/weapon_csocrossbow"
#include "../custom_weapons/cso/weapon_plasmagun"
#include "../custom_weapons/cso/weapon_augex"
#include "../custom_weapons/cso/weapon_csobow"
#include "../custom_weapons/cso/weapon_failnaught"

//Sniper Rifles (7)
#include "../custom_weapons/cso/weapon_awp"
#include "../custom_weapons/cso/weapon_m400"
#include "../custom_weapons/cso/weapon_svd"
#include "../custom_weapons/cso/weapon_svdex"
#include "../custom_weapons/cso/weapon_m95"
#include "../custom_weapons/cso/weapon_savery"
#include "../custom_weapons/cso/weapon_m95tiger"

//Machine Guns (3)
#include "../custom_weapons/cso/weapon_aeolis"
#include "../custom_weapons/cso/weapon_m134hero"
#include "../custom_weapons/cso/weapon_m2"

//Explosives (2)
#include "../custom_weapons/cso/weapon_at4"
#include "../custom_weapons/cso/weapon_at4ex"

//Other (1)
#include "../custom_weapons/cso/weapon_salamander"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Nero" );
	g_Module.ScriptInfo.SetContactInfo( "https://www.reddit.com/r/svencoop/\n" );
}

void MapInit()
{
	cso::ReadCSOPlayerModels();

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
	cso_m1887craft::Register();

	cso_m3::Register();
	cso_usas12::Register();
	cso_m1887::Register();
	cso_qbarrel::Register();
	cso_skull11::Register();
	cso_volcano::Register();
	cso_mk3a1::Register();
	cso_blockas::Register();

	cso_p90::Register();
	cso_thompson::Register();
	cso_crow3::Register();

	cso_aug::Register();
	cso_guitar::Register();
	cso_ethereal::Register();
	cso_crossbow::Register();
	cso_plasmagun::Register();
	cso_augex::Register();
	cso_bow::Register();
	cso_failnaught::Register();

	cso_awp::Register();
	cso_m400::Register();
	cso_svd::Register();
	cso_svdex::Register();
	cso_m95::Register();
	cso_savery::Register();
	cso_m95tiger::Register();

	cso_aeolis::Register();
	cso_m134hero::Register();
	cso_m2::Register();

	cso_at4::Register();
	cso_at4ex::Register();

	cso_salamander::Register();
}