//Weapon slots and positions.
//Melee
const int DCLAW_SLOT					= 1;
const int DCLAW_POSITION				= 10;
const int BEAMSWORD_SLOT				= 1;
const int BEAMSWORD_POSITION			= 11;
const int BALROG9_SLOT					= 1;
const int BALROG9_POSITION				= 12;
//Pistols
const int M950_SLOT					= 2;
const int M950_POSITION				= 10;
//Shotguns
const int QBARREL_SLOT				= 3;
const int QBARREL_POSITION			= 10;
//SMGs
const int V3_SLOT					= 4;
const int V3_POSITION				= 10;
//Assault Rifles
const int ETHEREAL_SLOT				= 5;
const int ETHEREAL_POSITION			= 10;
//Sniper Rifles
const int SAVERY_SLOT					= 6;
const int SAVERY_POSITION				= 10;
//Machine Guns
const int AEOLIS_SLOT					= 7;
const int AEOLIS_POSITION				= 10;
//Special (Equipment)
const int PB_SLOT					= 7;
const int PB_POSITION				= 11;

enum SMOKETYPE
{
	SMOKE_GUN = 0,
	SMOKE_RIFLE
};

enum riflesmoke
{
	RIFLE_SMOKE = 0
};

enum sniperZoom
{
	MODE_NOZOOM,
	MODE_ZOOM1,
	MODE_ZOOM2
};
const array<string> pSmokeSprites =
{
	"sprites/custom_weapons/cso/smoke_thanatos9.spr"
};

void GetDefaultShellInfo( EHandle &in ePlayer, Vector &out ShellOrigin, Vector &out ShellVelocity, float forwardScale, float rightScale, float upScale )
{  
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	Math.MakeVectors( pPlayer.pev.v_angle + pPlayer.pev.punchangle );

	ShellOrigin = pPlayer.pev.origin + pPlayer.pev.view_ofs + g_Engine.v_up * upScale + g_Engine.v_forward * forwardScale + g_Engine.v_right * rightScale;

	ShellVelocity = pPlayer.pev.velocity 
					+ g_Engine.v_right * Math.RandomFloat(50, 70) 
					+ g_Engine.v_up * Math.RandomFloat(100, 150) 
					+ g_Engine.v_forward * 25;
}

void DoDecalGunshot( Vector vecSrc, Vector vecAiming, float flConeX, float flConeY, int iBulletType, EHandle &in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	TraceResult tr;
	
	float x, y;
	
	g_Utility.GetCircularGaussianSpread( x, y );
	
	Vector vecDir = vecAiming 
					+ x * flConeX * g_Engine.v_right 
					+ y * flConeY * g_Engine.v_up;

	Vector vecEnd	= vecSrc + vecDir * 8192;

	g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );
	
	if( tr.flFraction < 1.0 )
	{
		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null || pHit.IsBSPModel() == true )
			{
				g_WeaponFuncs.DecalGunshot( tr, iBulletType );
			}
		}
	}
}

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

void CreateShotgunPelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, const int iDamage, EHandle &in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	TraceResult tr;
	
	float x, y;
	
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
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
				}
				
				if ( pHit.pev.takedamage != DAMAGE_NO )
				{
					g_WeaponFuncs.ClearMultiDamage();
					
					pHit.TraceAttack( pPlayer.pev, iDamage, vecDir, tr, DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB );
			
					g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
					
				}	
			}
		}
	}
}