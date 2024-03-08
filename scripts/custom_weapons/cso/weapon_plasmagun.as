namespace cso_plasmagun
{
	
const int CSOW_DEFAULT_GIVE					= 45;
const int CSOW_MAX_CLIP 						= 45;
const int CSOW_MAX_AMMO						= 200;
const int CSOW_ZOOMFOV						= 40;
const float CSOW_DAMAGE						= 43; //28?
const float CSOW_DAMAGE_RADIUS			= 88;
const float CSOW_TIME_DELAY					= 0.12;
const float CSOW_TIME_DELAY2					= 0.25;
const float CSOW_TIME_DRAW					= 0.7; //1.0
const float CSOW_TIME_IDLE						= 6.7;
const float CSOW_TIME_FIRE_TO_IDLE		= 1.0;
const float CSOW_TIME_RELOAD				= 3.5; //3.0
const float CSOW_PLASMA_SPEED				= 4096;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1.75, 1.75);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);

const string CSOW_ANIMEXT						= "m16";
const string CSOW_ANIMEXT2					= "sniperscope";

const string MODEL_VIEW							= "models/custom_weapons/cso/v_plasmagun.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_plasmagun.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_plasmagun.mdl";
const string MODEL_AMMO						= "models/custom_weapons/cso/plasmashell.mdl";

const string SPRITE_PLASMA						= "sprites/custom_weapons/cso/plasmaball.spr";
const string SPRITE_EXPLODE					= "sprites/custom_weapons/cso/plasmabomb.spr";

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
	SND_CLIPIN1,
	SND_CLIPIN2,
	SND_CLIPIN3,
	SND_DRAW,
	SND_EXPLODE,
	SND_IDLE,
	SND_SHOOT
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/plasmagun_clipin1.wav",
	"custom_weapons/cso/plasmagun_clipin2.wav",
	"custom_weapons/cso/plasmagun_clipout.wav",
	"custom_weapons/cso/plasmagun_draw.wav",
	"custom_weapons/cso/plasmagun_exp.wav",
	"custom_weapons/cso/plasmagun_idle.wav",	
	"custom_weapons/cso/plasmagun-1.wav"
};

class weapon_plasmagun : CBaseCSOWeapon
{
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

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
		g_Game.PrecacheModel( SPRITE_PLASMA );
		g_Game.PrecacheModel( SPRITE_EXPLODE );

		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_plasmagun.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud91.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud3.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash27.spr" );
		g_Game.PrecacheGeneric( "events/muzzle_plasmagun.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= cso::PLASMAGUN_SLOT - 1;
		info.iPosition		= cso::PLASMAGUN_POSITION - 1;
		info.iWeight		= cso::PLASMAGUN_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_plasmagun") );
		m.End();

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, CSOW_DEFAULT_GIVE );

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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], 0.5, ATTN_NORM );

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );
		self.m_fInReload = false;

		if( self.m_fInZoom )
			SecondaryAttack();

		BaseClass.Holster( skipLocal );
	}

	void UpdateOnRemove()
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );

		BaseClass.UpdateOnRemove();
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH; //Doesn't do anything?

		--self.m_iClip;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1, ATTN_NORM );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if( self.m_iClip == 0 and m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		Vector2D vec2dRecoilX = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_X : CSOW_RECOIL_STANDING_X;
		Vector2D vec2dRecoilY = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_RECOIL_DUCKING_Y : CSOW_RECOIL_STANDING_Y;

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( vec2dRecoilX.x, vec2dRecoilX.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( vec2dRecoilY.x, vec2dRecoilY.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 48 + g_Engine.v_right * 10 + g_Engine.v_up * -5;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecVelocity = g_Engine.v_forward * CSOW_PLASMA_SPEED;

		//If the player is moving, increase the spread
		if( m_pPlayer.pev.velocity.Length() > 0.0 )
			vecVelocity = vecVelocity + g_Engine.v_right * Math.RandomFloat(-16, 16) + g_Engine.v_up * Math.RandomFloat(-16, 16);
		else
			vecVelocity = vecVelocity + g_Engine.v_right * Math.RandomFloat(-8, 8) + g_Engine.v_up * Math.RandomFloat(-8, 8);

		dictionary keys;
		keys[ "origin" ] = vecOrigin.ToString();
		keys[ "velocity" ] = vecVelocity.ToString();

		CBaseEntity@ pPlasma = g_EntityFuncs.CreateEntity( "plasmaball", keys, false );
		@pPlasma.pev.owner = m_pPlayer.edict();

		g_EntityFuncs.DispatchSpawn( pPlasma.edict() );
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.pev.fov != 0 )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; // 0 means reset fov to default
			self.m_fInZoom = false;
			m_pPlayer.m_szAnimExtension = "m16";
		}
		else if( m_pPlayer.pev.fov != CSOW_ZOOMFOV )
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = CSOW_ZOOMFOV;
			self.m_fInZoom = true;
			m_pPlayer.m_szAnimExtension = "sniperscope";
		}

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		if( m_pPlayer.pev.fov != 0 )
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

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], 0.5, ATTN_NORM );

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
	}
}

class plasmaball : ScriptBaseEntity
{
	void Spawn()
	{
		self.Precache();

		g_EntityFuncs.SetModel( self, SPRITE_PLASMA );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype		= MOVETYPE_FLY;
		pev.solid			= SOLID_BBOX;
		pev.rendermode	= kRenderTransAdd;
		pev.renderamt		= 250;
		pev.scale			= Math.RandomFloat( 0.1, 0.25 ); //0.3
		pev.dmg				= CSOW_DAMAGE;

		SetTouch( TouchFunction(this.PlasmaTouch) );
	}

	void Precache()
	{
		g_Game.PrecacheModel( SPRITE_EXPLODE );
	}

	void PlasmaTouch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( pOther.edict() is pev.owner or pOther.pev.classname == "plasmaball" )
			return;

		Explode();
	}

	void Explode()
	{
		Vector vecOrigin = pev.origin;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_WORLDDECAL );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteByte( Math.RandomLong(11, 13) );
		m1.End();

		TraceResult tr;
		vecOrigin = pev.origin - pev.velocity.Normalize() * 32;
		g_Utility.TraceLine( vecOrigin, vecOrigin + pev.velocity.Normalize() * 64, ignore_monsters, self.edict(), tr );

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			vecOrigin = tr.vecEndPos + (tr.vecPlaneNormal * (pev.dmg - 12) * 0.6f);

		NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m2.WriteByte( TE_EXPLOSION );
			m2.WriteCoord( vecOrigin.x );
			m2.WriteCoord( vecOrigin.y );
			m2.WriteCoord( vecOrigin.z );
			m2.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLODE) );
			m2.WriteByte( 7 ); //scale
			m2.WriteByte( 30 ); //framerate
			m2.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m2.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pCSOWSounds[SND_EXPLODE], VOL_NORM, ATTN_NORM );
		g_WeaponFuncs.RadiusDamage( vecOrigin, self.pev, pev.owner.vars, pev.dmg, CSOW_DAMAGE_RADIUS, CLASS_PLAYER_ALLY, DMG_ENERGYBEAM | DMG_NEVERGIB );

		g_EntityFuncs.Remove( self );
	}
}

class ammo_plasmashell : ScriptBasePlayerAmmoEntity
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

		if( pOther.GiveAmmo( iGive, "plasma", CSOW_MAX_AMMO ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
} 

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_plasmagun::ammo_plasmashell", "ammo_plasmashell" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_plasmagun::plasmaball", "plasmaball" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_plasmagun::weapon_plasmagun", "weapon_plasmagun" );
	g_ItemRegistry.RegisterWeapon( "weapon_plasmagun", "custom_weapons/cso", "plasma", "", "ammo_plasmashell" );
}

} //namespace cso_plasmagun END