namespace cso_elites
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_elites";

const int CSOW_DEFAULT_GIVE						= 30;
const int CSOW_MAX_CLIP 								= 30;
const int CSOW_MAX_AMMO							= 120;
const int CSOW_TRACERFREQ							= 0;
const float CSOW_DAMAGE								= 36;
const float CSOW_TIME_DELAY						= 0.2;
const float CSOW_TIME_DRAW						= 1.1;
const float CSOW_TIME_IDLE							= 60.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 4.6;
const float CSOW_SPREAD_JUMPING				= 1.3;
const float CSOW_SPREAD_RUNNING				= 0.175;
const float CSOW_SPREAD_WALKING				= 0.175;
const float CSOW_SPREAD_STANDING			= 0.1;
const float CSOW_SPREAD_DUCKING				= 0.08;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_SHELL_ORIGIN_L			= Vector(20.0, -12.0, -4.0); //forward, right, up
const Vector CSOW_SHELL_ORIGIN_R			= Vector(20.0, 12.0, -4.0); //forward, right, up

const string CSOW_ANIMEXT							= "uzis"; //dualpistols

const string MODEL_VIEW								= "models/custom_weapons/cso/v_elite.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_elite.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_elite.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/pshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_LEFTEMPTY,
	ANIM_SHOOT_LEFT1,
	ANIM_SHOOT_LEFT2,
	ANIM_SHOOT_LEFT3,
	ANIM_SHOOT_LEFT4,
	ANIM_SHOOT_LEFT5,
	ANIM_SHOOT_LEFTLAST,
	ANIM_SHOOT_RIGHT1,
	ANIM_SHOOT_RIGHT2,
	ANIM_SHOOT_RIGHT3,
	ANIM_SHOOT_RIGHT4,
	ANIM_SHOOT_RIGHT5,
	ANIM_SHOOT_RIGHTLAST,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/elite_fire.wav",
	"custom_weapons/cso/elite_clipout.wav",
	"custom_weapons/cso/elite_deploy.wav",
	"custom_weapons/cso/elite_leftclipin.wav",
	"custom_weapons/cso/elite_reloadstart.wav",
	"custom_weapons/cso/elite_rightclipin.wav",
	"custom_weapons/cso/elite_sliderelease.wav",
	"custom_weapons/cso/elite_twirl.wav"
};

const int STATE_LEFT = 1;

class weapon_elites : CBaseCSOWeapon
{
	private float m_flAccuracy;
	private float m_flLastFire;
	private int m_iWeaponState;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;
		m_flAccuracy = 0.88;

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud14.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud15.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::ELITES_SLOT - 1;
		info.iPosition		= cso::ELITES_POSITION - 1;
		info.iWeight			= cso::ELITES_WEIGHT;

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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			m_flAccuracy = 0.88;

			if( (self.m_iClip % 2) != 0 )
				m_iWeaponState = STATE_LEFT;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		ELITEFire( (GetWeaponSpread()) * (1 - m_flAccuracy), CSOW_TIME_DELAY );
	}

	void ELITEFire( float flSpread, float flCycleTime )
	{
		flCycleTime -= 0.125;

		if( (m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) and self.m_flNextPrimaryAttack <= g_Engine.time ) //Makes the gun semi-automatic
			return;

		if( m_flLastFire > 0.0 )
		{
			m_flAccuracy -= (0.325 - (g_Engine.time - m_flLastFire)) * 0.275;

			if( m_flAccuracy > 0.88 )
				m_flAccuracy = 0.88;
			else if( m_flAccuracy < 0.55 )
				m_flAccuracy = 0.55;
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

		HandleAmmoReduction( 1 );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 1;

		if( m_iWeaponState == STATE_LEFT )
		{
			m_pPlayer.m_szAnimExtension = "uzis_right";
			m_iWeaponState = 0;

			FireBullets3( m_pPlayer.GetGunPosition() - g_Engine.v_right * 5, g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_9MM, CSOW_TRACERFREQ, flDamage, 0.75, CSOF_ALWAYSDECAL );
			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN_R.x + g_Engine.v_right * CSOW_SHELL_ORIGIN_R.y + g_Engine.v_up * CSOW_SHELL_ORIGIN_R.z, m_iShell );
		}
		else
		{
			m_pPlayer.m_szAnimExtension = "uzis_left";
			m_iWeaponState = STATE_LEFT;

			FireBullets3( m_pPlayer.GetGunPosition() - g_Engine.v_right * 5, g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_9MM, CSOW_TRACERFREQ, flDamage, 0.75, CSOF_ALWAYSDECAL );
			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN_L.x + g_Engine.v_right * CSOW_SHELL_ORIGIN_L.y + g_Engine.v_up * CSOW_SHELL_ORIGIN_L.z, m_iShell, TE_BOUNCE_SHELL, false );
		}

		int iAnim;

		if( self.m_iClip <= 0 )
			iAnim = ANIM_SHOOT_RIGHTLAST;
		else if( self.m_iClip == 1 )
			iAnim = ANIM_SHOOT_LEFTLAST;
		else
		{
			iAnim = (self.m_iClip % 2) != 0 ? ANIM_SHOOT_LEFT1 : ANIM_SHOOT_RIGHT1;
			iAnim += Math.RandomLong( 0, 4 );
		}

		self.SendWeaponAnim( iAnim, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		self.m_flTimeWeaponIdle = g_Engine.time + 0.2;
		m_pPlayer.pev.punchangle.x -= 2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( Math.RandomLong(0, 1) == 1 )
			m_pPlayer.m_szAnimExtension = "uzis_right";
		else
			m_pPlayer.m_szAnimExtension = "uzis_left";

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD-0.2, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;
		m_flAccuracy = 0.88;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		m_flLastFire = 0.0;
		m_pPlayer.m_szAnimExtension = "uzis";

		if( self.m_iClip > 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;

			if( self.m_iClip == 1 )
				self.SendWeaponAnim( ANIM_IDLE_LEFTEMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			else
				self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_elites::weapon_elites", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "9mm", "", "ammo_9mmclip" );
}

} //namespace cso_elites END