namespace cso_desperado
{

const int CSOW_DEFAULT_GIVE				= 7;
const int CSOW_MAX_CLIP 					= 7;
const int CSOW_MAX_AMMO					= 999;
const float CSOW_DAMAGE					= 35;
const float CSOW_TIME_DELAY				= 0.12f;
const float CSOW_TIME_DRAW				= 0.2f;
const float CSOW_TIME_IDLE					= 3.0f;
const float CSOW_TIME_IDLE_RUN			= 0.6f;
const float CSOW_TIME_FIRE_TO_IDLE	= 0.6f;
const float CSOW_TIME_RELOAD			= 0.7f;
const float CSOW_TIME_SWAP				= 0.2f;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE						= VECTOR_CONE_2DEGREES;

const string CSOW_ANIMEXT					= "onehanded";

const string MODEL_VIEW						= "models/custom_weapons/cso/v_desperado.mdl";
const string MODEL_PLAYER_R				= "models/custom_weapons/cso/p_desperado_m.mdl";
const string MODEL_PLAYER_L				= "models/custom_weapons/cso/p_desperado_w.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/w_desperado.mdl";

enum csow_e
{
	ANIM_IDLE_M = 0,
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
	SND_EMPTY = 0,
	SND_SHOOT,
	SND_RELOAD
};

enum modes_e
{
	MODE_RIGHT = 0,
	MODE_LEFT = 8 //The left-hand animations are all 8 ahead of the right-hand ones
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/dprd-1.wav",
	"custom_weapons/cso/dprd_reload_m.wav"
};

class weapon_desperado : CBaseCSOWeapon
{
	private uint8 m_iMode;
	private uint8 m_iInRun;
	private bool m_bInfiniteAmmo = true; //The original has infinite ammo

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.FallInit();
		m_iMode = MODE_RIGHT;
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_R );
		g_Game.PrecacheModel( MODEL_PLAYER_L );
		g_Game.PrecacheModel( MODEL_WORLD );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_desperado.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud164.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud18.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash59.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash60.spr" );
		g_Game.PrecacheGeneric( "events/muzzle_desperado_m.txt" );
		g_Game.PrecacheGeneric( "events/muzzle_desperado_w.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= CSO::DESPERADO_SLOT - 1;
		info.iPosition		= CSO::DESPERADO_POSITION - 1;
		info.iWeight		= CSO::DESPERADO_WEIGHT;
		info.iFlags			= ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;
		if( m_bInfiniteAmmo )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, CSOW_MAX_AMMO );

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_desperado") );
		m.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], 1.0f, ATTN_NORM );
		}

		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			FastReload();
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model((m_iMode == MODE_RIGHT ? MODEL_PLAYER_R : MODEL_PLAYER_L)), ANIM_DRAW_R + m_iMode, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

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
			Fire();
		else if( m_iMode == MODE_LEFT )
		{
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_SWAP;
			self.SendWeaponAnim( ANIM_SWAP_R + m_iMode );
			m_iMode = MODE_RIGHT;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_R;
			FastReload();			
		}
	}

	void SecondaryAttack()
	{
		if( m_iMode == MODE_RIGHT )
		{
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_SWAP;
			self.SendWeaponAnim( ANIM_SWAP_R + m_iMode );
			m_iMode = MODE_LEFT;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_L;
			FastReload();
		}
		else if( m_iMode == MODE_LEFT )
			Fire();
	}

	void Fire()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1, ATTN_NORM );

		self.SendWeaponAnim( ANIM_SHOOT_R + m_iMode );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, CSOW_CONE, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, 0 );

		if( self.m_iClip == 0 and m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_X : CSOW_RECOIL_STANDING_X;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_Y : CSOW_RECOIL_STANDING_Y;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;

		TraceResult tr;

		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecDir = vecAiming 
						+ x * (CSOW_CONE.x) * g_Engine.v_right 
						+ y * (CSOW_CONE.y) * g_Engine.v_up;

		Vector vecEnd = vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0f )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null or pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );

				g_WeaponFuncs.ClearMultiDamage();

				if( pHit.pev.takedamage != DAMAGE_NO )
					pHit.TraceAttack( m_pPlayer.pev, CSOW_DAMAGE, vecDir, tr, DMG_BULLET | DMG_NEVERGIB );

				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );	
			}
		}
	}

	void Reload()
	{
		if( self.m_iClip >= CSOW_MAX_CLIP ) return;

		if( !m_bInfiniteAmmo )
		{
			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
				return;

			self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD_R + m_iMode, CSOW_TIME_RELOAD );
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

			BaseClass.Reload();
		}
		else
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_RELOAD;

			self.SendWeaponAnim( ANIM_RELOAD_R + m_iMode );
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
		if( !m_bInfiniteAmmo )
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
		//self.ResetEmptySound(); //ORIGINAL! Lets the EmptySound get played while holding the trigger

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iInRun != 0 )
		{
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE_RUN;
			self.SendWeaponAnim( ANIM_RUN_END_R + m_iMode );
			m_iInRun = 0;
		}
		else
		{
			self.SendWeaponAnim( ANIM_IDLE_M + m_iMode );
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
		}
	}

	void ItemPreFrame()
	{
		if( IsRunning() )
		{
			if( m_iInRun == 0 )
			{
				self.SendWeaponAnim(ANIM_RUN_START_R + m_iMode);
				m_iInRun = 1;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.3f; //CSOW_TIME_IDLE_RUN
			}
			else if( m_iInRun == 1 )
			{
				if( self.m_flTimeWeaponIdle < g_Engine.time )
				{
					self.SendWeaponAnim(ANIM_RUN_IDLE_R + m_iMode);
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
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_desperado::weapon_desperado", "weapon_desperado" );
	g_ItemRegistry.RegisterWeapon( "weapon_desperado", "custom_weapons/cso", "44FD" ); //.44 Fast Draw
}

} //namespace cso_desperado END