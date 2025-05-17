//based on Dias Pendragon Leon's [CSO] Salamander 2015

namespace cso_salamander
{

const string CSOW_NAME								= "weapon_salamander";

const int CSOW_DEFAULT_GIVE						= 100;
const int CSOW_MAX_CLIP 							= 100;
const int CSOW_MAX_AMMO							= 200;
const float CSOW_DAMAGE								= 38;
const float CSOW_TIME_DELAY_FIRE				= 0.08;
const float CSOW_TIME_DELAY_FIRE_FAST		= 0.001;
const float CSOW_TIME_DELAY_END				= 2.0;
const float CSOW_TIME_DRAW						= 1.23;
const float CSOW_TIME_IDLE							= 9.4375;
const float CSOW_TIME_FIRE_TO_IDLE			= 2.1;
const float CSOW_TIME_RELOAD						= 5.0;
const float CSOW_FLAME_SPEED						= 640.0;

const Vector CSOW_OFFSETS_MUZZLE			= Vector( 30.082214, 6.318542, -3.830643 );

const string CSOW_ANIMEXT							= "egon";

const string MODEL_VIEW								= "models/custom_weapons/cso/v_flamethrower.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_flamethrower.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_flamethrower.mdl";
const string SPRITE_FLAME								= "sprites/custom_weapons/cso/flame_puff01.spr";
const string SPRITE_SMOKE							= "sprites/custom_weapons/cso/smokepuff.spr";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_SHOOT_END,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_SHOOT = 1,
	SND_SHOOT_END
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",  //only here for the precache
	"custom_weapons/cso/flamegun-1.wav",
	"custom_weapons/cso/flamegun-2.wav",
	"custom_weapons/cso/flamegun_clipin1.wav",
	"custom_weapons/cso/flamegun_clipin2.wav",
	"custom_weapons/cso/flamegun_clipout1.wav",
	"custom_weapons/cso/flamegun_clipout2.wav",
	"custom_weapons/cso/flamegun_draw.wav"
};

class weapon_salamander : CBaseCSOWeapon
{
	private bool m_bHasFired, m_bDontAnimate;
	private int m_iFireSound;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iWeaponType = TYPE_PRIMARY;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_Game.PrecacheModel( SPRITE_SMOKE );

		g_Game.PrecacheOther( "csoproj_flame" );
		g_Game.PrecacheOther( "cso_dotent" );

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud59.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud60.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::SALAMANDER_SLOT - 1;
		info.iPosition		= cso::SALAMANDER_POSITION - 1;
		info.iWeight			= cso::SALAMANDER_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW*2)));

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		m_bDontAnimate = false;
		m_bHasFired = false;
		m_iFireSound = 0;

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
			WeaponIdle();

			return;
		}

		FlamethrowerFire( 4 );

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if( !m_bDontAnimate )
		{
			self.SendWeaponAnim( ANIM_SHOOT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_bDontAnimate = true;
		}

		self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY_FIRE;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}

	//TEST
/*
	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.25;
			WeaponIdle();

			return;
		}

		FlamethrowerFire( 64 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if( !m_bDontAnimate )
		{
			self.SendWeaponAnim( ANIM_SHOOT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_bDontAnimate = true;
		}

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY_FIRE_FAST;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}
*/
	void FlamethrowerFire( int iSoundFrequency )
	{
		Vector vecAngles, vecOrigin, vecTargetOrigin, vecVelocity;

		get_position( 40.0, 5.0, -5.0, vecOrigin );
		get_position( 1024.0, 0.0, 0.0, vecTargetOrigin );

		vecAngles = m_pPlayer.pev.angles;

		vecAngles.z = Math.RandomFloat( 0.0, 18.0 ) * 20;

		CBaseEntity@ pFlame = g_EntityFuncs.Create( "csoproj_flame", vecOrigin, vecAngles, false, m_pPlayer.edict() );

		get_speed_vector( vecOrigin, vecTargetOrigin, CSOW_FLAME_SPEED, vecVelocity );
		pFlame.pev.velocity = vecVelocity;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		pFlame.pev.dmg = flDamage;

		g_EntityFuncs.DispatchSpawn( pFlame.edict() );

		m_bHasFired = true;

		if( (m_iFireSound % iSoundFrequency) == 0 )
			g_SoundSystem.EmitSound( pFlame.edict(), CHAN_BODY, pCSOWSounds[SND_SHOOT], 0.5, ATTN_NORM );

		m_iFireSound++;
		if( m_iFireSound >= 1000 ) m_iFireSound = 0;
	}

	void FireSmoke()
	{
		Vector vecOrigin;
		get_position( 40.0, 5.0, -15.0, vecOrigin );

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z);
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
			m1.WriteByte( 5 );
			m1.WriteByte( 30 );
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		m_bDontAnimate = false;
		m_bHasFired = false;
		m_iFireSound = 0;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		m_bDontAnimate = false;
		m_bHasFired = false;
		m_iFireSound = 0;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2)));
	}

	void ItemPreFrame()
	{
		if( m_bHasFired and (m_pPlayer.pev.button & IN_ATTACK) == 0 and (m_pPlayer.pev.oldbuttons & IN_ATTACK) != 0 )
		{
			m_bHasFired = false;
			m_bDontAnimate = false;
			FireSmoke();

			self.SendWeaponAnim( ANIM_SHOOT_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			if( self.m_iClip > 0 )
				self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY_END;
		}

		BaseClass.ItemPreFrame();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::csoproj_flame", "csoproj_flame" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_salamander::weapon_salamander", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "salamanderammo" );

	cso::RegisterDotEnt();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_salamander END