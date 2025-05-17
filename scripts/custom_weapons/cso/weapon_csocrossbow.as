namespace cso_crossbow
{

const string CSOW_NAME								= "weapon_csocrossbow";

const int CSOW_DEFAULT_GIVE						= 50;
const int CSOW_MAX_CLIP 								= 50;
const int CSOW_MAX_AMMO							= 200;
const float CSOW_DAMAGE								= 30; //42 ??
const float CSOW_TIME_DELAY1						= 0.14; //430 RPM ??
const float CSOW_TIME_DELAY2						= 0.25;
const float CSOW_TIME_DRAW						= 1.0;
const float CSOW_TIME_IDLE							= 1.9;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD					= 3.5;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-0.5, -1.0);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(-0.5, 0.5);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(-0.5, -1.0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(-0.5, 0.5);

const int CSOW_ZOOMFOV								= 30;
const int BOLT_AIR_VELOCITY							= 2000;
const int BOLT_WATER_VELOCITY					= 1000;

const string CSOW_ANIMEXT							= "bow";
const string CSOW_ANIMEXT_ZOOM				= "bowscope";

const string MODEL_VIEW								= "models/custom_weapons/cso/v_crossbow.mdl";
const string MODEL_VIEW_SCOPE					= "models/custom_weapons/cso/v_crossbow_scope.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/p_crossbow.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/w_crossbow.mdl";
const string MODEL_BOLT								= "models/custom_weapons/cso/crossbow_bolt.mdl";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW
};

enum csowsounds_e
{
	SND_SHOOT = 1,
	SND_HIT_WALL,
	SND_HIT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/crossbow-1.wav",
	"custom_weapons/cso/xbow_hit1.wav",
	"custom_weapons/cso/xbow_hitbod1.wav",
	"custom_weapons/cso/crossbow_draw.wav",
	"custom_weapons/cso/crossbow_foley1.wav",
	"custom_weapons/cso/crossbow_foley2.wav",
	"custom_weapons/cso/crossbow_foley3.wav",
	"custom_weapons/cso/crossbow_foley4.wav",
	//"custom_weapons/cso/crossbowex_draw.wav" //uncomment this line if using the advance (ex) skin
};

class weapon_csocrossbow : CBaseCSOWeapon
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_VIEW_SCOPE );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_BOLT );
		g_Game.PrecacheModel( cso::MODEL_CSOBOLTS );

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
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud44.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/sniper_scope.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot				= cso::CSOCROSSBOW_SLOT - 1;
		info.iPosition		= cso::CSOCROSSBOW_POSITION - 1;
		info.iWeight			= cso::CSOCROSSBOW_WEIGHT;

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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW*2)));

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true;
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
			return;
		}

		HandleAmmoReduction( 1 );

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( ANIM_SHOOT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2 + g_Engine.v_right * 2;
		Vector vecDir = g_Engine.v_forward;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		CBaseEntity@ pBolt = g_EntityFuncs.Create( "csobolt", vecSrc, vecDir, false, m_pPlayer.edict() );

		Vector vecVelocity;
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			vecVelocity = vecDir * BOLT_WATER_VELOCITY;
		else
			vecVelocity = vecDir * BOLT_AIR_VELOCITY;

		float flSpread = 32.0;

		if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			flSpread = 16.0;

		if( m_pPlayer.m_iFOV != 0 )
			flSpread = 8.0;

		vecVelocity = vecVelocity + g_Engine.v_right * Math.RandomFloat(-flSpread, flSpread) + g_Engine.v_up * Math.RandomFloat(-flSpread, flSpread);

		pBolt.pev.velocity = vecVelocity;
		pBolt.pev.angles = Math.VecToAngles( pBolt.pev.velocity.Normalize() );
		pBolt.pev.avelocity.z = 10;
		pBolt.pev.dmg = flDamage;

		float flRecoilMult = 1.0;

		if( m_pPlayer.m_iFOV != 0 )
			flRecoilMult = 0.25;

		HandleRecoil( CSOW_RECOIL_STANDING_X*flRecoilMult, CSOW_RECOIL_STANDING_Y*flRecoilMult, CSOW_RECOIL_DUCKING_X*flRecoilMult, CSOW_RECOIL_DUCKING_Y*flRecoilMult );

		self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.pev.fov != 0 )
		{
			m_pPlayer.pev.viewmodel = MODEL_VIEW;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; // 0 means reset to default fov
			self.m_fInZoom = false;
			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT;
		}
		else if( m_pPlayer.pev.fov != CSOW_ZOOMFOV )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = CSOW_ZOOMFOV;
			self.m_fInZoom = true;
			m_pPlayer.m_szAnimExtension = CSOW_ANIMEXT_ZOOM;
			m_pPlayer.pev.viewmodel = MODEL_VIEW_SCOPE;
		}

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2)));
	}
}

class csobolt : ScriptBaseEntity
{
	void Spawn()
	{
		pev.movetype = MOVETYPE_FLY;
		pev.solid    = SOLID_BBOX;
		pev.gravity = 0.5;
		self.SetClassification( CLASS_NONE );

		g_EntityFuncs.SetModel( self, MODEL_BOLT );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

		SetTouch( TouchFunction(this.BoltTouch) );
		SetThink( ThinkFunction(this.BubbleThink) );
		pev.nextthink = g_Engine.time + 0.2;
	}

	void BoltTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
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
				pOther.TraceAttack( pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BULLET | DMG_NEVERGIB ); 

			g_WeaponFuncs.ApplyMultiDamage( pev, pevOwner );

			pev.velocity = g_vecZero;

			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT], 1, ATTN_NORM );

			self.Killed( pev, GIB_NEVER );
		}
		else
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT_WALL], Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7) );

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			if( pOther.pev.ClassNameIs("worldspawn") )
			{
				Vector vecDir = pev.velocity.Normalize();
				g_EntityFuncs.SetOrigin( self, pev.origin - vecDir ); //Pull out of the wall a bit
				pev.angles = Math.VecToAngles( vecDir );
				pev.solid = SOLID_NOT;
				pev.movetype = MOVETYPE_FLY;
				pev.velocity = Vector(0, 0, 0);
				pev.avelocity.z = 0;
				pev.angles.z = Math.RandomLong(0, 360);
				pev.nextthink = g_Engine.time + 10.0;

				TraceResult tr = g_Utility.GetGlobalTrace();
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}

			if( g_EngineFuncs.PointContents(pev.origin) != CONTENTS_WATER )
				g_Utility.Sparks( pev.origin );
		}
	}

	void BubbleThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.waterlevel == WATERLEVEL_DRY )
			return;

		g_Utility.BubbleTrail( pev.origin - pev.velocity * 0.1, pev.origin, 1 );
	}

	void SUB_Remove()
	{
		self.SUB_Remove();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crossbow::csobolt", "csobolt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_crossbow::weapon_csocrossbow", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "csobolts", "", "ammo_csobolts" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_csobolts" ) ) 
		cso::RegisterCSOBolts();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_crossbow END