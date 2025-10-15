namespace cso_buffak
{

const bool USE_CSLIKE_RECOIL						= false;
const bool USE_PENETRATION							= true;
const string CSOW_NAME								= "weapon_buffak";

const int CSOW_DEFAULT_GIVE						= 50;
const int CSOW_MAX_CLIP 							= 50;
const int CSOW_MAX_AMMO							= 90;
const int  CSOW_ZOOM									= 60;
const float CSOW_DAMAGE1							= 24;
const float CSOW_DAMAGE2							= 56;
const float CSOW_PROJ_SPEED						= 2048.0;
const float CSOW_TIME_DELAY1						= 0.0955;
const float CSOW_TIME_DELAY2						= 0.5;
const float CSOW_TIME_DELAY3						= 0.3; //zoom
const float CSOW_TIME_DRAW						= 0.8;
const float CSOW_TIME_IDLE							= 3.0;
const float CSOW_TIME_FIRE_TO_IDLE			= 1.0;
const float CSOW_TIME_RELOAD						= 2.5;
const float CSOW_SPREAD_JUMPING				= 0.20;
const float CSOW_SPREAD_RUNNING				= 0.15;
const float CSOW_SPREAD_WALKING				= 0.1;
const float CSOW_SPREAD_STANDING				= 0.05;
const float CSOW_SPREAD_DUCKING				= 0.02;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D( -0.5, -2.0 );
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D( 0, 0 );
const Vector2D CSOW_RECOIL_DUCKING_X		= Vector2D( 0, 0 );
const Vector2D CSOW_RECOIL_DUCKING_Y		= Vector2D( 0, 0 );
const Vector2D CSOW_RECOIL_ALT_X				= Vector2D( -4.0, -6.0 );
const Vector2D CSOW_RECOIL_ALT_Y				= Vector2D( -2.0, 2.0 );
const Vector CSOW_OFFSETS_MUZZLE			= Vector( 26.414122, 4.169659, -2.442089 ); //Vector( 30.082214, 6.318542, -3.830643 );
const Vector CSOW_OFFSETS_SHELL				= Vector( 13.036917, -4.924881, -4.452251 ); //Vector( 28.245131, -7.099761, -4.173389 ); //forward, right, up

const float CSOW_FRAMERATE_SHOOT			= 30.0;

const string CSOW_ANIMEXT							= "mp5";
const string CSOW_ANIMEXT_CSO					= "ak47";

const string MODEL_VIEW								= "models/custom_weapons/cso/buffak/v_buffak.mdl";
const string MODEL_PLAYER							= "models/custom_weapons/cso/buffak/p_buffak.mdl";
const string MODEL_WORLD							= "models/custom_weapons/cso/buffak/w_buffak.mdl";
const string MODEL_SHELL								= "models/custom_weapons/cso/rshell.mdl";

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
	SND_SHOOT1 = 1,
	SND_SHOOT2,
	SND_IDLE
};

const array<string> arrsCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",  //only here for the precache
	"custom_weapons/cso/buffak/ak47buff-1.wav",
	"custom_weapons/cso/buffak/ak47buff-2.wav",
	"custom_weapons/cso/buffak/ak47buff_idle.wav",
	"custom_weapons/cso/buffak/ak47buff_draw.wav",
	"custom_weapons/cso/buffak/ak47buff_reload.wav"
};

class weapon_buffak : CBaseCSOWeapon
{
	private float m_flAccuracy;
	private int m_iMuzzleflashNum;
	private bool m_bPlayIdleSound;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_flSpreadJumping = CSOW_SPREAD_JUMPING;
		m_flSpreadRunning = CSOW_SPREAD_RUNNING;
		m_flSpreadWalking = CSOW_SPREAD_WALKING;
		m_flSpreadStanding = CSOW_SPREAD_STANDING;
		m_flSpreadDucking = CSOW_SPREAD_DUCKING;

		m_iWeaponType = TYPE_PRIMARY;
		m_sEmptySound = arrsCSOWSounds[0];

		m_flAccuracy = 0.2;
		m_iShotsFired = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( cso::SPRITE_HITMARKER );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash19.spr" ); //projectile
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/ef_buffak_hit.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash40.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash41.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash42.spr" );

		m_iShell = g_Game.PrecacheModel( MODEL_SHELL );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < arrsCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < arrsCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + arrsCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/" + CSOW_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud132.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip 			= CSOW_MAX_CLIP;
		info.iSlot				= cso::BUFFAK_SLOT - 1;
		info.iPosition			= cso::BUFFAK_POSITION - 1;
		info.iWeight			= cso::BUFFAK_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, PlayerHasCSOModel() ? CSOW_ANIMEXT_CSO : CSOW_ANIMEXT );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;

			m_flAccuracy = 0.2;
			m_iShotsFired = 0;
			m_bPlayIdleSound = true;

			return bResult;
		}
	}

	void Holster( int skiplocal )
	{
		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		SetThink( null );
		m_iMuzzleflashNum = 0;
		m_bPlayIdleSound = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, arrsCSOWSounds[SND_IDLE] );

		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.m_bPlayEmptySound = true; //without this, PlayEmptySound only plays once
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( !USE_CSLIKE_RECOIL )
		{
			HandleAmmoReduction( 1 );

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3) );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;

			if( m_pPlayer.m_iFOV == 0 )
			{
				float flDamage = CSOW_DAMAGE1;
				if( self.m_flCustomDmg > 0 )
					flDamage = self.m_flCustomDmg;

				int iPenetration = USE_PENETRATION ? 2 : 0; 
				FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, GetWeaponSpread(), iPenetration, BULLET_PLAYER_762MM, 0, flDamage, 0.98, CSOF_HITMARKER, CSOW_OFFSETS_MUZZLE );

				EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x - g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell, false );

				HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT1], VOL_NORM, ATTN_NORM );
			}
			else
			{
				FireBall();
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT2], VOL_NORM, ATTN_NORM );

				HandleRecoil( CSOW_RECOIL_ALT_X, CSOW_RECOIL_ALT_Y, CSOW_RECOIL_ALT_X*0.5, CSOW_RECOIL_ALT_Y*0.5 );
			}

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ((m_pPlayer.m_iFOV == 0) ? CSOW_TIME_DELAY1 : CSOW_TIME_DELAY2);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
		}
		else
		{
			if( m_pPlayer.m_iFOV == 0 )
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
					AK47Fire( 0.04 + (0.4) * m_flAccuracy, 0.0955, false );
				else if( m_pPlayer.pev.velocity.Length2D() > 140 )
					AK47Fire( 0.04 + (0.07) * m_flAccuracy, 0.0955, false );
				else
					AK47Fire( (0.0275), 0.0955, false );
			}
			else
			{
				FireBall();
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT2], VOL_NORM, ATTN_NORM );

				HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + ((m_pPlayer.m_iFOV == 0) ? CSOW_TIME_DELAY1 : CSOW_TIME_DELAY2);
				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
			}
		}

		MuzzleflashCSO( 1, "#I40 S0.08 R2.5 F0 P30 T0.01 A1 L0 O1" );

		m_iMuzzleflashNum = 1;
		SetThink( ThinkFunction(this.MuzzleflashThink) );
		pev.nextthink = g_Engine.time + (1 / CSOW_FRAMERATE_SHOOT); //0.0333;
		
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, arrsCSOWSounds[SND_IDLE] );
		m_bPlayIdleSound = true;
	}

	void AK47Fire( float flSpread, float flCycleTime, bool fUseAutoAim )
	{
		m_bDelayFire = true;
		m_iShotsFired++;
		m_flAccuracy = float((m_iShotsFired * m_iShotsFired * m_iShotsFired) / 200.0) + 0.35;

		if( m_flAccuracy > 1.25 )
			m_flAccuracy = 1.25;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();

		float flDamage = CSOW_DAMAGE1;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		int iPenetration = USE_PENETRATION ? 2 : 0;
		FireBullets3( vecSrc, g_Engine.v_forward, flSpread, iPenetration, BULLET_PLAYER_762MM, 0, flDamage, 0.98, CSOF_HITMARKER );

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT3) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_OFFSETS_SHELL.x + g_Engine.v_right * CSOW_OFFSETS_SHELL.y + g_Engine.v_up * CSOW_OFFSETS_SHELL.z, m_iShell );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, arrsCSOWSounds[SND_SHOOT1], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + 1.9;

		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7 );
		else if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			KickBack( 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			KickBack( 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9 );
		else
			KickBack( 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8 );
	}

	void FireBall()
	{
		Vector vecAngles, vecOrigin, vecTargetOrigin, vecVelocity;

		get_position( 40.0, 5.0, -5.0, vecOrigin );
		get_position( 1024.0, 0.0, 0.0, vecTargetOrigin );

		vecAngles = m_pPlayer.pev.angles;

		vecAngles.z = Math.RandomFloat( 0.0, 18.0 ) * 20;

		CBaseEntity@ pBall = g_EntityFuncs.Create( "csoproj_buffak", vecOrigin, vecAngles, false, m_pPlayer.edict() );

		get_speed_vector( vecOrigin, vecTargetOrigin, CSOW_PROJ_SPEED, vecVelocity );
		pBall.pev.velocity = vecVelocity;

		float flDamage = CSOW_DAMAGE2;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		pBall.pev.dmg = flDamage;

		g_EntityFuncs.DispatchSpawn( pBall.edict() );
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.m_iFOV != 0 )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		else
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = CSOW_ZOOM;

		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY3;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		m_iMuzzleflashNum = 0;

		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, arrsCSOWSounds[SND_IDLE] );
		m_bPlayIdleSound = true;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_bPlayIdleSound )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, arrsCSOWSounds[SND_IDLE], 1.0, ATTN_NORM, SND_FORCE_LOOP );
			m_bPlayIdleSound = false;
		}

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE*2)));
	}

	void MuzzleflashThink()
	{
		if( m_iMuzzleflashNum == 1 )
			MuzzleflashCSO( 1, "#I41 S0.06 R0 F0 P30 T0.01 A1 L0 O0" );
		else
			MuzzleflashCSO( 1, "#I42 S0.055 R0 F0 P30 T0.01 A1 L0 O0" );

		m_iMuzzleflashNum++;

		if( m_iMuzzleflashNum <= 2 )
			pev.nextthink = g_Engine.time + (1 / CSOW_FRAMERATE_SHOOT); //0.0333;
		else
		{
			SetThink( null );
			m_iMuzzleflashNum = 0;
		}
	}
}

class csoproj_buffak : ScriptBaseEntity
{
	private float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "sprites/custom_weapons/cso/muzzleflash19.spr" );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, -1.0), Vector(1.0, 1.0, 1.0) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_FLY;
		pev.solid    = SOLID_TRIGGER; //SOLID_BBOX
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 80;
		pev.scale = 0.15;
		pev.gravity = 0.01; //?

		m_flRemoveTime = g_Engine.time + 5.0;

		pev.nextthink = g_Engine.time;
		SetThink( ThinkFunction(this.FlyThink) );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/muzzleflash19.spr" );
		g_Game.PrecacheModel( "sprites/custom_weapons/cso/ef_buffak_hit.spr" );
	}

	void FlyThink()
	{
		pev.nextthink = g_Engine.time + 0.01;

		if( g_Engine.time >= m_flRemoveTime )
			g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther.edict() is pev.owner or pOther.pev.classname == self.GetClassname() ) //is checking the classname NEEDED ??
			return;

		if( pOther.pev.takedamage != DAMAGE_NO and pOther.IsAlive() )
		{
			if( g_EntityFuncs.Instance(pev.owner).IRelationship(pOther) > R_NO )
			{
				TraceResult tr;
				g_Utility.TraceLine( pOther.Center(), pOther.Center(), ignore_monsters, pev.owner, tr );

				g_WeaponFuncs.ClearMultiDamage();
				pOther.TraceAttack( pev.owner.vars, pev.dmg, g_Engine.v_forward, tr, DMG_NEVERGIB );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, pev.owner.vars );

				HitMarker();
			}
		}

		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;
		SetTouch( null );

		Explode();

		g_EntityFuncs.Remove( self );
	}

	void Explode()
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/custom_weapons/cso/ef_buffak_hit.spr") );
			m1.WriteByte( 5 ); // scale * 10
			m1.WriteByte( 15 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, pev.dmg, cso::MetersToUnits(2), CLASS_PLAYER, DMG_LAUNCH ); 
	}

	void HitMarker()
	{
		if( pev.owner is null ) return;
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		HUDSpriteParams hudParams;

		hudParams.channel = 1;
		hudParams.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_SCR_CENTER_X | HUD_ELEM_DEFAULT_ALPHA;
		hudParams.spritename = "custom_weapons/cso/buffhit.spr";
		hudParams.x = 0;
		hudParams.y = 0;
		hudParams.color1 = RGBA_WHITE;
		hudParams.holdTime = 0.1;

		g_PlayerFuncs.HudCustomSprite( pPlayer, hudParams );
	} 
}

void Register()
{
	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}

	if( !g_CustomEntityFuncs.IsCustomEntity( "csoproj_buffak" ) )
		g_CustomEntityFuncs.RegisterCustomEntity( "cso_buffak::csoproj_buffak", "csoproj_buffak" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cso_buffak::weapon_buffak", CSOW_NAME );
	g_ItemRegistry.RegisterWeapon( CSOW_NAME, "custom_weapons/cso", "buffak47ammo" ); //"762mg", "", "ammo_762mg"
}

} //namespace cso_buffak END