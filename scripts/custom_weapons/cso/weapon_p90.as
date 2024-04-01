namespace cso_p90
{

const bool USE_PENETRATION							= true;

const int CSOW_MAX_CLIP 								= 50;
const int CSOW_TRACERFREQ							= 2;
const float CSOW_DAMAGE								= 21;
const float CSOW_TIME_DELAY						= 0.086;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 20.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 3.4;
const float CSOW_SPREAD_JUMPING				= 0.3;
const float CSOW_SPREAD_RUNNING				= 0.115;
const float CSOW_SPREAD_WALKING				= 0.050;
const float CSOW_SPREAD_STANDING			= 0.025;
const float CSOW_SPREAD_DUCKING				= 0.02;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_SHELL_ORIGIN				= Vector(20.0, -12.0, -8.0); //forward, right, up
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 15.259552, 4.463806, -3.458954 );

const string CSOW_ANIMEXT							= "mp5"; //carbine

const string MODEL_VIEW								= "models/custom_weapons/cso/v_p90.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_p90.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_p90.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/rshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,	
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/p90-1.wav",
	"custom_weapons/cso/p90_boltpull.wav",
	"custom_weapons/cso/p90_clipin.wav",
	"custom_weapons/cso/p90_clipout.wav",
	"custom_weapons/cso/p90_cliprelease.wav"
};

class weapon_p90 : CBaseCSOWeapon
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = cso::GIVE_57MM;
		self.m_flCustomDmg = pev.dmg;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_p90.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud12.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud13.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash3.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_p90.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= cso::MAXCARRY_57MM;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::P90_SLOT - 1;
		info.iPosition		= cso::P90_POSITION - 1;
		info.iWeight			= cso::P90_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_p90") );
		m.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], VOL_NORM, ATTN_NORM );
		}

		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 84 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 1;
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_57MM, CSOW_TRACERFREQ, flDamage, 0.885, CSOF_ALWAYSDECAL, CSOW_OFFSETS_MUZZLE );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x - g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, true, true );

		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
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

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_p90::weapon_p90", "weapon_p90" );
	g_ItemRegistry.RegisterWeapon( "weapon_p90", "custom_weapons/cso", "57mm", "ammo_57mm" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_57mm" ) ) 
		cso::Register57MM();
}

} //namespace cso_p90 END