namespace cso_augex
{

const bool USE_CSLIKE_RECOIL					= false;
const bool USE_PENETRATION					= true;

const int CSOW_DEFAULT_GIVE					= 30;
const int CSOW_MAX_CLIP 						= 30;
const int CSOW_MAX_AMMO1					= 90;
const int CSOW_MAX_AMMO2					= 10;
const float CSOW_DAMAGE						= 28.0;
const float CSOW_GRENADE_VELOCITY		= 1800.0;
const float CSOW_GRENADE_DAMAGE			= 80.0;
const float CSOW_GRENADE_RADIUS			= 180.0;
const float CSOW_TIME_DELAY1					= 0.0825;
const float CSOW_TIME_DELAY2					= 3.0;
const float CSOW_TIME_DRAW					= 0.75;
const float CSOW_TIME_IDLE						= 20.0;
const float CSOW_TIME_RELOAD				= 3.0;
const float CSOW_TIME_FIRE_TO_IDLE1		= 1.9;
const float CSOW_TIME_FIRE_TO_IDLE2		= 4.9;
const float CSOW_TIME_FIRE_TO_IDLE3		= 3.9;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1, -3);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(0, 0);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(0, 0);
const Vector CSOW_CONE_STANDING			= VECTOR_CONE_2DEGREES;
const Vector CSOW_CONE_CROUCHING		= VECTOR_CONE_1DEGREES;
const Vector CSOW_SHELL_ORIGIN				= Vector(17.0, 14.0, -8.0); //forward, right, up
const Vector CSOW_MUZZLE_ORIGIN			= Vector(16.0, 4.0, -4.0); //forward, right, up

const string CSOW_ANIMEXT						= "m16"; //rifle

const string MODEL_VIEW							= "models/custom_weapons/cso/v_augex.mdl";
const string MODEL_PLAYER						= "models/custom_weapons/cso/p_augex.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_augex.mdl";
const string MODEL_SHELL							= "models/custom_weapons/cso/pshell.mdl";
const string MODEL_GRENADE						= "models/custom_weapons/cso/shell_svdex.mdl";

const string SPRITE_BEAM							= "sprites/laserbeam.spr";
const string SPRITE_EXPLOSION1				= "sprites/fexplo.spr";
const string SPRITE_EXPLOSION2				= "sprites/eexplo.spr";
const string SPRITE_SMOKE						= "sprites/steam1.spr";
const string SPRITE_MUZZLE						= "sprites/custom_weapons/cso/muzzleflash12.spr";

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT_GRENADE,
	ANIM_SHOOT_GRENADE_EMPTY
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SHOOT,
	SND_SHOOT_GRENADE,
	SND_SHOOT_GRENADE_EMPTY
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/augex-1.wav",
	"custom_weapons/cso/augex_shoot3.wav",
	"custom_weapons/cso/augex_shoot_empty.wav",
	"custom_weapons/cso/augex_clipin1.wav",
	"custom_weapons/cso/augex_clipin2.wav",
	"custom_weapons/cso/augex_clipout.wav"
};

class weapon_augex : CBaseCSOWeapon
{
	private float m_flAccuracy;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		m_flAccuracy = 0.2;
		m_iShotsFired = 0;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_GRENADE );
		g_Game.PrecacheModel( SPRITE_BEAM );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
		g_Game.PrecacheModel( SPRITE_EXPLOSION2 );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_MUZZLE );

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_augex.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud2.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud160.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash3.spr" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_aug.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO1;
		info.iMaxAmmo2 	= CSOW_MAX_AMMO2;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iSlot			= cso::AUGEX_SLOT - 1;
		info.iPosition		= cso::AUGEX_POSITION - 1;
		info.iWeight		= cso::AUGEX_WEIGHT;
		info.iFlags			= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_augex") );
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
			m_flAccuracy = 0.2;
			m_iShotsFired = 0;

			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW*2);

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( !USE_CSLIKE_RECOIL )
		{
			HandleAmmoReduction( 1 );

			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH; //Needed??
			self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE_CROUCHING : CSOW_CONE_STANDING;

			//m_pPlayer.FireBullets( 1, m_pPlayer.GetGunPosition(), g_Engine.v_forward, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, CSOW_DAMAGE );
			int iPenetration = USE_PENETRATION ? 2 : 0;
			cso::FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, 0, 8192, iPenetration, BULLET_PLAYER_556MM, CSOW_DAMAGE, 1.0, EHandle(m_pPlayer), m_pPlayer.random_seed );
			//DoDecalGunshot( m_pPlayer.GetGunPosition(), g_Engine.v_forward, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_SAW, true );

			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

			HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );

			if( m_pPlayer.pev.fov == 0 )
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
			else
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.135;

			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;
		}
		else
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
				AUGEXFire( 0.035 + (0.4) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else if( m_pPlayer.pev.velocity.Length2D() > 140 )
				AUGEXFire( 0.035 + (0.07) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else if( m_pPlayer.pev.fov == 0 )
				AUGEXFire( (0.02) * m_flAccuracy, CSOW_TIME_DELAY1 );
			else
				AUGEXFire( (0.02) * m_flAccuracy, 0.135 );
		}
	}

	void AUGEXFire( float flSpread, float flCycleTime )
	{
		m_bDelayFire = true;
		m_iShotsFired++;
		m_flAccuracy = float((m_iShotsFired * m_iShotsFired * m_iShotsFired) / 215.0) + 0.3;

		if( m_flAccuracy > 1 )
			m_flAccuracy = 1;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		int iPenetration = USE_PENETRATION ? 2 : 0;
		/*Vector vecDir = */cso::FireBullets3( vecSrc, g_Engine.v_forward, flSpread, 8192, iPenetration, BULLET_PLAYER_556MM, CSOW_DAMAGE, 0.96, EHandle(m_pPlayer), m_pPlayer.random_seed ); //CSOF_ALWAYSDECAL ??

		self.SendWeaponAnim( Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		//m_pPlayer.FireBullets( 1, vecSrc, g_Engine.v_forward, vecShootCone, 8192.0, BULLET_PLAYER_SAW, 4, 0 );
		//DoDecalGunshot( vecSrc, g_Engine.v_forward, vecDir.x, vecDir.y, BULLET_PLAYER_SAW, true );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + flCycleTime;

		HandleAmmoReduction( 1 );

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE1;

		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 1.0, 0.45, 0.275, 0.05, 4.0, 2.5, 7 );
		else if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			KickBack( 1.25, 0.45, 0.22, 0.18, 5.5, 4.0, 5 );
		else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
			KickBack( 0.575, 0.325, 0.2, 0.011, 3.25, 2.0, 8 );
		else
			KickBack( 0.625, 0.375, 0.25, 0.0125, 3.5, 2.25, 8 );
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.2;
			return;
		}

		HandleAmmoReduction( 0, 0, 0, 1 );

		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 )
		{
			LaunchGrenade();
			self.SendWeaponAnim( ANIM_SHOOT_GRENADE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_SHOOT_GRENADE], VOL_NORM, ATTN_NORM );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE2;
		}
		else
		{
			LaunchGrenade();
			self.SendWeaponAnim( ANIM_SHOOT_GRENADE_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_SHOOT_GRENADE_EMPTY], VOL_NORM, ATTN_NORM );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + (CSOW_TIME_DELAY2-0.4);
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE3;
		}

		DoMuzzleflash( SPRITE_MUZZLE, CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );
	}

	void LaunchGrenade()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0, -3.0);

		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 8 + g_Engine.v_right * 4 + g_Engine.v_up * -2;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		vecAngles.x = 360.0 - vecAngles.x;

		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "augex_grenade", vecOrigin, vecAngles, false, m_pPlayer.edict() ); 
		augex_grenade@ pGrenade = cast<augex_grenade@>(CastToScriptClass(cbeGrenade));
		pGrenade.m_bCluster = true;
		pGrenade.m_flAutoExplode = g_Engine.time + 0.42;
		pGrenade.pev.velocity = g_Engine.v_forward * CSOW_GRENADE_VELOCITY;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		m_flAccuracy = 0;
		m_iShotsFired = 0;
		m_bDelayFire = false;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
	}

	void ItemPostFrame()
	{
		if( USE_CSLIKE_RECOIL )
		{
			if( m_pPlayer.pev.button & (IN_ATTACK | IN_ATTACK2) == 0 )
			{
				if( m_bDelayFire )
				{
					m_bDelayFire = false;

					if( m_iShotsFired > 15 )
						m_iShotsFired = 15;

					m_flDecreaseShotsFired = g_Engine.time + 0.4;
				}

				self.m_bFireOnEmpty = false;

				if( m_iShotsFired > 0 )
				{
					if( g_Engine.time > m_flDecreaseShotsFired )
					{
						m_iShotsFired--;
						m_flDecreaseShotsFired = g_Engine.time + 0.0225;
					}
				}

				WeaponIdle();
			}
		}

		BaseClass.ItemPostFrame();
	}
}

class augex_grenade : ScriptBaseEntity
{
	bool m_bCluster;
	float m_flAutoExplode;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_GRENADE );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.movetype = MOVETYPE_PUSHSTEP;
		pev.solid = SOLID_BBOX;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMFOLLOW );
			m1.WriteShort( self.entindex() );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAM) );
			m1.WriteByte( 20 ); // life
			m1.WriteByte( 4 );  // width
			m1.WriteByte( 200 ); // r
			m1.WriteByte( 200 ); // g
			m1.WriteByte( 200 ); // b
			m1.WriteByte( 200 ); // brightness
		m1.End();

		SetThink( ThinkFunction(this.GrenadeThink) );
		SetTouch( TouchFunction(this.GrenadeTouch) );

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_GRENADE );
		g_Game.PrecacheModel( SPRITE_BEAM );
	}

	void GrenadeThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity.Normalize() );

		if( m_flAutoExplode > 0.0 and m_flAutoExplode < g_Engine.time )
		{
			Explode();
			m_flAutoExplode = 0.0;
			return;
		}

		pev.nextthink = g_Engine.time + 0.1;
	}

	void GrenadeTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.classname == "augex_grenade" )
			return;

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Explode();
	}

	void Explode()
	{
		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		if( m_bCluster )
		{
			g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0, 1) );

			int sparkCount = Math.RandomLong(0, 3);
			for( int i = 0; i < sparkCount; i++ )
				g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );
		}
		else g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong(0, 2) );

		tr = g_Utility.GetGlobalTrace();

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0f )
			pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0f);

		Vector vecOrigin = pev.origin;

		if( m_bCluster )
		{
			NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
				msg1.WriteByte( TE_EXPLOSION );
				msg1.WriteCoord( vecOrigin.x );
				msg1.WriteCoord( vecOrigin.y );
				msg1.WriteCoord( vecOrigin.z );
				msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION1) );
				msg1.WriteByte( 15 ); // scale * 10
				msg1.WriteByte( 30 ); // framerate
				msg1.WriteByte( TE_EXPLFLAG_NONE );
			msg1.End();
		}
		else
		{
			NetworkMessage msg2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
				msg2.WriteByte( TE_EXPLOSION );
				msg2.WriteCoord( vecOrigin.x );
				msg2.WriteCoord( vecOrigin.y );
				msg2.WriteCoord( vecOrigin.z );
				msg2.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION2) );
				msg2.WriteByte( 10 ); // scale * 10
				msg2.WriteByte( 30 ); // framerate
				msg2.WriteByte( TE_EXPLFLAG_NONE );
			msg2.End();
		}

		float flDamage = CSOW_GRENADE_DAMAGE;
		float flRadius = CSOW_GRENADE_RADIUS;

		if( m_bCluster )
		{
			array<CBaseEntity@> cbeCluster(3);
			array<augex_grenade@> pCluster(3);
			array<Vector> vecCluster(3);

			vecCluster[0] = Vector( 200, 200, -250 );
			vecCluster[1] = Vector( 200, -200, -250 );
			vecCluster[2] = Vector( -200, 200, -250 );

			Vector vecSrc = pev.origin;

			for( int i = 0; i < 3; ++i )
			{
				@cbeCluster[i] = g_EntityFuncs.Create( "augex_grenade", vecSrc, g_vecZero, false, pev.owner );
				@pCluster[i] = cast<augex_grenade@>(CastToScriptClass(cbeCluster[i]));
				pCluster[i].pev.velocity = vecCluster[i];
				pCluster[i].m_bCluster = false;
			}
		}
		else
		{
			flDamage = CSOW_GRENADE_DAMAGE/2;
			flRadius = CSOW_GRENADE_RADIUS/2;
		}

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_BLAST );

		pev.effects |= EF_NODRAW;
		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetTouch( null );

		if( m_bCluster )
		{
			SetThink( ThinkFunction(this.Smoke) );
			pev.nextthink = g_Engine.time + 0.5;
		}
	}

	void Smoke()
	{
		NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			msg1.WriteByte( TE_SMOKE );
			msg1.WriteCoord( pev.origin.x );
			msg1.WriteCoord( pev.origin.y );
			msg1.WriteCoord( pev.origin.z );
			msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
			msg1.WriteByte( 40 ); // scale * 10
			msg1.WriteByte( 6 ); // framerate
		msg1.End();

		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_augex::augex_grenade", "augex_grenade" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_augex::weapon_augex", "weapon_augex" );
	g_ItemRegistry.RegisterWeapon( "weapon_augex", "custom_weapons/cso", "556", "ARgrenades", "ammo_556", "ammo_ARgrenades" );
}

} //namespace cso_augex END
