import appdaemon.plugins.hass.hassapi as hass  # type: ignore
import datetime


class Goodnight(hass.Hass):
    def initialize(self):
        default_time_str = "22:30"

        # Read the time from the app configuration or use default
        time_str = self.args.get("time", default_time_str)
        hour, minute = map(int, time_str.split(":"))

        # set goodnight mode every day at the specified time
        time_to_run = datetime.time(hour, minute)
        self.run_daily(self.goodnight, time_to_run)

        # turn off goodnight mode at sunrise
        self.run_at_sunrise(self.wakeup)

        # if we were offline when we should have transitioned, it will be
        # in the wrong state. explicitly set it now.
        now_time = self.datetime().time()
        sunrise_time = self.sunrise().time()

        self.log(
            f"goodnight now: {now_time} "
            + f"time_to_run: {time_to_run} "
            + f"sunrise: {sunrise_time}"
        )

        if now_time > time_to_run or now_time < sunrise_time:
            self.log("goodnight mode ON during init")
            self.call_service(
                "input_boolean/turn_on", entity_id="input_boolean.goodnight_mode"
            )
        else:
            self.log("goodnight mode OFF during init")
            self.call_service(
                "input_boolean/turn_off", entity_id="input_boolean.goodnight_mode"
            )

    def goodnight(self, kwargs):
        self.log("goodnight mode ON")
        self.call_service(
            "input_boolean/turn_on", entity_id="input_boolean.goodnight_mode"
        )

    def wakeup(self, kwargs):
        self.log("goodnight mode OFF")
        self.call_service(
            "input_boolean/turn_off", entity_id="input_boolean.goodnight_mode"
        )
