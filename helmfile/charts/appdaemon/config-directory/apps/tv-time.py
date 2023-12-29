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
        self.listen_state(self.on, self.media_players, new="on")
        self.listen_state(self.tv_time_on, self.tv_time_mode, new="on")
        self.listen_state(self.tv_time_off, self.tv_time_mode, new="off")

    def paused(self, entity, attribute, old, new, kwargs):
        self.log("paused")
        if self.is_tv_time():
            self.turn_on(self.scene_paused)

    def playing(self, entity, attribute, old, new, kwargs):
        self.log("playing")
        if self.is_tv_time():
            self.turn_on(self.scene_playing)

    def off(self, entity, attribute, old, new, kwargs):
        self.log("off")
        self.call_service("input_boolean/turn_off", entity_id=self.tv_time_mode)

    def on(self, entity, attribute, old, new, kwargs):
        self.log("on")
        if not self.too_early():
            self.call_service("input_boolean/turn_on", entity_id=self.tv_time_mode)

    def tv_time_on(self, entity, attribute, old, new, kwargs):
        message = "TV Time ON"
        self.call_service("notify/lg_tv", message=message)

    def tv_time_off(self, entity, attribute, old, new, kwargs):
        message = "TV Time OFF"
        self.call_service("notify/lg_tv", message=message)

    def is_tv_time(self):
        return self.get_state(self.tv_time_mode) == "on"

    def too_early(self):
        return self.get_now().hour < 21

    def log(self, str):
        super().log(f"TvTime {str}")
