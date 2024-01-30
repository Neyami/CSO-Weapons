namespace cso_blockas
{

const Vector CSOW_VECTOR_SPREAD( 0.0725, 0.0725, 0.0 );
const Vector CSOW_SHELL_ORIGIN( 22.0, 11.0, -9.0 );
const Vector2D CSOW_VEC2D_RECOIL( 6.0, 10.0 );

const int CSOW_DEFAULT_GIVE			= 8;
const int CSOW_MAX_CLIP 			= 8;
const int CSOW_MAX_AMMO1 			= 32; //doesn't actually do anything since it uses the maxammo set by the buymenu plugin ¯\_(ツ)_/¯
const int CSOW_MAX_AMMO2 			= 10;
const int CSOW_PELLETCOUNT			= 8;
const float CSOW_DAMAGE1			= 7.5; //total 60
const float CSOW_DAMAGE2			= 113.0;
const float CSOW_RADIUS				= 80.0;

const float CSOW_DELAY1				= 0.30;
const float CSOW_DELAY2				= 0.35;
const float CSOW_TIME_IDLE			= 1.7;
const float CSOW_TIME_DRAW			= 1.0; //1.1
const float CSOW_TIME_FIRE_TO_IDLE	= 1.0;

const string MODEL_VIEW1			= "models/custom_weapons/cso/v_blockas1.mdl";
const string MODEL_VIEW2			= "models/custom_weapons/cso/v_blockas2.mdl";
const string MODEL_VIEW_BLOCKCHANGE	= "models/custom_weapons/cso/v_blockchange.mdl";
const string MODEL_PLAYER1			= "models/custom_weapons/cso/p_blockas1.mdl";
const string MODEL_PLAYER2			= "models/custom_weapons/cso/p_blockas2.mdl";
const string MODEL_WORLD1			= "models/custom_weapons/cso/w_blockas1.mdl";
//const string MODEL_WORLD2			= "models/custom_weapons/cso/w_blockas2.mdl";
const string MODEL_SHELL			= "models/custom_weapons/cso/block_shell.mdl";
const string MODEL_ROCKET			= "models/custom_weapons/cso/block_missile.mdl";

const string CSOW_ANIMEXT			= "shotgun";

const string SPRITE_TRAIL			= "sprites/smoke.spr";
const string SPRITE_EXPLOSION1		= "sprites/eexplo.spr";
const string SPRITE_EXPLOSION2		= "sprites/fexplo.spr";
const string SPRITE_EXPLOSION3		= "sprites/dexplo.spr";
const string SPRITE_LAUNCH			= "sprites/custom_weapons/cso/rainsplash.spr";
const string SPRITE_SMOKE			= "sprites/steam1.spr";

enum csow_e1
{
	ANIM1_IDLE = 0, //1.7
	ANIM1_DRAW, //1.0
	ANIM1_SHOOT1, //1.0
	ANIM1_SHOOT2, //1.0
	ANIM1_SHOOT3, //1.0
	ANIM1_CHANGE1, //1.3
	ANIM1_CHANGE2, //1.3
	ANIM1_RELOAD_START, //0.7
	ANIM1_RELOAD_INSERT, //0.4
	ANIM1_RELOAD_END //0.4
}

enum csow_e2
{
	ANIM2_IDLE = 0, //1.7
	ANIM2_IDLE_EMPTY, //1.7
	ANIM2_DRAW, //1.0
	ANIM2_DRAW_EMPTY, //1.0
	ANIM2_SHOOT_START, //0.9
	ANIM2_SHOOT_END, //1.0
	ANIM2_RELOAD, //2.0
	ANIM2_CHANGE1, //1.3
	ANIM2_CHANGE1_EMPTY, //1.3
	ANIM2_CHANGE2, //1.3
	ANIM2_CHANGE2_EMPTY //1.3
}

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_DRAW,
	SND_IDLE,
	SND_SHOOT1,
	SND_RELOAD_INSERT,
	SND_CHANGE1_TO_2,
	SND_CHANGE1_FROM_2,
	SND_CHANGE,
	SND_CHANGE2_TO_1,
	SND_CHANGE2_FROM_1,
	SND_SHOOT2_START,
	SND_SHOOT2_END,
	SND_RELOAD2
}

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/blockas2_draw.wav",
	"custom_weapons/cso/blockas2_idle.wav",
	"custom_weapons/cso/blockas1-2.wav",
	"custom_weapons/cso/blockas1_reload_loop.wav",
	"custom_weapons/cso/blockas1_change1.wav",
	"custom_weapons/cso/blockas1_change2.wav",
	"custom_weapons/cso/block_change.wav",
	"custom_weapons/cso/blockas2_change1_1.wav",
	"custom_weapons/cso/blockas2_change2_1.wav",
	"custom_weapons/cso/blockas2_shoot_start.wav",
	"custom_weapons/cso/blockas2_shoot_end.wav",
	"custom_weapons/cso/blockas2_reload.wav"
};

enum modes_e
{
	MODE_A = 0,
	MODE_B
};

class weapon_blockas : CBaseCSOWeapon
{
	private float m_flShootRocketStage1, m_flShootRocketStage2, m_flShootRocketStage3;
	private float m_flModeChangeStage1, m_flModeChangeStage2, m_flModeChangeStage3;
	private int m_iShotgunReload;
	private int m_iWeaponMode;
	private bool m_bChanging;
	private bool m_bRocketLoaded;
	private bool m_bFirstPickup, m_bFirstChange;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, MODEL_WORLD1 );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;
		m_iWeaponMode = MODE_A;
		m_bFirstPickup = false;
		m_bFirstChange = true;
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW1 );
		g_Game.PrecacheModel( MODEL_VIEW2 );
		g_Game.PrecacheModel( MODEL_VIEW_BLOCKCHANGE );
		g_Game.PrecacheModel( MODEL_PLAYER1 );
		g_Game.PrecacheModel( MODEL_PLAYER2 );
		g_Game.PrecacheModel( MODEL_WORLD1 );
		//g_Game.PrecacheModel( MODEL_WORLD2 );

		g_Game.PrecacheModel( MODEL_SHELL );
		g_Game.PrecacheModel( MODEL_ROCKET );

		g_Game.PrecacheModel( SPRITE_TRAIL );
		g_Game.PrecacheModel( SPRITE_EXPLOSION1 );
		g_Game.PrecacheModel( SPRITE_EXPLOSION2 );
		g_Game.PrecacheModel( SPRITE_EXPLOSION3 );
		g_Game.PrecacheModel( SPRITE_LAUNCH );
		g_Game.PrecacheModel( SPRITE_SMOKE );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_blockas.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud14.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud130.spr" );
		g_Game.PrecacheGeneric( "sprites/cso/muzzleflash36.spr" );
		g_Game.PrecacheGeneric( "events/muzzle_cso36.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO1;
		info.iMaxAmmo2 	= CSOW_MAX_AMMO2;
		info.iMaxClip 	= CSOW_MAX_CLIP;
		info.iSlot 		= cso::BLOCKAS_SLOT - 1;
		info.iPosition 	= cso::BLOCKAS_POSITION - 1;
		info.iWeight 	= cso::BLOCKAS_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		if( !m_bFirstPickup )
		{
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, CSOW_MAX_AMMO2 );
			m_bFirstPickup = true;
		}

		m_bRocketLoaded = true;
		m_bChanging = false;

		NetworkMessage blockas( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			blockas.WriteLong( g_ItemRegistry.GetIdForName("weapon_blockas") );
		blockas.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], 0.8, ATTN_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			switch( m_iWeaponMode )
			{
				case MODE_A: bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW1), self.GetP_Model(MODEL_PLAYER1), ANIM1_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break; //saw, shotgun while reloading??
				case MODE_B: bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW2), self.GetP_Model(MODEL_PLAYER2), (m_bRocketLoaded ? ANIM2_DRAW : ANIM2_DRAW_EMPTY), CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
			}

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		m_iShotgunReload = 0;
		m_flShootRocketStage1 = m_flShootRocketStage2 = m_flShootRocketStage3 = 0;
		m_flModeChangeStage1 = m_flModeChangeStage2 = m_flModeChangeStage3 = 0;

		m_bChanging = false;

		BaseClass.Holster( skipLocal );
	}

	~weapon_blockas()
	{
		self.m_fInReload = false;
		m_iShotgunReload = 0;
		m_flShootRocketStage1 = m_flShootRocketStage2 = m_flShootRocketStage3 = 0;
		m_flModeChangeStage1 = m_flModeChangeStage2 = m_flModeChangeStage3 = 0;

		m_bChanging = false;

		//g_Game.AlertMessage( at_console, "weapon_blockas has been destroyed via ~ \n");
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;

			return;
		}

		if( m_iWeaponMode == MODE_A )
		{
			if( self.m_iClip <= 0 )
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 1.0;

				return;
			}

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

			--self.m_iClip;

			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			self.SendWeaponAnim( Math.RandomLong(ANIM1_SHOOT1, ANIM1_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

			Vector vecShellVelocity, vecShellOrigin;
			CS16GetDefaultShellInfo( EHandle(m_pPlayer), vecShellVelocity, vecShellOrigin, CSOW_SHELL_ORIGIN.x, CSOW_SHELL_ORIGIN.y, CSOW_SHELL_ORIGIN.z, true, false );
			g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHOTSHELL );

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT1], VOL_NORM, 0.5, 0, 94 + Math.RandomLong(0, 15) );

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecSrc	 = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;

			float flDamage = CSOW_DAMAGE1;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			m_pPlayer.FireBullets( CSOW_PELLETCOUNT, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );
			cso::CreateShotgunPelletDecals( m_pPlayer, vecSrc, vecAiming, CSOW_VECTOR_SPREAD, CSOW_PELLETCOUNT, flDamage, (DMG_BULLET | DMG_LAUNCH | DMG_NEVERGIB) );

			if( self.m_iClip <= 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_DELAY1;

			if( self.m_iClip > 0 )
				self.m_flTimeWeaponIdle = g_Engine.time + 2.25;
			else
				self.m_flTimeWeaponIdle = 0.75;

			m_iShotgunReload = 0;

			if( (m_pPlayer.pev.flags & FL_ONGROUND) != 0 )
				m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, (CSOW_VEC2D_RECOIL.x/2), (CSOW_VEC2D_RECOIL.y/2) );
			else
				m_pPlayer.pev.punchangle.x -= g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed + 1, CSOW_VEC2D_RECOIL.x, CSOW_VEC2D_RECOIL.y );
		}
		else
			Shoot_Special();
	}

	void Shoot_Special()
	{
		if( !m_bRocketLoaded )
			return;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 4.0;
		self.m_flTimeWeaponIdle = g_Engine.time + 5.0;

		self.SendWeaponAnim( ANIM2_SHOOT_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT2_START], VOL_NORM, ATTN_NORM );

		m_flShootRocketStage1 = g_Engine.time + 1.0;
	}

	void Shoot_Rocket()
	{
		self.SendWeaponAnim( ANIM2_SHOOT_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		m_pPlayer.pev.punchangle.x -= 4.0;

		Vector vecOrigin, vecTargetOrigin, vecAngles, angles_fix;
		get_position( 2.0, 4.0, 0.0, vecOrigin );

		vecAngles = m_pPlayer.pev.v_angle;

		CBaseEntity@ pRocket = null;
		dictionary keys;
		keys[ "origin" ] = vecOrigin.ToString();

		@pRocket = g_EntityFuncs.CreateEntity( "block_missile", keys, false );

		angles_fix.x = 360.0f - vecAngles.x;
		angles_fix.y = vecAngles.y;
		angles_fix.z = vecAngles.z;

		@pRocket.pev.owner = m_pPlayer.edict();

		pRocket.pev.angles = angles_fix;

		Vector vecVelocity;
		Vector start = m_pPlayer.GetGunPosition();

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		
		TraceResult tr;
		g_Utility.TraceLine( start, start + g_Engine.v_forward * 9999.0, dont_ignore_monsters, self.edict(), tr );

		vecTargetOrigin = tr.vecEndPos;

		start = start + g_Engine.v_forward * 16;

		NetworkMessage msg1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			msg1.WriteByte( TE_SPRITE );
			msg1.WriteCoord( start.x );
			msg1.WriteCoord( start.y );
			msg1.WriteCoord( start.z );
			msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_LAUNCH) );
			msg1.WriteByte( 3 ); // scale
			msg1.WriteByte( 200 );  // brightness
		msg1.End();

		get_speed_vector( vecOrigin, vecTargetOrigin, 1500.0, vecVelocity );
		pRocket.pev.velocity = vecVelocity;

		g_EntityFuncs.DispatchSpawn( pRocket.edict() );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT2_END], VOL_NORM, ATTN_NORM );
		m_bRocketLoaded = false;

		for( int i = 0; i < 5; i++ )
		{
			//set_pdata_int(weapon_entity, 57, shell_block, 4)
			//set_pdata_float(Player, 111, get_gametime() + 0.01)
			eject_shell( false );
			eject_shell( true );
		}

		int ammo2 = m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType);
		ammo2--;
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, ammo2 );

		if( ammo2 >= 1 )
			m_flShootRocketStage2 = g_Engine.time + 1.0;
	}

	void SecondaryAttack()
	{
		if( m_bChanging ) return;

		switch( m_iWeaponMode )
		{
			case MODE_A: self.SendWeaponAnim( ANIM1_CHANGE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
			case MODE_B:
			{
				if( m_bRocketLoaded ) self.SendWeaponAnim( ANIM2_CHANGE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				else self.SendWeaponAnim( ANIM2_CHANGE1_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				break;
			}
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 4.7;
		self.m_flTimeWeaponIdle = g_Engine.time + 4.7;
		m_bChanging = true;

		m_flModeChangeStage1 = g_Engine.time + 1.0;
	}

	void Reload()
	{
		if( m_bChanging ) return;

		if( m_iWeaponMode == MODE_A )
		{
			int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);

			if( ammo <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
				return;

			if( self.m_flNextPrimaryAttack > g_Engine.time )
				return;

			if( m_iShotgunReload <= 0 )
			{
				self.SendWeaponAnim( ANIM1_RELOAD_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				m_iShotgunReload = 1;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.55;
				//self.m_flNextPrimaryAttack = g_Engine.time + 0.55; //prevents firing while reloading
				//self.m_flNextSecondaryAttack = g_Engine.time + 0.55; //prevents firing while reloading
			}
			else if( m_iShotgunReload == 1 )
			{
				if( self.m_flTimeWeaponIdle > g_Engine.time )
					return;

				m_iShotgunReload = 2;

				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_RELOAD_INSERT], VOL_NORM, ATTN_NORM, SND_FORCE_SINGLE, 85 + Math.RandomLong(0, 31) ); //0x1f

				m_pPlayer.SetAnimation(PLAYER_RELOAD);
				self.SendWeaponAnim( ANIM1_RELOAD_INSERT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				self.m_iClip++;
				ammo--;
				m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo);

				self.m_flTimeWeaponIdle = g_Engine.time + 0.3;
			}
			else
				m_iShotgunReload = 1;
		}
		else
		{
			if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 )
				Reload_Rocket();
		}
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 and m_iShotgunReload == 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
				Reload();
			else if( m_iShotgunReload != 0 )
			{
				if( self.m_iClip != CSOW_MAX_CLIP and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
					Reload();
				else
				{
					self.SendWeaponAnim( ANIM1_RELOAD_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

					m_iShotgunReload = 0;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
				}
			}
			else
			{
				if( m_iWeaponMode == MODE_A )
				{
					self.SendWeaponAnim( ANIM1_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE * Math.RandomFloat(1.0, 1.2));
				}
				else
				{
					if( m_bRocketLoaded )
						self.SendWeaponAnim( ANIM2_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					else
						self.SendWeaponAnim( ANIM2_IDLE_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

					self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE * Math.RandomFloat(1.0, 1.2));
				}
			}
		}
	}

	void ItemPostFrame()
	{
		if( m_flShootRocketStage1 > 0 and g_Engine.time > m_flShootRocketStage1 )
		{
			m_flShootRocketStage1 = 0;
			Shoot_Rocket();
		}
		else if( m_flShootRocketStage2 > 0 and g_Engine.time > m_flShootRocketStage2 )
		{
			m_flShootRocketStage2 = 0;
			Reload_Rocket();
		}
		else if( m_flShootRocketStage3 > 0 and g_Engine.time > m_flShootRocketStage3 )
		{
			m_flShootRocketStage3 = 0;
			Complete_Reload_Rocket();
		}
		else if( m_flModeChangeStage1 > 0 and g_Engine.time > m_flModeChangeStage1 )
		{
			m_flModeChangeStage1 = 0;
			AnimBlockChange();
		}
		else if( m_flModeChangeStage2 > 0 and g_Engine.time > m_flModeChangeStage2 )
		{
			m_flModeChangeStage2 = 0;
			AnimBlockChange_2();
		}
		else if( m_flModeChangeStage3 > 0 and g_Engine.time > m_flModeChangeStage3 )
		{
			m_flModeChangeStage3 = 0;
			AnimBlockChange_Complete();
		}

		BaseClass.ItemPostFrame();
	}

	void Reload_Rocket()
	{
		if( m_iWeaponMode != MODE_B or m_bRocketLoaded )
			return;

		self.SendWeaponAnim( ANIM2_RELOAD, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.5;
		self.m_flTimeWeaponIdle = g_Engine.time + 2.0;

		m_flShootRocketStage3 = g_Engine.time + 1.0;
	}

	void Complete_Reload_Rocket()
	{
		m_bRocketLoaded = true;
	}

	void AnimBlockChange()
	{
		if( !m_bChanging )
			return;

		self.SendWeaponAnim( 0, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		m_pPlayer.pev.viewmodel = MODEL_VIEW_BLOCKCHANGE;

		m_flModeChangeStage2 = g_Engine.time + 2.36;
	}

	void AnimBlockChange_2()
	{
		if( !m_bChanging )
			return;

		if( m_iWeaponMode == MODE_A )
		{
			m_pPlayer.pev.viewmodel = MODEL_VIEW2;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER2;
			//g_EntityFuncs.SetModel( self, MODEL_WORLD2 ); //doesn't work, probably no way to get it to work

			if( !m_bRocketLoaded ) self.SendWeaponAnim( ANIM2_CHANGE2_EMPTY, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			else self.SendWeaponAnim( ANIM2_CHANGE2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
		else
		{
			m_pPlayer.pev.viewmodel = MODEL_VIEW1;
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER1;
			//g_EntityFuncs.SetModel( self, MODEL_WORLD1 ); //doesn't work, probably no way to get it to work
			self.SendWeaponAnim( ANIM1_CHANGE2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}

		m_iWeaponMode = (m_iWeaponMode == MODE_B) ? MODE_A : MODE_B;

		m_flModeChangeStage3 = g_Engine.time + 1.36;
	}

	void AnimBlockChange_Complete()
	{
		if( !m_bChanging )
			return;

		if( m_iWeaponMode == MODE_B )
		{
			if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 and m_bFirstChange )
			{
				m_bRocketLoaded = true;
				m_bFirstChange = false;
			}
		}

		m_bChanging = false;
	}

	void eject_shell( bool bRight )
	{
		Vector origin, origin2, gunorigin, v_forward, v_forward2, v_up, v_up2, v_right, v_right2;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		v_forward = g_Engine.v_forward;
		v_right = g_Engine.v_right;
		v_up = g_Engine.v_up;
		v_forward2 = g_Engine.v_forward;
		v_right2 = g_Engine.v_right;
		v_up2 = g_Engine.v_up;
		gunorigin = m_pPlayer.GetOrigin() + m_pPlayer.pev.view_ofs;

		if( !bRight )
		{
			v_forward = v_forward * 20.0;
			v_right = v_right * -2.5;
			v_up = v_up * -1.5;
			v_forward2 = v_forward2 * 19.9;
			v_right2 = v_right2 * -2.0;
			v_up2 = v_up2 * -2.0;
		}
		else
		{
			v_forward = v_forward * 20.0;
			v_right = v_right * 2.5;
			v_up = v_up * -1.5;
			v_forward2 = v_forward2 * 19.9;
			v_right2 = v_right2 * 2.0;
			v_up2 = v_up2 * -2.0;
		}

		origin = gunorigin + v_forward;
		origin2 = gunorigin + v_forward2;
		origin = origin + v_right;
		origin2 = origin2 + v_right2;
		origin = origin + v_up;
		origin2 = origin2 + v_up2;

		Vector velocity;
		get_speed_vector( origin2, origin, Math.RandomFloat(70.0, 320.0), velocity );

		NetworkMessage msg1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			msg1.WriteByte( TE_MODEL );
			msg1.WriteCoord( origin.x );
			msg1.WriteCoord( origin.y );
			msg1.WriteCoord( origin.z - 16.0 );
			msg1.WriteCoord( velocity.x );
			msg1.WriteCoord( velocity.y );
			msg1.WriteCoord( velocity.z );
			msg1.WriteAngle( Math.RandomFloat(0, 360) ); // yaw
			msg1.WriteShort( g_EngineFuncs.ModelIndex(MODEL_SHELL) ); // model
			msg1.WriteByte( TE_BOUNCE_NULL ); // bouncesound //TE_BOUNCE_SHOTSHELL
			msg1.WriteByte( 20 ); // decay time
		msg1.End();
	}
}

class block_missile : ScriptBaseEntity
{
	void Spawn()
	{
		pev.movetype = MOVETYPE_TOSS;
		pev.solid    = SOLID_BBOX;
		pev.gravity = 0.5;

		g_EntityFuncs.SetModel( self, MODEL_ROCKET );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector(-0.1, -0.1, -0.1), Vector(0.1, 0.1, 0.1) );

		NetworkMessage msg1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			msg1.WriteByte( TE_BEAMFOLLOW );
			msg1.WriteShort( self.entindex() );
			msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_TRAIL) );
			msg1.WriteByte( 3 ); // life
			msg1.WriteByte( 2 );  // width
			msg1.WriteByte( 255 ); // r
			msg1.WriteByte( 255 ); // g
			msg1.WriteByte( 255 ); // b
			msg1.WriteByte( 150 ); // brightness
		msg1.End();
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther.edict() is pev.owner )
			return;

		TraceResult tr;
		Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0, 1) );

		int sparkCount = Math.RandomLong(0, 3);
		for( int i = 0; i < sparkCount; i++ )
			g_EntityFuncs.Create( "spark_shower", pev.origin, tr.vecPlaneNormal, false );

		tr = g_Utility.GetGlobalTrace();

		// Pull out of the wall a bit
		if( tr.flFraction != 1.0 )
			pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0);

		Vector vecOrigin = pev.origin;

		NetworkMessage msg1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			msg1.WriteByte( TE_EXPLOSION );
			msg1.WriteCoord( vecOrigin.x );
			msg1.WriteCoord( vecOrigin.y );
			msg1.WriteCoord( vecOrigin.z + 20.0 );
			msg1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION1) );
			msg1.WriteByte( 25 ); // scale * 10
			msg1.WriteByte( 30 ); // framerate
			msg1.WriteByte( TE_EXPLFLAG_NONE );
		msg1.End();

		NetworkMessage msg2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			msg2.WriteByte( TE_EXPLOSION );
			msg2.WriteCoord( vecOrigin.x + Math.RandomFloat(-64.0, 64.0) );
			msg2.WriteCoord( vecOrigin.y + Math.RandomFloat(-64.0, 64.0) );
			msg2.WriteCoord( vecOrigin.z + Math.RandomFloat(30.0, 35.0) );
			msg2.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION2) );
			msg2.WriteByte( 30 ); // scale * 10
			msg2.WriteByte( 30 ); // framerate
			msg2.WriteByte( TE_EXPLFLAG_NONE ); //TE_EXPLFLAG_NOSOUND
		msg2.End();

		NetworkMessage msg3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			msg3.WriteByte( TE_EXPLOSION );
			msg3.WriteCoord( vecOrigin.x + Math.RandomFloat(-64.0, 64.0) );
			msg3.WriteCoord( vecOrigin.y + Math.RandomFloat(-64.0, 64.0) );
			msg3.WriteCoord( vecOrigin.z + Math.RandomFloat(30.0, 35.0) );
			msg3.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION3) );
			msg3.WriteByte( 30 ); // scale * 10
			msg3.WriteByte( 30 ); // framerate
			msg3.WriteByte( TE_EXPLFLAG_NOSOUND );
		msg3.End();

		NetworkMessage msg4( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			msg4.WriteByte( TE_BREAKMODEL );
			msg4.WriteCoord( vecOrigin.x );
			msg4.WriteCoord( vecOrigin.y );
			msg4.WriteCoord( vecOrigin.z );
			msg4.WriteCoord( 150 ); //size
			msg4.WriteCoord( 150 ); //size
			msg4.WriteCoord( 150 ); //size
			msg4.WriteCoord( Math.RandomLong(-50, 50) ); // velocity
			msg4.WriteCoord( Math.RandomLong(-50, 50) ); // velocity
			msg4.WriteCoord( Math.RandomLong(-50, 50) ); // velocity
			msg4.WriteByte( 30 ); //random velocity
			msg4.WriteShort( g_EngineFuncs.ModelIndex(MODEL_SHELL) );
			msg4.WriteByte( Math.RandomLong(30, 40) ); // count
			msg4.WriteByte( 20 ); //lifetime
			msg4.WriteByte( 0 ); //flags
		msg4.End();

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, CSOW_DAMAGE2, CSOW_RADIUS, CLASS_NONE, DMG_BLAST );

		pev.effects |= EF_NODRAW;
		pev.velocity = g_vecZero;
		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetThink( ThinkFunction(this.Smoke) );
		pev.nextthink = g_Engine.time + 0.5;
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_blockas::weapon_blockas", "weapon_blockas" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_blockas::block_missile", "block_missile" );
	g_ItemRegistry.RegisterWeapon( "weapon_blockas", "custom_weapons/cso", "buckshot", "m777shot", "ammo_buckshot" );
}

} //namespace cso_blockas END