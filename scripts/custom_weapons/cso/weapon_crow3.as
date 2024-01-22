namespace cso_crow3
{
const int CSOW_DEFAULT_GIVE					= 64;
const int CSOW_MAX_CLIP 						= 64;
const int CSOW_MAX_AMMO						= 120;
const float CSOW_DAMAGE						= 14;
const float CSOW_TIME_DELAY					= 0.087;
const float CSOW_TIME_DRAW					= 1.0;
const float CSOW_TIME_IDLE						= 3.0;
const float CSOW_TIME_FIRE_TO_IDLE		= 0.5;
const float CSOW_TIME_RELOAD1				= 3.0;
const float CSOW_TIME_RELOAD2				= 2.0;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, 1);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, -1);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE_STANDING			= VECTOR_CONE_2DEGREES;
const Vector CSOW_CONE_CROUCHING		= VECTOR_CONE_1DEGREES;

const string CSOW_ANIMEXT						= "mp5";

const string MODEL_VIEW							= "models/custom_weapons/cso/v_crow3.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_crow3.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_crow3.mdl";

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
	SND_EMPTY = 0,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/crow3-1.wav",
	"custom_weapons/cso/crow3_draw.wav",
	"custom_weapons/cso/crow3_reload_a.wav",
	"custom_weapons/cso/crow3_reload_b.wav",
	"custom_weapons/cso/crow3_reload_boltpull.wav",
	"custom_weapons/cso/crow3_reload_in.wav"
};

enum csowstate_e
{
	STATE_NONE = 0,
	STATE_RELOAD_START,
	STATE_RELOAD_MID,
	STATE_RELOAD_QUICK,
	STATE_RELOAD_END
};

class weapon_crow3 : CBaseCSOWeapon
{
	private int m_iReloadState;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		m_iReloadState = STATE_NONE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		if( CSO::bUseDroppedItemEffect )
			g_Game.PrecacheModel( CSO::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < CSO::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( CSO::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_crow3.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud156.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash2.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash17.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_crow31.txt" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_crow32.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= CSO::CROW3_SLOT - 1;
		info.iPosition		= CSO::CROW3_POSITION - 1;
		info.iWeight		= CSO::CROW3_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		SetThink(null);
		m_iReloadState = STATE_NONE;
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		HandleAmmoReduction();
		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;
		Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE_CROUCHING : CSOW_CONE_STANDING;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, CSOW_DAMAGE );
		DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_MP5, m_pPlayer, true );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}

	void ItemPreFrame()
	{
		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 and self.m_iClip < CSOW_MAX_CLIP and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			switch( m_iReloadState )
			{
				case STATE_NONE:
				{
					m_iReloadState = STATE_RELOAD_START;
					self.SendWeaponAnim( ANIM_RELOAD_START );

					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD1;
					SetThink( ThinkFunction(this.ReloadThink) );
					pev.nextthink = g_Engine.time + 0.6;
					break;
				}

				case STATE_RELOAD_MID:
				{
					m_iReloadState = STATE_RELOAD_QUICK;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
					SetThink( ThinkFunction(this.ReloadThink) );
					pev.nextthink = g_Engine.time;
					break;
				}
			}
		}

		BaseClass.ItemPreFrame();
	}

	void ReloadThink()
	{
		switch( m_iReloadState )
		{
			case STATE_RELOAD_START:
			{
				m_iReloadState = STATE_RELOAD_MID;
				pev.nextthink = g_Engine.time + 0.4;
				break;
			}

			case STATE_RELOAD_MID:
			{
				self.SendWeaponAnim( ANIM_RELOAD_END_NORMAL );
				m_iReloadState = STATE_RELOAD_END;
				pev.nextthink = g_Engine.time + 2.0;
				break;
			}

			case STATE_RELOAD_QUICK:
			{
				self.SendWeaponAnim( ANIM_RELOAD_END_QUICK );
				m_iReloadState = STATE_RELOAD_END;
				pev.nextthink = g_Engine.time + 1.0;
				break;
			}

			case STATE_RELOAD_END:
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
				SetThink( null );
				m_iReloadState = STATE_NONE;
				break;
			}
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crow3::weapon_crow3", "weapon_crow3" );
	g_ItemRegistry.RegisterWeapon( "weapon_crow3", "custom_weapons/cso", "9mm", "", "ammo_9mmAR" );

	if( CSO::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			CSO::RegisterGunDrop();
	}
}

} //namespace cso_crow3 END

/*
TODO
Somehow fix the quick-reload indicator and the eyes in the v_model (not possible in svencoop?)
Make use of the default Reload function somehow?
*/