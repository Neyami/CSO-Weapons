#include "includes/csoenums"
#include "includes/csoentities"
#include "includes/csoammo"

namespace cso
{

const bool bUseDroppedItemEffect = true;

//Weapon slots, positions, and weights (Auto-switch priority).
//Melee
const int DCLAW_SLOT						= 1;
const int DCLAW_POSITION				= 10;
const int BEAMSWORD_SLOT				= 1;
const int BEAMSWORD_POSITION		= 11;
const int BALROG9_SLOT						= 1;
const int BALROG9_POSITION				= 12;
const int JANUS9_SLOT						= 1;
const int JANUS9_POSITION				= 13;
const int DWAKI_SLOT							= 1;
const int DWAKI_POSITION					= 14;
const int THANATOS9_SLOT					= 1;
const int THANATOS9_POSITION			= 15;
const int RIPPER_SLOT						= 1;
const int RIPPER_POSITION					= 16;
const int DUALSWORD_SLOT				= 1;
const int DUALSWORD_POSITION		= 17;

const int DCLAW_WEIGHT					= 10;
const int BEAMSWORD_WEIGHT			= 10;
const int BALROG9_WEIGHT				= 10;
const int JANUS9_WEIGHT					= 10;
const int DWAKI_WEIGHT					= 10;
const int THANATOS9_WEIGHT			= 10;
const int RIPPER_WEIGHT					= 10;
const int DUALSWORD_WEIGHT			= 10;

//Pistols
const int ELITES_SLOT							= 2;
const int ELITES_POSITION					= 10;
const int M950_SLOT							= 2;
const int M950_POSITION					= 11;
const int SKULL2_SLOT						= 2;
const int SKULL2_POSITION				= 12;
const int BLOODHUNTER_SLOT			= 2;
const int BLOODHUNTER_POSITION	= 13;
const int DESPERADO_SLOT				= 2;
const int DESPERADO_POSITION			= 14;
const int GUNKATA_SLOT						= 2;
const int GUNKATA_POSITION				= 15;
const int M1887CRAFT_SLOT				= 2;
const int M1887CRAFT_POSITION		= 16;

const int ELITES_WEIGHT					= 5;
const int M950_WEIGHT						= 10;
const int SKULL2_WEIGHT					= 10;
const int BLOODHUNTER_WEIGHT		= 10;
const int DESPERADO_WEIGHT			= 10;
const int GUNKATA_WEIGHT				= 10;
const int M1887CRAFT_WEIGHT			= 10;

//Shotguns
const int M3_SLOT								= 3;
const int M3_POSITION						= 10;
const int BLOCKAS_SLOT						= 3;
const int BLOCKAS_POSITION				= 11;
const int MK3A1_SLOT							= 3;
const int MK3A1_POSITION					= 12;
const int VOLCANO_SLOT					= 3;
const int VOLCANO_POSITION				= 13;
const int QBARREL_SLOT						= 3;
const int QBARREL_POSITION				= 14;
const int M1887_SLOT							= 3;
const int M1887_POSITION					= 15;
const int SKULL11_SLOT						= 3;
const int SKULL11_POSITION				= 16;

const int M3_WEIGHT							= 20;
const int BLOCKAS_WEIGHT				= 20;
const int MK3A1_WEIGHT					= 20;
const int VOLCANO_WEIGHT				= 20;
const int QBARREL_WEIGHT				= 20;
const int M1887_WEIGHT					= 20;
const int SKULL11_WEIGHT					= 20;

//SMGs
const int CROW3_SLOT						= 4;
const int CROW3_POSITION				= 10;
const int P90_SLOT								= 4;
const int P90_POSITION						= 11;
const int THOMPSON_SLOT					= 4;
const int THOMPSON_POSITION			= 12;

const int CROW3_WEIGHT					= 10;
const int P90_WEIGHT							= 26;
const int THOMPSON_WEIGHT				= 10;

//Assault Rifles
const int AUG_SLOT								= 5;
const int AUG_POSITION						= 10;
const int PLASMAGUN_SLOT				= 5;
const int PLASMAGUN_POSITION			= 11;
const int CSOBOW_SLOT						= 5;
const int CSOBOW_POSITION				= 12;
const int FAILNAUGHT_SLOT				= 5;
const int FAILNAUGHT_POSITION		= 13;
const int AUGEX_SLOT							= 5;
const int AUGEX_POSITION					= 14;
const int GUITAR_SLOT						= 5;
const int GUITAR_POSITION				= 15;
const int ETHEREAL_SLOT					= 5;
const int ETHEREAL_POSITION			= 16;

const int AUG_WEIGHT						= 25;
const int PLASMAGUN_WEIGHT			= 20;
const int CSOBOW_WEIGHT				= 10;
const int FAILNAUGHT_WEIGHT			= 10;
const int AUGEX_WEIGHT					= 30;
const int GUITAR_WEIGHT					= 10;
const int ETHEREAL_WEIGHT				= 10;

//Sniper Rifles
const int AWP_SLOT							= 6;
const int AWP_POSITION						= 10;
const int SVD_SLOT								= 6;
const int SVD_POSITION						= 11;
const int SVDEX_SLOT							= 6;
const int SVDEX_POSITION					= 12;
const int M95_SLOT								= 6;
const int M95_POSITION						= 13;
const int SAVERY_SLOT						= 6;
const int SAVERY_POSITION				= 14;
const int M95TIGER_SLOT					= 6;
const int M95TIGER_POSITION			= 15;

const int AWP_WEIGHT						= 30;
const int SVD_WEIGHT						= 30;
const int SVDEX_WEIGHT					= 30;
const int M95_WEIGHT						= 35;
const int SAVERY_WEIGHT					= 15;
const int M95TIGER_WEIGHT				= 40;

//Machine Guns
const int AEOLIS_SLOT						= 7;
const int AEOLIS_POSITION				= 10;
const int M134HERO_SLOT					= 7;
const int M134HERO_POSITION			= 11;
const int M2_SLOT								= 7;
const int M2_POSITION						= 12;

const int AEOLIS_WEIGHT					= 30;
const int M134HERO_WEIGHT				= 40;
const int M2_WEIGHT							= 25;

//Special/Miscellaneous (Equipment)
const int AT4_SLOT								= 8;
const int AT4_POSITION						= 10;
const int AT4EX_SLOT							= 8;
const int AT4EX_POSITION					= 11;

const int AT4_WEIGHT							= 30;
const int AT4EX_WEIGHT						= 30;



//FireBullets3
const string SPRITE_TRAIL_CSOBOW						= "sprites/laserbeam.spr";
const string SPRITE_TRAIL_FAILNAUGHT					= "sprites/custom_weapons/cso/ef_huntbow_trail.spr";
const string SPRITE_TRAIL_FAILNAUGHT_EXPLODE	= "sprites/custom_weapons/cso/ef_huntbow_explo.spr";

//Bullet-Proof Textures
const array<string> pBPTextures = 
{
	"c2a2_dr",	//Blast Door
	"c2a5_dr"	//Secure Access
};


const float CSO_AZ_MULTIPLIER	= 1.2; //Anti-Zombie

const array<string> g_arrsZombies =
{
	"npc_zombienormal",
	"npc_zombielight",
	"npc_zombieheavy",
	"npc_zombievenomsting"/*,
	"monster_gonome",
	"monster_zombie",
	"monster_zombie_barney",
	"monster_zombie_soldier"*/
};

const array<string> pSmokeSprites =
{
	"sprites/custom_weapons/cso/smoke_thanatos9.spr",
	"sprites/custom_weapons/cso/wall_puff1.spr",
	"sprites/custom_weapons/cso/wall_puff2.spr",
	"sprites/custom_weapons/cso/wall_puff3.spr",
	"sprites/custom_weapons/cso/wall_puff4.spr"
};

void DoGunSmoke( Vector vecSrc, int iSmokeType )
{
	string szGunSmoke;
	szGunSmoke = pSmokeSprites[iSmokeType];

	NetworkMessage gunsmoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
		gunsmoke.WriteByte( TE_EXPLOSION );
		gunsmoke.WriteCoord( vecSrc.x );
		gunsmoke.WriteCoord( vecSrc.y );
		gunsmoke.WriteCoord( vecSrc.z );
		gunsmoke.WriteShort( g_EngineFuncs.ModelIndex(szGunSmoke) );
		gunsmoke.WriteByte( 1 );//scale in 0.1s
		gunsmoke.WriteByte( 16 );//framerate
		gunsmoke.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );//flags
	gunsmoke.End();

/*
	NetworkMessage gunsmoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
		gunsmoke.WriteByte( TE_FIREFIELD );
		gunsmoke.WriteCoord( vecSrc.x );
		gunsmoke.WriteCoord( vecSrc.y );
		gunsmoke.WriteCoord( vecSrc.z );
		gunsmoke.WriteShort( 1 );//radius
		gunsmoke.WriteShort( g_EngineFuncs.ModelIndex(szGunSmoke) );
		gunsmoke.WriteByte( 1 );//count
		gunsmoke.WriteByte( TEFIRE_FLAG_ALLFLOAT|TEFIRE_FLAG_ADDITIVE );
		gunsmoke.WriteByte( 4 );//duration
	gunsmoke.End();
*/
/*
	NetworkMessage gunsmoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
			gunsmoke.WriteByte( TE_SPRITE );
			gunsmoke.WriteCoord( vecSrc.x );
			gunsmoke.WriteCoord( vecSrc.y );
			gunsmoke.WriteCoord( vecSrc.z );
			gunsmoke.WriteShort( g_EngineFuncs.ModelIndex(szGunSmoke) );
			gunsmoke.WriteByte( 1 );//scale
			gunsmoke.WriteByte( 128 );//brightness
	gunsmoke.End();
*/
}

void CreateShotgunPelletDecals( CBasePlayer@ pPlayer, const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, float flMaxDamage, const int iDamageFlags )
{
	TraceResult tr;

	float x, y, flDamage;
	float flTotalDamage = 0;

	for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
	{
		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecDir = vecAiming 
						+ x * vecSpread.x * g_Engine.v_right 
						+ y * vecSpread.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 2048;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );

					NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
						m1.WriteByte( TE_EXPLOSION );
						m1.WriteCoord( tr.vecEndPos.x );
						m1.WriteCoord( tr.vecEndPos.y );
						m1.WriteCoord( tr.vecEndPos.z - 10.0 );
						m1.WriteShort( g_EngineFuncs.ModelIndex(pSmokeSprites[Math.RandomLong(1, 4)]) );
						m1.WriteByte( 2 ); //scale
						m1.WriteByte( 50 ); //framerate
						m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
					m1.End();
				}

				if( pHit.pev.takedamage != DAMAGE_NO )
				{
					//flDamage = (1 - tr.flFraction) * flMaxDamage; //decreases the damage the further away the target is
					flDamage = flMaxDamage;

					if( (iDamageFlags & DMG_ANTIZOMBIE) != 0 )
					{
						if( g_arrsZombies.find(pHit.GetClassname()) >= 0 )
							flDamage *= CSO_AZ_MULTIPLIER;
					}

					flTotalDamage += flDamage;
					//g_Game.AlertMessage( at_notice, "Shot Number %1 - flDamage: %2 - Total Damage: %3\n", uiPellet, flDamage, flTotalDamage );
					g_WeaponFuncs.ClearMultiDamage();
					pHit.TraceAttack( pPlayer.pev, flDamage, vecDir, tr, iDamageFlags );
					g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
				}
			}
		}
	}
}

Vector AngleRecoil( CBasePlayer@ m_pPlayer, float &in x, float &in y, float &in z = 0 )
{
	Vector vecTemp = m_pPlayer.pev.v_angle;
	vecTemp.x += x;
	vecTemp.y += y;
	vecTemp.z += z;
	m_pPlayer.pev.angles = vecTemp;
	m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;

	return m_pPlayer.pev.angles;
}

CBaseEntity@ ShootCustomProjectile( string classname, string mdl, Vector origin, Vector velocity, Vector angles, EHandle &in eOwner, float time = 0 )
{
	CBaseEntity@ pOwner = eOwner.GetEntity();

	if( classname.Length() == 0 )
		return null;

	dictionary keys;
	Vector projAngles = angles * Vector( -1, 1, 1 );
	keys[ "origin" ] = origin.ToString();
	keys[ "angles" ] = projAngles.ToString();
	keys[ "velocity" ] = velocity.ToString();

	string model = mdl.Length() > 0 ? mdl : "models/error.mdl";
	keys[ "model" ] = model;

	if( mdl.Length() == 0 )
		keys[ "rendermode" ] = "1"; // don't render the model

	CBaseEntity@ shootEnt = g_EntityFuncs.CreateEntity( classname, keys, false );
	@shootEnt.pev.owner = pOwner.edict();

	if( time > 0 ) shootEnt.pev.dmgtime = time;

	g_EntityFuncs.DispatchSpawn( shootEnt.edict() );

	return shootEnt;
}

double MetersToUnits( float flMeters ) { return flMeters/0.0254; }
double InchesToUnits( float flInches ) { return flInches/1.00000054; }
double FeetToUnits( float flFeet ) { return flFeet/0.08333232; }

double UnitsToMeters( float flUnits ) { return flUnits*0.0254; }
double UnitsToInches( float flUnits ) { return flUnits*1.00000054; }
double UnitsToFeet( float flUnits ) { return flUnits*0.08333232; }

void get_position( edict_t@ pOwner, float flForward, float flRight, float flUp, Vector &out vecOut )
{
	Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

	vecOrigin = pOwner.vars.origin;
	vecUp = pOwner.vars.view_ofs; //GetGunPosition() ??
	vecOrigin = vecOrigin + vecUp;

	vecAngle = pOwner.vars.v_angle; //if normal entity: use pev.angles

	g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

	vecOut = vecOrigin + vecForward * flForward + vecRight * flRight + vecUp * flUp;
}

} //namespace cso END