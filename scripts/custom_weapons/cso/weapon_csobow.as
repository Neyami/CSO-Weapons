namespace cso_bow
{
const int CSOW_DEFAULT_GIVE					= 6;
const int CSOW_MAX_AMMO						= 60;
const int CSOW_WEIGHT							= 10;
const float CSOW_DAMAGE1						= 70; //78
const float CSOW_DAMAGE2						= 140; //127
const float CSOW_TIME_DELAY					= 0.28;
const float CSOW_TIME_DRAW					= 0.75;
const float CSOW_TIME_IDLE						= 1.7;
const float CSOW_TIME_FIRE_TO_IDLE1		= 0.5;
const float CSOW_TIME_FIRE_TO_IDLE2		= 1.3;
const float CSOW_TIME_FIRE_TO_IDLE3		= 0.7;
const float CSOW_TIME_RELOAD1				= 0.45;
const float CSOW_TIME_RELOAD2				= 1.25;
const float CSOW_TIME_CHARGE				= 0.5;
const float CSOW_TIME_ARROW_LIFE			= 10.0;
const float CSOW_ARROW_SPEED				= 2000;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1.0, -2.0);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(1.0, -1.0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE							= VECTOR_CONE_2DEGREES;

const string CSOW_ANIMEXT						= "egon";

const string MODEL_VIEW							= "models/custom_weapons/cso/v_bow.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_bow.mdl";
const string MODEL_PLAYER_EMPTY			= "models/custom_weapons/cso/p_bow_empty.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_bow.mdl";
const string MODEL_PROJ							= "models/custom_weapons/cso/arrow.mdl";
const string MODEL_AMMO						= "models/w_crossbow_clip.mdl";

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
	ANIM_CHARGE_IDLE2, //9
	ANIM_CHARGE_SHOOT1,
	ANIM_CHARGE_SHOOT1_EMPTY,
	ANIM_CHARGE_SHOOT2,
	ANIM_CHARGE_SHOOT2_EMPTY //13
};

enum csowsounds_e
{
	SND_CHARGE_FINISH = 0,
	SND_CHARGE_SHOOT_EMPTY,
	SND_CHARGE_SHOOT,
	SND_CHARGE_START1,
	SND_CHARGE_START2, //4
	SND_DRAW,
	SND_SHOOT,
	SND_HIT_WALL,
	SND_HIT //8
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cso/bow_charge_finish1.wav",
	"custom_weapons/cso/bow_charge_shoot1_empty.wav",
	"custom_weapons/cso/bow_charge_shoot2.wav",
	"custom_weapons/cso/bow_charge_start1.wav",
	"custom_weapons/cso/bow_charge_start2.wav",
	"custom_weapons/cso/bow_draw.wav",
	"custom_weapons/cso/bow-shoot1.wav",
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

class weapon_csobow : CBaseCustomWeapon
{
	private int m_iState;
	private float m_flTimeCharge;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_MAX_AMMO;
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
		g_Game.PrecacheModel( PENETRATE::SPRITE_TRAIL_CSOBOW );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_csobow.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud12.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud98.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= WEAPON_NOCLIP;
		info.iSlot			= CSO::CSOBOW_SLOT - 1;
		info.iPosition		= CSO::CSOBOW_POSITION - 1;
		info.iWeight		= CSOW_WEIGHT;
		info.iFlags			= ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_csobow") );
		m.End();

		m_iState = STATE_NONE;
		m_flTimeCharge = 0.0;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bool bHasAmmo = (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0);
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(bHasAmmo ? MODEL_PLAYER : MODEL_PLAYER_EMPTY), (bHasAmmo ? ANIM_DRAW : ANIM_DRAW_EMPTY), CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		m_iState = STATE_NONE;
		m_flTimeCharge = 0.0;
		//SetThink(null);

		BaseClass.Holster( skipLocal );
	}

	~weapon_csobow()
	{
		self.m_fInReload = false;
		m_iState = STATE_NONE;
		m_flTimeCharge = 0.0;
		//SetThink(null);
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
				self.SendWeaponAnim( ANIM_CHARGE_START );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

				m_iState = STATE_CHARGE_START;

				break;
			}

			case STATE_CHARGE_START:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE1 );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_flTimeCharge = g_Engine.time;
				m_iState = STATE_CHARGE_IDLE;

				break;
			}

			case STATE_CHARGE_IDLE:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE1 );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_iState = STATE_CHARGE_IDLE;

				if( g_Engine.time >= (m_flTimeCharge + CSOW_TIME_CHARGE) )
				{
					self.SendWeaponAnim( ANIM_CHARGE_FINISH );
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

					m_iState = STATE_CHARGE_FINISH;
				}

				break;
			}

			case STATE_CHARGE_FINISH:
			{
				self.SendWeaponAnim( ANIM_CHARGE_IDLE2 );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.35;

				m_iState = STATE_CHARGE_FINISH;

				break;
			}
		}
	}

	void ShootNormal( bool bInCharge )
	{
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( bInCharge ? ANIM_CHARGE_SHOOT1 : ANIM_SHOOT1 );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[bInCharge ? SND_CHARGE_SHOOT_EMPTY : SND_SHOOT], VOL_NORM, ATTN_NORM );

		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		Vector vecOrigin, vecEnd, vecAngles, vecVelocity;

		get_position( 40.0, 0.0, 0.0, vecOrigin );
		get_position( 4096.0, 0.0, 0.0, vecEnd );
		vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x *= -1;

		CBaseEntity@ pArrow = g_EntityFuncs.Create( "csoarrow", vecOrigin, vecAngles, false, m_pPlayer.edict() );

		float flSpeed = (m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD) ? CSOW_ARROW_SPEED : CSOW_ARROW_SPEED/2;
		vecVelocity = vecEnd - vecOrigin;
		float num = sqrt( flSpeed*flSpeed / (vecVelocity.x*vecVelocity.x + vecVelocity.y*vecVelocity.y + vecVelocity.z*vecVelocity.z) );
		vecVelocity = vecVelocity * num;
		pArrow.pev.velocity = vecVelocity;

		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_X : CSOW_RECOIL_STANDING_X;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_Y : CSOW_RECOIL_STANDING_Y;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + (bInCharge ? CSOW_TIME_RELOAD2 : CSOW_TIME_RELOAD1);

		m_iState = STATE_NONE;
	}

	void ShootCharged()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( ANIM_CHARGE_SHOOT2 );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_CHARGE_SHOOT], VOL_NORM, ATTN_NORM );

		PENETRATE::FirePenetratingBullets( m_pPlayer.GetGunPosition(), g_Engine.v_forward, 0, 4096, 2, PENETRATE::BULLET_PLAYER_CSOBOW, CSOW_DAMAGE2, 1.0, EHandle(m_pPlayer), false, m_pPlayer.random_seed ); //multiply CSOW_DAMAGE2 by 1.5 ??
		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_X : CSOW_RECOIL_STANDING_X;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_Y : CSOW_RECOIL_STANDING_Y;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD2;

		m_iState = STATE_NONE;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iState == STATE_CHARGE_START or m_iState == STATE_CHARGE_IDLE )
		{
			ShootNormal( true );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.2;
			return;
		}
		else if( m_iState == STATE_CHARGE_FINISH )
		{
			ShootCharged();
			return;
		}

		self.SendWeaponAnim( (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_IDLE : ANIM_IDLE_EMPTY);
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}

	void get_position( float flForward, float flRight, float flUp, Vector &out vecOut )
	{
		Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

		vecOrigin = m_pPlayer.pev.origin;
		vecUp = m_pPlayer.pev.view_ofs;

		for( int i = 0; i < 3; i++ )
			vecOrigin[i] = vecOrigin[i] + vecUp[i];

		vecAngle = m_pPlayer.pev.v_angle;

		g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

		for( int j = 0; j < 3; j++ )
			vecOut[j] = vecOrigin[j] + vecForward[j] * flForward + vecRight[j] * flRight + vecUp[j] * flUp;
	}
}

class csoarrow : ScriptBaseEntity
{
	private bool m_bBeamCreated;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_PROJ );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype	= MOVETYPE_FLY;
		pev.solid		= SOLID_BBOX;
		pev.gravity = 0.01;

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
				pOther.TraceAttack( pevOwner, CSOW_DAMAGE1, pev.velocity.Normalize(), tr, DMG_NEVERGIB ); 
			else
				pOther.TraceAttack( pevOwner, CSOW_DAMAGE1, pev.velocity.Normalize(), tr, DMG_BULLET | DMG_NEVERGIB ); 

			g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

			pev.velocity = g_vecZero;

			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT], VOL_NORM, ATTN_NORM );

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
				m1.WriteShort( g_EngineFuncs.ModelIndex(PENETRATE::SPRITE_TRAIL_CSOBOW) );
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
				m2.WriteShort( g_EngineFuncs.ModelIndex(PENETRATE::SPRITE_TRAIL_CSOBOW) );
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

	void RemoveThink()
	{
		g_EntityFuncs.Remove( self );
	}
}

class ammo_csoarrows : ScriptBasePlayerAmmoEntity
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

		if( pOther.GiveAmmo( iGive, "csoarrows", CSOW_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_bow::csoarrow", "csoarrow" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_bow::ammo_csoarrows", "ammo_csoarrows" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_bow::weapon_csobow", "weapon_csobow" );
	g_ItemRegistry.RegisterWeapon( "weapon_csobow", "custom_weapons/cso", "csoarrows" );
}

} //namespace cso_bow END

/*
TODO
Make a proper ammo model?
*/
