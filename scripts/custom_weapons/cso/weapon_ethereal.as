namespace cso_ethereal
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_ethereal";

const int CSOW_MAX_CLIP 								= 30;
const float CSOW_DAMAGE								= 25; //25, 54, 83
const float CSOW_TIME_DELAY						= 0.1;
const float CSOW_TIME_DRAW						= 1.3;
const float CSOW_TIME_IDLE							= 10.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 3.1;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.01785;
const float CSOW_SPREAD_WALKING				= 0.01785;
const float CSOW_SPREAD_STANDING			= 0.01718;
const float CSOW_SPREAD_DUCKING				= 0.01289;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -1);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 30.082214, 6.318542, -3.830643 );

const string CSOW_ANIMEXT							= "m16"; //rifle

const string MODEL_VIEW								= "models/custom_weapons/cso/v_ethereal.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_ethereal.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_ethereal.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/ethereal-1.wav",
	"custom_weapons/cso/ethereal_draw.wav",
	"custom_weapons/cso/ethereal_reload.wav"
};

class weapon_ethereal : CBaseCSOWeapon
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = cso::GIVE_ETHER;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud2.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud74.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash19.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_ethereal.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= cso::MAXCARRY_ETHER;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::ETHEREAL_SLOT - 1;
		info.iPosition		= cso::ETHEREAL_POSITION - 1;
		info.iWeight			= cso::ETHEREAL_WEIGHT;

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

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, cso::GIVE_ETHER ); 

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (CSOW_TIME_DRAW-0.7);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
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
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 1.4, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0;
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_556MM, 0, flDamage, 1.0, CSOF_ALWAYSDECAL|CSOF_ETHEREAL, CSOW_OFFSETS_MUZZLE );

		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD + 0.5);

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE + Math.RandomFloat(0, (CSOW_TIME_IDLE*2));
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_ethereal::weapon_ethereal", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "ether", "", "ammo_ether" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_ether" ) ) 
		cso::RegisterEther();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_ethereal END