namespace cso_crow7
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_crow7";

const int CSOW_DEFAULT_GIVE						= 100;
const int CSOW_MAX_CLIP 							= 100;
const int CSOW_MAX_AMMO							= 200;
const int CSOW_TRACERFREQ							= 4;
const float CSOW_DAMAGE								= 25;
const float CSOW_TIME_DELAY1						= 0.0955;
const float CSOW_TIME_DELAY2						= 0.2;
const float CSOW_TIME_DELAY_ZOOM				= 0.3;
const float CSOW_TIME_DRAW						= 1.5;
const float CSOW_TIME_IDLE							= 4.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD1					= 4.5; //normal
const float CSOW_TIME_RELOAD2					= 3.0; //quick
const float CSOW_TIME_RELOAD_PRE				= 1.3; //time before quick reload becomes available after hitting the reload-key the first time
const float CSOW_TIME_RELOAD_WINDOW		= 0.25; //the time between when quick reload becomes available and the normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_NORM	= 2.9; //reload time after normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_QUICK	= 1.65; //reload time after quick reload has been activated
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.15;
const float CSOW_SPREAD_WALKING				= 0.1;
const float CSOW_SPREAD_STANDING				= 0.06;
const float CSOW_SPREAD_DUCKING				= 0.04;
const float CSOW_SPREAD_ZOOM_MULT			= 0.72;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -2.0);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D(-0.25, -1.0);
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D(0, 0);
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 29.687382, 4.924402, -3.247410 ); //Vector( 30.082214, 6.318542, -3.830643 );
const Vector CSOW_OFFSETS_SHELL				=	Vector( 11.989824, -4.633915, -4.102987 ); //Vector( 17.0, -8.0, -4.0 ); //forward, right, up
const int CSOW_ZOOM_FOV							= 40;

const string CSOW_ANIMEXT							= "mp5";
const string CSOW_ANIMEXT_CSO					= "m249";

const string MODEL_VIEW								= "models/custom_weapons/cso/crow7/v_crow7.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/crow7/p_crow7.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/crow7/w_crow7.mdl";
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

const array<string> arrsCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",  //only here for the precache
	"custom_weapons/cso/crow7/crow7-1.wav",
	"custom_weapons/cso/crow7/crow7_beep.wav",
	"custom_weapons/cso/crow7/crow7_draw.wav",
	"custom_weapons/cso/crow7/crow7_reload_in.wav",
	"custom_weapons/cso/crow7/crow7_reloada.wav",
	"custom_weapons/cso/crow7/crow7_reloadb_boltpull.wav",
	"custom_weapons/cso/crow7/crow7_reloadb_clipin.wav",
	"custom_weapons/cso/crow7/crow7_reloadb_clipout.wav"
};

class weapon_crow7 : CBaseCSOWeapon, CSOCrowSeries
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

		m_iWeaponType = TYPE_PRIMARY;
		m_sEmptySound = arrsCSOWSounds[0];

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

		for( uint i = 0; i < arrsCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < arrsCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + arrsCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud138.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash3.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash4.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_crow7-1.txt" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_crow7-2.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::CROW7_SLOT - 1;
		info.iPosition			= cso::CROW7_POSITION - 1;
		info.iWeight			= cso::CROW7_WEIGHT;

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

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0; 
		float flSpreadMultiplier = (m_pPlayer.m_iFOV == 0) ? 1.0 : CSOW_SPREAD_ZOOM_MULT;
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread() * flSpreadMultiplier, iPenetration, BULLET_PLAYER_556MM, CSOW_TRACERFREQ, flDamage, 1.0, CSOF_ALWAYSDECAL, CSOW_OFFSETS_MUZZLE );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell );

		if( m_pPlayer.m_iFOV != 0 )
		{
			HandleRecoil( CSOW_RECOIL_STANDING_X*CSOW_SPREAD_ZOOM_MULT, CSOW_RECOIL_STANDING_Y*CSOW_SPREAD_ZOOM_MULT, CSOW_RECOIL_DUCKING_X*CSOW_SPREAD_ZOOM_MULT, CSOW_RECOIL_DUCKING_Y*CSOW_SPREAD_ZOOM_MULT );
			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
		}
		else
		{
			HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );
			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
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
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crow7::weapon_crow7", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "crow7ammo" ); //556
}

} //namespace cso_crow7 END