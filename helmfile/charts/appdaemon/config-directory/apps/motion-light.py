import appdaemon.plugins.hass.hassapi as hass  # type: ignore


class MotionLight(hass.Hass):
    def initialize(self):
        # mandatory settings
        self.entity = self.args.get("entity", None)
        self.sensors = self.args.get("sensors", [])

        # optional night mode settings.
        # it is assumed, but not checked, that the night mode entity
        # is a subset of entity. (or a scene that also truns on some subset
        # of entity).
        #
        # It is the entity that will be checked for "on" and will be turned
        # off, even during night mode.  night_mode_entity will be the one turned
        # on.
        self.night_mode_boolean = self.args.get(
            "night_mode_boolean", "input_boolean.goodnight_mode"
        )
        self.night_mode_entity = self.args.get("night_mode_entity", None)

        # misc settings
        self.motion_off_delay_sec = self.args.get("delay_sec", 5)
        self.turn_on_enabled = self.args.get("turn_on", True)
        self.turn_off_enabled = self.args.get("turn_off", True)

        # state
        self.run_in_handle = None

        if not self.entity:
            self.log("no entity specified")
            return

        if not self.sensors:
            self.log("no sensors specified")
            return

        self.log("init")

        # if we restart while the light is on, we still want the
        # to turn it off on no motion
        if self.get_state(self.entity) == "on":
            self.set_off_timer()

        self.listen_state(self.motion_recent, self.sensors, new="on")
        self.listen_state(self.entity_on, self.entity, new="on")

    def motion_recent(self, entity, attribute, old, new, kwargs):
        self.log(
            "motion_recent"
            + f" state: {self.get_state(self.entity)}"
            + f" need_illumination: {self.need_illumination()}"
            + f" turn_on_enabled: {self.turn_on_enabled}"
            + f" entity_to_turn_on: {self.entity_to_turn_on()}"
        )

        # we do this before the illumination and turn_on_enabled checks,
        # because regardless of their policy, we want to (potentially)
        # turn off the light after a lack of motion
        self.set_off_timer()

        # if this is a group, specific lights might already be manually
        # set. do not turn them all on.
        if (
            self.get_state(self.entity) == "on"
            or self.need_illumination() == False
            or self.turn_on_enabled == False
        ):
            return

        entity = self.entity_to_turn_on()
        if entity:
            self.turn_on(entity)

    def entity_on(self, entity, attribute, old, new, kwargs):
        # kick off the timer when manually turned on too
        self.log("entity_on")
        self.set_off_timer()

    def need_illumination(self):
        return self.sun_up()

    def entity_to_turn_on(self):
        if not self.get_state(self.night_mode_boolean):
            return self.entity

        if self.night_mode_entity:
            return self.night_mode_entity

        return self.entity

    def set_off_timer(self):
        self.log("set_off_timer")

        if self.run_in_handle:
            self.log("cancel timer")
            self.cancel_timer(self.run_in_handle)

        self.log(f"turn off in {self.motion_off_delay_sec}s")
        self.run_in_handle = self.run_in(self.turn_off_light, self.motion_off_delay_sec)

    def turn_off_light(self, kwargs):
        self.log("turn_off_light")
        self.run_in_handle = None

        if not self.turn_off_enabled:
            self.log("turn_off false")
            return

        self.turn_off(self.entity)

    def log(self, str):
        super().log(f"MotionLight {self.entity} {str}")
