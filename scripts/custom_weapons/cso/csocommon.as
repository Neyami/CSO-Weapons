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
const int M950_SLOT							= 2;
const int M950_POSITION					= 10;
const int SKULL2_SLOT						= 2;
const int SKULL2_POSITION				= 12;
const int BLOODHUNTER_SLOT			= 2;
const int BLOODHUNTER_POSITION	= 13;
const int DESPERADO_SLOT				= 2;
const int DESPERADO_POSITION			= 14;

const int M950_WEIGHT						= 10;
const int SKULL2_WEIGHT					= 10;
const int BLOODHUNTER_WEIGHT		= 10;
const int DESPERADO_WEIGHT			= 10;

//Shotguns
const int BLOCKAS_SLOT						= 3;
const int BLOCKAS_POSITION				= 10;
const int MK3A1_SLOT							= 3;
const int MK3A1_POSITION					= 11;
const int VOLCANO_SLOT					= 3;
const int VOLCANO_POSITION				= 12;

const int BLOCKAS_WEIGHT				= 20;
const int MK3A1_WEIGHT					= 20;
const int VOLCANO_WEIGHT				= 20;

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

const int AUG_WEIGHT						= 25;
const int PLASMAGUN_WEIGHT			= 20;
const int CSOBOW_WEIGHT				= 10;
const int FAILNAUGHT_WEIGHT			= 10;
const int AUGEX_WEIGHT					= 30;

//Sniper Rifles
const int AWP_SLOT							= 6;
const int AWP_POSITION						= 10;
const int M95_SLOT								= 6;
const int M95_POSITION						= 11;
const int SAVERY_SLOT						= 6;
const int SAVERY_POSITION				= 12;
const int M95TIGER_SLOT					= 6;
const int M95TIGER_POSITION			= 13;

const int AWP_WEIGHT						= 30;
const int M95_WEIGHT						= 35;
const int SAVERY_WEIGHT					= 15;
const int M95TIGER_WEIGHT				= 40;

//Machine Guns
const int AEOLIS_SLOT						= 7;
const int AEOLIS_POSITION				= 10;
const int M134HERO_SLOT					= 7;
const int M134HERO_POSITION			= 11;

const int AEOLIS_WEIGHT					= 30;
const int M134HERO_WEIGHT				= 40;

//Special/Miscellaneous (Equipment)



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


const float CSO_AZ_MULTIPLIER	= 1.2f; //Anti-Zombie

const array<string> g_arrsZombies =
{
	"monster_gonome",
	"monster_zombie",
	"monster_zombie_barney",
	"monster_zombie_soldier"
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

void CreateShotgunPelletDecals( CBasePlayer@ pPlayer, const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, float flMaxDamage, const int iDamageFlags, int spriteIndex = -1 )
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

		if( tr.flFraction < 1.0f )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );

					if( spriteIndex != -1 )
						cso::fake_smoke( tr, spriteIndex );
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

/*
void CreateShotgunPelletDecals( CBasePlayer@ pPlayer, const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, const int iDamage, const int iDamageFlags, int spriteIndex = -1 )
{
    TraceResult tr;

    float x, y;

    for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
    {
        g_Utility.GetCircularGaussianSpread( x, y );

        Vector vecDir = vecAiming 
                        + x * vecSpread.x * g_Engine.v_right 
                        + y * vecSpread.y * g_Engine.v_up;

        Vector vecEnd    = vecSrc + vecDir * 2048;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );

        if( tr.flFraction < 1.0f )
        {
            if( tr.pHit !is null )
            {
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

                if( pHit.IsBSPModel() == true )
                {
                    g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );

                    if( spriteIndex != -1 )
                        cso::fake_smoke( tr, spriteIndex );
                }

                if ( pHit.pev.takedamage != DAMAGE_NO )
                {
                    g_WeaponFuncs.ClearMultiDamage();
                    pHit.TraceAttack( pPlayer.pev, iDamage, vecDir, tr, iDamageFlags );
                    g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
                }
            }
        }
    }
}
*/

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

void fake_smoke( TraceResult tr, int spriteIndex )
{
	Vector origin;

	if( tr.flFraction != 1.0f )
		origin = tr.vecEndPos + (tr.vecPlaneNormal * 0.6f);

	/*//correct origin but slow framerate
	NetworkMessage msg( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, origin );
			msg.WriteByte( TE_SPRITE );
			msg.WriteCoord( origin.x );
			msg.WriteCoord( origin.y );
			msg.WriteCoord( origin.z );
			msg.WriteShort( spriteIndex );
			msg.WriteByte( 2 );//scale
			msg.WriteByte( 128 );//brightness
	msg.End();*/

	//incorrect origin but proper framerate
	NetworkMessage msg( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, origin );
		msg.WriteByte( TE_EXPLOSION );
		msg.WriteCoord( origin.x );
		msg.WriteCoord( origin.y );
		msg.WriteCoord( origin.z );
		msg.WriteShort( spriteIndex );
		msg.WriteByte( 2 ); // scale * 10
		msg.WriteByte( 50 ); // framerate
		msg.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
	msg.End();
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

//From cstrike combat.cpp Vector CBaseEntity::FireBullets3(Vector vecSrc, Vector vecDirShooting, float flSpread, float flDistance, int iPenetration, int iBulletType, int iDamage, float flRangeModifier, entvars_t *pevAttacker, bool bPistol, int shared_rand)
//FireBullets3( vecSrc, vecAiming, 0, 4096, 2, BULLET_PLAYER_50AE, 54, 0.81f, m_pPlayer.edict(), true, m_pPlayer.random_seed );
//TODO make bullet decals on the otherside of a penetrated wall
//TODO make bullet decals and smoke when hitting a wall that is further than flCurrentDistance ??
int FireBullets3( Vector vecSrc, Vector vecDirShooting, float flSpread, float flDistance, int iPenetration, int iBulletType, float flDamage, float flRangeModifier, EHandle &in ePlayer, int shared_rand, int iFlags = 0, Vector vecMuzzleOrigin = g_vecZero )
{
	CBasePlayer@ pPlayer = null;

	if( ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	const int HITGROUP_SHIELD = HITGROUP_RIGHTLEG + 1;
	float flPenetrationPower;
	float flPenetrationDistance;
	float flCurrentDamage = flDamage;
	float flCurrentDistance;
	TraceResult tr, tr2;
	Vector vecRight = g_Engine.v_right;
	Vector vecUp = g_Engine.v_up;
	CBaseEntity@ pEntity;
	bool bHitMetal = false;
	//int iSparksAmount; //UNUSED??
	int iTrail = TRAIL_NONE;
	Vector vecTrailOrigin = vecSrc;
	if( vecMuzzleOrigin != g_vecZero )
		vecTrailOrigin = vecTrailOrigin + g_Engine.v_forward * vecMuzzleOrigin.x + g_Engine.v_right * vecMuzzleOrigin.y + g_Engine.v_up * vecMuzzleOrigin.z;

	int iBulletDecal = BULLET_NONE;
	int iEnemiesHit = 0;

	switch( iBulletType )
	{
		case BULLET_PLAYER_9MM:
		{
			flPenetrationPower = 21;
			flPenetrationDistance = 800;
			//iSparksAmount = 15;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			iBulletDecal = BULLET_PLAYER_9MM;
			break;
		}

		case BULLET_PLAYER_45ACP:
		{
			flPenetrationPower = 15;
			flPenetrationDistance = 500;
			//iSparksAmount = 20;
			flCurrentDamage += (-2 + Math.RandomLong(0, 4));
			break;
		}

		case BULLET_PLAYER_50AE:
		{
			flPenetrationPower = 30;
			flPenetrationDistance = 1000;
			//iSparksAmount = 20;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			iBulletDecal = BULLET_PLAYER_EAGLE;
			break;
		}

		case BULLET_PLAYER_762MM:
		{
			flPenetrationPower = 39;
			flPenetrationDistance = 5000;
			//iSparksAmount = 30;
			flCurrentDamage += (-2 + Math.RandomLong(0, 4));
			iBulletDecal = BULLET_PLAYER_SNIPER;
			break;
		}

		case BULLET_PLAYER_556MM:
		{
			flPenetrationPower = 35;
			flPenetrationDistance = 4000;
			//iSparksAmount = 30;
			flCurrentDamage += (-3 + Math.RandomLong(0, 6));
			iBulletDecal = BULLET_PLAYER_SAW;
			break;
		}

		case BULLET_PLAYER_338MAG:
		{
			flPenetrationPower = 45;
			flPenetrationDistance = 8000;
			//iSparksAmount = 30;
			flCurrentDamage += (-4 + Math.RandomLong(0, 8));
			iBulletDecal = BULLET_PLAYER_SNIPER;
			break;
		}

		case BULLET_PLAYER_50BMG:
		{
			flPenetrationPower = 112;
			flPenetrationDistance = 8000;
			//iSparksAmount = 35;
			flCurrentDamage += (-2 + Math.RandomLong(4, 12));
			iBulletDecal = BULLET_PLAYER_SNIPER;
			break;
		}

		case BULLET_PLAYER_57MM:
		{
			flPenetrationPower = 30;
			flPenetrationDistance = 2000;
			//iSparksAmount = 20;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			iBulletDecal = BULLET_PLAYER_EAGLE;
			break;
		}

		case BULLET_PLAYER_357SIG:
		{
			flPenetrationPower = 25;
			flPenetrationDistance = 800;
			//iSparksAmount = 20;
			flCurrentDamage += (-4 + Math.RandomLong(0, 10));
			iBulletDecal = BULLET_PLAYER_357;
			break;
		}

		case BULLET_PLAYER_44MAG:
		{
			flPenetrationPower = 25;
			flPenetrationDistance = 800;
			//iSparksAmount = 20;
			//flCurrentDamage += (-4 + Math.RandomLong(0, 8));
			iBulletDecal = BULLET_PLAYER_EAGLE;
			break;
		}

		case BULLET_PLAYER_CSOBOW:
		{
			flPenetrationPower = 30;
			flPenetrationDistance = 1500;
			//iSparksAmount = 20;
			flCurrentDamage += (-2 + Math.RandomLong(0, 4));
			iTrail = TRAIL_CSOBOW;
			iBulletDecal = BULLET_PLAYER_MP5;
			break;
		}

		case BULLET_PLAYER_FAILNAUGHT:
		{
			flPenetrationPower = 35;
			flPenetrationDistance = 2000;
			//iSparksAmount = 20;
			flCurrentDamage += (-2 + Math.RandomLong(0, 4));
			iTrail = TRAIL_FAILNAUGHT;
			iBulletDecal = BULLET_PLAYER_MP5;
			break;
		}

		case BULLET_PLAYER_M95TIGER:
		{
			flPenetrationPower = 112;
			flPenetrationDistance = 8000;
			//iSparksAmount = 35;
			flCurrentDamage += (-2 + Math.RandomLong(4, 12));
			iTrail = TRAIL_M95TIGER;
			iBulletDecal = BULLET_PLAYER_SNIPER;
			break;
		}

		default:
		{
			flPenetrationPower = 0;
			flPenetrationDistance = 0;
			break;
		}
	}

	float x, y;

	x = g_PlayerFuncs.SharedRandomFloat(shared_rand, -0.5, 0.5) + g_PlayerFuncs.SharedRandomFloat(shared_rand + 1, -0.5, 0.5);
	y = g_PlayerFuncs.SharedRandomFloat(shared_rand + 2, -0.5, 0.5) + g_PlayerFuncs.SharedRandomFloat(shared_rand + 3, -0.5, 0.5);

	Vector vecDir = vecDirShooting + x * flSpread * vecRight + y * flSpread * vecUp;
	Vector vecEnd = vecSrc + vecDir * flDistance;
	Vector vecOldSrc;
	Vector vecNewSrc;
	float flDamageModifier = 0.5;

	while( iPenetration > 0 ) //!= 0 seems unsafe
	{
		g_WeaponFuncs.ClearMultiDamage();
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );

		//char cTextureType = UTIL_TextureHit( tr, vecSrc, vecEnd );
		string sTexture = g_Utility.TraceTexture( null, vecSrc, vecEnd );
		char cTextureType = g_SoundSystem.FindMaterialType(sTexture);
		bool bSparks = false;

		if( pBPTextures.find( sTexture ) != -1 )
		{
			g_Utility.Ricochet( tr.vecEndPos, 1.0f );
			return 0;
			//return tr.vecEndPos;
		}

		if( cTextureType == CHAR_TEX_METAL )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.15f;
			flDamageModifier = 0.2f;
		}
		else if( cTextureType == CHAR_TEX_CONCRETE )
		{
			flPenetrationPower *= 0.25f;
			flDamageModifier = 0.25f;
		}
		else if( cTextureType == CHAR_TEX_GRATE )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.5f;
			flDamageModifier = 0.4f;
		}
		else if( cTextureType == CHAR_TEX_VENT )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.5f;
			flDamageModifier = 0.45f;
		}
		else if( cTextureType == CHAR_TEX_TILE )
		{
			flPenetrationPower *= 0.65f;
			flDamageModifier = 0.3f;
		}
		else if( cTextureType == CHAR_TEX_COMPUTER )
		{
			bSparks = true;
			bHitMetal = true;
			flPenetrationPower *= 0.4f;
			flDamageModifier = 0.45f;
		}
		else if( cTextureType == CHAR_TEX_WOOD )
		{
			flPenetrationPower *= 1;
			flDamageModifier = 0.6f;
		}
		else
			bSparks = false;

		if( tr.flFraction != 1.0f )
		{
			@pEntity = g_EntityFuncs.Instance(tr.pHit);
			iPenetration--;

			flCurrentDistance = tr.flFraction * flDistance;
			flCurrentDamage *= pow(flRangeModifier, flCurrentDistance / 500);

			if( flCurrentDistance > flPenetrationDistance )
				iPenetration = 0;

			if( tr.iHitgroup == HITGROUP_SHIELD )
			{
				iPenetration = 0;

				if( tr.flFraction != 1.0f )
				{
					if( Math.RandomLong(0, 1) == 1 )
						g_SoundSystem.EmitSound( pEntity.edict(), CHAN_VOICE, "custom_weapons/cso/ric_metal-1.wav", 1, ATTN_NORM );
					else
						g_SoundSystem.EmitSound( pEntity.edict(), CHAN_VOICE, "custom_weapons/cso/ric_metal-2.wav", 1, ATTN_NORM );

					g_Utility.Sparks( tr.vecEndPos );

					pEntity.pev.punchangle.x = flCurrentDamage * Math.RandomFloat(-0.15f, 0.15f);
					pEntity.pev.punchangle.z = flCurrentDamage * Math.RandomFloat(-0.15f, 0.15f);

					if( pEntity.pev.punchangle.x < 4 )
						pEntity.pev.punchangle.x = 4;

					if( pEntity.pev.punchangle.z < -5 )
						pEntity.pev.punchangle.z = -5;
					else if( pEntity.pev.punchangle.z > 5 )
						pEntity.pev.punchangle.z = 5;
				}

				break;
			}

			if( tr.pHit.vars.solid == SOLID_BSP /*and iPenetration != 0*/ ) //prevents the last hit from causing decals
			{
				if( (iFlags & CSOF_ALWAYSDECAL) != 0 )
					g_WeaponFuncs.DecalGunshot( tr, iBulletDecal/*, false, pev, bHitMetal*/ );
				else if( Math.RandomLong(0, 3) == 1 )
					g_WeaponFuncs.DecalGunshot( tr, iBulletDecal/*, true, pev, bHitMetal*/ );

				vecSrc = tr.vecEndPos + (vecDir * flPenetrationPower);
				flDistance = (flDistance - flCurrentDistance) * 0.5f;
				vecEnd = vecSrc + (vecDir * flDistance);

				pEntity.TraceAttack( pPlayer.pev, flCurrentDamage, vecDir, tr, (DMG_BULLET|DMG_NEVERGIB) );

				//Wall smoke puff
				if( iTrail == TRAIL_NONE )
				{
					NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
						m1.WriteByte( TE_EXPLOSION );
						m1.WriteCoord( tr.vecEndPos.x );
						m1.WriteCoord( tr.vecEndPos.y );
						m1.WriteCoord( tr.vecEndPos.z - 10.0 );
						m1.WriteShort( g_EngineFuncs.ModelIndex(cso::pSmokeSprites[Math.RandomLong(1, 4)]) );
						m1.WriteByte( 2 ); //scale
						m1.WriteByte( 50 ); //framerate
						m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
					m1.End();
				}
				else
					DoTrailExplosion( iTrail, tr.vecEndPos );

				//g_Game.AlertMessage( at_notice, "Hit SOLID_BSP: %1 with damage: %2\n", tr.pHit.vars.classname, flCurrentDamage );

				flCurrentDamage *= flDamageModifier;
			}
			else// if( tr.pHit.vars.takedamage != DAMAGE_NO/*tr.pHit.vars.FlagBitSet(FL_MONSTER)*/ ) //barnacles don't have FL_MONSTER :aRage:
			{
				if( (iFlags & CSOF_HITMARKER) != 0 )
				{
					Vector vecOrigin = pPlayer.pev.origin;
					get_position( pPlayer.edict(), 50.0, -0.05, 1.0, vecOrigin );

					CBaseEntity@ pHitConfirm = g_EntityFuncs.Create( "cso_buffhit", vecOrigin, g_vecZero, false, pPlayer.edict() );
				}

				vecSrc = tr.vecEndPos + (vecDir * 42);
				flDistance = (flDistance - flCurrentDistance) * 0.75f;
				vecEnd = vecSrc + (vecDir * flDistance);

				pEntity.TraceAttack( pPlayer.pev, flCurrentDamage, vecDir, tr, (DMG_BULLET|DMG_NEVERGIB) );

				if( iTrail > TRAIL_NONE )
					DoTrailExplosion( iTrail, tr.vecEndPos );

				iEnemiesHit++;
				//g_Game.AlertMessage( at_notice, "Hit entity: %1 with damage: %2\n", tr.pHit.vars.classname, flCurrentDamage );

				flCurrentDamage *= 0.75f;
			}
		}
		else
			iPenetration = 0;

		g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
	}

	if( iTrail > TRAIL_NONE )
	{
		if( iPenetration <= 0 )
			DoTrail( iTrail, vecTrailOrigin, tr.vecEndPos );
	}

	return iEnemiesHit;
	//return Vector(x * flSpread, y * flSpread, 0);
}

void DoTrail( int iTrail, Vector vecTrailstart, Vector vecTrailend )
{
	switch( iTrail )
	{
		case TRAIL_CSOBOW:
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_BEAMPOINTS );
				m1.WriteCoord( vecTrailstart.x );//start position
				m1.WriteCoord( vecTrailstart.y );
				m1.WriteCoord( vecTrailstart.z );
				m1.WriteCoord( vecTrailend.x );//end position
				m1.WriteCoord( vecTrailend.y );
				m1.WriteCoord( vecTrailend.z );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_TRAIL_CSOBOW) );//sprite index
				m1.WriteByte( 0 );//starting frame
				m1.WriteByte( 0 );//framerate in 0.1's
				m1.WriteByte( 20 );//life in 0.1's
				m1.WriteByte( 10 );//width in 0.1's
				m1.WriteByte( 0 );//noise amplitude in 0.1's
				m1.WriteByte( 255 );//red
				m1.WriteByte( 127 );//green
				m1.WriteByte( 127 );//blue
				m1.WriteByte( 127 );//brightness
				m1.WriteByte( 0 );//scroll speed
			m1.End();

			break;
		}

		case TRAIL_FAILNAUGHT:
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_BEAMPOINTS );
				m1.WriteCoord( vecTrailstart.x );//start position
				m1.WriteCoord( vecTrailstart.y );
				m1.WriteCoord( vecTrailstart.z );
				m1.WriteCoord( vecTrailend.x );//end position
				m1.WriteCoord( vecTrailend.y );
				m1.WriteCoord( vecTrailend.z );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_TRAIL_FAILNAUGHT) );//sprite index
				m1.WriteByte( 0 );//starting frame
				m1.WriteByte( 1);//framerate in 0.1's
				m1.WriteByte( 20 );//life in 0.1's
				m1.WriteByte( 84 );//width in 0.1's
				m1.WriteByte( 0 );//noise amplitude in 0.1's
				m1.WriteByte( 219 );//red
				m1.WriteByte( 180 );//green
				m1.WriteByte( 12 );//blue
				m1.WriteByte( 127 );//brightness
				m1.WriteByte( 1 );//scroll speed
			m1.End();

			break;
		}

		case TRAIL_M95TIGER:
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_BEAMPOINTS );
				m1.WriteCoord( vecTrailstart.x );//start position
				m1.WriteCoord( vecTrailstart.y );
				m1.WriteCoord( vecTrailstart.z );
				m1.WriteCoord( vecTrailend.x );//end position
				m1.WriteCoord( vecTrailend.y );
				m1.WriteCoord( vecTrailend.z );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_TRAIL_CSOBOW) );//sprite index
				m1.WriteByte( 0 );//starting frame
				m1.WriteByte( 0 );//framerate in 0.1's
				m1.WriteByte( 5 );//life in 0.1's
				m1.WriteByte( 4 );//width in 0.1's
				m1.WriteByte( 0 );//noise amplitude in 0.1's
				m1.WriteByte( 213 );//red
				m1.WriteByte( 213 );//green
				m1.WriteByte( 0 );//blue
				m1.WriteByte( 190 );//brightness
				m1.WriteByte( 0 );//scroll speed
			m1.End();

			break;
		}
	}
}

void DoTrailExplosion( int iTrail, Vector vecTrailend )
{
	switch( iTrail )
	{
		case TRAIL_FAILNAUGHT:
		{
			NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, vecTrailend );
				m1.WriteByte( TE_EXPLOSION );
				m1.WriteCoord( vecTrailend.x );
				m1.WriteCoord( vecTrailend.y );
				m1.WriteCoord( vecTrailend.z );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_TRAIL_FAILNAUGHT_EXPLODE) );
				m1.WriteByte( 5 ); //scale
				m1.WriteByte( 30 ); //framerate
				m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
			m1.End();

			break;
		}
	}
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