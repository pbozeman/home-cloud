import appdaemon.plugins.hass.hassapi as hass  # type: ignore


class LightGroupAll(hass.Hass):
    def initialize(self):
        all_lights = self.get_state("light")
        light_entities = [entity for entity in all_lights.keys()]
        self.create_light_group("lights_all", "All Lights", light_entities)

    def create_light_group(self, group_name, friendly_name, entities):
        self.call_service(
            "group/set", object_id=group_name, name=friendly_name, entities=entities
        )
