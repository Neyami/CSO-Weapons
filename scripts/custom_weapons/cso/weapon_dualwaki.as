//Based on Dual Katan by Dias
namespace cso_dualwaki
{
	
const int CSOW_WEIGHT					= 55;

const int SLASH_DAMAGE					= 40;
const int SLASH_RADIUS					= 100;
const float SLASH_RESET_TIME			= 1.0f;
const float SLASH1_TIME					= 0.25f;
const float SLASH2_TIME1				= 0.25f;
const float SLASH2_TIME2				= 0.25f;

const int STAB_DAMAGE					= 160;
const int STAB_RADIUS					= 90;
const float STAB_POINT_DIS				= 48;
const float STAB_TIME					= 0.5f;
const float STAB_RESET_TIME				= 1.0f;

const float CSOW_TIME_DELAY1			= 0.6f;
const float CSOW_TIME_DELAY2			= 1.0f;
const float CSOW_TIME_IDLE1				= 18.7f; //Random number between these two
const float CSOW_TIME_IDLE2				= 18.7f;
const float CSOW_TIME_DRAW				= 1.0f; //1.2f
const float CSOW_TIME_FIRE_TO_IDLE1		= 1.5f;
const float CSOW_TIME_FIRE_TO_IDLE2		= 1.7f;

const string CSOW_MODEL_VIEW			= "models/custom_weapons/cso/v_dualwaki.mdl";
const string CSOW_MODEL_PLAYER			= "models/custom_weapons/cso/p_dualwaki.mdl";
const string CSOW_MODEL_WORLD			= "models/custom_weapons/cso/w_dualwaki.mdl";

const string CSOW_ANIMEXT				= "trip";

enum csow_e
{
	ANIM_IDLE,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STABMISS,
};

enum csowmodes_e
{
	ATTACK_SLASH1 = 1,
	ATTACK_SLASH2,
	ATTACK_SLASH3,
	ATTACK_STAB
};

enum csowsounds_e
{
	SND_DRAW = 0,
	SND_HIT1,
	SND_HIT2,
	SND_HITWALL,
	SND_SLASH1,
	SND_SLASH2,
	SND_SLASH3,
	SND_STAB,
	SND_STABMISS
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/dualwaki_draw.wav",
	"custom_weapons/cso/dualwaki_hit1.wav",
	"custom_weapons/cso/dualwaki_hit2.wav",
	"custom_weapons/cso/mastercombat_wall.wav",
	"custom_weapons/cso/dualwaki_slash1.wav",
	"custom_weapons/cso/dualwaki_slash2.wav",
	"custom_weapons/cso/dualwaki_slash3.wav",
	"custom_weapons/cso/dualwaki_stab.wav",
	"custom_weapons/cso/dualwaki_stab_miss.wav"
};

class weapon_dualwaki : CBaseCustomWeapon
{
	private int m_iSlashingMode;
	private int m_iAttackMode;
	private float m_flDoubleSlashTime;
	private bool m_bDoDoubleSlash;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, CSOW_MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.m_flCustomDmg = pev.dmg;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( CSOW_MODEL_VIEW );
		g_Game.PrecacheModel( CSOW_MODEL_PLAYER );
		g_Game.PrecacheModel( CSOW_MODEL_WORLD );

		for( i = 0; i < pCSOWSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_dualwaki.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud73.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= CSO::DWAKI_SLOT - 1;
		info.iPosition		= CSO::DWAKI_POSITION - 1;
		info.iWeight		= CSOW_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;
		m_iSlashingMode = 0;
		m_flDoubleSlashTime = 0;
		m_bDoDoubleSlash = false;

		NetworkMessage dwaki( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			dwaki.WriteLong( g_ItemRegistry.GetIdForName("weapon_dualwaki") );
		dwaki.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( CSOW_MODEL_VIEW ), self.GetP_Model( CSOW_MODEL_PLAYER ), ANIM_DRAW, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal )
	{
		SetThink(null);
		m_flDoubleSlashTime = 0;
		m_bDoDoubleSlash = false;

		BaseClass.Holster( skipLocal );
	}

	~weapon_dualwaki()
	{
		SetThink(null);
		m_flDoubleSlashTime = 0;
		m_bDoDoubleSlash = false;
	}

	void PrimaryAttack()
	{
		if( m_iSlashingMode == 0 ) m_iSlashingMode = 1;

		m_iSlashingMode++;

		if( m_iSlashingMode > ATTACK_SLASH3 ) m_iSlashingMode = 1;

		switch( m_iSlashingMode )
		{
			case 1:
			{
				m_iAttackMode = ATTACK_SLASH1;

				m_pPlayer.pev.framerate = 0.75f; //??

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + SLASH_RESET_TIME;
				self.m_flTimeWeaponIdle = g_Engine.time + (SLASH_RESET_TIME + 0.5f);

				self.SendWeaponAnim( ANIM_SLASH1 );
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

				SetThink( ThinkFunction(this.Do_Slashing) );
				pev.nextthink = g_Engine.time + SLASH1_TIME;

				break;
			}

			case 2:
			{
				m_iAttackMode = ATTACK_SLASH2;

				m_pPlayer.pev.framerate = 1.0f; //??

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + SLASH_RESET_TIME;
				self.m_flTimeWeaponIdle = g_Engine.time + (SLASH_RESET_TIME + 0.5f);

				self.SendWeaponAnim( ANIM_SLASH2 );
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

				m_flDoubleSlashTime = g_Engine.time + SLASH2_TIME1;
				m_bDoDoubleSlash = true;

				break;
			}
		
			case 3:
			{
				m_iAttackMode = ATTACK_SLASH3;

				m_pPlayer.pev.framerate = 1.0f; //??

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + SLASH_RESET_TIME;
				self.m_flTimeWeaponIdle = g_Engine.time + (SLASH_RESET_TIME + 0.5f);

				self.SendWeaponAnim( ANIM_SLASH3 );
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

				m_flDoubleSlashTime = g_Engine.time + SLASH2_TIME1;
				m_bDoDoubleSlash = true;

				break;
			}
		}
	}

	void SecondaryAttack()
	{
		m_iAttackMode = ATTACK_STAB;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (STAB_TIME + 0.1f);
		self.m_flTimeWeaponIdle = g_Engine.time + (STAB_TIME + 0.6f);

		self.SendWeaponAnim( ANIM_STAB );

		SetThink( ThinkFunction(this.Do_StabNow) );
		pev.nextthink = g_Engine.time + STAB_TIME;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( CSOW_TIME_IDLE1, CSOW_TIME_IDLE2 );
	}

	void ItemPostFrame()
	{
		if( m_flDoubleSlashTime > 0 and g_Engine.time > m_flDoubleSlashTime )
		{
			Do_Slashing();

			if( m_bDoDoubleSlash )
			{
				m_bDoDoubleSlash = false;
				m_flDoubleSlashTime = g_Engine.time + SLASH2_TIME2;
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			}
			else m_flDoubleSlashTime = 0;
		}

		BaseClass.ItemPostFrame();
	}

	void Do_Slashing()
	{
		if( !m_pPlayer.IsAlive() ) return;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * SLASH_RADIUS;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0f )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0f )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null or pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0f )
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_SLASH1, SND_SLASH3)], 1, ATTN_NORM );
		else
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

			float flDamage = SLASH_DAMAGE;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();
			pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, (DMG_NEVERGIB|DMG_SLASH) ); //DMG_NEVERGIB|DMG_BULLET
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0f;
			bool bHitWorld = true;

			if( pEntity !is null )
			{
				if( pEntity.Classify() != CLASS_NONE and pEntity.Classify() != CLASS_MACHINE and pEntity.BloodColor() != DONT_BLEED )
				{
					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_HIT1, SND_HIT2)], 1, ATTN_NORM );

					m_pPlayer.m_iWeaponVolume = 128; 

					if( !pEntity.IsAlive() )
						return;
					else
						flVol = 0.1f;

					bHitWorld = false;
				}
			}

			if( bHitWorld )
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_HITWALL], VOL_NORM, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3) );

			m_pPlayer.m_iWeaponVolume = int(flVol * 512);
		}
	}

	void Do_StabNow()
	{
		if( !m_pPlayer.IsAlive() ) return;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + STAB_RESET_TIME;
		self.m_flTimeWeaponIdle = g_Engine.time + (STAB_RESET_TIME + 0.5f);

		Check_StabAttack();
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_iAttackMode = 0;
	}

	void Check_StabAttack()
	{
		array<Vector> vecPoints(4);

		float Point_Dis = STAB_RADIUS; //STAB_POINT_DIS;
		//float Point_Dis = STAB_POINT_DIS;
		float TB_Distance = STAB_RADIUS / 4.0f;

		Vector vecTargetOrigin, vecMyOrigin = m_pPlayer.pev.origin;

		for( int i = 0; i < 4; i++ ) get_position( TB_Distance * (i + 1), 0.0f, 0.0f, vecPoints[i] );

		bool bHitSomeone = false;

		CBaseEntity@ pTarget = null;

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.GetGunPosition()/*m_pPlayer.pev.origin*/, STAB_RADIUS, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or (!pTarget.IsMonster() and !pTarget.IsPlayer()) or !pTarget.IsAlive() )
				continue;

			//vecTargetOrigin = pTarget.pev.origin;
			vecTargetOrigin = pTarget.Center();

			if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

			if( (vecTargetOrigin - vecPoints[0]).Length() <= Point_Dis
			or (vecTargetOrigin - vecPoints[1]).Length() <= Point_Dis
			or (vecTargetOrigin - vecPoints[2]).Length() <= Point_Dis
			or (vecTargetOrigin - vecPoints[3]).Length() <= Point_Dis )
			{
				bHitSomeone = true;

				TraceResult tr;

				Math.MakeVectors( m_pPlayer.pev.v_angle );
				g_Utility.TraceLine( vecMyOrigin, vecTargetOrigin, dont_ignore_monsters, m_pPlayer.edict(), tr );

				g_WeaponFuncs.ClearMultiDamage();
				pTarget.TraceAttack( m_pPlayer.pev, STAB_DAMAGE, g_Engine.v_forward, tr, (DMG_NEVERGIB|DMG_SLASH) );
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}
		}

		if( bHitSomeone )
		{
			//this comment is here so that the if-else doesn't look like shit :joy:
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_STAB], VOL_NORM, ATTN_NORM );
		}
		else
		{
			vecMyOrigin.z += 26.0f;
			get_position( STAB_RADIUS - 5.0f, 0.0f, 0.0f, vecPoints[0] );

			TraceResult tr;

			g_Utility.TraceLine( vecMyOrigin, vecPoints[0], ignore_monsters, m_pPlayer.edict(), tr );

			if( (vecPoints[0] - tr.vecEndPos).Length() > 0 )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

				if( pEntity !is null and pEntity.IsBSPModel() ) //Deal damage to breakables
				{
					g_WeaponFuncs.ClearMultiDamage();
					pEntity.TraceAttack( m_pPlayer.pev, STAB_DAMAGE, g_Engine.v_forward, tr, (DMG_NEVERGIB|DMG_SLASH) );
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_HITWALL], VOL_NORM, ATTN_NORM );
			}
			else
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_STABMISS], VOL_NORM, ATTN_NORM );
		}
	}

	void get_position( float forw, float right, float up, Vector &out vOut )
	{
		Vector vOrigin, vAngle, vForward, vRight, vUp;

		vOrigin = m_pPlayer.pev.origin;
		vUp = m_pPlayer.pev.view_ofs; //for player, can also use GetGunPosition()
		vOrigin = vOrigin + vUp;
		vAngle = m_pPlayer.pev.v_angle; //if normal entity: use pev.angles

		g_EngineFuncs.AngleVectors( vAngle, vForward, vRight, vUp );

		vOut.x = vOrigin.x + vForward.x * forw + vRight.x * right + vUp.x * up;
		vOut.y = vOrigin.y + vForward.y * forw + vRight.y * right + vUp.y * up;
		vOut.z = vOrigin.z + vForward.z * forw + vRight.z * right + vUp.z * up;
	}

	bool is_wall_between_points( Vector start, Vector end, edict_t@ ignore_ent )
	{
		TraceResult ptr;

		g_Utility.TraceLine( start, end, ignore_monsters, ignore_ent, ptr );

		return (end - ptr.vecEndPos).Length() > 0;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_dualwaki::weapon_dualwaki", "weapon_dualwaki" );
	g_ItemRegistry.RegisterWeapon( "weapon_dualwaki", "custom_weapons/cso" );
}

} //namespace cso_dualwaki END
/*
Todo
Increase size of w_model
*/