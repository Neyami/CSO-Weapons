namespace cso_crow1
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_crow1";

const int CSOW_DEFAULT_GIVE						= 20;
const int CSOW_MAX_CLIP 							= 20;
const int CSOW_MAX_AMMO							= 120;
const int CSOW_TRACERFREQ							= 1;
const float CSOW_DAMAGE1							= 25;
const float CSOW_DAMAGE2							= 32;
const float CSOW_TIME_DELAY_SEMI				= 0.25;
const float CSOW_TIME_DELAY_AUTO				= 0.1;
const float CSOW_TIME_DRAW						= 0.7;
const float CSOW_TIME_IDLE							= 1.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD1					= 3.3; //normal
const float CSOW_TIME_RELOAD2					= 2.0; //quick
const float CSOW_TIME_RELOAD_PRE				= 0.84; //time before quick reload becomes available after hitting the reload-key the first time
const float CSOW_TIME_RELOAD_WINDOW		= 0.25; //the time between when quick reload becomes available and the normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_NORM	= 2.21; //reload time after normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_QUICK	= 0.65; //reload time after quick reload has been activated
const float CSOW_SPREAD_JUMPING				= 0.6; //1.2
const float CSOW_SPREAD_WALKING				= 0.185;
const float CSOW_SPREAD_STANDING				= 0.15; //0.3
const float CSOW_SPREAD_DUCKING				= 0.095;
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 13.440315, 3.609473, -2.286852 ); //Vector( 30.082214, 6.318542, -3.830643 );
const Vector CSOW_OFFSETS_SHELL				= Vector( 9.440313, -2.709480, -2.286276 ); //Vector( 17.0, -8.0, -4.0 ); //forward, right, up

const string CSOW_ANIMEXT							= "onehanded";

const string MODEL_VIEW								= "models/custom_weapons/cso/crow1/v_crow1.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/crow1/p_crow1.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/crow1/w_crow1.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/pshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_SHOOT_BURST,
	ANIM_SHOOT2,
	ANIM_SHOOT_EMPTY,
	ANIM_RELOAD_START,
	ANIM_RELOAD_END_QUICK,
	ANIM_RELOAD_END_NORMAL
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> arrsCSOWSounds =
{
	"custom_weapons/cso/crow1/crow1_shoot_empty.wav",
	"custom_weapons/cso/crow1/crow1-1.wav",
	"custom_weapons/cso/crow1/crow1_draw.wav",
	"custom_weapons/cso/crow1/crow1_reload_in.wav",
	"custom_weapons/cso/crow1/crow1_reloada_1.wav",
	"custom_weapons/cso/crow1/crow1_reloada_2.wav",
	"custom_weapons/cso/crow1/crow1_reloadb_1.wav",
	"custom_weapons/cso/crow1/crow1_reloadb_2.wav"
};

class weapon_crow1 : CBaseCSOWeapon, CSOCrowSeries
{
	private float m_flAccuracy;
	private float m_flLastFire;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );

		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iWeaponType = TYPE_PRIMARY;
		m_sEmptySound = arrsCSOWSounds[0];

		m_flAccuracy = 0.9;

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud163.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash2.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_crow1.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::CROW1_SLOT - 1;
		info.iPosition			= cso::CROW1_POSITION - 1;
		info.iWeight			= cso::CROW1_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW*2)));

			m_flAccuracy = 0.9;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			CROW1Fire( (CSOW_SPREAD_JUMPING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_SEMI, false );
		else if( m_pPlayer.pev.velocity.Length2D() > 0 )
			CROW1Fire( (CSOW_SPREAD_WALKING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_SEMI, false );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			CROW1Fire( (CSOW_SPREAD_DUCKING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_SEMI, false );
		else
			CROW1Fire( (CSOW_SPREAD_STANDING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_SEMI, false );
	}

	void SecondaryAttack()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			CROW1Fire( (CSOW_SPREAD_JUMPING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_AUTO, true );
		else if( m_pPlayer.pev.velocity.Length2D() > 0 )
			CROW1Fire( (CSOW_SPREAD_WALKING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_AUTO, true );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			CROW1Fire( (CSOW_SPREAD_DUCKING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_AUTO, true );
		else
			CROW1Fire( (CSOW_SPREAD_STANDING) * (1 - m_flAccuracy), CSOW_TIME_DELAY_AUTO, true );
	}

	void CROW1Fire( float flSpread, float flCycleTime, bool bUseAutoMode )
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
			return;
		}

		if( !bUseAutoMode )
		{
			m_iShotsFired++;
			flCycleTime -= 0.05; //??

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
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		float flDamage = CSOW_DAMAGE1;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 1 : 0; 
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, flSpread, 1, BULLET_PLAYER_9MM, CSOW_TRACERFREQ, flDamage, 0.75, CSOF_ALWAYSDECAL, CSOW_OFFSETS_MUZZLE );

		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7 );
		else if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			KickBack( 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			KickBack( 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9 );
		else
			KickBack( 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8 ); 

		int iAnim;
		if( self.m_iClip > 1 )
			iAnim = ANIM_SHOOT2;
		else
			iAnim = ANIM_SHOOT_EMPTY;

		self.SendWeaponAnim( iAnim );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false, TE_BOUNCE_SHELL, true );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + 2.5;
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
		if( !cso::HasFlags(m_pPlayer.pev.button, (IN_ATTACK | IN_ATTACK2)) )
			m_iShotsFired = 0;

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

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crow1::weapon_crow1", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "crow1ammo" ); //9mm
}

} //namespace cso_crow1 END