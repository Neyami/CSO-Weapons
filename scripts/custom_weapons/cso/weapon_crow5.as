namespace cso_crow5
{

const bool USE_CSLIKE_RECOIL						= false;
const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_crow5";

const int CSOW_DEFAULT_GIVE						= 50;
const int CSOW_MAX_CLIP 							= 50;
const int CSOW_MAX_AMMO							= 90;
const int CSOW_TRACERFREQ							= 2;
const float CSOW_DAMAGE								= 26;
const float CSOW_TIME_DELAY1						= 0.0955;
const float CSOW_TIME_DELAY2						= 0.135; //zoomed in
const float CSOW_TIME_DELAY_ZOOM				= 0.3;
const float CSOW_TIME_DRAW_TO_FIRE			= 0.75;
const float CSOW_TIME_DRAW_TO_IDLE			= 1.5;
const float CSOW_TIME_IDLE							= 2.0;
const float CSOW_TIME_FIRE_TO_IDLE1			= 1.9;
const float CSOW_TIME_RELOAD1					= 3.0; //normal
const float CSOW_TIME_RELOAD2					= 2.0; //quick
const float CSOW_TIME_RELOAD_PRE				= 0.6; //time before quick reload becomes available after hitting the reload-key the first time
const float CSOW_TIME_RELOAD_WINDOW		= 0.4; //the time between when quick reload becomes available and the normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_NORM	= 2.0; //reload time after normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_QUICK	= 1.0; //reload time after quick reload has been activated
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.01785;
const float CSOW_SPREAD_WALKING				= 0.01785;
const float CSOW_SPREAD_STANDING				= 0.01718;
const float CSOW_SPREAD_DUCKING				= 0.01289;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D(0, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D(0, 0);
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 29.123854, 3.328030, -2.666483 ); //forward, right, up //Vector( 22.414886, 5.827087, -2.659210 );
const Vector CSOW_OFFSETS_SHELL				= Vector( 11.414523, 6.387324, -4.091387 ); //Vector(17.0, 14.0, -8.0);
const int CSOW_ZOOM_FOV							= 31;

const string CSOW_ANIMEXT							= "m16";
const string CSOW_ANIMEXT_CSO					= "carbine";

const string MODEL_VIEW								= "models/custom_weapons/cso/crow5/v_crow5.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/crow5/p_crow5.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/crow5/w_crow5.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/rshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD_START,
	ANIM_RELOAD_END_QUICK,
	ANIM_RELOAD_END_NORMAL,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/crow-1.wav",
	"custom_weapons/cso/crow5_draw.wav",
	"custom_weapons/cso/crow5_reload_a.wav",
	"custom_weapons/cso/crow5_reload_b.wav",
	"custom_weapons/cso/crow5_reload_in.wav"
};

class weapon_crow5 : CBaseCSOWeapon, CSOCrowSeries
{
	private float m_flAccuracy;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		m_flAccuracy = 0.2;
		m_iShotsFired = 0;

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
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash3.spr" );

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_crow5.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud142.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::CROW5_SLOT - 1;
		info.iPosition			= cso::CROW5_POSITION - 1;
		info.iWeight			= cso::CROW5_WEIGHT;

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
			m_flAccuracy = 0.2;
			m_iShotsFired = 0;

			bResult = CSODeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, PlayerHasCSOModel() ? CSOW_ANIMEXT_CSO : CSOW_ANIMEXT, CSOW_TIME_DRAW_TO_FIRE, CSOW_TIME_DRAW_TO_IDLE );

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

		if( !USE_CSLIKE_RECOIL )
		{
			HandleAmmoReduction( 1 );

			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			m_pPlayer.pev.effects |= EF_MUZZLEFLASH; //Needed??
			self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;

			int iPenetration = USE_PENETRATION ? 2 : 1;
			FireBullets3( vecSrc, g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_556MM, CSOW_TRACERFREQ, CSOW_DAMAGE, 1.0, CSOF_ALWAYSDECAL, CSOW_OFFSETS_MUZZLE );

			MuzzleflashCSO( 1, "#I3 S0.25 R1 F0 P30 T0.01 A1 L0 O0", 200 );

			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x + g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell );

			HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

			if( m_pPlayer.pev.fov == 0 )
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
			else
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;

			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;
		}
		else
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
				CROW5Fire( 0.035 + (0.4) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else if( m_pPlayer.pev.velocity.Length2D() > 140 )
				CROW5Fire( 0.035 + (0.07) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else if( m_pPlayer.pev.fov == 0 )
				CROW5Fire( (0.02) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else
				CROW5Fire( (0.02) * m_flAccuracy, CSOW_TIME_DELAY2 );
		}
	}

	void CROW5Fire( float flSpread, float flCycleTime )
	{
		m_bDelayFire = true;
		m_iShotsFired++;
		m_flAccuracy = float((m_iShotsFired * m_iShotsFired * m_iShotsFired) / 215.0) + 0.3;

		if( m_flAccuracy > 1 )
			m_flAccuracy = 1;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		int iPenetration = USE_PENETRATION ? 2 : 0;
		FireBullets3( vecSrc, g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_556MM, CSOW_TRACERFREQ, CSOW_DAMAGE, 0.96, CSOF_ALWAYSDECAL, CSOW_OFFSETS_MUZZLE );

		MuzzleflashCSO( 1, "#I3 S0.25 R1 F0 P30 T0.01 A1 L0 O0", 200 );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x + g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;

		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 1.0, 0.45, 0.275, 0.05, 4.0, 2.5, 7 );
		else if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			KickBack( 1.25, 0.45, 0.22, 0.18, 5.5, 4.0, 5 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			KickBack( 0.575, 0.325, 0.2, 0.011, 3.25, 2.0, 8 );
		else
			KickBack( 0.625, 0.375, 0.25, 0.0125, 3.5, 2.25, 8 );
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.m_iFOV != 0 )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		else
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = CSOW_ZOOM_FOV;

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY_ZOOM;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2)));
	}

	void ItemPostFrame()
	{
		if( m_pPlayer.pev.button & (IN_ATTACK | IN_ATTACK2) == 0 )
		{
			if( m_bDelayFire )
			{
				m_bDelayFire = false;

				if( m_iShotsFired > 15 )
					m_iShotsFired = 15;

				m_flDecreaseShotsFired = g_Engine.time + 0.4;
			}

			self.m_bFireOnEmpty = false;

			if( m_iShotsFired > 0 )
			{
				if( g_Engine.time > m_flDecreaseShotsFired )
				{
					m_iShotsFired--;
					m_flDecreaseShotsFired = g_Engine.time + 0.0225;
				}
			}

			WeaponIdle();
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crow5::weapon_crow5", "weapon_crow5" );
	g_ItemRegistry.RegisterWeapon( "weapon_crow5", "custom_weapons/cso", "crow5ammo" ); //556
}

} //namespace cso_crow5 END