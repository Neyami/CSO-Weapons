//Gunkata animation and some mathgic based on AMXX Plugin "AMXX Dual Beretta 5.1" by Asdian
//Thanks to Outerbeast for tip on how to make shadows invisible to the player
//Thanks to Garompa for the gun kata shadow muzzleflashes being transparent

namespace cso_gunkata
{

const bool USE_INFINITE_AMMO						= true; //The original has infinite ammo
const bool USE_PENETRATION							= true;
const bool bSpecialRenderingGunKata			= true; //only display ef_gunkata to other players, and ef_gunkataweapon to current player
const bool bSpecialRenderingShadows			= true; //only display ef_gunkatashadow to other players
const string CSOW_NAME								= "weapon_gunkata";

const int CSOW_DEFAULT_GIVE						= 36;
const int CSOW_MAX_CLIP 								= 36;
const int CSOW_MAX_AMMO							= 180;
const float CSOW_DAMAGE								= 20;
const float CSOW_SKILL_RADIUS_FAR			= cso::MetersToUnits(6);
const float CSOW_SKILL_RADIUS_CLOSE		= cso::MetersToUnits(3);
const float CSOW_SKILL_DAMAGE_FAR			= 9.9; //default 99
const float CSOW_SKILL_DAMAGE_CLOSE		= 10.9; //default 109
const float CSOW_SKILL_KNOCKBACK			= 80;
const float CSOW_TIME_DELAY1						= 0.095; //between shots
const float CSOW_TIME_DELAY2						= 0.35; //between switching hands
const float CSOW_TIME_DELAY3						= 0.25; //SecondaryAttack
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 6.0;
const float CSOW_TIME_RELOAD					= 2.0;
const float CSOW_TIME_SKILL_AMMO				= 0.1; //How fast to decrease ammo during gun kata
const float CSOW_TIME_SKILL_EFFECT			= 0.5; //How often to spawn ef_gunkata
const float CSOW_SPREAD_JUMPING				= 0.1; //0.20
const float CSOW_SPREAD_RUNNING				= 0.06; //0.15
const float CSOW_SPREAD_WALKING				= 0.03; //0.1
const float CSOW_SPREAD_STANDING			= 0.02;
const float CSOW_SPREAD_DUCKING				= 0.02;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -1.0);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(-0.5, -1.0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_SHELL_ORIGIN_R			= Vector(17.0, -8.0, -4.0); //forward, right, up
const Vector CSOW_SHELL_ORIGIN_L			= Vector(17.0, 8.0, -4.0); //forward, right, up

const string CSOW_ANIMEXT							= "uzis"; //gunkata

const string MODEL_VIEW								= "models/custom_weapons/cso/v_gunkata.mdl";
const string MODEL_PLAYER1							= "models/custom_weapons/cso/p_gunkata.mdl";
const string MODEL_PLAYER2							= "models/custom_weapons/cso/p_gunkata2.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_gunkata.mdl";
const string MODEL_GUNKATA							= "models/custom_weapons/cso/ef_gunkata.mdl";
const string MODEL_BLAST								= "models/custom_weapons/cso/ef_scorpion_hole.mdl";
const string MODEL_SHADOW_MAN				= "models/custom_weapons/cso/ef_gunkata_man.mdl";
const string MODEL_SHADOW_WOMAN			= "models/custom_weapons/cso/ef_gunkata_woman.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/pshell.mdl";

enum csow_e
{
	ANIM_IDLE_RIGHT = 0,
	ANIM_IDLE_LEFT,
	ANIM_SHOOT_RIGHT,
	ANIM_SHOOT_RIGHT_LAST,
	ANIM_SHOOT_LEFT,
	ANIM_SHOOT_LEFT_LAST,
	ANIM_RELOAD_RIGHT,
	ANIM_RELOAD_LEFT,
	ANIM_DRAW_RIGHT,
	ANIM_DRAW_LEFT,
	ANIM_SKILL1, //10
	ANIM_SKILL2,
	ANIM_SKILL3,
	ANIM_SKILL4,
	ANIM_SKILL5,
	ANIM_SKILL_LAST
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT,
	SND_SKILL1,
	SND_SKILL2,
	SND_SKILL3,
	SND_SKILL4,
	SND_SKILL5,
	SND_SKILL_LAST_EXP,
	SND_SKILL_HIT1,
	SND_SKILL_HIT2
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/gunkata-1.wav",
	"custom_weapons/cso/gunkata_skill_01.wav",
	"custom_weapons/cso/gunkata_skill_02.wav",
	"custom_weapons/cso/gunkata_skill_03.wav",
	"custom_weapons/cso/gunkata_skill_04.wav",
	"custom_weapons/cso/gunkata_skill_05.wav",
	"custom_weapons/cso/gunkata_skill_last_exp.wav",
	"custom_weapons/cso/turbulent9_hit1.wav", //make sure these are the correct sounds ??
	"custom_weapons/cso/turbulent9_hit2.wav",
	"custom_weapons/cso/gunkata_skill_last.wav",
	"custom_weapons/cso/gunkata_draw.wav",
	"custom_weapons/cso/gunkata_draw2.wav",
	//"custom_weapons/cso/gunkata_idle.wav", //unused atm, way too loud imo
	"custom_weapons/cso/gunkata_reload.wav",
	"custom_weapons/cso/gunkata_reload2.wav"
};

const array<string> m_arrsAnimationExtensions =
{
	"crowbar",
	"wrench",
	"gren",
	"trip",
	"onehanded",
	"python",
	"shotgun",
	"gauss",
	"mp5",
	"rpg",
	"egon",
	"squeak",
	"hive",
	"bow",
	"bowscope",
	"minigun",
	"uzis",
	"m16",
	"m203",
	"sniper",
	"sniperscope",
	"saw"
};

enum csowstates_e
{
	STATE_RIGHT = 0,
	STATE_LEFT
};

enum csowgunkata_e
{
	SKILLSTATE_NONE = 0,
	SKILLSTATE_LOOP,
	SKILLSTATE_END_START,
	SKILLSTATE_END
};

class weapon_gunkata : CBaseCSOWeapon
{
	private int m_iGunKataNum;
	private int m_iSkillState;
	private int m_iRandomSkillAnim;
	private int m_iCurSkillAnim;
	private int m_iSetSkillAnim;
	private int m_iSkillSoundChannel; //temp
	private float m_flSpawnGunkataEffect;
	private float m_flSkillKnockback;
	private float m_flSkillEnd;
	private float m_flSkillAmmoReduction;
	private bool m_bInReload;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;
		m_iGunKataNum = 0;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER1 );
		g_Game.PrecacheModel( MODEL_PLAYER2 );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_GUNKATA );
		g_Game.PrecacheModel( MODEL_BLAST );
		g_Game.PrecacheModel( MODEL_SHADOW_MAN );
		g_Game.PrecacheModel( MODEL_SHADOW_WOMAN );
		g_Game.PrecacheModel( cso::SPRITE_HITMARKER );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud18.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud176.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash77.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_gunkata_left.txt" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_gunkata_right.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::GUNKATA_SLOT - 1;
		info.iPosition		= cso::GUNKATA_POSITION - 1;
		info.iWeight			= cso::GUNKATA_WEIGHT;
		info.iFlags			= ITEM_FLAG_NOAUTOSWITCHEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;
		if( USE_INFINITE_AMMO )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 999 );

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName(CSOW_NAME) );
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

	void Holster( int skiplocal )
	{
		SetThink( null );
		m_bInReload = false;
		m_flSkillKnockback = 0.0;
		m_flSkillEnd = 0.0;
		m_flSkillAmmoReduction = 0.0;
		m_iSkillState = SKILLSTATE_NONE;
		m_iRandomSkillAnim = 0;
		m_iCurSkillAnim = 0;
		m_iSetSkillAnim = 0;
		RemoveGunkataEffect();

		BaseClass.Holster( skiplocal );
	} 

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER1), GetWeaponAnim(ANIM_DRAW_RIGHT), CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.20;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0; 
		cso::FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), 8192, iPenetration, BULLET_PLAYER_44MAG, flDamage, 1.0, EHandle(m_pPlayer), m_pPlayer.random_seed, (CSOF_ALWAYSDECAL | CSOF_HITMARKER) );

		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		Vector vecShellOrigin = GetWeaponState(-1) == STATE_RIGHT ? CSOW_SHELL_ORIGIN_R  : CSOW_SHELL_ORIGIN_L;
		int iAnimation;
		float flDelay;

		if( (self.m_iClip % 3) == 0 ) //switch hands
		{
			iAnimation = GetWeaponState() == STATE_RIGHT ? ANIM_SHOOT_LEFT_LAST : ANIM_SHOOT_RIGHT_LAST;
			flDelay = CSOW_TIME_DELAY2;
		}
		else
		{
			iAnimation = GetWeaponState() == STATE_RIGHT ? ANIM_SHOOT_RIGHT : ANIM_SHOOT_LEFT;
			flDelay = CSOW_TIME_DELAY1;
		}

		m_pPlayer.m_szAnimExtension = GetWeaponState(-1) == STATE_RIGHT ? "uzis_right" : "uzis_left";
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flDelay;
		self.m_flTimeWeaponIdle = g_Engine.time + flDelay + 0.5;
		self.SendWeaponAnim( iAnimation, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * vecShellOrigin.x - g_Engine.v_right * vecShellOrigin.y + g_Engine.v_up * vecShellOrigin.z, m_iShell, TE_BOUNCE_SHELL, (GetWeaponState(-1) == STATE_RIGHT ? true : false) );
	}

	void SecondaryAttack()
	{
		if( m_iSkillState > SKILLSTATE_LOOP or (m_pPlayer.pev.button & IN_ATTACK) != 0 ) return;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or (self.m_iClip <= 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 and m_iSkillState == SKILLSTATE_LOOP) )
		{
			self.SendWeaponAnim( GetWeaponAnim(ANIM_IDLE_RIGHT), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_bPlayEmptySound = true;
			PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.20;
			return;
		}

		DoSkillDamage();

		float flDelay;
		if( m_iRandomSkillAnim < 2 ) //try to prevent playing the same animation too often
		{
			int iAnim = Math.RandomLong( ANIM_SKILL1, ANIM_SKILL5 );
			if( iAnim == m_iSetSkillAnim )
			{
				if( iAnim == ANIM_SKILL5) iAnim--;
				else iAnim++;
			}

			if( iAnim == 10 or iAnim == 11) flDelay = 0.7;
			else flDelay = 1.03;

			self.SendWeaponAnim( iAnim, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_iSetSkillAnim = iAnim;
		}
		else
		{
			m_iCurSkillAnim++;
			if( m_iCurSkillAnim > 4 ) m_iCurSkillAnim = 0;

			if( m_iCurSkillAnim == 1 or m_iCurSkillAnim == 2 ) flDelay = 0.7;
			else flDelay = 1.03;

			int iAnim = 10 + m_iCurSkillAnim;
			if( iAnim == m_iSetSkillAnim )
			{
				if( iAnim == ANIM_SKILL5) iAnim--;
				else iAnim++;
			}

			SpawnWeaponAnims( iAnim, g_Engine.time + 1.0 );
			m_iSetSkillAnim = iAnim;
		}

		m_pPlayer.m_szAnimExtension = m_arrsAnimationExtensions[ Math.RandomLong(0, m_arrsAnimationExtensions.length()-1) ];
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.angles.y = Math.RandomFloat( 0.0, 359.0 );

		bool isMallarding = ((m_pPlayer.pev.flags & FL_DUCKING) == 1) ? true : false;
		SpawnShadow( isMallarding ? m_iCurSkillAnim + 6 : m_iCurSkillAnim );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_AUTO, pCSOWSounds[m_iCurSkillAnim+2], VOL_NORM, ATTN_NORM );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + Math.RandomFloat( 0.21, 0.24 );
		self.m_flTimeWeaponIdle = g_Engine.time + flDelay;

		m_iSkillState = SKILLSTATE_LOOP;
		m_iRandomSkillAnim = Math.RandomLong( 0, 9 );

		if( m_flSkillAmmoReduction <= 0.0 ) m_flSkillAmmoReduction = g_Engine.time;
		if( m_flSpawnGunkataEffect <= 0.0 ) m_flSpawnGunkataEffect = g_Engine.time;
	}

	void DoSkillDamage()
	{
		Vector vecTargetOrigin, vecMyOrigin;
		vecMyOrigin = m_pPlayer.GetGunPosition();

		CBaseEntity@ pTarget = null;
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, vecMyOrigin, CSOW_SKILL_RADIUS_FAR, "*", "classname")) !is null )
		{
			if( pTarget.edict() is m_pPlayer.edict() or pTarget.pev.takedamage == DAMAGE_NO or pTarget.pev.FlagBitSet(FL_CLIENT) or !pTarget.IsAlive() )
				continue;

			vecTargetOrigin = pTarget.pev.origin + Vector( 0, 0, (pTarget.pev.size.z/2) );

			if( is_wall_between_points(vecMyOrigin, vecTargetOrigin, m_pPlayer.edict()) ) continue;

			float flDamage = CSOW_SKILL_DAMAGE_FAR;
			if( (vecMyOrigin - vecTargetOrigin).Length() <= CSOW_SKILL_RADIUS_CLOSE )
			{
				flDamage = CSOW_SKILL_DAMAGE_CLOSE;
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[Math.RandomLong(SND_SKILL_HIT1, SND_SKILL_HIT2)], 0.56, ATTN_NORM );
			}

			TraceResult tr;
			g_Utility.TraceLine( pTarget.Center(), pTarget.Center(), ignore_monsters, m_pPlayer.edict(), tr );

			g_WeaponFuncs.ClearMultiDamage();
			pTarget.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH | DMG_NEVERGIB );
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			CreateBuffHit();
		}
	}

	void CreateBuffHit()
	{
		Vector vecOrigin = m_pPlayer.pev.origin;
		cso::get_position( m_pPlayer.edict(), 50.0, -0.05, 1.0, vecOrigin );

		CBaseEntity@ pHitConfirm = g_EntityFuncs.Create( "cso_buffhit", vecOrigin, g_vecZero, false, m_pPlayer.edict() );
	}

	void Reload()
	{
		if( self.m_iClip >= CSOW_MAX_CLIP or m_bInReload or (m_pPlayer.pev.button & IN_ATTACK) != 0 or (m_iSkillState != SKILLSTATE_NONE) ) return;

		if( USE_INFINITE_AMMO )
		{
			m_bInReload = true;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_RELOAD-0.2;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;
			self.SendWeaponAnim( GetWeaponAnim(ANIM_RELOAD_RIGHT), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			SetThink( ThinkFunction(this.ReloadThink) );
			pev.nextthink = g_Engine.time + CSOW_TIME_RELOAD-0.2;
		}
		else
		{
			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
				return;

			self.DefaultReload( CSOW_MAX_CLIP, GetWeaponAnim(ANIM_RELOAD_RIGHT), CSOW_TIME_RELOAD-0.2, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;
		}

		BaseClass.Reload();
	}

	void ReloadThink()
	{
		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT;

		while( self.m_iClip < CSOW_MAX_CLIP )
		{
			if( self.m_iClip >= CSOW_MAX_CLIP ) break;
			++self.m_iClip;
		}

		m_bInReload = false;

		SetThink( null );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT;

		self.SendWeaponAnim( GetWeaponAnim(ANIM_IDLE_RIGHT), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomLong( CSOW_TIME_IDLE, CSOW_TIME_IDLE*2 );
	}

	void ItemPostFrame() 
	{
		CheckForEndOfSkill();

		if( m_flSkillKnockback > 0.0 and m_flSkillKnockback < g_Engine.time and m_iSkillState == SKILLSTATE_END_START )
		{
			KnockbackCheck();

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.97;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW*2;

			if( USE_INFINITE_AMMO )
				ReloadThink();
			else
				self.m_fInReload = true;

			m_flSkillKnockback = 0.0;
			m_flSkillEnd = g_Engine.time + 0.22;
		}

		if( m_flSkillEnd > 0.0 and m_flSkillEnd < g_Engine.time and m_iSkillState == SKILLSTATE_END_START )
		{
			m_flSkillEnd = 0.0;
			m_iSkillState = SKILLSTATE_END;
		}

		if( m_iSkillState == SKILLSTATE_LOOP and m_flSkillAmmoReduction < g_Engine.time and self.m_iClip > 0 )
		{
			HandleAmmoReduction( 1 );
			m_flSkillAmmoReduction = g_Engine.time + CSOW_TIME_SKILL_AMMO;
		}

		if( m_iSkillState == SKILLSTATE_LOOP and m_flSpawnGunkataEffect < g_Engine.time and self.m_iClip > 0 )
		{
			SpawnGunkataEffect();
			m_flSpawnGunkataEffect = g_Engine.time + CSOW_TIME_SKILL_EFFECT;
		}

		if( ((m_pPlayer.pev.button & IN_ATTACK2) == 0 and m_iSkillState == SKILLSTATE_LOOP) or m_iSkillState == SKILLSTATE_END )
		{
			RemoveGunkataEffect();

			self.SendWeaponAnim( GetWeaponAnim(ANIM_DRAW_RIGHT), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			float flDelay = ( m_iSkillState == SKILLSTATE_END ? 0.5 : 1.0 );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			m_iRandomSkillAnim = 0;
			m_iSetSkillAnim = 0;
			m_flSkillAmmoReduction = 0;
			m_iSkillState = SKILLSTATE_NONE;
		}

		BaseClass.ItemPostFrame();
	}

	void CheckForEndOfSkill()
	{
		if( self.m_iClip <= 0 and m_iSkillState == SKILLSTATE_LOOP )
		{
			RemoveGunkataEffect();

			m_flSkillKnockback = g_Engine.time + 0.66;

			self.SendWeaponAnim( GetWeaponAnim(ANIM_SKILL_LAST), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.57;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.57;

			m_iRandomSkillAnim = 0;
			m_iSetSkillAnim = 0;

			m_iSkillState = SKILLSTATE_END_START;

			return;
		}
	}

	void GunkataBlastEffect()
	{
		Vector vecOrigin = m_pPlayer.pev.origin;
		vecOrigin.z -= 5.0;
		CBaseEntity@ pBlast = g_EntityFuncs.Create( "ef_gunkatablast", vecOrigin, g_vecZero, false, m_pPlayer.edict() );
	}

	void KnockbackCheck()
	{
		GunkataBlastEffect();

		CBaseEntity@ pTarget = null;
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, CSOW_SKILL_RADIUS_FAR, "*", "classname")) !is null )
		{
			if( !pTarget.pev.FlagBitSet(FL_MONSTER) or !pTarget.IsAlive() or pTarget.pev.takedamage == DAMAGE_NO or cso::g_arrsKnockbackImmuneMobs.find(pTarget.GetClassname()) >= 0 )
				continue; 

			Knockback( pTarget );
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_VOICE, pCSOWSounds[SND_SKILL_LAST_EXP], VOL_NORM, ATTN_NORM );
	}

	void Knockback( CBaseEntity@ pTarget )
	{
		Vector	vecAttacker = m_pPlayer.pev.origin,
					vecVictim = pTarget.pev.origin,
					vecVicCurVel;

		vecAttacker.z = vecVictim.z = 0.0;
		vecVictim = vecVictim - vecAttacker;

		float flDistance = vecVictim.Length();

		vecVictim = vecVictim * (1 / flDistance);

		vecVicCurVel = pTarget.pev.velocity;
		vecVictim = vecVictim * CSOW_SKILL_KNOCKBACK;
		vecVictim = vecVictim * 50.0;
		vecVictim.z = vecVictim.Length() * 0.15;

		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			vecVictim = vecVictim * 1.2;
			vecVictim.z *= 0.4;
		}

		if( vecVictim.Length() > vecVicCurVel.Length() )
			pTarget.pev.velocity = vecVictim;
	}

	bool CheckForActiveEffect()
	{
		CBaseEntity@ pEffect = null;
		while( (@pEffect = g_EntityFuncs.FindEntityByClassname(pEffect, "ef_gunkata")) !is null ) 
		{
			if( pEffect.pev.owner is null ) continue;
			if( pEffect.pev.owner is m_pPlayer.edict() ) return true;
		}

		return false;
	}

	void SpawnGunkataEffect()
	{
		Vector vecOrigin = m_pPlayer.pev.origin;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = -vecAngles.x;

		CBaseEntity@ cbeEffect = g_EntityFuncs.Create( "ef_gunkata", vecOrigin, vecAngles, true, m_pPlayer.edict() );
		ef_gunkata@ pEffect = cast<ef_gunkata@>(CastToScriptClass(cbeEffect));

		if( pEffect !is null )
		{
			pEffect.m_hOwner = EHandle( m_pPlayer );
			pEffect.m_hWeapon = EHandle( self );

			g_EntityFuncs.DispatchSpawn( pEffect.self.edict() );

			if( bSpecialRenderingGunKata )
			{
				string szAnimTargetName = "ef_gunkata_" + m_pPlayer.entindex() + "_" + m_iGunKataNum;
				pEffect.pev.targetname = szAnimTargetName;

				m_iGunKataNum++;
				if( m_iGunKataNum >= 4269 ) m_iGunKataNum = 0;

				dictionary keys;
				keys[ "target" ] = szAnimTargetName;
				keys[ "rendermode" ] = "2"; //kRenderTransTexture
				keys[ "renderamt" ] = "0";
				keys[ "spawnflags" ] = "64"; //Affect Activator (ignore netname)

				CBaseEntity@ pRender = g_EntityFuncs.CreateEntity( "env_render_individual", keys );

				if( pRender !is null )
				{
					pRender.Use( m_pPlayer, pRender, USE_ON, 0.0 );
					pEffect.m_hRenderEntity = EHandle( pRender );
				}
			}
		}
	}

	void RemoveGunkataEffect()
	{
		m_flSpawnGunkataEffect = 0.0;

		CBaseEntity@ pEffect = null;
		while( (@pEffect = g_EntityFuncs.FindEntityByClassname(pEffect, "ef_gunkata")) !is null ) 
		{
			if( pEffect.pev.owner is null ) continue;

			if( pEffect.pev.owner is m_pPlayer.edict() )
				g_EntityFuncs.Remove( pEffect );
		}
	}

	void SpawnWeaponAnims( int iAnim, float flRemoveTime )
	{
		Vector vecOrigin = m_pPlayer.GetGunPosition();
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = -vecAngles.x;

		CBaseEntity@ cbeAnim = g_EntityFuncs.Create( "ef_gunkataweapon", vecOrigin, vecAngles, true, m_pPlayer.edict() );
		ef_gunkataweapon@ pAnim = cast<ef_gunkataweapon@>(CastToScriptClass(cbeAnim));

		if( pAnim !is null )
		{
			pAnim.m_hOwner = EHandle( m_pPlayer );
			pAnim.m_hWeapon = EHandle( self );
			pAnim.m_flRemoveTime = flRemoveTime;

			pAnim.pev.sequence = iAnim;
			pAnim.pev.body = (m_bSwitchHands ? g_iCSOWHands : 0);
			pAnim.pev.colormap = m_pPlayer.pev.colormap;

			g_EntityFuncs.DispatchSpawn( pAnim.self.edict() );

			if( bSpecialRenderingGunKata )
			{
				string szAnimTargetName = "ef_gunkataweapon_" + m_pPlayer.entindex() + "_" + m_iGunKataNum;
				pAnim.pev.targetname  = szAnimTargetName;

				m_iGunKataNum++;
				if( m_iGunKataNum >= 4269 ) m_iGunKataNum = 0;

				dictionary keys;
				keys[ "target" ] = szAnimTargetName;
				keys[ "rendermode" ] = "0";
				keys[ "renderamt" ] = "255";
				keys[ "spawnflags" ] = "64"; //Affect Activator (ignore netname)

				CBaseEntity@ pRender = g_EntityFuncs.CreateEntity( "env_render_individual", keys );

				if( pRender !is null )
				{
					pRender.Use( m_pPlayer, pRender, USE_ON, 0.0 );
					pAnim.m_hRenderEntity = EHandle( pRender );
				}
			}
		}
	}

	void SpawnShadow( int iAnim )
	{
		Vector vecOrigin = m_pPlayer.pev.origin;
		Vector vecAngles = m_pPlayer.pev.angles;

		CBaseEntity@ cbeShadow = g_EntityFuncs.Create( "ef_gunkatashadow", vecOrigin, vecAngles, true, m_pPlayer.edict() );
		ef_gunkatashadow@ pShadow = cast<ef_gunkatashadow@>(CastToScriptClass(cbeShadow));

		if( pShadow !is null )
		{
			KeyValueBuffer@ pInfo = g_EngineFuncs.GetInfoKeyBuffer( m_pPlayer.edict() );
			string szPlayerModelName = pInfo.GetValue( "model" );

			if( cso::g_arrsFemaleModels.find(szPlayerModelName) >= 0 )
				pShadow.m_bMaleModel = false;
			else if( cso::g_arrsMaleModels.find(szPlayerModelName) >= 0 )
				pShadow.m_bMaleModel = true;
			else
				pShadow.m_bMaleModel = (Math.RandomLong(0, 1) == 0) ? true : false;

			pShadow.pev.sequence = iAnim;

			g_EntityFuncs.DispatchSpawn( pShadow.self.edict() );

			if( bSpecialRenderingShadows )
			{
				string szShadowTargetName = "ef_gunkatashadow_" + m_pPlayer.entindex() + "_" + m_iGunKataNum;
				pShadow.pev.targetname  = szShadowTargetName;

				m_iGunKataNum++;
				if( m_iGunKataNum >= 4269 ) m_iGunKataNum = 0;

				dictionary keys;
				keys[ "target" ] = szShadowTargetName;
				keys[ "rendermode" ] = "2";
				keys[ "renderamt" ] = "0";
				keys[ "spawnflags" ] = "64"; //Affect Activator (ignore netname)

				CBaseEntity@ pRender = g_EntityFuncs.CreateEntity( "env_render_individual", keys );

				if( pRender !is null )
				{
					pRender.Use( m_pPlayer, pRender, USE_ON, 0.0 );
					pShadow.m_hRenderEntity = EHandle( pRender );
				}
			}
		}
	}

	int GetWeaponAnim( int iRightAnimation ) //returns the correct animation depending on weaponstate
	{
		return (GetWeaponState() == 0 ? iRightAnimation : iRightAnimation +1);
	}

	int GetWeaponState( int iModifier = 0 )
	{
		return ((((CSOW_MAX_CLIP + iModifier) - self.m_iClip) / 3) % 2);
	}
}

class ef_gunkata : ScriptBaseEntity
{
	EHandle m_hOwner;
	EHandle m_hWeapon;
	EHandle m_hRenderEntity;
	private float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_GUNKATA );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, -1.0), Vector(1.0, 1.0, 1.0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_FLY;
		pev.takedamage = DAMAGE_NO;
		pev.frame = 0.0;
		pev.animtime = g_Engine.time; //makes the animation play properly for some reason :hehe:
		pev.framerate = 1.0;
		pev.rendermode = kRenderNormal;
		pev.renderamt = 255.0;

		m_flRemoveTime = g_Engine.time + 0.7;

		SetThink( ThinkFunction(this.EffectThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_GUNKATA );
	}

	void EffectThink()
	{
		if( !m_hOwner.IsValid() or !m_hWeapon.IsValid() )
		{
			RemoveThink();
			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( m_hOwner.GetEntity() );

		if( pOwner is null )
		{
			RemoveThink();
			return;
		}

		Vector vecAngle = pOwner.pev.v_angle;

		vecAngle.x = -vecAngle.x;

		pev.velocity = pOwner.pev.velocity;
		pev.angles = vecAngle;

		if( m_flRemoveTime < g_Engine.time or !pOwner.IsAlive() )
		{
			RemoveThink(); //pev.flags |= FL_KILLME??
			return;
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}

	void UpdateOnRemove()
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		BaseClass.UpdateOnRemove();
	}
}

class ef_gunkatablast : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_BLAST );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, -1.0), Vector(1.0, 1.0, 1.0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.takedamage = DAMAGE_NO;
		pev.frame = 0.0;
		pev.animtime = g_Engine.time; //makes the animation play properly for some reason :hehe:
		pev.framerate = 1.0;
		pev.sequence = 1;
		pev.scale = 1.0;

		SetThink( ThinkFunction(this.RemoveThink) );
		pev.nextthink = g_Engine.time + 0.3;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_BLAST );
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}
}

class ef_gunkataweapon : ScriptBaseEntity
{
	EHandle m_hOwner;
	EHandle m_hWeapon;
	EHandle m_hRenderEntity;
	float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_VIEW );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, -1.0), Vector(1.0, 1.0, 1.0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_FLY;
		pev.takedamage = DAMAGE_NO;
		pev.rendermode = kRenderTransTexture;
		pev.renderamt = 0;
		pev.animtime = g_Engine.time;
		pev.framerate = 1.0;
		pev.velocity = Vector( 0.01, 0.01, 0.01 ); //NEEDED??

		SetThink( ThinkFunction(this.EffectThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_VIEW );
	}

	void EffectThink()
	{
		if( !m_hOwner.IsValid() or !m_hWeapon.IsValid() )
		{
			RemoveThink();
			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( m_hOwner.GetEntity() );

		if( pOwner is null )
		{
			RemoveThink();
			return;
		}

		Vector vecAngle = pOwner.pev.v_angle;

		vecAngle.x = -vecAngle.x;

		pev.velocity = pOwner.pev.velocity;
		pev.angles = vecAngle;

		if( m_flRemoveTime < g_Engine.time or !pOwner.IsAlive() )
		{
			RemoveThink(); //pev.flags |= FL_KILLME??
			return;
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}

	void UpdateOnRemove()
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		BaseClass.UpdateOnRemove();
	}
}

class ef_gunkatashadow : ScriptBaseEntity
{
	EHandle m_hRenderEntity;
	bool m_bMaleModel;

	void Spawn()
	{
		Precache();

		if( m_bMaleModel )
			g_EntityFuncs.SetModel( self, MODEL_SHADOW_MAN );
		else
			g_EntityFuncs.SetModel( self, MODEL_SHADOW_WOMAN );

		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_FLY;
		pev.takedamage = DAMAGE_NO;
		pev.rendermode = kRenderTransTexture;
		pev.renderamt = 200.0;
		pev.animtime = g_Engine.time;
		pev.framerate = 1.0;

		SetThink( ThinkFunction(this.EffectThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_SHADOW_MAN );
		g_Game.PrecacheModel( MODEL_SHADOW_WOMAN );
	}

	void EffectThink()
	{
		float flRenderAmount = pev.renderamt;

		flRenderAmount -= 3.5;

		if( flRenderAmount <= 0.0 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		pev.renderamt = flRenderAmount;
		pev.nextthink = g_Engine.time + 0.01;
	}

	void UpdateOnRemove()
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		BaseClass.UpdateOnRemove();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_gunkata::ef_gunkatashadow", "ef_gunkatashadow" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_gunkata::ef_gunkataweapon", "ef_gunkataweapon" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_gunkata::ef_gunkatablast", "ef_gunkatablast" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_gunkata::ef_gunkata", "ef_gunkata" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_gunkata::weapon_gunkata", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "44MAG" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "cso_buffhit" ) ) 
		cso::RegisterBuffHit();
}

} //namespace cso_gunkata END