# Use the base image of CentOS for OpenShift.
FROM openshift/base-centos7

# Use "/opt" as a working directory.
WORKDIR /opt

# Install Ant, Git, and OpenJDK, clone the YaCy repo, and build the project.
# Remove unneeded components at the end.
RUN yum install -y --enablerepo=centosplus \
	ant git java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
	git clone https://github.com/yacy/yacy_search_server.git yacy && \
	ant compile -f /opt/yacy/build.xml && \
	rm -rf /opt/yacy/.git && \
	yum autoremove -y ant git && \
	yum clean all -y

# Set default user and password to "admin" and "docker".
# This is against OpenShift guidelines, however, there is no other easy way
# to set these data. Custom hashing algorithm is used by YaCy, so user will have hard
# time coming up with their own credentials anyway. Though we still allow them to
# redefine it if they are capable of doing that.
RUN if [ $YACY_INIT_USER == "" ]; then export $YACY_INIT_USER="admin"; fi
RUN if [ $YACY_INIT_PASS == "" ]; then export $YACY_INIT_PASS="MD5:e672161ffdce91be4678605f4f4e6786"; fi

# Use value of $YACY_INIT_USER environment variable as initial username
# and value of $YACY_INIT_PASS as initial password. Expected format of the
# password is "MD5:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx".
RUN sed -i "/adminAccountBase64MD5=/c\${YACY_INIT_USER}AccountBase64MD5=${YACY_INIT_PASS}" \
	/opt/yacy/defaults/yacy.init

# Enable HTTPS by default.
RUN sed -i "/server.https=false/c\server.https=true" \
	/opt/yacy/defaults/yacy.init

# Create a user with custom UID.
RUN adduser --system --user-group --no-create-home --uid 2016 yacy

# Set ownership of the YaCy directory to the current user and group.
RUN chown yacy:yacy -R /opt/yacy

# Expose default ports.
EXPOSE 8090 8443

# Run commands as YaCy non-root user.
# OpenShift requires a numeric value of User ID. For details see:
# https://docs.openshift.org/latest/creating_images/guidelines.html#use-uid
USER 2016

# Set data volume so YaCy data will persist after
# container destruction / restart.
VOLUME ["/opt/yacy/DATA"]

# Start YaCy. Use "-d" flag for debug mode.
CMD sh /opt/yacy/startYACY.sh -d
