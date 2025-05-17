namespace cso_m950
{

const int CSOW_DEFAULT_GIVE				= 50;
const int CSOW_MAX_CLIP 					= 50;
const int CSOW_MAX_AMMO					= 120;
const float CSOW_DAMAGE						= 16;
const float CSOW_TIME_DELAY				= 0.16;
const float CSOW_TIME_RELOAD				= 3.5;
const float CSOW_TIME_IDLE					= 4.0;
const float CSOW_TIME_DRAW				= 1.0;
const float CSOW_TIME_FIRE_TO_IDLE	= 1.0;
const float CSOW_RECOIL_X					= Math.RandomLong( -2, 2 );
const float CSOW_RECOIL_Y					= 0;

const string MODEL_VIEW						= "models/custom_weapons/cso/v_m950.mdl";
const string MODEL_PLAYER					= "models/custom_weapons/cso/p_m950.mdl";
const string MODEL_WORLD					= "models/custom_weapons/cso/w_m950.mdl";
const string MODEL_SHELL						= "models/custom_weapons/cso/shell_9mm.mdl";
const string MODEL_CLIP						= "models/custom_weapons/cso/clip_m950.mdl";

const string CSOW_ANIMEXT					= "onehanded";

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
	SND_SHOOT = 1
};

const array<string> pCSOWSounds =
{
	"custom_weapons/cs16/dryfire_pistol.wav", //only here for the precache
	"custom_weapons/cso/m950-1.wav",
	"custom_weapons/cso/m950_boltpull.wav",
	"custom_weapons/cso/m950_clipin.wav",
	"custom_weapons/cso/m950_clipout.wav"
};

class weapon_m950 : CBaseCSOWeapon
{
	int m_iDroppedClip;

	void Spawn()
	{
		m_iShotsFired = 0;
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
		m_sEmptySound = pCSOWSounds[0];

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_Game.PrecacheModel( MODEL_SHELL );
		g_Game.PrecacheModel( MODEL_CLIP );

		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pCSOWSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pCSOWSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pCSOWSounds[i] );

		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/weapon_m950.txt" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/custom_weapons/cso/640hud123.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CSOW_MAX_AMMO;
		info.iMaxClip			= CSOW_MAX_CLIP;
		info.iSlot				= cso::M950_SLOT - 1;
		info.iPosition			= cso::M950_POSITION - 1;
		info.iWeight			= cso::M950_WEIGHT;

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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( MODEL_VIEW ), self.GetP_Model( MODEL_PLAYER ), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DRAW;
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
			self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DELAY*2;
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
			case 0: self.SendWeaponAnim( ANIM_SHOOT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
			case 1: self.SendWeaponAnim( ANIM_SHOOT2, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
			case 2: self.SendWeaponAnim( ANIM_SHOOT3, 0, (m_bSwitchHands ? g_iCSOWHands : 0) ); break;
		}

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, vecShootCone, 8192.0, BULLET_PLAYER_CUSTOMDAMAGE, 4, CSOW_DAMAGE );

		Vector vecShellVelocity, vecShellOrigin;
		CS16GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 15, 6, -5, true, false );
		vecShellVelocity.y *= -1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], g_EngineFuncs.ModelIndex(MODEL_SHELL), TE_BOUNCE_SHELL );

		DoDecalGunshot( vecSrc, vecAiming, vecShootCone.x, vecShootCone.y, BULLET_PLAYER_MP5 );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = CSOW_RECOIL_X;
		m_pPlayer.pev.punchangle.y = CSOW_RECOIL_Y;
		/*The Specialist-style recoil
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.5f;
		vecTemp.y += 0.25f;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;*/

		self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CSOW_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;
		m_pPlayer.pev.effects = int(m_pPlayer.pev.effects) | EF_MUZZLEFLASH;
	}	

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0 )
			return;

		self.DefaultReload( CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0) );
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

		self.SendWeaponAnim( ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0) );
		self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
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
				m950clip.WriteShort( g_EngineFuncs.ModelIndex( MODEL_CLIP ) );
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
	g_ItemRegistry.RegisterWeapon( "weapon_m950", "custom_weapons/cso", "9mm", "", "ammo_9mmclip" );

	if( cso::bUseDroppedItemEffect )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "ef_gundrop" ) )
			cso::RegisterGunDrop();
	}
}

} //namespace cso_m950 END
