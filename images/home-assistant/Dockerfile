FROM homeassistant/home-assistant:stable

COPY injected /injected

RUN chmod +x /injected/wrapper-script.sh

ENTRYPOINT ["/injected/wrapper-script.sh"]
