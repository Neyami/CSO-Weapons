namespace cso_aeolis
{

const int AEOLIS_DEFAULT_GIVE			= 150;
const int AEOLIS_MAX_AMMO				= 200;
const int AEOLIS_MAX_AMMO2				= 89;
const int AEOLIS_MAX_CLIP 				= 150;
const float AEOLIS_DAMAGE				= 30;
const float AEOLIS_DAMAGE_FLAME			= 35;
const float AEOLIS_DELAY_PRIMARY		= 0.10;
const float AEOLIS_DELAY_SECONDARY		= 0.10;//0.095
const float AEOLIS_TIME_RELOAD			= 4.5;
const float AEOLIS_TIME_IDLE			= 5.05;
const float AEOLIS_TIME_DRAW			= 1.0;
const float AEOLIS_TIME_FIRE_TO_IDLE	= 1.0;
const float AEOLIS_RECOIL_X				= Math.RandomFloat( -2.0, 2.0 + Math.RandomFloat(0, 0.3) );
const float AEOLIS_RECOIL_Y				= Math.RandomFloat( 2.0 + Math.RandomFloat(0, 0.1), -2.0 );

const string AEOLIS_MODEL_VIEW			= "models/custom_weapons/cso/v_aeolis.mdl";
const string AEOLIS_MODEL_PLAYER		= "models/custom_weapons/cso/p_aeolis.mdl";
const string AEOLIS_MODEL_WORLD			= "models/custom_weapons/cso/w_aeolis.mdl";
const string AEOLIS_MODEL_SHELL			= "models/custom_weapons/cso/shell_556_big.mdl";
const string AEOLIS_MODEL_CLIP			= "models/custom_weapons/cso/clip_aeolis.mdl";
const string AEOLIS_SPRITE_FLAME		= "sprites/custom_weapons/cso/flame_puff01.spr";

const string AEOLIS_SOUND_CLIPIN1		= "custom_weapons/cso/aeolis_clipin1.wav";
const string AEOLIS_SOUND_CLIPIN2		= "custom_weapons/cso/aeolis_clipin2.wav";
const string AEOLIS_SOUND_CLIPIN3		= "custom_weapons/cso/aeolis_clipin3.wav";
const string AEOLIS_SOUND_CLIPOUT		= "custom_weapons/cso/aeolis_clipout1.wav";
const string AEOLIS_SOUND_DRAW			= "custom_weapons/cso/aeolis_draw.wav";
const string AEOLIS_SOUND_IDLE			= "custom_weapons/cso/aeolis_idle2.wav";
const string AEOLIS_SOUND_SHOOT			= "custom_weapons/cso/aeolis-1.wav";
const string AEOLIS_SOUND_FLAME1		= "custom_weapons/cso/flamegun-1.wav";
const string AEOLIS_SOUND_FLAME2		= "custom_weapons/cso/flamegun-2.wav";
const string AEOLIS_SOUND_STEAM			= "custom_weapons/cso/papin_steam.wav";
const string AEOLIS_SOUND_EMPTY			= "custom_weapons/cs16/dryfire_rifle.wav";

const Vector CSOW_SHELL_ORIGIN				= Vector(15.0, 13.0, -10.0); //forward, right, up

enum AeolisAnimation
{
	AEOLIS_IDLE = 0,
	AEOLIS_SHOOT_BULLET,
	AEOLIS_SHOOT_FLAME,
	AEOLIS_RELOAD,
	AEOLIS_DRAW
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

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( AEOLIS_MODEL_VIEW );
		g_Game.PrecacheModel( AEOLIS_MODEL_PLAYER );
		g_Game.PrecacheModel( AEOLIS_MODEL_WORLD );

		m_iShell = g_Game.PrecacheModel( AEOLIS_MODEL_SHELL );
		g_Game.PrecacheModel( AEOLIS_MODEL_CLIP );

		for( uint i = 0; i < cso::pSmokeSprites.length(); ++i )
			g_Game.PrecacheModel( cso::pSmokeSprites[i] );

		g_Game.PrecacheModel( AEOLIS_SPRITE_FLAME );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );

		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_CLIPIN1 );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_CLIPIN2 );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_CLIPIN3 );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_CLIPOUT );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_FLAME1 );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_FLAME2 );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_IDLE );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_SHOOT );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_STEAM );
		g_SoundSystem.PrecacheSound( AEOLIS_SOUND_EMPTY );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_CLIPIN1 );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_CLIPIN2 );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_CLIPIN3 );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_CLIPOUT );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_FLAME1 );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_FLAME2 );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_IDLE );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_STEAM );
		g_Game.PrecacheGeneric( "sound/" + AEOLIS_SOUND_EMPTY );

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
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, AEOLIS_SOUND_EMPTY, 0.8f, ATTN_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			m_iInAttack = 0;
			bResult = self.DefaultDeploy( self.GetV_Model( AEOLIS_MODEL_VIEW ), self.GetP_Model( AEOLIS_MODEL_PLAYER ), AEOLIS_DRAW, "saw" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + AEOLIS_TIME_DRAW;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, AEOLIS_SOUND_IDLE, 0.5f, ATTN_NORM );
			heatCount = 1;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, AEOLIS_SOUND_IDLE );
		self.m_fInReload = false;
		m_iInAttack = 0;
		m_iAnimate = 0;

		SetThink(null);
		
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? VECTOR_CONE_4DEGREES : VECTOR_CONE_5DEGREES;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
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

		self.SendWeaponAnim( AEOLIS_SHOOT_BULLET );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, AEOLIS_SOUND_SHOOT, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xf ) );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		float flDamage = AEOLIS_DAMAGE;

		if( self.m_flCustomDmg > 0 ) flDamage = self.m_flCustomDmg;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, int(flDamage) );

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

			if( m_iHeat == 10 || m_iHeat == 24 )
			{
				cso::DoGunSmoke( vecSrc + g_Engine.v_forward * 8 + g_Engine.v_up * -10 + g_Engine.v_right * 4, SMOKE_RIFLE );
				g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_AUTO, AEOLIS_SOUND_STEAM, 0.5f, ATTN_NORM );
			}
		}

		//self.SetBoneController( 0, m_iHeat );
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_iHeat );

		Vector vecShellOrigin, vecShellVelocity;
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, CSOW_SHELL_ORIGIN.x, CSOW_SHELL_ORIGIN.y, CSOW_SHELL_ORIGIN.z, false, false );
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, g_EngineFuncs.ModelIndex(AEOLIS_MODEL_SHELL), TE_BOUNCE_SHELL ); 
		//EjectBrass( m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL );

		DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_SAW );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? AEOLIS_RECOIL_X/2 : AEOLIS_RECOIL_X;
		m_pPlayer.pev.punchangle.y = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? AEOLIS_RECOIL_Y/2 : AEOLIS_RECOIL_Y;
		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;
		self.m_flNextPrimaryAttack = g_Engine.time + AEOLIS_DELAY_PRIMARY;
		self.m_flTimeWeaponIdle = g_Engine.time + AEOLIS_TIME_FIRE_TO_IDLE;
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 || m_iInAttack == 1 )
		{
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
			WeaponIdle();

			return;
		}
		
		if( m_iAnimate == 0 && m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 )
		{
			self.SendWeaponAnim( AEOLIS_SHOOT_FLAME );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, AEOLIS_SOUND_FLAME1, 0.9f, ATTN_NORM, SND_FORCE_LOOP, 95 + Math.RandomLong( 0, 10 ) );
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
			FlamethrowerFire();
	}

	void FlamethrowerFire()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
		{
			self.m_flNextSecondaryAttack = g_Engine.time + 0.55f;
			WeaponIdle();
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		cso::ShootCustomProjectile( "csoproj_flame", AEOLIS_SPRITE_FLAME, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 2 + g_Engine.v_up * -2, g_Engine.v_forward * 400, m_pPlayer.pev.v_angle, m_pPlayer );

		self.m_flNextSecondaryAttack = g_Engine.time + AEOLIS_DELAY_SECONDARY;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.1f;
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= AEOLIS_MAX_CLIP )
			return;

		self.DefaultReload( AEOLIS_MAX_CLIP, AEOLIS_RELOAD, AEOLIS_TIME_RELOAD );
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
			self.m_flNextPrimaryAttack = g_Engine.time + 0.1f;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.1f;

			if( m_iInAttack == 2 )
			{
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, AEOLIS_SOUND_FLAME1 );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, AEOLIS_SOUND_FLAME2, 0.9f, ATTN_NORM, 0, PITCH_NORM );
			}

			m_iInAttack = 0;
			m_iAnimate = 0;

			return;
		}

		if( m_iDroppedClip == 1)
			m_iDroppedClip = 0;

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( AEOLIS_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + AEOLIS_TIME_IDLE;
	}
}

//Thanks to Aperture for this one!
class csoproj_flame : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, AEOLIS_SPRITE_FLAME );
		g_EntityFuncs.SetSize( self.pev, Vector(-4, -4, -4), Vector(4, 4, 4) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid    = SOLID_BBOX;
		self.pev.rendermode = kRenderTransAdd;
		self.pev.renderamt = 250;  
		self.pev.scale = 0.3f;
		self.pev.frame = 0;
		self.pev.nextthink = g_Engine.time + 0.1f;
		SetThink( ThinkFunction(this.FlameThink) );
	}

	void FlameThink()
	{
		self.pev.nextthink = g_Engine.time + 0.03f;

		int r = 255, g = 200, b = 100;
		
		NetworkMessage glowdl( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			glowdl.WriteByte( TE_DLIGHT );
			glowdl.WriteCoord( self.pev.origin.x );
			glowdl.WriteCoord( self.pev.origin.y );
			glowdl.WriteCoord( self.pev.origin.z );
			glowdl.WriteByte( 16 );//radius
			glowdl.WriteByte( int(r) );
			glowdl.WriteByte( int(g) );
			glowdl.WriteByte( int(b) );
			glowdl.WriteByte( 4 );//life
			glowdl.WriteByte( 128 );//decay
		glowdl.End();

		self.pev.frame += 1.0f;
		self.pev.scale += 0.09f;
		
		if( self.pev.frame > 21 )
		{
			self.pev.frame = 0;
			g_EntityFuncs.Remove( self );
			return;
		}
	}

	void Touch( CBaseEntity@ pOther )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if( pOther.edict() is self.pev.owner )
			return;

		if( pOther.pev.classname == "csoproj_flame" )
		{
			self.pev.solid = SOLID_NOT;
			self.pev.movetype = MOVETYPE_NONE;

			return;
		}

		if( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() == true )
		{
			if( pOther.pev.classname == "monster_cleansuit_scientist" || pOther.IsMonster() == false )
				pOther.TakeDamage( pevOwner, pevOwner, Math.RandomLong(AEOLIS_DAMAGE,AEOLIS_DAMAGE_FLAME), DMG_BURN | DMG_NEVERGIB );
			else
				pOther.TakeDamage( pevOwner, pevOwner, Math.RandomLong(AEOLIS_DAMAGE,AEOLIS_DAMAGE_FLAME), DMG_BURN | DMG_POISON | DMG_NEVERGIB );
		}

		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
		SetTouch(null);
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_aeolis::csoproj_flame", "csoproj_flame" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_aeolis::weapon_aeolis", "weapon_aeolis" );
	g_ItemRegistry.RegisterWeapon( "weapon_aeolis", "custom_weapons/cso", "556", "semen", "ammo_556" );
}

} //namespace cso_aeolis END
