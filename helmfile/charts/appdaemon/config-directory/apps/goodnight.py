import appdaemon.plugins.hass.hassapi as hass
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

        # and check if we need to turn it on now, possibly because
        # we were down and will miss the alarm
        now = self.datetime()

        self.log(f"goodnight now: {now} ttr: {time_to_run} sunrise: {self.sunrise()}")

        if now.time() > time_to_run or now < self.sunrise():
            self.log("goodnight mode ON during init")
            self.call_service(
                "input_boolean/turn_on", entity_id="input_boolean.goodnight_mode"
            )

        # turn off goodnight mode at sunrise
        self.run_at_sunrise(self.wakeup)

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
