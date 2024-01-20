class CBaseCSOWeapon : ScriptBasePlayerWeaponEntity
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
}