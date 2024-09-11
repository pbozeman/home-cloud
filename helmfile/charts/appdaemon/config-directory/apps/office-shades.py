import appdaemon.plugins.hass.hassapi as hass  # type: ignore

import appdaemon.plugins.hass.hassapi as hass


class OfficeShades(hass.Hass):
    def initialize(self):
        self.button = self.args.get("button", None)
        self.shades = self.args.get("shades", [])

        if not self.button:
            self.log("no button specified")
            return

        if not self.shades:
            self.log("no shades specified")
            return

        self.log("init")

        self.listen_state(self.button_open, self.button, new="open")
        self.listen_state(self.button_close, self.button, new="close")

    def button_open(self, entity, attribute, old, new, kwargs):
        self.log(f"button open")

        for shade in self.shades:
            self.call_service("cover/open_cover", entity_id=shade)
            self.log(f"opened {shade}")

    def button_close(self, entity, attribute, old, new, kwargs):
        self.log(f"button close")

        for shade in self.shades:
            self.call_service("cover/close_cover", entity_id=shade)
            self.log(f"closed {shade}")

    def log(self, str):
        super().log(f"OfficeShades {str}")
