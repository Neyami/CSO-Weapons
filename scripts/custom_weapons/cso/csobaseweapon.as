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

	void DoDecalGunshot( Vector vecSrc, Vector vecAiming, float flConeX, float flConeY, int iBulletType, EHandle &in ePlayer, bool bSmokePuff = false )
	{
		CBasePlayer@ pPlayer = null;

		if( ePlayer.IsValid() ) @pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
		if( pPlayer !is null ) DoDecalGunshot( vecSrc, vecAiming, flConeX, flConeY, iBulletType, pPlayer, bSmokePuff );
	}

	void DoDecalGunshot( Vector vecSrc, Vector vecAiming, float flConeX, float flConeY, int iBulletType, CBasePlayer@ pPlayer, bool bSmokePuff = false )
	{
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * flConeX * g_Engine.v_right 
						+ y * flConeY * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 8192;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, iBulletType );

					if( bSmokePuff )
					{
						NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
							m1.WriteByte( TE_EXPLOSION );
							m1.WriteCoord( tr.vecEndPos.x );
							m1.WriteCoord( tr.vecEndPos.y );
							m1.WriteCoord( tr.vecEndPos.z - 10.0 );
							m1.WriteShort( g_EngineFuncs.ModelIndex(CSO::pSmokeSprites[Math.RandomLong(1, 4)]) );
							m1.WriteByte( 2 );
							m1.WriteByte( 50 );
							m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
						m1.End();
					}
				}
			}
		}
	}
}