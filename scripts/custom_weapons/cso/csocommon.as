#include "pbullet"
#include "csoenums"

namespace CSO
{

//Weapon slots, positions, and weights (Auto-switch priority).
//Melee
const int DCLAW_SLOT						= 1;
const int DCLAW_POSITION				= 10;
const int BEAMSWORD_SLOT				= 1;
const int BEAMSWORD_POSITION		= 11;
const int BALROG9_SLOT					= 1;
const int BALROG9_POSITION				= 12;
const int JANUS9_SLOT						= 1;
const int JANUS9_POSITION				= 13;
const int DWAKI_SLOT						= 1;
const int DWAKI_POSITION				= 14;
const int THANATOS9_SLOT				= 1;
const int THANATOS9_POSITION		= 15;

const int DCLAW_WEIGHT					= 10;
const int BEAMSWORD_WEIGHT			= 10;
const int BALROG9_WEIGHT				= 10;
const int JANUS9_WEIGHT					= 10;
const int DWAKI_WEIGHT					= 10;
const int THANATOS9_WEIGHT			= 10;

//Pistols
const int M950_SLOT						= 2;
const int M950_POSITION					= 10;
const int SKULL2_SLOT						= 2;
const int SKULL2_POSITION				= 12;
const int BLOODHUNTER_SLOT			= 2;
const int BLOODHUNTER_POSITION		= 13;
const int DESPERADO_SLOT				= 2;
const int DESPERADO_POSITION			= 14;

const int M950_WEIGHT					= 10;
const int SKULL2_WEIGHT					= 10;
const int BLOODHUNTER_WEIGHT		= 10;
const int DESPERADO_WEIGHT			= 10;

//Shotguns
const int BLOCKAS_SLOT					= 3;
const int BLOCKAS_POSITION				= 10;
const int MK3A1_SLOT						= 3;
const int MK3A1_POSITION				= 11;
const int VOLCANO_SLOT					= 3;
const int VOLCANO_POSITION			= 12;

const int BLOCKAS_WEIGHT				= 20;
const int MK3A1_WEIGHT					= 20;
const int VOLCANO_WEIGHT				= 20;

//SMGs
const int CROW3_SLOT						= 4;
const int CROW3_POSITION				= 10;

const int CROW3_WEIGHT					= 10;

//Assault Rifles
const int PLASMAGUN_SLOT				= 5;
const int PLASMAGUN_POSITION			= 10;
const int CSOBOW_SLOT					= 5;
const int CSOBOW_POSITION				= 11;
const int FAILNAUGHT_SLOT				= 5;
const int FAILNAUGHT_POSITION		= 12;

const int PLASMAGUN_WEIGHT			= 20;
const int CSOBOW_WEIGHT				= 10;
const int FAILNAUGHT_WEIGHT			= 10;

//Sniper Rifles
const int SAVERY_SLOT					= 6;
const int SAVERY_POSITION				= 10;

const int SAVERY_WEIGHT					= 15;

//Machine Guns
const int AEOLIS_SLOT						= 7;
const int AEOLIS_POSITION				= 10;
const int M134HERO_SLOT					= 7;
const int M134HERO_POSITION			= 11;

const int AEOLIS_WEIGHT					= 30;
const int M134HERO_WEIGHT				= 40;

//Special/Miscellaneous (Equipment)


const float CSO_AZ_MULTIPLIER	= 1.2f; //Anti-Zombie

const string CSO_ITEMDISPLAY_MODEL	= "models/custom_weapons/cso/ef_gundrop.mdl";
const bool bUseDroppedItemEffect = true;

enum SMOKETYPE
{
	SMOKE_GUN = 0,
	SMOKE_RIFLE
}

enum riflesmoke
{
	RIFLE_SMOKE = 0
}

enum sniperZoom
{
	MODE_NOZOOM,
	MODE_ZOOM1,
	MODE_ZOOM2
}

enum cso_dmg
{
	DMG_ANTIZOMBIE = 268435456
}

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

	switch( iSmokeType )
	{
		case SMOKE_RIFLE: szGunSmoke = pSmokeSprites[RIFLE_SMOKE];
	}

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
						CSO::fake_smoke( tr, spriteIndex );
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
                        CSO::fake_smoke( tr, spriteIndex );
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

class cso_aoetrigger : ScriptBaseEntity
{
	void Spawn()
	{
		pev.solid = SOLID_TRIGGER;
		pev.movetype = MOVETYPE_NONE;
		g_EntityFuncs.SetOrigin( self, self.GetOrigin() );
		SetThink( null );
		//pev.nextthink = g_Engine.time + 0.1f;
	}
/*
	void Think()
	{
		DrawDebugBox( pev.absmin, pev.absmax, 25, Math.RandomLong( 0, 255 ), Math.RandomLong( 0, 255 ), Math.RandomLong( 0, 255 ) );
		SetThink( null );
	}

	void DrawDebugBox( Vector &in mins, Vector &in maxs, uint time, int r, int g, int b )
	{
		NetworkMessage box( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			box.WriteByte( TE_BOX );
			box.WriteCoord( mins.x );
			box.WriteCoord( mins.y );
			box.WriteCoord( mins.z );
			box.WriteCoord( maxs.x );
			box.WriteCoord( maxs.y );
			box.WriteCoord( maxs.z );
			box.WriteShort( time );
			box.WriteByte( r );
			box.WriteByte( g );
			box.WriteByte( b );
		box.End();
	}*/
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

class ef_gundrop : ScriptBaseAnimating
{
	EHandle m_hOwner;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, CSO_ITEMDISPLAY_MODEL );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		pev.solid		= SOLID_NOT;
		pev.framerate	= 1.0;

		self.pev.frame = 0;
		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.IdleThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( CSO_ITEMDISPLAY_MODEL );
	}

	void IdleThink()
	{
		if( m_hOwner.IsValid() )
		{
			self.StudioFrameAdvance();

			if( m_hOwner.GetEntity().pev.owner !is null )
				g_EntityFuncs.Remove( self );
		}
		else g_EntityFuncs.Remove( self );

		pev.nextthink = g_Engine.time + 0.1;
	}
}

void RegisterGunDrop()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CSO::ef_gundrop", "ef_gundrop" );
}

class ammo_762mg : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		g_EntityFuncs.SetModel( self, "models/custom_weapons/cs16/w_762natobox_big.mdl" );

		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/custom_weapons/cs16/w_762natobox_big.mdl" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( 100, "762mg", 600 ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register762MG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CSO::ammo_762mg", "ammo_762mg" );
}

} //namespace CSO END
