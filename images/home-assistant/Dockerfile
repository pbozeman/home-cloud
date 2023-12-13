FROM homeassistant/home-assistant:2023.12

COPY injected /injected

RUN chmod +x /injected/wrapper-script.sh

ENTRYPOINT ["/injected/wrapper-script.sh"]
