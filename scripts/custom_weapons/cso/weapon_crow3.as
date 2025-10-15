namespace cso_crow3
{
const int CSOW_DEFAULT_GIVE						= 64;
const int CSOW_MAX_CLIP 							= 64;
const int CSOW_MAX_AMMO							= 120;
const float CSOW_DAMAGE								= 14;
const float CSOW_TIME_DELAY						= 0.087;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 3.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 0.5;
const float CSOW_TIME_RELOAD1					= 3.0;
const float CSOW_TIME_RELOAD2					= 2.0;
const float CSOW_TIME_RELOAD_PRE				= 0.6; //time before quick reload becomes available after hitting the reload-key the first time
const float CSOW_TIME_RELOAD_WINDOW		= 0.4; //the time between when quick reload becomes available and the normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_NORM	= 2.0; //reload time after normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_QUICK	= 1.0; //reload time after quick reload has been activated
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, 1);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D(0, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D(0, 0);
const Vector CSOW_CONE_STANDING				= VECTOR_CONE_2DEGREES;
const Vector CSOW_CONE_CROUCHING			= VECTOR_CONE_1DEGREES;

const string CSOW_ANIMEXT							= "mp5";

const string MODEL_VIEW								= "models/custom_weapons/cso/crow3/v_crow3.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/crow3/p_crow3.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/crow3/w_crow3.mdl";

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
	"custom_weapons/cs16/dryfire_pistol.wav", //only here for the precache
	"custom_weapons/cso/crow3-1.wav",
	"custom_weapons/cso/crow3_draw.wav",
	"custom_weapons/cso/crow3_reload_a.wav",
	"custom_weapons/cso/crow3_reload_b.wav",
	"custom_weapons/cso/crow3_reload_boltpull.wav",
	"custom_weapons/cso/crow3_reload_in.wav"
};

class weapon_crow3 : CBaseCSOWeapon, CSOCrowSeries
{
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		m_iReloadState = STATE_NONE;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash2.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash17.spr" );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_crow3.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud156.spr" );
		//g_Game.PrecacheGeneric( "events/cso/muzzle_crow31.txt" );
		//g_Game.PrecacheGeneric( "events/cso/muzzle_crow32.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= cso::CROW3_SLOT - 1;
		info.iPosition		= cso::CROW3_POSITION - 1;
		info.iWeight		= cso::CROW3_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_crow3") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true; //without this, PlayEmptySound only plays once
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		HandleAmmoReduction( 1 );
		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		if( Math.RandomLong(1, 2) == 1 )
		{
			self.SendWeaponAnim( ANIM_SHOOT1 );
			//{ event 5001 0 "#I17 S0.12 R2 F0 P30 T0.01 A1 L0 O0" }
			MuzzleflashCSO( 1, "#I17 S0.12 R2 F0 P30 T0.01 A1 L0 O0" );
		}
		else
		{
			self.SendWeaponAnim( ANIM_SHOOT2 );
			//{ event 5001 0 "#I2 S0.22 R1 F0 P30 T0.01 A1 L0 O0" } 
			MuzzleflashCSO( 1, "#I2 S0.22 R1 F0 P30 T0.01 A1 L0 O0" );
		}

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH; //Needed??

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;
		Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE_CROUCHING : CSOW_CONE_STANDING;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, CSOW_DAMAGE );
		DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_MP5, true );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crow3::weapon_crow3", "weapon_crow3" );
	g_ItemRegistry.RegisterWeapon( "weapon_crow3", "custom_weapons/cso", "9mm", "", "ammo_9mmAR" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_crow3 END

/*
TODO
Somehow fix the quick-reload indicator and the eyes in the v_model (not possible in svencoop?)
Make use of the default Reload function somehow?
*/