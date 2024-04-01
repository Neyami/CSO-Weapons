//Based on an AMXX plugin by cs-topcounter-strike1.6sma62

namespace cso_failnaught
{

const bool USE_PENETRATION							= true;
const bool ARROWS_STICK_TO_PLAYERS		= true; //no damage is dealt though

const int CSOW_DEFAULT_GIVE						= 25;
const int CSOW_MAX_AMMO							= 250;
const int  CSOW_ARROW_MAX_STACKS			= 5; //Number of arrows that need to hit an enemy to cause an explosion
const float CSOW_DAMAGE1							= 40;
const float CSOW_DAMAGE2							= 200; //33 from the wiki
const float CSOW_TIME_DELAY						= 0.3;
const float CSOW_TIME_DRAW						= 1.5; //1.7
const float CSOW_TIME_IDLE							= 2.7; //3.0
const float CSOW_TIME_FIRE_TO_IDLE1		= 0.5;
const float CSOW_TIME_FIRE_TO_IDLE2		= 1.3;
const float CSOW_TIME_FIRE_TO_IDLE3		= 0.7;
const float CSOW_TIME_RELOAD1					= 0.45;
const float CSOW_TIME_RELOAD2					= 1.25;
const float CSOW_TIME_CHARGE					= 1.0;
const float CSOW_TIME_ARROW_LIFE			= 10.0;
const float CSOW_ARROW_SPEED					= 2000;
//const float CSOW_ARROW_EXP_RADIUS			= 90; //Not used atm, radius is based on mob volume
const float CSOW_SKILL_RANGE						= 35; //in meters :ayaya:
const float CSOW_SKILL_RATE						= 0.05;
const float CSOW_SKILL_SIZE						= 10.0; //Base size of the rectangle (based on monster_zombie)
const RGBA CSOW_SKILL_COLOR					= RGBA_SVENCOOP; //RGBA_RED
const float CSOW_STACK_LIFETIME				= 5.0;

const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1.0, -2.0);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(1.0, -1.0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE								= VECTOR_CONE_2DEGREES;

const string CSOW_ANIMEXT							= "egon";

const string MODEL_VIEW								= "models/custom_weapons/cso/v_huntbow.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_huntbow.mdl";
const string MODEL_PLAYER_EMPTY				= "models/custom_weapons/cso/p_huntbow_empty.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_huntbow.mdl";
const string MODEL_PROJ								= "models/custom_weapons/cso/huntbow_arrow.mdl";
const string MODEL_AMMO								= "models/w_crossbow_clip.mdl";

const string SPRITE_EXPLODE							= "sprites/custom_weapons/cso/skull.spr";
const string SPRITE_HUNTERSEYE					= "sprites/laserbeam.spr";
//const string SPRITE_MUZZLE1						= "sprites/custom_weapons/cso/muzzleflash208.spr"; //??
//const string SPRITE_MUZZLE2						= "sprites/custom_weapons/cso/muzzleflash210.spr"; //Charge finish
const string SPRITE_MUZZLE3							= "sprites/custom_weapons/cso/muzzleflash211.spr"; //Draw, and pulling back the arrow after shooting?
//const string SPRITE_MUZZLE4						= "sprites/custom_weapons/cso/muzzleflash212.spr"; //Charge idle1

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_EMPTY,
	ANIM_SHOOT1,
	ANIM_SHOOT1_EMPTY,
	ANIM_DRAW,
	ANIM_DRAW_EMPTY, //5
	ANIM_CHARGE_START,
	ANIM_CHARGE_FINISH,
	ANIM_CHARGE_IDLE1,
	ANIM_CHARGE_IDLE2,
	ANIM_CHARGE_SHOOT1, //10
	ANIM_CHARGE_SHOOT1_EMPTY,
	ANIM_CHARGE_SHOOT2,
	ANIM_CHARGE_SHOOT2_EMPTY
};

enum csowsounds_e
{
	SND_CHARGE_LOOP = 0,
	SND_CHARGE_START_FX,
	SND_SHOOT,
	SND_CHARGE_SHOOT,
	SND_EXPLODE,
	SND_HIT_WALL, //5
	SND_HIT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/failnaught_charge_loop_fx.wav",
	"custom_weapons/cso/failnaught_charge_start_fx.wav",
	"custom_weapons/cso/failnaught-1.wav",
	"custom_weapons/cso/failnaught-2.wav",
	"custom_weapons/cso/failnaught-2_exp.wav",
	"custom_weapons/cso/xbow_hit1.wav",
	"custom_weapons/cso/xbow_hitbod1.wav",
	"custom_weapons/cso/failnaught_charge_shoot1.wav",
	"custom_weapons/cso/failnaught_charge_shoot2.wav",
	"custom_weapons/cso/failnaught_charge_start1.wav",
	"custom_weapons/cso/failnaught_draw.wav",
	"custom_weapons/cso/failnaught_shoot1.wav",
	"custom_weapons/cso/failnaught_shoot1_empty.wav",
	"custom_weapons/cso/failnaught_draw_empty.wav"
};

const array<string> pDamageMarks =
{
	"",
	"sprites/custom_weapons/cso/dmgreiteration01.spr",
	"sprites/custom_weapons/cso/dmgreiteration02.spr",
	"sprites/custom_weapons/cso/dmgreiteration03.spr",
	"sprites/custom_weapons/cso/dmgreiteration04.spr"
};

enum csowmodes_e
{
	STATE_NONE = 0,
	STATE_CHARGE_START,
	STATE_CHARGE_MID,
	STATE_CHARGED_IDLE
};

enum csowattach_e
{
	ATTACH_MUZZLE1 = 0,	//At the center of the rotating thingy
	ATTACH_MUZZLE2			//A bit further out from the first
};

class weapon_failnaught : CBaseCSOWeapon
{
	private int m_iState;
	private float m_flTimeCharge;
	private float m_flNextLoopSound;
	private float m_flUpdateHuntersEye;
	private int m_iHuntersEyeSprite;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_MAX_AMMO;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		uint i;

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_PLAYER_EMPTY );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_AMMO );
		g_Game.PrecacheModel( MODEL_PROJ );
		g_Game.PrecacheModel( cso::SPRITE_TRAIL_FAILNAUGHT );
		g_Game.PrecacheModel( cso::SPRITE_TRAIL_FAILNAUGHT_EXPLODE );
		g_Game.PrecacheModel( SPRITE_EXPLODE );
		m_iHuntersEyeSprite = g_Game.PrecacheModel( SPRITE_HUNTERSEYE );
		//g_Game.PrecacheModel( SPRITE_MUZZLE1 );
		//g_Game.PrecacheModel( SPRITE_MUZZLE2 );
		g_Game.PrecacheModel( SPRITE_MUZZLE3 );
		//g_Game.PrecacheModel( SPRITE_MUZZLE4 );

		for( i = 1; i < pDamageMarks.length(); ++i )
			g_Game.PrecacheModel( pDamageMarks[i] );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_failnaught.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud41.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud213.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= WEAPON_NOCLIP;
		info.iAmmo1Drop	= CSOW_DEFAULT_GIVE;
		info.iSlot				= cso::FAILNAUGHT_SLOT - 1;
		info.iPosition		= cso::FAILNAUGHT_POSITION - 1;
		info.iWeight			= cso::FAILNAUGHT_WEIGHT;
		info.iFlags			= ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_failnaught") );
		m.End();

		m_iState = STATE_NONE;
		m_flTimeCharge = 0.0;
		m_flNextLoopSound = 0.0;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			int iAnim = (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_DRAW : ANIM_DRAW_EMPTY;
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), iAnim, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		m_iState = STATE_NONE;
		m_flTimeCharge = 0.0;
		m_flNextLoopSound = 0.0;

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_iState > STATE_NONE )
			return;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		ShootNormal( false );
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		switch( m_iState )
		{
			case STATE_NONE: 
			{
				self.SendWeaponAnim( ANIM_CHARGE_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

				m_iState = STATE_CHARGE_START;

				break;
			}

			case STATE_CHARGE_START:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_flTimeCharge = g_Engine.time;
				m_iState = STATE_CHARGE_MID;

				break;
			}

			case STATE_CHARGE_MID:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_iState = STATE_CHARGE_MID;

				if( g_Engine.time >= (m_flTimeCharge + CSOW_TIME_CHARGE) )
				{
					self.SendWeaponAnim( ANIM_CHARGE_FINISH, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_CHARGE_START_FX], VOL_NORM, ATTN_NORM );
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = m_flNextLoopSound = g_Engine.time + 0.35;

					m_iState = STATE_CHARGED_IDLE;
				}

				break;
			}

			case STATE_CHARGED_IDLE:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_iState = STATE_CHARGED_IDLE;
				m_flUpdateHuntersEye = g_Engine.time + CSOW_SKILL_RATE;

				break;
			}
		}
	}

	void ShootNormal( bool bInCharge )
	{
		m_flNextLoopSound = 0.0;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		int iShootNormalAnim, iShootChargedAnim;
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			iShootNormalAnim = ANIM_SHOOT1;
			iShootChargedAnim = ANIM_CHARGE_SHOOT1;
		}
		else
		{
			iShootNormalAnim = ANIM_SHOOT1_EMPTY;
			iShootChargedAnim = ANIM_CHARGE_SHOOT1_EMPTY;

			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_EMPTY;
		}

		self.SendWeaponAnim( bInCharge ? iShootChargedAnim : iShootNormalAnim, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[bInCharge ? SND_CHARGE_SHOOT : SND_SHOOT], VOL_NORM, ATTN_NORM );

		Vector vecOrigin, vecEnd, vecAngles, vecVelocity;

		get_position( 40.0, 0.0, 0.0, vecOrigin );
		get_position( 4096.0, 0.0, 0.0, vecEnd );
		vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x *= -1;

		CBaseEntity@ pArrow = g_EntityFuncs.Create( "holyarrow", vecOrigin, vecAngles, false, m_pPlayer.edict() );

		if( self.m_flCustomDmg > 0 )
			pArrow.pev.dmg = self.m_flCustomDmg;
		else
			pArrow.pev.dmg = CSOW_DAMAGE1;

		float flSpeed = (m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD) ? CSOW_ARROW_SPEED : CSOW_ARROW_SPEED/2;
		vecVelocity = vecEnd - vecOrigin;
		float num = sqrt( flSpeed*flSpeed / (vecVelocity.x*vecVelocity.x + vecVelocity.y*vecVelocity.y + vecVelocity.z*vecVelocity.z) );
		vecVelocity = vecVelocity * num;
		pArrow.pev.velocity = vecVelocity;

		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_X : CSOW_RECOIL_STANDING_X;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_Y : CSOW_RECOIL_STANDING_Y;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + (bInCharge ? CSOW_TIME_RELOAD2 : CSOW_TIME_RELOAD1);

		m_iState = STATE_NONE;
	}

	void ShootCharged()
	{
		m_flNextLoopSound = 0.0;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 ) m_pPlayer.pev.weaponmodel = MODEL_PLAYER_EMPTY;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_CHARGE_SHOOT2 : ANIM_CHARGE_SHOOT2_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_CHARGE_SHOOT], VOL_NORM, ATTN_NORM );

		int iPenetration = USE_PENETRATION ? 4 : 0;
		FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, 0, iPenetration, BULLET_PLAYER_FAILNAUGHT, 0, CSOW_DAMAGE2, 1.0 );

		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_X : CSOW_RECOIL_STANDING_X;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_Y : CSOW_RECOIL_STANDING_Y;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD2;

		m_iState = STATE_NONE;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iState == STATE_CHARGE_START or m_iState == STATE_CHARGE_MID )
		{
			ShootNormal( true );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.2;
			return;
		}
		else if( m_iState == STATE_CHARGED_IDLE )
		{
			ShootCharged();
			return;
		}

		int iIdleAnim;
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			iIdleAnim = ANIM_IDLE;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER;
		}
		else
			iIdleAnim = ANIM_IDLE_EMPTY;

		self.SendWeaponAnim( iIdleAnim, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}

	void ItemPostFrame()
	{
		if( m_iState == STATE_CHARGED_IDLE )
		{
			if( m_flNextLoopSound > 0.0 and m_flNextLoopSound < g_Engine.time )
			{
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_CHARGE_LOOP], VOL_NORM, ATTN_NORM );
				m_flNextLoopSound = g_Engine.time + 3.0;
			}

			if( m_flUpdateHuntersEye > 0.0 and m_flUpdateHuntersEye < g_Engine.time )
			{
				HuntersEye();

				m_flUpdateHuntersEye = g_Engine.time + CSOW_SKILL_RATE;
			}
		}

		BaseClass.ItemPostFrame();
	}

	void MuzzleflashThink()
	{
		if( m_pDynamicEnt is null )
		{
			SetThink( null );
			return;
		}

		Vector vecOrigin;
		GetAttachment( ATTACH_MUZZLE1, vecOrigin, void );
		g_EntityFuncs.SetOrigin( m_pDynamicEnt, vecOrigin );

		pev.nextthink = g_Engine.time + 0.01;
	}

	void HuntersEye()
	{
		CBaseEntity@ pTarget;
		Vector vecStartOrigin, vecView, vecEnd, vecTargetOrigin, vecEndPosEsp, vecVectorTmp2, vecAnglesEsp;
		bool bSee;
		float flRange = cso::MetersToUnits(CSOW_SKILL_RANGE);

		vecStartOrigin = m_pPlayer.pev.origin;
		vecView = m_pPlayer.pev.view_ofs;
		vecAnglesEsp = m_pPlayer.pev.v_angle;

		Vector vecRight, vecUp;
		{
			Vector vecUnused;
			g_EngineFuncs.AngleVectors( vecAnglesEsp, vecUnused, vecRight, vecUp );
		}

		vecRight = vecRight.Normalize();
		vecUp = vecUp.Normalize();
		vecStartOrigin = vecStartOrigin + vecView;

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pPlayer.pev.origin, flRange, "*", "classname")) !is null )
		{
			if( !pTarget.pev.FlagBitSet(FL_MONSTER) or !pTarget.IsAlive() )
				continue;

			bSee = false;
			vecEnd = pTarget.Center();
			TraceResult tr;

			g_Utility.TraceLine( vecStartOrigin, vecEnd, ignore_monsters, m_pPlayer.edict(), tr ); //257 ??

			if( tr.pHit !is null and pTarget.edict() !is tr.pHit and pTarget.edict() !is tr.pHit.vars.owner )
			{
				bSee = true;
				vecEndPosEsp = tr.vecEndPos;
			}

			if( !bSee )
			{
				vecView = pTarget.pev.view_ofs;
				vecEnd = vecEnd + vecView;

				g_Utility.TraceLine( vecStartOrigin, vecEnd, ignore_monsters, m_pPlayer.edict(), tr ); //257 ??

				if( tr.pHit !is null and pTarget.edict() !is tr.pHit and pTarget.edict() !is tr.pHit.vars.owner )
				{
					bSee = true;
					vecEndPosEsp = tr.vecEndPos;
				}
			}

			if( bSee or (pTarget.pev.origin - m_pPlayer.pev.origin).Length() < flRange )
			{
				if( !bSee )
				{
					vecEnd = pTarget.pev.origin;
					g_Utility.TraceLine( vecStartOrigin, vecEnd, ignore_monsters, m_pPlayer.edict(), tr ); //257 ??
					vecEndPosEsp = tr.vecEndPos;
				}

				Vector vecVector, vecVectorTmp;

				vecVector = vecEndPosEsp - vecStartOrigin;
				vecVector = vecVector.Normalize();
				vecVector = vecVector * 5.0;
				vecVector = vecEndPosEsp - vecVector;
				vecTargetOrigin = pTarget.pev.origin;
				vecVectorTmp = vecTargetOrigin - vecStartOrigin;
				vecVectorTmp2 = vecVector - vecStartOrigin;

				float flLen = ( vecVectorTmp2.Length() / vecVectorTmp.Length() ) * GetScaleForMonster( pTarget );

				array<Vector> vecFourPoints(4);

				Vector vecTmpUp, vecTmpRight;

				vecTmpUp = vecUp;
				vecTmpRight = vecRight;
				vecTmpUp = vecTmpUp * flLen;
				vecTmpRight = vecTmpRight * flLen;

				vecFourPoints[0] = vecVector;
				vecFourPoints[0] = vecFourPoints[0] + vecTmpUp;
				vecFourPoints[0] = vecFourPoints[0] + vecTmpRight;

				vecFourPoints[1] = vecVector;
				vecFourPoints[1] = vecFourPoints[1] + vecTmpUp;
				vecFourPoints[1] = vecFourPoints[1] - vecTmpRight;

				vecFourPoints[2] = vecVector;
				vecFourPoints[2] = vecFourPoints[2] - vecTmpUp;
				vecFourPoints[2] = vecFourPoints[2] + vecTmpRight;

				vecFourPoints[3] = vecVector;
				vecFourPoints[3] = vecFourPoints[3] - vecTmpUp;
				vecFourPoints[3] = vecFourPoints[3] - vecTmpRight;

				DrawHuntersEye( vecFourPoints[0], vecFourPoints[1] );
				DrawHuntersEye( vecFourPoints[0], vecFourPoints[2] );
				DrawHuntersEye( vecFourPoints[2], vecFourPoints[3] );
				DrawHuntersEye( vecFourPoints[3], vecFourPoints[1] );
			}
		}
	}

	void DrawHuntersEye( Vector vecStart, Vector vecEnd )
	{
		NetworkMessage m1( MSG_ONE_UNRELIABLE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
			m1.WriteByte( TE_BEAMPOINTS );
			m1.WriteCoord( vecStart.x );//start position
			m1.WriteCoord( vecStart.y );
			m1.WriteCoord( vecStart.z );
			m1.WriteCoord( vecEnd.x );//end position
			m1.WriteCoord( vecEnd.y );
			m1.WriteCoord( vecEnd.z );
			m1.WriteShort( m_iHuntersEyeSprite );//sprite index
			m1.WriteByte( 0 );//starting frame
			m1.WriteByte( 0 );//framerate in 0.1's
			m1.WriteByte( 1 );//life in 0.1's
			m1.WriteByte( 25 );//width in 0.1's
			m1.WriteByte( 0 );//noise amplitude in 0.1's
			m1.WriteByte( CSOW_SKILL_COLOR.r );//red
			m1.WriteByte( CSOW_SKILL_COLOR.g );//green
			m1.WriteByte( CSOW_SKILL_COLOR.b );//blue
			m1.WriteByte( 175 );//brightness
			m1.WriteByte( 0 );//scroll speed
		m1.End();
	}

	float GetScaleForMonster( CBaseEntity@ pMonster, float flScaleIncrease = 0.4, float flScaleDecrease = 1.5 )
	{
		int iBaseScale = CSOW_SKILL_SIZE;
		int iMinScale = 10;
		int iMaxScale = 100;
		float flBaseMobVolume = 73728;
		float flScale;

		float flMobVolume = (pMonster.pev.size.x * pMonster.pev.size.y * pMonster.pev.size.z);
		if( flMobVolume > flBaseMobVolume ) flScale = (iBaseScale * (flMobVolume/flBaseMobVolume)) * flScaleIncrease;
		else if( flMobVolume < flBaseMobVolume ) flScale = (iBaseScale / (flBaseMobVolume/flMobVolume)) * flScaleDecrease;
		else flScale = iBaseScale;

		return flScale;
	}
}

class holyarrow : ScriptBaseEntity
{
	private bool m_bBeamCreated;

	EHandle m_hStuckInEntity;
	private float m_flRemoveTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_PROJ );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype	= MOVETYPE_FLY;
		pev.solid		= SOLID_BBOX;

		m_bBeamCreated = false;

		SetThink( ThinkFunction(this.ArrowThink) );
		SetTouch( TouchFunction(this.ArrowTouch) );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void ArrowThink()
	{
		if( pev.waterlevel != WATERLEVEL_DRY )
			g_Utility.BubbleTrail( pev.origin - pev.velocity * 0.1, pev.origin, 1 );

		if( !m_bBeamCreated )
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_BEAMFOLLOW );
				m1.WriteShort( self.entindex() );
				m1.WriteShort( g_EngineFuncs.ModelIndex(cso::SPRITE_TRAIL_FAILNAUGHT) );
				m1.WriteByte( 10 ); // life
				m1.WriteByte( 2 );  // width
				m1.WriteByte( 255 ); // r
				m1.WriteByte( 127 ); // g
				m1.WriteByte( 127 ); // b
				m1.WriteByte( 127 ); // brightness
			m1.End();

			NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m2.WriteByte( TE_BEAMFOLLOW );
				m2.WriteShort( self.entindex() );
				m2.WriteShort( g_EngineFuncs.ModelIndex(cso::SPRITE_TRAIL_FAILNAUGHT) );
				m2.WriteByte( 10 ); // life
				m2.WriteByte( 2 );  // width
				m2.WriteByte( 255 ); // r
				m2.WriteByte( 255 ); // g
				m2.WriteByte( 255 ); // b
				m2.WriteByte( 127 ); // brightness
			m2.End();

			m_bBeamCreated = true;
		}

		pev.nextthink = g_Engine.time + 0.1;
	}

	void ArrowTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		SetTouch(null);
		SetThink(null);

		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			if( !pOther.IsPlayer() )
			{
				TraceResult tr = g_Utility.GetGlobalTrace();
				entvars_t@ pevOwner = pev.owner.vars;

				g_WeaponFuncs.ClearMultiDamage();

				pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BULLET | DMG_NEVERGIB ); 

				if( !pOther.IsBSPModel() and pOther.IsAlive() and !pOther.IsPlayerAlly() )
					HandleStacks( EHandle(pOther) );

				g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, pCSOWSounds[SND_HIT], VOL_NORM, ATTN_NORM );

				if( pOther.pev.ClassNameIs("func_breakable") )
				{
					StickToWall();

					return;
				}
				else
					self.Killed( pev, GIB_NEVER );
			}
			else
				if( ARROWS_STICK_TO_PLAYERS ) StickToPlayer( pOther );
		}
		else
		{
			StickToWall();

			if( g_EngineFuncs.PointContents(pev.origin) != CONTENTS_WATER )
				g_Utility.Sparks( pev.origin );
		}
	}

	void StickToPlayer( CBaseEntity@ pEntity )
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT], Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7) );

		SetThink( ThinkFunction(this.ArrowStickToPlayerThink) );
		pev.nextthink = g_Engine.time;

		Vector vecDir = pev.velocity.Normalize();
		g_EntityFuncs.SetOrigin( self, pev.origin + vecDir * 12 ); //Push in a bit
		pev.angles = Math.VecToAngles( vecDir );
		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;
		pev.velocity = g_vecZero;
		pev.avelocity.z = 0;
		pev.angles.z = Math.RandomLong(0, 360);

		m_hStuckInEntity = EHandle( pEntity );
		m_flRemoveTime = g_Engine.time + CSOW_TIME_ARROW_LIFE;
	}

	void StickToWall()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT_WALL], Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7) );

		SetThink( ThinkFunction(this.RemoveThink) );
		pev.nextthink = g_Engine.time + CSOW_TIME_ARROW_LIFE;

		Vector vecDir = pev.velocity.Normalize();
		g_EntityFuncs.SetOrigin( self, pev.origin - vecDir * 6 ); //Pull out of the wall a bit

		pev.angles = Math.VecToAngles( vecDir );
		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_FLY;
		pev.velocity = g_vecZero;
		pev.avelocity.z = 0;
		pev.angles.z = Math.RandomLong(0, 360);
	}

	void ArrowStickToPlayerThink()
	{
		if( g_Engine.time >= m_flRemoveTime )
			g_EntityFuncs.Remove( self );

		if( m_hStuckInEntity.IsValid() )
		{
			CBaseEntity@ pStuckInMonster = m_hStuckInEntity.GetEntity();

			if( pStuckInMonster !is null and pStuckInMonster.IsAlive() )
				pev.velocity = pStuckInMonster.pev.velocity;
			else
				g_EntityFuncs.Remove( self );
		}
		else
			g_EntityFuncs.Remove( self );

		pev.nextthink = g_Engine.time + 0.05;
	}

	void HandleStacks( EHandle &in hMonster )
	{
		if( pev.owner is null ) return;

		bool bStackentFound = false;
		fn_stackent@ pStackEnt = null;
		CBaseEntity@ cbeStackent = null;
		while( (@cbeStackent = g_EntityFuncs.FindEntityByClassname(cbeStackent, "fn_stackent")) !is null )
		{
			if( cbeStackent.pev.owner is pev.owner ) //Stackent found and is owned by the same player.
			{
				@pStackEnt = cast<fn_stackent@>(CastToScriptClass(cbeStackent));

				if( pStackEnt.m_hMonster.GetEntity() is hMonster.GetEntity() ) //Stackent has the same target, increase stack and reset removetime.
				{
					bStackentFound = true;
					pStackEnt.m_iArrowStack++;
					pStackEnt.m_flRemoveTime = g_Engine.time + CSOW_STACK_LIFETIME;
				}
			}
		}

		if( !bStackentFound ) //No existing stackent, create one, set the target, and set stack to 1
		{
			@cbeStackent = g_EntityFuncs.Create( "fn_stackent", pev.origin, g_vecZero, false, pev.owner );
			@pStackEnt = cast<fn_stackent@>(CastToScriptClass(cbeStackent));
			pStackEnt.m_hMonster = EHandle(hMonster);
			pStackEnt.m_iArrowStack = 1;
			pStackEnt.m_flRemoveTime = g_Engine.time + CSOW_STACK_LIFETIME;
			pStackEnt.pev.dmg = pev.dmg;
		}
	}

	void DoRadiusDamage( Vector vecOrigin, float flRadius )
	{
		CBaseEntity@ pTarget = null;

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, vecOrigin, flRadius, "*", "classname")) !is null )
		{
			if( pTarget.edict() is pev.owner or !pTarget.IsMonster() or pTarget.IsPlayer() or !pTarget.IsAlive() )
				continue;

			Vector vecTargetOrigin = pTarget.pev.origin;

			if( is_wall_between_points(pev.origin, vecTargetOrigin, pev.owner) ) continue;

			pTarget.TakeDamage( pev.owner.vars, pev.owner.vars, pev.dmg * 5, (DMG_NEVERGIB|DMG_GENERIC) ); 
		}
	}

	bool is_wall_between_points( Vector start, Vector end, edict_t@ ignore_ent )
	{
		TraceResult ptr;

		g_Utility.TraceLine( start, end, ignore_monsters, ignore_ent, ptr );

		return (end - ptr.vecEndPos).Length() > 0;
	}

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}
}

class fn_stackent : ScriptBaseEntity
{
	EHandle m_hMonster;
	float m_flRemoveTime;
	int m_iArrowStack;
	int iBaseMarkScale = 5;
	int iMinMarkScale = 3;
	int iMaxMarkScale = 25;
	float flBaseMobVolume = 73728;
	float flMarkScale;

	void Spawn()
	{
		SetThink( ThinkFunction(this.StackThink) );
		pev.nextthink = g_Engine.time + 0.05;
	}

	void StackThink()
	{
		if( pev.owner is null or !m_hMonster.IsValid() or !m_hMonster.GetEntity().IsAlive() or g_Engine.time >= m_flRemoveTime )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		CBaseEntity@ pMonster = m_hMonster.GetEntity();
		Vector vecOrigin = pMonster.pev.origin;
		vecOrigin.z += pMonster.pev.size.z + 8.0;

		if( m_iArrowStack == 5 )
		{
			Explode( pMonster );
			g_EntityFuncs.Remove( self );
			return;
		}

		float flMobVolume = (pMonster.pev.size.x * pMonster.pev.size.y * pMonster.pev.size.z);
		if( flMobVolume > flBaseMobVolume ) flMarkScale = (iBaseMarkScale * (flMobVolume/flBaseMobVolume)) * 0.4;
		else if( flMobVolume < flBaseMobVolume ) flMarkScale = (iBaseMarkScale / (flBaseMobVolume/flMobVolume)) * 1.5;
		else flMarkScale = iBaseMarkScale;

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pev.owner );
			m1.WriteByte( TE_SPRITE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(pDamageMarks[m_iArrowStack]) );
			m1.WriteByte( Math.clamp(iMinMarkScale, iMaxMarkScale, int(flMarkScale)) ); // scale * 10
			m1.WriteByte( 150 ); // brightness
		m1.End();

		pev.nextthink = g_Engine.time + 0.05;
	}

	void Explode( CBaseEntity@ pMonster )
	{
		Vector vecOrigin = pMonster.pev.origin;
		int iBaseScale = 10;
		int iMinScale = 3;
		int iMaxScale = 40;
		float flScale;

		float flMobVolume = (pMonster.pev.size.x * pMonster.pev.size.y * pMonster.pev.size.z);
		if( flMobVolume > flBaseMobVolume ) flScale = (iBaseScale * (flMobVolume/flBaseMobVolume)) * 0.4;
		else if( flMobVolume < flBaseMobVolume ) flScale = (iBaseScale / (flBaseMobVolume/flMobVolume)) * 1.5;
		else flScale = iBaseScale;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z + (pMonster.pev.size.z/2) );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLODE) );
			m1.WriteByte( Math.clamp(iMinScale, iMaxScale, int(flScale)) ); // scale * 10
			m1.WriteByte( 30 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pCSOWSounds[SND_EXPLODE], VOL_NORM, ATTN_NORM );

		float flRadius = (pev.dmg * flScale) * 0.3; //CSOW_ARROW_EXP_RADIUS
		DoRadiusDamage( vecOrigin, flRadius );
	}

	void DoRadiusDamage( Vector vecOrigin, float flRadius )
	{
		CBaseEntity@ pTarget = null;

		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, vecOrigin, flRadius, "*", "classname")) !is null )
		{
			if( pTarget.edict() is pev.owner or !pTarget.IsMonster() or pTarget.IsPlayer() or !pTarget.IsAlive() )
				continue;

			Vector vecTargetOrigin = pTarget.pev.origin;

			if( is_wall_between_points(pev.origin, vecTargetOrigin, pev.owner) ) continue;

			pTarget.TakeDamage( pev.owner.vars, pev.owner.vars, pev.dmg * 5, (DMG_NEVERGIB|DMG_GENERIC) ); 
		}
	}

	bool is_wall_between_points( Vector start, Vector end, edict_t@ ignore_ent )
	{
		TraceResult ptr;

		g_Utility.TraceLine( start, end, ignore_monsters, ignore_ent, ptr );

		return (end - ptr.vecEndPos).Length() > 0;
	}
}

class ammo_holyarrows : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		g_EntityFuncs.SetModel( self, MODEL_AMMO );
		pev.scale = 2.0;
		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( CSOW_DEFAULT_GIVE, "holyarrows", CSOW_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::fn_stackent", "fn_stackent" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::holyarrow", "holyarrow" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::ammo_holyarrows", "ammo_holyarrows" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::weapon_failnaught", "weapon_failnaught" );
	g_ItemRegistry.RegisterWeapon( "weapon_failnaught", "custom_weapons/cso", "holyarrows", "", "ammo_holyarrows" );
}

} //namespace cso_failnaught END

/*
TODO
PrimaryAttack autoaim
Make a proper ammo model?
Add muzzleflashes with DoMuzzleflash ??
Make arrows stuck in players turn with them
*/