namespace cso_svd
{

const bool USE_PENETRATION					= true;
const string CSOW_NAME						= "weapon_svd";

const int CSOW_DEFAULT_GIVE				= 10;
const int CSOW_MAX_CLIP 						= 10;
const int CSOW_MAX_AMMO					= 90;
const float CSOW_DAMAGE						= 99;
const float CSOW_TIME_DELAY1				= 0.6;
const float CSOW_TIME_DELAY2				= 0.3;
const float CSOW_TIME_DRAW				= 1.3;
const float CSOW_TIME_IDLE					= 60.0;
const float CSOW_TIME_RELOAD			= 3.5;
const float CSOW_SPREAD_JUMPING		= 0.85;
const float CSOW_SPREAD_RUNNING		= 0.25;
const float CSOW_SPREAD_WALKING		= 0.1;
const float CSOW_SPREAD_STANDING	= 0.001;
const float CSOW_SPREAD_DUCKING		= 0.0;
const float CSOW_RECOIL						= 2.0;
const Vector CSOW_SHELL_ORIGIN		= Vector(20.0, 12.0, -4.0); //forward, right, up
const string CSOW_ANIMEXT					= "sniper"; //rifle

const string MODEL_VIEW						= "models/custom_weapons/cso/v_svd.mdl";
const string MODEL_PLAYER					= "models/custom_weapons/cso/p_svd.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/w_svd.mdl";
const string MODEL_SHELL						= "models/custom_weapons/cso/rshell_big.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_ZOOM,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/zoom.wav",
	"custom_weapons/cso/svd-1.wav",
	"custom_weapons/cso/svd_clipin.wav",
	"custom_weapons/cso/svd_clipon.wav",
	"custom_weapons/cso/svd_clipout.wav",
	"custom_weapons/cso/svd_draw.wav"
};

class weapon_svd : CBaseCSOWeapon
{
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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_svd.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud23.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/sniper_scope.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::SVD_SLOT - 1;
		info.iPosition		= cso::SVD_POSITION - 1;
		info.iWeight			= cso::SVD_WEIGHT;

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

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], VOL_NORM, ATTN_NORM );
		}

		return false;
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			ResetZoom();

		BaseClass.Holster( skiplocal );
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = g_Engine.time + (CSOW_TIME_DRAW - 0.4);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.4, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0;
		cso::FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), 8192, iPenetration, BULLET_PLAYER_762MM, flDamage, 1.0, EHandle(m_pPlayer), m_pPlayer.random_seed, CSOF_ALWAYSDECAL );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false, true );

		self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1/2;

		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		m_pPlayer.pev.punchangle.x -= CSOW_RECOIL;
	}

	void SecondaryAttack()
	{
		switch( m_pPlayer.m_iFOV )
		{
			case 0: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40; m_pPlayer.m_szAnimExtension = "sniperscope"; break;
			case 40: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10; break;
			default: ResetZoom(); break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_ZOOM], 0.2, 2.4 );
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10;
			SecondaryAttack();
		}

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD + 0.5);

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( self.m_iClip > 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
			self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}

	void ResetZoom()
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		m_pPlayer.m_szAnimExtension = "sniper";
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_svd::weapon_svd", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "m40a1", "", "ammo_762" );
}

} //namespace cso_svd END