# TODO: At the time I did this, I didn't knob about the capabilities 
# of ConfigMaps. Go back and config HA via configmaps in the helm
# chart and remove this custom docker image.
FROM homeassistant/home-assistant:stable

COPY injected /injected

RUN chmod +x /injected/wrapper-script.sh

ENTRYPOINT ["/injected/wrapper-script.sh"]
