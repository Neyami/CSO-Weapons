namespace cso_volcano
{

const Vector CSOW_VECTOR_SPREAD( 0.03f, 0.03f, 0.0f );
const Vector CSOW_SHELL_ORIGIN( 22.0f, 11.0f, -9.0f );
const Vector2D CSOW_VEC2D_RECOIL( 3.0f, 5.0f );

const int CSOW_DEFAULT_GIVE			= 40;
const int CSOW_MAX_CLIP 			= 40;
const int CSOW_MAX_AMMO 			= 40; //doesn't actually do anything since it uses the maxammo set by the buymenu plugin ¯\_(ツ)_/¯
const int CSOW_PELLETCOUNT			= 6;
const float CSOW_DAMAGE				= 4.5f; //total 27

const float CSOW_DELAY				= 0.25f;
const float CSOW_TIME_RELOAD		= 4.5f;
const float CSOW_TIME_RLD_TO_IDLE	= 5.0f;
const float CSOW_TIME_IDLE			= 9.4375f;
const float CSOW_TIME_DRAW			= 1.0f;
const float CSOW_TIME_DRAW_TO_FIRE	= 0.8f;
const float CSOW_TIME_FIRE_TO_IDLE	= 0.6f;

const string MODEL_VIEW				= "models/custom_weapons/cso/v_firevulcan.mdl";
const string MODEL_PLAYER			= "models/custom_weapons/cso/p_firevulcan.mdl";
const string MODEL_WORLD			= "models/custom_weapons/cso/w_firevulcan.mdl";
const string MODEL_SHELL			= "models/custom_weapons/cso/shotgunshell.mdl";

const string CSOW_ANIMEXT			= "saw"; //shotgun

enum csow_e
{
	ANIM_IDLE = 0, //9.4375
	ANIM_DRAW, //1.0
	ANIM_SHOOT1, //0.6
	ANIM_SHOOT2, //0.6
	ANIM_RELOAD //5.0
}

enum csowsounds_e
{
	SND_SHOOT = 1
}

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/gatlingm-1.wav",
	"custom_weapons/cso/gatling_boltpull.wav",
	"custom_weapons/cso/gatling_clipin1.wav",
	"custom_weapons/cso/gatling_clipin2.wav",
	"custom_weapons/cso/gatling_clipout1.wav",
	"custom_weapons/cso/gatling_clipout2.wav",
	"custom_weapons/cso/usas_draw.wav"
};

class weapon_volcano : CBaseCSOWeapon
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_Game.PrecacheModel( MODEL_SHELL );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "events/muzzle_fvulcan1.txt" );
		g_Game.PrecacheGeneric( "events/muzzle_fvulcan2.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_volcano.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud121.spr" );
		g_Game.PrecacheGeneric( "sprites/cs16/mzcs1.spr" );
		g_Game.PrecacheGeneric( "sprites/cs16/mzcs2.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 	= CSOW_MAX_CLIP;
		info.iSlot 		= cso::VOLCANO_SLOT - 1;
		info.iPosition 	= cso::VOLCANO_POSITION - 1;
		info.iWeight 	= cso::VOLCANO_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage volcano( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			volcano.WriteLong( g_ItemRegistry.GetIdForName("weapon_volcano") );
		volcano.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DRAW_TO_FIRE;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;
			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		Vector vecShellVelocity, vecShellOrigin;
		CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, CSOW_SHELL_ORIGIN.x, CSOW_SHELL_ORIGIN.y, CSOW_SHELL_ORIGIN.z, true, false );
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity*1.2, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHOTSHELL );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1.0, 0.5, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( CSOW_PELLETCOUNT, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );
		cso::CreateShotgunPelletDecals( m_pPlayer, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET | DMG_NEVERGIB) );

		if( self.m_iClip <= 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flNextPrimaryAttack = g_Engine.time + CSOW_DELAY;

		if( self.m_iClip > 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 2.25;
		else
			self.m_flTimeWeaponIdle = 0.75;

		if( (m_pPlayer.pev.flags & FL_ONGROUND) != 0 )
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, (CSOW_VEC2D_RECOIL.x/2), (CSOW_VEC2D_RECOIL.y/2) );
		else
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, CSOW_VEC2D_RECOIL.x, CSOW_VEC2D_RECOIL.y );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE * Math.RandomFloat(1.0, 1.7));

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE * Math.RandomFloat(1.0, 1.7));
		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_volcano::weapon_volcano", "weapon_volcano" );
	g_ItemRegistry.RegisterWeapon( "weapon_volcano", "custom_weapons/cso", "buckshot", "", "ammo_buckshot" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_volcano END
