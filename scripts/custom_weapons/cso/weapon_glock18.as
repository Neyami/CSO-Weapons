namespace cso_glock18
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_glock18";

const int CSOW_DEFAULT_GIVE						= 20;
const int CSOW_MAX_CLIP 							= 20;
const int CSOW_MAX_AMMO							= 120;
const int CSOW_TRACERFREQ							= 1;
const float CSOW_DAMAGE1							= 25;
const float CSOW_DAMAGE2							= 32;
const float CSOW_TIME_DELAY_BURST			= 0.02; //time between burst shots
const float CSOW_TIME_DRAW						= 0.7;
const float CSOW_TIME_IDLE							= 1.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD						= 2.2;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.15;
const float CSOW_SPREAD_WALKING				= 0.1;
const float CSOW_SPREAD_STANDING				= 0.05;
const float CSOW_SPREAD_DUCKING				= 0.02;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -2);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D(0, 0);
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 17.396296, 4.428030, -2.887005 );//Vector( 30.082214, 6.318542, -3.830643 );
const Vector CSOW_OFFSETS_SHELL				= Vector( 12.750802, -4.668098, -2.877388 );//Vector( 17.0, -8.0, -4.0 ); //forward, right, up

const string CSOW_ANIMEXT							= "onehanded";
const string CSOW_ANIMEXT_SHIELD				= "shieldgun";

const string MODEL_VIEW								= "models/custom_weapons/cso/glock18/v_glock18.mdl";
const string MODEL_VIEW_SHIELD					= "models/custom_weapons/cso/shield/v_shield_glock18.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/glock18/p_glock18.mdl";
const string MODEL_PLAYER_SHIELD				= "models/custom_weapons/cso/shield/p_shield_glock18.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/glock18/w_glock18.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/pshell.mdl";

enum csow_e
{
	ANIM_IDLE1,
	ANIM_IDLE2,
	ANIM_IDLE3,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_SHOOT_EMPTY,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_HOLSTER,
	ANIM_ADD_SILENCER,
	ANIM_DRAW2,
	ANIM_RELOAD2
};

enum glock18_shield_e
{
	ANIM_SHIELD_IDLE1,
	ANIM_SHIELD_SHOOT,
	ANIM_SHIELD_SHOOT2,
	ANIM_SHIELD_SHOOT_EMPTY,
	ANIM_SHIELD_RELOAD,
	ANIM_SHIELD_DRAW,
	ANIM_SHIELD_IDLE,
	ANIM_SHIELD_UP,
	ANIM_SHIELD_DOWN
};

enum csowsounds_e
{
	SND_SHOOT1 = 1,
	SND_SHOOT2
};

const array<string> arrsCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",  //only here for the precache
	"custom_weapons/cso/glock18/glock18-1.wav",
	"custom_weapons/cso/glock18/glock18-2.wav",
	"custom_weapons/cso/glock18/clipin1.wav",
	"custom_weapons/cso/glock18/clipout1.wav",
	"custom_weapons/cso/glock18/slideback1.wav",
	"custom_weapons/cso/glock18/sliderelease1.wav"
};

const int WPNSTATE_GLOCK18_BURST_MODE = 1 << 1;

class weapon_glock18 : CBaseCSOWeapon
{
	private bool m_bBurstFire;
	private int m_iGlock18ShotsFired;
	private float m_flGlock18Shoot;
	private float m_flAccuracy;
	private float m_flLastFire;

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
		m_sEmptySound = arrsCSOWSounds[0];

		m_bBurstFire = false;
		m_iGlock18ShotsFired = 0;
		m_flGlock18Shoot = 0;
		m_flAccuracy = 0.9;
		m_iWeaponState &= ~WPNSTATE_SHIELD_DRAWN;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_VIEW_SHIELD );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_PLAYER_SHIELD );
		g_Game.PrecacheModel( MODEL_WORLD );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < arrsCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < arrsCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + arrsCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud1.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud4.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash2.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_glock18.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::GLOCK18_SLOT - 1;
		info.iPosition			= cso::GLOCK18_POSITION - 1;
		info.iWeight			= cso::GLOCK18_WEIGHT;

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
			if( HasShield() )
				bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW_SHIELD), self.GetP_Model(MODEL_PLAYER_SHIELD), ANIM_SHIELD_DRAW, CSOW_ANIMEXT_SHIELD );
			else
				bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), brandom() ? ANIM_DRAW : ANIM_DRAW2, CSOW_ANIMEXT );

			//bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), brandom() ? ANIM_DRAW : ANIM_DRAW2, CSOW_ANIMEXT );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW*2)));

			m_bBurstFire = false;
			m_iGlock18ShotsFired = 0;
			m_flGlock18Shoot = 0;
			m_flAccuracy = 0.9;
			//m_fMaxSpeed = 250;
			m_iWeaponState &= ~WPNSTATE_SHIELD_DRAWN;
			//m_pPlayer.m_bShieldDrawn = false;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true; //without this, PlayEmptySound only plays once
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
			return;
		}

		if( cso::HasFlags(m_iWeaponState, WPNSTATE_GLOCK18_BURST_MODE) )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
				GLOCK18Fire( (1.2) * (1 - m_flAccuracy), 0.5, true );
			else if( m_pPlayer.pev.velocity.Length2D() > 0 )
				GLOCK18Fire( (0.185) * (1 - m_flAccuracy), 0.5, true );
			else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
				GLOCK18Fire( (0.095) * (1 - m_flAccuracy), 0.5, true );
			else
				GLOCK18Fire( (0.3) * (1 - m_flAccuracy), 0.5, true );
		}
		else
		{
			if( !cso::HasFlags(m_iWeaponState, WPNSTATE_SHIELD_DRAWN) )
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
					GLOCK18Fire( (1.0) * (1 - m_flAccuracy), 0.2, false );
				else if( m_pPlayer.pev.velocity.Length2D() > 0 )
					GLOCK18Fire( (0.165) * (1 - m_flAccuracy), 0.2, false );
				else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
					GLOCK18Fire( (0.075) * (1 - m_flAccuracy), 0.2, false );
				else
					GLOCK18Fire( (0.1) * (1 - m_flAccuracy), 0.2, false );
			}
		}
	}

	void GLOCK18Fire( float flSpread, float flCycleTime, bool bUseBurstMode )
	{
		if( bUseBurstMode )
			m_iGlock18ShotsFired = 0;
		else
		{
			m_iShotsFired++;
			flCycleTime -= 0.05;

			if( m_iShotsFired > 1 )
				return;
		}

		if( m_flLastFire > 0 )
		{
			m_flAccuracy -= ( 0.325 - (g_Engine.time - m_flLastFire) ) * 0.275;

			if( m_flAccuracy > 0.9 )
				m_flAccuracy = 0.9;
			else if( m_flAccuracy < 0.6 )
				m_flAccuracy = 0.6;
		}

		m_flLastFire = g_Engine.time;

		if( self.m_iClip <= 0 )
		{
			if( self.m_bFireOnEmpty )
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			}

			return;
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		SetPlayerShieldAnim();
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		float flDamage = CSOW_DAMAGE1;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 1 : 0; 
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, flSpread, 1, BULLET_PLAYER_9MM, CSOW_TRACERFREQ, flDamage, 0.75, CSOF_ALWAYSDECAL, CSOW_OFFSETS_MUZZLE );
		//PLAYBACK_EVENT_FULL(flags, m_pPlayer.edict(), m_usFireGlock18, 0, (float *)&g_vecZero, (float *)&g_vecZero, vecDir.x, vecDir.y, (int)(m_pPlayer.pev.punchangle.x * 100), (int)(m_pPlayer.pev.punchangle.y * 100), m_iClip != 0, FALSE);

		int iAnim, iSound;
		if( self.m_iClip > 0 )
		{
			if( HasShield() ) //g_bHoldingShield
				iAnim = ANIM_SHIELD_SHOOT;
			else
				iAnim = ( cso::HasFlags(m_iWeaponState, WPNSTATE_GLOCK18_BURST_MODE) ) ? ANIM_SHOOT1: ANIM_SHOOT3; //g_iWeaponFlags
		}
		else
		{
			if( HasShield() ) //g_bHoldingShield
				iAnim = ANIM_SHIELD_SHOOT_EMPTY;
			else
				iAnim = ANIM_SHOOT_EMPTY;
		}

		self.SendWeaponAnim( iAnim );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false );

		//iSound = cso::HasFlags(m_iWeaponState, WPNSTATE_GLOCK18_BURST_MODE) ? SND_SHOOT1: SND_SHOOT2;
		//g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[iSound], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomFloat(0, 15) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT2], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + 2.5;

		if( bUseBurstMode )
		{
			m_iGlock18ShotsFired++;
			m_flGlock18Shoot = g_Engine.time + CSOW_TIME_DELAY_BURST;
		}

		ResetPlayerShieldAnim();
	}

	void SecondaryAttack()
	{
		if( ShieldSecondaryFire(ANIM_SHIELD_UP, ANIM_SHIELD_DOWN) )
			return;

		if( cso::HasFlags(m_iWeaponState, WPNSTATE_GLOCK18_BURST_MODE) )
		{
			g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "Changed to semi-automatic mode." );
			m_iWeaponState &= ~WPNSTATE_GLOCK18_BURST_MODE;
		}
		else
		{
			g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "Changed to burst mode." );
			m_iWeaponState |= WPNSTATE_GLOCK18_BURST_MODE;
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 0.3;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 or cso::HasFlags(m_iWeaponState, WPNSTATE_SHIELD_DRAWN) )
			return;

		int iAnim;

		if( HasShield() )
			iAnim = ANIM_SHIELD_RELOAD;
		else if( brandom() )
			iAnim = ANIM_RELOAD;
		else
			iAnim = ANIM_RELOAD2;

		if( self.DefaultReload(CSOW_MAX_CLIP, iAnim, CSOW_TIME_RELOAD))
		{
			m_pPlayer.SetAnimation( PLAYER_RELOAD );
			m_flAccuracy = 0.9;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD + 0.5);

		//BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( HasShield() )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + 20.0;

			if( cso::HasFlags(m_iWeaponState, WPNSTATE_SHIELD_DRAWN) )
				self.SendWeaponAnim( ANIM_SHIELD_IDLE );

			return;
		}

		if( self.m_iClip > 0 )
		{
			float flRand = Math.RandomFloat( 0, 1 );

			if( flRand < 0.3 )
			{
				self.m_flTimeWeaponIdle = g_Engine.time + 3.0625;
				self.SendWeaponAnim( ANIM_IDLE3 );
			}
			else if (flRand < 0.6)
			{
				self.m_flTimeWeaponIdle = g_Engine.time + 3.75;
				self.SendWeaponAnim( ANIM_IDLE1 );
			}
			else
			{
				self.m_flTimeWeaponIdle = g_Engine.time + 2.5;
				self.SendWeaponAnim( ANIM_IDLE2 );
			}
		}
	}

	void ItemPostFrame()
	{
		if( m_flGlock18Shoot != 0 and g_Engine.time > m_flGlock18Shoot )
			FireRemaining();

		if( !cso::HasFlags(m_pPlayer.pev.button, (IN_ATTACK | IN_ATTACK2)) )
			m_iShotsFired = 0;

		BaseClass.ItemPostFrame();
	}

	void FireRemaining()
	{
		HandleAmmoReduction( 1 ); //self.m_iClip--;

		if( self.m_iClip < 0 )
		{
			self.m_iClip = 0;
			m_iGlock18ShotsFired = 3;
			m_flGlock18Shoot = 0;
			return;
		}

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		//FireBullets3(m_pPlayer.GetGunPosition(), gpGlobals.v_forward, 0.05, 8192, 1, BULLET_PLAYER_9MM, 18, 0.9, m_pPlayer.pev, TRUE, m_pPlayer.random_seed);
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, 0.05, 1, BULLET_PLAYER_9MM, 1, 18, 0.9, CSOF_ALWAYSDECAL );
		//PLAYBACK_EVENT_FULL(flags, ENT(m_pPlayer.pev), m_usFireGlock18, 0, (float *)&g_vecZero, (float *)&g_vecZero, vecDir.x, vecDir.y, (int)(m_pPlayer.pev.punchangle.x * 10000), (int)(m_pPlayer.pev.punchangle.y * 10000), m_iClip != 0, FALSE);
		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT2], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );
		//m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 ); //m_pPlayer.ammo_9mm--;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_iGlock18ShotsFired++;

		if( m_iGlock18ShotsFired == 3 )
			m_flGlock18Shoot = 0;
		else
			m_flGlock18Shoot = g_Engine.time + CSOW_TIME_DELAY_BURST;
	}
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_glock18::weapon_glock18", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "glock18ammo" ); //9mm
}

} //namespace cso_glock18 END