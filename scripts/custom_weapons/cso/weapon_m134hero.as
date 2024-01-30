//Based on AMXX Plugin M134 Vulcan by Dias Leon
namespace cso_m134hero
{
const int CSOW_DEFAULT_GIVE					= 300;
const int CSOW_MAX_CLIP 						= 300;
const int CSOW_MAX_AMMO						= 600;
const float CSOW_DAMAGE						= 23; // Normal: 23, Zombie: 111, Scenario: 53
const float CSOW_TIME_DELAY1					= 0.04;
const float CSOW_TIME_DELAY2					= 0.02;
const float CSOW_TIME_DRAW					= 1.0;
const float CSOW_TIME_IDLE						= 2.0;
const float CSOW_TIME_FIRE_TO_IDLE		= 1.0;
const float CSOW_TIME_RELOAD				= 5.0;
const Vector2D CSOW_RECOIL_STANDING_X	= Vector2D(-1.5, 1.5);
const Vector2D CSOW_RECOIL_STANDING_Y	= Vector2D(-1.5, 1.5);
const Vector2D CSOW_RECOIL_DUCKING_X	= Vector2D(-0.5, 0.5);
const Vector2D CSOW_RECOIL_DUCKING_Y	= Vector2D(-0.5, 0.5);
const Vector CSOW_CONE_STANDING			= VECTOR_CONE_5DEGREES;
const Vector CSOW_CONE_CROUCHING		= VECTOR_CONE_4DEGREES;
const Vector CSOW_SHELL_ORIGIN1			= Vector(10, -2.5, -17.5); //forward, right, up
const Vector CSOW_SHELL_ORIGIN2			= Vector(10, 4.5, -17.5); //forward, right, up

const string CSOW_ANIMEXT						= "minigun";

const string MODEL_VIEW							= "models/custom_weapons/cso/v_m134hero.mdl";
const string MODEL_PLAYER_IDLE				= "models/custom_weapons/cso/p_m134hero_idle.mdl";
const string MODEL_PLAYER_SPIN				= "models/custom_weapons/cso/p_m134hero_spin.mdl";
const string MODEL_WORLD						= "models/custom_weapons/cso/w_m134hero.mdl";
const string MODEL_SHELL1						= "models/custom_weapons/cso/shell762_m134_01.mdl";
const string MODEL_SHELL2						= "models/custom_weapons/cso/shell762_m134.mdl";

const string SPRITE_STEAM						= "sprites/custom_weapons/cso/m134hero_steam.spr";

const string SPRITE_HUD							= "custom_weapons/cso/progressbar.spr"; //from Outerbeast
const int CSOW_HUD_MAXFRAME				= 10;
const int CSOW_HUD_CHANNEL_CD				= 6;
const float CSOW_HUD_CD_X						= 0;
const float CSOW_HUD_CD_Y						= 256;

enum csow_e
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_RELOAD,
	ANIM_SHOOT_START,
	ANIM_SHOOT_LOOP, //5
	ANIM_SHOOT_END,
	ANIM_FIRE_CHANGE,
	ANIM_IDLE_CHANGE,
	ANIM_OH_DRAW,
	ANIM_OH_START, //10
	ANIM_OH_IDLE,
	ANIM_OH_END,
	ANIM_SFIRE_START,
	ANIM_SFIRE_LOOP,
	ANIM_SFIRE_END //15
};

enum csowsounds_e
{
	SND_EMPTY = 0,
	SND_SPINDOWN,
	SND_SPINUP,
	SND_SPIN,
	SND_SHOOT,
	SND_STEAM
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav",
	"custom_weapons/cso/m134hero_spindown.wav",
	"custom_weapons/cso/m134hero_spinup.wav",
	"custom_weapons/cso/m134ex_spin.wav",
	"custom_weapons/cso/m134ex-1.wav",
	"custom_weapons/cso/steam.wav",
	"custom_weapons/cso/m134_clipoff.wav",
	"custom_weapons/cso/m134_clipon.wav",
	"custom_weapons/cso/m134hero_draw.wav",
	"custom_weapons/cso/m134hero_fire_after_overheat.wav",
	"custom_weapons/cso/m134hero_overheat_end.wav",
	"custom_weapons/cso/m134hero_overload.wav"
};

enum csowstate_e
{
	STATE_NONE = 0,
	STATE_BEGIN,
	STATE_LOOP,
	STATE_END
};

class weapon_m134hero : CBaseCSOWeapon
{
	private int m_iState;
	private float m_flFiringTime;
	private float m_flSteamTime;
	private float m_flCooldownRate;
	private int m_iCooldown;
	private float m_flSpeedControl;
	private float m_flAttackDelay;
	private bool m_bOverheated;
	private bool m_bRapidMode;
	private bool m_bFired;
	private HUDSpriteParams m_hudParamsCooldown;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;

		m_iState = STATE_NONE;
		m_bOverheated = false;
		m_bRapidMode = false;
		m_bFired = false;
		m_iCooldown = 0;
		SetHudParamsCooldown();
		g_iCSOWHands = HANDS_SVENCOOP;
		m_bSwitchHands = true;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER_IDLE );
		g_Game.PrecacheModel( MODEL_PLAYER_SPIN );
		g_Game.PrecacheModel( MODEL_WORLD );
		g_Game.PrecacheModel( "models/custom_weapons/cs16/w_762natobox_big.mdl" );
		g_Game.PrecacheModel( SPRITE_STEAM );
		g_Game.PrecacheModel( MODEL_SHELL1 );
		g_Game.PrecacheModel( MODEL_SHELL2 );

		if( cso::bUseDroppedItemEffect )
			g_Game.PrecacheModel( cso::CSO_ITEMDISPLAY_MODEL );

		for( uint i = 1; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_m134hero.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud128.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash6.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/muzzleflash7.spr" );
		g_Game.PrecacheGeneric( "sprites/" + SPRITE_HUD );
		g_Game.PrecacheGeneric( "events/cso/muzzle_m134hero1.txt" );
		g_Game.PrecacheGeneric( "events/cso/muzzle_m134hero2.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CSOW_MAX_AMMO;
		info.iMaxClip 		= CSOW_MAX_CLIP;
		info.iAmmo1Drop	= 100;
		info.iSlot			= cso::M134HERO_SLOT - 1;
		info.iPosition		= cso::M134HERO_POSITION - 1;
		info.iWeight		= cso::M134HERO_WEIGHT;
		info.iFlags			= ITEM_FLAG_NOAUTORELOAD; //removing this may interfere with the overheating if the weapon is fired until out of clip-ammo

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName("weapon_m134hero") );
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
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER_IDLE), m_bOverheated ? ANIM_OH_DRAW : ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;

			return bResult;
		}
	}

	bool CanHolster() //Doesn't prevent weapon switching, only quickswitch
	{
		return !(m_bRapidMode);
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		//SetThink(null);
		m_iState = STATE_NONE;
		m_bRapidMode = false;
		g_PlayerFuncs.HudToggleElement( m_pPlayer, CSOW_HUD_CHANNEL_CD, false );

		BaseClass.Holster( skipLocal );
	}

	~weapon_m134hero()
	{
		self.m_fInReload = false;
		SetThink(null);
		m_iState = STATE_NONE;
		m_bOverheated = false;
		m_bRapidMode = false;
		g_PlayerFuncs.HudToggleElement( m_pPlayer, CSOW_HUD_CHANNEL_CD, false );
	}

	void PrimaryAttack()
	{
		if( m_bOverheated ) return;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( m_iState == STATE_NONE )
		{
			m_iState = STATE_BEGIN;

			m_flFiringTime = 0.0;
			m_bFired = false;
			m_bRapidMode = false;
		}
		else if( m_iState == STATE_BEGIN )
		{
			if( m_pPlayer.pev.weaponanim != ANIM_SHOOT_END ) self.SendWeaponAnim( ANIM_SHOOT_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_SPIN;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.2;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.7;

			m_iState = STATE_LOOP;
		}
		else if( m_iState == STATE_LOOP )
		{
			if( self.m_iClip > 0 )
			{
				if( !m_bRapidMode ) self.SendWeaponAnim( ANIM_SHOOT_LOOP, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				else self.SendWeaponAnim( ANIM_SFIRE_LOOP, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				ScreenShake();

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.5;
				self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
			}
			else
			{
				m_iState = STATE_END;
				self.SendWeaponAnim( ANIM_SHOOT_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				m_pPlayer.pev.weaponmodel = MODEL_PLAYER_IDLE;

				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SPINDOWN], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.25;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.5;

				m_iState = STATE_NONE;
			}
		}
	}

	void SecondaryAttack()
	{
		if( m_bOverheated ) return;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if( m_iState == STATE_NONE )
		{
			m_bRapidMode = true;

			m_flFiringTime = 0.0;
			m_bFired = false;
			m_iState = STATE_BEGIN;
		}
		else if( m_iState == STATE_BEGIN )
		{
			if( m_pPlayer.pev.weaponanim != ANIM_SHOOT_END ) self.SendWeaponAnim( ANIM_SFIRE_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_SPIN;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SPINUP], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

			ScreenShake();

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.2;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.7;

			m_iState = STATE_LOOP;
		}
		else if( m_iState == STATE_LOOP )
		{
			if( self.m_iClip > 0 )
			{
				if( !m_bRapidMode ) self.SendWeaponAnim( ANIM_SHOOT_LOOP, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
				else self.SendWeaponAnim( ANIM_SFIRE_LOOP, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.5;
				self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
			}
			else
			{
				m_iState = STATE_END;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SPINDOWN], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );
				m_pPlayer.pev.weaponmodel = MODEL_PLAYER_IDLE;

				Overheat_Begin();

				m_iState = STATE_NONE;
			}
		}
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or m_bOverheated )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );

		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( m_bOverheated ? ANIM_OH_IDLE : ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + 20.0;

		if( m_iState == STATE_LOOP )
		{
			m_iState = STATE_END;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SPINDOWN], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 2.0;

			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.25; //??

			if( !m_bRapidMode ) self.SendWeaponAnim( ANIM_SHOOT_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			else Overheat_Begin();

			m_pPlayer.pev.weaponmodel = MODEL_PLAYER_IDLE;

			m_iState = STATE_NONE;
		}
	}

	void ItemPostFrame()
	{
		if( m_bOverheated )
		{
			if( g_Engine.time - 1.0 > m_flSteamTime )
			{
				Vector vecOrigin;
				get_position( 20.0, 0.0, 0.0, vecOrigin );

				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_SPRITE );
					m1.WriteCoord( vecOrigin.x );
					m1.WriteCoord( vecOrigin.y );
					m1.WriteCoord( vecOrigin.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_STEAM) );
					m1.WriteByte( 1 ); // scale * 10
					m1.WriteByte( 250 ); // brightness
				m1.End(); 

				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_STEAM], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

				m_flSteamTime = g_Engine.time;
			}
		}

		if( m_iState == STATE_LOOP )
		{
			float flDerSpeed;
			flDerSpeed = m_bRapidMode ? CSOW_TIME_DELAY2 : CSOW_TIME_DELAY1;

			if( g_Engine.time - flDerSpeed > m_flSpeedControl )
			{
				if( self.m_iClip > 0 )
				{
					m_bFired = true;

					HandleRecoil( CSOW_RECOIL_STANDING_X, CSOW_RECOIL_STANDING_Y, CSOW_RECOIL_DUCKING_X, CSOW_RECOIL_DUCKING_Y );
					HandleBrassEject();
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.52, 0, 94 + Math.RandomLong(0, 15) );

					if( g_Engine.time - 1.0 > m_flSteamTime )
					{
						m_flFiringTime++;
						m_flSteamTime = g_Engine.time;
					}

					m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
					m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
					m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

					Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
					Vector vecSrc = m_pPlayer.GetGunPosition();
					Vector vecAiming = g_Engine.v_forward;
					Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? CSOW_CONE_CROUCHING : CSOW_CONE_STANDING;

					m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, CSOW_DAMAGE );
					DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_SAW, true );

					HandleAmmoReduction();
				}
				else
				{
					m_iState = STATE_END;
					if( !m_bRapidMode ) self.SendWeaponAnim( ANIM_SHOOT_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
					else Overheat_Begin();
					//else self.SendWeaponAnim( ANIM_SFIRE_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

					self.m_flTimeWeaponIdle = g_Engine.time + 2.5;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.25;

					m_iState = STATE_NONE;
				}

				m_flSpeedControl = g_Engine.time;
			}

			float flDerTime;
			flDerTime = m_bRapidMode ? 0.1 : 0.25;

			if( g_Engine.time - flDerTime > m_flAttackDelay )
			{
				if( self.m_iClip > 0 )
				{
					//HandleAmmoReduction(); //Putting the ammo reduction here instead makes it reduce at a much slower rate

					if( self.m_iClip <= 0 and m_bRapidMode )
					{
						SetThink( ThinkFunction(this.Overheat_Begin) );
						pev.nextthink = g_Engine.time + 0.1;
					}
				}

				m_flAttackDelay = g_Engine.time;
			}
		}

		BaseClass.ItemPostFrame();
	}

	void ScreenShake()
	{
		NetworkMessage m1( MSG_ONE_UNRELIABLE, NetworkMessages::ScreenShake, g_vecZero, m_pPlayer.edict() );
			m1.WriteShort( 8192 );
			m1.WriteShort( 4096 );
			m1.WriteShort( 8192 );
/*
			m1.WriteShort( (1<<12) * 10 );
			m1.WriteShort( (1<<12) * 2 );
			m1.WriteShort( (1<<12) * 10 );
*/
		m1.End();
	}

	void Overheat_Begin()
	{
		if( m_bFired )
		{
			if( m_flFiringTime > 0.0 )
			{
				m_bOverheated = true;

				m_flSteamTime = g_Engine.time + 1.0;

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + (m_flFiringTime + 1.0);
				self.m_flTimeWeaponIdle = g_Engine.time + 3.5;

				self.SendWeaponAnim( ANIM_OH_START, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

				ShowCooldownBar();
				m_flCooldownRate = (m_flFiringTime + 1.0) / CSOW_HUD_MAXFRAME;
				SetThink( ThinkFunction(this.CooldownThink) );
				pev.nextthink = g_Engine.time;
			}
			else
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.25;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.5;

				self.SendWeaponAnim( ANIM_SFIRE_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			}
		}
		else
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 0.25;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.5;

			self.SendWeaponAnim( ANIM_SFIRE_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		}
	}

	void Overheat_End()
	{
		m_bOverheated = false;
		m_iCooldown = 0;
		m_flCooldownRate = 0.0;
		m_flFiringTime = 0.0;

		self.SendWeaponAnim( ANIM_OH_END, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack  = g_Engine.time + 2.0;
		self.m_flTimeWeaponIdle = g_Engine.time + 2.5;
		SetThink( null );
		g_PlayerFuncs.HudToggleElement( m_pPlayer, CSOW_HUD_CHANNEL_CD, false );
	}

	void ShowCooldownBar()
	{
		m_hudParamsCooldown.frame = 0;
		g_PlayerFuncs.HudCustomSprite( m_pPlayer, m_hudParamsCooldown );
	}

	void CooldownThink()
	{
		if( m_iCooldown > CSOW_HUD_MAXFRAME )
		{
			Overheat_End();
			return;
		}

		m_hudParamsCooldown.frame = Math.clamp(0, CSOW_HUD_MAXFRAME, m_iCooldown );

		if( pev.owner !is null)
			g_PlayerFuncs.HudCustomSprite( m_pPlayer, m_hudParamsCooldown );

		m_iCooldown++;

		pev.nextthink = g_Engine.time + m_flCooldownRate;
	}

	void SetHudParamsCooldown()
	{
		m_hudParamsCooldown.channel = CSOW_HUD_CHANNEL_CD;
		m_hudParamsCooldown.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_SCR_CENTER_X | HUD_SPR_MASKED;
		m_hudParamsCooldown.spritename = SPRITE_HUD;
		m_hudParamsCooldown.x = CSOW_HUD_CD_X;
		m_hudParamsCooldown.y = CSOW_HUD_CD_Y;
		m_hudParamsCooldown.color1 = RGBA_WHITE;
	}

	void HandleBrassEject()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		Vector vecShellVelocity = m_pPlayer.pev.velocity + -g_Engine.v_right * Math.RandomFloat(50, 70) + g_Engine.v_up * Math.RandomFloat(100, 150) + g_Engine.v_forward * 25;
		EjectBrass( pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * CSOW_SHELL_ORIGIN1.x - g_Engine.v_right * CSOW_SHELL_ORIGIN1.y + g_Engine.v_up * CSOW_SHELL_ORIGIN1.z, vecShellVelocity, MODEL_SHELL1 );

		Vector vecShellVelocity2 = m_pPlayer.pev.velocity + g_Engine.v_right * Math.RandomFloat(50, 70) + g_Engine.v_up * Math.RandomFloat(100, 150) + g_Engine.v_forward * 25;
		EjectBrass( pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * CSOW_SHELL_ORIGIN2.x + g_Engine.v_right * CSOW_SHELL_ORIGIN2.y + g_Engine.v_up * CSOW_SHELL_ORIGIN2.z, vecShellVelocity2, MODEL_SHELL2 );
	}

	void EjectBrass( Vector vecOrigin, Vector vecVelocity, string szShellModel )
	{
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_MODEL );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteCoord( vecVelocity.x ); 
			m1.WriteCoord( vecVelocity.y );
			m1.WriteCoord( vecVelocity.z );
			m1.WriteAngle( Math.RandomLong(0, 360) );
			m1.WriteShort( g_EngineFuncs.ModelIndex(szShellModel) );
			m1.WriteByte( TE_BOUNCE_SHELL );
			m1.WriteByte( 7 );
		m1.End();		
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m134hero::weapon_m134hero", "weapon_m134hero" );
	g_ItemRegistry.RegisterWeapon( "weapon_m134hero", "custom_weapons/cso", "762mg", "", "ammo_762mg" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "ammo_762mg" ) )
		cso::Register762MG();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_m134hero END

/*
TODO
Fix p_model (placement and angle)
Fix thing with overheating

*/