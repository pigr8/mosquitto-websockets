Mosquitto + Websockets
================
Mosquitto MQTT v1.6.9 on ultra light Alpine container, with WebSockets v2.4.2 support.

    $ sudo docker run -d \
      --v /data/path:/etc/mosquitto \
      --name mqtt \
      -p 1883:1883 \
      -p 9001:9001 \
      pigr8/mosquitto-websockets

By default the password file is empty, you have to create a user and password for authentication (hashed). To do so after creation of the container start it and run:

    $ sudo docker exec -it mqtt mosquitto_passwd -b /etc/mosquitto/passwd username password

Restart the container and you will be able to authenticate with user and password of choice.

## Credits

Mostly based on jllopis work here on github!
