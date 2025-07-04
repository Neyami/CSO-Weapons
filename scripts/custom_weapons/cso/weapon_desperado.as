namespace cso_desperado
{

const bool USE_PENETRATION					= true;
const bool USE_INFINITE_AMMO				= true; //The original has infinite ammo

const int CSOW_DEFAULT_GIVE				= 7;
const int CSOW_MAX_CLIP 					= 7;
const int CSOW_MAX_AMMO					= 999;
const int CSOW_TRACERFREQ					= 0;
const float CSOW_DAMAGE						= 35;
const float CSOW_TIME_DELAY				= 0.12;
const float CSOW_TIME_DRAW				= 0.2f;
const float CSOW_TIME_IDLE					= 3.0;
const float CSOW_TIME_IDLE_RUN			= 0.6;
const float CSOW_TIME_FIRE_TO_IDLE	= 0.6;
const float CSOW_TIME_RELOAD				= 0.7;
const float CSOW_TIME_SWAP				= 0.2;
const float CSOW_SPREAD_JUMPING		= 0.20;
const float CSOW_SPREAD_RUNNING		= 0.15;
const float CSOW_SPREAD_WALKING		= 0.1;
const float CSOW_SPREAD_STANDING		= 0.05;
const float CSOW_SPREAD_DUCKING		= 0.02;

const string CSOW_ANIMEXT					= "onehanded";

const string MODEL_VIEW						= "models/custom_weapons/cso/desperado/v_desperado.mdl";
const string MODEL_PLAYER_R				= "models/custom_weapons/cso/desperado/p_desperado_m.mdl";
const string MODEL_PLAYER_L				= "models/custom_weapons/cso/desperado/p_desperado_w.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/desperado/w_desperado.mdl";

const float CSOW_FRAMERATE_SHOOT	= 30.0; //0.0333

enum csow_e
{
	ANIM_IDLE_R = 0,
	ANIM_RUN_START_R,
	ANIM_RUN_IDLE_R,
	ANIM_RUN_END_R,
	ANIM_DRAW_R,
	ANIM_SHOOT_R,
	ANIM_RELOAD_R,
	ANIM_SWAP_R,
	ANIM_IDLE_L,
	ANIM_RUN_START_L,
	ANIM_RUN_IDLE_L,
	ANIM_RUN_END_L,
	ANIM_DRAW_L,
	ANIM_SHOOT_L,
	ANIM_RELOAD_L,
	ANIM_SWAP_L
};

enum csowsounds_e
{
	SND_SHOOT = 1
};

enum modes_e
{
	MODE_RIGHT = 0,
	MODE_LEFT = 8 //The left-hand animations are all 8 ahead of the right-hand ones
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav", //only here for the precache
	"custom_weapons/cso/dprd-1.wav",
	"custom_weapons/cso/dprd_reload_m.wav"
};

class weapon_desperado : CBaseCSOWeapon
{
	private uint8 m_iMode;
	private uint8 m_iInRun;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;
		
		m_iMode = MODE_RIGHT;
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

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_R );
		g_Game.PrecacheModel( MODEL_PLAYER_L );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( cso::SPRITE_HITMARKER );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash59.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash60.spr" );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_desperado.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud164.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud18.spr" );
		//g_Game.PrecacheGeneric( "events/cso/muzzle_desperado_m.txt" );
		//g_Game.PrecacheGeneric( "events/cso/muzzle_desperado_w.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::DESPERADO_SLOT - 1;
		info.iPosition		= cso::DESPERADO_POSITION - 1;
		info.iWeight			= cso::DESPERADO_WEIGHT;
		info.iFlags			= ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;
		if( USE_INFINITE_AMMO )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 999 );

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_desperado") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			FastReload();
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model((m_iMode == MODE_RIGHT ? MODEL_PLAYER_R : MODEL_PLAYER_L)), ANIM_DRAW_R + m_iMode, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		SetThink(null);
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_iMode == MODE_RIGHT )
			Fire( GetWeaponSpread() );
		else if( m_iMode == MODE_LEFT )
		{
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_SWAP;
			self.SendWeaponAnim( ANIM_SWAP_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_iMode = MODE_RIGHT;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_R;
			FastReload();			
		}
	}

	void SecondaryAttack()
	{
		if( m_iMode == MODE_RIGHT )
		{
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_SWAP;
			self.SendWeaponAnim( ANIM_SWAP_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_iMode = MODE_LEFT;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_L;
			FastReload();
		}
		else if( m_iMode == MODE_LEFT )
			Fire( GetWeaponSpread() );
	}

	void Fire( float flSpread )
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY;
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1, ATTN_NORM );

		self.SendWeaponAnim( ANIM_SHOOT_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		int iPenetration = USE_PENETRATION ? 2 : 1;
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_44MAG, CSOW_TRACERFREQ, flDamage, 5, (CSOF_ALWAYSDECAL | CSOF_HITMARKER) );

		HandleAmmoReduction( 1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;

		SetThink( ThinkFunction(this.MuzzleflashThink) );
		pev.nextthink = g_Engine.time + ((1 / CSOW_FRAMERATE_SHOOT) * 2); //on the 3rd frame
	}

	void Reload()
	{
		if( self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 ) return;

		if( !USE_INFINITE_AMMO )
		{
			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
				return;

			SetThink( null );
			self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD_R + m_iMode, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

			BaseClass.Reload();
		}
		else
		{
			SetThink( null );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_RELOAD;

			self.SendWeaponAnim( ANIM_RELOAD_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_fInReload = true;
			self.m_flTimeWeaponIdle = g_Engine.time + 3;

			while( self.m_iClip < CSOW_MAX_CLIP )
			{
				if( self.m_iClip >= CSOW_MAX_CLIP ) break;
				++self.m_iClip;
			}

			BaseClass.Reload();
		}
	}

	void FastReload()
	{
		if( !USE_INFINITE_AMMO )
		{
			int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

			if( ammo <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
				return;

			while( ammo > 0 )
			{
				if( self.m_iClip >= CSOW_MAX_CLIP ) break;

				--ammo;
				++self.m_iClip;
			}

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
		}
		else
		{
			if( self.m_iClip >= CSOW_MAX_CLIP ) return;

			while( self.m_iClip < CSOW_MAX_CLIP )
			{
				if( self.m_iClip >= CSOW_MAX_CLIP ) break;
				++self.m_iClip;
			}
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iInRun != 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE_RUN;
			self.SendWeaponAnim( ANIM_RUN_END_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_iInRun = 0;
		}
		else
		{
			self.SendWeaponAnim( ANIM_IDLE_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
		}
	}

	void ItemPreFrame()
	{
		if( IsRunning() )
		{
			if( m_iInRun == 0 )
			{
				self.SendWeaponAnim( ANIM_RUN_START_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				m_iInRun = 1;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.3; //CSOW_TIME_IDLE_RUN
			}
			else if( m_iInRun == 1 )
			{
				if( self.m_flTimeWeaponIdle < g_Engine.time )
				{
					self.SendWeaponAnim( ANIM_RUN_IDLE_R + m_iMode, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE_RUN;
				}
			}
		}

		BaseClass.ItemPreFrame();
	}

	bool IsRunning()
	{
		return( (m_pPlayer.pev.button & IN_FORWARD) != 0 and (m_pPlayer.pev.button & (IN_ATTACK|IN_ATTACK2)) == 0 and (m_pPlayer.pev.flags & FL_DUCKING) == 0 );
	}

	void MuzzleflashThink()
	{
		if( m_iMode == MODE_RIGHT )
			MuzzleflashCSO( 1, "#I60 S0.09 R2.5 F0 P90 T0.15 A1 L0 O1 X0" );
		else
			MuzzleflashCSO( 3, "#I59 S0.088 R2.5 F0 P90 T0.15 A1 L0 O1 X2" );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_desperado::weapon_desperado", "weapon_desperado" );
	g_ItemRegistry.RegisterWeapon( "weapon_desperado", "custom_weapons/cso", "44FD" ); //.44 Fast Draw

	//if( !g_CustomEntityFuncs.IsCustomEntity( "cso_buffhit" ) ) 
		//cso::RegisterBuffHit();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_desperado END