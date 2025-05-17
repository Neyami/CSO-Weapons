namespace cso_usas12
{

const string CSOW_NAME								= "weapon_usas12";

const int CSOW_DEFAULT_GIVE						= 20;
const int CSOW_MAX_CLIP 								= 20;
const int CSOW_MAX_AMMO							= 40;
const int CSOW_TRACERFREQ							= 0;
const int CSOW_PELLETCOUNT						= 6; //??
const float CSOW_DAMAGE								= (60/CSOW_PELLETCOUNT);
const float CSOW_TIME_DELAY						= 0.35;
const float CSOW_TIME_DRAW						= 1.4;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 4.5;
const Vector CSOW_OFFSETS_SHELL				= Vector( 10.592894, -5.715073, -4.249912 ); //forward, right, up
const Vector CSOW_VECTOR_SPREAD				= Vector( 0.0725, 0.0725, 0.0 );

const string CSOW_ANIMEXT							= "mp5"; //m249

const string MODEL_VIEW								= "models/custom_weapons/cso/v_usas.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_usas.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_usas.mdl";
const string MODEL_SHELL								= "models/shotgunshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/usas-1.wav",
	"custom_weapons/cso/usas_draw.wav",
	"custom_weapons/cso/usas_foley1.wav",
	"custom_weapons/cso/usas_foley2.wav",
	"custom_weapons/cso/usas_foley3.wav"
};

class weapon_usas12 : CBaseCSOWeapon
{
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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud26.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash2.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash4.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_usas12_1.txt" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_usas12_2.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::USAS12_SLOT - 1;
		info.iPosition		= cso::USAS12_POSITION - 1;
		info.iWeight			= cso::USAS12_WEIGHT;

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
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (CSOW_TIME_DRAW-0.3);
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
			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPelletCount = CSOW_PELLETCOUNT;
		m_pPlayer.FireBullets( iPelletCount, m_pPlayer.GetGunPosition(), g_Engine.v_forward, CSOW_VECTOR_SPREAD, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, CSOW_TRACERFREQ, 0 );
		cso::CreateShotgunPelletDecals( m_pPlayer, m_pPlayer.GetGunPosition(), g_Engine.v_forward, CSOW_VECTOR_SPREAD, iPelletCount, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, TE_BOUNCE_SHOTSHELL, false, true );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		if( (m_pPlayer.pev.flags & FL_ONGROUND) != 0 )
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 3.6, 5.4 );
		else
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 7.2, 9.9 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD-0.7, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + 20;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_usas12::weapon_usas12", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "buckshot", "", "ammo_buckshot" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_usas12 END