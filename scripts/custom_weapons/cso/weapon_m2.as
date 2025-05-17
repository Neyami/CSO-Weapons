namespace cso_m2
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_m2";

const int CSOW_DEFAULT_GIVE						= 250;
const int CSOW_MAX_CLIP 								= 250;
const int CSOW_MAX_AMMO							= 500;
const int CSOW_TRACERFREQ							= 4;
const float CSOW_DAMAGE_A							= 30;
const float CSOW_DAMAGE_B							= 23;
const float CSOW_TIME_DELAY_A					= 0.30;
const float CSOW_TIME_DELAY_B					= 0.11;
const float CSOW_TIME_DELAY_CHANGE_A	= 4.7;
const float CSOW_TIME_DELAY_CHANGE_B	= 3.7;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 2.8;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.4;
const float CSOW_TIME_RELOAD_A				= 6.1;
const float CSOW_TIME_RELOAD_B				= 5.5;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.15;
const float CSOW_SPREAD_WALKING				= 0.1;
const float CSOW_SPREAD_STANDING			= 0.05;
const float CSOW_SPREAD_DUCKING				= 0.02;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -2);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(-1, 1);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(-0.25, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(-0.25, 0.25);
const Vector CSOW_OFFSETS_MUZZLE_A		= Vector( 57.292938, 6.706848, -8.466423 ); //forward, right, up
const Vector CSOW_OFFSETS_SHELL_A			= Vector( 20.294096, -8.645997, -7.482176 );
const Vector CSOW_OFFSETS_MUZZLE_B		= Vector( 68.616280, 0.156617, -9.340979 );
const Vector CSOW_OFFSETS_SHELL_B			= Vector( 31.617718, -2.129577, -8.417007 );

const string CSOW_ANIMEXT_A						= "minigun"; //m134
const string CSOW_ANIMEXT_B						= "sniper"; //bow also works, but no muzzleflash

const string MODEL_VIEW								= "models/custom_weapons/cso/v_m2.mdl";
const string MODEL_PLAYER_A						= "models/custom_weapons/cso/p_m2_1.mdl";
const string MODEL_PLAYER_B						= "models/custom_weapons/cso/p_m2_2.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_m2.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/rshell.mdl";

enum csow_e
{
	ANIM_IDLE_A = 0,
	ANIM_IDLE_B,
	ANIM_DRAW,
	ANIM_DRAW_EMPTY,
	ANIM_CHANGE_ATOB,
	ANIM_CHANGE_ATOB_EMPTY,
	ANIM_CHANGE_BTOA,
	ANIM_CHANGE_BTOA_EMPTY,
	ANIM_RELOAD_A,
	ANIM_RELOAD_B,
	ANIM_SHOOT_A,
	ANIM_SHOOT_B,
	ANIM_IDLE_A_EMPTY,
	ANIM_IDLE_B_EMPTY
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/m2-1.wav",
	"custom_weapons/cso/m2_clipin.wav",
	"custom_weapons/cso/m2_clipin2.wav",
	"custom_weapons/cso/m2_cliplock.wav",
	"custom_weapons/cso/m2_clipout.wav",
	"custom_weapons/cso/m2_close.wav",
	"custom_weapons/cso/m2_draw.wav",
	"custom_weapons/cso/m2_foley1.wav",
	"custom_weapons/cso/m2_foley2.wav",
	"custom_weapons/cso/m2_open.wav"
};

class weapon_m2 : CBaseCSOWeapon
{
	private bool m_bDeployed;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		m_bDeployed = false;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_A );
		g_Game.PrecacheModel( MODEL_PLAYER_B );
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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud102.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::M2_SLOT - 1;
		info.iPosition		= cso::M2_POSITION - 1;
		info.iWeight			= cso::M2_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER_A), (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_DRAW : ANIM_DRAW_EMPTY, CSOW_ANIMEXT_A, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		m_bDeployed = false;
		UnMallard();
		m_pPlayer.SetMaxSpeedOverride( -1 );
		m_pPlayer.pev.fuser4 = 0;

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
		self.SendWeaponAnim( m_bDeployed ? ANIM_SHOOT_B : ANIM_SHOOT_A, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = m_bDeployed ? CSOW_DAMAGE_B : CSOW_DAMAGE_A;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0; 
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_50BMG, CSOW_TRACERFREQ, flDamage, 1.0, CSOF_ARMORPEN, m_bDeployed ? CSOW_OFFSETS_MUZZLE_B : CSOW_OFFSETS_MUZZLE_A );

		Vector vecShellOffsets = m_bDeployed ? CSOW_OFFSETS_SHELL_B : CSOW_OFFSETS_SHELL_A;
		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * vecShellOffsets.x - g_Engine.v_right * vecShellOffsets.y + g_Engine.v_up * vecShellOffsets.z, m_iShell, TE_BOUNCE_SHELL, true, !m_bDeployed );

		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (m_bDeployed ? CSOW_TIME_DELAY_B : CSOW_TIME_DELAY_A);
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}

	void SecondaryAttack()
	{
		if( !m_bDeployed )
		{
			if( m_pPlayer.IsOnLadder() )
			{
				g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile on a ladder" );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
				return;
			}

			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			{
				g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
				return;
			}

			if( m_pPlayer.pev.waterlevel > WATERLEVEL_FEET )
			{
				g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in water" );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
				return;
			}

			self.SendWeaponAnim( (self.m_iClip > 0) ? ANIM_CHANGE_ATOB : ANIM_CHANGE_ATOB_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			ForceMallard();

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_pPlayer.pev.fuser4 = 1;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_B;
			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT_B;
		}
		else
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? ANIM_CHANGE_BTOA : ANIM_CHANGE_BTOA_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			UnMallard();

			m_pPlayer.SetMaxSpeedOverride( -1 );
			m_pPlayer.pev.fuser4 = 0;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_A;
			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT_A;
		}

		float flTime = (m_bDeployed ? CSOW_TIME_DELAY_CHANGE_B : CSOW_TIME_DELAY_CHANGE_A);
		m_bDeployed = !m_bDeployed;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
		self.m_flTimeWeaponIdle = g_Engine.time + (flTime + 0.5);
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		float flReloadTime = m_bDeployed ? CSOW_TIME_RELOAD_B : CSOW_TIME_RELOAD_A;
		self.DefaultReload( CSOW_MAX_CLIP, m_bDeployed ? ANIM_RELOAD_B : ANIM_RELOAD_A, flReloadTime, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + flReloadTime;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int	iAnimA = (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_IDLE_A : ANIM_IDLE_A_EMPTY,
				iAnimB = (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_IDLE_B : ANIM_IDLE_B_EMPTY;

		self.SendWeaponAnim( m_bDeployed ? iAnimB : iAnimA, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2));
	}

	void ItemPreFrame()
	{
		if( m_bDeployed )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
				ForceMallard();
		}

		BaseClass.ItemPreFrame();
	}

	void ForceMallard()
	{
		NetworkMessage forcemallard( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			forcemallard.WriteString( "+duck\n" );
		forcemallard.End();
	}

	void UnMallard()
	{
		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "-duck\n" );
		m1.End();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m2::weapon_m2", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "50bmg", "", "ammo_50bmg" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_50bmg" ) ) 
		cso::Register50BMG();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_m2 END