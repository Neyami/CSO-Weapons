namespace cso_guitar
{

const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_guitar";

const int CSOW_DEFAULT_GIVE						= 30;
const int CSOW_MAX_CLIP 								= 30;
const int CSOW_MAX_AMMO							= 90;
const float CSOW_DAMAGE								= 23; //23, 54, 61
const float CSOW_TIME_DELAY						= 0.15;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 2.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 3.0;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.01785;
const float CSOW_SPREAD_WALKING				= 0.01785;
const float CSOW_SPREAD_STANDING			= 0.01718;
const float CSOW_SPREAD_DUCKING				= 0.01289;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -1);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_SHELL_ORIGIN				= Vector(17.0, -8.0, -4.0); //forward, right, up
const Vector CSOW_NOTE_OFFSET_DRAW		= Vector(24.0, -8.0, -4.0);
const Vector CSOW_NOTE_OFFSET_SHOOT	= Vector(17.0, -8.0, -4.0);
const Vector CSOW_NOTE_OFFSET_RELOAD	= Vector(24.0, -8.0, -4.0);

const string CSOW_ANIMEXT							= "m16"; //ak47

const string MODEL_VIEW								= "models/custom_weapons/cso/v_guitar.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_guitar.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_guitar.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/rshell.mdl";

const string SPRITE_NOTE1								= "sprites/custom_weapons/cso/ef_pianogun_note1.spr";
const string SPRITE_NOTE3								= "sprites/custom_weapons/cso/ef_pianogun_note3.spr";
const string SPRITE_NOTE4								= "sprites/custom_weapons/cso/ef_pianogun_note4.spr";

const float flCircleRadiusDraw							= 2.0;
const float flCircleRadiusShoot						= 4.0;

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/gt-1.wav",
	"custom_weapons/cso/gt_clipin.wav",
	"custom_weapons/cso/gt_clipon.wav",
	"custom_weapons/cso/gt_clipout.wav",
	"custom_weapons/cso/gt_draw.wav"
};

enum csoweffect_e
{
	EFFECT_DRAW = 0,
	EFFECT_SHOOT,
	EFFECT_RELOAD
};

class weapon_guitar : CBaseCSOWeapon
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

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
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_Game.PrecacheModel( SPRITE_NOTE1 );
		g_Game.PrecacheModel( SPRITE_NOTE3 );
		g_Game.PrecacheModel( SPRITE_NOTE4 );

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud38.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash3.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_guitar.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::GUITAR_SLOT - 1;
		info.iPosition		= cso::GUITAR_POSITION - 1;
		info.iWeight			= cso::GUITAR_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

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

		BaseClass.Holster( skiplocal );
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_NOTE_OFFSET_DRAW.x - g_Engine.v_right * CSOW_NOTE_OFFSET_DRAW.y + g_Engine.v_up * CSOW_NOTE_OFFSET_DRAW.z;
			SpawnNote( vecOrigin, EFFECT_DRAW );

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.64 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 1;
		cso::FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), 8192, iPenetration, BULLET_PLAYER_556MM, flDamage, 1.0, EHandle(m_pPlayer), m_pPlayer.random_seed );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x - g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false );

		HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

		if( Math.RandomLong(0, 1 ) == 1 )
		{
			Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_NOTE_OFFSET_DRAW.x - g_Engine.v_right * CSOW_NOTE_OFFSET_DRAW.y + g_Engine.v_up * CSOW_NOTE_OFFSET_DRAW.z;
			SpawnNote( vecOrigin, EFFECT_SHOOT );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}

	void TertiaryAttack()
	{
		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 64;

		SpawnNote( vecOrigin, EFFECT_RELOAD );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		SetThink( ThinkFunction(this.SpawnNoteThink) );
		pev.nextthink = g_Engine.time + 2.3;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD + 0.5);

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE + Math.RandomFloat(0, (CSOW_TIME_IDLE*2));
	}

	void SpawnNoteThink()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_NOTE_OFFSET_RELOAD.x - g_Engine.v_right * CSOW_NOTE_OFFSET_RELOAD.y + g_Engine.v_up * CSOW_NOTE_OFFSET_RELOAD.z;
		SpawnNote( vecOrigin, EFFECT_RELOAD );
	}

	void SpawnNote( Vector vecOrigin, int iEffectType )
	{
		CBaseEntity@ cbeNote = g_EntityFuncs.Create( "ef_guitar", vecOrigin, g_vecZero, true, m_pPlayer.edict() );
		ef_guitar@ pNote = cast<ef_guitar@>(CastToScriptClass(cbeNote));

		if( pNote !is null )
		{
			pNote.m_iEffectType = iEffectType;

			if( iEffectType == EFFECT_SHOOT ) pNote.pev.velocity = m_pPlayer.pev.velocity - g_Engine.v_right * Math.RandomFloat(50, 75) + g_Engine.v_up * Math.RandomFloat(50, 75);

			g_EntityFuncs.DispatchSpawn( pNote.self.edict() );
		}
	}
}

class ef_guitar : ScriptBaseEntity
{
	int m_iEffectType;
	private Vector m_vecOrbit;
	private Vector m_vecIdeal;
	private float m_flAngle;
	private float m_flRemoveTime;
	private float m_flCycleSprite;

	private float m_flCircleSpeed = 0.1;

	void Spawn()
	{
		Precache();

		if( m_iEffectType == EFFECT_DRAW )
		{
			g_EntityFuncs.SetModel( self, SPRITE_NOTE4 );
			m_flRemoveTime = g_Engine.time + 1.0;
			m_vecOrbit = pev.origin;
			pev.scale = 0.05;
			pev.velocity.z = 24.0;
			pev.movetype = MOVETYPE_NOCLIP;
			SetThink( ThinkFunction(this.EffectThink) );
			pev.nextthink = g_Engine.time;
		}
		else if( m_iEffectType == EFFECT_SHOOT )
		{
			g_EntityFuncs.SetModel( self, SPRITE_NOTE1 );
			m_flCycleSprite = g_Engine.time + 0.5;
			m_flRemoveTime = g_Engine.time + 1.0;
			pev.scale = 0.02;
			pev.movetype = MOVETYPE_FLY;
			SetThink( ThinkFunction(this.TossThink) );
			pev.nextthink = g_Engine.time + 0.15;
		}
		else if( m_iEffectType == EFFECT_RELOAD )
		{
			g_EntityFuncs.SetModel( self, SPRITE_NOTE3 );
			m_flCycleSprite = g_Engine.time + 0.3;
			m_flRemoveTime = g_Engine.time + 0.6;
			pev.scale = 0.02;
			pev.velocity.z = 32.0;
			pev.avelocity.z = -64;
			pev.movetype = MOVETYPE_NOCLIP;
			SetThink( ThinkFunction(this.EffectThink) );
			pev.nextthink = g_Engine.time;
		}

		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.takedamage = DAMAGE_NO;
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 200;
	}

	void Precache()
	{
		g_Game.PrecacheModel( SPRITE_NOTE1 );
		g_Game.PrecacheModel( SPRITE_NOTE3 );
		g_Game.PrecacheModel( SPRITE_NOTE4 );
	}

	void TossThink()
	{
		m_vecOrbit = pev.origin;
		pev.movetype = MOVETYPE_NOCLIP;
		pev.velocity.z = 32.0;

		SetThink( ThinkFunction(this.EffectThink) );
		pev.nextthink = g_Engine.time;
	}

	void EffectThink()
	{
		if( m_flRemoveTime < g_Engine.time )
		{
			m_flCycleSprite = 0.0;
			g_EntityFuncs.Remove( self );
			return;
		}

		if( m_iEffectType == EFFECT_DRAW )
			Circle( flCircleRadiusDraw );
		else if( m_iEffectType == EFFECT_SHOOT )
		{
			Circle( flCircleRadiusShoot );
			CycleSprite();
		}
		else if( m_iEffectType == EFFECT_RELOAD )
		{
			CycleSprite();
			WiggleSprite();
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Circle( float flRadius )
	{
		 m_flAngle -= m_flCircleSpeed;

		 double x = cos(m_flAngle) * flRadius;
		 double y = sin(m_flAngle) * flRadius;

		 x += m_vecOrbit.x;
		 y += m_vecOrbit.y;

		 pev.origin.x = x;
		 pev.origin.y = y;
	}

	void CycleSprite()
	{
		if( m_flCycleSprite > 0.0 and m_flCycleSprite < g_Engine.time )
		{
			if( pev.model == SPRITE_NOTE1 )
				g_EntityFuncs.SetModel( self, SPRITE_NOTE3 );
			else
				g_EntityFuncs.SetModel( self, SPRITE_NOTE1 );

			if( m_iEffectType == EFFECT_SHOOT )
				m_flCycleSprite = g_Engine.time + 0.4;
			else if( m_iEffectType == EFFECT_RELOAD )
				m_flCycleSprite = g_Engine.time + 0.2;
		}
	}

	void WiggleSprite()
	{
		if( pev.angles.z > 10 )
			pev.avelocity.z = -64;
		if( pev.angles.z < -10 )
			pev.avelocity.z = 64;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_guitar::ef_guitar", "ef_guitar" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_guitar::weapon_guitar", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "556", "", "ammo_556" );
}

} //namespace cso_guitar END