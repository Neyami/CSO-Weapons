namespace cso_failnaught
{

const int CSOW_DEFAULT_GIVE					= 25;
const int CSOW_MAX_AMMO						= 250;
const int  CSOW_ARROW_MAX_STACKS		= 5; //Number of arrows that need to hit an enemy to cause an explosion
const float CSOW_DAMAGE1						= 40; //40
const float CSOW_DAMAGE2						= 200; //33
const float CSOW_TIME_DELAY					= 0.3;
const float CSOW_TIME_DRAW					= 1.5; //1.7
const float CSOW_TIME_IDLE						= 2.7; //3.0
const float CSOW_TIME_FIRE_TO_IDLE1		= 0.5;
const float CSOW_TIME_FIRE_TO_IDLE2		= 1.3;
const float CSOW_TIME_FIRE_TO_IDLE3		= 0.7;
const float CSOW_TIME_RELOAD1				= 0.45;
const float CSOW_TIME_RELOAD2				= 1.25;
const float CSOW_TIME_CHARGE				= 1.0;
const float CSOW_TIME_ARROW_LIFE			= 10.0;
const float CSOW_ARROW_SPEED				= 2000;
const float CSOW_ARROW_EXP_RADIUS		= 90; //Not used atm, radius is based on mob volume
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1.0, -2.0);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(1.0, -1.0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE							= VECTOR_CONE_2DEGREES;

const string CSOW_ANIMEXT						= "egon";

const string MODEL_VIEW							= "models/custom_weapons/cso/v_huntbow.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_huntbow.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_huntbow.mdl";
const string MODEL_PROJ							= "models/custom_weapons/cso/huntbow_arrow.mdl";
const string MODEL_AMMO						= "models/w_crossbow_clip.mdl";

const string SPRITE_EXPLODE					= "sprites/custom_weapons/cso/skull.spr";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_DRAW,
	ANIM_CHARGE_START,
	ANIM_CHARGE_FINISH,
	ANIM_CHARGE_IDLE1, //5
	ANIM_CHARGE_IDLE2,
	ANIM_CHARGE_SHOOT1,
	ANIM_CHARGE_SHOOT1_EMPTY,
	ANIM_CHARGE_SHOOT2,
	ANIM_CHARGE_SHOOT2_EMPTY //10
};

enum csowsounds_e
{
	SND_CHARGE_LOOP = 0,
	SND_UNUSED1, //SND_CHARGE_RELOAD1
	SND_UNUSED2, //SND_CHARGE_RELOAD2
	SND_CHARGE_START_FX,
	SND_UNUSED3, //SND_CHARGE_START1
	SND_UNUSED4, //5, SND_DRAW
	SND_UNUSED5, //SND_RELOAD
	SND_UNUSED6, //SND_RELOAD_EMPTY
	SND_SHOOT,
	SND_CHARGE_SHOOT,
	SND_EXPLODE,
	SND_HIT_WALL,
	SND_HIT //12
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/failnaught_charge_loop_fx.wav",
	"custom_weapons/cso/failnaught_charge_shoot1.wav",
	"custom_weapons/cso/failnaught_charge_shoot2.wav",
	"custom_weapons/cso/failnaught_charge_start_fx.wav",
	"custom_weapons/cso/failnaught_charge_start1.wav",
	"custom_weapons/cso/failnaught_draw.wav",
	"custom_weapons/cso/failnaught_shoot1.wav",
	"custom_weapons/cso/failnaught_shoot1_empty.wav",
	"custom_weapons/cso/failnaught-1.wav",
	"custom_weapons/cso/failnaught-2.wav",
	"custom_weapons/cso/failnaught-2_exp.wav",
	"custom_weapons/cso/xbow_hit1.wav",
	"custom_weapons/cso/xbow_hitbod1.wav"
};

enum csowmodes_e
{
	STATE_NONE = 0,
	STATE_CHARGE_START,
	STATE_CHARGE_IDLE,
	STATE_CHARGE_FINISH
};

class weapon_failnaught : CBaseCSOWeapon
{
	EHandle m_eMonster;
	int m_iArrowStack;
	private int m_iState;
	private float m_flTimeCharge;
	private float m_flNextLoopSound;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_MAX_AMMO;

		m_iArrowStack = 0;
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
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_AMMO );
		g_Game.PrecacheModel( MODEL_PROJ );
		g_Game.PrecacheModel( cso::SPRITE_TRAIL_FAILNAUGHT );
		g_Game.PrecacheModel( cso::SPRITE_TRAIL_FAILNAUGHT_EXPLODE );
		g_Game.PrecacheModel( SPRITE_EXPLODE );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_failnaught.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud41.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud213.spr" );
		//g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash208.spr" ); //
		//g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash210.spr" ); //Charge finish
		//g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash211.spr" ); //Draw, and pulling back the arrow after shooting?
		//g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash212.spr" ); //Charge idle1
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= WEAPON_NOCLIP;
		info.iAmmo1Drop	= CSOW_DEFAULT_GIVE;
		info.iSlot			= cso::FAILNAUGHT_SLOT - 1;
		info.iPosition		= cso::FAILNAUGHT_POSITION - 1;
		info.iWeight		= cso::FAILNAUGHT_WEIGHT;
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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
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

	~weapon_failnaught()
	{
		self.m_fInReload = false;
		m_iState = STATE_NONE;
		m_flTimeCharge = 0.0;
		m_flNextLoopSound = 0.0;
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

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME; //none!
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH; //none!

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
				m_iState = STATE_CHARGE_IDLE;

				break;
			}

			case STATE_CHARGE_IDLE:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_iState = STATE_CHARGE_IDLE;

				if( g_Engine.time >= (m_flTimeCharge + CSOW_TIME_CHARGE) )
				{
					self.SendWeaponAnim( ANIM_CHARGE_FINISH, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_CHARGE_START_FX], VOL_NORM, ATTN_NORM );
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = m_flNextLoopSound = g_Engine.time + 0.35;

					m_iState = STATE_CHARGE_FINISH;
				}

				break;
			}

			case STATE_CHARGE_FINISH:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_iState = STATE_CHARGE_FINISH;

				break;
			}
		}
	}

	void ShootNormal( bool bInCharge )
	{
		m_flNextLoopSound = 0.0;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( bInCharge ? ANIM_CHARGE_SHOOT1 : ANIM_SHOOT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[bInCharge ? SND_CHARGE_SHOOT : SND_SHOOT], VOL_NORM, ATTN_NORM );

		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		Vector vecOrigin, vecEnd, vecAngles, vecVelocity;

		get_position( 40.0, 0.0, 0.0, vecOrigin );
		get_position( 4096.0, 0.0, 0.0, vecEnd );
		vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x *= -1;

		CBaseEntity@ cbeArrow = g_EntityFuncs.Create( "holyarrow", vecOrigin, vecAngles, false, m_pPlayer.edict() );
		holyarrow@ pArrow = cast<holyarrow@>(CastToScriptClass(cbeArrow));
		pArrow.m_eLauncher = EHandle(self);

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

		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( ANIM_CHARGE_SHOOT2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_CHARGE_SHOOT], VOL_NORM, ATTN_NORM );

		//FireBullets3( Vector vecSrc, Vector vecDirShooting, float flSpread, float flDistance, int iPenetration, int iBulletType, float flDamage, float flRangeModifier, EHandle &in ePlayer, bool bPistol, int shared_rand )
		cso::FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, 0, 4096, 4, BULLET_PLAYER_FAILNAUGHT, CSOW_DAMAGE2, 1.0, EHandle(m_pPlayer), false, m_pPlayer.random_seed ); //multiply CSOW_DAMAGE2 by 1.5 ??

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

		if( m_iState == STATE_CHARGE_START or m_iState == STATE_CHARGE_IDLE )
		{
			ShootNormal( true );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.2;
			return;
		}
		else if( m_iState == STATE_CHARGE_FINISH )
		{
			ShootCharged();
			return;
		}

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}

	void ItemPostFrame()
	{
		if( m_iState == STATE_CHARGE_IDLE and m_flNextLoopSound > 0.0 and m_flNextLoopSound < g_Engine.time )
		{
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_CHARGE_LOOP], VOL_NORM, ATTN_NORM );

			m_flNextLoopSound = g_Engine.time + 3.0;
		}

		BaseClass.ItemPostFrame();
	}
}

class holyarrow : ScriptBaseEntity
{
	EHandle m_eLauncher;
	private bool m_bBeamCreated;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_PROJ );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype	= MOVETYPE_FLY;
		pev.solid		= SOLID_BBOX;
		pev.gravity		= 0.01;
		pev.dmg			= CSOW_DAMAGE1;

		m_bBeamCreated = false;

		SetTouch( TouchFunction(this.ArrowTouch) );
		SetThink( ThinkFunction(this.ArrowThink) );

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
			TraceResult tr = g_Utility.GetGlobalTrace();
			entvars_t@ pevOwner = pev.owner.vars;

			g_WeaponFuncs.ClearMultiDamage();

			if( pOther.IsPlayer() )
				pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NEVERGIB ); 
			else
			{
				pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BULLET | DMG_NEVERGIB ); 

				if( m_eLauncher.IsValid() and !pOther.IsBSPModel() and pOther.IsAlive() and !pOther.IsPlayerAlly() )
					HandleStacks( EHandle(pOther) );
			}

			g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

			pev.velocity = g_vecZero;

			g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, pCSOWSounds[SND_HIT], VOL_NORM, ATTN_NORM );

			self.Killed( pev, GIB_NEVER );
		}
		else
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT_WALL], Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7) );

			SetThink( ThinkFunction(this.RemoveThink) );
			pev.nextthink = g_Engine.time;

			if( pOther.pev.ClassNameIs("worldspawn") )
			{
				Vector vecDir = pev.velocity.Normalize();
				g_EntityFuncs.SetOrigin( self, pev.origin - vecDir * 6 ); //Pull out of the wall a bit
				pev.angles = Math.VecToAngles( vecDir );
				pev.solid = SOLID_NOT;
				pev.movetype = MOVETYPE_FLY;
				pev.velocity = g_vecZero;
				pev.avelocity.z = 0;
				pev.angles.z = Math.RandomLong(0, 360);
				pev.nextthink = g_Engine.time + CSOW_TIME_ARROW_LIFE;
			}

			if( g_EngineFuncs.PointContents(pev.origin) != CONTENTS_WATER )
				g_Utility.Sparks( pev.origin );
		}
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

	void HandleStacks( EHandle &in eMonster )
	{
		if( !m_eLauncher.IsValid() ) return;

		CBaseEntity@ pMonster = eMonster.GetEntity();
		CBaseEntity@ cbeLauncher = m_eLauncher.GetEntity();
		weapon_failnaught@ pLauncher = cast<weapon_failnaught@>(CastToScriptClass(cbeLauncher));

		int iBaseScale = 10;
		int iMinScale = 3;
		int iMaxScale = 40;
		float flBaseVolume = 73728;
		float flScale;

		if( !pLauncher.m_eMonster.IsValid() or pLauncher.m_eMonster.GetEntity() !is pMonster ) //Enemy hit and no currently set target or not the same as hit enemy; set enemy as target and increase stack
		{
			//g_Game.AlertMessage( at_notice, "ENEMY HIT AND NO CURRENT TARGET OR NEW TARGET\n" );
			pLauncher.m_eMonster = eMonster;
			pLauncher.m_iArrowStack = 1; //Set to 1 because this check should only happen once
		}
		else
		{
			if( pLauncher.m_eMonster.GetEntity() is pMonster ) //Enemy hit and is the same as the set target; increase stack
			{
				//g_Game.AlertMessage( at_notice, "ENEMY HIT AND AND IS THE SAME\n" );
				if( pLauncher.m_iArrowStack < CSOW_ARROW_MAX_STACKS-1 )
					pLauncher.m_iArrowStack++;
				else if( pLauncher.m_iArrowStack == CSOW_ARROW_MAX_STACKS-1 ) //The stack is one arrow away from max; cause an explosion and reset stack to 0
				{
					Vector vecOrigin = pMonster.pev.origin;
					float flMobVolume = (pMonster.pev.size.x * pMonster.pev.size.y * pMonster.pev.size.z);
					if( flMobVolume > flBaseVolume ) flScale = (iBaseScale * (flMobVolume/flBaseVolume)) * 0.4;
					else if( flMobVolume < flBaseVolume ) flScale = (iBaseScale / (flBaseVolume/flMobVolume)) * 1.5;
					else flScale = iBaseScale;

					NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
						m1.WriteByte( TE_SPRITE );
						m1.WriteCoord( vecOrigin.x );
						m1.WriteCoord( vecOrigin.y );
						m1.WriteCoord( vecOrigin.z + (pMonster.pev.size.z/2) );
						m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLODE) );
						m1.WriteByte( Math.clamp(iMinScale, iMaxScale, int(flScale)) ); // scale * 10
						m1.WriteByte( 150 ); // brightness
					m1.End();

					g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pCSOWSounds[SND_EXPLODE], VOL_NORM, ATTN_NORM );
					float flRadius = (pev.dmg * flScale) * 0.3; //CSOW_ARROW_EXP_RADIUS
					//g_WeaponFuncs.RadiusDamage( vecOrigin, self.pev, pev.owner.vars, pev.dmg * 5, (pev.dmg*5) * 2.5, CLASS_NONE, DMG_GENERIC );
					DoRadiusDamage( vecOrigin, flRadius );
					//g_Game.AlertMessage( at_notice, "Damage radius: %1\n", flRadius );

					pLauncher.m_iArrowStack = 0;
				}
			}
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
		int iGive;

		iGive = CSOW_DEFAULT_GIVE;

		if( pOther.GiveAmmo( iGive, "holyarrows", CSOW_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::holyarrow", "holyarrow" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::ammo_holyarrows", "ammo_holyarrows" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_failnaught::weapon_failnaught", "weapon_failnaught" );
	g_ItemRegistry.RegisterWeapon( "weapon_failnaught", "custom_weapons/cso", "holyarrows", "", "ammo_holyarrows" );
}

} //namespace cso_failnaught END

/*
TODO
PrimaryAttack autoaim
Stacks on more than one mob at a time
Autoremove stacks after a certain time?
Hunter's Instinct, see mobs through walls
Make a proper ammo model?
Add viewmodel muzzleflashes somehow (the model events don't show up properly)
Add muzzleflashes somehow, they don't work properly when put in the model's .qc
*/