namespace cso_mk3a1
{

const Vector CSOW_VECTOR_SPREAD( 0.0725, 0.0725, 0.0 );
const Vector2D CSOW_VEC2D_RECOIL( 6.0, 10.0 );

const int CSOW_DEFAULT_GIVE			= 10;
const int CSOW_MAX_CLIP 			= 10;
const int CSOW_MAX_AMMO 			= 40; //doesn't actually do anything since it uses the maxammo set by the buymenu plugin ¯\_(ツ)_/¯
const int CSOW_PELLETCOUNT			= 8;
const float CSOW_DAMAGE				= 7.5; //total 60

const float CSOW_DELAY1				= 0.35;
const float CSOW_TIME_RELOAD		= 2.5;
const float CSOW_TIME_IDLE			= 2.0;
const float CSOW_TIME_DRAW			= 1.3;
const float CSOW_TIME_FIRE_TO_IDLE	= 0.5;

const string MODEL_VIEW				= "models/custom_weapons/cso/v_mk3a1.mdl";
const string MODEL_PLAYER			= "models/custom_weapons/cso/p_mk3a1.mdl";
const string MODEL_WORLD			= "models/custom_weapons/cso/w_mk3a1.mdl";

const string CSOW_ANIMEXT			= "saw"; //shotgun

enum csow_e
{
	ANIM_IDLE = 0, //2.0
	ANIM_DRAW, //1.3
	ANIM_SHOOT1, //0.5
	ANIM_SHOOT2, //0.5
	ANIM_RELOAD //2.5
}

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/mk3a1-1.wav",
	"custom_weapons/cso/mk3a1_clipin1.wav",
	"custom_weapons/cso/mk3a1_clipin2.wav",
	"custom_weapons/cso/mk3a1_clipout1.wav",
	"custom_weapons/cso/mk3a1_clipout2.wav"
};

class weapon_mk3a1 : CBaseCSOWeapon
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_mk3a1.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud123.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 	= CSOW_MAX_CLIP;
		info.iSlot 		= cso::MK3A1_SLOT - 1;
		info.iPosition 	= cso::MK3A1_POSITION - 1;
		info.iWeight 	= cso::MK3A1_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage mk3a1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			mk3a1.WriteLong( g_ItemRegistry.GetIdForName("weapon_mk3a1") );
		mk3a1.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.15;

			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0;

			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1.0, 0.5, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( CSOW_PELLETCOUNT, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );
		cso::CreateShotgunPelletDecals( m_pPlayer, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB) );

		HandleAmmoReduction( 1 );

		self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_DELAY1;

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
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.m_flTimeWeaponIdle = g_Engine.time + 20;
		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_mk3a1::weapon_mk3a1", "weapon_mk3a1" );
	g_ItemRegistry.RegisterWeapon( "weapon_mk3a1", "custom_weapons/cso", "buckshot", "", "ammo_buckshot" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_mk3a1 END