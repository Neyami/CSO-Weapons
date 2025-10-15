namespace cso_ak47
{

const bool USE_CSLIKE_RECOIL						= false;
const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_ak47";

const int CSOW_DEFAULT_GIVE						= 30;
const int CSOW_MAX_CLIP 							= 30;
const int CSOW_MAX_AMMO							= 90;
const int CSOW_TRACERFREQ							= 2;
const float CSOW_DAMAGE								= 36;
const float CSOW_TIME_DELAY						= 0.0955;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 1.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD						= 2.5;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.15;
const float CSOW_SPREAD_WALKING				= 0.1;
const float CSOW_SPREAD_STANDING				= 0.05;
const float CSOW_SPREAD_DUCKING				= 0.02;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -2);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D(0, 0);
//const Vector CSOW_OFFSETS_SHELL				= Vector( 20.0, -8.0, -10.0 ); //forward, right, up
const Vector CSOW_OFFSETS_SHELL				= Vector( 28.245131, -7.099761, -4.173389 ); //forward, right, up

const Vector CSOW_OFFSETS_MUZZLE			= Vector( 30.082214, 6.318542, -3.830643 );

const string CSOW_ANIMEXT							= "mp5";
const string CSOW_ANIMEXT_CSO					= "ak47";

const string MODEL_VIEW								= "models/custom_weapons/cso/ak47/v_ak47.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/ak47/p_ak47.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/ak47/w_ak47.mdl";
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
	SND_SHOOT1 = 1,
	SND_SHOOT2
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",  //only here for the precache
	"custom_weapons/cso/ak47/ak47-1.wav",
	"custom_weapons/cso/ak47/ak47-2.wav",
	"custom_weapons/cso/ak47/ak47_boltpull.wav",
	"custom_weapons/cso/ak47/ak47_clipin.wav",
	"custom_weapons/cso/ak47/ak47_clipout.wav"
};

class weapon_ak47 : CBaseCSOWeapon
{
	private float m_flAccuracy;

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

		m_iWeaponType = TYPE_PRIMARY;
		m_sEmptySound = pCSOWSounds[0];

		m_flAccuracy = 0.2;
		m_iShotsFired = 0;

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud10.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud11.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::AK47_SLOT - 1;
		info.iPosition			= cso::AK47_POSITION - 1;
		info.iWeight			= cso::AK47_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, PlayerHasCSOModel() ? CSOW_ANIMEXT_CSO : CSOW_ANIMEXT );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW*2)));

			m_flAccuracy = 0.2;
			m_iShotsFired = 0;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true; //without this, PlayEmptySound only plays once
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( !USE_CSLIKE_RECOIL )
		{
			HandleAmmoReduction( 1 );

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3) );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT2)], VOL_NORM, ATTN_NORM );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;

			float flDamage = CSOW_DAMAGE;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			int iPenetration = USE_PENETRATION ? 2 : 0; 
			FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_762MM, CSOW_TRACERFREQ, flDamage, 1.0, 0, CSOW_OFFSETS_MUZZLE );

			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false );

			HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
		}
		else
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
				AK47Fire( 0.04 + (0.4) * m_flAccuracy, 0.0955, false );
			else if( m_pPlayer.pev.velocity.Length2D() > 140 )
				AK47Fire( 0.04 + (0.07) * m_flAccuracy, 0.0955, false );
			else
				AK47Fire( (0.0275), 0.0955, false );
		}
	}

	void AK47Fire( float flSpread, float flCycleTime, bool fUseAutoAim )
	{
		m_bDelayFire = true;
		m_iShotsFired++;
		m_flAccuracy = float((m_iShotsFired * m_iShotsFired * m_iShotsFired) / 200.0) + 0.35;

		if( m_flAccuracy > 1.25 )
			m_flAccuracy = 1.25;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0;
		FireBullets3( vecSrc, g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_762MM, CSOW_TRACERFREQ, flDamage, 0.98 );

		//PLAYBACK_EVENT_FULL(flags, m_pPlayer.edict(), m_usFireAK47, 0, (float *)&g_vecZero, (float *)&g_vecZero, vecDir.x, vecDir.y, (int)(m_pPlayer.pev.punchangle.x * 100), (int)(m_pPlayer.pev.punchangle.y * 100), FALSE, FALSE);
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x + g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT2)], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + 1.9;

		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7 );
		else if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			KickBack( 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			KickBack( 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9 );
		else
			KickBack( 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

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
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2)));
	}
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_ak47::weapon_ak47", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "ak47ammo" ); //"762mg", "", "ammo_762mg"
}

} //namespace cso_ak47 END