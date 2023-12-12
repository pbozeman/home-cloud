import appdaemon.plugins.hass.hassapi as hass  # type: ignore


class TvTime(hass.Hass):
    def initialize(self):
        self.log("init")

        # mandatory settings
        self.scene_playing = self.args.get("scene_playing", None)
        self.scene_paused = self.args.get("scene_paused", None)
        self.media_players = self.args.get("media_players", [])

        # optional
        self.tv_time_mode = self.args.get("tv_time_mode", "input_boolean.tv_time_mode")

        self.listen_state(self.paused, self.media_players, new="paused")
        self.listen_state(self.playing, self.media_players, new="playing")
        self.listen_state(self.off, self.media_players, new="off")

    def paused(self, entity, attribute, old, new, kwargs):
        self.log("paused")
        if not self.is_tv_time():
            return
        self.turn_on(self.scene_paused)

    def playing(self, entity, attribute, old, new, kwargs):
        self.log("playing")
        if not self.is_tv_time():
            return
        self.turn_on(self.scene_playing)

    def off(self, entity, attribute, old, new, kwargs):
        self.log("off")
        self.call_service("input_boolean/turn_off", entity_id=self.tv_time_mode)

    def is_tv_time(self):
        return self.get_state(self.tv_time_mode) == "on"

    def log(self, str):
        super().log(f"TvTime {str}")
