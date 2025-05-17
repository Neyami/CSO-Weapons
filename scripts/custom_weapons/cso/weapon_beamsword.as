//Based on AMXX Plugin [CSO] LightSaber by Dias Leon
namespace cso_beamsword
{

const int CSOW_DAMAGE1						= 48; //62
const int CSOW_DAMAGE2						= 31;

const float CSOW_RADIUS_ON				= 96.0;
const float CSOW_RADIUS_OFF				= 72.0;
const float CSOW_TIME_DRAW				= 1.5; //0.75
const float CSOW_TIME_IDLE1				= 5.0; //Random number between these two
const float CSOW_TIME_IDLE2				= 10.0;
const float CSOW_TIME_DELAY_SWITCH	= 0.5;

const string CSOW_ANIMEXT1				= "onehanded";
const string CSOW_ANIMEXT2				= "crowbar";

const string MODEL_VIEW						= "models/custom_weapons/cso/v_sfsword.mdl";
const string MODEL_PLAYER_ON				= "models/custom_weapons/cso/p_sfsword_on.mdl";
const string MODEL_PLAYER_OFF			= "models/custom_weapons/cso/p_sfsword_off.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/w_sfsword.mdl";

const int CSOW_LIGHT_RADIUS				= 14;
//255 241 80		255 240 40		210 199 0
const int CSOW_LIGHT_R						= 255;
const int CSOW_LIGHT_G						= 240;
const int CSOW_LIGHT_B						= 40;
const int CSOW_LIGHT_LIFE					= 2;
const float CSOW_LIGHT_RATE				= 0.05; //How often the light from the sword gets updated

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_TURNON,
	ANIM_TURNOFF,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STAB_MISS,
	ANIM_MIDSLASH1,
	ANIM_MIDSLASH2,
	ANIM_IDLE_OFF,
	ANIM_SLASH_OFF
};

enum csowsounds_e
{
	SND_DRAW = 0,
	SND_HIT1,
	SND_HIT2,
	SND_IDLE,
	SND_MIDSLASH1,
	SND_MIDSLASH2, //5
	SND_MIDSLASH3,
	SND_OFF,
	SND_OFF_HIT,
	SND_OFF_SLASH,
	SND_ON, //10
	SND_STAB,
	SND_WALL1,
	SND_WALL2,
	SND_OFF_WALL1,
	SND_OFF_WALL2
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/sfsword_draw.wav",
	"custom_weapons/cso/sfsword_hit1.wav",
	"custom_weapons/cso/sfsword_hit2.wav",
	"custom_weapons/cso/sfsword_idle.wav",
	"custom_weapons/cso/sfsword_midslash1.wav",
	"custom_weapons/cso/sfsword_midslash2.wav",
	"custom_weapons/cso/sfsword_midslash3.wav",
	"custom_weapons/cso/sfsword_off.wav",
	"custom_weapons/cso/sfsword_off_hit.wav",
	"custom_weapons/cso/sfsword_off_slash1.wav",
	"custom_weapons/cso/sfsword_on.wav",
	"custom_weapons/cso/sfsword_stab.wav",
	"custom_weapons/cso/sfsword_wall1.wav",
	"custom_weapons/cso/sfsword_wall2.wav",
	"weapons/knife_hit_wall1.wav",
	"weapons/knife_hit_wall2.wav"
};

enum csowmode_e
{
	MODE_OFF = 0,
	MODE_ON
};

class weapon_beamsword : CBaseCSOWeapon
{
	private int m_iMode;
	private int m_iAttackType;
	private bool m_bInSpecialAttack;
	private float m_flNextDLight;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.m_flCustomDmg		= self.pev.dmg;

		m_iMode = MODE_ON;
		m_iAttackType = 0;
		m_bInSpecialAttack = false;
		m_flNextDLight = 0.0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_ON );
		g_Game.PrecacheModel( MODEL_PLAYER_OFF );
		g_Game.PrecacheModel( MODEL_WORLD );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_beamsword.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud87.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= cso::BEAMSWORD_SLOT - 1;
		info.iPosition		= cso::BEAMSWORD_POSITION - 1;
		info.iWeight		= cso::BEAMSWORD_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_beamsword") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER_ON), ANIM_DRAW, CSOW_ANIMEXT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], 0.5, ATTN_NORM );
			m_flNextDLight = g_Engine.time + 0.1;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );
		m_iMode = MODE_ON;
		m_iAttackType = 0;
		m_bInSpecialAttack = false;

		SetThink( null );
	}

	void PrimaryAttack()
	{
		if( m_iMode == MODE_ON )
		{
			if( !m_bInSpecialAttack )
			{
				m_iAttackType++;
				if( m_iAttackType > 2 ) m_iAttackType = 0;

				m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT2;

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 1.0;
				self.m_flTimeWeaponIdle = g_Engine.time + 1.5;

				int iSound;
				if( m_iAttackType == 0 )
				{
					self.SendWeaponAnim( ANIM_MIDSLASH1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					iSound = SND_MIDSLASH1;
				}
				else if( m_iAttackType == 1 )
				{
					self.SendWeaponAnim( ANIM_MIDSLASH2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					iSound = SND_MIDSLASH2;
				}
				else if( m_iAttackType == 2 )
				{
					self.SendWeaponAnim( ANIM_MIDSLASH1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					iSound = SND_MIDSLASH3;
				}

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[iSound], VOL_NORM, ATTN_NORM );

				SetThink( ThinkFunction(this.DamageSlash) );
				pev.nextthink = g_Engine.time + 0.25;

				m_bInSpecialAttack = true;
			}
			else
			{
				m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT2;

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 1.0;
				self.m_flTimeWeaponIdle = g_Engine.time + 1.5;

				self.SendWeaponAnim( ANIM_STAB, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_STAB], VOL_NORM, ATTN_NORM );

				SetThink( ThinkFunction(this.DamageStab) );
				pev.nextthink = g_Engine.time + 0.25;
			}
		}
		else
		{
			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT2;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 1.0;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.5;

			self.SendWeaponAnim( ANIM_SLASH_OFF, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_OFF_SLASH], VOL_NORM, ATTN_NORM );

			SetThink( ThinkFunction(this.DamageOff) );
			pev.nextthink = g_Engine.time + 0.25;

			m_bInSpecialAttack = false;
		}
	}

	void DamageSlash()
	{
		float flDamage = CSOW_DAMAGE1;

		if( self.m_flCustomDmg > 0 ) flDamage = self.m_flCustomDmg;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

		int iTarget = MeleeAttack( CSOW_RADIUS_ON, flDamage );
		if( iTarget == HIT_ENEMY ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_HIT1, SND_HIT2)], VOL_NORM, ATTN_NORM );
		else if( iTarget == HIT_WALL ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_WALL1, SND_WALL2)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.ResetAnim) );
		pev.nextthink = g_Engine.time + 1.25;
	}

	void DamageStab()
	{
		float flDamage = CSOW_DAMAGE1;

		if( self.m_flCustomDmg > 0 ) flDamage = self.m_flCustomDmg;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

		int iTarget = MeleeAttack( CSOW_RADIUS_ON, flDamage );
		if( iTarget == HIT_ENEMY ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_HIT1, SND_HIT2)], VOL_NORM, ATTN_NORM );
		else if( iTarget == HIT_WALL ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_WALL1, SND_WALL2)], VOL_NORM, ATTN_NORM );

		if( m_bInSpecialAttack )
		{
			m_bInSpecialAttack = false;
			pev.nextthink = g_Engine.time + 0.25;
			return;
		}

		SetThink( ThinkFunction(this.ResetAnim) );
		pev.nextthink = g_Engine.time + 1.25;
	}

	void DamageOff()
	{
		float flDamage = CSOW_DAMAGE2;

		if( self.m_flCustomDmg > 0 ) flDamage = self.m_flCustomDmg;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

		int iTarget = MeleeAttack( CSOW_RADIUS_OFF, flDamage );
		if( iTarget == HIT_ENEMY ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_OFF_HIT], VOL_NORM, ATTN_NORM );
		else if( iTarget == HIT_WALL ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_OFF_WALL1, SND_OFF_WALL2)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.ResetAnim) );
		pev.nextthink = g_Engine.time + 1.25;
	}

	int MeleeAttack( float flRadius, float flDamage )
	{
		float flMaxDistance, flTBDistance;

		flMaxDistance = flRadius;
		flTBDistance = flMaxDistance / 4.0;

		Vector vecTargetOrigin, vecMyOrigin;
		vecMyOrigin = m_pPlayer.pev.origin;

		int iHitSomething = HIT_NOTHING;
		CBaseEntity@ pTarget = null;

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, flRadius, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or (!pTarget.IsMonster() and !pTarget.IsPlayer()) or !pTarget.IsAlive() )
				continue;

			if( !m_pPlayer.FInViewCone(pTarget) ) continue;

			vecTargetOrigin = pTarget.pev.origin + Vector( 0, 0, (pTarget.pev.size.z/2) );

			if( (m_pPlayer.pev.origin - vecTargetOrigin).Length() > flMaxDistance ) continue;

			vecTargetOrigin = pTarget.pev.origin;

			if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

			iHitSomething = HIT_ENEMY;

			pTarget.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, flDamage, DMG_ENERGYBEAM | DMG_BURN ); 
		}

		if( iHitSomething != HIT_ENEMY )
		{
			Vector vecWallCheck;
			vecMyOrigin.z += 26.0;
			get_position( flRadius - 5.0, 0.0, 0.0, vecWallCheck );

			TraceResult tr;
			g_Utility.TraceLine( vecMyOrigin, vecWallCheck, ignore_monsters, m_pPlayer.edict(), tr );

			if( (vecWallCheck - tr.vecEndPos).Length() > 0 )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

				if( pEntity !is null and pEntity.IsBSPModel() )
				{
					g_WeaponFuncs.ClearMultiDamage();
					pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_ENERGYBEAM | DMG_BURN );
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}

				iHitSomething = HIT_WALL;
			}
		}

		return iHitSomething;
	}

	void ResetAnim()
	{
		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT1;
	}

	void SecondaryAttack()
	{
		self.SendWeaponAnim( m_iMode == MODE_ON ? ANIM_TURNOFF : ANIM_TURNON, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + CSOW_TIME_DELAY_SWITCH;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY_SWITCH + 0.5;

		SetThink( ThinkFunction(this.SwitchThink) );
		pev.nextthink = g_Engine.time + (CSOW_TIME_DELAY_SWITCH - 0.1);
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( m_iMode == MODE_ON ? ANIM_IDLE : ANIM_IDLE_OFF, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		if( m_iMode == MODE_ON )
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], 0.5, ATTN_NORM );

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( CSOW_TIME_IDLE1, CSOW_TIME_IDLE2 );
	}

	void ItemPostFrame()
	{
		if( m_iMode == MODE_ON )
		{
			if( m_flNextDLight > 0.0 and m_flNextDLight < g_Engine.time )
			{
				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_DLIGHT );
					m1.WriteCoord( m_pPlayer.GetGunPosition().x );
					m1.WriteCoord( m_pPlayer.GetGunPosition().y );
					m1.WriteCoord( m_pPlayer.GetGunPosition().z );
					m1.WriteByte( CSOW_LIGHT_RADIUS );//radius
					m1.WriteByte( CSOW_LIGHT_R );
					m1.WriteByte( CSOW_LIGHT_G );
					m1.WriteByte( CSOW_LIGHT_B );
					m1.WriteByte( CSOW_LIGHT_LIFE );//life
					m1.WriteByte( 0 );//decay
				m1.End();

				m_flNextDLight = g_Engine.time + CSOW_LIGHT_RATE;
			}
		}

		BaseClass.ItemPostFrame();
	}

	void SwitchThink()
	{
		if( m_iMode == MODE_ON )
		{
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );
			m_iMode = MODE_OFF;
			m_flNextDLight = 0.0;
		}
		else
		{
			m_iMode = MODE_ON;
			m_flNextDLight = g_Engine.time + 0.1;
		}

		m_pPlayer.pev.weaponmodel = m_iMode == MODE_ON ? MODEL_PLAYER_ON : MODEL_PLAYER_OFF;
		m_pPlayer.m_szAnimExtension = m_iMode == MODE_ON ? CSOW_ANIMEXT1 : CSOW_ANIMEXT2;
		SetThink( null );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_beamsword::weapon_beamsword", "weapon_beamsword" );
	g_ItemRegistry.RegisterWeapon( "weapon_beamsword", "custom_weapons/cso" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_beamsword END

/*
TODO
Fix p_model texture alignment?
Increase movement speed when off?
*/