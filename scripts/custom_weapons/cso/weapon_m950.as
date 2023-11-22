namespace cso_m950
{

const int M950_DEFAULT_GIVE			= 50;
const int M950_MAX_AMMO				= 120;
const int M950_MAX_CLIP 			= 50;
const int M950_WEIGHT 				= 15;
const float M950_DAMAGE				= 16;
const float M950_DELAY				= 0.16f;
const float M950_TIME_RELOAD		= 3.5f;
const float M950_TIME_IDLE			= 4.0f;
const float M950_TIME_DRAW			= 1.0f;
const float M950_TIME_FIRE_TO_IDLE	= 1.0f;
const float M950_RECOIL_X			= Math.RandomLong( -2, 2 );
const float M950_RECOIL_Y			= 0;

const string M950_MODEL_VIEW		= "models/custom_weapons/cso/v_m950.mdl";
const string M950_MODEL_PLAYER		= "models/custom_weapons/cso/p_m950.mdl";
const string M950_MODEL_WORLD		= "models/custom_weapons/cso/w_m950.mdl";
const string M950_MODEL_SHELL		= "models/custom_weapons/cso/shell_9mm.mdl";
const string M950_MODEL_CLIP		= "models/custom_weapons/cso/clip_m950.mdl";

const string M950_SOUND_BOLTPULL	= "custom_weapons/cso/m950_boltpull.wav";
const string M950_SOUND_CLIPIN		= "custom_weapons/cso/m950_clipin.wav";
const string M950_SOUND_CLIPOUT		= "custom_weapons/cso/m950_clipout.wav";
const string M950_SOUND_SHOOT		= "custom_weapons/cso/m950-1.wav";
const string M950_SOUND_EMPTY		= "custom_weapons/cs16/dryfire_pistol.wav";

enum M950Animation
{
	M950_IDLE1 = 0,
	M950_RELOAD,
	M950_DRAW,
	M950_SHOOT1,
	M950_SHOOT2,
	M950_SHOOT3
};

class weapon_m950 : CBaseCustomWeapon //ScriptBasePlayerWeaponEntity
{
	//private CBasePlayer@ m_pPlayer = null;
	int m_iDroppedClip, m_iShotsFired;

	void Spawn()
	{
		m_iShotsFired = 0;
		g_EntityFuncs.SetModel( self, M950_MODEL_WORLD );
		self.m_iDefaultAmmo = M950_DEFAULT_GIVE;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( M950_MODEL_VIEW );
		g_Game.PrecacheModel( M950_MODEL_PLAYER );
		g_Game.PrecacheModel( M950_MODEL_WORLD );

		g_Game.PrecacheModel( M950_MODEL_SHELL );
		g_Game.PrecacheModel( M950_MODEL_CLIP );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );

		g_SoundSystem.PrecacheSound( M950_SOUND_BOLTPULL );
		g_SoundSystem.PrecacheSound( M950_SOUND_CLIPIN );
		g_SoundSystem.PrecacheSound( M950_SOUND_CLIPOUT );
		g_SoundSystem.PrecacheSound( M950_SOUND_SHOOT );
		g_SoundSystem.PrecacheSound( M950_SOUND_EMPTY );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/" + M950_SOUND_BOLTPULL );
		g_Game.PrecacheGeneric( "sound/" + M950_SOUND_CLIPIN );
		g_Game.PrecacheGeneric( "sound/" + M950_SOUND_CLIPOUT );
		g_Game.PrecacheGeneric( "sound/" + M950_SOUND_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + M950_SOUND_EMPTY );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_m950.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud123.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= M950_MAX_AMMO;
		info.iMaxClip 	= M950_MAX_CLIP;
		info.iSlot 		= CSO::M950_SLOT - 1;
		info.iPosition 	= CSO::M950_POSITION - 1;
		info.iFlags 	= 0;
		info.iWeight 	= M950_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m950( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m950.WriteLong( g_ItemRegistry.GetIdForName("weapon_m950") );
		m950.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, M950_SOUND_EMPTY, 0.8f, ATTN_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( M950_MODEL_VIEW ), self.GetP_Model( M950_MODEL_PLAYER ), M950_DRAW, "onehanded" );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + M950_TIME_DRAW;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		SetThink(null);

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{	
		Shoot( true );
	}

	void TertiaryAttack()
	{
		Shoot( false );
	}

	void Shoot( bool IsPrimaryAttack )
	{
		if( !IsPrimaryAttack ) m_iShotsFired++;

		if( m_iShotsFired > 10 )
		{
			g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "IT'S JAMMED! FUCKING PIECE OF SHIT GUN!!!" );
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + M950_DELAY;
			self.m_flTimeWeaponIdle = g_Engine.time + M950_DELAY*2;
			return;
		}

		Vector vecShootCone = (m_pPlayer.pev.flags & FL_DUCKING != 0) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_3DEGREES;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;
		
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0: self.SendWeaponAnim( M950_SHOOT1 ); break;
			case 1: self.SendWeaponAnim( M950_SHOOT2 ); break;
			case 2: self.SendWeaponAnim( M950_SHOOT3 ); break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, M950_SOUND_SHOOT, 1, ATTN_NORM );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 4, M950_DAMAGE );

		Vector vecShellVelocity, vecShellOrigin;
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 15, 6, -5, true, false );
		vecShellVelocity.y *= -1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], g_EngineFuncs.ModelIndex(M950_MODEL_SHELL), TE_BOUNCE_SHELL );

		CSO::DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_MP5, m_pPlayer );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = M950_RECOIL_X;
		m_pPlayer.pev.punchangle.y = M950_RECOIL_Y;
		/*The Specialist-style recoil
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.5f;
		vecTemp.y += 0.25f;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;*/

		self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + M950_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + M950_TIME_FIRE_TO_IDLE;
		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;
	}	

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= M950_MAX_CLIP )
			return;

		self.DefaultReload( M950_MAX_CLIP, M950_RELOAD, M950_TIME_RELOAD );
		self.m_flTimeWeaponIdle = g_Engine.time + 4.0f;

		self.pev.nextthink = g_Engine.time + 0.85f;
		SetThink( ThinkFunction(EjectClipThink) );
		m_iShotsFired = 0;

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( m_iDroppedClip == 1)
			m_iDroppedClip = 0;

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( M950_IDLE1 );
		self.m_flTimeWeaponIdle = g_Engine.time + M950_TIME_IDLE;
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
		
		NetworkMessage m950clip( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
				m950clip.WriteByte( TE_BREAKMODEL );
				m950clip.WriteCoord( origin.x );
				m950clip.WriteCoord( origin.y );
				m950clip.WriteCoord( origin.z );
				m950clip.WriteCoord( 0 );//size
				m950clip.WriteCoord( 0 );//size
				m950clip.WriteCoord( 0 );//size
				m950clip.WriteCoord( 0 );//velocity
				m950clip.WriteCoord( 0 );//velocity
				m950clip.WriteCoord( 0 );//velocity
				m950clip.WriteByte( 0 );//random velocity
				m950clip.WriteShort( g_EngineFuncs.ModelIndex( M950_MODEL_CLIP ) );
				m950clip.WriteByte( 1 );//count
				m950clip.WriteByte( int(lifetime) );
				m950clip.WriteByte( 2 );//flags
				/*flags
				1: glass bounce sound
				2: metallic bounce sound
				4: fleshy bounce sound
				8: wooden bounce sound
				16: smoketrails
				32: transparent models
				64: rock bounce sound
				*/
		m950clip.End();

		m_iDroppedClip = 1;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cso_m950::weapon_m950", "weapon_m950" );
	g_ItemRegistry.RegisterWeapon( "weapon_m950", "custom_weapons/cso", "9mm" );
}

} //namespace cso_m950 END
