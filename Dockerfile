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
