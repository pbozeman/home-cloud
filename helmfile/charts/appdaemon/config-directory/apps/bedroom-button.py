import appdaemon.plugins.hass.hassapi as hass  # type: ignore

import appdaemon.plugins.hass.hassapi as hass


class BedroomButton(hass.Hass):
    def initialize(self):
        self.log("init")
        self.listen_event(self.button_event, "lutron_caseta_button_event")

    def button_event(self, event_name, data, kwargs):
        self.log(f"Lutron button event received: {data}")

        if data.get("area_name") != "Main Bedroom":
            return

        if data.get("device_name") != "Pico":
            return

        if data.get("action") != "press":
            return

        button = data.get("leap_button_number")
        if button == 0:
            self.on()
        elif button == 2:
            self.off()

    def on(self):
        self.log("on")
        self.turn_on("scene.goodnight")

    def off(self):
        self.log("off")

    def up(self):
        self.log("up")

    def down(self):
        self.log("down")

    def log(self, str):
        super().log(f"BedroomButton {str}")
