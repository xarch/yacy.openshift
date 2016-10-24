# Use the latest version of OpenJDK on
# a Debian based distro.
FROM openjdk:latest

# Trace the version of OpenJDK in use.
RUN java -version

# Use "/opt" as a working directory.
WORKDIR /opt

# This part is based on the official Docker image:
# - Install "ant" and "git";
# - Clone YaCy git repository;
# - Compile it with "ant";
# - Remove space consuming ".git" directory;
# - Remove both "ant" and "git".
RUN apt-get update && \
	apt-get install -yq ant git && \
	git clone https://github.com/yacy/yacy_search_server.git yacy && \
	ant compile -f /opt/yacy/build.xml && \
	rm -rf /opt/yacy/.git && \
	apt-get purge -yq --auto-remove ant git && \
	apt-get clean

# Use value of $YACY_INIT_USER environment variable as initial username
# and value of $YACY_INIT_PASS as initial password. Expected format of the
# password is "MD5:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx".
RUN sed -i "/adminAccountBase64MD5=/c\${YACY_INIT_USER}AccountBase64MD5=${YACY_INIT_PASS}" \
	/opt/yacy/defaults/yacy.init

# Enable HTTPS by default.
RUN sed -i "/server.https=false/c\server.https=true" \
	/opt/yacy/defaults/yacy.init

# Set ownership of the YaCy directory to the current user and group.
RUN chown `id -u`:`id -g` -R /opt/yacy

# Expose default ports.
EXPOSE 8090 8443

# Set data volume so YaCy data will persist after
# container destruction / restart.
VOLUME ["/opt/yacy/DATA"]

# Run YaCy as a current user.
USER `id -u`

# Start YaCy. Use "-d" flag for debug mode.
CMD sh /opt/yacy/startYACY.sh -d
