namespace cso_dualsword
{

const int CSOW_DAMAGE			= 10;

const float CSOW_TIME_DRAW	= 0.2;
const float CSOW_TIME_DELAY1	= 1.0;
const float CSOW_TIME_DELAY2 = 1.2;
const float CSOW_TIME_IDLEA	= 3.0;
const float CSOW_TIME_IDLEB	= 4.0;

const string CSOW_ANIMEXT	= "crowbar";

const string MODEL_VIEW			= "models/custom_weapons/cso/v_dualsword.mdl";
const string MODEL_PLAYER_A	= "models/custom_weapons/cso/p_dualsword_a.mdl";
const string MODEL_PLAYER_B	= "models/custom_weapons/cso/p_dualsword_b.mdl";
const string MODEL_WORLD		= "models/custom_weapons/cso/w_dualsword.mdl";
const string MODEL_SLASH		= "models/custom_weapons/cso/dualswordfx.mdl";
const string MODEL_SKILLSTART	= "models/custom_weapons/cso/dualsword_skill.mdl";
const string MODEL_STABFX		= "models/custom_weapons/cso/dualsword_skillfx2.mdl";
const string MODEL_SLASHFX		= "models/custom_weapons/cso/dualsword_skillfx1.mdl";

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
	SND_HIT1,
	SND_HIT2,
	SND_HIT3,
	SND_IDLE_A,
	SND_IDLE_B,
	SND_SKILL_END,
	SND_SKILL_LOOP,
	SND_SKILL_START,
	SND_SLASH1,
	SND_SLASH2,
	SND_SLASH3,
	SND_SLASH4,
	SND_SLASH4_1,
	SND_SLASH4_2,
	SND_SLASH_END,
	SND_STAB_END,
	SND_STAB1,
	SND_STAB1_HIT,
	SND_STAB2,
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
	"custom_weapons/cso/dualsword_skill_loop_end.wav",
	"custom_weapons/cso/dualsword_skill_start.wav",
	"custom_weapons/cso/dualsword_slash_1.wav",
	"custom_weapons/cso/dualsword_slash_2.wav",
	"custom_weapons/cso/dualsword_slash_3.wav",
	"custom_weapons/cso/dualsword_slash_4.wav",
	"custom_weapons/cso/dualsword_slash_4_1.wav",
	"custom_weapons/cso/dualsword_slash_4_2.wav",
	"custom_weapons/cso/dualsword_slash_end.wav",
	"custom_weapons/cso/dualsword_stab_end.wav",
	"custom_weapons/cso/dualsword_stab1.wav",
	"custom_weapons/cso/dualsword_stab1_hit.wav",
	"custom_weapons/cso/dualsword_stab2.wav",
	"custom_weapons/cso/dualsword_stab2_hit.wav",
	"custom_weapons/cso/mastercombat_wall.wav"
};

enum csowstate_e
{
	STATE_NONE = 0,
	STATE_STAB,
	STATE_SLASH,
	STATE_SKILL
};

enum csowmode_e
{
	MODE_A = 0,
	MODE_B
};

class weapon_dualsword : CBaseCSOWeapon
{
	private int m_iState;
	private int m_iMode;
	private int m_iStabState;
	int m_iSlashState;
	//private int m_iComboState;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iClip = WEAPON_NOCLIP;
		self.m_flCustomDmg		= self.pev.dmg;

		m_iWeaponType = TYPE_MELEE;
		m_iState = STATE_NONE;
		m_iMode = MODE_B;
		m_iStabState = 0;
		m_iSlashState = 0;

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
		g_Game.PrecacheModel( MODEL_SKILLSTART );
		g_Game.PrecacheModel( MODEL_STABFX );
		g_Game.PrecacheModel( MODEL_SLASHFX );

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model((m_iMode == MODE_A) ? MODEL_PLAYER_A : MODEL_PLAYER_B), (m_iMode == MODE_A) ? ANIM_DRAW_A : ANIM_DRAW_B, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		StopIdleSound();
		m_iState = STATE_NONE;
		m_iStabState = 0;
		m_iSlashState = 0;

		SetThink( null );
	}

	void PrimaryAttack()
	{
		SetThink( null );
		StopIdleSound();
		m_iSlashState = 0;

		//if( m_iMode == MODE_A ) self.SendWeaponAnim( ANIM_SWAP_TO_B );

		if( m_iStabState >= 2 ) m_iStabState = 0;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[(m_iStabState == 0) ? SND_STAB1 : SND_STAB2], VOL_NORM, ATTN_NORM );
		self.SendWeaponAnim( ANIM_STAB1 + m_iStabState );
		m_iStabState++;

		m_iState = STATE_STAB;
		m_iMode = MODE_B;

		SetThink( ThinkFunction(this.StabEndThink) );

		if( m_iStabState == 1 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.4;
			pev.nextthink = g_Engine.time + 0.7;
		}
		else if( m_iStabState == 2 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
			pev.nextthink = g_Engine.time + 0.9;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
	}

	void StabEndThink()
	{
		self.SendWeaponAnim( ANIM_STAB_END );
		self.m_flTimeWeaponIdle = g_Engine.time + 1.4;

		SetThink( null );
	}

	void SecondaryAttack()
	{
		StopIdleSound();

		m_iStabState = 0;
		m_iSlashState = 0;
		m_iState = STATE_SLASH;

		if( m_iMode == MODE_B ) self.SendWeaponAnim( ANIM_SWAP_TO_A );
		m_iMode = MODE_A;
		
		SetThink( ThinkFunction(this.SlashThink) );
		pev.nextthink = g_Engine.time + 0.1;

		CreateSlash( 0 );

		self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
		self.m_flTimeWeaponIdle = g_Engine.time + 3.2;
	}

	void SlashThink()
	{
		self.SendWeaponAnim( ANIM_SLASH1 + m_iSlashState );
		m_iSlashState++;

		if( m_iSlashState >= 0 and m_iSlashState <= 3 )
		{
			CreateSlash( m_iSlashState-1 );

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SLASH1+(m_iSlashState -1)], VOL_NORM, ATTN_NORM );
			pev.nextthink = g_Engine.time + 0.15;
		}
		else if( m_iSlashState == 4 )
		{
			CreateSlash( 3 );

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SLASH4], VOL_NORM, ATTN_NORM );
			self.m_flNextPrimaryAttack = g_Engine.time + 0.6;
			pev.nextthink = g_Engine.time + 0.8;
		}
		else if( m_iSlashState == 5 )
		{
			pev.nextthink = g_Engine.time + 0.5;
			SetThink( null );
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		m_iState = STATE_NONE;
		m_iStabState = 0;

		self.SendWeaponAnim( (m_iMode == MODE_A) ? ANIM_IDLE_A : ANIM_IDLE_B );
		self.m_flTimeWeaponIdle = g_Engine.time + ((m_iMode == MODE_A) ? CSOW_TIME_IDLEA : CSOW_TIME_IDLEB);
	}

	void StopIdleSound()
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[(m_iMode == MODE_A) ? SND_IDLE_A : SND_IDLE_B] );
	}

	void CreateSlash( int iSequence )
	{
		Vector vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x = -vecAngles.x;

		CBaseEntity@ cbeSlashEffect = g_EntityFuncs.Create( "ef_dualsword", m_pPlayer.GetGunPosition(), vecAngles, true, m_pPlayer.edict() );
		ef_dualsword@ pSlashEffect = cast<ef_dualsword@>(CastToScriptClass(cbeSlashEffect));
		pSlashEffect.m_iEffectType = EFFECT_SLASH;
		pSlashEffect.m_ePlayer = EHandle(m_pPlayer);
		pSlashEffect.m_eWeapon = EHandle(self);

		if( iSequence < 3 )
			pSlashEffect.m_flKillTime = g_Engine.time + 0.1;
		else if( iSequence == 3 )
		{
			pSlashEffect.m_flSlashSound = g_Engine.time + 0.4;
			pSlashEffect.m_flKillTime = g_Engine.time + 1.0;
		}

		pSlashEffect.pev.sequence = iSequence;

		g_EntityFuncs.DispatchSpawn( pSlashEffect.self.edict() );
	}
}

enum csoweffect_e
{
	EFFECT_SLASH = 0,
	EFFECT_SKILL
};

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

		//g_Game.AlertMessage( at_console, "ef_dualsword SPAWNED!\n" );

		g_EntityFuncs.SetModel( self, MODEL_SLASH );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype 	= MOVETYPE_FLY;
		pev.solid    		= SOLID_NOT;
		pev.takedamage	= DAMAGE_NO;
		//pev.scale			= 0.1; //??
		pev.rendermode	= kRenderTransAdd;
		pev.renderamt		= 255;

		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.EffectThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_SLASH );
	}

	void EffectThink()
	{
		CBasePlayer@ pPlayer = null;
		if( m_ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( m_ePlayer.GetEntity() );

		if( pPlayer is null or !pPlayer.IsAlive() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( m_iEffectType == EFFECT_SLASH )
		{
			CBasePlayerWeapon@ pWeapon = null;

			if( m_eWeapon.IsValid() )
				@pWeapon = cast<CBasePlayerWeapon@>( m_eWeapon.GetEntity() );

			weapon_dualsword@ pDualSword = cast<weapon_dualsword@>(CastToScriptClass(pWeapon));

			Vector vecOrigin, vecAngles;
			vecOrigin = pPlayer.GetGunPosition();
			vecAngles = pPlayer.pev.v_angle;
			vecAngles.x = -vecAngles.x;

			g_EntityFuncs.SetOrigin( self, vecOrigin );
			pev.angles = vecAngles;

			if( m_flSlashSound > 0.0 and m_flSlashSound < g_Engine.time)
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SLASH4_1], VOL_NORM, ATTN_NORM );
				m_flSlashSound = 0.0;
			}

			if( pDualSword is null or pDualSword.m_iSlashState == 0 or (m_flKillTime > 0.0 and m_flKillTime < g_Engine.time) )
			{
				float flRenderAmount;
				flRenderAmount = pev.renderamt;

				flRenderAmount -= 4.5;

				if( flRenderAmount <= 5.0 )
				{
					g_EntityFuncs.Remove( self );
					return;
				}

				pev.renderamt = flRenderAmount;
			}
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void RemoveThink()
	{
		//g_Game.AlertMessage( at_notice, "ef_dualsword REMOVED!\n" );
		g_EntityFuncs.Remove( self );
	}
}
/*
stock CreateSlash(id,iEnt,seq)
{
	new Float:vecOrigin[3], Float:vecAngle[3];
	GetGunPosition(id, vecOrigin);
	pev(id, pev_v_angle, vecAngle);
	vecAngle[0] = -vecAngle[0];
	
	new pEntity = DPS_Entites(id,"models/dualswordfx.mdl",vecOrigin,vecOrigin,0.01,SOLID_NOT,seq)
		
	// Set info for ent	
	m_iEffectMode(pEntity, 0)
	set_pev(pEntity, pev_scale, 0.1);
	set_pev(pEntity, pev_iuser1, iEnt);
	set_pev(pEntity, pev_velocity, Float:{0.01,0.01,0.01});
	set_pev(pEntity, pev_angles, vecAngle);
	set_pev(pEntity, pev_nextthink, get_gametime()+0.01);
}

stock DPS_Entites(id, models[], Float:Start[3], Float:End[3], Float:speed, solid, seq, move=MOVETYPE_FLY)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
	// Set info for ent	
	set_pev(pEntity, pev_movetype, move);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, models);
	set_pev(pEntity, pev_classname, "dps_entytyd");
	set_pev(pEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
	set_pev(pEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
	set_pev(pEntity, pev_origin, Start);
	set_pev(pEntity, pev_gravity, 0.01);
	set_pev(pEntity, pev_solid, solid);
	
	static Float:Velocity[3];
	Stock_Get_Speed_Vector(Start, End, speed, Velocity);
	set_pev(pEntity, pev_velocity, Velocity);

	new Float:vecVAngle[3]; pev(id, pev_v_angle, vecVAngle);
	vector_to_angle(Velocity, vecVAngle)
	
	if(vecVAngle[0] > 90.0) vecVAngle[0] = -(360.0 - vecVAngle[0]);
	set_pev(pEntity, pev_angles, vecVAngle);
	
	set_pev(pEntity, pev_rendermode, kRenderTransAdd);
	set_pev(pEntity, pev_renderamt, 255.0);
	set_pev(pEntity, pev_sequence, seq)
	set_pev(pEntity, pev_animtime, get_gametime());
	set_pev(pEntity, pev_framerate, 1.0)
	return pEntity;
}
*/
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_dualsword::ef_dualsword", "ef_dualsword" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_dualsword::weapon_dualsword", "weapon_dualsword" );
	g_ItemRegistry.RegisterWeapon( "weapon_dualsword", "custom_weapons/cso" );
}

} //namespace cso_dualsword END