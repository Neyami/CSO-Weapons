namespace cso_at4
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_at4";

const int CSOW_DEFAULT_GIVE						= 2;
const int CSOW_MAX_CLIP 								= 1;
const int CSOW_MAX_AMMO							= 10;
const float CSOW_DAMAGE								= 123; //Based on AT4-CS which deals 4% more damage
const float CSOW_TIME_DELAY1						= 1.5; //N/A as it is a single-fire weapon
const float CSOW_TIME_DELAY2						= 0.3;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 1.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD						= 3.7;
const float CSOW_ZOOM_FOV							= 40;
const float CSOW_ROCKET_SPEED					= 1024;
const float CSOW_ROCKET_RADIUS				= 200;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-8, -12);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(-1, 1);
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D(-4, -8);
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D(-0.5, 0.5);
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 34.333031, 12.009664, -5.616758 );

const string CSOW_ANIMEXT							= "rpg"; //at4

const string MODEL_VIEW								= "models/custom_weapons/cso/at4/v_at4.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/at4/p_at4.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/at4/w_at4.mdl";
const string MODEL_ROCKET							= "models/custom_weapons/cso/rpgrocket.mdl";

const string SPRITE_MUZZLE							= "sprites/ballsmoke.spr";
const string SPRITE_ROCKET_TRAIL1				= "sprites/xfireball3.spr";
const string SPRITE_ROCKET_TRAIL2				= "sprites/ballsmoke.spr";

const string SPRITE_EXPLOSION1					= "sprites/fexplo.spr";
const string SPRITE_EXPLOSION2					= "sprites/eexplo.spr";
const string SPRITE_SMOKE							= "sprites/steam1.spr";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/at4-1.wav",
	"custom_weapons/cso/at4_clipin1.wav",
	"custom_weapons/cso/at4_clipin2.wav",
	"custom_weapons/cso/at4_clipin3.wav",
	"custom_weapons/cso/at4_draw.wav"
};

class weapon_at4 : CBaseCSOWeapon
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iWeaponType = TYPE_PRIMARY;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_ROCKET );

		g_Game.PrecacheModel( SPRITE_MUZZLE );
		g_Game.PrecacheModel( SPRITE_ROCKET_TRAIL1 );
		g_Game.PrecacheModel( SPRITE_ROCKET_TRAIL2 );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
		g_Game.PrecacheModel( SPRITE_EXPLOSION2 );
		g_Game.PrecacheModel( SPRITE_SMOKE );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud53.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::AT4_SLOT - 1;
		info.iPosition		= cso::AT4_POSITION - 1;
		info.iWeight			= cso::AT4_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName(CSOW_NAME) );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (CSOW_TIME_DRAW-0.2);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.SendWeaponAnim( ANIM_SHOOT2 );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_MUZZLE.x + g_Engine.v_right * CSOW_OFFSETS_MUZZLE.y + g_Engine.v_up * CSOW_OFFSETS_MUZZLE.z;
		Vector vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x *= -1;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		CBaseEntity@ pRocket = g_EntityFuncs.Create( "at4rocket", vecOrigin, vecAngles, false, m_pPlayer.edict() );

		pRocket.pev.velocity = g_Engine.v_forward * CSOW_ROCKET_SPEED;
		pRocket.pev.dmg = flDamage;

		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		DoMuzzleflash2( SPRITE_MUZZLE, CSOW_OFFSETS_MUZZLE.x, CSOW_OFFSETS_MUZZLE.y, CSOW_OFFSETS_MUZZLE.z*2, 10, 20, TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.m_iFOV != 0 )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		else
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = CSOW_ZOOM_FOV;

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2));
	}
}

class at4rocket : ScriptBaseEntity
{
	void Spawn()
	{
		self.Precache();

		g_EntityFuncs.SetModel( self, MODEL_ROCKET );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype		= MOVETYPE_FLY;
		pev.solid			= SOLID_BBOX;

		SetTouch( TouchFunction(this.RocketTouch) );
		SetThink( ThinkFunction(this.RocketThink) );
		pev.nextthink = g_Engine.time + 0.2;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_ROCKET );
	}

	void RocketThink()
	{
		Vector vecOrigin = pev.origin - pev.velocity.Normalize() * 4;

		//Fire
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z - 10 );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_ROCKET_TRAIL1) );
			m1.WriteByte( 3 ); //scale
			m1.WriteByte( 60 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		//Smoke
		NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m2.WriteByte( TE_EXPLOSION );
			m2.WriteCoord( pev.origin.x );
			m2.WriteCoord( pev.origin.y );
			m2.WriteCoord( pev.origin.z - 10 );
			m2.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_ROCKET_TRAIL2) );
			m2.WriteByte( 3 ); //scale
			m2.WriteByte( 16 ); //framerate
			m2.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m2.End();

		pev.nextthink = g_Engine.time + 0.1;
	}

	void RocketTouch( CBaseEntity@ pOther )
	{
		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0, 1) );

		int sparkCount = Math.RandomLong(0, 3);
		for( int i = 0; i < sparkCount; i++ )
			g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0 )
			pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0);

		Vector vecOrigin = pev.origin;

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION1) );
			m1.WriteByte( 30 ); // scale * 10
			m1.WriteByte( 30 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NONE );
		m1.End();

		NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_EXPLOSION );
			m2.WriteCoord( vecOrigin.x + Math.RandomFloat(5, 15) );
			m2.WriteCoord( vecOrigin.y + Math.RandomFloat(5, 15) );
			m2.WriteCoord( vecOrigin.z + 32 );
			m2.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION2) );
			m2.WriteByte( 20 ); // scale * 10
			m2.WriteByte( 35 ); // framerate
			m2.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m2.End();

		NetworkMessage m3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m3.WriteByte( TE_SMOKE );
			m3.WriteCoord( vecOrigin.x );
			m3.WriteCoord( vecOrigin.y );
			m3.WriteCoord( vecOrigin.z );
			m3.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
			m3.WriteByte( 40 ); // scale * 10
			m3.WriteByte( 5 ); // framerate
		m3.End();

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, pev.dmg, CSOW_ROCKET_RADIUS, CLASS_NONE, DMG_BLAST );

		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_at4::at4rocket", "at4rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_at4::weapon_at4", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "rockets", "", "ammo_rpgclip" );
}

} //namespace cso_at4 END