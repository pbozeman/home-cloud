import appdaemon.plugins.hass.hassapi as hass  # type: ignore

import appdaemon.plugins.hass.hassapi as hass


class TvTimeButton(hass.Hass):
    def initialize(self):
        self.log("init")
        self.listen_event(self.button_event, "lutron_caseta_button_event")

    def button_event(self, event_name, data, kwargs):
        self.log(f"Lutron button event received: {data}")

        if data.get("area_name") != "Living Room":
            return

        if data.get("device_name") != "Pico":
            return

        if data.get("action") != "press":
            return

        button = data.get("button_number")
        if button == 2:
            self.on()
        elif button == 4:
            self.off()
        elif button == 5:
            self.up()
        elif button == 6:
            self.down()
        elif button == 3:
            self.center()

    def on(self):
        self.log("on")

    def off(self):
        self.log("off")

    def up(self):
        self.log("up")

    def down(self):
        self.log("down")

    def center(self):
        self.log("center")
        self.call_service(
            "input_boolean/toggle", entity_id="input_boolean.tv_time_mode"
        )

    def log(self, str):
        super().log(f"TvTimeButton {str}")
