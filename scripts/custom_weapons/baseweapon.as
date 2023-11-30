class CBaseCustomWeapon : ScriptBasePlayerWeaponEntity
{
	// Possible workaround for the SendWeaponAnim() access violation crash.
	// According to R4to0 this seems to provide at least some improvement.
	// GeckoN: TODO: Remove this once the core issue is addressed.
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	//legacy support only
	void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale )
	{
		Vector vecForward, vecRight, vecUp;

		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

		const float fR = Math.RandomFloat( 50, 70 );
		const float fU = Math.RandomFloat( 100, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}

	void CS16GetDefaultShellInfo( EHandle ePlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale, bool leftShell, bool downShell )
	{
		CBasePlayer@ pPlayer = null;

		if( ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
		if( pPlayer !is null ) CS16GetDefaultShellInfo( pPlayer, ShellVelocity, ShellOrigin, forwardScale, rightScale, upScale, leftShell, downShell );
	}

	void CS16GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale, bool leftShell, bool downShell )
	{  
		Vector vecForward, vecRight, vecUp;

		float fR;
		float fU;

		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

		(leftShell == true) ? fR = Math.RandomFloat( -70, -50 ) : fR = Math.RandomFloat( 50, 70 );
		(downShell == true) ? fU = Math.RandomFloat( -150, -100 ) : fU = Math.RandomFloat( 100, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}

	float GetFireRate( float &in rpm )
	{
		float firerate;
		rpm = (rpm / 60);
		firerate = (1 / rpm);

		return firerate;
	}

	void DynamicLight( Vector vecPos, int radius, int r, int g, int b, int life, int decay )
	{
		NetworkMessage dl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			dl.WriteByte( TE_DLIGHT );
			dl.WriteCoord( vecPos.x );
			dl.WriteCoord( vecPos.y );
			dl.WriteCoord( vecPos.z );
			dl.WriteByte( radius );
			dl.WriteByte( r );
			dl.WriteByte( g );
			dl.WriteByte( b );
			dl.WriteByte( life );
			dl.WriteByte( decay );
		dl.End();
	}
}

class CBaseCustomAmmo : ScriptBasePlayerAmmoEntity
{
	protected string m_strModel = "models/w_9mmclip.mdl"; //"models/error.mdl";
	protected string m_strName = "9mm";
	protected int m_iAmount = 17;
	protected float m_flRespawnTime = 30.0f;

	protected string m_strPickupSound = "items/9mmclip1.wav";

	void CommonSpawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, m_strModel );
		BaseClass.Spawn();
		g_EntityFuncs.DispatchKeyValue( self.edict(), "m_flCustomRespawnTime", m_flRespawnTime );
	}

	void Precache()
	{
		g_Game.PrecacheModel( m_strModel );
		g_SoundSystem.PrecacheSound( m_strPickupSound );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() ) return false;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if( pOther.GiveAmmo(m_iAmount, m_strName, pPlayer.GetMaxAmmo(m_strName), false) == -1 )
			return false;

		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, m_strPickupSound, 1, ATTN_NORM );

		return true;
	}
}

/*class CBaseCustomItem : ScriptBaseItemEntity
{
	protected CBasePlayer@ m_pPlayer = null;
	protected string m_strModel = "models/error.mdl";
	protected int m_iAmount = 0;
	protected float m_flRespawnTime = 30.0f;

	protected string m_strPickupSound = "items/9mmclip1.wav";

	void CommonSpawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, m_strModel );
		BaseClass.Spawn();
		//self.FallInit();
		pev.movetype = MOVETYPE_NONE;
		pev.noise = m_strPickupSound; // this actually doesn't work, so have to schedule later
		g_EntityFuncs.DispatchKeyValue( self.edict(), "m_flCustomRespawnTime", m_flRespawnTime );
	}

	void Precache()
	{
		g_Game.PrecacheModel( m_strModel );
		g_SoundSystem.PrecacheSound( m_strPickupSound );
		g_SoundSystem.PrecacheSound( "items/suitchargeok1.wav" );
	}
}*/