namespace cso_janus9
{

const int CSOW_WEIGHT					= 10;
const int CSOW_DAMAGE1					= 35;
const int CSOW_DAMAGE2					= 50;
const int CSOW_DAMAGE3					= 75;

const float CSOW_TIME_DRAW				= 1.0f;
const float CSOW_TIME_DELAY_MISS		= 1.2f;
const float CSOW_TIME_DELAY_HIT			= 0.6f;
const float CSOW_TIME_DELAY_HIT_WORLD	= 0.6f;
const float CSOW_TIME_DELAY2			= 1.8f;
const float CSOW_TIME_IDLE1				= 1.7f; //Random number between these two
const float CSOW_TIME_IDLE2				= 1.7f;
const float CSOW_TIME_FIRE_TO_IDLE1		= 1.2f;
const float CSOW_TIME_FIRE_TO_IDLE2		= 1.8f;

const Vector CSOW_AOE_MINS				= Vector(-32, -32, -64);
const Vector CSOW_AOE_MAXS				= Vector(32, 32, 64);

const string CSOW_ANIMEXT				= "crowbar";

const string MODEL_VIEW					= "models/custom_weapons/cso/v_janus9.mdl"; //modified/fixed by Aperture
const string MODEL_PLAYER1				= "models/custom_weapons/cso/p_janus9_a.mdl"; //modified/fixed by Aperture
const string MODEL_PLAYER2				= "models/custom_weapons/cso/p_janus9_b.mdl"; //modified/fixed by Aperture
const string MODEL_WORLD				= "models/custom_weapons/cso/w_janus9.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_SIGNAL,
	ANIM_ENDSIGNAL,
	ANIM_SLASH1,
	ANIM_SLASH1_STARTSIGNAL,
	ANIM_SLASH1_SIGNAL,
	ANIM_SLASH2,
	ANIM_SLASH2_STARTSIGNAL,
	ANIM_SLASH2_SIGNAL,
	ANIM_DRAW,
	ANIM_DRAW_SIGNAL,
	ANIM_STAB1,
	ANIM_STAB2
};

enum csowsounds_e
{
	SND_DRAW = 0,
	SND_ENDSIGNAL,
	SND_HIT1,
	SND_HIT2,
	SND_METAL1,
	SND_METAL2,
	SND_SLASH1,
	SND_SLASH2_SIGNAL,
	SND_STAB1,
	SND_STAB2,
	SND_STONE1,
	SND_STONE2,
	SND_WOOD1,
	SND_WOOD2
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/janus9_draw.wav",
	"custom_weapons/cso/janus9_endsignal.wav",
	"custom_weapons/cso/janus9_hit1.wav",
	"custom_weapons/cso/janus9_hit2.wav",
	"custom_weapons/cso/janus9_metal1.wav",
	"custom_weapons/cso/janus9_metal2.wav",
	"custom_weapons/cso/janus9_slash1.wav",
	"custom_weapons/cso/janus9_slash2_signal.wav",
	"custom_weapons/cso/janus9_stab1.wav",
	"custom_weapons/cso/janus9_stab2.wav",
	"custom_weapons/cso/janus9_stone1.wav",
	"custom_weapons/cso/janus9_stone2.wav",
	"custom_weapons/cso/janus9_wood1.wav",
	"custom_weapons/cso/janus9_wood2.wav"
};

class weapon_janus9 : CBaseCustomWeapon
{
	//private CBasePlayer@ m_pPlayer = null;

	private int m_iSwing;
	private int m_iMode;
	private float m_flResetMode;
	private CBaseEntity@ pTrigger = null;
	private float m_flRemoveTrigger;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.m_flCustomDmg = self.pev.dmg;
		m_iMode = -1;
		m_flResetMode = 0;
		m_flRemoveTrigger = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER1 );
		g_Game.PrecacheModel( MODEL_PLAYER2 );
		g_Game.PrecacheModel( MODEL_WORLD );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_janus9.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud96.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= CSO::JANUS9_SLOT - 1;
		info.iPosition		= CSO::JANUS9_POSITION - 1;
		info.iWeight		= CSOW_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_janus9") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			string pmodel = m_iMode <= 0 ? MODEL_PLAYER1 : MODEL_PLAYER2;
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(pmodel), m_iMode <= 0 ? ANIM_DRAW : ANIM_DRAW_SIGNAL, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5f;
		m_pPlayer.pev.viewmodel = "";

		SetThink( null );
	}

	void PrimaryAttack()
	{
		if( !Swing(1) )
		{
			SetThink( ThinkFunction(this.SwingAgain) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}

		if( m_iMode > 0 )
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER2;

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;
	}

	void SecondaryAttack()
	{
		if( m_iMode < 1 )
			return;

		switch( (m_iSwing++) % 2 )
		{
			case 0: self.SendWeaponAnim( ANIM_STAB1 ); break;
			case 1: self.SendWeaponAnim( ANIM_STAB2 ); break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SLASH2_SIGNAL], 1, ATTN_NORM );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		AOEDamage();

		m_iMode = -1;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void AOEDamage()
	{
		Vector triggerPosition;
		{
			Vector vecUnused;
			g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, triggerPosition, vecUnused, vecUnused );
		}

		triggerPosition = pev.origin + (triggerPosition * 32);
		@pTrigger = g_EntityFuncs.Create( "cso_aoetrigger", triggerPosition, g_vecZero, false, m_pPlayer.edict() );
		g_EntityFuncs.SetSize( pTrigger.pev, CSOW_AOE_MINS, CSOW_AOE_MAXS );
		g_EntityFuncs.DispatchSpawn(pTrigger.edict());

		if( pTrigger !is null )
		{
			array<CBaseEntity@> pList(8);
			int count = g_EntityFuncs.EntitiesInBox( pList, pTrigger.pev.absmin, pTrigger.pev.absmax, (FL_MONSTER) );

			Vector forward;
			{
				Vector vecUnused;
				g_EngineFuncs.AngleVectors( m_pPlayer.pev.angles, forward, vecUnused, vecUnused );
			}

			if( count > 0 )
			{
				for( int i = 0; i < count; ++i )
				{
					if( pList[i] !is pTrigger )
					{
						if( pList[i].edict() !is m_pPlayer.edict() )
						{
							//g_Game.AlertMessage( at_console, "I hit something: " + pList[i].pev.classname + "\n");
							pList[i].TakeDamage( m_pPlayer.pev, m_pPlayer.pev, CSOW_DAMAGE3, DMG_CRUSH );
							pList[i].pev.punchangle.x = 15;
							pList[i].pev.velocity = pList[i].pev.velocity + forward * 100;
						}
					}
				}

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_HIT1 + Math.RandomLong(0, 1)], 1, ATTN_NORM );

				m_pPlayer.m_iWeaponVolume = 128;
			}
			//else g_Game.AlertMessage( at_console, "count <= 0 !\n" );
		}
		//else g_Game.AlertMessage( at_console, "pTrigger is null !\n" );

		m_flRemoveTrigger = g_Engine.time + 0.1f;
	}

	void SwingAgain()
	{
		Swing(0);
	}

	bool Swing( int iFirst )
	{
		bool bDidHit = false;

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
				if ( pHit is null or pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0f )
		{
			if( iFirst != 0 )
			{
				++m_iMode;
				m_flResetMode = g_Engine.time + 5.0f;

				switch( (m_iSwing++) % 2 )
				{
					case 0: self.SendWeaponAnim( ANIM_SLASH1 + Math.clamp(0, 2, m_iMode) ); break;
					case 1: self.SendWeaponAnim( ANIM_SLASH2 + Math.clamp(0, 2, m_iMode) ); break;
				}

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY_MISS;

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[ (m_iMode <= 0 ? SND_SLASH1 : SND_SLASH2_SIGNAL)], 1, ATTN_NORM );

				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			}
		}
		else
		{
			++m_iMode;
			m_flResetMode = g_Engine.time + 5.0f;

			bDidHit = true;

			CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

			switch( (m_iSwing++) % 2 )
			{
				case 0: self.SendWeaponAnim( ANIM_SLASH1 + Math.clamp(0, 2, m_iMode) ); break;
				case 1: self.SendWeaponAnim( ANIM_SLASH2 + Math.clamp(0, 2, m_iMode) ); break;
			}

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			float flDamage = m_iMode <= 0 ? CSOW_DAMAGE1 : CSOW_DAMAGE2;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();

			pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0f;
			bool bHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY_HIT;

				if( pEntity.Classify() != CLASS_NONE and pEntity.Classify() != CLASS_MACHINE and pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() )
						pEntity.pev.velocity = pEntity.pev.velocity + (self.pev.origin - pEntity.pev.origin).Normalize() * 120;

					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_HIT1 + Math.RandomLong(0, 1)], 1, ATTN_NORM );

					m_pPlayer.m_iWeaponVolume = 128;

					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1f;

					bHitWorld = false;
				}
			}

			if( bHitWorld )
			{
				g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CROWBAR );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY_HIT_WORLD;

				string sTexture = g_Utility.TraceTexture( null, vecSrc, vecSrc + g_Engine.v_forward * 128 );
				char cType = g_SoundSystem.FindMaterialType(sTexture);

				int iSound = SND_METAL1;

				if( string(cType) == "C" )
					iSound = SND_STONE1;
				else if( string(cType) == "W" )
					iSound = SND_WOOD1;

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[iSound + Math.RandomLong(0, 1)], 1, ATTN_NORM );
			}

			m_pPlayer.m_iWeaponVolume = int(flVol * 512); 
		}

		return bDidHit;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( m_iMode < 1 ? ANIM_IDLE : ANIM_IDLE_SIGNAL );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( CSOW_TIME_IDLE1, CSOW_TIME_IDLE2 );
	}

	void ItemPreFrame()
	{
		if( m_iMode > 5 ) m_iMode = -1;

		if( m_iMode >= 1 and m_flResetMode > 0 and g_Engine.time > m_flResetMode )
		{//Todo: play ANIM_ENDSIGNAL
			m_flResetMode = 0;
			m_iMode = -1;
		}

		if( m_flRemoveTrigger > 0 and g_Engine.time > m_flRemoveTrigger )
		{
			if( pTrigger !is null )
				g_EntityFuncs.Remove( pTrigger );

			m_flRemoveTrigger = 0;
		}

		if( m_iMode < 1 and self.m_flNextSecondaryAttack < g_Engine.time )
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER1;

		BaseClass.ItemPreFrame();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_janus9::weapon_janus9", "weapon_janus9" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CSO::cso_aoetrigger", "cso_aoetrigger" );
	g_ItemRegistry.RegisterWeapon( "weapon_janus9", "custom_weapons/cso" );
}

} //namespace janus9 END
