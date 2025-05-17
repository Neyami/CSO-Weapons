namespace cso_aeolis
{

const int AEOLIS_DEFAULT_GIVE				= 150;
const int AEOLIS_MAX_AMMO					= 200;
const int AEOLIS_MAX_AMMO2				= 89;
const int AEOLIS_MAX_CLIP 					= 150;
const float AEOLIS_DAMAGE					= 30;
const float AEOLIS_DAMAGE_FLAME		= 35;
const float AEOLIS_DELAY_PRIMARY		= 0.10;
const float AEOLIS_DELAY_SECONDARY	= 0.10;//0.095
const float AEOLIS_TIME_RELOAD			= 4.5;
const float AEOLIS_TIME_IDLE				= 5.05;
const float AEOLIS_TIME_DRAW				= 1.0;
const float AEOLIS_TIME_FIRE_TO_IDLE	= 1.0;
const float AEOLIS_RECOIL_X					= Math.RandomFloat( -2.0, 2.0 + Math.RandomFloat(0, 0.3) );
const float AEOLIS_RECOIL_Y					= Math.RandomFloat( 2.0 + Math.RandomFloat(0, 0.1), -2.0 );
const float CSOW_FLAME_SPEED				= 640.0;

const string CSOW_ANIMEXT					= "saw";

const string AEOLIS_MODEL_VIEW			= "models/custom_weapons/cso/v_aeolis.mdl";
const string AEOLIS_MODEL_PLAYER		= "models/custom_weapons/cso/p_aeolis.mdl";
const string AEOLIS_MODEL_WORLD		= "models/custom_weapons/cso/w_aeolis.mdl";
const string AEOLIS_MODEL_SHELL			= "models/custom_weapons/cso/shell_556_big.mdl";
const string AEOLIS_MODEL_CLIP			= "models/custom_weapons/cso/clip_aeolis.mdl";
const string SPRITE_FLAME						= "sprites/custom_weapons/cso/flame_puff01.spr";

const Vector CSOW_SHELL_ORIGIN		= Vector(15.0, 13.0, -10.0); //forward, right, up

enum csow_e
{
	AEOLIS_IDLE = 0,
	AEOLIS_SHOOT_BULLET,
	AEOLIS_SHOOT_FLAME,
	AEOLIS_RELOAD,
	AEOLIS_DRAW
};

enum csowsounds_e
{
	SND_SHOOT = 1,
	SND_IDLE,
	SND_FLAME1,
	SND_FLAME2,
	SND_STEAM
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_rifle.wav", //only here for the precache
	"custom_weapons/cso/aeolis-1.wav",
	"custom_weapons/cso/aeolis_idle2.wav",
	"custom_weapons/cso/flamegun-1.wav",
	"custom_weapons/cso/flamegun-2.wav",
	"custom_weapons/cso/papin_steam.wav",
	"custom_weapons/cso/aeolis_clipin1.wav",
	"custom_weapons/cso/aeolis_clipin2.wav",
	"custom_weapons/cso/aeolis_clipin3.wav",
	"custom_weapons/cso/aeolis_clipout1.wav",
	"custom_weapons/cso/aeolis_draw.wav"
};

class weapon_aeolis : CBaseCSOWeapon
{
	private int m_iInAttack, m_iAnimate, m_iAmmoUse;
	private int m_iDroppedClip;
	private int m_iHeat, heatCount;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, AEOLIS_MODEL_WORLD );
		self.m_iDefaultAmmo = AEOLIS_DEFAULT_GIVE;
		m_iHeat = 0;
		m_iAmmoUse = 0;
		m_iAnimate = 0;
		//self.InitBoneControllers();
		//self.SetBoneController( 0, -44 );
		self.m_flCustomDmg = self.pev.dmg;

		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( AEOLIS_MODEL_VIEW );
		g_Game.PrecacheModel( AEOLIS_MODEL_PLAYER );
		g_Game.PrecacheModel( AEOLIS_MODEL_WORLD );

		g_Game.PrecacheOther( "csoproj_flame" );
		g_Game.PrecacheOther( "cso_dotent" );

		m_iShell = g_Game.PrecacheModel( AEOLIS_MODEL_SHELL );
		g_Game.PrecacheModel( AEOLIS_MODEL_CLIP );

		for( uint i = 0; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		g_Game.PrecacheModel( SPRITE_FLAME );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_aeolis.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud106.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= AEOLIS_MAX_AMMO;
		info.iMaxAmmo2 	= AEOLIS_MAX_AMMO2;
		info.iMaxClip 	= AEOLIS_MAX_CLIP;
		info.iSlot 		= cso::AEOLIS_SLOT - 1;
		info.iPosition 	= cso::AEOLIS_POSITION - 1;
		info.iWeight 	= cso::AEOLIS_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage aeolis( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			aeolis.WriteLong( g_ItemRegistry.GetIdForName("weapon_aeolis") );
		aeolis.End();

		return true;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			m_iInAttack = 0;
			bResult = self.DefaultDeploy( self.GetV_Model( AEOLIS_MODEL_VIEW ), self.GetP_Model( AEOLIS_MODEL_PLAYER ), AEOLIS_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + AEOLIS_TIME_DRAW;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE], 0.5, ATTN_NORM );
			heatCount = 1;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_IDLE] );
		self.m_fInReload = false;
		m_iInAttack = 0;
		m_iAnimate = 0;

		SetThink(null);
		
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? VECTOR_CONE_4DEGREES : VECTOR_CONE_5DEGREES;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

			return;
		}

		if( m_iInAttack == 2 )
		{
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
			WeaponIdle();

			return;
		}

		if( m_iInAttack == 0 )
			m_iInAttack = 1;
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		--self.m_iClip;

		self.SendWeaponAnim( AEOLIS_SHOOT_BULLET, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xf ) );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = AEOLIS_DAMAGE;

		if( self.m_flCustomDmg > 0 ) flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, 4, int(flDamage) );

		int r = 255, g = 200, b = 100;
		
		NetworkMessage firedl( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			firedl.WriteByte( TE_DLIGHT );
			firedl.WriteCoord( vecSrc.x );
			firedl.WriteCoord( vecSrc.y );
			firedl.WriteCoord( vecSrc.z );
			firedl.WriteByte( 8 );//radius
			firedl.WriteByte( int(r) );
			firedl.WriteByte( int(g) );
			firedl.WriteByte( int(b) );
			firedl.WriteByte( 4 );//life
			firedl.WriteByte( 128 );//decay
		firedl.End();

		if( (heatCount++ % 2) == 0 )
		{
			if( m_iHeat < 50 )
				m_iHeat += 1;

			if( m_iHeat == 10 or m_iHeat == 24 )
			{
				cso::DoGunSmoke( vecSrc + g_Engine.v_forward * 8 + g_Engine.v_up * -10 + g_Engine.v_right * 4, SMOKE_RIFLE );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_AUTO, pCSOWSounds[SND_STEAM], 0.5, ATTN_NORM );
			}
		}

		//self.SetBoneController( 0, m_iHeat );
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_iHeat );

		Vector vecShellOrigin, vecShellVelocity;
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, CSOW_SHELL_ORIGIN.x, CSOW_SHELL_ORIGIN.y, CSOW_SHELL_ORIGIN.z, false, false );
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(AEOLIS_MODEL_SHELL), TE_BOUNCE_SHELL ); 
		//EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL );

		DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_SAW );

		if( self.m_iClip == 0 and m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? AEOLIS_RECOIL_X/2 : AEOLIS_RECOIL_X;
		m_pPlayer.pev.punchangle.y = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? AEOLIS_RECOIL_Y/2 : AEOLIS_RECOIL_Y;
		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;
		self.m_flNextPrimaryAttack = g_Engine.time + AEOLIS_DELAY_PRIMARY;
		self.m_flTimeWeaponIdle = g_Engine.time + AEOLIS_TIME_FIRE_TO_IDLE;
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 or m_iInAttack == 1 )
		{
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			WeaponIdle();

			return;
		}
		
		if( m_iAnimate == 0 and m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 )
		{
			self.SendWeaponAnim( AEOLIS_SHOOT_FLAME, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_FLAME1], 0.9, ATTN_NORM, SND_FORCE_LOOP, 95 + Math.RandomLong( 0, 10 ) );
			m_iAnimate = 1;

			return;
		}

		++m_iAmmoUse;
		
		if( m_iAmmoUse == 1 )
		{
			if( m_iHeat > 0 )
				m_iHeat -= 1;

			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_iHeat );
			m_iAmmoUse = 0;
		}

		if( m_iInAttack == 0 )
		{
			m_iInAttack = 2;
			return;
		}

		if( m_iInAttack == 2 )
			FlamethrowerFire( 4 );
	}

	void FlamethrowerFire( int iSoundFrequency )
	{
		Vector vecAngles, vecOrigin, vecTargetOrigin, vecVelocity;

		get_position( 40.0, 5.0, -5.0, vecOrigin );
		get_position( 1024.0, 0.0, 0.0, vecTargetOrigin );

		vecAngles = m_pPlayer.pev.angles;

		vecAngles.z = Math.RandomFloat( 0.0, 18.0 ) * 20;

		CBaseEntity@ pFlame = g_EntityFuncs.Create( "csoproj_flame", vecOrigin, vecAngles, false, m_pPlayer.edict() );

		get_speed_vector( vecOrigin, vecTargetOrigin, CSOW_FLAME_SPEED, vecVelocity );
		pFlame.pev.velocity = vecVelocity;

		float flDamage = AEOLIS_DAMAGE_FLAME;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		pFlame.pev.dmg = flDamage;

		g_EntityFuncs.DispatchSpawn( pFlame.edict() );

		self.m_flNextSecondaryAttack = g_Engine.time + AEOLIS_DELAY_SECONDARY;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.1;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 or self.m_iClip >= AEOLIS_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( AEOLIS_MAX_CLIP, AEOLIS_RELOAD, AEOLIS_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + 4.0f;

		self.pev.nextthink = g_Engine.time + 1.25f;
		SetThink( ThinkFunction(EjectClipThink) );
		heatCount = 0;
		m_iAnimate = 0;
		m_iInAttack = 0;

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		ClipCasting( m_pPlayer.pev.origin );
	}
	
	void ClipCasting( Vector origin )
	{
		if( m_iDroppedClip == 1 )
			return;
			
		int lifetime = 69;
		
		NetworkMessage aeolisclip( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
				aeolisclip.WriteByte( TE_BREAKMODEL );
				aeolisclip.WriteCoord( origin.x );
				aeolisclip.WriteCoord( origin.y );
				aeolisclip.WriteCoord( origin.z );
				aeolisclip.WriteCoord( 0 );
				aeolisclip.WriteCoord( 0 );
				aeolisclip.WriteCoord( 0 );
				aeolisclip.WriteCoord( 0 ); // velocity
				aeolisclip.WriteCoord( 0 ); // velocity
				aeolisclip.WriteCoord( 0 ); // velocity
				aeolisclip.WriteByte( 0 );
				aeolisclip.WriteShort( g_EngineFuncs.ModelIndex( AEOLIS_MODEL_CLIP ) );
				aeolisclip.WriteByte( 1); // bounce sound
				aeolisclip.WriteByte( int(lifetime) );
				aeolisclip.WriteByte( 2 ); // metallic sound
		aeolisclip.End();

		m_iDroppedClip = 1;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( m_iInAttack > 0 )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 0.1;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.1;

			if( m_iInAttack == 2 )
			{
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_FLAME1] );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, pCSOWSounds[SND_FLAME2], 0.9, ATTN_NORM, 0, PITCH_NORM );
			}

			m_iInAttack = 0;
			m_iAnimate = 0;

			return;
		}

		if( m_iDroppedClip == 1)
			m_iDroppedClip = 0;

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( AEOLIS_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + AEOLIS_TIME_IDLE;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso::csoproj_flame", "csoproj_flame" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_aeolis::weapon_aeolis", "weapon_aeolis" );
	g_ItemRegistry.RegisterWeapon( "weapon_aeolis", "custom_weapons/cso", "556", "aeolisflame", "ammo_556" );

	cso::RegisterDotEnt();

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_aeolis END