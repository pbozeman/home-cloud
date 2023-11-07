# home-network

This repo contains a declarative configuration for my home network. It is designed
around the following requirements:

## Security Requirements

I have the following actors and associated threats in my home network:

- **Iot Devices:** I want some, but not all, of these to have internet access. I consider them to be actively hostile. They should not be able to initiate communication with more trusted devices. An example of a device I want to allow internet access is a scale. While I generally believe in full local control of devices, I do not see the value in building my own local weight tracking system. An example of a device that I do not want to have internet access is my TV. I want it to be as dumb as possible and do not want upsells or ads from the manufacturer of my TV.

- **Guests:** I live in a remote area without cellular access. I need to provide internet access for guests to be able to communicate, including WiFi based calling, otherwise, they are completely cut off while on my property. Some guests are friends, others, like employees of contractors, I may not know at all. These folks should have internet access, but nothing else.

- **Kids:** These are similar to guests in terms of a threat model in that I assume their machines will end up with malware. They need to be isolated from the rest of the network. In addition, as they are still young, I want to make sure they don't stumble into age inappropriate content online. I also want to be able to control their online screen time when at home.

- **Trusted devices:** Phones, laptops, etc for adult family members and close friends. There are no restrictions on these devices. They should be able to Airplay/Chromecast to lesser trusted media players.

For both guests and IoT devices, I'm assuming a low level of sophistication of attack. For example, VLAN isolation plus selective internet connectivity based on IP address is fine, even though a device that should not have internet access could spoof the IP of another device that does. Such a device can't access the more secure networks, so they shouldn't have any meaningful data to exfiltrate and this level of security is sufficient to prevent lower level threats such as unwanted ads and updates from my TV manufacturer.

TODO: terraform howto and network write-up.
