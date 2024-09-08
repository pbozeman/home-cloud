FROM homeassistant/home-assistant:2024.9

COPY injected /injected

RUN chmod +x /injected/wrapper-script.sh

ENTRYPOINT ["/injected/wrapper-script.sh"]
