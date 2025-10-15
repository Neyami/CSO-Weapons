enum csowstate_e
{
	STATE_NONE = 0,
	STATE_RELOAD_START,
	STATE_RELOAD_MID,
	STATE_RELOAD_QUICK,
	STATE_RELOAD_END
};

mixin class CSOCrowSeries
{
	private int m_iReloadState;
	private bool m_bQuickReloadFailed;
	private bool m_bDontAutoReload;

	void Holster( int skipLocal = 0 )
	{
		if( m_pPlayer.m_iFOV != 0 )
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;

		self.m_fInReload = false;
		SetThink(null);
		m_iReloadState = STATE_NONE;
		m_bQuickReloadFailed = false;
		m_bDontAutoReload = false;
		BaseClass.Holster( skipLocal );
	}

	void ItemPreFrame()
	{
		if( ShouldReload() )
		{
			switch( m_iReloadState )
			{
				case STATE_NONE:
				{
					if( m_pPlayer.m_iFOV != 0 )
						m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;

					m_bQuickReloadFailed = false;
					m_iReloadState = STATE_RELOAD_START;
					self.SendWeaponAnim( ANIM_RELOAD_START );

					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD1;
					SetThink( ThinkFunction(this.ReloadThink) );
					pev.nextthink = g_Engine.time + CSOW_TIME_RELOAD_PRE;
					break;
				}

				case STATE_RELOAD_START:
				{
					m_bQuickReloadFailed = true;
					break;
				}

				case STATE_RELOAD_MID:
				{
					if( !m_bQuickReloadFailed )
					{
						m_iReloadState = STATE_RELOAD_QUICK;
						self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + (CSOW_TIME_RELOAD_END_QUICK + 0.1);
						self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD_END_QUICK + 0.5);
						SetThink( ThinkFunction(this.ReloadThink) );
						pev.nextthink = g_Engine.time;
					}

					break;
				}
			}
		}

		BaseClass.ItemPreFrame();
	}

	bool ShouldReload()
	{
		if( self.m_iClip >= CSOW_MAX_CLIP or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return false;

		//(m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0
		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 and (m_pPlayer.pev.button & IN_ATTACK) == 0 and (m_pPlayer.pev.button & IN_ATTACK2) == 0 )
			return true;

		if( self.m_iClip <= 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 and (m_pPlayer.pev.button & IN_ATTACK) == 0 and (m_pPlayer.pev.button & IN_ATTACK2) == 0 and !m_bDontAutoReload )
		{
			m_bDontAutoReload = true;
			return true;
		}

		return false;
	}

	void ReloadThink()
	{
		switch( m_iReloadState )
		{
			case STATE_RELOAD_START:
			{
				m_iReloadState = STATE_RELOAD_MID;
				pev.nextthink = g_Engine.time + CSOW_TIME_RELOAD_WINDOW;
				break;
			}

			case STATE_RELOAD_MID:
			{
				self.SendWeaponAnim( ANIM_RELOAD_END_NORMAL );
				m_iReloadState = STATE_RELOAD_END;
				pev.nextthink = g_Engine.time + CSOW_TIME_RELOAD_END_NORM;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD_END_NORM + 0.1);
				break;
			}

			case STATE_RELOAD_QUICK:
			{
				self.SendWeaponAnim( ANIM_RELOAD_END_QUICK );
				m_iReloadState = STATE_RELOAD_END;
				pev.nextthink = g_Engine.time + CSOW_TIME_RELOAD_END_QUICK;
				break;
			}

			case STATE_RELOAD_END:
			{
				int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

				if( ammo <= 0 or self.m_iClip >= CSOW_MAX_CLIP )
					return;

				while( ammo > 0 )
				{
					if( self.m_iClip >= CSOW_MAX_CLIP ) break;

					--ammo;
					++self.m_iClip;
				}

				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
				SetThink( null );
				m_iReloadState = STATE_NONE;
				m_bQuickReloadFailed = false;
				m_bDontAutoReload = false;
				break;
			}
		}
	}
}