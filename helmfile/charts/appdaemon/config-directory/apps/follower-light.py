import appdaemon.plugins.hass.hassapi as hass  # type: ignore


class FollowerLight(hass.Hass):
    def initialize(self):
        self.leader = self.args.get("leader", None)
        self.follower = self.args.get("follower", None)

        if not self.leader:
            self.log("no leader specified")
            return

        if not self.follower:
            self.log("no follower specified")
            return

        self.ignore_on = self.args.get("ignore_on", False)
        self.ignore_off = self.args.get("ignore_off", False)

        self.listen_state(self.leader_turned_on, self.leader, new="on")
        self.listen_state(self.leader_turned_off, self.leader, new="off")

    def leader_turned_on(self, entity, attribute, old, new, kwargs):
        self.log(f"leader_turned_on ignore_on: {self.ignore_on}")
        if not self.ignore_on:
            self.turn_on(self.follower)

    def leader_turned_off(self, entity, attribute, old, new, kwargs):
        self.log(f"leader_turned_off ignore_off: {self.ignore_off}")
        if not self.ignore_off:
            self.turn_off(self.follower)

    def log(self, str):
        super().log(f"FollowerLight {self.leader} -> {self.follower} {str}")
