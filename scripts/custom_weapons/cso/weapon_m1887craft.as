namespace cso_m1887craft
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_m1887craft";

const int CSOW_DEFAULT_GIVE						= 6;
const int CSOW_MAX_CLIP 								= 6;
const int CSOW_MAX_AMMO							= 32;
const int CSOW_TRACERFREQ							= 0;
const int CSOW_PELLETCOUNT						= 8;
const float CSOW_DAMAGE								= (76/CSOW_PELLETCOUNT);
const float CSOW_TIME_DELAY						= 0.76475;
const float CSOW_TIME_DRAW						= 1.0;
const Vector CSOW_OFFSETS_SHELL				= Vector( 9.267645, 5.626740, -2.025541 ); //forward, right, up
const Vector CSOW_VECTOR_SPREAD				= Vector( 0.0675, 0.0675, 0 );

const string CSOW_ANIMEXT							= "onehanded";

const string MODEL_VIEW								= "models/custom_weapons/cso/v_m1887craft.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_m1887craft.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_m1887craft.mdl";
const string MODEL_SHELL								= "models/shotgunshell.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_SHOOT4,
	ANIM_SHOOT5,
	ANIM_RELOAD_INSERT,
	ANIM_RELOAD_END,
	ANIM_RELOAD_START,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT1,
	SND_SHOOT2
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/m1887craft-1.wav",
	"custom_weapons/cso/m1887craft-2.wav",
	"custom_weapons/cso/m1887craft_after_reload.wav",
	"custom_weapons/cso/m1887craft_draw.wav",
	"custom_weapons/cso/m1887craft_insert.wav",
	"custom_weapons/cso/m1887craft_start_reload.wav"
};

class weapon_m1887craft : CBaseCSOWeapon
{
	private int m_iInSpecialReload;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud12.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud108.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::M1887CRAFT_SLOT - 1;
		info.iPosition		= cso::M1887CRAFT_POSITION - 1;
		info.iWeight			= cso::M1887CRAFT_WEIGHT;

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
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (CSOW_TIME_DRAW-0.3);
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW*2)));

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_bPlayEmptySound = true;
			PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			Reload();

			if( self.m_iClip == 0 )
			{
				self.m_bPlayEmptySound = true;
				PlayEmptySound();
			}

			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( CSOW_PELLETCOUNT, m_pPlayer.GetGunPosition(), g_Engine.v_forward, CSOW_VECTOR_SPREAD, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, CSOW_TRACERFREQ, 0 );
		cso::CreateShotgunPelletDecals( m_pPlayer, m_pPlayer.GetGunPosition(), g_Engine.v_forward, CSOW_VECTOR_SPREAD, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB) );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT5), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT2)], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x + g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, TE_BOUNCE_SHOTSHELL, false, true );
		HandleAmmoReduction( 1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;

		if( self.m_iClip > 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 2.5;
		else
			self.m_flTimeWeaponIdle = CSOW_TIME_DELAY;

		m_iInSpecialReload = 0;

		if( m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 3.1152, 4.6728 );
		else
			m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, 6.2304, 8.5668 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
			return;

		if( self.m_flNextPrimaryAttack > g_Engine.time )
			return;

		if( m_iInSpecialReload == 0 )
		{
			self.SendWeaponAnim( ANIM_RELOAD_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			m_iInSpecialReload = 1;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.55;
		}
		else if( m_iInSpecialReload == 1 )
		{
			if( self.m_flTimeWeaponIdle > g_Engine.time )
				return;

			m_iInSpecialReload = 2;
			self.SendWeaponAnim( ANIM_RELOAD_INSERT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			self.m_flTimeWeaponIdle = g_Engine.time + 0.45;
		}
		else
		{
			m_pPlayer.SetAnimation( PLAYER_RELOAD );
			self.m_iClip++;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
			m_iInSpecialReload = 1;
		}
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 and m_iInSpecialReload == 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
				Reload();
			else if( m_iInSpecialReload != 0 )
			{
				if( self.m_iClip != CSOW_MAX_CLIP and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
					Reload();
				else
				{
					self.SendWeaponAnim( ANIM_RELOAD_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

					m_iInSpecialReload = 0;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
				}
			}
			else
				self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m1887craft::weapon_m1887craft", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "buckshot", "", "ammo_buckshot" );
}

} //namespace cso_m1887craft END