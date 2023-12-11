import appdaemon.plugins.hass.hassapi as hass  # type: ignore


class MotionLight(hass.Hass):
    def initialize(self):
        # mandatory settings
        self.entity = self.args.get("entity", None)
        self.sensors = self.args.get("sensors", [])

        # optional day/night mode settings.
        #
        # entity is the thing that will get checked to see if is on. It is what
        # will get turned off.  It is expected to be a light or group.
        #
        # The day mode entity is the thing that will get "turned on." i.e.
        # if "entity" is "off" the day mode entity will be turned on.  This
        # allows it to be a scene, yet still check to see if one or more of the
        # lights it turns on are already on.
        #
        # The night_mode_entity works the same way.
        # Night entity defaults to None since the norm is to not turn on any
        # lights.
        self.day_mode_entity = self.args.get("day_mode_entity", self.entity)
        self.night_mode_entity = self.args.get("night_mode_entity", None)
        self.night_mode_boolean = self.args.get(
            "night_mode_boolean", "input_boolean.goodnight_mode"
        )

        # misc settings
        self.blocker = self.args.get("blocker", None)
        self.motion_off_delay_sec = self.args.get("delay_sec", 300)
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
        self.log_state("motion_recent")

        if self.is_blocked():
            return

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
        self.log_state("entity_on")

        if self.is_blocked():
            return

        # kick off the timer when manually turned on too
        self.set_off_timer()

    def is_blocked(self):
        if not self.blocker:
            return False

        return self.get_state(self.blocker) == "on"

    def need_illumination(self):
        return self.sun_down()

    def is_night_mode(self):
        return self.get_state(self.night_mode_boolean) == "on"

    def entity_to_turn_on(self):
        if self.is_night_mode():
            return self.night_mode_entity
        else:
            return self.day_mode_entity

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

    def log_state(self, str):
        return self.log(
            str
            + f" state: '{self.get_state(self.entity)}'"
            + f" is_blocked: '{self.is_blocked()}'"
            + f" need_illumination: '{self.need_illumination()}'"
            + f" turn_on_enabled: '{self.turn_on_enabled}'"
            + f" is_night_mode: '{self.is_night_mode()}'"
            + f" entity_to_turn_on: '{self.entity_to_turn_on()}'"
        )
