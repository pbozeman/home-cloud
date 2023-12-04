import appdaemon.plugins.hass.hassapi as hass  # type: ignore


class MotionLight(hass.Hass):
    def initialize(self):
        self.light = self.args.get("light", None)
        self.sensors = self.args.get("sensors", [])
        self.motion_off_delay_sec = self.args.get("delay_sec", 5)

        if not self.light:
            self.log("no light specified")
            return

        if not self.sensors:
            self.log("no sensors specified")
            return

        self.log("init")

        self.run_in_handle = None
        self.disabled = False

        # if we restart while the light is on, we still want the
        # to turn it off on no motion
        if self.get_state(self.light) == "on" and not self.disabled:
            self.set_off_timer()

        self.listen_state(self.motion_recent, self.sensors, new="on")
        self.listen_state(self.light_on, self.light, new="on")

    def motion_recent(self, entity, attribute, old, new, kwargs):
        self.log("motion_recent")

        if self.disabled:
            self.log("disabled")
            return

        # we do this before the illumination check, because we always
        # want to be refreshing the timer and turing off the light in case
        # it got turned on manually
        self.set_off_timer()

        if self.need_illumination() == False:
            self.log("illumination not needed")
            return

        # if this is a group, specific lights might already be manually
        # set. do not turn them all on.
        if self.get_state(self.light) == "on":
            self.log("already on")
            return

        self.log(f"turn on {self.light}")
        self.turn_on(self.light)

    def light_on(self, entity, attribute, old, new, kwargs):
        self.log("light_on")

        if self.disabled:
            self.log("disabled")
            return

        self.log("light_on")
        self.set_off_timer()

    def need_illumination(self):
        return self.sun_up()

    def set_off_timer(self):
        self.log("set_off_timer")

        if self.run_in_handle:
            self.log("cancel timer")
            self.cancel_timer(self.run_in_handle)
            self.run_in_hanlde = None

        self.log(f"turn off in {self.motion_off_delay_sec}s")
        self.run_in_handle = self.run_in(self.turn_off_light, self.motion_off_delay_sec)

    def turn_off_light(self, kwargs):
        self.log("turn_off_light")
        self.run_in_handle = None
        self.turn_off(self.light)

    def enable(self):
        self.disabled = False

    def disable(self):
        self.disabled = True

    def log(self, str):
        super().log(f"MotionLight {self.light} {str}")
