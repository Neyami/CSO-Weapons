namespace cso_aug
{

const bool USE_CSLIKE_RECOIL					= false;
const bool USE_PENETRATION					= true;

const int CSOW_DEFAULT_GIVE					= 30;
const int CSOW_MAX_CLIP 						= 30;
const int CSOW_MAX_AMMO						= 90;
const float CSOW_DAMAGE						= 28;
const float CSOW_TIME_DELAY1					= 0.0825;
const float CSOW_TIME_DELAY2					= 0.3;
const float CSOW_TIME_DRAW					= 0.75;
const float CSOW_TIME_IDLE						= 20.0;
const float CSOW_TIME_RELOAD				= 3.3;
const float CSOW_TIME_FIRE_TO_IDLE1		= 1.9;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE_STANDING			= VECTOR_CONE_2DEGREES;
const Vector CSOW_CONE_CROUCHING		= VECTOR_CONE_1DEGREES;
const Vector CSOW_SHELL_ORIGIN				= Vector(17.0, 14.0, -8.0); //forward, right, up

const string CSOW_ANIMEXT						= "m16";

const string MODEL_VIEW							= "models/custom_weapons/cso/v_aug.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_aug.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_aug.mdl";
const string MODEL_SHELL							= "models/custom_weapons/cso/pshell.mdl";

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
	"custom_weapons/cso/aug-1.wav",
	"custom_weapons/cso/aug_boltpull.wav",
	"custom_weapons/cso/aug_boltslap.wav",
	"custom_weapons/cso/aug_clipin.wav",
	"custom_weapons/cso/aug_clipout.wav",
	"custom_weapons/cso/aug_forearm.wav"
};

class weapon_aug : CBaseCSOWeapon
{
	private float m_flAccuracy;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_aug.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud14.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud15.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash3.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_aug.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= cso::AUG_SLOT - 1;
		info.iPosition		= cso::AUG_POSITION - 1;
		info.iWeight		= cso::AUG_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_aug") );
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
			m_flAccuracy = 0.2;
			m_iShotsFired = 0;

			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW*2);

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
			m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH; //Needed??
			self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;
			Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE_CROUCHING : CSOW_CONE_STANDING;

			//m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, CSOW_DAMAGE );
			int iPenetration = USE_PENETRATION ? 2 : 0;
			cso::FireBullets3( vecSrc, g_Engine.v_forward, 0, 8192, iPenetration, BULLET_PLAYER_556MM, CSOW_DAMAGE, 1.0, EHandle(m_pPlayer), m_pPlayer.random_seed );
			//DoDecalGunshot( vecSrc, g_Engine.v_forward, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_SAW, true );

			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

			HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

			if( m_pPlayer.pev.fov == 0 )
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
			else
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.135;

			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;
		}
		else
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
				AUGFire( 0.035 + (0.4) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else if( m_pPlayer.pev.velocity.Length2D() > 140 )
				AUGFire( 0.035 + (0.07) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else if( m_pPlayer.pev.fov == 0 )
				AUGFire( (0.02) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else
				AUGFire( (0.02) * m_flAccuracy, 0.135 );
		}
	}

	void AUGFire( float flSpread, float flCycleTime )
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
		cso::FireBullets3( vecSrc, g_Engine.v_forward, flSpread, 8192, iPenetration, BULLET_PLAYER_556MM, CSOW_DAMAGE, 0.96, EHandle(m_pPlayer), m_pPlayer.random_seed );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		//m_pPlayer.FireBullets( 1, vecSrc, g_Engine.v_forward, vecShootCone, 8192.0, BULLET_PLAYER_SAW, 4, 0 );

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
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40;

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		m_flAccuracy = 0;
		m_iShotsFired = 0;
		m_bDelayFire = false;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_aug::weapon_aug", "weapon_aug" );
	g_ItemRegistry.RegisterWeapon( "weapon_aug", "custom_weapons/cso", "556", "ammo_556" );
}

} //namespace cso_aug END