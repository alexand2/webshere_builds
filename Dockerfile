FROM registry.access.redhat.com/rhel7

ENV WLP_OUTPUT_DIR="/opt/IBM/WebSphere/Liberty/usr/servers/" im_installer="agent.installer.linux.gtk.x86_64-1.8.3.zip" java_installer="ibm-java-jre-8.0-5.25-x86_64-archive.bin" was_file="wlp-kernel-17.0.0.3.zip" LIBERTY_DIR="/opt/IBM/WebSphere/Liberty" JAVA_URL="http://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/8.0.5.25/linux/x86_64/" WEBSPHERE_URL="https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/WSA/07683/1/" INSTALL_DIR="/opt/IBM/" user="wasadmin" group="root"

RUN useradd -u 1001 $user -g $group -m \
    #usermod -u 1001 $user \
    && mkdir -p $LIBERTY_DIR \
    && mkdir -p $LIBERTY_DIR/etc \
    && chown -R $user:$group $INSTALL_DIR \
    && chown -R $user:$group /var /opt /tmp

COPY .open_ocp-ha-lab.repo /etc/yum.repos.d/

RUN echo $user $group && yum install -y unzip

USER $user

# Install JRE

RUN curl --insecure -s -f  -X GET "$JAVA_URL/$java_installer" -o /tmp/ibm-java.bin \
    && echo "INSTALLER_UI=silent" > /tmp/response.properties \
    && echo "USER_INSTALL_DIR=$INSTALL_DIR/java" >> /tmp/response.properties \
    && echo "LICENSE_ACCEPTED=TRUE" >> /tmp/response.properties \
    && mkdir -p /opt/IBM \
    && chmod +x /tmp/ibm-java.bin \
    && /tmp/ibm-java.bin -i silent -f /tmp/response.properties \
    && rm -f /tmp/response.properties \
    && rm -f /tmp/ibm-java.bin

ENV JAVA_HOME=$INSTALL_DIR/java \
    PATH=$INSTALL_DIR/java/jre/bin:$PATH

#install WebSphere Liberty

RUN curl --insecure -s -f -X GET "$WEBSPHERE_URL/$was_file" -o /tmp/wlp.zip \
    && unzip -q /tmp/wlp.zip -d $INSTALL_DIR \
    && mv $INSTALL_DIR/wlp/* $LIBERTY_DIR/ \
    && rm /tmp/wlp.zip \
    && rmdir $INSTALL_DIR/wlp

ENV PATH=$INSTALL_DIR/wlp/bin:$PATH 

# Set Path Shortcuts - these items would have to be done as root user then changed over to wasadmin - leaving out for now

ENV LOG_DIR=/logs \

    WLP_OUTPUT_DIR=$LIBERTY_DIR/output

RUN mkdir /logs \

    && ln -s $WLP_OUTPUT_DIR/defaultServer /output \
    && ln -s $LIBERTY_DIR/usr/servers/defaultServer /config

# Configure WebSphere Liberty

RUN $LIBERTY_DIR/bin/server create \
    && rm -rf $WLP_OUTPUT_DIR/.classCache/* /$WLP_OUTPUT_DIR/defaultServer/workarea/* \
    && mkdir -p $WLP_OUTPUT_DIR/defaultServer/logs/ \
    && touch $WLP_OUTPUT_DIR/defaultServer/logs/messages.log \
    && mkdir -p $LIBERTY_DIR/usr/servers/defaultServer/.logs/ \
    && chmod g+rwx $LIBERTY_DIR/usr/servers $LIBERTY_DIR/usr/servers/defaultServer $LIBERTY_DIR/usr/servers/defaultServer/dropins $LIBERTY_DIR/usr/servers/defaultServer/apps $WLP_OUTPUT_DIR/defaultServer/workarea $WLP_OUTPUT_DIR/.classCache/ $LIBERTY_DIR/usr/servers/defaultServer/.logs $WLP_OUTPUT_DIR/defaultServer/logs/ \
    && chmod g+rw $LIBERTY_DIR/usr/servers/defaultServer/server.xml $LIBERTY_DIR/usr/servers/defaultServer/server.env  $LIBERTY_DIR/usr/servers/defaultServer/workarea/.sLock $WLP_OUTPUT_DIR/defaultServer/logs/messages.log

#RUN curl --insecure -s -f -X GET "$WEBSPHERE_URL/repositories.properties" -o $LIBERTY_DIR/etc/repositories.properties
COPY repositories.properties $LIBERTY_DIR/etc/repositories.properties

RUN curl --insecure -s -f -X GET "https://ak-delivery04-mul.dhe.ibm.com/sar/CMA/WSA/07684/1/wlp-featureRepo-17.0.0.3.zip" -o $LIBERTY_DIR/usr/wlp-featureRepo-17.0.0.3.zip

RUN mkdir -p $LIBERTY_DIR/lib/features

EXPOSE 9080 9443

#CMD ["/opt/IBM/WebSphere/Liberty/bin/server", "run", "defaultServer"]
CMD ["/opt/IBM/WebSphere/Liberty/bin/installUtility" ,"install" , "--acceptLicense" ,"defaultServer"]
