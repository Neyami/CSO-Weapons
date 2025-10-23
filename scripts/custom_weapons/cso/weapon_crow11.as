namespace cso_crow11
{

const string CSOW_NAME								= "weapon_crow11";

const int CSOW_DEFAULT_GIVE						= 20;
const int CSOW_MAX_CLIP 							= 20;
const int CSOW_MAX_AMMO							= 40;
const int CSOW_TRACERFREQ							= 0;
const int CSOW_PELLETCOUNT						= 6; //??
const float CSOW_DAMAGE								= (52 / CSOW_PELLETCOUNT);
const float CSOW_TIME_DELAY						= 0.32;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_DRAW_TO_FIRE			= 0.75; //TODO
const float CSOW_TIME_DRAW_TO_IDLE			= 1.5; //TODO
const float CSOW_TIME_IDLE							= 2.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0; //TODO
const float CSOW_TIME_RELOAD1					= 3.5; //normal
const float CSOW_TIME_RELOAD2					= 2.5; //quick
const float CSOW_TIME_RELOAD_PRE				= 0.74; //time before quick reload becomes available after hitting the reload-key the first time
const float CSOW_TIME_RELOAD_WINDOW		= 0.25; //the time between when quick reload becomes available and the normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_NORM	= 2.21; //reload time after normal reload is automatically chosen
const float CSOW_TIME_RELOAD_END_QUICK	= 1.21; //reload time after quick reload has been activated
const Vector CSOW_OFFSETS_SHELL				= Vector( 10.592894, -5.715073, -4.249912 ); //forward, right, up
const Vector CSOW_VECTOR_SPREAD				= Vector( 0.0625, 0.0625, 0.0 );

const string CSOW_ANIMEXT							= "mp5";
const string CSOW_ANIMEXT_CSO					= "m249";

const string MODEL_VIEW								= "models/custom_weapons/cso/crow11/v_crow11.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/crow11/p_crow11.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/crow11/w_crow11.mdl";
const string MODEL_SHELL								= "models/shotgunshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD_START,
	ANIM_RELOAD_END_QUICK,
	ANIM_RELOAD_END_NORMAL
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/crow11-1.wav",
	"custom_weapons/cso/crow11_draw.wav",
	"custom_weapons/cso/crow11_reload_a.wav",
	"custom_weapons/cso/crow11_reload_b1.wav",
	"custom_weapons/cso/crow11_reload_b2.wav",
	"custom_weapons/cso/crow11_reload_in.wav"
};

class weapon_crow11 : CBaseCSOWeapon, CSOCrowSeries
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iWeaponType = TYPE_PRIMARY;

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
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash4.spr" );

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud149.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::CROW11_SLOT - 1;
		info.iPosition			= cso::CROW11_POSITION - 1;
		info.iWeight			= cso::CROW11_WEIGHT;

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
		return CSODeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, PlayerHasCSOModel() ? CSOW_ANIMEXT_CSO : CSOW_ANIMEXT, CSOW_TIME_DRAW_TO_FIRE, CSOW_TIME_DRAW_TO_IDLE );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		if( brandom() )
		{
			//{ event 5001 0 "#I1 S0.25 R1 F0 P30 T0.01 A1 L0 O0" } 
			MuzzleflashCSO( 1, "#I4 S0.25 R1 F0 P30 T0.01 A1 L0 O0" );
		}
		else
		{
			//{ event 5001 0 "#I2 S0.25 R1 F0 P30 T0.01 A1 L0 O0" } 
			MuzzleflashCSO( 1, "#I2 S0.25 R1 F0 P30 T0.01 A1 L0 O0" );
		}

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( CSOW_PELLETCOUNT, m_pPlayer.GetGunPosition(), g_Engine.v_forward, CSOW_VECTOR_SPREAD, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, CSOW_TRACERFREQ, 0 );
		cso::CreateShotgunPelletDecals( m_pPlayer, m_pPlayer.GetGunPosition(), g_Engine.v_forward, CSOW_VECTOR_SPREAD, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false, TE_BOUNCE_SHOTSHELL, true );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		if( (m_pPlayer.pev.flags & FL_ONGROUND) != 0 )
		{
			if( (m_pPlayer.pev.flags & FL_DUCKING != 0) )
				m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 1.5, 2.5 );
			else
				m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 3.0, 5.0 );
		}
		else
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 7.2, 9.9 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + 20;
	}
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crow11::weapon_crow11", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "crow11ammo" ); //buckshot
}

} //namespace cso_crow11 END