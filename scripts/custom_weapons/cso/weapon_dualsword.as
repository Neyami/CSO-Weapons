//Skillfx based on AMXX plugin by DarkNemessis

namespace cso_dualsword
{

const float CSOW_DAMAGE_STAB1			= 35.0;
const float CSOW_DAMAGE_STAB2			= 50.0;
const float CSOW_RANGE_STAB1			= 145.0;
const float CSOW_RANGE_STAB2			= 150.0;
const float CSOW_RADIUS_STAB				= 90.0;

const float CSOW_DAMAGE_SLASH1		= 15.0;
const float CSOW_DAMAGE_SLASH2		= 17.0;
const float CSOW_DAMAGE_SLASH3		= 45.0;
const float CSOW_DAMAGE_SLASH4		= 60.0;
const float CSOW_RANGE_SLASH			= 95.0;
const float CSOW_RADIUS_SLASH			= 120.0;

const float CSOW_SKILL_DAMAGE			= 19.0; //419 in CSO, WAY too high :ayaya:
const float CSOW_SKILL_DMG_FREQ		= 0.25;
const float CSOW_SKILL_RADIUS			= cso::MetersToUnits(5);
const float CSOW_SKILL_SOUND_FREQ	= 0.088;

const float CSOW_TIME_DRAW				= 0.2;
const float CSOW_TIME_DELAY1				= 1.0;
const float CSOW_TIME_DELAY2				= 1.2;
const float CSOW_TIME_IDLEA				= 3.0;
const float CSOW_TIME_IDLEB				= 4.0;
const float CSOW_TIME_SKILL_RESET	= 2.0;
const float CSOW_TIME_SKILL_LOOP		= 11.8;


const string MODEL_VIEW						= "models/custom_weapons/cso/v_dualsword.mdl";
const string MODEL_PLAYER_A				= "models/custom_weapons/cso/p_dualsword_a.mdl";
const string MODEL_PLAYER_B				= "models/custom_weapons/cso/p_dualsword_b.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/w_dualsword.mdl";
const string MODEL_SLASH						= "models/custom_weapons/cso/dualswordfx.mdl";
const string MODEL_SKILL						= "models/custom_weapons/cso/dualsword_skill.mdl";
const string MODEL_SKILLFX1					= "models/custom_weapons/cso/dualsword_skillfx1.mdl";
const string MODEL_SKILLFX2					= "models/custom_weapons/cso/dualsword_skillfx2.mdl";

const string SPRITE_HIT_STAB1				= "sprites/custom_weapons/cso/leaf01_dualsword.spr";
const string SPRITE_HIT_STAB2				= "sprites/custom_weapons/cso/leaf02_dualsword.spr";
const string SPRITE_HIT_SLASH1			= "sprites/custom_weapons/cso/petal01_dualsword.spr";
const string SPRITE_HIT_SLASH2			= "sprites/custom_weapons/cso/petal02_dualsword.spr";

const string CSOW_ANIMEXT1					= "onehanded";
const string CSOW_ANIMEXT2					= "crowbar";

enum csow_e
{
	ANIM_IDLE_A = 0,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_SLASH4,
	ANIM_SLASH_END, //5
	ANIM_DRAW_A,
	ANIM_IDLE_B,
	ANIM_STAB1,
	ANIM_STAB2,
	ANIM_STAB_END, //10
	ANIM_DRAW_B,
	ANIM_SWAP_TO_B,
	ANIM_SWAP_TO_A,
	ANIM_SKILL_START,
	ANIM_SKILL_LOOP //15
};

enum csowsounds_e
{
	SND_FLY1 = 0,
	SND_FLY2,
	SND_FLY3,
	SND_FLY4,
	SND_FLY5,
	SND_HIT1, //5
	SND_HIT2,
	SND_HIT3,
	SND_IDLE_A,
	SND_IDLE_B,
	SND_SKILL_END, //10
	SND_SKILL_START,
	SND_SLASH1,
	SND_SLASH2,
	SND_SLASH3,
	SND_SLASH4, //15
	SND_SLASH_TWINKLE,
	SND_SKILL_TRIGGER,
	SND_STAB1,
	SND_STAB1_HIT,
	SND_STAB2, //20
	SND_STAB2_HIT,
	SND_HIT_WALL
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/dualsword_fly1.wav",
	"custom_weapons/cso/dualsword_fly2.wav",
	"custom_weapons/cso/dualsword_fly3.wav",
	"custom_weapons/cso/dualsword_fly4.wav",
	"custom_weapons/cso/dualsword_fly5.wav",
	"custom_weapons/cso/dualsword_hit1.wav",
	"custom_weapons/cso/dualsword_hit2.wav",
	"custom_weapons/cso/dualsword_hit3.wav",
	"custom_weapons/cso/dualsword_idle_a.wav",
	"custom_weapons/cso/dualsword_idle_b.wav",
	"custom_weapons/cso/dualsword_skill_end.wav",
	"custom_weapons/cso/dualsword_skill_start.wav",
	"custom_weapons/cso/dualsword_slash_1.wav",
	"custom_weapons/cso/dualsword_slash_2.wav",
	"custom_weapons/cso/dualsword_slash_3.wav",
	"custom_weapons/cso/dualsword_slash_4.wav",
	"custom_weapons/cso/dualsword_slash_4_1.wav",
	"custom_weapons/cso/dualsword_slash_4_2.wav",
	"custom_weapons/cso/dualsword_stab1.wav",
	"custom_weapons/cso/dualsword_stab1_hit.wav",
	"custom_weapons/cso/dualsword_stab2.wav",
	"custom_weapons/cso/dualsword_stab2_hit.wav",
	"custom_weapons/cso/mastercombat_wall.wav",
	"custom_weapons/cso/dualsword_slash_end.wav",
	"custom_weapons/cso/dualsword_stab_end.wav",
	"custom_weapons/cso/dualsword_skill_loop_end.wav"
};

enum csowstate_e
{
	STATE_NONE = 0,
	STATE_STAB,
	STATE_SLASH,
	STATE_SKILL_START,
	STATE_SKILL_LOOP,
	STATE_SKILL_END
};

enum csowmode_e
{
	MODE_SLASH = 0,
	MODE_STAB
};

enum csoweffect_e
{
	EFFECT_SKILL_START = 0,
	EFFECT_SKILL_END,
	EFFECT_SKILLFX1,
	EFFECT_SKILLFX2
};

enum csowcombo_e
{
	COMBO_STAB1 = 0,
	COMBO_STAB2,
	COMBO_SLASH_START,
	COMBO_SLASH_END
};

class weapon_dualsword : CBaseCSOWeapon
{
	private int m_iState;
	private int m_iMode;
	private int m_iStabState;
	private int m_iSlashState;
	private int m_iComboState;
	private float m_flSlashSound;
	private float m_flComboReset;
	private float m_flSkillStart;
	private float m_flSkillEnd;
	private float m_flSkillSound;
	private float m_flSkillDealDamage;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.m_flCustomDmg		= self.pev.dmg;

		m_iWeaponType = TYPE_MELEE;
		m_iState = STATE_NONE;
		m_iMode = MODE_STAB;
		m_iStabState = 0;
		m_iSlashState = 0;
		m_iComboState = 0;
		m_flComboReset = 0.0;
		m_flSkillStart = 0.0;
		m_flSkillSound = 0.0;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_A );
		g_Game.PrecacheModel( MODEL_PLAYER_B );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_SLASH );
		g_Game.PrecacheModel( MODEL_SKILL );
		g_Game.PrecacheModel( MODEL_SKILLFX1 );
		g_Game.PrecacheModel( MODEL_SKILLFX2 );

		g_Game.PrecacheModel( SPRITE_HIT_STAB1 );
		g_Game.PrecacheModel( SPRITE_HIT_STAB2 );
		g_Game.PrecacheModel( SPRITE_HIT_SLASH1 );
		g_Game.PrecacheModel( SPRITE_HIT_SLASH2 );
		g_Game.PrecacheModel( "sprites/blood.spr" );
		g_Game.PrecacheModel( "sprites/bloodspray.spr" );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_dualsword.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud162.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= cso::DUALSWORD_SLOT - 1;
		info.iPosition		= cso::DUALSWORD_POSITION - 1;
		info.iWeight		= cso::DUALSWORD_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_dualsword") );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model((m_iMode == MODE_SLASH) ? MODEL_PLAYER_A : MODEL_PLAYER_B), (m_iMode == MODE_SLASH) ? ANIM_DRAW_A : ANIM_DRAW_B, CSOW_ANIMEXT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		StopIdleSound();
		m_iState = STATE_NONE;
		m_iStabState = 0;
		m_iSlashState = 0;
		m_iComboState = 0;
		m_flComboReset = 0.0;
		m_flSkillStart = 0.0;
		m_flSkillSound = 0.0;
		m_flSkillDealDamage = 0.0;

		SetThink( null );
	}

	void PrimaryAttack()
	{
		m_pPlayer.pev.viewmodel = MODEL_VIEW;
		m_pPlayer.pev.weaponmodel = MODEL_PLAYER_B;
		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT2;
		SetThink( null );
		StopIdleSound();
		m_iSlashState = 0;

		if( m_iStabState >= 2 ) m_iStabState = 0;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[(m_iStabState == 0) ? SND_STAB1 : SND_STAB2], VOL_NORM, ATTN_NORM );
		self.SendWeaponAnim( ANIM_STAB1 + m_iStabState, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_iStabState++;

		m_iState = STATE_STAB;
		m_iMode = MODE_STAB;

		SetThink( ThinkFunction(this.StabThink) );
		pev.nextthink = g_Engine.time + 0.2;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.4;
		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
	}

	void StabThink()
	{
		SetThink( ThinkFunction(this.StabEndThink) );

		if( m_iStabState == 1 )
		{
			ComboCheck( COMBO_STAB1 );
			CheckMeleeAttack( CSOW_RANGE_STAB1, CSOW_RADIUS_STAB, CSOW_DAMAGE_STAB1, 1 );

			pev.nextthink = g_Engine.time + 0.5;
		}
		else if( m_iStabState == 2 )
		{
			ComboCheck( COMBO_STAB2 );
			CheckMeleeAttack( CSOW_RANGE_STAB2, CSOW_RADIUS_STAB, CSOW_DAMAGE_STAB2, 2 );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.8;
			pev.nextthink = g_Engine.time + 0.7;
		}
	}

	void StabEndThink()
	{
		self.SendWeaponAnim( ANIM_STAB_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + 1.4;

		SetThink( null );
		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT1;
	}

	void SecondaryAttack()
	{
		m_pPlayer.pev.weaponmodel = MODEL_PLAYER_A;
		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT2;
		ComboCheck( COMBO_SLASH_START );
		StopIdleSound();

		m_iStabState = 0;
		m_iSlashState = 0;
		m_iState = STATE_SLASH;

		m_iMode = MODE_SLASH;

		SetThink( ThinkFunction(this.SlashThink) );
		pev.nextthink = g_Engine.time + 0.1;

		self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
		self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
		self.m_flTimeWeaponIdle = g_Engine.time + 3.4;
	}

	void SlashThink()
	{
		m_pPlayer.pev.viewmodel = MODEL_SLASH;
		self.SendWeaponAnim( m_iSlashState, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		m_iSlashState++;

		if( m_iSlashState >= 0 and m_iSlashState <= 3 )
		{
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			CheckMeleeAttack( CSOW_RANGE_SLASH, CSOW_RADIUS_SLASH, CSOW_DAMAGE_SLASH1+(m_iSlashState-1) );

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SLASH1+(m_iSlashState -1)], VOL_NORM, ATTN_NORM );
			pev.nextthink = g_Engine.time + 0.15;
		}
		else if( m_iSlashState == 4 )
		{
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			ComboCheck( COMBO_SLASH_END );

			CheckMeleeAttack( CSOW_RANGE_SLASH, CSOW_RADIUS_SLASH, CSOW_DAMAGE_SLASH4 );

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SLASH4], VOL_NORM, ATTN_NORM );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.6;
			pev.nextthink = g_Engine.time + 0.9;
			m_flSlashSound = g_Engine.time + 0.5;
		}
		else if( m_iSlashState == 5 )
		{
			pev.nextthink = g_Engine.time + 0.5;
			SetThink( null );
			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT1;
			m_pPlayer.pev.viewmodel = MODEL_VIEW;
			self.SendWeaponAnim( ANIM_SLASH_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}

	void CheckMeleeAttack( float flRange, float flRadius, float flDamage, int iStab = 0 )
	{
		int iTarget = MeleeAttack( flRange, flRadius, flDamage, iStab );

		if( iTarget == HIT_ENEMY )
		{
			int iHitSound;

			if( iStab == 0 ) iHitSound = Math.RandomLong( SND_HIT1, SND_HIT3 );
			else if( iStab == 1 ) iHitSound = SND_STAB1_HIT;
			else if( iStab == 2 ) iHitSound = SND_STAB2_HIT;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[iHitSound], VOL_NORM, ATTN_NORM );
		}
		else if( iTarget == HIT_WALL ) g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_HIT_WALL], VOL_NORM, ATTN_NORM );
	}

	int MeleeAttack( float flRange, float flRadius, float flDamage, int iStab = 0 )
	{
		Vector vecTargetOrigin, vecMyOrigin;
		vecMyOrigin = m_pPlayer.pev.origin;

		int iHitSomething = HIT_NOTHING;

		Vector vecWallCheck;
		vecMyOrigin.z += 26.0f;
		get_position( flRange, 0.0, 0.0, vecWallCheck );

		TraceResult tr;
		g_Utility.TraceLine( vecMyOrigin, vecWallCheck, dont_ignore_monsters, m_pPlayer.edict(), tr );

		CBaseEntity@ pFirstTarget = null;
		if( (vecWallCheck - tr.vecEndPos).Length() > 0 )
		{
			@pFirstTarget = g_EntityFuncs.Instance(tr.pHit);

			if( pFirstTarget !is null )
			{
				if( pFirstTarget.pev.takedamage != DAMAGE_NO )
				{
					g_WeaponFuncs.ClearMultiDamage();
					pFirstTarget.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH | DMG_NEVERGIB );
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}

				if( pFirstTarget.IsBSPModel() )
					iHitSomething = HIT_WALL;
				else if( pFirstTarget.edict() !is m_pPlayer.edict() and pFirstTarget.pev.FlagBitSet(FL_MONSTER) and !pFirstTarget.pev.FlagBitSet(FL_CLIENT) and pFirstTarget.IsAlive() )
					iHitSomething = HIT_ENEMY;
			}

			for( int i = 0; i < 5; ++i )
				HitEffect( tr.vecEndPos, iStab, iHitSomething );
		}

		CBaseEntity@ pTarget = null;
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, flRadius*4, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or !pTarget.pev.FlagBitSet(FL_MONSTER) or pTarget.pev.FlagBitSet(FL_CLIENT) or !pTarget.IsAlive() or (pFirstTarget !is null and pTarget is pFirstTarget) )
				continue;

			if( iStab > 0 )
				m_pPlayer.m_flFieldOfView = VIEW_FIELD_ULTRA_NARROW;

			if( !m_pPlayer.FInViewCone(pTarget) ) continue;

			m_pPlayer.m_flFieldOfView = 0.5;

			vecTargetOrigin = pTarget.pev.origin + Vector( 0, 0, (pTarget.pev.size.z/2) );

			if( (m_pPlayer.pev.origin - vecTargetOrigin).Length() > flRange ) continue;

			vecTargetOrigin = pTarget.pev.origin;

			if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

			iHitSomething = HIT_ENEMY;

			//pTarget.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, flDamage, DMG_SLASH | DMG_NEVERGIB );

			g_Utility.TraceLine( pTarget.Center(), pTarget.Center(), ignore_monsters, m_pPlayer.edict(), tr );

			g_WeaponFuncs.ClearMultiDamage();
			pTarget.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH | DMG_NEVERGIB );
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			for( int i = 0; i < 5; ++i )
				HitEffect( pTarget.Center(), iStab, iHitSomething );
		}

		if( iHitSomething != HIT_ENEMY )
		{

		}

		return iHitSomething;
	}

	void ComboCheck( int iAttack )
	{
		if( iAttack == COMBO_STAB1 )
		{
			if( m_iComboState == 0 )
			{
				m_iComboState = 1;
				m_flComboReset = g_Engine.time + CSOW_TIME_SKILL_RESET;
			}
			else if( m_iComboState == 2 )
			{
				m_iComboState = 3;
				m_flComboReset = g_Engine.time + CSOW_TIME_SKILL_RESET;
			}
			else if( m_iComboState != 0 )
			{
				m_iComboState = 0;
				m_flComboReset = 0.0;
				//g_Game.AlertMessage( at_notice, "COMBO STATE RESET: Wrong button pushed!\n" );
			}
		}
		else if( iAttack == COMBO_STAB2 )
		{
			if( m_iComboState == 3 )
			{
				m_iComboState = 4;
				m_flComboReset = g_Engine.time + CSOW_TIME_SKILL_RESET;
			}
			else if( m_iComboState != 0 )
			{
				m_iComboState = 0;
				m_flComboReset = 0.0;
				//g_Game.AlertMessage( at_notice, "COMBO STATE RESET: Wrong button pushed!\n" );
			}
		}
		else if( iAttack == COMBO_SLASH_START )
		{
			if( m_iComboState > 0 )
			{
				if( m_iComboState != 1 and m_iComboState != 4 )
				{
					m_iComboState = 0;
					m_flComboReset = 0.0;
					//g_Game.AlertMessage( at_notice, "COMBO STATE RESET: Wrong button pushed!\n" );
				}
			}
		}
		else if( iAttack == COMBO_SLASH_END )
		{
			if( m_iComboState == 1 )
			{
				m_iComboState = 2;
				m_flComboReset = g_Engine.time + CSOW_TIME_SKILL_RESET;
			}
			else if( m_iComboState == 4 )
			{
				m_flComboReset = 0.0;
				m_flSkillStart = g_Engine.time + 0.4;
			}
			else if( m_iComboState != 0 )
			{
				m_iComboState = 0;
				m_flComboReset = 0.0;
				//g_Game.AlertMessage( at_notice, "COMBO STATE RESET: Wrong button pushed!\n" );
			}
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT1;
		m_iState = STATE_NONE;
		m_iStabState = 0;
		m_iComboState = 0;
		m_flComboReset = 0.0;

		self.SendWeaponAnim( (m_iMode == MODE_SLASH) ? ANIM_IDLE_A : ANIM_IDLE_B, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + ((m_iMode == MODE_SLASH) ? CSOW_TIME_IDLEA : CSOW_TIME_IDLEB);
	}

	void ItemPostFrame()
	{
		if( m_flSlashSound > 0.0 and m_flSlashSound < g_Engine.time)
		{
			int iSound = SND_SLASH_TWINKLE;
			if( m_iComboState == 4 ) iSound = SND_SKILL_TRIGGER;

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[iSound], VOL_NORM, ATTN_NORM );
			m_flSlashSound = 0.0;
		}

		if( m_flComboReset > 0.0 and m_flComboReset < g_Engine.time )
		{
			m_iComboState = 0;
			m_flComboReset = 0.0;
			//g_Game.AlertMessage( at_notice, "COMBO STATE RESET: You took too long!\n" );
		}

		if( m_flSkillStart > 0.0 and m_flSkillStart < g_Engine.time )
		{
			m_flSkillStart = 0.0;
			SkillStart();
		}

		BaseClass.ItemPostFrame();
	}

	void StopIdleSound()
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[(m_iMode == MODE_SLASH) ? SND_IDLE_A : SND_IDLE_B] );
	}

	void SkillStart()
	{
		m_iState = STATE_SKILL_START;

		m_pPlayer.pev.viewmodel = MODEL_VIEW;
		self.SendWeaponAnim( ANIM_SKILL_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_SKILL_LOOP + 1.30;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_SKILL_LOOP + 1.30;

		Vector vecOrigin = m_pPlayer.pev.origin;
		vecOrigin.z -= 25.0;

		CBaseEntity@ cbeSlashEffect = g_EntityFuncs.Create( "ef_dualsword", vecOrigin, g_vecZero, true, m_pPlayer.edict() );
		ef_dualsword@ pSkillEffect = cast<ef_dualsword@>(CastToScriptClass(cbeSlashEffect));
		pSkillEffect.m_iEffectType = EFFECT_SKILL_START;
		pSkillEffect.m_flKillTime = g_Engine.time + 1.5;
		pSkillEffect.m_ePlayer = EHandle(m_pPlayer);
		pSkillEffect.m_eWeapon = EHandle(self);
		g_EntityFuncs.DispatchSpawn( pSkillEffect.self.edict() );

		m_flSkillEnd = g_Engine.time + CSOW_TIME_SKILL_LOOP;
		SetThink( ThinkFunction(this.SkillPrepareThink) );
		pev.nextthink = g_Engine.time + 1.0;
	}

	void SkillPrepareThink()
	{
		if( m_iState != STATE_SKILL_LOOP ) self.SendWeaponAnim( ANIM_SKILL_LOOP, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		m_iState = STATE_SKILL_LOOP;

		SetThink( ThinkFunction(this.SkillThink) );
		pev.nextthink = m_flSkillSound = m_flSkillDealDamage = g_Engine.time + 0.7;
	}

	void SkillThink()
	{
		if( m_flSkillEnd > 0.0 and m_flSkillEnd < g_Engine.time )
		{
			m_flSkillEnd = 0.0;
			SetThink(null);
			SkillEnd();
			return;
		}

		if( m_flSkillDealDamage > 0.0 and m_flSkillDealDamage < g_Engine.time )
		{
			CBaseEntity@ pTarget = null;
			while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, CSOW_SKILL_RADIUS, "*", "classname")) !is null )
			{
				if( pTarget.edict() is m_pPlayer.edict() or !pTarget.pev.FlagBitSet(FL_MONSTER) or pTarget.pev.FlagBitSet(FL_CLIENT) or !pTarget.IsAlive() )
					continue;

				Vector vecMyOrigin = m_pPlayer.GetGunPosition();
				Vector vecTargetOrigin = pTarget.pev.origin + Vector( 0, 0, (pTarget.pev.size.z*0.9) );

				if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

				//pTarget.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, CSOW_SKILL_DAMAGE, DMG_SLASH | DMG_NEVERGIB );

				TraceResult tr;
				g_Utility.TraceLine( pTarget.Center(), pTarget.Center(), ignore_monsters, m_pPlayer.edict(), tr );

				g_WeaponFuncs.ClearMultiDamage();
				pTarget.TraceAttack( m_pPlayer.pev, CSOW_SKILL_DAMAGE, g_Engine.v_forward, tr, DMG_SLASH | DMG_NEVERGIB );
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_BLOODSPRITE );
					m1.WriteCoord( vecTargetOrigin.x );
					m1.WriteCoord( vecTargetOrigin.y );
					m1.WriteCoord( vecTargetOrigin.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/bloodspray.spr") );
					m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/blood.spr") );
					m1.WriteByte( 75 ); //color, default: 75
					m1.WriteByte( 15 ); //scale, default: 5
				m1.End();
			}

			m_flSkillDealDamage = g_Engine.time + CSOW_SKILL_DMG_FREQ;
		}

		array<Vector> vecOrigin3(2);
		Vector vecOrigin;

		vecOrigin = vecOrigin3[0] = vecOrigin3[1] = m_pPlayer.pev.origin;

		float flFloat = Math.RandomFloat( CSOW_SKILL_RADIUS * -0.85, CSOW_SKILL_RADIUS * 0.85 );
		vecOrigin3[0].z = vecOrigin3[1].z = vecOrigin3[0].z + Math.RandomFloat( -5.0, 65.0 );

		switch( Math.RandomLong(0, 3) )
		{
			case 0:
			{
				vecOrigin3[0].x += flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[0].y += flFloat * Math.RandomFloat( -1.0, 1.0 );
				
				vecOrigin3[1].x -= flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[1].y -= flFloat * Math.RandomFloat( -1.0, 1.0 );

				break;
			}
			case 1:
			{
				vecOrigin3[0].x += flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[0].y -= flFloat * Math.RandomFloat( -1.0, 1.0 );
				
				vecOrigin3[1].x -= flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[1].y += flFloat * Math.RandomFloat( -1.0, 1.0 );

				break;
			}
			case 2:
			{
				vecOrigin3[0].x -= flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[0].y += flFloat * Math.RandomFloat( -1.0, 1.0 );
				
				vecOrigin3[1].x += flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[1].y -= flFloat * Math.RandomFloat( -1.0, 1.0 );

				break;
			}
			case 3:
			{
				vecOrigin3[0].x -= flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[0].y -= flFloat * Math.RandomFloat( -1.0, 1.0 );
				
				vecOrigin3[1].x += flFloat * Math.RandomFloat( -1.0, 1.0 );
				vecOrigin3[1].y += flFloat * Math.RandomFloat( -1.0, 1.0 );

				break;
			}
		}

		if( Math.RandomLong(0, 9) > 8 )
		{
			Vector vecAngle2;
			vecAngle2.x = ( Math.RandomLong(0, 1) == 1) ? Math.RandomFloat(-30.0, -15.0) : Math.RandomFloat(15.0, 30.0);
			vecAngle2.y = ( Math.RandomLong(0, 1) == 1) ? Math.RandomFloat(-180.0, 0.0) : Math.RandomFloat(0.0, 180.0);

			ef_dualsword@ pSkillEffect = SpawnSkillFx( EFFECT_SKILLFX1, vecOrigin3[0], vecOrigin3[0], 0.01 );
			pSkillEffect.pev.angles = vecAngle2;
			pSkillEffect.m_flKillTime = g_Engine.time + 0.2;
			pSkillEffect.pev.oldorigin = vecOrigin;
			pSkillEffect.pev.sequence = Math.RandomLong(0, 2);
		}

		ef_dualsword@ pSkillEffect = SpawnSkillFx( EFFECT_SKILLFX2, vecOrigin3[0], vecOrigin3[1], 500.0 );
		pSkillEffect.pev.oldorigin = vecOrigin;
		pSkillEffect.m_flKillTime = g_Engine.time + 0.2;

		if( m_flSkillSound > 0.0 and m_flSkillSound < g_Engine.time )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, pCSOWSounds[Math.RandomLong(SND_FLY1, SND_FLY5)], VOL_NORM, ATTN_NORM );

			m_flSkillSound = g_Engine.time + CSOW_SKILL_SOUND_FREQ;
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	ef_dualsword@ SpawnSkillFx( int iEffectType, Vector vecStart, Vector vecEnd, float flSpeed )
	{
		CBaseEntity@ cbeSkillEffect = g_EntityFuncs.Create( "ef_dualsword", vecStart, g_vecZero, true, m_pPlayer.edict() );
		ef_dualsword@ pSkillEffect = cast<ef_dualsword@>(CastToScriptClass(cbeSkillEffect));

		Vector vecVelocity;
		GetSpeedVector( vecStart, vecEnd, flSpeed, vecVelocity );
		pSkillEffect.pev.velocity = vecVelocity;

		Vector vecAngles = m_pPlayer.pev.v_angle;
		g_EngineFuncs.VecToAngles( vecVelocity, vecAngles );

		if( vecAngles.x > 90.0) vecAngles.x = -(360.0 - vecAngles.x);
		pSkillEffect.pev.angles = vecAngles;

		pSkillEffect.m_iEffectType = iEffectType;
		pSkillEffect.m_ePlayer = EHandle(m_pPlayer);
		pSkillEffect.m_eWeapon = EHandle(self);
		g_EntityFuncs.DispatchSpawn( pSkillEffect.self.edict() );

		return pSkillEffect;
	}

	void SkillEnd()
	{
		CBaseEntity@ cbeOldSkillEffect = null;
		while( (@cbeOldSkillEffect = g_EntityFuncs.FindEntityByClassname(cbeOldSkillEffect, "ef_dualsword")) !is null )
		{
			if( cbeOldSkillEffect.pev.owner is m_pPlayer.edict() )
				g_EntityFuncs.Remove( cbeOldSkillEffect );
		} 

		m_iState = STATE_SKILL_END;

		Vector vecOrigin = m_pPlayer.pev.origin;
		vecOrigin.z -= 25.0;

		CBaseEntity@ cbeSkillEffect = g_EntityFuncs.Create( "ef_dualsword", vecOrigin, g_vecZero, true, m_pPlayer.edict() );
		ef_dualsword@ pSkillEffect = cast<ef_dualsword@>(CastToScriptClass(cbeSkillEffect));
		pSkillEffect.m_iEffectType = EFFECT_SKILL_END;
		pSkillEffect.m_flKillTime = g_Engine.time + 1.5;
		pSkillEffect.m_ePlayer = EHandle(m_pPlayer);
		pSkillEffect.m_eWeapon = EHandle(self);
		g_EntityFuncs.DispatchSpawn( pSkillEffect.self.edict() );

		m_iMode = MODE_SLASH;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.4;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
	}

	void HitEffect( Vector vecOrigin, int iStab, int iHitSomething )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_BLOODSPRITE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex((iStab == 0) ? SPRITE_HIT_SLASH1 : SPRITE_HIT_STAB2) );
			m1.WriteShort( g_EngineFuncs.ModelIndex((iStab == 0) ? SPRITE_HIT_SLASH2 : SPRITE_HIT_STAB1) );
			m1.WriteByte( (iStab == 0) ? 178 : 128 ); //color
			m1.WriteByte( Math.RandomLong(2, 3) ); //scale
		m1.End();

		if( iHitSomething == HIT_ENEMY )
		{
			NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m2.WriteByte( TE_BLOODSPRITE );
				m2.WriteCoord( vecOrigin.x );
				m2.WriteCoord( vecOrigin.y );
				m2.WriteCoord( vecOrigin.z );
				m2.WriteShort( g_EngineFuncs.ModelIndex("sprites/bloodspray.spr") );
				m2.WriteShort( g_EngineFuncs.ModelIndex("sprites/blood.spr") );
				m2.WriteByte( 75 ); //color, default: 75
				m2.WriteByte( 5 ); //scale, default: 5
			m2.End();
		}
	}

	void GetSpeedVector( Vector &in origin1, Vector &in origin2, float flSpeed, Vector &out vecVelocity )
	{
		vecVelocity = origin2 - origin1;
		vecVelocity = vecVelocity.Normalize();
		vecVelocity = vecVelocity * flSpeed;
	}
}

class ef_dualsword : ScriptBaseAnimating
{
	int m_iEffectType;
	float m_flKillTime;
	float m_flSlashSound;
	EHandle m_ePlayer;
	EHandle m_eWeapon;

	void Spawn()
	{
		Precache();

		if( m_iEffectType == EFFECT_SKILL_START )
		{
			g_EntityFuncs.SetModel( self, MODEL_SKILL );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, pCSOWSounds[SND_SKILL_START], VOL_NORM, ATTN_NORM );
		}
		else if( m_iEffectType == EFFECT_SKILLFX1 ) //Slashes
		{
			g_EntityFuncs.SetModel( self, MODEL_SKILLFX1 );
			pev.rendermode	= kRenderTransAdd;
		}
		else if( m_iEffectType == EFFECT_SKILLFX2 ) //Stabs
			g_EntityFuncs.SetModel( self, MODEL_SKILLFX2 );
		else if( m_iEffectType == EFFECT_SKILL_END )
		{
			g_EntityFuncs.SetModel( self, MODEL_SKILL );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, pCSOWSounds[SND_SKILL_END], VOL_NORM, ATTN_NORM );
			pev.sequence = 1;
		}

		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.renderamt		= 255;
		pev.movetype 	= MOVETYPE_FLY;
		pev.solid    		= SOLID_NOT;
		pev.takedamage	= DAMAGE_NO;
		//pev.scale			= 0.1; //??

		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.EffectThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_SLASH );
		g_Game.PrecacheModel( MODEL_SKILL );
		g_Game.PrecacheModel( MODEL_SKILLFX1 );
		g_Game.PrecacheModel( MODEL_SKILLFX2 );
	}

	void EffectThink()
	{
		CBasePlayer@ pOwner = null;
		if( m_ePlayer.IsValid() ) @pOwner = cast<CBasePlayer@>( m_ePlayer.GetEntity() );

		if( pOwner is null or !pOwner.IsAlive() or !m_eWeapon.IsValid() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( m_iEffectType == EFFECT_SKILL_START or m_iEffectType == EFFECT_SKILL_END )
		{
			if( m_flKillTime > 0.0 and m_flKillTime < g_Engine.time )
			{
				g_EntityFuncs.Remove( self );
				return;
			}

			pev.velocity = pOwner.pev.velocity;
		}
		else if( m_iEffectType >= EFFECT_SKILLFX1 )
		{
			Vector vecOrigin = pOwner.GetGunPosition();
			Vector vecNewOrigin = pev.origin + (vecOrigin - pev.oldorigin);

			pev.origin = vecNewOrigin;
			pev.oldorigin = vecOrigin;

			if( m_iEffectType == EFFECT_SKILLFX2 )
			{
				if( (vecOrigin - vecNewOrigin).Length() > 87.5 )
				{
					g_EntityFuncs.Remove( self );
					return;
				}
			}

			if( m_flKillTime > 0.0 and m_flKillTime < g_Engine.time )
			{
				g_EntityFuncs.Remove( self );
				return;
			}
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_dualsword::ef_dualsword", "ef_dualsword" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_dualsword::weapon_dualsword", "weapon_dualsword" );
	g_ItemRegistry.RegisterWeapon( "weapon_dualsword", "custom_weapons/cso" );
}

} //namespace cso_dualsword END

/*TODO
Make use of ef_dualsword_left.spr and ef_dualsword_right.spr
Limit the amount of ef_dualsword spawned during skill?
Use tempentity for the skillfx?
Somehow keep the SecondaryAttack slashes on screen without making them visible to other players ??
*/