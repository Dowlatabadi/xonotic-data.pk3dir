#ifdef INTERFACE
CLASS(XonoticAudioSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticAudioSettingsTab, fill, void(entity))
	ATTRIB(XonoticAudioSettingsTab, title, string, _("Audio"))
	ATTRIB(XonoticAudioSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticAudioSettingsTab, rows, float, 17)
	ATTRIB(XonoticAudioSettingsTab, columns, float, 6.5)
ENDCLASS(XonoticAudioSettingsTab)
entity makeXonoticAudioSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticAudioSettingsTab()
{
	entity me;
	me = spawnXonoticAudioSettingsTab();
	me.configureDialog(me);
	return me;
}

void XonoticAudioSettingsTab_fill(entity me)
{
	entity e, s, sl;

	me.TR(me);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "mastervolume");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Master:")));
		me.TD(me, 1, 2, s);
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "bgmvolume");
		makeMulti(s, "snd_csqcchannel2volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Music:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_staticvolume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Ambient:")));
		makeMulti(s, "snd_entchannel2volume");
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_worldchannel0volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Info:")));
		makeMulti(s, "snd_csqcchannel0volume");
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_entchannel3volume");
		makeMulti(s, "snd_playerchannel0volume snd_playerchannel3volume snd_csqcchannel3volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Items:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_playerchannel6volume");
		makeMulti(s, "snd_csqcchannel6volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Pain:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_playerchannel7volume");
		makeMulti(s, "snd_entchannel7volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Player:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_entchannel4volume");
		makeMulti(s, "snd_playerchannel4volume snd_entchannel6volume snd_csqcchannel4volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Shots:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_playerchannel2volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Voice:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider(-20, 0, 0.5, "snd_playerchannel1volume");
		makeMulti(s, "snd_playerchannel5volume snd_entchannel1volume snd_entchannel5volume");
		me.TD(me, 1, 0.8, e = makeXonoticSliderCheckBox(-1000000, 1, s, _("Weapons:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Frequency:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("snd_speed"));
			e.addValue(e, _("8 kHz"), "8000");
			e.addValue(e, _("11.025 kHz"), "11025");
			e.addValue(e, _("16 kHz"), "16000");
			e.addValue(e, _("22.05 kHz"), "22050");
			e.addValue(e, _("24 kHz"), "24000");
			e.addValue(e, _("32 kHz"), "32000");
			e.addValue(e, _("44.1 kHz"), "44100");
			e.addValue(e, _("48 kHz"), "48000");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Channels:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("snd_channels"));
			e.addValue(e, _("Mono"), "1");
			e.addValue(e, _("Stereo"), "2");
			e.addValue(e, _("2.1"), "3");
			e.addValue(e, _("4"), "4");
			e.addValue(e, _("5"), "5");
			e.addValue(e, _("5.1"), "6");
			e.addValue(e, _("6.1"), "7");
			e.addValue(e, _("7.1"), "8");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "snd_swapstereo", _("Swap Stereo")));
		setDependent(e, "snd_channels", 1.5, 0.5);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "snd_spatialization_control", _("Headphone friendly mode")));
		setDependent(e, "snd_channels", 1.5, 0.5);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Spatial voices:")));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(1, "cl_voice_directional", "0", ZCTX(_("VOICES^None"))));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(1, "cl_voice_directional", "2", ZCTX(_("VOICES^Taunts"))));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(1, "cl_voice_directional", "1", ZCTX(_("VOICES^All"))));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Taunt range:")));
		setDependent(e, "cl_voice_directional", 0.5, -0.5);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_voice_directional_taunt_attenuation"));
			e.addValue(e, ZCTX(_("RANGE^Very short")), "3");
			e.addValue(e, ZCTX(_("RANGE^Short")), "2");
			e.addValue(e, ZCTX(_("RANGE^Normal")), "0.5");
			e.addValue(e, ZCTX(_("RANGE^Long")), "0.25");
			e.addValue(e, ZCTX(_("RANGE^Full")), "0.015625");
			e.configureXonoticTextSliderValues(e);
		setDependent(e, "cl_voice_directional", 0.5, -0.5);
	me.TR(me);
		sl = makeXonoticSlider(0.15, 1, 0.05, "cl_autotaunt");
			sl.valueDisplayMultiplier = 100;
			sl.valueDigits = 0;
		me.TD(me, 1, 3, e = makeXonoticSliderCheckBox(0, 1, sl, _("Automatic taunts")));
		if(sl.value != e.savedValue)
			e.savedValue = 0.65; // default
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Frequency:")));
		me.TD(me, 1, 2, sl);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Time warning:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_sound_maptime_warning"));
			e.addValue(e, ZCTX(_("WARNING^None")), "0");
			e.addValue(e, _("1 minute"), "1");
			e.addValue(e, _("5 minutes"), "2");
			e.addValue(e, ZCTX(_("WARNING^Both")), "3");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_hitsound", _("Hit indicator")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 0, "menu_sounds", _("Menu sounds")));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "snd_restart; sendcvar cl_hitsound; sendcvar cl_autotaunt; sendcvar cl_voice_directional; sendcvar cl_voice_directional_taunt_attenuation", COMMANDBUTTON_APPLY));
}
#endif
