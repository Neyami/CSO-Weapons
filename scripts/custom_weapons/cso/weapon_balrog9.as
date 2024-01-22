namespace cso_balrog9
{

const int BALROG9_DAMAGE_PRIMARY		= 35;
const float BALROG9_DAMAGE_SEC_MIN		= 60;
const float BALROG9_DAMAGE_SEC_MAX		= 120;

const float BALROG9_DELAY_PRIMARY		= 0.35f;
const float BALROG9_DELAY_PRIMARY_MISS	= 0.5f;
const float BALROG9_DELAY_SEC			= 0.9f;
const float BALROG9_DELAY_SEC_MISS		= 0.9f;
const float BALROG9_TIME_DRAW			= 1.0f;
const float BALROG9_TIME_FIRE_TO_IDLE1	= 1.2f;
const float BALROG9_TIME_FIRE_TO_IDLE2	= 1.4f;
const float BALROG9_TIME_CHARGE			= 3.0f;
const int BALROG9_MAXCHARGE				= 150;

const string BALROG9_MODEL_VIEW			= "models/custom_weapons/cso/v_balrog9.mdl";
const string BALROG9_MODEL_PLAYER		= "models/custom_weapons/cso/p_balrog9.mdl";
const string BALROG9_MODEL_WORLD		= "models/custom_weapons/cso/w_balrog9.mdl";
const string BALROG9_SPRITE_EXP			= "sprites/custom_weapons/cso/ef_balrog1.spr";

enum balrog9_e
{
	BALROG9_IDLE = 0,
	BALROG9_SLASH1,
	BALROG9_SLASH2,
	BALROG9_SLASH3,
	BALROG9_SLASH4,
	BALROG9_SLASH5,
	BALROG9_DRAW,
	BALROG9_CHARGE_START,
	BALROG9_CHARGE_FINISH,
	BALROG9_CHARGE_IDLE1,
	BALROG9_CHARGE_IDLE2,
	BALROG9_CHARGE_ATTACK1,
	BALROG9_CHARGE_ATTACK2
};

enum b9sounds
{
	BALROG9_SND_CHARGE_ATTACK = 0,
	BALROG9_SND_CHARGE_FINISH,
	BALROG9_SND_CHARGE_START,
	BALROG9_SND_DRAW,
	BALROG9_SND_HIT1,
	BALROG9_SND_HIT2,
	BALROG9_SND_HIT_WALL,
	BALROG9_SND_SLASH1,
	BALROG9_SND_SLASH2,
	BALROG9_SND_SLASH3,
	BALROG9_SND_SLASH4,
	BALROG9_SND_SLASH5
};

const array<string> pB9Sounds =
{
	"custom_weapons/cso/balrog9_charge_attack.wav",
	"custom_weapons/cso/balrog9_charge_finish.wav",
	"custom_weapons/cso/balrog9_charge_start.wav",
	"custom_weapons/cso/balrog9_draw.wav",
	"custom_weapons/cso/balrog9_hit1.wav",
	"custom_weapons/cso/balrog9_hit2.wav",
	"custom_weapons/cso/skullaxe_wall.wav",
	"custom_weapons/cso/balrog9_slash1.wav",
	"custom_weapons/cso/balrog9_slash2.wav",
	"custom_weapons/cso/balrog9_slash3.wav",
	"custom_weapons/cso/balrog9_slash4.wav",
	"custom_weapons/cso/balrog9_slash5.wav"
};


class weapon_balrog9 : CBaseCSOWeapon
{
	TraceResult m_trHit;
	int m_iInAttack, m_iCharge;
	float m_flStartCharge, m_flAnimDelay;
	bool m_bFullyCharged;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, BALROG9_MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( BALROG9_MODEL_VIEW );
		g_Game.PrecacheModel( BALROG9_MODEL_PLAYER );
		g_Game.PrecacheModel( BALROG9_MODEL_WORLD );
		g_Game.PrecacheModel( BALROG9_SPRITE_EXP );

		for( i = 0; i < pB9Sounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pB9Sounds[i] );

		//Precache these for downloading
		for( i = 0; i < pB9Sounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pB9Sounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_balrog9.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud75.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/mzbalrog9.spr" );
		
		g_Game.PrecacheGeneric( "events/muzzle_balrog9.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= CSO::BALROG9_SLOT - 1;
		info.iPosition		= CSO::BALROG9_POSITION - 1;
		info.iWeight		= CSO::BALROG9_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage balrog9( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			balrog9.WriteLong( g_ItemRegistry.GetIdForName("weapon_balrog9") );
		balrog9.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( BALROG9_MODEL_VIEW ), self.GetP_Model( BALROG9_MODEL_PLAYER ), BALROG9_DRAW, "squeak" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + BALROG9_TIME_DRAW;
			m_flAnimDelay = 0;

			return bResult;
		}
	}

	void Holster( int skipLocal )
	{
		SetThink( null );
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5f;
		m_iInAttack = 0;
		m_flStartCharge = 0;
		m_iCharge = 0;
		m_flAnimDelay = 0;
		m_bFullyCharged = false;
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_afButtonPressed & IN_ATTACK2 == 1 )
		{
			WeaponIdle();
			return;
		}

		if( m_iInAttack == 1)
		{
			WeaponIdle();
			return;
		}

		if( !Swing(1) )
		{
			SetThink( ThinkFunction(this.SwingAgain) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + BALROG9_TIME_FIRE_TO_IDLE1;
	}

	void SecondaryAttack()
	{
		if( m_iInAttack == 0 )
		{
			self.SendWeaponAnim( BALROG9_CHARGE_START );
			m_iInAttack = 1;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.75f;
			m_flStartCharge = g_Engine.time;
		}
		else if( m_iInAttack == 1 )
		{
			if( self.m_flTimeWeaponIdle < g_Engine.time )
			{
				self.SendWeaponAnim( BALROG9_CHARGE_IDLE1 );
				m_iInAttack = 2;
			}
		}

		if( m_iCharge < BALROG9_MAXCHARGE ) m_iCharge++;
	}

	void Smack()
	{
		g_Utility.DecalTrace( m_trHit, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );
	}

	void HeavySmack()
	{
		g_Utility.DecalTrace( m_trHit, DECAL_OFSCORCH1 + Math.RandomLong(0,2) );
	}

	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0f )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0f )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0f )
		{
			if( fFirst != 0 )
			{
				// miss
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
				self.SendWeaponAnim( BALROG9_SLASH1 + Math.RandomLong(0, 4) );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pB9Sounds[BALROG9_SND_SLASH1 + Math.RandomLong(0, 4)], 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + BALROG9_DELAY_PRIMARY_MISS;
			}
		}
		else
		{
			self.SendWeaponAnim( BALROG9_SLASH1 + Math.RandomLong(0, 4) );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			// hit
			fDidHit = true;
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			g_WeaponFuncs.ClearMultiDamage();

			if( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, BALROG9_DAMAGE_PRIMARY, g_Engine.v_forward, tr, DMG_CLUB ); 
			}
			else
			{
				// subsequent swings do half
				pEntity.TraceAttack( m_pPlayer.pev, BALROG9_DAMAGE_PRIMARY * 0.5f, g_Engine.v_forward, tr, DMG_CLUB ); 
			}

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0f;
			bool bHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + BALROG9_DELAY_PRIMARY;

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE )
				{
					m_pPlayer.m_iWeaponVolume = 128;

					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pB9Sounds[BALROG9_SND_HIT1 + Math.RandomLong(0, 1)], 1, ATTN_NORM );

					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1f;

					bHitWorld = false;
				}
			}

			if( bHitWorld )
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pB9Sounds[BALROG9_SND_HIT_WALL], 1, ATTN_NORM );

			m_trHit = tr;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 );

			SetThink( ThinkFunction(this.Smack) );
			self.pev.nextthink = g_Engine.time + 0.2f;
		}

		return fDidHit;
	}

	void StartLargeSwing()
	{
		float flDamage;

		if( g_Engine.time - m_flStartCharge > BALROG9_TIME_CHARGE )
			flDamage = BALROG9_DAMAGE_SEC_MAX;
		else
			flDamage = Math.clamp( BALROG9_DAMAGE_SEC_MIN, BALROG9_DAMAGE_SEC_MAX, BALROG9_DAMAGE_SEC_MAX * ((g_Engine.time - m_flStartCharge) / BALROG9_TIME_CHARGE) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.75f;
		LargeSwing( flDamage );
	}

	bool LargeSwing( float flDamage )
	{
		bool fDidHit = false;
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( m_bFullyCharged )
		{
			DoBalrogEffect( vecSrc + g_Engine.v_forward * 32 );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pB9Sounds[BALROG9_SND_CHARGE_ATTACK], 1, ATTN_NORM );
			g_WeaponFuncs.RadiusDamage(	tr.vecEndPos, self.pev, m_pPlayer.pev, 64, 80, m_pPlayer.Classify(), DMG_BURN | DMG_NEVERGIB );
		}

		if( tr.flFraction >= 1.0f )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0f )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0f )
		{
			// miss
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			self.SendWeaponAnim( BALROG9_CHARGE_ATTACK1 + Math.RandomLong(0, 1) );

			if( !m_bFullyCharged )
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pB9Sounds[BALROG9_SND_SLASH1 + Math.RandomLong(0, 4)], 1, ATTN_NORM, 0, 94 + Math.RandomLong(0, 0xF) );

			self.m_flNextSecondaryAttack = g_Engine.time + BALROG9_DELAY_SEC_MISS;
		}
		else
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			self.SendWeaponAnim( BALROG9_CHARGE_ATTACK1 + Math.RandomLong(0, 1) );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			fDidHit = true;

			g_WeaponFuncs.ClearMultiDamage();

			pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB | DMG_LAUNCH ); 

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0f;
			bool bHitWorld = true;

			if( pEntity !is null )
			{
				//self.m_flNextSecondaryAttack = g_Engine.time + BALROG9_DELAY_SEC;
				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE )
				{
					m_pPlayer.m_iWeaponVolume = 128;

					if( !m_bFullyCharged )
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pB9Sounds[BALROG9_SND_HIT1 + Math.RandomLong(0, 1)], 1, ATTN_NORM );

					if( !pEntity.IsAlive() )
						  return true;
					else
						  flVol = 0.1f;

					bHitWorld = false;
				}
			}

			if( !m_bFullyCharged && bHitWorld )
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pB9Sounds[BALROG9_SND_HIT_WALL], 1, ATTN_NORM );

			m_trHit = tr;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 );//2048

			self.m_flNextPrimaryAttack = g_Engine.time + BALROG9_DELAY_PRIMARY;
			self.m_flNextSecondaryAttack = g_Engine.time + BALROG9_DELAY_SEC;

			if( !m_bFullyCharged )
			{
				SetThink( ThinkFunction(this.Smack) );
				self.pev.nextthink = g_Engine.time + 0.2f;
			}
			else
			{
				SetThink( ThinkFunction(this.HeavySmack) );
				self.pev.nextthink = g_Engine.time + 0.2f;
			}
		}

		return fDidHit;
	}

	void DoBalrogEffect( Vector &in origin )
	{
		NetworkMessage beffect( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			beffect.WriteByte( TE_EXPLOSION );
			beffect.WriteCoord( origin.x );
			beffect.WriteCoord( origin.y );
			beffect.WriteCoord( origin.z );
			beffect.WriteShort( g_EngineFuncs.ModelIndex(BALROG9_SPRITE_EXP) );
			beffect.WriteByte( 6 ); //scale
			beffect.WriteByte( 50 ); //framerate
			beffect.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		beffect.End();
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iInAttack != 0 )
		{
			StartLargeSwing();
			m_iInAttack = 0;
			m_bFullyCharged = false;
			m_iCharge = 0;
			m_flAnimDelay = 0;
			self.m_flTimeWeaponIdle = g_Engine.time + BALROG9_TIME_FIRE_TO_IDLE2;
		}
		else
		{
			self.SendWeaponAnim( BALROG9_IDLE );
			self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 6.7f, 13.4f );
		}
	}

	void ItemPostFrame()
	{
		if( m_iCharge >= BALROG9_MAXCHARGE && !m_bFullyCharged )
		{
			//g_Game.AlertMessage( at_console, "CHARGED!\n" );

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pB9Sounds[BALROG9_SND_CHARGE_FINISH], VOL_NORM, ATTN_NORM );
			self.SendWeaponAnim( BALROG9_CHARGE_FINISH );
			m_bFullyCharged = true;
			m_flAnimDelay = g_Engine.time + 0.2f;
		}

		if( m_iInAttack != 0 && m_flAnimDelay > 0 && g_Engine.time > m_flAnimDelay )
		{
			self.SendWeaponAnim( BALROG9_CHARGE_IDLE2 );

			m_flAnimDelay = g_Engine.time + 0.2f;
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_balrog9::weapon_balrog9", "weapon_balrog9" );
	g_ItemRegistry.RegisterWeapon( "weapon_balrog9", "custom_weapons/cso" );
}

} //namespace cso_balrog9 END
