namespace cso_dragonclaw
{

const int DCLAW_DAMAGE_SLASH			= 45;//45 default
const int DCLAW_DAMAGE_STAB				= 80;//100 default

const float DCLAW_DELAY_PRIMARY			= 1.0f;
const float DCLAW_DELAY_SECONDARY		= 0.9f;
const float DCLAW_TIME_IDLE				= Math.RandomFloat( 8.5f, 17 );
const float DCLAW_TIME_DRAW				= 1.2f;
const float DCLAW_TIME_FIRE_TO_IDLE1	= 1.2f;
const float DCLAW_TIME_FIRE_TO_IDLE2	= 1.4f;

const string DCLAW_SOUND_IDLE			= "custom_weapons/cso/dragonclaw_idle.wav";
const string DCLAW_SOUND_DRAW			= "custom_weapons/cso/dragonclaw_draw.wav";
const string DCLAW_SOUND_SLASH1_1		= "custom_weapons/cso/dragonclaw_slash1_1.wav";
const string DCLAW_SOUND_SLASH1_2		= "custom_weapons/cso/dragonclaw_slash1_2.wav";
const string DCLAW_SOUND_SLASH2_1		= "custom_weapons/cso/dragonclaw_slash2_1.wav";
const string DCLAW_SOUND_SLASH2_2		= "custom_weapons/cso/dragonclaw_slash2_2.wav";
const string DCLAW_SOUND_SLASHHIT		= "custom_weapons/cso/dragonclaw_hit1.wav";
const string DCLAW_SOUND_SLASHWALL		= "custom_weapons/cso/dragonclaw_hitwall1.wav";
const string DCLAW_SOUND_STABREADY		= "custom_weapons/cso/dragonclaw_stab_ready.wav";
const string DCLAW_SOUND_STABHIT		= "custom_weapons/cso/dragonclaw_stab_hit.wav";
const string DCLAW_SOUND_STABMISS		= "custom_weapons/cso/dragonclaw_stab_miss.wav";

const string CSOW_ANIMEXT						= "squeak";

const string DCLAW_MODEL_VIEW			= "models/custom_weapons/cso/v_dragonclaw.mdl";
const string DCLAW_MODEL_PLAYER			= "models/custom_weapons/cso/p_dragonclaw.mdl";
const string DCLAW_MODEL_WORLD			= "models/custom_weapons/cso/w_dragonclaw.mdl";

enum dclaw_e
{
	DCLAW_IDLE,
	DCLAW_DRAW,
	DCLAW_SLASH1,
	DCLAW_SLASH2,
	DCLAW_SLASH3,
	DCLAW_SLASH3HIT,
	DCLAW_SLASH3MISS,
};

class weapon_dragonclaw : CBaseCSOWeapon
{
	int m_iSwing;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, DCLAW_MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( DCLAW_MODEL_VIEW );
		g_Game.PrecacheModel( DCLAW_MODEL_PLAYER );
		g_Game.PrecacheModel( DCLAW_MODEL_WORLD );

		g_SoundSystem.PrecacheSound( DCLAW_SOUND_IDLE );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_SLASH1_1 );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_SLASH1_2 );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_SLASH2_1 );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_SLASH2_2 );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_SLASHHIT );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_SLASHWALL );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_STABREADY );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_STABHIT );
		g_SoundSystem.PrecacheSound( DCLAW_SOUND_STABMISS );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_IDLE );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_SLASH1_1 );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_SLASH1_2 );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_SLASH2_1 );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_SLASH2_2 );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_SLASHHIT );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_SLASHWALL );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_STABREADY );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_STABHIT );
		g_Game.PrecacheGeneric( "sound/" + DCLAW_SOUND_STABMISS );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_dragonclaw.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud63.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= cso::DCLAW_SLOT - 1;
		info.iPosition		= cso::DCLAW_POSITION - 1;
		info.iWeight		= cso::DCLAW_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage dclaw( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			dclaw.WriteLong( g_ItemRegistry.GetIdForName("weapon_dragonclaw") );
		dclaw.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			m_iSwing = 0;
			bResult = self.DefaultDeploy( self.GetV_Model( DCLAW_MODEL_VIEW ), self.GetP_Model( DCLAW_MODEL_PLAYER ), DCLAW_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal )
	{
		SetThink( null );
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5f;

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		SwingFirst( 1 );
		SetThink( ThinkFunction( this.SwingSecond ) );
		self.pev.nextthink = g_Engine.time + 0.5f;
		self.m_flTimeWeaponIdle = g_Engine.time + DCLAW_TIME_FIRE_TO_IDLE1;
	}
	
	void SecondaryAttack()
	{
		HeavySwingFirst();
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_SECONDARY;
		SetThink( ThinkFunction(this.HeavySwingSecond) );
		self.pev.nextthink = g_Engine.time + 0.7f;
		
		self.m_flTimeWeaponIdle = g_Engine.time + DCLAW_TIME_FIRE_TO_IDLE2;
	}

	void SwingFirst( int fFirst )
	{
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 47;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0 )
		{
			if( fFirst == 1 )
			{
				switch( ( m_iSwing++ ) % 2 )
				{
					case 0:
						self.SendWeaponAnim( DCLAW_SLASH1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
					case 1:
						self.SendWeaponAnim( DCLAW_SLASH2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
				}
				
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_PRIMARY;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_SLASH1_1, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
			}

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_SLASH1_2, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
		}
		else
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( fFirst == 1 )
			{
				switch( ( ( m_iSwing++ ) % 2 ) )
				{
					case 0:
						self.SendWeaponAnim( DCLAW_SLASH1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
					case 1:
						self.SendWeaponAnim( DCLAW_SLASH2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
				}
				
			}

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			float flDamage = DCLAW_DAMAGE_SLASH;

			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();

			if( fFirst == 1 )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH );  
			}
			else
			{
				// subsequent swings do 50%
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_SLASH );  
			}

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				if( !pEntity.IsAlive() )
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1f;
				else
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_PRIMARY/2;

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() )// let's pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}

					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_SLASHHIT, 1, ATTN_NORM );
					
					m_pPlayer.m_iWeaponVolume = 128;

					if( pEntity.IsAlive() )
						flVol = 0.1f;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_PRIMARY/2;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_SLASHWALL, 1, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
			}

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
	}

	void SwingSecond()
	{
		SwingFirst( 0 );
	}

	void HeavySwingFirst()
	{
		self.SendWeaponAnim( DCLAW_SLASH3, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_STABREADY, 1, ATTN_NORM );
	}

	void HeavySwingSecond()
	{
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 37;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0 )
		{
			self.SendWeaponAnim( DCLAW_SLASH3MISS, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_SECONDARY/2;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_STABMISS, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
		}
		else
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			self.SendWeaponAnim( DCLAW_SLASH3HIT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			float flDamage = DCLAW_DAMAGE_STAB;

			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();
			pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH );  
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_SECONDARY/1.5f;

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	
					if( pEntity.IsPlayer() )
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	
					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_STABHIT, 1, ATTN_NORM );
					
					m_pPlayer.m_iWeaponVolume = 128; 
					
					if( pEntity.IsAlive() )
						flVol = 0.1f;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + DCLAW_DELAY_SECONDARY/2;
				fvolbar = 1;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DCLAW_SOUND_SLASHWALL, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			}

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		self.SendWeaponAnim( DCLAW_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		
		self.m_flTimeWeaponIdle = g_Engine.time + DCLAW_TIME_IDLE;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_dragonclaw::weapon_dragonclaw", "weapon_dragonclaw" );
	g_ItemRegistry.RegisterWeapon( "weapon_dragonclaw", "custom_weapons/cso" );
}

} // namespace cso_dragonclaw END