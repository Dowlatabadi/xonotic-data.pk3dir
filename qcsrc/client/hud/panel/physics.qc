#include "physics.qh"

#include <client/autocvars.qh>
#include <client/defs.qh>
#include <client/miscfunctions.qh>
#include <client/main.qh>
#include <common/mapinfo.qh>
#include <lib/csqcmodel/cl_player.qh>

// StrafeHUD cvars, should be handled in a different file
AUTOCVAR_SAVE(hud_panel_physics_strafehud, bool, false, "displays a hud intended for strafing");
AUTOCVAR_SAVE(hud_strafehud_bar_alpha, float, 0.4, "opacity of the strafe meter");
AUTOCVAR_SAVE(hud_strafehud_bar_color, vector, '255 255 255', "color of the strafe meter");
AUTOCVAR_SAVE(hud_strafehud_indicator_color, vector, '0 255 0', "color of the strafe angle indicator");
AUTOCVAR_SAVE(hud_strafehud_indicator_switch_color, vector, '255 127 0', "color of the strafe angle indicator on the opposite side");
AUTOCVAR_SAVE(hud_strafehud_angle, float, 0, "the maximum angle displayed on the hud, \"0\" = dynamic (please stick with dynamic mode for now)");
AUTOCVAR_SAVE(hud_strafehud_good_color, vector, '0 255 255', "indicator color of the actual strafe angle if the angle matches the ideal angle");
AUTOCVAR_SAVE(hud_strafehud_warning_color, vector, '255 127 0', "indicator color of the actual strafe angle if the angle doesn't match the ideal angle"); // 127 counts as 255?
AUTOCVAR_SAVE(hud_strafehud_alert_color, vector, '255 0 255', "indicator color of the actual strafe angle if the angle has a critical value");
AUTOCVAR_SAVE(hud_strafehud_angle_alpha, float, .8, "indicator transparency of the actual strafe angle");
AUTOCVAR_SAVE(hud_strafehud_direction_color, vector, '0 0 255', "direction indicator color");

bool strafe_fwd = true; // to be removed (see TODO)
float strafe_onground_time = 0;
float strafe_strafekeys_time = 0;
bool strafe_onground = true;
bool strafe_strafekeys = false;
bool strafe_turn = false;
float strafe_turnangle;

// Physics (#15)

vector acc_prevspeed;
float acc_prevtime, acc_avg, top_speed, top_speed_time;
float physics_update_time, discrete_speed, discrete_acceleration;
void HUD_Physics()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_physics) return;
		if(spectatee_status == -1 && (autocvar_hud_panel_physics == 1 || autocvar_hud_panel_physics == 3)) return;
		if(autocvar_hud_panel_physics == 3 && !(ISGAMETYPE(RACE) || ISGAMETYPE(CTS))) return;
	}

	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	if (autocvar_hud_panel_physics_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	float acceleration_progressbar_scale = 0;
	if(autocvar_hud_panel_physics_progressbar && autocvar_hud_panel_physics_acceleration_progressbar_scale > 1)
		acceleration_progressbar_scale = autocvar_hud_panel_physics_acceleration_progressbar_scale;

	float text_scale;
	if (autocvar_hud_panel_physics_text_scale <= 0)
		text_scale = 1;
	else
		text_scale = min(autocvar_hud_panel_physics_text_scale, 1);

	//compute speed
	float speed, conversion_factor = GetSpeedUnitFactor(autocvar_hud_panel_physics_speed_unit);
	string unit = GetSpeedUnit(autocvar_hud_panel_physics_speed_unit);
	vector vel = (csqcplayer ? csqcplayer.velocity : pmove_vel);

	float max_speed = floor( autocvar_hud_panel_physics_speed_max * conversion_factor + 0.5 );
	if (autocvar__hud_configure)
		speed = floor( max_speed * 0.65 + 0.5 );
	else if(autocvar_hud_panel_physics_speed_vertical)
		speed = floor( vlen(vel) * conversion_factor + 0.5 );
	else
		speed = floor( vlen(vel - vel.z * '0 0 1') * conversion_factor + 0.5 );

	//compute acceleration
	float acceleration, f;
	if (autocvar__hud_configure)
		acceleration = autocvar_hud_panel_physics_acceleration_max * 0.3;
	else
	{
		// 1 m/s = 0.0254 qu/s; 1 g = 9.80665 m/s^2
		f = time - acc_prevtime;
		if(autocvar_hud_panel_physics_acceleration_vertical)
			acceleration = (vlen(vel) - vlen(acc_prevspeed));
		else
			acceleration = (vlen(vel - '0 0 1' * vel.z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed.z));

		acceleration = acceleration * (1 / max(0.0001, f)) * (0.0254 / 9.80665);

		acc_prevspeed = vel;
		acc_prevtime = time;

		if(autocvar_hud_panel_physics_acceleration_movingaverage)
		{
			f = bound(0, f * 10, 1);
			acc_avg = acc_avg * (1 - f) + acceleration * f;
			acceleration = acc_avg;
		}
	}

	const int acc_decimals = 2;
	if(time > physics_update_time)
	{
		discrete_acceleration = acceleration;
		// workaround for ftos_decimals returning a negative 0
		if(discrete_acceleration > -1 / (10 ** acc_decimals) && discrete_acceleration < 0)
			discrete_acceleration = 0;
		discrete_speed = speed;
		physics_update_time += autocvar_hud_panel_physics_update_interval;
		if(physics_update_time < time)
			physics_update_time = time + autocvar_hud_panel_physics_update_interval;
	}

	//compute layout
	float panel_ar = panel_size.x/panel_size.y;
	vector speed_offset = '0 0 0', acceleration_offset = '0 0 0';
	if (panel_ar >= 5 && !acceleration_progressbar_scale)
	{
		panel_size.x *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset.x = panel_size.x;
		else
			acceleration_offset.x = panel_size.x;
	}
	else
	{
		panel_size.y *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset.y = panel_size.y;
		else
			acceleration_offset.y = panel_size.y;
	}
	int speed_baralign, acceleration_baralign;
	if (autocvar_hud_panel_physics_baralign == 1)
		acceleration_baralign = speed_baralign = 1;
    else if(autocvar_hud_panel_physics_baralign == 4)
		acceleration_baralign = speed_baralign = 2;
	else if (autocvar_hud_panel_physics_flip)
	{
		acceleration_baralign = (autocvar_hud_panel_physics_baralign == 2);
		speed_baralign = (autocvar_hud_panel_physics_baralign == 3);
	}
	else
	{
		speed_baralign = (autocvar_hud_panel_physics_baralign == 2);
		acceleration_baralign = (autocvar_hud_panel_physics_baralign == 3);
	}
	if (autocvar_hud_panel_physics_acceleration_progressbar_mode == 0)
		acceleration_baralign = 3; //override hud_panel_physics_baralign value for acceleration

	//draw speed
	if(speed)
	if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 2)
		HUD_Panel_DrawProgressBar(panel_pos + speed_offset, panel_size, "progressbar", speed/max_speed, 0, speed_baralign, autocvar_hud_progressbar_speed_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	vector tmp_offset = '0 0 0', tmp_size = '0 0 0';
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 2)
	{
		tmp_size.x = panel_size.x * 0.75;
		tmp_size.y = panel_size.y * text_scale;
		if (speed_baralign)
			tmp_offset.x = panel_size.x - tmp_size.x;
		//else
			//tmp_offset_x = 0;
		tmp_offset.y = (panel_size.y - tmp_size.y) / 2;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(discrete_speed), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

		//draw speed unit
		if (speed_baralign)
			tmp_offset.x = 0;
		else
			tmp_offset.x = tmp_size.x;
		if (autocvar_hud_panel_physics_speed_unit_show)
		{
			//tmp_offset_y = 0;
			tmp_size.x = panel_size.x * (1 - 0.75);
			tmp_size.y = panel_size.y * 0.4 * text_scale;
			tmp_offset.y = (panel_size.y * 0.4 - tmp_size.y) / 2;
			drawstring_aspect(panel_pos + speed_offset + tmp_offset, unit, tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}

	//compute and draw top speed
	if (autocvar_hud_panel_physics_topspeed)
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 2)
	{
		if (autocvar__hud_configure)
		{
			top_speed = floor( max_speed * 0.75 + 0.5 );
			f = 1;
		}
		else
		{
			if (speed >= top_speed)
			{
				top_speed = speed;
				top_speed_time = time;
			}
			if (top_speed != 0)
			{
				f = max(1, autocvar_hud_panel_physics_topspeed_time);
				// divide by f to make it start from 1
				f = cos( ((time - top_speed_time) / f) * PI/2 );
			}
            else //hide top speed 0, it would be stupid
				f = 0;
		}
		if (f > 0)
		{
			//top speed progressbar peak
			if(speed < top_speed)
			if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 2)
			{
				float peak_offsetX;
				vector peak_size = '0 0 0';
				if (speed_baralign == 0)
					peak_offsetX = min(top_speed, max_speed)/max_speed * panel_size.x;
                else if (speed_baralign == 1)
					peak_offsetX = (1 - min(top_speed, max_speed)/max_speed) * panel_size.x;
                else // if (speed_baralign == 2)
                    peak_offsetX = min(top_speed, max_speed)/max_speed * panel_size.x * 0.5;
				peak_size.x = floor(panel_size.x * 0.01 + 1.5);
                peak_size.y = panel_size.y;
                if (speed_baralign == 2) // draw two peaks, on both sides
                {
                    drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size.x + peak_offsetX - peak_size.x), peak_size, autocvar_hud_progressbar_speed_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size.x - peak_offsetX + peak_size.x), peak_size, autocvar_hud_progressbar_speed_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                else
                    drawfill(panel_pos + speed_offset + eX * (peak_offsetX - peak_size.x), peak_size, autocvar_hud_progressbar_speed_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}

			//top speed
			tmp_offset.y = panel_size.y * 0.4;
			tmp_size.x = panel_size.x * (1 - 0.75);
			tmp_size.y = (panel_size.y - tmp_offset.y) * text_scale;
			tmp_offset.y += (panel_size.y - tmp_offset.y - tmp_size.y) / 2;
			drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(top_speed), tmp_size, '1 0 0', f * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		else
			top_speed = 0;
	}

	//draw acceleration
	if(acceleration)
	if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 3)
	{
		vector progressbar_color;
		if(acceleration < 0)
			progressbar_color = autocvar_hud_progressbar_acceleration_neg_color;
		else
			progressbar_color = autocvar_hud_progressbar_acceleration_color;

		f = acceleration/autocvar_hud_panel_physics_acceleration_max;
		if (autocvar_hud_panel_physics_acceleration_progressbar_nonlinear)
			f = (f >= 0 ? sqrt(f) : -sqrt(-f));

		if (acceleration_progressbar_scale) // allow progressbar to go out of panel bounds
		{
			tmp_size = acceleration_progressbar_scale * panel_size.x * eX + panel_size.y * eY;

			if (acceleration_baralign == 1)
				tmp_offset.x = panel_size.x - tmp_size.x;
			else if (acceleration_baralign == 2 || acceleration_baralign == 3)
				tmp_offset.x = (panel_size.x - tmp_size.x) / 2;
			else
				tmp_offset.x = 0;
			tmp_offset.y = 0;
		}
		else
		{
			tmp_size = panel_size;
			tmp_offset = '0 0 0';
		}

		HUD_Panel_DrawProgressBar(panel_pos + acceleration_offset + tmp_offset, tmp_size, "accelbar", f, 0, acceleration_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if(autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 3)
	{
		tmp_size.x = panel_size.x;
		tmp_size.y = panel_size.y * text_scale;
		tmp_offset.x = 0;
		tmp_offset.y = (panel_size.y - tmp_size.y) / 2;

		drawstring_aspect(panel_pos + acceleration_offset + tmp_offset, strcat(ftos_decimals(discrete_acceleration, acc_decimals), "g"), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}

    // TODO: make the angle indicator transparent so that the strafe indicator is still visible even if they overlap
    //       mby useful checks (change HUD mode accordingly): IS_ONSLICK(csqcplayer), IS_JUMP_HELD(csqcplayer), PHYS_TRACK_CANJUMP(csqcplayer), IS_DEAD(csqcplayer), csqcplayer.player_blocked,
    //       !intermission, STAT(FROZEN, this), this.viewloc && !(this.viewloc.spawnflags & VIEWLOC_FREEMOVE), game_stopped, and (csqcplayer.flags & FL_INWATER)
    //       make HUD use pressed keys only in spectating mode while there is no other solution (csqcplayer entity of spectated player?)
    //       make use of KEY_JUMP and KEY_CROUCH
    //       remove strafe_fwd global var and check instead whether the players movement relative to their viewing angle is "backwards"
    //       mark overturn areas when in non-dynamic maxangle mode

    // draw StrafeHUD
    if(autocvar_hud_panel_physics_strafehud == true && csqcplayer)
    {
        vector strafe_indicator_color;
        vector strafe_indicator_size = '0 0 0';
        bool   strafe_indicator_visible = true;
        float  strafe_ups_factor = GetSpeedUnitFactor(1);
        float  strafe_speed = !autocvar__hud_configure ? vlen(vec2(csqcplayer.velocity)) * strafe_ups_factor : 0;
        float  strafe_maxspeed = (IS_ONGROUND(csqcplayer) ? PHYS_MAXSPEED(csqcplayer) : PHYS_MAXAIRSPEED(csqcplayer)) * (IS_DUCKED(csqcplayer) ? .5 : 1); // does IS_DUCKED(csqcplayer) work in spectate? else → KEY_CROUCH
        float  strafe_maxaccel = 0; //IS_ONGROUND(csqcplayer) || PHYS_AIRACCELERATE(csqcplayer) < 0 ? PHYS_ACCELERATE(csqcplayer) : PHYS_AIRACCELERATE(csqcplayer);
        float  strafehud_vel_angle = vectoangles(csqcplayer.velocity).y;
        float  strafehud_view_angle = view_angles.y + 180;
        float  strafe_angle;
        float  strafe_direction;
        //vector strafe_movement = PHYS_CS(csqcplayer).movement;
        //float  strafe_moveangle = strafe_movement_x == 0 ? (strafe_movement_y < 0 ? -90 : strafe_movement_y > 0 ? 90 : 0) : strafe_movement_y == 0 ? 0 : RAD2DEG * atan2(strafe_movement_y, strafe_movement_x);
        int    strafe_keys = STAT(PRESSED_KEYS);
        float  strafe_moveangle = (strafe_keys & KEY_LEFT ? (strafe_keys & KEY_FORWARD ? -45 : (strafe_keys & KEY_BACKWARD ? -135 : -90)) : 0) + (strafe_keys & KEY_RIGHT ? (strafe_keys & KEY_FORWARD ? 45 : (strafe_keys & KEY_BACKWARD ? 135 : 90)) : 0);
        float  strafe_maxangle = autocvar_hud_strafehud_angle == 0 ? 90 - fabs(remainder(strafe_moveangle, 90)) : bound(45, fabs(autocvar_hud_strafehud_angle), 180); //why does fabs() inside remainder() not work?
        float  strafe_indicator_angle = 0;
        float  strafe_indicator_offset;
        float  strafe_good_zone_offset;
        vector strafe_good_zone_size = '0 0 0';
        vector strafe_direction_size_1 = '0 0 0';
        vector strafe_direction_size_2 = '0 0 0';

        //strafe_fwd = strafe_movement_x < 0 ? false : strafe_movement_x > 0 ? true : strafe_fwd;
        strafe_fwd = strafe_keys & KEY_FORWARD ? true : strafe_keys & KEY_BACKWARD ? false : strafe_fwd;
        
        if(IS_ONGROUND(csqcplayer) != strafe_onground)
        {
            strafe_onground_time = time;
        }
        if((fabs(strafe_moveangle) == 90) != strafe_strafekeys)
        {
            strafe_strafekeys_time = time;
        }
        if (!IS_ONGROUND(csqcplayer)) // does this work in spectate? would be nice if IS_ONSLICK(csqcplayer) works too
        {
            if(fabs(strafe_moveangle) == 90)
            {
                strafe_turn = true; // CPM turning
                strafe_turnangle = strafe_moveangle;
            }
            else if((time - strafe_strafekeys_time) > .1)
            {
                strafe_turn = false;
            }
            else if((strafe_keys & KEY_FORWARD) || (strafe_keys & KEY_BACKWARD))
            {
                strafe_turn = false;
            }
        }
        else
        {
            if((time - strafe_onground_time) > .033333)
            {
                strafe_turn = false;
            }
        }
        strafe_strafekeys = fabs(strafe_moveangle) == 90;
        strafe_onground = IS_ONGROUND(csqcplayer);
        if(strafe_turn)
        {
            strafe_maxspeed = PHYS_MAXAIRSTRAFESPEED(csqcplayer) * (IS_DUCKED(csqcplayer) ? .5 : 1);
            strafe_moveangle = strafe_turnangle;
            //strafe_maxaccel = PHYS_AIRSTRAFEACCELERATE(csqcplayer);
        }

        // initialize autovars, should be handled in a seperate file
        if (!autocvar_hud_strafehud_bar_alpha)
            autocvar_hud_strafehud_bar_alpha = 0.4;

        if (!autocvar_hud_strafehud_bar_color)
            autocvar_hud_strafehud_bar_color = '255 255 255';

        if (!autocvar_hud_strafehud_indicator_color)
            autocvar_hud_strafehud_indicator_color = '0 255 0';

        if (!autocvar_hud_strafehud_good_color)
            autocvar_hud_strafehud_good_color = '0 255 255';

        if (!autocvar_hud_strafehud_warning_color)
            autocvar_hud_strafehud_warning_color = strafe_indicator_color = '255 127 0';
        else
            strafe_indicator_color = autocvar_hud_strafehud_warning_color;

        if (!autocvar_hud_strafehud_alert_color)
            autocvar_hud_strafehud_alert_color = '255 0 255';

        // scale the bar of the strafe-o-meter
        panel_pos.x += panel_size.x / 2;
        panel_size.x *= 3;
        panel_pos.x -= panel_size.x / 2;
        panel_pos.y -= panel_size.y * 1.75;

        // add a background to the strafe-o-meter
        HUD_Panel_DrawProgressBar(panel_pos, panel_size, "progressbar", 1, 0, 0, autocvar_hud_strafehud_bar_color, .5 * autocvar_hud_strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);

        // get current strafing angle ranging from -180° to +180°
        if (strafe_speed > 0)
        {
            if (!strafe_fwd)
            {
                strafehud_view_angle += strafehud_view_angle < 0 ? 180 : strafehud_view_angle > 0 ? -180 : 0;
                strafe_moveangle += strafe_moveangle < 0 ? 180 : strafe_moveangle > 0 ? -180 : 0;
            }
            strafe_angle = strafehud_view_angle - strafehud_vel_angle;

            if (strafe_angle > 180)
                strafe_angle = -360 + strafe_angle;
            else if (strafe_angle < -180)
                strafe_angle =  360 + strafe_angle;

            strafe_angle = 180 - strafe_angle;
            if (strafe_angle > 180)
                strafe_angle = -fabs(360 - strafe_angle);

            // making the hud less affected by rounding errors
            if (strafe_angle > 179.9 || strafe_angle < -179.9)
            {
                strafe_indicator_color = autocvar_hud_strafehud_alert_color;
                strafe_angle = 0;
            }
            if (strafe_angle < .1 && strafe_angle > -.1)
            {
                strafe_angle = 0;
            }
        }
        else
            strafe_angle = 0;

        strafe_direction = (strafe_angle + strafe_moveangle) > 0 ? 1 : (strafe_angle + strafe_moveangle) < 0 ? -1 : 0;
        if((strafe_direction == 0) && (strafe_moveangle != 0))
        {
            strafe_direction = 1; // noone will notice
        }

        // draw ideal strafe angle indicator
        if(strafe_speed > (strafe_maxspeed + .1)) // do not make it appear unless you move strafe-y
        {
            strafe_indicator_size.x = floor(panel_size.x * .01 + .5);
            strafe_indicator_size.y = floor(panel_size.y + .5);
            if (strafe_direction != 0)
            {
                if(!strafe_turn)
                {
                    strafe_indicator_angle = acos((strafe_maxspeed - strafe_maxaccel) / strafe_speed) * RAD2DEG * strafe_direction - strafe_moveangle;
                }
                else
                {
                    strafe_indicator_angle = acos((strafe_maxspeed - strafe_maxaccel) / strafe_speed) * RAD2DEG * strafe_direction - strafe_moveangle;
                }
                if (fabs(strafe_indicator_angle) <= strafe_maxangle)
                {
                    strafe_indicator_offset = floor(strafe_indicator_angle/strafe_maxangle * panel_size.x/2 + panel_size.x/2 + .5);
                    strafe_good_zone_size.y = panel_size.y;
                    if(fabs(strafe_moveangle) < 89.9)
                    {
                        strafe_good_zone_offset = strafe_direction < 0 ? 0 : strafe_indicator_offset + strafe_indicator_size.x;
                        strafe_good_zone_size.x = strafe_direction < 0 ? strafe_indicator_offset : panel_size.x - strafe_good_zone_offset;
                    }
                    else
                    {
                        vector strafe_overturn_area = panel_size;
                        strafe_overturn_area.x = floor(strafe_overturn_area.x / 2 + .5);
                        strafe_good_zone_offset = strafe_direction < 0 ? panel_size.x / 2 : strafe_indicator_offset + strafe_indicator_size.x;
                        strafe_good_zone_size.x = strafe_direction < 0 ? strafe_indicator_offset - panel_size.x / 2 : panel_size.x / 2 - strafe_good_zone_offset;
                        HUD_Panel_DrawProgressBar(panel_pos + eX * (strafe_direction < 0 ? 0 : strafe_overturn_area.x), strafe_overturn_area, "progressbar", 1, 0, 0, autocvar_hud_strafehud_alert_color, .5 * autocvar_hud_strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    }
                    HUD_Panel_DrawProgressBar(panel_pos + eX * strafe_good_zone_offset, strafe_good_zone_size, "progressbar", 1, 0, 0, autocvar_hud_strafehud_indicator_color, .5 * autocvar_hud_strafehud_bar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    strafe_indicator_offset = floor(-strafe_indicator_angle/strafe_maxangle * panel_size.x/2 + panel_size.x/2 + .5);
                    drawfill(panel_pos + eX * (strafe_indicator_offset - (-strafe_direction < 0 ? strafe_indicator_size.x : 0)), strafe_indicator_size, autocvar_hud_strafehud_indicator_switch_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    strafe_indicator_offset = floor(strafe_indicator_angle/strafe_maxangle * panel_size.x/2 + panel_size.x/2 + .5);
                    drawfill(panel_pos + eX * (strafe_indicator_offset - (strafe_direction < 0 ? strafe_indicator_size.x : 0)), strafe_indicator_size, autocvar_hud_strafehud_indicator_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                strafe_direction_size_1.x = floor(panel_size.x * .0075 + .5);
                strafe_direction_size_1.y = panel_size.y;
                strafe_direction_size_2.x = floor(strafe_direction_size_1.x * 3 + .5);
                strafe_direction_size_2.y = strafe_direction_size_1.x;
                drawfill(panel_pos + eX * (strafe_direction < 0 ? -strafe_direction_size_1.x : panel_size.x), strafe_direction_size_1, autocvar_hud_strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                drawfill(panel_pos + eX * (strafe_direction < 0 ? -strafe_direction_size_1.x : panel_size.x - strafe_direction_size_2.x + strafe_direction_size_1.x) - eY * strafe_direction_size_2.y, strafe_direction_size_2, autocvar_hud_strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                drawfill(panel_pos + eX * (strafe_direction < 0 ? -strafe_direction_size_1.x : panel_size.x - strafe_direction_size_2.x + strafe_direction_size_1.x) + eY * panel_size.y, strafe_direction_size_2, autocvar_hud_strafehud_direction_color, panel_fg_alpha, DRAWFLAG_NORMAL);
            }
            else
            {
                strafe_indicator_angle = acos((strafe_maxspeed - strafe_maxaccel) / strafe_speed) * RAD2DEG;
                if (fabs(strafe_indicator_angle) <= strafe_maxangle)
                {
                    strafe_indicator_offset = floor(-strafe_indicator_angle/strafe_maxangle * panel_size.x/2 + panel_size.x/2 + .5);
                    drawfill(panel_pos + eX * (strafe_indicator_offset - strafe_indicator_size.x), strafe_indicator_size, autocvar_hud_strafehud_indicator_switch_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                    strafe_indicator_offset = floor(strafe_indicator_angle/strafe_maxangle * panel_size.x/2 + panel_size.x/2 + .5);
                    drawfill(panel_pos + eX * (strafe_indicator_offset), strafe_indicator_size, autocvar_hud_strafehud_indicator_switch_color, panel_fg_alpha, DRAWFLAG_NORMAL);
                }
            }
        }
        else
        {
            strafe_indicator_visible = false;
        }

        // draw actual strafe angle
        if (strafe_indicator_visible)
        {
            if ((strafe_direction > 0 && strafe_angle >= strafe_indicator_angle) ||
                (strafe_direction < 0 && strafe_angle <= strafe_indicator_angle))
            strafe_indicator_color = autocvar_hud_strafehud_good_color;
        }

        if (fabs(strafe_angle + strafe_moveangle) > 89.9) // avoid inconsistencies due to rounding errors (while walking only, may remove later)
        {
            strafe_indicator_color = autocvar_hud_strafehud_alert_color;
        }

        if (strafe_speed <= (strafe_maxspeed + .1) && strafe_indicator_color != autocvar_hud_strafehud_alert_color)
            strafe_indicator_color = autocvar_hud_strafehud_good_color;

        strafe_indicator_offset = floor(bound(-strafe_maxangle, strafe_angle, strafe_maxangle)/strafe_maxangle * panel_size.x/2 + panel_size.x/2 + .5);

        strafe_indicator_size.x = floor(panel_size.x * .005 + .5);
        strafe_indicator_size.y = floor(panel_size.y * 1.5 + .5);
        drawfill(panel_pos - '0 1 0'*floor(panel_size.y * .25 + .5) + eX * (strafe_indicator_offset - strafe_indicator_size.x/2), strafe_indicator_size, strafe_indicator_color, autocvar_hud_strafehud_angle_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);

        // cleanup, only needed if other hud items follow which do not break the size limitation
        /*panel_pos.y += panel_size.y * 1.75;
        panel_pos.x += panel_size.x / 2;
        panel_size.x /= 3;
        panel_pos.x -= panel_size.x / 2;*/
    }
	draw_endBoldFont();
}
