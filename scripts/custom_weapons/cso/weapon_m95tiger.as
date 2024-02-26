namespace cso_m95tiger
{

const int CSOW_DEFAULT_GIVE			= 20;
const int CSOW_MAX_CLIP 					= 20;
const int CSOW_MAX_AMMO2				= 7;
const int CSOW_ZOOMFOV					= 20;
const float CSOW_DAMAGE					= 119; // 119 / 3085 / 6169
const float CSOW_TIME_DELAY1			= 1.47; //Fire
const float CSOW_TIME_DELAY2			= 0.3; //Zoom
const float CSOW_TIME_DELAY3			= 1.7; //Fire net
const float CSOW_TIME_DRAW			= 1.45;
const float CSOW_TIME_IDLE				= 15.0;
const float CSOW_TIME_RELOAD		= 2.0;
const float CSOW_RECOIL					= 4.0;
const float CSOW_NET_VELOCITY		= 1200.0;
const float CSOW_NET_LIFETIME		= 1.7;
const float CSOW_NET_RADIUS			= cso::MetersToUnits(2); //a second mob within this radius will get hit
const Vector CSOW_SHELL_ORIGIN	= Vector( 9.0, 9.0, -9.0 ); //forward, right, up
const Vector CSOW_MUZZLE_ORIGIN	= Vector( 27.0, 4.0, -4.0 ); //forward, right, up
const Vector CSOW_NET_MINS			= Vector( -32.0, -32.0, -32.0 );
const Vector CSOW_NET_MAXS			= Vector( 32.0, 32.0, 32.0 );
const Vector CSOW_TIGER_MINS		= Vector( -50.0, -50.0, -50.0 );
const Vector CSOW_TIGER_MAXS		= Vector( 50.0, 50.0, 50.0 );
const float CSOW_TIGER_VELOCITY	= 750.0;
const float CSOW_TIGER_LIFETIME		= 3.0;
const float CSOW_TIGER_DAMAGE		= 149; //zombies: 7413, scenario: 14,826
const float CSOW_TIGER_RADIUS		= 120.0;
const float CSOW_CLAW_LIFETIME		= 2.5;

const string CSOW_ANIMEXT				= "sniper"; //rifle

const string MODEL_VIEW					= "models/custom_weapons/cso/v_m95tiger.mdl";
const string MODEL_PLAYER				= "models/custom_weapons/cso/p_m95tiger.mdl";
const string MODEL_WORLD				= "models/custom_weapons/cso/w_m95tiger.mdl";
const string MODEL_SHELL					= "models/custom_weapons/cso/rshell_big.mdl";
const string MODEL_TIGER					= "models/custom_weapons/cso/ef_m95tiger.mdl";
const string MODEL_NET						= "models/custom_weapons/cso/ef_m95tiger_net.mdl";
const string MODEL_NETHIT				= "models/custom_weapons/cso/ef_m95tiger_nethit.mdl";
const string MODEL_SCOPE_R				= "models/custom_weapons/cso/m95tiger_scope_red.mdl";
const string MODEL_SCOPE_Y				= "models/custom_weapons/cso/m95tiger_scope_yellow.mdl";

const string SPRITE_MUZZLE1				= "sprites/custom_weapons/cso/muzzleflash80.spr";
const string SPRITE_MUZZLE2				= "sprites/custom_weapons/cso/muzzleflash59.spr";
const string SPRITE_NETHIT				= "sprites/custom_weapons/cso/ef_m95tiger_nethit.spr";
const string SPRITE_CLAW					= "sprites/custom_weapons/cso/ef_m95tiger_scratch.spr";

enum bodygroup_e
{
	BODYGROUP_HANDS = 4,
	BODYGROUP_SYMBOL
};

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_TIGER,
	ANIM_SHOOT_NET
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_ZOOM,
	SND_IDLE,
	SND_SHOOT,
	SND_SHOOT_NET,
	SND_SHOOT_TIGER
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/zoom.wav",
	"custom_weapons/cso/m95tiger_idle.wav",
	"custom_weapons/cso/m95tiger-1.wav",
	"custom_weapons/cso/m95tiger-2.wav",
	"custom_weapons/cso/m95tiger-3.wav",
	"custom_weapons/cso/m95tiger_clipin.wav",
	"custom_weapons/cso/m95tiger_clipout.wav",
	"custom_weapons/cso/m95_boltpull.wav",
	"custom_weapons/cso/m95tiger_draw.wav",
	"custom_weapons/cso/m95tiger_reloadb.wav",
	"custom_weapons/cso/m95tiger_tiger.wav",
	"custom_weapons/cso/shoot_net1.wav",
	"custom_weapons/cso/shoot_net2.wav"
};

class weapon_m95tiger : CBaseCSOWeapon
{
	private bool m_bResumeZoom;
	private int m_iLastZoom;
	private float m_flEjectBrass;
	private bool m_bSkillActive;
	private int m_iBodyConfig;
	int m_iKilledMobs;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_iDefaultSecAmmo = CSOW_MAX_AMMO2;
		self.m_flCustomDmg = pev.dmg;

		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;
		m_iKilledMobs = 0;
		m_bSkillActive = false;
		m_iBodyConfig = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( MODEL_TIGER );
		g_Game.PrecacheModel( MODEL_NET );
		g_Game.PrecacheModel( MODEL_NETHIT );
		g_Game.PrecacheModel( MODEL_SCOPE_R );
		g_Game.PrecacheModel( MODEL_SCOPE_Y );

		g_Game.PrecacheModel( SPRITE_MUZZLE1 );
		g_Game.PrecacheModel( SPRITE_MUZZLE2 );
		g_Game.PrecacheModel( SPRITE_NETHIT );
		g_Game.PrecacheModel( SPRITE_CLAW );
		g_Game.PrecacheModel( cso::SPRITE_HITMARKER );
		g_Game.PrecacheModel( cso::SPRITE_TRAIL_CSOBOW );

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

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_m95tiger.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud19.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud183.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/m95tiger_scope_grenade.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/sniper_scope.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= cso::BMG50_MAXCARRY;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iAmmo1Drop	= CSOW_DEFAULT_GIVE; 
		info.iMaxAmmo2 	= CSOW_MAX_AMMO2;
		info.iSlot				= cso::M95TIGER_SLOT - 1;
		info.iPosition		= cso::M95TIGER_POSITION - 1;
		info.iWeight			= cso::M95TIGER_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_m95tiger") );
		m.End();

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
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

	void Holster( int skiplocal )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		m_flEjectBrass = 0.0;

		BaseClass.Holster( skiplocal );
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? GetBodygroup() : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

			m_bResumeZoom = false;
			m_iLastZoom = 0;

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( m_bSkillActive and (m_pPlayer.pev.button & IN_ATTACK2) != 0 )
		{
			LaunchTiger();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
			return;
		}

		if( m_pPlayer.pev.fov != 0 )
		{
			if( m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD and self.m_iClip > 0 )
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
					M95TigerFire( 0.85, CSOW_TIME_DELAY1 );
				else if( m_pPlayer.pev.velocity.Length2D() > 140 )
					M95TigerFire( 0.25, CSOW_TIME_DELAY1 );
				else if( m_pPlayer.pev.velocity.Length2D() > 10 )
					M95TigerFire( 0.1, CSOW_TIME_DELAY1 );
				else if( m_pPlayer.pev.FlagBitSet(FL_DUCKING) )
					M95TigerFire( 0.0, CSOW_TIME_DELAY1 );
				else
					M95TigerFire( 0.001, CSOW_TIME_DELAY1 );

				return;
			}
		}
		else
		{
			if( m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD and m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 )
			{
				PrepareNetShot();
				return;
			}
		}

		self.PlayEmptySound();
		self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
	}

	void M95TigerFire( float flSpread, float flCycleTime )
	{
		if( m_pPlayer.pev.fov != 0 )
		{
			m_bResumeZoom = true;
			m_iLastZoom = m_pPlayer.m_iFOV;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
			m_pPlayer.pev.viewmodel = MODEL_VIEW;
		}
		else
			flCycleTime += 0.08;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_flEjectBrass = g_Engine.time + 1.0;
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		float flDamage = CSOW_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		int iEnemiesHit = cso::FireBullets3( m_pPlayer.GetGunPosition(), g_Engine.v_forward, flSpread, 8192, 20, BULLET_PLAYER_M95TIGER, flDamage, 5, EHandle(m_pPlayer), m_pPlayer.random_seed, (CSOF_ALWAYSDECAL | CSOF_HITMARKER), Vector(CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z) );
		m_iKilledMobs += iEnemiesHit;

		self.SendWeaponAnim( ANIM_SHOOT, 0, (m_bSwitchHands ? GetBodygroup() : 0) );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		HandleAmmoReduction();
		DoMuzzleflash( SPRITE_MUZZLE1, CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z, Math.RandomFloat(0.08, 0.09), 150, 30.0, 240.0 );

		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		m_pPlayer.pev.punchangle.x -= CSOW_RECOIL;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;
	}

	void PrepareNetShot()
	{
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		self.SendWeaponAnim( ANIM_SHOOT_NET, 0, (m_bSwitchHands ? GetBodygroup() : 0) );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT_NET], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) - 1 );
		DoMuzzleflash( SPRITE_MUZZLE2, CSOW_MUZZLE_ORIGIN.x, CSOW_MUZZLE_ORIGIN.y, CSOW_MUZZLE_ORIGIN.z, Math.RandomFloat(0.13, 0.14), 150, 30.0, 240.0 );

		FireNet();

		m_pPlayer.pev.punchangle.x -= CSOW_RECOIL;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY3;
		self.m_flTimeWeaponIdle = g_Engine.time + 2.7;
	}

	void FireNet()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_MUZZLE_ORIGIN.x + g_Engine.v_right * CSOW_MUZZLE_ORIGIN.y + g_Engine.v_up * CSOW_MUZZLE_ORIGIN.z;
		Vector vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x *= -1;

		CBaseEntity@ pNetShot = g_EntityFuncs.Create( "net_shot", vecOrigin, vecAngles, false, m_pPlayer.edict() );
		pNetShot.pev.velocity = g_Engine.v_forward * CSOW_NET_VELOCITY;
		pNetShot.pev.angles = Math.VecToAngles( pNetShot.pev.velocity.Normalize() );
	}

	void LaunchTiger()
	{
		self.SendWeaponAnim( ANIM_SHOOT_TIGER, 0, (m_bSwitchHands ? GetBodygroup() : 0) );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT_TIGER], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );
		g_PlayerFuncs.ScreenFade( m_pPlayer, Vector(117, 196, 70), 0.5, 0.2, 70, 0 );
		m_iKilledMobs = 0;
		m_bSkillActive = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );

		Vector vecVelocity;
		CBaseEntity@ pTiger = g_EntityFuncs.Create( "m95_tiger", m_pPlayer.pev.origin, g_vecZero, false, m_pPlayer.edict() );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		pTiger.pev.velocity = g_Engine.v_forward * CSOW_TIGER_VELOCITY;
		pTiger.pev.angles = Math.VecToAngles( pTiger.pev.velocity.Normalize() );
	}

	void SecondaryAttack()
	{
		switch( m_pPlayer.m_iFOV )
		{
			case 0:
			{
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = CSOW_ZOOMFOV;
				m_pPlayer.m_szAnimExtension = "sniperscope";
				m_pPlayer.pev.viewmodel = m_bSkillActive ? MODEL_SCOPE_Y : MODEL_SCOPE_R;
				break;
			}

			default:
			{
				m_pPlayer.pev.viewmodel = MODEL_VIEW;
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
				m_pPlayer.m_szAnimExtension = "sniper";
			}
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_ZOOM], 0.2, 2.4 );
		self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or m_flEjectBrass > 0.0 )
			return;

		if( m_pPlayer.m_iFOV != 0 )
			SecondaryAttack();

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? GetBodygroup() : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( self.m_iClip > 0 )
		{
			self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? GetBodygroup() : 0) );
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;

			if( m_bSkillActive )
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], VOL_NORM, ATTN_NORM );
		}
	}

	void ItemPostFrame()
	{
		if( self.m_flNextPrimaryAttack <= g_Engine.time )
		{
			if( m_bResumeZoom )
			{
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = m_iLastZoom;
				m_pPlayer.pev.viewmodel = m_bSkillActive ? MODEL_SCOPE_Y : MODEL_SCOPE_R;

				if( m_pPlayer.m_iFOV == m_iLastZoom )
					m_bResumeZoom = false;
			}
		}

		if( m_flEjectBrass > 0.0 and m_flEjectBrass < g_Engine.time )
		{
			m_flEjectBrass = 0.0;
			EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false, true );
		}

		if( !m_bSkillActive and m_iKilledMobs >= 10 )
		{
			m_bSkillActive = true;
			//Set tiger eyes here
		}

		BaseClass.ItemPostFrame();
	}

	private int GetBodygroup()
	{
		if( m_bSkillActive )
		{
			m_iBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(MODEL_VIEW), m_iBodyConfig, BODYGROUP_HANDS, g_iCSOWHands );
			m_iBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(MODEL_VIEW), m_iBodyConfig, BODYGROUP_SYMBOL, 1 );
		}
		else
		{
			m_iBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(MODEL_VIEW), m_iBodyConfig, BODYGROUP_HANDS, g_iCSOWHands );
			m_iBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(MODEL_VIEW), m_iBodyConfig, BODYGROUP_SYMBOL, 0 );
		}

		return m_iBodyConfig;
	}
}

class net_shot : ScriptBaseAnimating
{
	private float m_flRemoveTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_NET );
		g_EntityFuncs.SetSize( self.pev, CSOW_NET_MINS, CSOW_NET_MAXS );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 255;

		m_flRemoveTime = g_Engine.time + 2.0;
		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.NetThink) );
		pev.nextthink = g_Engine.time + 0.05;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_NET );
		g_Game.PrecacheModel( MODEL_NETHIT );
	}

	void NetThink()
	{
		if( pev.owner is null )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		CBaseEntity@ pTarget = null;
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, pev.origin, pev.size.x, "*", "classname")) !is null )
		{
			if( !pTarget.pev.FlagBitSet(FL_MONSTER) or !pTarget.IsAlive() or pTarget.pev.takedamage == DAMAGE_NO )
				continue; 

			NetHit( pTarget );

			break;
		}

		if( g_Engine.time >= (m_flRemoveTime - 1.6) )
			pev.renderamt = Math.clamp(0.0, 255.0, Math.max( pev.renderamt - 25.0, 0.0) );

		if( (pev.origin - pev.owner.vars.origin).Length() > 950.0 or g_Engine.time >= m_flRemoveTime ) pev.flags |= FL_KILLME;

		pev.nextthink = g_Engine.time + 0.05;
	}

	void NetHit( CBaseEntity@ pTarget )
	{
		WebMob( pTarget );
		CreateNetHit( pTarget );

		CBaseEntity@ pSecondHit = null;
		while( (@pSecondHit = g_EntityFuncs.FindEntityInSphere(pSecondHit, pTarget.pev.origin, CSOW_NET_RADIUS, "*", "classname")) !is null )
		{
			if( pSecondHit is pTarget or !pSecondHit.pev.FlagBitSet(FL_MONSTER) or !pSecondHit.IsAlive() or pSecondHit.pev.takedamage == DAMAGE_NO )
				continue; 

			WebMob( pSecondHit );
			CreateNetHit( pSecondHit );

			break;
		}

		g_EntityFuncs.Remove( self );
	}

	void WebMob( CBaseEntity@ pEntity )
	{
		CBaseMonster@ pMonster = cast<CBaseMonster@>( pEntity );

		pMonster.SetState( MONSTERSTATE_PLAYDEAD );
		pMonster.Stop();
	}

	void CreateNetHit( CBaseEntity@ pEntity )
	{
		Vector vecOrigin = pEntity.pev.origin;
		vecOrigin.z += (pEntity.pev.size.z/3);
		CBaseEntity@ cbeNetHit = g_EntityFuncs.Create( "net_hit", vecOrigin, g_vecZero, false, pev.owner );
		net_hit@ pNetHit = cast<net_hit@>(CastToScriptClass(cbeNetHit));
		pNetHit.m_hWebbedMob = EHandle( pEntity );

		NetHitExplode( pEntity.pev.origin );
	}

	void NetHitExplode( Vector vecOrigin )
	{
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_NETHIT) );
			m1.WriteByte( 7 ); // scale * 10
			m1.WriteByte( 15 ); // framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES  );
		m1.End();
	}
}

class net_hit : ScriptBaseAnimating
{
	private float m_flRemoveTime;
	EHandle m_hWebbedMob;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_NETHIT );
		g_EntityFuncs.SetSize( self.pev, Vector(-15.0, -15.0, -15.0), Vector(15.0, 15.0, 15.0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 255;

		m_flRemoveTime = g_Engine.time + CSOW_NET_LIFETIME;
		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.NetThink) );
		pev.nextthink = g_Engine.time + 0.05;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_NETHIT );
	}

	void NetThink()
	{
		KeepMobWebbed();

		if( g_Engine.time >= (m_flRemoveTime - (CSOW_NET_LIFETIME-1.1)) )
			pev.renderamt = Math.clamp(0.0, 255.0, Math.max( pev.renderamt - 15.0, 0.0) );

		if( g_Engine.time >= m_flRemoveTime )
		{
			FreeMob();
			g_EntityFuncs.Remove( self );
		}

		pev.nextthink = g_Engine.time + 0.05;
	}

	void KeepMobWebbed()
	{
		if( !m_hWebbedMob.IsValid() ) return;

		CBaseMonster@ pMonster = cast<CBaseMonster@>( m_hWebbedMob.GetEntity() );

		if( pMonster !is null and pMonster.IsAlive() )
		{
			pMonster.SetState( MONSTERSTATE_PLAYDEAD );
			pMonster.Stop();
		}
	}

	void FreeMob()
	{
		if( !m_hWebbedMob.IsValid() ) return;

		CBaseMonster@ pMonster = cast<CBaseMonster@>( m_hWebbedMob.GetEntity() );

		if( pMonster !is null and pMonster.IsAlive() )
		{
			pMonster.RunAI();
			pMonster.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
			pMonster.ClearSchedule();
			pMonster.SetState( MONSTERSTATE_IDLE );
			pMonster.StartMonster();
		}
	}
}

class m95_tiger : ScriptBaseAnimating
{
	private float m_flRemoveTime;
	private float m_flDamageTime;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_TIGER );
		g_EntityFuncs.SetSize( self.pev, CSOW_TIGER_MINS, CSOW_TIGER_MAXS );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;
		pev.rendermode = kRenderTransAdd;
		pev.renderamt = 255;
		pev.framerate = 1.0;
		pev.sequence = 1;

		m_flRemoveTime = g_Engine.time + CSOW_TIGER_LIFETIME;
		m_flDamageTime = g_Engine.time + 0.05;

		SetThink( ThinkFunction(this.TigerThink) );
		pev.nextthink = g_Engine.time + 0.05;
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_TIGER );
	}

	void TigerThink()
	{
		if( pev.owner is null )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( g_Engine.time >= (m_flRemoveTime - 0.6) )
			pev.renderamt = Math.clamp(0.0, 255.0, Math.max( pev.renderamt - 15.0, 0.0) );

		RadiusDamage();

		if( g_Engine.time >= m_flRemoveTime )
			g_EntityFuncs.Remove( self );

		pev.nextthink = g_Engine.time + 0.05;
	}

	void RadiusDamage()
	{
		//Intersects(CBaseEntity@ pOther) ??
		CBaseEntity@ pTarget = null;
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, pev.origin, CSOW_TIGER_RADIUS, "*", "classname")) !is null )
		{
			if( !pTarget.pev.FlagBitSet(FL_MONSTER) or !pTarget.IsAlive() or pTarget.pev.takedamage == DAMAGE_NO )
				continue; 

			//if( (pTarget.pev.spawnflags & 1) != 0 ) continue; //Only Trigger spawnflag for func_breakable

			bool bDamageCurrentTarget = true;
			CBaseEntity@ pExistingClawMark = null;
			while( (@pExistingClawMark = g_EntityFuncs.FindEntityByClassname(pExistingClawMark, "ef_claw")) !is null )
			{
				if( pExistingClawMark.pev.owner is null )
					continue;

				if( pExistingClawMark.pev.owner is pTarget.edict() )
				{
					bDamageCurrentTarget = false;
					break;
				}
			}

			if( bDamageCurrentTarget )
			{
				TraceResult tr;
				g_Utility.TraceLine( pTarget.Center(), pTarget.Center(), ignore_monsters, null, tr );

				g_WeaponFuncs.ClearMultiDamage();
				pTarget.TraceAttack( pev.owner.vars, CSOW_TIGER_DAMAGE, pev.velocity.Normalize(), tr, DMG_SLASH | DMG_NEVERGIB ); 
				g_WeaponFuncs.ApplyMultiDamage( pev, pev.owner.vars );

				CBaseEntity@ pClaw = g_EntityFuncs.Create( "ef_claw", pTarget.Center(), g_vecZero, false, pTarget.edict() );
				//@pClaw.pev.aiment = pTarget.edict(); //places the effect at the feet :(
				CreateBuffHit();
			}
		}
	}

	void CreateBuffHit()
	{
		Vector vecOrigin = pev.owner.vars.origin;
		cso::get_position( pev.owner, 50.0, -0.05, 1.0, vecOrigin );

		CBaseEntity@ pHitConfirm = g_EntityFuncs.Create( "cso_buffhit", vecOrigin, g_vecZero, false, pev.owner );
	}
}

class ef_claw : ScriptBaseEntity
{
	private float m_flRemoveTime;
	private float m_flMobFrameRate = 1.0;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, SPRITE_CLAW );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.rendermode = kRenderTransAdd;
		pev.scale = 0.5;
		pev.renderamt = 255;

		m_flRemoveTime = g_Engine.time + CSOW_CLAW_LIFETIME;
		if( pev.owner !is null ) m_flMobFrameRate = pev.owner.vars.framerate;

		SetThink( ThinkFunction(this.ClawThink) );
		pev.nextthink = g_Engine.time + 0.05;
	}

	void Precache()
	{
		g_Game.PrecacheModel( SPRITE_CLAW );
	}

	void ClawThink()
	{
		if( pev.owner is null or pev.owner.vars.deadflag > DEAD_NO )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( g_Engine.time >= (m_flRemoveTime - (CSOW_CLAW_LIFETIME-0.6)) )
			pev.renderamt = Math.clamp(0.0, 255.0, Math.max( pev.renderamt - 25.0, 0.0) );

		if( g_Engine.time >= m_flRemoveTime )
		{
			pev.owner.vars.framerate = m_flMobFrameRate;
			g_EntityFuncs.Remove( self );
			return;
		}

		Vector vecOrigin = pev.owner.vars.origin;
		vecOrigin.z += pev.owner.vars.size.z/2;
		pev.origin = vecOrigin;

		pev.owner.vars.framerate = 0.5;

		pev.nextthink = g_Engine.time + 0.25;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m95tiger::net_shot", "net_shot" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m95tiger::net_hit", "net_hit" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m95tiger::m95_tiger", "m95_tiger" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m95tiger::ef_claw", "ef_claw" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m95tiger::weapon_m95tiger", "weapon_m95tiger" );
	g_ItemRegistry.RegisterWeapon( "weapon_m95tiger", "custom_weapons/cso", "50bmg", "csonets", "ammo_50bmg" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_50bmg" ) ) 
		cso::Register50BMG();

	if( !g_CustomEntityFuncs.IsCustomEntity( "cso_buffhit" ) ) 
		cso::RegisterBuffHit();
}

} //namespace cso_m95tiger END

/*
TODO
Fix ammo pickup sound spam
*/
