namespace cso_m95
{

const int CSOW_DEFAULT_GIVE					= 5;
const int CSOW_MAX_CLIP 						= 5;
const int CSOW_MAX_AMMO						= 50;
const float CSOW_DAMAGE						= 280; //145
const float CSOW_TIME_DELAY1					= 1.47;
const float CSOW_TIME_DELAY2					= 0.3;
const float CSOW_TIME_DRAW					= 1.45;
const float CSOW_TIME_IDLE						= 60.0;
const float CSOW_TIME_RELOAD				= 4.0;
const float CSOW_RECOIL							= 4.0;
const Vector CSOW_SHELL_ORIGIN				= Vector(16.0, 9.0, -9.0); //forward, right, up

const string CSOW_ANIMEXT						= "sniper"; //rifle

const string MODEL_VIEW							= "models/custom_weapons/cso/v_m95.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_m95.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_m95.mdl";
const string MODEL_SHELL							= "models/custom_weapons/cso/rshell_big.mdl";

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
	SND_EMPTY = 0,
	SND_ZOOM,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/zoom.wav",
	"custom_weapons/cso/m95-1.wav",
	"custom_weapons/cso/m95_boltpull.wav",
	"custom_weapons/cso/m95_clipin.wav",
	"custom_weapons/cso/m95_clipout.wav"
};

class weapon_m95 : CBaseCSOWeapon
{
	private bool m_bResumeZoom;
	private int m_iLastZoom;
	private float m_flEjectBrass;

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_m95.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud53.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/sniper_scope.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash4.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= cso::M95_SLOT - 1;
		info.iPosition		= cso::M95_POSITION - 1;
		info.iWeight		= cso::M95_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_m95") );
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

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		m_flEjectBrass = 0.0;

		BaseClass.Holster( skiplocal );
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

			m_bResumeZoom = false;
			m_iLastZoom = 0;

			return bResult;
		}
	}
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			M95Fire( 0.85, CSOW_TIME_DELAY1 );
		else if( m_pPlayer.pev.velocity.Length2D() > 140 )
			M95Fire( 0.25, CSOW_TIME_DELAY1 );
		else if( m_pPlayer.pev.velocity.Length2D() > 10 )
			M95Fire( 0.1, CSOW_TIME_DELAY1 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			M95Fire( 0.0, CSOW_TIME_DELAY1 );
		else
			M95Fire( 0.001, CSOW_TIME_DELAY1 );
	}

	void M95Fire( float flSpread, float flCycleTime )
	{
		if( m_pPlayer.pev.fov != 0 )
		{
			m_bResumeZoom = true;
			m_iLastZoom = m_pPlayer.m_iFOV;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		}
		else
			flCycleTime += 0.08;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		m_flEjectBrass = g_Engine.time + 0.55;
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		Vector vecSrc = m_pPlayer.GetGunPosition();
		cso::FireBullets3( vecSrc, g_Engine.v_forward, flSpread, 8192, 20, BULLET_PLAYER_338MAG, flDamage, 5, EHandle(m_pPlayer), m_pPlayer.random_seed, CSOF_ALWAYSDECAL );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction();

		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		m_pPlayer.pev.punchangle.x -= CSOW_RECOIL;
	}

	void SecondaryAttack()
	{
		switch( m_pPlayer.m_iFOV )
		{
			case 0: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40; m_pPlayer.m_szAnimExtension = "sniperscope"; break;
			case 40: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10; break;
			default: m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; m_pPlayer.m_szAnimExtension = "sniper"; break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_ZOOM], 0.2, 2.4 );
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or m_flEjectBrass > 0.0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10;
			SecondaryAttack();
		}

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

		if( self.m_iClip > 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
			self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}

	void ItemPostFrame()
	{
		if( self.m_flNextPrimaryAttack <= g_Engine.time )
		{
			if( m_bResumeZoom )
			{
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = m_iLastZoom;

				if( m_pPlayer.m_iFOV == m_iLastZoom )
					m_bResumeZoom = false;
			}
		}

		if( m_flEjectBrass > 0.0 and m_flEjectBrass < g_Engine.time )
		{
			m_flEjectBrass = 0.0;
			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false, true );
		}

		BaseClass.ItemPostFrame();
	}

	/*float GetMaxSpeed()
	{
		if( m_pPlayer.m_iFOV == 0 )
			return 210;

		return 150;
	}*/
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m95::weapon_m95", "weapon_m95" );
	g_ItemRegistry.RegisterWeapon( "weapon_m95", "custom_weapons/cso", "50bmg", "", "ammo_50bmg" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_50bmg" ) ) 
		cso::Register50BMG();
}

} //namespace cso_m95 END