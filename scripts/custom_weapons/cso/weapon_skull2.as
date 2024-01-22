namespace cso_skull2
{

const int CSOW_DEFAULT_GIVE			= 7;
const int CSOW_MAX_CLIP 			= 7; //14 when dualwielding
const int CSOW_MAX_AMMO				= 35;
const float CSOW_DAMAGE1			= 39;
const float CSOW_DAMAGE2			= 47;
const float CSOW_DELAY1				= 0.28f;
const float CSOW_DELAY2				= 0.15f;
const float CSOW_TIME_DRAW1			= 1.0f;
const float CSOW_TIME_DRAW2			= 1.3f;
const float CSOW_TIME_IDLE1			= 3.0f; //Random number between these two
const float CSOW_TIME_IDLE2			= 3.0f;
const float CSOW_TIME_FIRE_TO_IDLE	= 1.0f;
const float CSOW_TIME_RELOAD1		= 2.5f;
const float CSOW_TIME_RELOAD2		= 3.3f;
const Vector2D CSOW_RECOIL1_X		= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL1_Y		= Vector2D(0, 0);
const Vector2D CSOW_RECOIL2_X		= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL2_Y		= Vector2D(-2, 2);
const Vector CSOW_CONE1_DUCKING		= VECTOR_CONE_2DEGREES;
const Vector CSOW_CONE1_STANDING	= VECTOR_CONE_3DEGREES;
const Vector CSOW_CONE2_DUCKING		= VECTOR_CONE_3DEGREES;
const Vector CSOW_CONE2_STANDING	= VECTOR_CONE_4DEGREES;

const string CSOW_MODEL_VIEW		= "models/custom_weapons/cso/v_skull2.mdl";
const string CSOW_MODEL_PLAYER		= "models/custom_weapons/cso/p_skull2.mdl";
const string CSOW_MODEL_PLAYER_DUAL	= "models/custom_weapons/cso/p_skull2dual.mdl";
const string CSOW_MODEL_WORLD		= "models/custom_weapons/cso/w_skull2.mdl";
const string CSOW_MODEL_SHELL		= "models/custom_weapons/cso/shell_skull1.mdl";
const string CSOW_MODEL_CLIP		= "models/custom_weapons/cso/clip_skull1.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE2,
	ANIM_IDLE_LEFTEMPTY,
	ANIM_DRAW,
	ANIM_DRAW2,
	ANIM_DRAW3,
	ANIM_DRAW4,
	ANIM_SHOOT,
	ANIM_SHOOT_EMPTY,
	ANIM_SHOOT_LEFT1,
	ANIM_SHOOT_LEFT2,
	ANIM_SHOOT_LEFT_LAST,
	ANIM_SHOOT_RIGHT1,
	ANIM_SHOOT_RIGHT2,
	ANIM_SHOOT_RIGHT_LAST,
	ANIM_RELOAD1,
	ANIM_RELOAD2
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_CLIPIN,
	SND_CLIPOUT,
	SND_DRAW,
	SND_DRAW2,
	SND_DRAW3,
	SND_DRAW4,
	SND_RELOAD2_1,
	SND_RELOAD2_2,
	SND_SHOOT
};

enum skull2mode_e
{
	MODE_SINGLE = 1,
	MODE_DUAL
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/skull2_clipin.wav",
	"custom_weapons/cso/skull2_clipout.wav",
	"custom_weapons/cso/skull2_draw.wav",
	"custom_weapons/cso/skull2_draw2.wav",
	"custom_weapons/cso/skull2_draw3.wav",
	"custom_weapons/cso/skull2_draw4.wav",
	"custom_weapons/cso/skull2_reload2_1.wav",
	"custom_weapons/cso/skull2_reload2_2.wav",
	"custom_weapons/cso/skull2-1.wav"
};

class weapon_skull2 : CBaseCSOWeapon
{
	private uint m_uiMode;
	private bool leftright = false;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, CSOW_MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		m_uiMode = MODE_SINGLE;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( CSOW_MODEL_VIEW );
		g_Game.PrecacheModel( CSOW_MODEL_PLAYER );
		g_Game.PrecacheModel( CSOW_MODEL_PLAYER_DUAL );
		g_Game.PrecacheModel( CSOW_MODEL_WORLD );
		g_Game.PrecacheModel( CSOW_MODEL_SHELL );
		g_Game.PrecacheModel( CSOW_MODEL_CLIP );

		for( i = 0; i < pCSOWSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_skull2.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud136.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud2.spr" );
		g_Game.PrecacheGeneric( "sprites/cs16/mzcs2.spr" );

		g_Game.PrecacheGeneric( "events/muzzle_skull2_left.txt" );
		g_Game.PrecacheGeneric( "events/muzzle_skull2_right.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 		= CSOW_MAX_AMMO;
		info.iMaxClip 		= m_uiMode == MODE_SINGLE ? CSOW_MAX_CLIP : (CSOW_MAX_CLIP * 2);
		info.iAmmo1Drop		= CSOW_MAX_CLIP;
		info.iSlot			= CSO::SKULL2_SLOT - 1;
		info.iPosition		= CSO::SKULL2_POSITION - 1;
		info.iWeight		= CSO::SKULL2_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_skull2") );
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
			switch( m_uiMode )
			{
				case MODE_SINGLE:
				{
					bResult = self.DefaultDeploy( self.GetV_Model(CSOW_MODEL_VIEW), self.GetP_Model(CSOW_MODEL_PLAYER), ANIM_DRAW, "onehanded" );
					self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW1;

					break;
				}

				case MODE_DUAL:
				{
					bResult = self.DefaultDeploy( self.GetV_Model(CSOW_MODEL_VIEW), self.GetP_Model(CSOW_MODEL_PLAYER_DUAL), ANIM_DRAW2, "uzis" );
					self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW2;

					break;
				}
			}

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
		SKULL2Fire( m_uiMode == MODE_SINGLE ? CSOW_DELAY1 : CSOW_DELAY2 );
	}

	void SKULL2Fire( float flCycleTime )
	{
		flCycleTime -= 0.07f;

		Vector vecShootCone;

		if( (m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) && self.m_flNextPrimaryAttack <= g_Engine.time )
			return;

		vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE1_DUCKING : CSOW_CONE1_STANDING;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		int anim;

		if( m_uiMode == MODE_SINGLE )
		{
			anim = ANIM_SHOOT;

			if( self.m_iClip == 0 )
				anim = ANIM_SHOOT_EMPTY;
		}
		else
		{
			if( leftright )
			{
				m_pPlayer.m_szAnimExtension = "uzis_left";
				leftright = false;
			}
			else
			{
				m_pPlayer.m_szAnimExtension = "uzis_right";
				leftright = true;
			}

			if( self.m_iClip == 1 )
				anim = ANIM_SHOOT_RIGHT_LAST;
			else if( self.m_iClip == 0 )
				anim = ANIM_SHOOT_LEFT_LAST;
			else
			{
				anim = ((self.m_iClip % 2) == 0) ? ANIM_SHOOT_LEFT1 : ANIM_SHOOT_RIGHT1;
				anim += Math.RandomLong(0, 1);
			}
		}

		self.SendWeaponAnim( anim );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1, ATTN_NORM );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, 0 ); //needed ??

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( CSOW_RECOIL1_X.x, CSOW_RECOIL1_X.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( CSOW_RECOIL1_Y.x, CSOW_RECOIL1_Y.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;

		TraceResult tr;

		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecDir = vecAiming 
						+ x * (vecShootCone.x) * g_Engine.v_right 
						+ y * (vecShootCone.y) * g_Engine.v_up;

		Vector vecEnd = vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0f )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );

				g_WeaponFuncs.ClearMultiDamage();

				if( pHit.pev.takedamage != DAMAGE_NO )
					pHit.TraceAttack( m_pPlayer.pev, m_uiMode == MODE_SINGLE ? CSOW_DAMAGE1 : CSOW_DAMAGE2, vecDir, tr, DMG_SNIPER | DMG_LAUNCH | DMG_NEVERGIB );

				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );	
			}
		}
	}

	void SecondaryAttack()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		switch( m_uiMode )
		{
			case MODE_SINGLE:
			{
				if( ammo > 0 )
				{
					int ammodiff = Math.min( CSOW_MAX_CLIP, ammo );
					ammo -= ammodiff;
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
					self.m_iClip += Math.min( ammodiff, CSOW_MAX_CLIP );
				}

				self.SendWeaponAnim( ANIM_DRAW3 );
				m_pPlayer.pev.weaponmodel = CSOW_MODEL_PLAYER_DUAL;
				m_pPlayer.m_szAnimExtension = "uzis";
				m_uiMode = MODE_DUAL;

				break;
			}

			case MODE_DUAL:
			{
				if( self.m_iClip > CSOW_MAX_CLIP )
				{
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + (self.m_iClip - CSOW_MAX_CLIP) );
					self.m_iClip = CSOW_MAX_CLIP;
				}

				self.SendWeaponAnim( ANIM_DRAW4 );
				m_pPlayer.pev.weaponmodel = CSOW_MODEL_PLAYER;
				m_pPlayer.m_szAnimExtension = "onehanded";
				m_uiMode = MODE_SINGLE;

				break;
			}
		}

		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 3.0f;
	}

	void Reload()
	{
		int ammocomp = m_uiMode == MODE_SINGLE ? CSOW_MAX_CLIP : (CSOW_MAX_CLIP * 2);

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 || self.m_iClip >= ammocomp )
			return;

		switch( m_uiMode )
		{
			case MODE_SINGLE:
			{
				self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD1, CSOW_TIME_RELOAD1 );
				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD1;

				break;
			}

			case MODE_DUAL:
			{
				self.DefaultReload( CSOW_MAX_CLIP * 2, ANIM_RELOAD2, CSOW_TIME_RELOAD2 );
				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD2;

				break;
			}
		}

		self.pev.nextthink = g_Engine.time + 0.5f;
		SetThink( ThinkFunction(DropShellsThink) );

		BaseClass.Reload();

		leftright = false;
	}

	void ItemPostFrame()
	{
		if( self.m_fInReload && (m_pPlayer.m_flNextAttack <= 0.0f) )
		{
			int maxclip = m_uiMode == MODE_SINGLE ? CSOW_MAX_CLIP : (CSOW_MAX_CLIP * 2);
			// complete the reload. 
			int j = Math.min( maxclip - self.m_iClip, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) );

			// Add them to the clip
			self.m_iClip += j;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - j);

			self.m_fInReload = false;
		}

		BaseClass.ItemPostFrame();
	}

	void DropShellsThink()
	{
		DropShells();
	}

	void DropShells()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle );

		Vector vecShellVelocity, vecShellOrigin;

		for( uint i = 0; i <= 6; i++ )
		{
			CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 0, 0, 0, false, true );
			//vecShellVelocity.y *= 1;
			g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[1], g_EngineFuncs.ModelIndex(CSOW_MODEL_SHELL), TE_BOUNCE_SHELL );
		}

		if( m_uiMode == MODE_DUAL )
		{
			for( uint i = 0; i <= 6; i++ )
			{
				CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 0, -16, 0, false, true );
				//vecShellVelocity.y *= 1;
				g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[1], g_EngineFuncs.ModelIndex(CSOW_MODEL_SHELL), TE_BOUNCE_SHELL );
			}
		}

		self.pev.nextthink = g_Engine.time + 1.2f;
		SetThink( ThinkFunction(DropClipThink) );
	}

	void DropClipThink()
	{
		Vector vecShellVelocity, vecShellOrigin;

		CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 15, 12, -9, false, true );
		//vecShellVelocity.y *= 1;
		DropClip( vecShellOrigin, vecShellVelocity, 1, g_EngineFuncs.ModelIndex(CSOW_MODEL_CLIP) );

		if( m_uiMode == MODE_DUAL )
		{
			CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, 15, -12, -9, false, true );
			//vecShellVelocity.y *= 1;
			DropClip( vecShellOrigin, vecShellVelocity, 1, g_EngineFuncs.ModelIndex(CSOW_MODEL_CLIP) );
		}
	}

	void DropClip( Vector& in vecOrigin, Vector& in vecVelocity, int rotation, int model )
	{
		NetworkMessage m( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m.WriteByte(TE_BREAKMODEL);
			m.WriteCoord(vecOrigin.x);
			m.WriteCoord(vecOrigin.y);
			m.WriteCoord(vecOrigin.z - 2);
			m.WriteCoord(1);
			m.WriteCoord(1);
			m.WriteCoord(1);
			m.WriteCoord(vecVelocity.x);
			m.WriteCoord(vecVelocity.y);
			m.WriteCoord(vecVelocity.z);
			m.WriteByte(rotation);
			m.WriteShort(model);
			m.WriteByte(1);
			m.WriteByte(20);
			m.WriteByte(2);
		m.End();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( m_uiMode == MODE_DUAL )
			m_pPlayer.m_szAnimExtension = "uzis";

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int anim = ANIM_IDLE;

		if( m_uiMode == MODE_DUAL )
		{
			if( self.m_iClip == 1 ) anim = ANIM_IDLE_LEFTEMPTY;
			else anim = ANIM_IDLE2;
		}

		self.SendWeaponAnim( anim );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( CSOW_TIME_IDLE1, CSOW_TIME_IDLE2 );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_skull2::weapon_skull2", "weapon_skull2" );
	g_ItemRegistry.RegisterWeapon( "weapon_skull2", "custom_weapons/cso", "357", "", "ammo_357" );
}

} //namespace cso_skull2 END

/*
Todo
recoil
spread
clip dropping
*/