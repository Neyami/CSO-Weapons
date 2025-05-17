namespace cso_svdex
{

const bool USE_PENETRATION					= true;
const bool USE_GRENADE_CROSSHAIRS = true; //causes the view to be zoomed in while in grenade mode
const string CSOW_NAME						= "weapon_svdex";

const int CSOW_DEFAULT_GIVE				= 20;
const int CSOW_MAX_CLIP 						= 20;
const int CSOW_MAX_AMMO					= 180;
const int CSOW_MAX_AMMO2					= 10;
const int CSOW_TRACERFREQ					= 0;
const float CSOW_DAMAGE						= 70;
const float CSOW_GRENADE_VELOCITY	= 1800.0;
const float CSOW_GRENADE_DAMAGE		= 140.0;
const float CSOW_GRENADE_RADIUS		= 180.0;
const float CSOW_TIME_DELAY1				= 0.45; //gun
const float CSOW_TIME_DELAY2				= 1.5; //switch
const float CSOW_TIME_DELAY3				= 2.8; //grenade
const float CSOW_TIME_DRAW				= 1.0;
const float CSOW_TIME_IDLE					= 60.0;
const float CSOW_TIME_RELOAD			= 3.8;
const float CSOW_SPREAD_JUMPING		= 0.85;
const float CSOW_SPREAD_RUNNING		= 0.25;
const float CSOW_SPREAD_WALKING		= 0.1;
const float CSOW_SPREAD_STANDING	= 0.001;
const float CSOW_SPREAD_DUCKING		= 0.0;
const float CSOW_RECOIL						= 2.0;
const Vector CSOW_SHELL_ORIGIN		= Vector( 20.0, 10.0, -4.0 ); //forward, right, up
const Vector CSOW_MUZZLE_ORIGIN		= Vector( 16.0, 4.0, -4.0 ); //forward, right, up

const string CSOW_ANIMEXT					= "sniper"; //rifle

const string MODEL_VIEW						= "models/custom_weapons/cso/v_svdex.mdl";
const string MODEL_PLAYER					= "models/custom_weapons/cso/p_svdex.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/w_svdex.mdl";
const string MODEL_SHELL						= "models/custom_weapons/cso/rshell_big.mdl";
const string MODEL_GRENADE					= "models/custom_weapons/cso/shell_svdex.mdl";

const string SPRITE_BEAM						= "sprites/laserbeam.spr";
const string SPRITE_EXPLOSION1			= "sprites/fexplo.spr";
const string SPRITE_SMOKE					= "sprites/steam1.spr";
const string SPRITE_MUZZLE_GRENADE	= "sprites/custom_weapons/cso/muzzleflash12.spr";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_GREN_IDLE,
	ANIM_GREN_SHOOT,
	ANIM_GREN_SHOOT_EMPTY,
	ANIM_GREN_DRAW,
	ANIM_SWAP_TO_GREN,
	ANIM_SWAP_TO_GUN
};

enum csowsounds_e
{
	SND_SHOOT = 1,
	SND_SHOOT_GRENADE,
	SND_EXPLODE
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/svdex-1.wav",
	"custom_weapons/cso/svdex-launcher.wav",
	"custom_weapons/cso/svdex_exp.wav",
	"custom_weapons/cso/svdex_clipin.wav",
	"custom_weapons/cso/svdex_clipon.wav",
	"custom_weapons/cso/svdex_clipout.wav",
	"custom_weapons/cso/svdex_draw.wav",
	"custom_weapons/cso/svdex_foley1.wav",
	"custom_weapons/cso/svdex_foley2.wav",
	"custom_weapons/cso/svdex_foley3.wav",
	"custom_weapons/cso/svdex_foley4.wav"
};

enum csowmodes_e
{
	MODE_GUN = 0,
	MODE_GRENADE
};

class weapon_svdex : CBaseCSOWeapon
{
	private int m_iMode;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		m_iMode = MODE_GUN;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_GRENADE );
		g_Game.PrecacheModel( SPRITE_BEAM );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_MUZZLE_GRENADE );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_svdex.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud36.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud41.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/scope_vip_grenade.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxAmmo2	= CSOW_MAX_AMMO2;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::SVDEX_SLOT - 1;
		info.iPosition		= cso::SVDEX_POSITION - 1;
		info.iWeight			= cso::SVDEX_WEIGHT;
		info.iFlags			= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), m_iMode == MODE_GUN ? ANIM_DRAW : ANIM_GREN_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			float flTime = m_iMode == MODE_GUN ? (CSOW_TIME_DRAW - 0.4) : (CSOW_TIME_DRAW + 0.4);

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			if( USE_GRENADE_CROSSHAIRS and m_iMode == MODE_GRENADE )
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 49;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 or (m_iMode == MODE_GRENADE and m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0) )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( m_iMode == MODE_GUN )
		{
			HandleAmmoReduction( 1 );

			m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			self.SendWeaponAnim( ANIM_SHOOT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.4, 0, 94 + Math.RandomLong(0, 15) );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

			float flDamage = CSOW_DAMAGE;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			int iPenetration = USE_PENETRATION ? 2 : 1;
			FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_762MM, CSOW_TRACERFREQ, flDamage, 1.0, CSOF_ALWAYSDECAL );

			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false, true );

			m_pPlayer.pev.punchangle.x -= CSOW_RECOIL;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		}
		else if( m_iMode == MODE_GRENADE )
		{
			HandleAmmoReduction( 0, 0, 0, 1 );
			bool bHasAmmo = m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0;

			m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			int iAnim = bHasAmmo ? ANIM_GREN_SHOOT : ANIM_GREN_SHOOT_EMPTY;
			self.SendWeaponAnim( iAnim, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT_GRENADE], VOL_NORM, 0.4 );

			LaunchGrenade();
			
			float flTime = bHasAmmo ? CSOW_TIME_DELAY3 : (CSOW_TIME_DELAY3 - 1.6);
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
			self.m_flTimeWeaponIdle = g_Engine.time + flTime + 0.5;
		}
	}

	void LaunchGrenade()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0, -3.0);

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 4 + g_Engine.v_up * -2;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = 360.0 - vecAngles.x;

		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "svd_rocket", vecOrigin, vecAngles, false, m_pPlayer.edict() ); 
		svd_rocket@ pGrenade = cast<svd_rocket@>(CastToScriptClass(cbeGrenade));
		pGrenade.pev.velocity = g_Engine.v_forward * CSOW_GRENADE_VELOCITY;

		DoMuzzleflash( SPRITE_MUZZLE_GRENADE, CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );
	}

	void SecondaryAttack()
	{
		if( m_iMode == MODE_GUN )
		{
			m_iMode = MODE_GRENADE;
			self.SendWeaponAnim( ANIM_SWAP_TO_GREN, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			if( USE_GRENADE_CROSSHAIRS )
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 49; //Lowest possible fov to cause the crosshairs to change
		}
		else
		{
			m_iMode = MODE_GUN;
			self.SendWeaponAnim( ANIM_SWAP_TO_GUN, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			if( USE_GRENADE_CROSSHAIRS )
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY2 + 0.5;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD-0.5, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( self.m_iClip > 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
			self.SendWeaponAnim( m_iMode == MODE_GUN ? ANIM_IDLE : ANIM_GREN_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}
}

class svd_rocket : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_GRENADE );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_TOSS;
		pev.solid = SOLID_BBOX;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMFOLLOW );
			m1.WriteShort( self.entindex() );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAM) );
			m1.WriteByte( 20 ); // life
			m1.WriteByte( 4 );  // width
			m1.WriteByte( 200 ); // r
			m1.WriteByte( 200 ); // g
			m1.WriteByte( 200 ); // b
			m1.WriteByte( 200 ); // brightness
		m1.End();

		SetThink( ThinkFunction(this.GrenadeThink) );
		SetTouch( TouchFunction(this.GrenadeTouch) );

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_GRENADE );
		g_Game.PrecacheModel( SPRITE_BEAM );
	}

	void GrenadeThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity.Normalize() );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void GrenadeTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.classname == "svd_rocket" )
			return;

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Explode();
	}

	void Explode()
	{
		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0, 1) );

		int sparkCount = Math.RandomLong(0, 3);
		for( int i = 0; i < sparkCount; i++ )
			g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

		tr = g_Utility.GetGlobalTrace();

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0f);

		Vector vecOrigin = pev.origin;

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION1) );
			m1.WriteByte( 15 ); // scale * 10
			m1.WriteByte( 30 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NONE );
		m1.End();

		float flDamage = CSOW_GRENADE_DAMAGE;
		float flRadius = CSOW_GRENADE_RADIUS;

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_BLAST );

		pev.effects |= EF_NODRAW;
		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetTouch( null );

		SetThink( ThinkFunction(this.Smoke) );
		pev.nextthink = g_Engine.time + 0.5;
	}

	void Smoke()
	{
		NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			msg1.WriteByte( TE_SMOKE );
			msg1.WriteCoord( pev.origin.x );
			msg1.WriteCoord( pev.origin.y );
			msg1.WriteCoord( pev.origin.z );
			msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
			msg1.WriteByte( 40 ); // scale * 10
			msg1.WriteByte( 6 ); // framerate
		msg1.End();

		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_svdex::svd_rocket", "svd_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_svdex::weapon_svdex", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "m40a1", "ARgrenades", "ammo_762", "ammo_ARgrenades" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_svdex END