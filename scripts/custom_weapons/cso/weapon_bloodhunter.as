namespace cso_bloodhunter
{

const bool CSOW_DEBUG						= false;
const bool CSOW_USE_MAGDROP			= true; //Drop mag while reloading or not
const int CSOW_DEFAULT_GIVE				= 30;
const int CSOW_MAX_CLIP 					= 30;
const int CSOW_MAX_AMMO					= 100;
const int CSOW_WEIGHT						= 10;
const float CSOW_DAMAGE					= 32;
const float CSOW_DAMAGE_GREN_MIN		= 40.0; //(Random number between these two) * Level of grenade 1-3 * 0.5
const float CSOW_DAMAGE_GREN_MAX	= 50.0;
const float CSOW_GRENADE_RADIUS		= 200;
const float CSOW_GRENADE_THROW		= 800; //Range
const float CSOW_TIME_DELAY1				= 0.28f;
const float CSOW_TIME_DELAY2				= 0.83f;
const float CSOW_TIME_DRAW				= 0.8f; //1.2
const float CSOW_TIME_IDLE1				= 2.0f; //Random number between these two
const float CSOW_TIME_IDLE2				= 2.0f;
const float CSOW_TIME_FIRE_TO_IDLE	= 1.0f;
const float CSOW_TIME_RELOAD			= 3.5f;
const int CSOW_IDLE_SOUND_CHANCE		= 5; //Random between 0 and this number; if result == 1 then play idle sound
const Vector2D CSOW_RECOIL1_X			= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL1_Y			= Vector2D(0, 0);
const Vector2D CSOW_RECOIL2_X			= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL2_Y			= Vector2D(-2, 2);
const Vector CSOW_CONE_DUCKING		= VECTOR_CONE_2DEGREES;
const Vector CSOW_CONE_STANDING		= VECTOR_CONE_3DEGREES;

const string CSOW_ANIMEXT					= "uzis"; //uzis, bloodhunter, dualpistols_1

const string MODEL_VIEW		= "models/custom_weapons/cso/v_bloodhunter.mdl";
const string MODEL_PLAYER	= "models/custom_weapons/cso/p_bloodhunter.mdl";
const string MODEL_WORLD	= "models/custom_weapons/cso/w_bloodhunter.mdl";
const string MODEL_GRENADE	= "models/custom_weapons/cso/w_bloodhunter_grenade.mdl";
const string MODEL_SHELL		= "models/custom_weapons/cso/pshell.mdl";
const string MODEL_MAG		= "models/w_9mmclip.mdl";

int g_iExplosionId = 0;

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_IDLEA,
	ANIM_IDLEB,
	ANIM_IDLEC,
	ANIM_DRAW,
	ANIM_DRAWA,
	ANIM_DRAWB,
	ANIM_DRAWC,
	ANIM_SHOOT,
	ANIM_SHOOTA,
	ANIM_SHOOTB,
	ANIM_SHOOTC,
	ANIM_SHOOT_EF,
	ANIM_SHOOTA_EF,
	ANIM_SHOOTB_EF,
	ANIM_SHOOTC_EF,
	ANIM_RELOAD,
	ANIM_RELOADA,
	ANIM_RELOADB,
	ANIM_RELOADC,
	ANIM_THROW,
	ANIM_THROWA,
	ANIM_THROWB,
	ANIM_THROWC
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_CHANGE,
	SND_CLIPIN,
	SND_CLIPOUT,
	SND_DRAW,
	SND_DRAWA,
	SND_DRAWB,
	SND_DRAWC,
	SND_IDLE,
	SND_RELOADA_CLIPIN,
	SND_RELOADA_CLIPOUT,
	SND_RELOADB_CLIPIN,
	SND_RELOADC_CLIPIN,
	SND_THROW,
	SND_SHOOT,
	SND_EXPLODE
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav",
	"custom_weapons/cso/bloodhunter_change.wav",
	"custom_weapons/cso/bloodhunter_clipin.wav",
	"custom_weapons/cso/bloodhunter_clipout.wav",
	"custom_weapons/cso/bloodhunter_draw.wav",
	"custom_weapons/cso/bloodhunter_drawa.wav",
	"custom_weapons/cso/bloodhunter_drawb.wav",
	"custom_weapons/cso/bloodhunter_drawc.wav",
	"custom_weapons/cso/bloodhunter_idle.wav",
	"custom_weapons/cso/bloodhunter_reloada_clipin.wav",
	"custom_weapons/cso/bloodhunter_reloada_clipout.wav",
	"custom_weapons/cso/bloodhunter_reloadb_clipin.wav",
	"custom_weapons/cso/bloodhunter_reloadc_clipin.wav",
	"custom_weapons/cso/bloodhunter_throwa.wav",
	"custom_weapons/cso/bloodhunter-1.wav",
	"custom_weapons/cso/bloodhunter_explode.wav"
};

const array<string> pCSOWSprites =
{
	"sprites/custom_weapons/cso/ef_bloodhunter1.spr",
	"sprites/custom_weapons/cso/ef_bloodhunter2.spr",
	"sprites/custom_weapons/cso/ef_bloodhunter3.spr"
};

class weapon_bloodhunter : CBaseCustomWeapon
{
	private uint m_uiLevel, m_uiShotsHit;
	private float m_flRedrawTime;
	private float m_flThrowGrenade;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		m_uiLevel = 0;
		m_flRedrawTime = 0.0;
		m_flThrowGrenade = 0.0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_GRENADE );
		g_Game.PrecacheModel( MODEL_SHELL );
		if( CSOW_USE_MAGDROP )
			g_Game.PrecacheModel( MODEL_MAG );

		for( uint i = 0; i < pCSOWSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		g_Game.PrecacheModel( pCSOWSprites[0] );
		g_Game.PrecacheModel( pCSOWSprites[1] );
		g_iExplosionId = g_Game.PrecacheModel( pCSOWSprites[2] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_bloodhunter.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud145.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud17.spr" );
		g_Game.PrecacheGeneric( "sprites/cs16/mzcs2.spr" );

		g_Game.PrecacheGeneric( "events/muzzle_cso2.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iAmmo1Drop	= CSOW_MAX_CLIP;
		info.iSlot			= CSO::BLOODHUNTER_SLOT - 1;
		info.iPosition		= CSO::BLOODHUNTER_POSITION - 1;
		info.iWeight		= CSOW_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_bloodhunter") );
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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW + m_uiLevel, CSOW_ANIMEXT );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		SetThink(null);
		m_flRedrawTime = 0.0;
		m_flThrowGrenade = 0.0f;

		BaseClass.Holster( skipLocal );
	}

	~weapon_bloodhunter()
	{
		self.m_fInReload = false;
		SetThink(null);
		m_flRedrawTime = 0.0;
		m_flThrowGrenade = 0.0f;
		g_Game.AlertMessage( at_console, "weapon_bloodhunter has been destroyed via ~ \n");
	}

	void PrimaryAttack()
	{
		float flCycleTime = CSOW_TIME_DELAY1;

		Vector vecShootCone;

		if( (m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) and self.m_flNextPrimaryAttack <= g_Engine.time ) //NEEDED??
			return;

		vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE_DUCKING : CSOW_CONE_STANDING;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		m_pPlayer.m_szAnimExtension = "uzis_left";
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE  );
		EjectShell();

		if( self.m_iClip == 0 and m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = Math.RandomFloat( CSOW_RECOIL1_X.x, CSOW_RECOIL1_X.y );
		m_pPlayer.pev.punchangle.y = Math.RandomFloat( CSOW_RECOIL1_Y.x, CSOW_RECOIL1_Y.y );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;

		TraceResult tr;

		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );

		Vector vecDir = vecAiming 
						+ x * (vecShootCone.x) * g_Engine.v_right 
						+ y * (vecShootCone.y) * g_Engine.v_up;

		Vector vecEnd = vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( g_EngineFuncs.PointContents(tr.vecEndPos) != CONTENTS_SKY )
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_STREAK_SPLASH );
				m1.WriteCoord( tr.vecEndPos.x );
				m1.WriteCoord( tr.vecEndPos.y );
				m1.WriteCoord( tr.vecEndPos.z );
				m1.WriteCoord( tr.vecPlaneNormal.x * Math.RandomFloat(25.0, 30.0) );
				m1.WriteCoord( tr.vecPlaneNormal.y * Math.RandomFloat(25.0, 30.0) );
				m1.WriteCoord( tr.vecPlaneNormal.z * Math.RandomFloat(25.0, 30.0) );
				m1.WriteByte( 1 ); //color
				m1.WriteShort( 20 ); //count
				m1.WriteShort( 3 ); //speed
				m1.WriteShort( 90 ); //velocity
			m1.End();
		}

		if( tr.flFraction < 1.0f )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( pHit is null or pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_EAGLE );

				g_WeaponFuncs.ClearMultiDamage();

				if( pHit.pev.takedamage != DAMAGE_NO and !pHit.IsBSPModel() and !pHit.IsPlayer() )
				{
					pHit.TraceAttack( m_pPlayer.pev, CSOW_DAMAGE, vecDir, tr, DMG_BULLET | DMG_NEVERGIB );

					if( m_uiShotsHit < 12 )
						++m_uiShotsHit;

					int anim = ANIM_SHOOT;

					if( m_uiShotsHit == 4 or m_uiShotsHit == 8 or m_uiShotsHit == 12 and m_uiLevel != 3 )
					{
						anim = ANIM_SHOOT_EF;
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_CHANGE], VOL_NORM, ATTN_NORM );
					}

					m_uiLevel = m_uiShotsHit / 4; //4shots per level, 12 to fully charge

					self.SendWeaponAnim( anim + m_uiLevel );

					Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

					vecOrigin = m_pPlayer.pev.origin;
					vecUp = m_pPlayer.pev.view_ofs;
					vecOrigin = vecOrigin + vecUp;
					vecAngle = m_pPlayer.pev.v_angle;

					g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

					vecOrigin = vecOrigin + vecForward * 15.0 + vecRight * 0.0 + vecUp * -5.0;

					g_EntityFuncs.Create( "bloodhunter_effect", vecOrigin, g_vecZero, false, m_pPlayer.edict() );
				}
				else
					self.SendWeaponAnim( ANIM_SHOOT + m_uiLevel );

				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );	
			}
		}
	}

	void SecondaryAttack()
	{
		if( m_uiLevel > 0 )
		{
			self.SendWeaponAnim( ANIM_THROW + m_uiLevel );
			m_pPlayer.m_szAnimExtension = "crowbar";
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_THROW], 1.0f, ATTN_NORM );

			m_flRedrawTime = g_Engine.time + 0.53;
			m_flThrowGrenade = g_Engine.time + 0.3;
		}

		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void TertiaryAttack()
	{
		if( CSOW_DEBUG )
		{
			if( m_uiLevel == 3 )
				m_uiLevel = 0;

			m_uiLevel++;

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
		}
	}

	void ThrowGrenade()
	{
		Vector vecOrigin = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
		Vector vecVelocity = g_Engine.v_forward * CSOW_GRENADE_THROW + m_pPlayer.pev.velocity;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "bloodgrenade", vecOrigin, g_vecZero, true, m_pPlayer.edict() );
		bloodgrenade@ pGrenade = cast<bloodgrenade@>(CastToScriptClass(cbeGrenade));

		pGrenade.pev.velocity = vecVelocity;
		pGrenade.m_uiLevel = m_uiLevel;

		g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );

		m_uiLevel = 0;
		m_uiShotsHit = 0;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
			return;

		m_pPlayer.m_szAnimExtension = "uzis_left";
		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD + m_uiLevel, CSOW_TIME_RELOAD );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		if( CSOW_USE_MAGDROP )
		{
			self.pev.nextthink = g_Engine.time + 0.5f;
			SetThink( ThinkFunction(DropMag) );
		}

		BaseClass.Reload();
	}

	void ItemPostFrame()
	{
		if( m_flRedrawTime > 0.0f and m_flRedrawTime < g_Engine.time )
		{
			self.SendWeaponAnim( ANIM_DRAW + m_uiLevel );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			m_flRedrawTime = 0.0f;
		}

		if( m_flThrowGrenade > 0.0f and m_flThrowGrenade < g_Engine.time )
		{
			ThrowGrenade();
			m_flThrowGrenade = 0.0f;
		}

		BaseClass.ItemPostFrame();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.m_szAnimExtension = "uzis";

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE + m_uiLevel );

		if( Math.RandomLong(0, CSOW_IDLE_SOUND_CHANCE) == 1 )
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_IDLE], VOL_NORM, ATTN_NORM );

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( CSOW_TIME_IDLE1, CSOW_TIME_IDLE2 );
	}

	void DropMag()
	{
		Vector vecMagVelocity, vecMagOrigin;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		vecMagOrigin = pev.origin + m_pPlayer.pev.view_ofs + -g_Engine.v_up * 9;
		vecMagVelocity = m_pPlayer.pev.velocity + -g_Engine.v_up * Math.RandomFloat(100, 150);

		NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecMagOrigin );
			m.WriteByte( TE_BREAKMODEL );
			m.WriteCoord( vecMagOrigin.x ); //position
			m.WriteCoord( vecMagOrigin.y );
			m.WriteCoord( vecMagOrigin.z - 2 );
			m.WriteCoord( 1 ); //size
			m.WriteCoord( 1 );
			m.WriteCoord( 1 );
			m.WriteCoord( vecMagVelocity.x ); //velocity
			m.WriteCoord( vecMagVelocity.y );
			m.WriteCoord( vecMagVelocity.z );
			m.WriteByte( 1 ); //random velocity in 10's
			m.WriteShort( g_EngineFuncs.ModelIndex(MODEL_MAG) ); //sprite or model index
			m.WriteByte( 1 ); //count
			m.WriteByte( 20 ); //life in 0.1 secs
			m.WriteByte( BREAK_METAL ); //flags
		m.End();
	}

	void EjectShell()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		Vector vecShellVelocity = m_pPlayer.pev.velocity + -g_Engine.v_right * Math.RandomFloat(50, 70) + g_Engine.v_up * Math.RandomFloat(100, 150) + g_Engine.v_forward * 25;
		g_EntityFuncs.EjectBrass( pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_up * -9 + g_Engine.v_forward * 16 - g_Engine.v_right * 9, vecShellVelocity, pev.angles.y, g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHELL );
	}
}

class bloodgrenade : ScriptBaseMonsterEntity
{
	uint m_uiLevel;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_GRENADE );

		pev.movetype = MOVETYPE_BOUNCE;
		pev.solid    = SOLID_BBOX;
		pev.gravity = 0.8;
		pev.dmg = Math.RandomFloat(CSOW_DAMAGE_GREN_MIN, CSOW_DAMAGE_GREN_MAX) * m_uiLevel * 0.5;
		pev.avelocity.x = -360;
		pev.avelocity.y = -360;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Explode();
	}

	void Explode()
	{
		Vector vecOrigin;
		vecOrigin = pev.origin;

		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		g_Utility.TraceLine( vecSpot, vecSpot + pev.velocity.Normalize() * 64, ignore_monsters, self.edict(), tr );

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			vecOrigin = tr.vecEndPos + (tr.vecPlaneNormal * (pev.dmg - 12) * 0.6f);

		NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_SPRITE );
			m2.WriteCoord( vecOrigin.x );
			m2.WriteCoord( vecOrigin.y );
			m2.WriteCoord( vecOrigin.z );
			m2.WriteShort( g_iExplosionId );
			m2.WriteByte( 20 * m_uiLevel ); // scale * 10
			m2.WriteByte( 150 ); // brightness
		m2.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, pCSOWSounds[SND_EXPLODE], VOL_NORM, ATTN_NORM );

		//g_WeaponFuncs.RadiusDamage( vecOrigin, self.pev, pev.owner.vars, pev.dmg, CSOW_GRENADE_RADIUS, CLASS_NONE, DMG_GENERIC | DMG_LAUNCH );

		CBaseEntity@ pTarget = null;
		for( int i = 0; i < g_Engine.maxEntities; ++i )
		{
			edict_t@ edict = @g_EntityFuncs.IndexEnt(i);
			@pTarget = g_EntityFuncs.Instance(edict);
			if( pTarget is null ) continue;
			if( !pTarget.IsAlive() ) continue;
			float flDist = (pTarget.pev.origin - vecOrigin).Length();
			if( flDist > CSOW_GRENADE_RADIUS ) continue;

			pTarget.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_GENERIC | DMG_LAUNCH ); //(pev.dmg - flDist)

			/*Vector vecVelocity( Math.RandomFloat(-750.0, 750.0), Math.RandomFloat(-750.0, 750.0), 400.0 * m_uiLevel );
			pTarget.pev.velocity = vecVelocity;*/
		}

		g_EntityFuncs.Remove( self );
	}
}

class bloodhunter_effect : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, pCSOWSprites[Math.RandomLong(0, 1)] );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_FLY;
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 255.0;
		pev.frame = 0.0;
		pev.skin = 1;
		pev.scale = 0.075;

		SetThink( ThinkFunction(this.BloodThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	void BloodThink()
	{
		float flFrame;
		flFrame = pev.frame;

		CBaseEntity@ cbeOwner = g_EntityFuncs.Instance(pev.owner);
		Vector vecOrigin, vecAngle, vecForward, vecRight, vecUp;

		vecOrigin = pev.owner.vars.origin;
		vecUp = pev.owner.vars.view_ofs;
		vecOrigin = vecOrigin + vecUp;
		vecAngle = pev.owner.vars.v_angle;

		g_EngineFuncs.AngleVectors( vecAngle, vecForward, vecRight, vecUp );

		vecOrigin = vecOrigin + vecForward * 15.0 + vecRight * 0.0 + vecUp * 0.0;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		flFrame += 0.5;
		if( flFrame >= 44.0 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		pev.frame = flFrame;
		pev.nextthink = g_Engine.time + 0.01;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_bloodhunter::bloodgrenade", "bloodgrenade" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_bloodhunter::bloodhunter_effect", "bloodhunter_effect" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_bloodhunter::weapon_bloodhunter", "weapon_bloodhunter" );
	g_ItemRegistry.RegisterWeapon( "weapon_bloodhunter", "custom_weapons/cso", "357", "", "ammo_357", "" );
}

} //namespace cso_bloodhunter END